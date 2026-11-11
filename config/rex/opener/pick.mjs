import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";
import { MARKDOWN, open_in_editor, SUPPORT_DIRECTORY } from "./bridge.mjs";

const [session, block, mode] = process.argv.slice(2);
const { rex, nvim } = JSON.parse(readFileSync(join(SUPPORT_DIRECTORY, "programs.json"), "utf8"));
const server = process.env.REX_SERVER;
const call = (args) => execFileSync(rex, [
  ...(server ? ["--server", server] : []), "--autostart=false", "--timeout", "2s", ...args,
], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024, stdio: ["ignore", "pipe", "pipe"] });
const fail = async (message) => {
  process.stdout.write(`\n  ${message}\n`);
  await delay(1800);
  process.exit(1);
};

const home = homedir();
const target = ["--session", session, "--block", block];
const cwd = JSON.parse(call(["block", "call", ...target, "process"])).foreground?.cwd ?? home;
const { columns } = JSON.parse(call(["block", "call", ...target, "size"]));
const rows = call(["capture", ...target, "--trim", "--unwrap"]).split("\n").slice(-300)
  .map((text) => ({
    full: text.length >= columns - 2,
    tokens: text.split(/[\s"'`()<>[\]{}|,;=]+/).filter(Boolean),
  }));

const kind = (path) => {
  try {
    const stats = statSync(path);
    return stats.isFile() ? "file" : stats.isDirectory() ? "directory" : undefined;
  } catch {
    return undefined;
  }
};
const parse = (token) => {
  const [, name, line] = /^(.+?)(?::(\d+)(?::\d+)?)?$/.exec(token.replace(/[.,:;!?]+$/, "")) ?? [];
  if (!name || !/[/.]/.test(name) || name.includes("://")) return undefined;
  return { name: name.startsWith("~/") ? join(home, name.slice(2)) : name, line };
};

const mentions = [];
for (let index = rows.length - 1; index >= 0; index--) {
  const { full, tokens } = rows[index];
  const wrapped = full && tokens.at(-1) && rows[index + 1]?.tokens[0]
    ? [tokens.at(-1) + rows[index + 1].tokens[0]] : [];
  for (const token of [...tokens, ...wrapped]) {
    const mention = parse(token);
    if (mention) mentions.push(mention);
  }
}

const shown = new Set();
for (const { name } of mentions) {
  if (!isAbsolute(name)) continue;
  const found = kind(name);
  for (let path = found === "file" ? dirname(name) : found ? name : "";
    path.startsWith(`${home}/`) && path !== cwd; path = dirname(path)) shown.add(path);
}
const skipped = (name) => name.startsWith(".") || name === "node_modules";
const below = (directory) => {
  try {
    return readdirSync(directory, { withFileTypes: true })
      .filter((entry) => entry.isDirectory() && !skipped(entry.name))
      .map((entry) => join(directory, entry.name));
  } catch {
    return [];
  }
};
const children = below(cwd);
const nearby = [...children, ...children.flatMap(below)];

const choices = new Map();
for (const { name, line } of mentions) {
  const names = [...new Set([name, name.replace(/^[ab]\//, "")])];
  const bases = isAbsolute(name) ? [""]
    : [cwd, ...shown, ...(name.includes("/") ? nearby : [])];
  const paths = new Set();
  for (const base of bases) {
    for (const candidate of names) {
      const path = resolve(base, candidate);
      if (kind(path) === "file") paths.add(path);
    }
    if (paths.size >= 3) break;
  }
  for (const path of paths) {
    const inside = relative(cwd, path);
    const label = (inside.startsWith("..") ? path.replace(home, "~") : inside) +
      (line ? `:${line}` : "");
    if (!choices.has(label)) choices.set(label, `${path}\t${line ?? 0}\t${label}`);
  }
}
if (mode === "--list") {
  process.stdout.write([...choices.keys()].join("\n") + "\n");
  process.exit(0);
}
if (!choices.size) await fail("No file paths on this pane's screen.");

const fzf = ["/opt/homebrew/bin/fzf", "/usr/local/bin/fzf", "/usr/bin/fzf"].find(existsSync);
if (!fzf) await fail("fzf is not installed.");
const bat = ["/opt/homebrew/bin/bat", "/usr/local/bin/bat", "/usr/bin/bat"].find(existsSync);
const show = `'${bat}' --color=always --style=numbers`;
const preview = bat
  ? `if [ {2} -gt 0 ]; then ${show} --highlight-line {2} -- {1}; else ${show} -- {1}; fi`
  : "head -n 500 -- {1}";
const picked = spawnSync(fzf, [
  "--delimiter", "\t", "--with-nth", "3", "--reverse", "--no-sort", "--prompt", "open > ",
  "--header", "click or Enter · Esc cancels", "--bind", "left-click:accept",
  "--preview", preview, "--preview-window", "right,55%,+{2}/2",
], { input: [...choices.values()].join("\n"), encoding: "utf8", stdio: ["pipe", "pipe", "inherit"] });
const [path, line] = picked.stdout.trim().split("\t");
if (picked.status !== 0 || !path) process.exit(0);

try {
  if (MARKDOWN.some((extension) => path.toLowerCase().endsWith(`.${extension}`))) {
    execFileSync(process.execPath, [join(dirname(fileURLToPath(import.meta.url)), "open.mjs"), path], {
      env: { ...process.env, REX_SESSION: session, REX_BLOCK: block },
      stdio: ["ignore", "ignore", "pipe"], encoding: "utf8",
    });
  } else {
    const launch = (args) => execFileSync(rex, args,
      { stdio: ["ignore", "ignore", "pipe"], encoding: "utf8" });
    open_in_editor({ call, launch, nvim }, { server, session, block, path }, cwd, Number(line));
  }
} catch (error) {
  await fail(error.stderr?.trim() || error.message);
}
