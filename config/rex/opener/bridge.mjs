import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, realpathSync, rmSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

export const SUPPORT_DIRECTORY = join(homedir(), "Library", "Application Support", "Rex Opener");

export const MARKDOWN = ["md", "markdown"];
export const CODE = [
  "py", "json", "yaml", "yml", "toml", "sh", "zsh", "c", "h", "cpp", "swift", "rb", "go", "rs",
  "lua", "js", "mjs", "ts", "tsx", "css", "sql", "ipynb", "txt",
];

export function read_target(target) {
  const path = target.startsWith("file:") ? fileURLToPath(target) : resolve(target);
  const extension = extname(path).slice(1).toLowerCase();
  const viewer = MARKDOWN.includes(extension) ? "glow" : CODE.includes(extension) && "nvim";
  if (!viewer || path.includes("\0") || !statSync(path).isFile()) {
    throw new Error("Not a file Rex Opener opens");
  }
  return { path, viewer };
}

export function find_origin(run, path, hint) {
  const name = basename(path);
  const sessions = [...new Set(JSON.parse(run(["client", "ls", "--json"])).clients
    .filter((client) => client.info?.kind === "app")
    .flatMap((client) => client.session_ids ?? []))];
  if (sessions.includes(hint)) sessions.unshift(...sessions.splice(sessions.indexOf(hint), 1));
  let focused;
  for (const session of sessions) {
    const view = JSON.parse(run(["api", "call", "--session", session, "session.view", "{}"]));
    const window = view.windows.find((item) => item.window_id === view.active_window_id);
    if (!window?.focused_block_id) continue;
    if (session === hint) focused = { session, block: window.focused_block_id };
    const blocks = new Set([window.focused_block_id, ...window.layers.flatMap(
      (layer) => (layer.blocks ?? []).map((block) => block.block_id))]);
    for (const block of blocks) {
      let screen;
      try {
        screen = run(["capture", "--session", session, "--block", block, "--trim", "--unwrap"]);
      } catch {
        continue;
      }
      if (screen.split("\n").slice(-200).join("\n").includes(name)) return { session, block };
    }
  }
  if (focused) return focused;
  throw new Error("No Rex pane is showing this file");
}

export async function refresh_preview(run, origin, created, glow, wait = delay) {
  const block = created.block_ids?.[0];
  if (created.anchor_id !== origin.block || created.block_ids?.length !== 1 ||
      block === origin.block || !/^block:[a-f0-9-]+$/.test(block)) {
    throw new Error("Refusing to refresh an unverified preview pane");
  }
  const target = ["--session", origin.session, "--block", block];
  const executable = realpathSync(glow);
  const deadline = Date.now() + 5000;
  for (let attempt = 0; attempt < 50 && Date.now() < deadline; attempt++) {
    const modes = JSON.parse(run(["block", "call", ...target, "modes"]));
    if (modes.screen === "alternate") {
      const screen = run(["capture", ...target, "--trim"]);
      if (/\bGlow\b[^\n]*\?\s*Help/.test(screen)) {
        const state = JSON.parse(run(["block", "call", ...target, "process"]));
        if (!state.child || state.last_exit ||
            state.foreground?.pid !== state.child.pid ||
            state.foreground?.path !== executable) {
          throw new Error("The preview is no longer running the expected Glow process");
        }
        run(["send-key", ...target, "r"]);
        return;
      }
    }
    await wait(100);
  }
  throw new Error("Glow did not become ready for its startup refresh");
}

function run_arguments(origin, options, command) {
  return [
    ...(origin.server ? ["--server", origin.server] : []), "--autostart=false", "run",
    "--session", origin.session, "--block", origin.block, "--split", "right", ...options,
    "--json", "--", ...command,
  ];
}

export function glow_arguments(origin, glow) {
  return run_arguments(origin, [
    "--ratio", "45", "--focus=false", "--shell=none", "--cwd", dirname(origin.path),
    "--label", "Markdown · Glow",
  ], [glow, "--tui", "--config", join(SUPPORT_DIRECTORY, "glow.yml"), "--", origin.path]);
}

export function editor_arguments(origin, nvim, cwd, { line, listen } = {}) {
  return run_arguments(origin, ["--interactive", "--cwd", cwd, "--label", "nvim"], [
    nvim, ...(listen ? ["--listen", listen] : []), ...(line ? [`+${line}`] : []),
    "--", origin.path,
  ]);
}

export function editor_expression(path, line) {
  const file = `fnameescape('${path.replaceAll("'", "''")}')`;
  return `[execute('edit ${line ? `+${line} ` : ""}' .. ${file}), getenv('REX_BLOCK')][1]`;
}

const pause = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);

// Sends the file to the tab's nvim and returns that nvim's pane, or undefined when no nvim is
// listening there. A listening nvim that fails or is too slow is an error, not a missing editor:
// starting another one would leave the first unreachable.
export function send_to_editor(nvim, listen, path, line) {
  try {
    return execFileSync(nvim, ["--server", listen, "--remote-expr", editor_expression(path, line)],
      { timeout: 5000, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
  } catch (error) {
    if (/\bE247:/.test(error.stderr ?? "")) return undefined;
    const reason = error.stderr?.trim() || error.message;
    throw new Error(`The tab's nvim did not open the file: ${reason}`);
  }
}

// One open at a time per tab, so two quick opens cannot each start an editor. A lock left by
// an opener that died is not taken over automatically, since two openers could then both take
// it; the error names it so it can be removed by hand (it is in /tmp, so a restart clears it).
function with_lock(lock, work, wait) {
  for (let waited = 0; ; waited += 100) {
    try {
      mkdirSync(lock);
      break;
    } catch (error) {
      if (error.code !== "EEXIST") throw error;
      if (waited >= 20000) {
        throw new Error(
          `Another file is still being opened in this tab; if none is, remove ${lock}`);
      }
      wait(100);
    }
  }
  try {
    return work();
  } finally {
    rmSync(lock, { recursive: true, force: true });
  }
}

const SOCKETS = join("/tmp", `rex-opener-${process.getuid()}`);

export function open_in_editor({ call, launch, nvim, sockets = SOCKETS }, origin, cwd, line,
  wait = pause) {
  const view = JSON.parse(call(["api", "call", "--session", origin.session, "session.view", "{}"]));
  const window = view.windows.find((item) => item.layers.some(
    (layer) => (layer.blocks ?? []).some((block) => block.block_id === origin.block)));
  if (!window) throw new Error("The pane is no longer open");
  const listen = join(sockets, `${window.window_id.slice(-12)}.sock`);
  mkdirSync(dirname(listen), { recursive: true, mode: 0o700 });
  const block = with_lock(`${listen}.lock`, () => {
    const running = send_to_editor(nvim, listen, origin.path, line);
    if (running) return running;
    rmSync(listen, { force: true });
    launch(editor_arguments(origin, nvim, cwd, { line, listen }));
    // Hold the lock until the new nvim listens, so the next open reaches it. An nvim that takes
    // longer than this to start (a very slow shell) could still see a second one started.
    for (let waited = 0; waited < 15000 && !existsSync(listen); waited += 100) wait(100);
    if (!existsSync(listen)) throw new Error("nvim did not start listening within 15 seconds");
    return undefined;
  }, wait);
  if (!block) return;
  try {
    call(["api", "call", "--session", origin.session, "session.focus_block",
      JSON.stringify({ block_id: block })]);
  } catch (error) {
    process.stderr.write(`Opened in nvim, but could not focus its pane: ${error.message}\n`);
  }
}
