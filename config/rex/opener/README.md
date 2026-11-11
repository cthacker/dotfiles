# Rex Opener

Cmd-click a local file in any Rex pane to open it in a new pane to the right of the pane
that shows it:

- **Markdown** previews in Glow. Rex's current focus is preserved. Click the preview to
  scroll or use its keyboard controls; **q** closes it, **r** reloads, and **?** shows help.
- **Code and text** open in nvim, which takes focus. Its working directory is that of the
  pane you clicked in, and it starts through your interactive shell, so it has the same
  `PATH` as an nvim you start by hand. Each Rex tab gets one such nvim pane: later files
  from that tab open in it instead of splitting again. The pane closes when nvim exits.

Rex refuses to Cmd-click some files, and a click needs the path to be a link. For
everything else there is a picker: **Ctrl-Cmd-O** (Caps Lock-Cmd-O, with Caps Lock remapped
to Control) lists the files named on the focused pane's screen. See
[Picking a file from the screen](#picking-a-file-from-the-screen).

Rex has no hook for link clicks: it asks macOS to open the file. So this installs a small
app, `Rex Opener.app`, as the default macOS opener for these file types. The app handles
files that Rex asks for and passes every other request on to the opener each type had
before.

## Scope

- Works for whatever Rex makes clickable: absolute paths, and terminal hyperlinks to a
  `file:` URL, an absolute path or a relative path.
- Relative targets need the shell to report its working directory to Rex (OSC 7). The
  dotfiles `zsh/zshrc` does this; a pane whose shell does not is limited to absolute paths.
- Rex does not make a bare relative filename such as `notes.md` clickable. From a shell in
  the pane, run `open notes.md` instead.
- The file types are the `MARKDOWN` and `CODE` lists in `bridge.mjs`. To change them, edit
  the lists and run the installer again; a type you remove returns to its previous opener.
  HTML is deliberately left to the browser.
- Script types (`py`, `sh`, `zsh`, `rb`, `js`, `mjs`, `tsx`) cannot be Cmd-clicked. Rex
  refuses to open a file that macOS classes as a script or executable ("Opening this local
  target could execute code"), so the click never reaches this app. Use the picker for
  those. Two slower routes also work for a type registered to this app: `open run.sh` from
  a shell in the pane, or Shift-Cmd-click to preview the file and then "Open with Rex Opener".
- macOS asks you to confirm each change of default app, when installing, removing or
  changing the lists. If you choose to keep the current app, that type stays as it was.
- A Cmd-click does not pass on a line number after the path, as in `app.py:42`: nvim opens
  at the top. The picker does use it.
- A request counts as coming from Rex when Rex sent it, or when the sender is not an app
  (such as `open` in a shell) and Rex is the frontmost app. Finder and other apps still
  open each type in its previous opener.
- Each Markdown click opens a fresh Glow pane. Code files reuse one nvim pane per tab.
- Does not navigate to Markdown fragment anchors.
- Local macOS Rex only; not panes on remote hosts.

## Install or refresh

Requires macOS, Rex, Glow, nvim, Node 22.18 or newer and the Xcode command-line tools.
Tested with Rex 0.1.0-preview.14, Glow 3.0.0, nvim 0.12 and Node 24. From the dotfiles repository:

```sh
node config/rex/opener/install.mjs
```

The installer creates:

- `~/Applications/Rex Opener.app`: locally compiled, ad-hoc-signed, and registered as the
  default opener for every handled type. It exits when each request completes.
- `~/Library/Application Support/Rex Opener/`: the Rex, Glow and nvim paths and each type's
  previous opener (`programs.json`), a dedicated Glow configuration and the handler log.

It records the current Node, Rex, Glow and nvim paths and this directory's location. Run
it again if an upgrade removes one of those executables or if this directory moves.

Because the app is now the default opener, Finder shows its generic icon for these files
and Quick Look offers "Open with Rex Opener". `.ts` shares its macOS type with MPEG
transport-stream video, so those videos take the same route.

## Finding the pane

macOS hands the app a file path, not the pane that was clicked. The opener looks at the
active tab of each session the Rex app has open, starting with the session the app last
focused, and picks the first pane whose screen shows the file's name. If none does, as
with a hyperlink whose text hides its target, it uses the focused pane of the session the
app last focused.

The last-focused session comes from the Rex app's preferences
(`Workspace.lastFocusedSession` in `com.superlogical.rex`). That key is undocumented. If a
Rex update removes it, clicks on visible paths still work and hidden-target links fall
back to the previous opener.

Run inside a Rex pane, `node config/rex/opener/open.mjs FILE` skips the search and opens the
preview beside that pane.

## Picking a file from the screen

**Ctrl-Cmd-O** (Caps Lock-Cmd-O) opens a floating list of the files named on the focused
pane's screen, most recent first, with a preview beside it. Click an entry, or type to
filter and press Enter; Esc cancels. Markdown opens in Glow and everything else in nvim,
at the line number if the path had one. It is also in the command palette as "Open File
from Pane…". The key is bound at the end of `../init.lua`.

It needs fzf, and uses bat for the preview when it is installed. It does not go through
macOS, so it works for any file type, including the scripts Rex will not Cmd-click.

A relative path is tried against, in order: the pane's working directory; any directory
named by an absolute path on screen, and its parents, which catches the current directory
an agent shows in its status line; and, for a path with a slash, the directories up to two
levels below the working directory. If it exists in several, up to three are listed. A
path the program broke across two lines is rejoined when the first line reaches the
pane's edge.

It only sees what is on screen now, not what has scrolled away in a full-screen program.
It misses paths that contain spaces and links whose text hides their target.

## Files

| File | Purpose |
| --- | --- |
| `Handler.swift` | The macOS app: decides whether Rex asked, then previews or passes on. |
| `open.mjs` | Validates the file, finds the pane, then launches Glow or nvim beside it. |
| `bridge.mjs` | Handled types, pane search, launch arguments, the shared nvim pane, Glow refresh. |
| `pick`, `pick.mjs` | The picker: lists the files named on a pane's screen and opens one. |
| `install.mjs` | Builds and registers the app and writes its configuration; also removes it. |
| `bridge.test.mjs` | Tests for the above with a simulated Rex. |

## Verification and troubleshooting

```sh
node --test config/rex/opener/bridge.test.mjs
```

Every request is recorded in `~/Library/Application Support/Rex Opener/handler.log` as
`preview` or `pass`, with the app it came from, followed by the opener's output. If a
click opens the previous opener instead of a Rex pane, the log says why.

### Automatic startup refresh for Glow 3.0.0

Rex creates a pane at 80×24 and resizes it a moment later. Glow's
[initial file-render path][glow-startup] renders the text without storing it in
`currentDocument.Body`, and its [resize handler][glow-resize] then redraws from that empty
body, so the preview goes blank. Pressing **r** uses the normal file-loading path, which
fills the cache and makes later resizes work.

The opener waits for the new preview's alternate-screen document UI, verifies that the
configured Glow executable is still its foreground process, and sends **r once to that
new pane only**. It never sends input to any other pane or changes focus. Readiness
polling is limited to 50 checks over a five-second window. If the refresh cannot run
safely, the preview stays open, the log records the failure, and **r** still works by hand.

[glow-startup]: https://github.com/charmbracelet/glow/blob/v3.0.0/ui/ui.go#L151-L175
[glow-resize]: https://github.com/charmbracelet/glow/blob/v3.0.0/ui/pager.go

## Remove

```sh
node config/rex/opener/install.mjs remove
```

This makes each type's previous opener its default again, unregisters and deletes the
app, and deletes its support directory.
