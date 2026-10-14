# Privacy Policy

**Markdown Viewer ("mdv")** - published by Patir Softwares
Effective date: 14 October 2026

## Summary

Markdown Viewer does not collect, store, transmit, sell or share any personal information. It has no accounts,
no analytics, no advertising and no telemetry.

## What the app does with your files

The app reads the Markdown files that you open, on your device, in order to display them. Their content is never
uploaded or sent anywhere by the app. Rendering of text, mathematical formulas and diagrams (including Mermaid) happens
entirely on your device; the diagram library is built into the app.

## What the app stores on your device

The app saves a small settings file in your user profile (`%APPDATA%\mdv` on Windows, `~/.config/mdv` on Linux,
`~/Library/Application Support/mdv` on macOS) containing:

- your theme choice (system, light or dark),
- your zoom level,
- whether the update check is enabled (downloadable builds only), and
- the file paths of the last ten documents you opened (the "Open Recent" list).

The operating system's web view component also keeps its normal cache in the `webview` folder next to that settings file.
This data stays on your device. You can delete it at any time by removing the folder (uninstalling the app also removes it
on Windows when installed from the Microsoft Store).

## Network access

The app itself makes no network connections and sends no data to the publisher or any third party.

The one exception is the **update check in the downloadable builds** (the standalone `.exe`, installer, Linux and macOS
packages from GitHub Releases). At most once a day it asks the public GitHub API for the latest release version
(`https://api.github.com/repos/sunaram/markdown-viewer/releases/latest`) and shows a notice if a newer one exists. No
information about you, your files or your device is sent beyond what any web request includes (such as your IP address, which
GitHub can see). You can turn it off in **Help > Check for updates at startup**, or run it on demand with **Help > Check for
Updates**. The version installed from the **Microsoft Store never makes this request**: the Store delivers updates.

Markdown documents can contain remote content - for example images, videos, embedded frames or scripts that point to web
addresses. If a document you open contains such content, the app's web view will load it from the address given in the
document, in the same way a web browser would, and that website can see your IP address and ordinary request information.
Links you click in a document open in your default web browser. Documents can also contain scripts that run in the viewer,
so open files only from sources you trust.

## Children

The app is a general-purpose document viewer. It does not collect personal information from anyone, including children.

## Open source

Markdown Viewer is open source under the MIT license. You can inspect exactly what it does at
<https://github.com/sunaram/markdown-viewer>.

## Changes to this policy

If this policy changes, the updated version will be published at
<https://github.com/sunaram/markdown-viewer/blob/main/PRIVACY.md> with a new effective date.

## Contact

Questions about privacy can be raised by opening an issue at <https://github.com/sunaram/markdown-viewer/issues>.
