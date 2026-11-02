# Rex Glow for Pi

Cmd-click an existing local Markdown link in Pi to open Glow in a pane to the right of
the originating Pi terminal. Rex's current focus is preserved. Click the preview to
scroll or use its keyboard controls; **q** closes it, **r** reloads, and **?** shows help.

This adapts the display-link and URL-ticket approach from
[Rex Markdown for Pi](https://github.com/jal-co/jalco-dotfiles/tree/main/tools/rex-markdown).
It uses the already-installed Glow instead of terminal-browser. No browser engine,
HTTP listener, or persistent background bridge is installed.

## Scope

- Recognizes Markdown links and inline-code spans containing an exact, existing local
  `.md` or `.markdown` path. Handles relative paths, absolute paths, `~/`, and local
  `file:` URLs, including encoded filenames.
- Relative paths resolve against Pi's working directory. Missing paths are not guessed.
- Leaves web links, fenced code, images, thinking blocks, and non-Markdown links alone.
  Bare unformatted text paths still use Rex's usual detection and macOS opener.
- Only changes Pi's displayed Markdown, not saved messages or model context.
- Does not change the macOS Markdown association, Rex keybindings, or normal web opening.
- Opens a fresh pane per click; it does not reuse an existing preview.
- Does not navigate to Markdown fragment anchors or line numbers.
- Works only in a local macOS Rex TUI, not SSH, RPC, or print-mode Pi.

## Install or refresh

Requires macOS, Rex, Glow, Node/npm, Xcode command-line tools, and Pi with
`registerMarkdownTransformer`. Tested with packaged Pi 1.5.0, Glow 3.0.0, and Node 24.
The tests use native TypeScript loading and require Node 22.18 or newer.

From the dotfiles repository:

```sh
node config/pi/extensions/rex-glow/install.mjs
```

The installer runs `npm ci --ignore-scripts --no-audit --no-fund` in this directory.
It installs exactly one runtime dependency, **marked 18.0.11**, locally under
`node_modules/`, using `package-lock.json`. It does not install npm packages globally.
Normal npm cache/log files may also be updated. The parser is owned by this extension;
resolving it through Pi\'s private bundled modules does not work in packaged Pi.

Then run **/reload** in Pi. Existing transcript messages get fresh display links.

The installer creates:

- `~/.pi/agent/extensions/rex-glow`: symlink to this source directory.
- `~/Applications/Rex Glow.app`: locally compiled, ad-hoc-signed URL handler for
  `rex-glow:` only. It exits when each launch completes.
- `~/Library/Application Support/Rex Glow/`: installed executable paths, dedicated
  Glow configuration, handler log, and private link-ticket files.

The installer records the current Node, Rex and Glow paths. Run it again if an upgrade
removes one of those executables or if this source directory moves.

## Files

| File | Purpose |
| --- | --- |
| `index.ts` | Pi extension: checks the Rex origin and registers the display transformer. |
| `bridge.mjs` | Local paths, Markdown rewriting, tickets, launch argv and guarded refresh. |
| `open.mjs` | Validates the origin, launches Glow without a shell, then refreshes it once. |
| `Handler.swift` | Small macOS URL receiver; invokes Node and records launch errors. |
| `install.mjs` | Builds/registers that receiver, writes configuration and links the extension. |
| `bridge.test.mjs` | Sixteen tests, including packaged-Pi loading and safe startup refresh. |
| `package.json` | Extension entry point, test command and pinned parser dependency. |
| `package-lock.json` | npm integrity hashes and reproducible dependency installation. |
| `.gitignore` | Keeps this extension's generated `node_modules/` out of Git. |
| `README.md` | Usage, installation, verification, limitations and removal. |

The URL contains a random 256-bit ticket, not a filename or command. Ticket files are
mode 0600 inside a mode-0700 directory. Only registered local Markdown destinations
can be opened. Each extension instance allows at most 2,000 distinct tickets and
removes its tickets at normal shutdown or reload. A hard crash can leave stale ticket
files; they are not automatically aged out. An already-closed origin cannot be opened.

## Verification and troubleshooting

After installation, run from the dotfiles repository:

```sh
npm --prefix config/pi/extensions/rex-glow test
```

The lifecycle test requires the installed macOS handler and uses a simulated Pi API.
The packaged-Pi regression test invokes `~/.pi/agent/bin/pi` (or `PI_BIN`) with
`NODE_PATH` removed, offline mode, only this extension, and `--help`. No model is called.
The other tests cover encoded names, missing paths, unchanged web links/code examples,
ticket permissions and revocation, forged URLs, shell metacharacters, and focus flags.

An additional integration check used a real packaged-Pi TUI in an isolated Rex session
with a synthetic saved conversation. Startup and `/reload` both emitted valid Glow
terminal links while preserving the control web URL. Opening the exact captured Glow
URL through macOS displayed the judge report beside that test Pi pane, preserved focus,
and closed on **q**. Pi shutdown revoked the ticket. No model requests were made, and
the temporary session and fixture were removed. macOS still reported Xcode as the
normal Markdown opener. Actual Cmd-click behavior in the current Pi conversation
requires a user check after **/reload**.

### Automatic startup refresh for Glow 3.0.0

Glow's [initial file-render path][glow-startup] renders the text without storing it in
`currentDocument.Body`. Its [resize handler][glow-resize] then redraws from that empty
body. Pressing **r** uses the normal file-loading path, which fills the cache and makes
subsequent resizes work. A controlled test reproduced blanking on resize and confirmed
that one refresh fixed later resizes.

The opener now waits for the new preview's alternate-screen document UI, verifies that
the configured Glow executable is still its foreground process, and sends **r once to
that new pane only**. It never sends input to the originating Pi pane or changes focus.
Readiness polling is limited to 50 checks over a five-second window; individual Rex
requests also have timeouts. The handler then exits, with no persistent watcher.

Three native URL launches were verified with automatic refresh and three subsequent
resizes each; all nine resizes kept the document visible. The system Glow binary is
unchanged. This workaround takes effect on the next click without reloading Pi.

If automatic refresh cannot run safely, the preview remains open and the handler log
records the failure. **r** is still available as a manual fallback.

[glow-startup]: https://github.com/charmbracelet/glow/blob/v3.0.0/ui/ui.go#L151-L175
[glow-resize]: https://github.com/charmbracelet/glow/blob/v3.0.0/ui/pager.go

If a click does nothing, check `~/Library/Application Support/Rex Glow/handler.log`.
If it opens Xcode, reload Pi and use an explicit Markdown link or an inline-code path;
bare text, tool-output paths and unsupported targets are not rewritten.

## Remove

Remove the extension symlink, unregister/delete the app, and remove its private state:

```sh
unlink "$HOME/.pi/agent/extensions/rex-glow"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/"
LSREGISTER+="LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -u "$HOME/Applications/Rex Glow.app"
rm -rf "$HOME/Applications/Rex Glow.app"
rm -rf "$HOME/Library/Application Support/Rex Glow"
```

Run **/reload** in Pi. The source in dotfiles remains available; no default file
association needs to be restored. To also remove the local parser installation, delete
`config/pi/extensions/rex-glow/node_modules/` from the dotfiles repository.
