#![cfg_attr(windows, windows_subsystem = "windows")]

use pulldown_cmark::{CodeBlockKind, Event, Options, Parser, Tag, TagEnd, html};
use std::borrow::Cow;
use std::path::{Component, Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant, SystemTime};
use tao::event::{Event as Ev, StartCause, WindowEvent};
use tao::event_loop::{ControlFlow, EventLoopBuilder};
use tao::window::WindowBuilder;
use wry::http::{Response, header::CONTENT_TYPE};
use wry::{DragDropEvent, WebViewBuilder};

const CSS: &str = include_str!("../assets/style.css");
const MERMAID_Z: &[u8] = include_bytes!("../assets/mermaid.js.z");

#[cfg(windows)]
const ORIGIN: &str = "http://mv.localhost";
#[cfg(not(windows))]
const ORIGIN: &str = "mv://localhost";

const JS: &str = include_str!("../assets/app.js");

enum User {
    Open(PathBuf),
    Cmd(String),
}

#[derive(Default)]
struct State {
    file: Option<PathBuf>,
    /// "" = follow the OS, otherwise "light" / "dark"
    theme: &'static str,
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

fn render(md: &str) -> String {
    let opts = Options::ENABLE_TABLES
        | Options::ENABLE_FOOTNOTES
        | Options::ENABLE_STRIKETHROUGH
        | Options::ENABLE_TASKLISTS
        | Options::ENABLE_HEADING_ATTRIBUTES
        | Options::ENABLE_MATH
        | Options::ENABLE_SUPERSCRIPT
        | Options::ENABLE_SUBSCRIPT;
    let mut in_mermaid = false;
    let mut src = String::new();
    let events = Parser::new_ext(md, opts).filter_map(|ev| match ev {
        Event::InlineMath(t) => Some(math(&t, false)),
        Event::DisplayMath(t) => Some(math(&t, true)),
        Event::Start(Tag::CodeBlock(CodeBlockKind::Fenced(ref l))) if &**l == "mermaid" => {
            in_mermaid = true;
            src.clear();
            None
        }
        Event::Text(t) if in_mermaid => {
            src.push_str(&t);
            None
        }
        Event::End(TagEnd::CodeBlock) if in_mermaid => {
            in_mermaid = false;
            Some(Event::Html(format!("<pre class=\"mermaid\">{}</pre>\n", esc(&src)).into()))
        }
        e => Some(e),
    });
    let mut out = String::with_capacity(md.len() * 2);
    html::push_html(&mut out, events);
    out
}

fn math(tex: &str, display: bool) -> Event<'static> {
    use latex2mathml::{DisplayStyle, latex_to_mathml};
    let style = if display { DisplayStyle::Block } else { DisplayStyle::Inline };
    let h = match latex_to_mathml(tex, style) {
        Ok(m) if display => format!("<div class=\"math\">{m}</div>"),
        Ok(m) => m,
        Err(e) => format!("<code class=\"err\" title=\"{}\">{}</code>", esc(&e.to_string()), esc(tex)),
    };
    Event::InlineHtml(h.into())
}

fn page(state: &State) -> String {
    let theme = state.theme;
    let body = match &state.file {
        Some(p) => match std::fs::read(p) {
            Ok(b) => render(&String::from_utf8_lossy(&b)),
            Err(e) => format!("<p class=\"err\">Cannot read {}: {}</p>", esc(&p.display().to_string()), e),
        },
        None => "<h1>Markdown Viewer</h1><p>Drop a <code>.md</code> file here, or run <code>mdv file.md</code>.</p>".into(),
    };
    format!(
        "<!doctype html><html data-theme=\"{theme}\"><meta charset=utf-8><meta name=viewport content=\"width=device-width,initial-scale=1\">\
<base href=\"{ORIGIN}/\"><style>{CSS}</style><article>{body}</article><script>{JS}</script>"
    )
}

fn mime(p: &Path) -> &'static str {
    match p.extension().and_then(|e| e.to_str()).map(|e| e.to_ascii_lowercase()).as_deref() {
        Some("png") => "image/png",
        Some("jpg" | "jpeg") => "image/jpeg",
        Some("gif") => "image/gif",
        Some("webp") => "image/webp",
        Some("svg") => "image/svg+xml",
        Some("css") => "text/css",
        Some("js") => "text/javascript",
        Some("html" | "htm") => "text/html",
        Some("mp4") => "video/mp4",
        Some("webm") => "video/webm",
        _ => "application/octet-stream",
    }
}

fn unescape(s: &str) -> String {
    let b = s.as_bytes();
    let mut o = Vec::with_capacity(b.len());
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'%' && i + 2 < b.len() + 0 {
            if let Ok(v) = u8::from_str_radix(&s[i + 1..i + 3], 16) {
                o.push(v);
                i += 3;
                continue;
            }
        }
        o.push(b[i]);
        i += 1;
    }
    String::from_utf8_lossy(&o).into_owned()
}

fn canon(p: PathBuf) -> PathBuf {
    let c = p.canonicalize().unwrap_or(p);
    match c.to_str().and_then(|s| s.strip_prefix(r"\\?\")) {
        Some(rest) if !rest.starts_with("UNC") => PathBuf::from(rest),
        _ => c,
    }
}

fn is_md(p: &str) -> bool {
    let p = p.to_ascii_lowercase();
    p.ends_with(".md") || p.ends_with(".markdown")
}

fn open_external(url: &str) {
    use std::process::Command;
    #[cfg(windows)]
    let _ = Command::new("rundll32").args(["url.dll,FileProtocolHandler", url]).spawn();
    #[cfg(target_os = "macos")]
    let _ = Command::new("open").arg(url).spawn();
    #[cfg(all(unix, not(target_os = "macos")))]
    let _ = Command::new("xdg-open").arg(url).spawn();
}

const MAX_RECENT: usize = 10;

struct Settings {
    theme: &'static str,
    zoom: f64,
    recent: Vec<PathBuf>,
}

fn settings_path() -> Option<PathBuf> {
    use std::env::var_os;
    #[cfg(windows)]
    let base = var_os("APPDATA").map(PathBuf::from);
    #[cfg(target_os = "macos")]
    let base = var_os("HOME").map(|h| PathBuf::from(h).join("Library/Application Support"));
    #[cfg(all(unix, not(target_os = "macos")))]
    let base = var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| var_os("HOME").map(|h| PathBuf::from(h).join(".config")));
    base.map(|b| b.join("mdv").join("settings.txt"))
}

fn load_settings() -> Settings {
    let mut s = Settings { theme: "", zoom: 1.0, recent: vec![] };
    let Some(text) = settings_path().and_then(|p| std::fs::read_to_string(p).ok()) else { return s };
    for line in text.lines() {
        match line.split_once('=') {
            Some(("theme", "light")) => s.theme = "light",
            Some(("theme", "dark")) => s.theme = "dark",
            Some(("zoom", v)) => s.zoom = v.parse().map_or(1.0, |z: f64| z.clamp(0.3, 5.0)),
            Some(("recent", p)) if s.recent.len() < MAX_RECENT => s.recent.push(PathBuf::from(p)),
            _ => {}
        }
    }
    s
}

fn save_settings(s: &Settings) {
    let Some(path) = settings_path() else { return };
    let mut out = format!("theme={}\nzoom={}\n", s.theme, s.zoom);
    for p in &s.recent {
        out.push_str(&format!("recent={}\n", p.display()));
    }
    if let Some(dir) = path.parent() {
        let _ = std::fs::create_dir_all(dir);
    }
    let _ = std::fs::write(path, out);
}

/// Rebuild the "Open Recent" submenu from `recent`.
fn fill_recent(sub: &muda::Submenu, old: &mut Vec<muda::MenuItem>, recent: &[PathBuf]) {
    use muda::MenuItem;
    for i in old.drain(..) {
        let _ = sub.remove(&i);
    }
    let mut add = |id: String, label: String, enabled: bool| {
        let m = MenuItem::with_id(id, label, enabled, None);
        let _ = sub.append(&m);
        old.push(m);
    };
    if recent.is_empty() {
        add("none".into(), "(empty)".into(), false);
        return;
    }
    for (i, p) in recent.iter().enumerate() {
        add(format!("recent:{i}"), p.to_string_lossy().replace('&', "&&"), true);
    }
    add("recent_clear".into(), "Clear Recent".into(), true);
}

fn build_menu() -> (muda::Menu, muda::Submenu) {
    use muda::{Menu, MenuItem, PredefinedMenuItem as P, Submenu};
    // macOS gets real accelerators; elsewhere shortcuts are handled in page JS
    // (the focused webview swallows menu accelerators) and shown as a label hint.
    let it = |id: &str, label: &str, key: &str| -> MenuItem {
        #[cfg(target_os = "macos")]
        {
            MenuItem::with_id(id, label, true, format!("CmdOrCtrl+{key}").parse().ok())
        }
        #[cfg(not(target_os = "macos"))]
        {
            let l = if key.is_empty() { label.to_string() } else { format!("{label}\tCtrl+{key}") };
            MenuItem::with_id(id, l, true, None)
        }
    };
    let sep = P::separator();
    let recent = Submenu::new("Open &Recent", true);
    let file = Submenu::with_items(
        "&File",
        true,
        &[
            &it("open", "&Open…", "O"),
            &recent,
            &it("reload", "&Reload", "R"),
            &it("print", "&Print / Save as PDF…", "P"),
            &it("editor", "Open in &Editor", "E"),
            &sep,
            &it("quit", "&Quit", "W"),
        ],
    )
    .unwrap();
    let view = Submenu::with_items(
        "&View",
        true,
        &[
            &it("find", "&Find…", "F"),
            &sep,
            &it("zin", "Zoom &In", "="),
            &it("zout", "Zoom &Out", "-"),
            &it("zreset", "&Actual Size", "0"),
            &sep,
            &it("theme_auto", "Theme: &System", ""),
            &it("theme_light", "Theme: &Light", ""),
            &it("theme_dark", "Theme: &Dark", ""),
        ],
    )
    .unwrap();
    let help = Submenu::with_items("&Help", true, &[&it("about", "&About", "")]).unwrap();
    (Menu::with_items(&[&file, &view, &help]).unwrap(), recent)
}

fn main() {
    let mut cfg = load_settings();
    cfg.recent.retain(|p| p.exists());
    let arg = std::env::args_os().nth(1).map(|a| {
        canon(PathBuf::from(a))
    });
    if let Some(p) = &arg {
        cfg.recent.retain(|r| r != p);
        cfg.recent.insert(0, p.clone());
        cfg.recent.truncate(MAX_RECENT);
        save_settings(&cfg);
    }
    let state = Arc::new(Mutex::new(State {
        // no argument: reopen the last file
        file: arg.or_else(|| cfg.recent.first().cloned()),
        theme: cfg.theme,
    }));
    let mermaid: Arc<Mutex<Option<Vec<u8>>>> = Arc::new(Mutex::new(None));

    let event_loop = EventLoopBuilder::<User>::with_user_event().build();
    let proxy = event_loop.create_proxy();
    let window = WindowBuilder::new()
        .with_title("Markdown Viewer")
        .with_inner_size(tao::dpi::LogicalSize::new(900.0, 800.0))
        .build(&event_loop)
        .unwrap();

    // The menu must be attached before the webview on Linux so it sits above it in the GTK box.
    let (menu, recent_menu) = build_menu();
    let mut recent_items = Vec::new();
    fill_recent(&recent_menu, &mut recent_items, &cfg.recent);
    {
        let proxy = Mutex::new(proxy.clone());
        muda::MenuEvent::set_event_handler(Some(move |e: muda::MenuEvent| {
            let _ = proxy.lock().unwrap().send_event(User::Cmd(e.id.0.clone()));
        }));
    }
    #[cfg(windows)]
    unsafe {
        use tao::platform::windows::WindowExtWindows;
        menu.init_for_hwnd(window.hwnd() as isize).unwrap();
    }
    #[cfg(target_os = "linux")]
    {
        use tao::platform::unix::WindowExtUnix;
        menu.init_for_gtk_window(window.gtk_window(), window.default_vbox()).unwrap();
    }
    #[cfg(target_os = "macos")]
    menu.init_for_nsapp();

    let st = state.clone();
    // keep WebView2's profile out of the exe's folder (may be read-only, e.g. Program Files)
    let mut web_ctx = wry::WebContext::new(settings_path().and_then(|p| p.parent().map(|d| d.join("webview"))));
    let builder = WebViewBuilder::new_with_web_context(&mut web_ctx)
        .with_url(format!("{ORIGIN}/"))
        .with_custom_protocol("mv".into(), move |_, req| {
            let path = unescape(req.uri().path());
            let ok = |ct: &str, body: Vec<u8>| {
                Response::builder().header(CONTENT_TYPE, ct).body(Cow::Owned(body)).unwrap()
            };
            if path == "/" {
                return ok("text/html; charset=utf-8", page(&st.lock().unwrap()).into_bytes());
            }
            if path == "/__mermaid.js" {
                let mut m = mermaid.lock().unwrap();
                let js = m.get_or_insert_with(|| miniz_oxide::inflate::decompress_to_vec(MERMAID_Z).unwrap_or_default());
                return ok("text/javascript", js.clone());
            }
            let dir = st.lock().unwrap().file.as_ref().and_then(|f| f.parent().map(Path::to_path_buf));
            let rel = Path::new(path.trim_start_matches('/'));
            let safe = rel.components().all(|c| matches!(c, Component::Normal(_)));
            if let (Some(dir), true) = (dir, safe) {
                let full = dir.join(rel);
                if let Ok(b) = std::fs::read(&full) {
                    return ok(mime(&full), b);
                }
            }
            Response::builder().status(404).body(Cow::Borrowed(&b""[..])).unwrap()
        })
        .with_navigation_handler({
            let st = state.clone();
            let proxy = proxy.clone();
            move |url| {
                if let Some(rest) = url.strip_prefix(ORIGIN) {
                    let p = unescape(rest.split(['#', '?']).next().unwrap_or(""));
                    if is_md(&p) {
                        let dir = st.lock().unwrap().file.as_ref().and_then(|f| f.parent().map(Path::to_path_buf));
                        let rel = Path::new(p.trim_start_matches('/'));
                        if let Some(d) = dir {
                            if rel.components().all(|c| matches!(c, Component::Normal(_))) {
                                let _ = proxy.send_event(User::Open(d.join(rel)));
                            }
                        }
                        return false;
                    }
                    return true;
                }
                if url.starts_with("http://") || url.starts_with("https://") || url.starts_with("mailto:") {
                    open_external(&url);
                }
                false
            }
        })
        .with_drag_drop_handler({
            let proxy = proxy.clone();
            move |ev| {
                if let DragDropEvent::Drop { paths, .. } = ev {
                    if let Some(p) = paths.into_iter().next() {
                        let _ = proxy.send_event(User::Open(p));
                    }
                }
                true
            }
        })
        .with_ipc_handler({
            let proxy = proxy.clone();
            move |req| {
                let _ = proxy.send_event(User::Cmd(req.body().clone()));
            }
        });

    #[cfg(not(target_os = "linux"))]
    let webview = builder.build(&window).unwrap();
    #[cfg(target_os = "linux")]
    let webview = {
        use tao::platform::unix::WindowExtUnix;
        use wry::WebViewBuilderExtUnix;
        builder.build_gtk(window.default_vbox().unwrap()).unwrap()
    };

    let title = |f: &Option<PathBuf>| match f.as_ref().and_then(|p| p.file_name()) {
        Some(n) => format!("{} - Markdown Viewer", n.to_string_lossy()),
        None => "Markdown Viewer".into(),
    };
    let mtime = |f: &Option<PathBuf>| f.as_ref().and_then(|p| std::fs::metadata(p).and_then(|m| m.modified()).ok());
    window.set_title(&title(&state.lock().unwrap().file));
    let mut last: Option<SystemTime> = mtime(&state.lock().unwrap().file);
    let mut zoom = cfg.zoom;
    if zoom != 1.0 {
        let _ = webview.zoom(zoom);
    }

    event_loop.run(move |event, _, flow| {
        let _keep = &menu;
        *flow = ControlFlow::WaitUntil(Instant::now() + Duration::from_millis(500));
        match event {
            Ev::WindowEvent { event: WindowEvent::CloseRequested, .. } => *flow = ControlFlow::Exit,
            // Finder "Open With" / double-click delivers files as an Apple Event, not argv
            #[cfg(target_os = "macos")]
            Ev::Opened { urls } => {
                if let Some(p) = urls.iter().find_map(|u| u.to_file_path().ok()) {
                    let _ = proxy.send_event(User::Open(p));
                }
            }
            #[cfg(windows)]
            Ev::WindowEvent { event: WindowEvent::Resized(size), .. } => {
                let _ = webview.set_bounds(wry::Rect {
                    position: wry::dpi::PhysicalPosition::new(0, 0).into(),
                    size: wry::dpi::PhysicalSize::new(size.width, size.height).into(),
                });
            }
            Ev::UserEvent(u) => {
                let mut pick = None;
                match u {
                    User::Open(p) => pick = Some(p),
                    User::Cmd(c) => match c.as_str() {
                        "open" => {
                            let mut d = rfd::FileDialog::new()
                                .add_filter("Markdown", &["md", "markdown", "mdown", "mkd", "txt"])
                                .add_filter("All files", &["*"]);
                            if let Some(dir) = state.lock().unwrap().file.as_ref().and_then(|f| f.parent()) {
                                d = d.set_directory(dir);
                            }
                            pick = d.pick_file();
                        }
                        "reload" => {
                            let _ = webview.evaluate_script("location.reload()");
                        }
                        "print" => {
                            let _ = webview.print();
                        }
                        "editor" => {
                            if let Some(f) = &state.lock().unwrap().file {
                                open_external(&f.to_string_lossy());
                            }
                        }
                        "find" => {
                            let _ = webview.evaluate_script("__find()");
                        }
                        "zin" | "zout" | "zreset" => {
                            zoom = match c.as_str() {
                                "zin" => zoom + 0.1,
                                "zout" => zoom - 0.1,
                                _ => 1.0,
                            }
                            .clamp(0.3, 5.0);
                            let _ = webview.zoom(zoom);
                            cfg.zoom = zoom;
                            save_settings(&cfg);
                        }
                        "recent_clear" => {
                            cfg.recent.clear();
                            fill_recent(&recent_menu, &mut recent_items, &cfg.recent);
                            save_settings(&cfg);
                        }
                        r if r.starts_with("recent:") => {
                            pick = r[7..].parse::<usize>().ok().and_then(|i| cfg.recent.get(i).cloned());
                        }
                        "theme_auto" | "theme_light" | "theme_dark" => {
                            cfg.theme = match c.as_str() {
                                "theme_light" => "light",
                                "theme_dark" => "dark",
                                _ => "",
                            };
                            state.lock().unwrap().theme = cfg.theme;
                            save_settings(&cfg);
                            let _ = webview.evaluate_script("location.reload()");
                        }
                        "about" => {
                            rfd::MessageDialog::new()
                                .set_title("About")
                                .set_description(format!(
                                    "Markdown Viewer {}\nMarkdown, LaTeX, Mermaid and HTML/SVG/MathML.",
                                    env!("CARGO_PKG_VERSION")
                                ))
                                .show();
                        }
                        "quit" => *flow = ControlFlow::Exit,
                        _ => {}
                    },
                }
                if let Some(p) = pick {
                    let mut s = state.lock().unwrap();
                    s.file = Some(canon(p));
                    window.set_title(&title(&s.file));
                    last = mtime(&s.file);
                    let _ = webview.evaluate_script("location.reload()");
                    if let Some(f) = s.file.clone() {
                        cfg.recent.retain(|r| *r != f);
                        cfg.recent.insert(0, f);
                        cfg.recent.truncate(MAX_RECENT);
                        fill_recent(&recent_menu, &mut recent_items, &cfg.recent);
                        save_settings(&cfg);
                    }
                }
            }
            // live reload when the file changes on disk
            Ev::NewEvents(StartCause::ResumeTimeReached { .. }) => {
                let m = mtime(&state.lock().unwrap().file);
                if m != last {
                    last = m;
                    let _ = webview.evaluate_script("location.reload()");
                }
            }
            _ => {}
        }
    });
}
