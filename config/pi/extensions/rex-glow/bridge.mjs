import { randomBytes } from "node:crypto";
import {
  mkdirSync, readFileSync, realpathSync, statSync, unlinkSync, writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, extname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

export const SUPPORT_DIRECTORY = join(homedir(), "Library", "Application Support", "Rex Glow");
export const TICKET_DIRECTORY = join(SUPPORT_DIRECTORY, "tickets");

export function resolve_markdown_path(href, cwd) {
  let path;
  try {
    if (href.startsWith("file:")) {
      const url = new URL(href);
      if (url.hostname && url.hostname !== "localhost") return;
      url.hash = "";
      url.search = "";
      path = fileURLToPath(url);
    } else {
      if (/^[a-z][a-z\d+.-]*:|^\/\//i.test(href)) return;
      path = decodeURIComponent(href.split(/[?#]/, 1)[0]).replace(/\\([\\()[\] ])/g, "$1");
      path = path.startsWith("~/") ? join(homedir(), path.slice(2)) : resolve(cwd, path);
    }
  } catch {
    return;
  }
  if (path.includes("\0") || !/\.(md|markdown)$/i.test(extname(path))) return;
  try {
    if (statSync(path).isFile()) return path;
  } catch {
    return;
  }
}

export function rewrite_markdown(source, tokens, link_for) {
  let cursor = 0;
  let result = "";
  for (const token of tokens) {
    if (!token.raw) continue;
    const start = source.indexOf(token.raw, cursor);
    if (start < 0) continue;
    let replacement = token.raw;
    if (token.type === "codespan") {
      const target = link_for(token.text);
      if (target) replacement = `[${token.raw}](${target})`;
    } else if (token.type === "link") {
      const target = link_for(token.href);
      if (target) {
        const title = token.title
          ? ` "${token.title.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"` : "";
        replacement = `[${token.text}](${target}${title})`;
      }
    } else if (token.type === "blockquote" || token.type === "list_item") {
      const raw_lines = token.raw.split("\n");
      const text_lines = token.text.split("\n");
      if (text_lines.length <= raw_lines.length &&
          text_lines.every((line, index) => raw_lines[index].endsWith(line))) {
        const rewritten = rewrite_markdown(token.text, token.tokens, link_for).split("\n");
        if (rewritten.length === text_lines.length) {
          replacement = raw_lines.map((line, index) => index < text_lines.length
            ? line.slice(0, line.length - text_lines[index].length) + rewritten[index]
            : line).join("\n");
        }
      }
    } else if (!["code", "codespan", "html", "image"].includes(token.type)) {
      const cells = token.type === "table" ? [...token.header, ...token.rows.flat()] : [];
      const children = token.tokens ?? token.items ?? cells.flatMap((cell) => cell.tokens);
      replacement = rewrite_markdown(token.raw, children, link_for);
    }
    result += source.slice(cursor, start) + replacement;
    cursor = start + token.raw.length;
  }
  return result + source.slice(cursor);
}

export function create_tickets(context, directory = TICKET_DIRECTORY) {
  const files = new Map();
  return {
    link(path) {
      if (files.has(path)) return files.get(path).url;
      if (files.size >= 2000) return;
      mkdirSync(directory, { recursive: true, mode: 0o700 });
      const token = randomBytes(32).toString("hex");
      const file = join(directory, `${token}.json`);
      writeFileSync(file, JSON.stringify({ ...context, path }), { flag: "wx", mode: 0o600 });
      const url = `rex-glow://open/${token}`;
      files.set(path, { file, url });
      return url;
    },
    close() {
      for (const { file } of files.values()) {
        try {
          unlinkSync(file);
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
        }
      }
      files.clear();
    },
  };
}

export function read_ticket(url, directory = TICKET_DIRECTORY) {
  const match = /^rex-glow:\/\/open\/([a-f0-9]{64})$/.exec(url);
  if (!match) throw new Error("Invalid Rex Glow link");
  const ticket = JSON.parse(readFileSync(join(directory, `${match[1]}.json`), "utf8"));
  if (!/^session:[a-f0-9-]+$/.test(ticket.session) || !/^block:[a-f0-9-]+$/.test(ticket.block)) {
    throw new Error("Invalid Rex destination");
  }
  if (!ticket.server?.startsWith("unix:///") || !isAbsolute(ticket.path) ||
      !/\.(md|markdown)$/i.test(ticket.path) || !statSync(ticket.path).isFile()) {
    throw new Error("The Markdown link no longer points to a local file");
  }
  return ticket;
}

export async function refresh_preview(run, ticket, created, glow, wait = delay) {
  const block = created.block_ids?.[0];
  if (created.anchor_id !== ticket.block || created.block_ids?.length !== 1 ||
      block === ticket.block || !/^block:[a-f0-9-]+$/.test(block)) {
    throw new Error("Refusing to refresh an unverified preview pane");
  }
  const target = ["--session", ticket.session, "--block", block];
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

export function glow_arguments(ticket, glow) {
  return [
    "--server", ticket.server, "--autostart=false", "run",
    "--session", ticket.session, "--block", ticket.block,
    "--split", "right", "--ratio", "45", "--focus=false", "--shell=none",
    "--cwd", dirname(ticket.path), "--json", "--label", "Markdown · Glow",
    "--", glow, "--tui", "--config", join(SUPPORT_DIRECTORY, "glow.yml"),
    "--", ticket.path,
  ];
}
