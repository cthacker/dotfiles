import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import {
  mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, rmSync, statSync, writeFileSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import test from "node:test";
import { lexer } from "marked";
import {
  create_tickets, glow_arguments, read_ticket, refresh_preview,
  resolve_markdown_path, rewrite_markdown,
} from "./bridge.mjs";

const context = {
  session: "session:1234-abcd", block: "block:5678-abcd", server: "unix:///tmp/rex.sock",
};

function test_fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), "rex-glow-"));
  const file = join(directory, "Review 🐕 (draft).md");
  writeFileSync(file, "# A review\n");
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return { directory, file };
}

test("resolves existing local Markdown paths without guessing missing absolute paths", (t) => {
  const { directory, file } = test_fixture(t);
  const name = "Review 🐕 (draft).md";
  for (const href of [
    name, name.replaceAll("(", "\\(").replaceAll(")", "\\)"),
    encodeURIComponent(name), file, pathToFileURL(file).href,
    `${encodeURIComponent(name)}#notes`,
  ]) assert.equal(resolve_markdown_path(href, directory), file, href);
  mkdirSync(join(directory, ".reviews"));
  writeFileSync(join(directory, ".reviews", "a.md"), "# Local");
  assert.equal(resolve_markdown_path("/.reviews/a.md", directory), undefined);
});

test("leaves remote, missing, malformed, non-Markdown and directory targets unchanged", (t) => {
  const { directory } = test_fixture(t);
  mkdirSync(join(directory, "folder.md"));
  writeFileSync(join(directory, "not-md.txt"), "text");
  for (const href of [
    "https://example.com/a.md", "//example.com/a.md", "file://remote/a.md",
    "rex-glow://open/foo", "missing.md", "bad%xx.md", "folder.md", "not-md.txt",
    "#section", "file:///tmp/a%00.md",
  ]) assert.equal(resolve_markdown_path(href, directory), undefined, href);
});

test("rewrites links, references and exact inline-code paths, but not fenced examples", (t) => {
  const { directory, file } = test_fixture(t);
  const rewrite = (source) => rewrite_markdown(source, lexer(source),
    (href) => resolve_markdown_path(href, directory) ? "rex-glow://open/test" : undefined);
  const url = pathToFileURL(file).href;
  const source = `[**Review**](<${file}> "draft") and [web](https://example.com/a.md).`;
  assert.equal(rewrite(source),
    '[**Review**](rex-glow://open/test "draft") and [web](https://example.com/a.md).');
  assert.equal(rewrite(`\`${file}\``), `[\`${file}\`](rex-glow://open/test)`);
  assert.match(rewrite(`[ref][report]\n\n[report]: ${url}\n`),
    /\[ref\]\(rex-glow:\/\/open\/test\)/);
  for (const code of [
    `\`[review](${url})\``, `\`cat ${file}\``,
    `\`\`\`md\n[review](${url})\n\`\`\``, `    [review](${url})\n`,
    `![image](${url})`, `<pre>\n[review](${url})\n</pre>\n`, `[review](${url}`,
  ]) assert.equal(rewrite(code), code);
});

test("preserves headings, quotes, lists and tables around links", () => {
  const source = "# [a](a.md)\n\n- **[b](b.md)**\n\n> [c](c.md)\n\n" +
    "| name |\n| --- |\n| [d](d.md) |\n";
  const result = rewrite_markdown(source, lexer(source), () => "rex-glow://open/test");
  assert.equal((result.match(/rex-glow:\/\/open\/test/g) ?? []).length, 4);
  for (const prefix of ["> ", "- ", "- [ ] "]) {
    const continuation = prefix.startsWith(">") ? "> " : "  ";
    const text = `${prefix}First\n${continuation}[link](a.md)\n`;
    assert.equal(rewrite_markdown(text, lexer(text), () => "rex-glow://open/test"),
      text.replace("[link](a.md)", "[link](rex-glow://open/test)"));
  }
});

test("tickets are opaque, stable, private, bounded and revoked on close", (t) => {
  const { directory, file } = test_fixture(t);
  const registry = join(directory, "tickets");
  const tickets = create_tickets(context, registry);
  const url = tickets.link(file);
  assert.match(url, /^rex-glow:\/\/open\/[a-f0-9]{64}$/);
  assert.equal(tickets.link(file), url);
  assert.equal(statSync(registry).mode & 0o777, 0o700);
  assert.equal(statSync(join(registry, readdirSync(registry)[0])).mode & 0o777, 0o600);
  assert.deepEqual(read_ticket(url, registry), { ...context, path: file });
  for (let i = 1; i < 2000; i++) tickets.link(`/tmp/${i}.md`);
  assert.equal(tickets.link("/tmp/overflow.md"), undefined);
  tickets.close();
  tickets.close();
  assert.throws(() => read_ticket(url, registry), { code: "ENOENT" });
});

test("rejects traversal, unknown tickets, deleted files and invalid destinations", (t) => {
  const { directory, file } = test_fixture(t);
  const registry = join(directory, "tickets");
  const url = create_tickets(context, registry).link(file);
  for (const invalid of [
    "https://example.com", "rex-glow://open/../../etc/passwd",
    `${url}?path=/tmp/a.md`, `${url}#x`, "rex-glow://open/" + "0".repeat(64),
  ]) assert.throws(() => read_ticket(invalid, registry));
  const record = join(registry, readdirSync(registry)[0]);
  for (const changes of [
    { session: "$(touch /tmp/pwn)" }, { block: "--help" }, { server: "https://remote" },
    { path: "relative.md" }, { path: join(directory, "missing.md") },
  ]) {
    writeFileSync(record, JSON.stringify({ ...context, path: file, ...changes }));
    assert.throws(() => read_ticket(url, registry));
  }
  assert.equal(readFileSync(file, "utf8"), "# A review\n");
});

test("launches Glow with literal argv, correct origin and no shell or focus stealing", () => {
  const file = "/tmp/$(touch hacked); review.md";
  const args = glow_arguments({ ...context, path: file }, "/opt/homebrew/bin/glow");
  assert.equal(args.at(-1), file);
  assert.equal(args[args.indexOf("--session") + 1], context.session);
  assert.equal(args[args.indexOf("--block") + 1], context.block);
  assert.equal(args[args.indexOf("--cwd") + 1], "/tmp");
  assert.ok(args.includes("--shell=none"));
  assert.ok(args.includes("--focus=false"));
  assert.ok(args.includes("--autostart=false"));
  assert.equal(args[args.indexOf("--") + 1], "/opt/homebrew/bin/glow");
  assert.deepEqual(args.slice(-2), ["--", file]);
});

test("Pi display hook activates only in Rex TUI and revokes links at shutdown", async (t) => {
  const { directory, file } = test_fixture(t);
  const { default: extension } = await import("./index.ts");
  const handlers = new Map();
  const notices = [];
  const saved = { session: process.env.REX_SESSION, block: process.env.REX_BLOCK };
  process.env.REX_SESSION = context.session;
  process.env.REX_BLOCK = context.block;
  t.after(() => {
    for (const [key, value] of [
      ["REX_SESSION", saved.session], ["REX_BLOCK", saved.block],
    ]) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
    handlers.get("session_shutdown")?.();
  });
  let transform;
  await extension({
    registerMarkdownTransformer(fn) { transform = fn; },
    on(name, fn) { handlers.set(name, fn); },
    exec: async () => ({
      code: 0, stdout: JSON.stringify({
        endpoint: context.server, session_id: context.session, block_id: context.block,
      }),
    }),
  });
  const source = `[review](${pathToFileURL(file).href})`;
  assert.equal(transform(source, { messageType: "assistant" }), source);
  const ctx = { mode: "tui", cwd: directory, ui: { notify: (...args) => notices.push(args) } };
  await handlers.get("session_start")({}, ctx);
  assert.deepEqual(notices, []);
  const rendered = transform(source, { messageType: "assistant" });
  const url = /rex-glow:\/\/open\/[a-f0-9]{64}/.exec(rendered)?.[0];
  assert.ok(url);
  assert.equal(read_ticket(url).path, file);
  assert.equal(transform(source, { messageType: "assistant-thinking" }), source);
  await handlers.get("session_shutdown")();
  assert.throws(() => read_ticket(url), { code: "ENOENT" });
  assert.equal(transform(source, { messageType: "assistant" }), source);
  await handlers.get("session_start")({}, { ...ctx, mode: "rpc" });
  assert.equal(transform(source, { messageType: "assistant" }), source);
  assert.equal(readFileSync(file, "utf8"), "# A review\n");
});

test("refresh waits for Glow's document screen and sends r once to only the new pane", async () => {
  const created = { anchor_id: context.block, block_ids: ["block:abcd-1234"] };
  const calls = [];
  let stage = 0;
  await refresh_preview((args) => {
    calls.push(args);
    if (args.at(-1) === "modes") {
      return JSON.stringify({ screen: stage ? "alternate" : "primary" });
    }
    if (args[0] === "capture") return stage > 1 ? " Glow  test.md  100%  ? Help\n" : "";
    if (args.at(-1) === "process") {
      return JSON.stringify({
        child: { pid: 123 }, foreground: { pid: 123, path: realpathSync(process.execPath) },
        last_exit: null,
      });
    }
    assert.equal(args[0], "send-key");
    return "";
  }, context, created, process.execPath, async (ms) => {
    assert.equal(ms, 100);
    stage++;
  });
  assert.equal(stage, 2);
  assert.equal(calls.filter((args) => args[0] === "send-key").length, 1);
  assert.equal(calls.at(-1).at(-1), "r");
  for (const args of calls) {
    assert.equal(args[args.indexOf("--session") + 1], context.session);
    assert.equal(args[args.indexOf("--block") + 1], created.block_ids[0]);
    assert.ok(!args.includes(context.block));
  }
});

test("refresh refuses an origin pane or an unexpected launch result", async () => {
  for (const created of [
    { anchor_id: context.block, block_ids: [context.block] },
    { anchor_id: "block:dead", block_ids: ["block:abcd"] },
    { anchor_id: context.block, block_ids: ["block:abcd", "block:bcde"] },
    { anchor_id: context.block, block_ids: ["--help"] },
    {},
  ]) {
    await assert.rejects(refresh_preview(() => assert.fail("Rex must not be called"),
      context, created, process.execPath), /unverified preview/);
  }
});

test("refresh does not type into another process or a finished Glow pane", async () => {
  for (const state of [
    { child: { pid: 123 }, foreground: { pid: 123, path: "/bin/zsh" }, last_exit: null },
    { child: { pid: 123 }, foreground: { pid: 456, path: process.execPath }, last_exit: null },
    { child: { pid: 123 }, foreground: null, last_exit: { exit_code: 0 } },
  ]) {
    await assert.rejects(refresh_preview((args) => {
      assert.notEqual(args[0], "send-key");
      if (args.at(-1) === "modes") return '{"screen":"alternate"}';
      if (args[0] === "capture") return " Glow  test.md  100%  ? Help";
      return JSON.stringify(state);
    }, context, { anchor_id: context.block, block_ids: ["block:abcd"] }, process.execPath),
    /expected Glow process/);
  }
});

test("refresh stops if the preview disappears", async () => {
  let calls = 0;
  await assert.rejects(refresh_preview(() => {
    calls++;
    throw new Error("block not found");
  }, context, { anchor_id: context.block, block_ids: ["block:abcd"] }, process.execPath),
  /block not found/);
  assert.equal(calls, 1);
});

test("refresh readiness polling is bounded and never types before the UI is ready", async () => {
  let polls = 0;
  let waits = 0;
  await assert.rejects(refresh_preview((args) => {
    assert.equal(args.at(-1), "modes");
    polls++;
    return '{"screen":"primary"}';
  }, context, { anchor_id: context.block, block_ids: ["block:abcd"] }, process.execPath,
  async () => { waits++; }), /did not become ready/);
  assert.equal(polls, 50);
  assert.equal(waits, 50);
});

test("refresh does not retry a failed key delivery", async () => {
  let deliveries = 0;
  await assert.rejects(refresh_preview((args) => {
    if (args.at(-1) === "modes") return '{"screen":"alternate"}';
    if (args[0] === "capture") return " Glow  test.md  100%  ? Help";
    if (args.at(-1) === "process") return JSON.stringify({
      child: { pid: 123 }, foreground: { pid: 123, path: realpathSync(process.execPath) },
      last_exit: null,
    });
    deliveries++;
    throw new Error("write failed");
  }, context, { anchor_id: context.block, block_ids: ["block:abcd"] }, process.execPath),
  /write failed/);
  assert.equal(deliveries, 1);
});

test("packaged Pi loads the extension without borrowed host dependencies", () => {
  const env = { ...process.env };
  delete env.NODE_PATH;
  const result = spawnSync(process.env.PI_BIN ?? join(homedir(), ".pi", "agent", "bin", "pi"), [
    "--offline", "--no-extensions",
    "-e", fileURLToPath(new URL("./index.ts", import.meta.url)), "--help",
  ], { env, encoding: "utf8", timeout: 15000 });
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(result.stderr, /Failed to load extension|Cannot find module/);
  assert.match(result.stdout, /Usage:/);
});

test("dispatcher rejects an unregistered URL before invoking Rex", () => {
  assert.throws(() => execFileSync(process.execPath, [
    new URL("./open.mjs", import.meta.url).pathname, "rex-glow://open/../../tmp/a",
  ], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
  (error) => error.status === 1 && error.stderr.includes("Invalid Rex Glow link"));
});
