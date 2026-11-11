import { execFileSync } from "node:child_process";
import { mkdirSync, realpathSync, rmSync, statSync } from "node:fs";
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

export function open_in_editor({ call, launch, nvim }, origin, cwd, line) {
  const view = JSON.parse(call(["api", "call", "--session", origin.session, "session.view", "{}"]));
  const window = view.windows.find((item) => item.layers.some(
    (layer) => (layer.blocks ?? []).some((block) => block.block_id === origin.block)));
  if (!window) throw new Error("The pane is no longer open");
  const listen = join("/tmp", `rex-opener-${process.getuid()}`,
    `${window.window_id.slice(-12)}.sock`);
  try {
    const block = execFileSync(nvim, [
      "--server", listen, "--remote-expr", editor_expression(origin.path, line),
    ], { timeout: 2000, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
    call(["api", "call", "--session", origin.session, "session.focus_block",
      JSON.stringify({ block_id: block })]);
    return;
  } catch {
    rmSync(listen, { force: true });
  }
  mkdirSync(dirname(listen), { recursive: true, mode: 0o700 });
  launch(editor_arguments(origin, nvim, cwd, { line, listen }));
}
