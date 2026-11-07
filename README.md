# MD-editor
Easy to use MD files editor application with BPMN process tools

**MD Editor** is a split-view Markdown editor for Windows: a Markdown **source** pane next to an editable **rich-text** pane, kept in sync. It ships as a small native host (WinForms + Microsoft Edge **WebView2**) that renders a single self-contained web page, `md-editor.html`.

> **Source status — please read.** This repository was assembled from the files that were available; it is **not yet a complete, buildable copy of the shipped v1.0 installer**. See [Source status and known gaps](#source-status-and-known-gaps).

## Repository layout

```
MD-editor/
├── README.md
├── .gitignore
├── src/
│   ├── host/
│   │   └── launcher.cs          # Windows host (WinForms + WebView2), v1.3.4
│   └── web/
│       └── md-editor.html       # Editor UI: HTML + CSS + JS in one file (2026-06-12 version)
├── scripts/
│   └── build-host.ps1           # Compiles launcher.cs and assembles a runnable folder (not yet verified)
└── docs/
    └── host-bridge-protocol.md  # Message protocol between the page and the host
```

## Features

### Editor page (`src/web/md-editor.html`)

- Split view: Markdown source and a click-to-edit rich-text pane, with a collapsible source pane.
- Toolbar: Open (with recent files), Save, Save As, reload from disk, undo/redo, H1–H3, bold, italic, strikethrough, inline code, text colour, highlight, clear formatting, bullet/numbered lists with indent/outdent and *continue numbering*, links, images (from URL or embedded from a file, with resize handles), tables (insert; right-click to add/delete rows and columns), code blocks, horizontal rule, and an **A4 page-width** toggle.
- Shortcuts: `Ctrl+S` save, `Ctrl+O` open, `Ctrl+B` bold, `Ctrl+I` italic, `Ctrl+Z` undo, `Ctrl+Y` / `Ctrl+Shift+Z` redo.
- Markdown is parsed in a Web Worker so large files do not freeze the UI.
- Fenced ```` ```plantuml ```` blocks are rendered locally to SVG (no network). The built-in renderer understands **entity / ER diagrams** (`entity Name { … }` with `<<PK>>` / `<<FK>>` markers); other PlantUML diagram types are not supported.
- Works standalone in a Chromium-based browser (uses the File System Access API and IndexedDB for the last-used folder).

### Windows host (`src/host/launcher.cs`)

- Borderless window with a custom dark title bar (icon, app name, centred file name, minimise / maximise / close), native Aero Snap, and maximise pinned to the current monitor's work area.
- Open with / double-click: a file path passed as the first argument is loaded on start.
- `mdeditor://` URL protocol: `mdeditor://C:/path/doc.md` opens a local file. Only local-drive paths ending in `.md`, `.markdown` or `.txt` are accepted; UNC paths are rejected so a web page cannot make Windows contact a remote host.
- Native Open / Save As dialogs that remember the last folder.
- Guarded autosave: a background save is refused if the file changed on disk since the page last read or wrote it, so external edits are never overwritten.
- Unsaved-changes guard on every close path (Save and close / Close / Cancel).
- Links and `window.open` open in the default browser; the editor never navigates away itself.
- A linked `.md` can open in its own new window.
- Clipboard read is auto-allowed inside the app so right-click **Paste** does not show a permission prompt.
- WebView2 profile data lives in `%LOCALAPPDATA%\MDEditor\WebView2`.

Details of the page ↔ host messages are in [`docs/host-bridge-protocol.md`](docs/host-bridge-protocol.md).

## Requirements

- Windows 10 / 11, x64
- [Microsoft Edge WebView2 Evergreen Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)
- To build: the .NET Framework 4 C# compiler (`csc.exe`, included with Windows) and the WebView2 SDK assemblies `Microsoft.Web.WebView2.Core.dll`, `Microsoft.Web.WebView2.WinForms.dll` and `WebView2Loader.dll` (x64), e.g. from the `Microsoft.Web.WebView2` NuGet package.

The host is written to compile with the in-box C# 5 compiler (no newer language features).

## Build

Put the three WebView2 DLLs in a folder (e.g. `lib\`), then from the repository root in PowerShell:

```powershell
.\scripts\build-host.ps1 -LibDir .\lib
```

Optional: `-IconPath` (`md-editor.ico`, used as the exe icon) and `-HeaderIconPath` (`md-editor-icon.png`, the title-bar logo). The output goes to `dist\` and contains `md-editor.exe` plus everything the exe needs next to it. The equivalent manual command is in the header comment of `launcher.cs`.

Run `dist\md-editor.exe`, or `dist\md-editor.exe C:\path\to\file.md` to open a file.

To use the page on its own, open `src/web/md-editor.html` in Chrome or Edge.

## Source status and known gaps

The repository documents what was actually on hand when it was created:

| Item | Status |
|---|---|
| `src/host/launcher.cs` | Included exactly as provided (assembly version 1.3.4.0). |
| `src/web/md-editor.html` | Included exactly as provided, dated **2026-06-12**. It predates the host: it contains **no client for the host bridge** (`__mdOpenFile`, `OPENPATH`, `SAVEAUTO`, `DIRTY:` …), so file open/save, autosave conflict detection, the unsaved-changes guard and `mdeditor://` links described above need the **newer `md-editor.html`**, which is not in this repository. |
| BPMN process tools | Mentioned in the project description, but **no BPMN code is present** in the available sources. |
| Installer script `md-editor.iss` (Inno Setup) | **Not included.** The v1.0 installer (`MDEditorSetup.exe`, Inno Setup 6.7) was not reverse-engineered; its script must be added from the original. |
| `md-editor.ico`, `md-editor-icon.png` | **Not included.** Needed for the exe/taskbar and title-bar icons; the host still runs without them. |
| WebView2 SDK DLLs | Not committed (third-party binaries); obtain from NuGet as described above. |
| `scripts/build-host.ps1` | Written from the compile command in `launcher.cs`; **not yet run** against the real DLLs. |
| License | **None chosen yet.** Add a `LICENSE` file before sharing the code. |

The installer binary is intentionally not committed; publish it as a GitHub Release asset instead.

To complete the repository: add the current `md-editor.html`, `md-editor.iss`, and the two icon files under `src/web/`, `installer/` and `assets/`, then update this table.
