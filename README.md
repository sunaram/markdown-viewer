# mdv - Markdown Viewer

A tiny cross-platform (Windows, Linux, macOS) Markdown viewer. The release binary is about 2.5 MB because it uses the
operating system's webview (WebView2 / WebKitGTK / WKWebView) instead of bundling a browser.

- **Markdown:** tables, footnotes, task lists, strikethrough, heading attributes
- **LaTeX:** `$inline$` and `$$display$$`, converted to MathML in Rust (no fonts or JavaScript shipped)
- **Mermaid:** diagrams in ```` ```mermaid ```` blocks; the library is embedded compressed and only loaded when needed
- **HTML:** raw HTML, inline SVG and MathML pass straight through (scripts run too - only open files you trust)
- **Desktop:** open dialog, drag and drop, live reload, recent files, find, zoom, print / save as PDF,
  light/dark/system theme (theme, zoom and recent files are remembered), links between `.md` files

## Build

```sh
cargo build --release          # Linux needs libwebkit2gtk-4.1-dev libgtk-3-dev libxdo-dev
target/release/mdv README.md
```

`assets/mermaid.js.z` is the deflate-compressed `mermaid.min.js`. To update it:

```sh
npm pack mermaid && tar -xzf mermaid-*.tgz package/dist/mermaid.min.js && cp package/dist/mermaid.min.js tools/
node tools/pack.mjs
```

## Packaging (`packaging/`)

| Platform | How |
|---|---|
| Windows (Microsoft Store) | `packaging/msix/build.ps1` builds an MSIX; see the header of that script for Store and local-test usage |
| Windows (direct) | `packaging/windows/install.ps1` (per-user, no extra tools) or `mdv.iss` (Inno Setup) |
| Linux | `packaging/linux/install.sh` (per-user; installs the binary, `.desktop` entry and icon, sets the Markdown MIME default) |
| macOS | `packaging/macos/bundle.sh` builds `Markdown Viewer.app` and a `.dmg` |

`.github/workflows/build.yml` builds all three on a version tag. The icons are placeholders.

## License

MIT - see [LICENSE](LICENSE). The embedded Mermaid library is also MIT-licensed.
