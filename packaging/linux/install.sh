#!/bin/sh
# Per-user install of mdv (no root needed):  ./install.sh [path/to/mdv]   |   ./install.sh --uninstall
# Installs to ~/.local/{bin,share} and registers the .desktop entry + icon + markdown MIME association.
set -e
here=$(cd "$(dirname "$0")" && pwd)
prefix="${PREFIX:-$HOME/.local}"
apps="$prefix/share/applications"
icons="$prefix/share/icons/hicolor"

refresh() {
    command -v update-desktop-database >/dev/null && update-desktop-database "$apps" 2>/dev/null || true
    command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t "$icons" 2>/dev/null || true
}

if [ "$1" = "--uninstall" ]; then
    rm -f "$prefix/bin/mdv" "$apps/mdv.desktop"
    for s in 48 128 256; do rm -f "$icons/${s}x${s}/apps/mdv.png"; done
    rm -f "$icons/scalable/apps/mdv.svg"
    refresh
    echo "mdv uninstalled."
    exit 0
fi

bin="${1:-}"
[ -z "$bin" ] && for c in "$here/mdv" "$here/../../target/release/mdv"; do [ -x "$c" ] && bin="$c" && break; done
[ -x "$bin" ] || { echo "mdv binary not found - run 'cargo build --release' or pass its path" >&2; exit 1; }

install -Dm755 "$bin" "$prefix/bin/mdv"
install -Dm644 "$here/mdv.desktop" "$apps/mdv.desktop"
install -Dm644 "$here/mdv.svg" "$icons/scalable/apps/mdv.svg"
refresh

# make it the default handler for Markdown (the user can undo this in their desktop settings)
if command -v xdg-mime >/dev/null; then
    xdg-mime default mdv.desktop text/markdown text/x-markdown 2>/dev/null || true
fi
echo "mdv installed to $prefix/bin/mdv"
case ":$PATH:" in *":$prefix/bin:"*) ;; *) echo "note: $prefix/bin is not on your PATH" ;; esac
