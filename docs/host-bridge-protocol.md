# Host bridge protocol

Source of truth: the comments and `HandleHostMessage` in [`src/host/launcher.cs`](../src/host/launcher.cs).

The editor page is loaded over `file://`, so it has no real operating-system file paths. File I/O therefore goes through the Windows host. Both directions use **plain strings**:

- page → host: `window.chrome.webview.postMessage("<command>")`
- host → page: `CoreWebView2.PostWebMessageAsString("<reply>")`

`<mtime>` is the file's last-write time as **Unix epoch milliseconds (UTC)** — milliseconds, not ticks, so the value stays exact in a JavaScript `Number`. `<path>` never contains a newline. `0` means the file is missing or unreadable.

## Page → host commands

| Command | Effect | Reply |
|---|---|---|
| `OPEN:` | Show the native Open dialog | `OPENED:<mtime>\n<path>\n<text>` · `OPENERR:<msg>` · `OPENCANCEL` |
| `OPENPATH:<path>` | Read exactly that file | `OPENED:…` · `OPENERR:<msg>` |
| `SAVETO:<path>\n<text>` | Write `text` to `path` unconditionally (manual save) | `SAVED:<mtime>` · `SAVEERR:<msg>` |
| `SAVEAUTO:<mtime>\n<path>\n<text>` | Guarded autosave: write only if the file on disk still has exactly the mtime the page last saw | `SAVED:<mtime>` · `SAVECONFLICT` · `SAVEERR:<msg>` |
| `SAVEAS:<suggestedName>\n<text>` | Show the native Save As dialog and write there | `SAVEDAS:<mtime>\n<path>` · `SAVEASCANCEL` · `SAVEERR:<msg>` |
| `NEWWIN:<path>` | Start a second MD Editor instance on that file | `OPENERR:<msg>` on failure, none on success |
| `OPENFOLDER:<path>` | Reveal the file in Explorer | none |
| `DIRTY:1` / `DIRTY:0` | Mirror the page's unsaved-changes flag for the close guard | none |
| `CLOSENOW` | The page finished "Save and close"; close without prompting again | none |

`SAVEAUTO` answers `SAVECONFLICT` when the baseline is missing, not positive, or not an exact match for the file's current mtime, or when the file no longer exists. A background save can therefore never overwrite an external edit.

## Host → page messages not tied to a command

| Message | Meaning |
|---|---|
| `SAVEFORCLOSE` | The user chose **Save and close**; the page should save (using Save As for an untitled document) and then send `CLOSENOW`. |

## Start-up injection

When the exe is launched with a file (Open with, double-click, or an `mdeditor://` link) the host reads it and registers, before the page loads:

```js
window.__mdOpenFile = { name: "<file name>", path: "<full path>", mtime: <mtime>, text: "<contents>" };
```

## Window title

The page sets `document.title` to `<file> • — MD Editor`. The host mirrors it into the taskbar title and, with the ` — MD Editor` suffix removed, into the centred title-bar label.

## Security notes

- `mdeditor://` links can be triggered by any web page, so only a **local drive path** (`X:\…`) to a `.md`, `.markdown` or `.txt` file is accepted. UNC paths are refused because `File.Exists` on them would make Windows contact the remote host.
- `http`, `https` and `mailto` navigations are cancelled in the editor and opened in the default browser instead.
- Clipboard read is the only permission the host grants automatically.
