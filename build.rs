fn main() {
    // embed the app icon and version info into mdv.exe (Windows only)
    #[cfg(windows)]
    {
        println!("cargo:rerun-if-changed=assets/mdv.ico");
        let mut res = winresource::WindowsResource::new();
        res.set_icon("assets/mdv.ico");
        res.set("ProductName", "Markdown Viewer");
        res.set("FileDescription", "Markdown Viewer");
        res.compile().expect("failed to embed Windows resources");
    }
}
