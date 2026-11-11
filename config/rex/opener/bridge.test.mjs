import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import test from "node:test";
import {
  editor_arguments, editor_expression, find_origin, glow_arguments, read_target, refresh_preview,
} from "./bridge.mjs";

const context = {
  session: "session:1234-abcd", block: "block:5678-abcd", server: "unix:///tmp/rex.sock",
};

function test_fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), "rex-opener-"));
  const file = join(directory, "Review 🐕 (draft).md");
  writeFileSync(file, "# A review\n");
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return { directory, file };
}

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

test("uses the default local server when the origin names none", () => {
  const args = glow_arguments({ session: context.session, block: context.block, path: "/tmp/a.md" },
    "/opt/homebrew/bin/glow");
  assert.deepEqual(args.slice(0, 2), ["--autostart=false", "run"]);
});

test("opens the editor through the interactive shell, focused, in the origin's directory", () => {
  const file = "/work/src/$(touch hacked) app.py";
  const args = editor_arguments({ ...context, path: file }, "/opt/homebrew/bin/nvim", "/work");
  assert.equal(args[args.indexOf("--cwd") + 1], "/work");
  assert.equal(args[args.indexOf("--block") + 1], context.block);
  assert.ok(args.includes("--interactive"));
  assert.ok(!args.includes("--focus=false"));
  assert.deepEqual(args.slice(-4), ["--", "/opt/homebrew/bin/nvim", "--", file]);
});

test("the editor can start at a line and listen for later files", () => {
  const args = editor_arguments({ ...context, path: "/work/app.py" }, "/bin/nvim", "/work",
    { line: 42, listen: "/tmp/tab.sock" });
  assert.deepEqual(args.slice(-6),
    ["/bin/nvim", "--listen", "/tmp/tab.sock", "+42", "--", "/work/app.py"]);
});

test("a later file is sent to the running editor with its path quoted for Vim", () => {
  assert.equal(editor_expression("/work/it's $(x).py", 7),
    "[execute('edit +7 ' .. fnameescape('/work/it''s $(x).py')), getenv('REX_BLOCK')][1]");
  assert.equal(editor_expression("/work/a.py"),
    "[execute('edit ' .. fnameescape('/work/a.py')), getenv('REX_BLOCK')][1]");
});

test("accepts file URLs and paths for existing files of a handled type only", (t) => {
  const { directory, file } = test_fixture(t);
  for (const name of ["page.html", "tool.LUA", "notes.md.bak"]) {
    writeFileSync(join(directory, name), "text");
  }
  assert.deepEqual(read_target(pathToFileURL(file).href), { path: file, viewer: "glow" });
  assert.deepEqual(read_target(file), { path: file, viewer: "glow" });
  assert.deepEqual(read_target(join(directory, "tool.LUA")),
    { path: join(directory, "tool.LUA"), viewer: "nvim" });
  for (const invalid of ["page.html", "notes.md.bak", "missing.md", "."]) {
    assert.throws(() => read_target(join(directory, invalid)));
  }
});

function fake_rex(screens) {
  const sessions = [...new Set(Object.keys(screens).map((key) => key.split("/")[0]))];
  return (args) => {
    if (args[0] === "client") {
      return JSON.stringify({ clients: [
        { info: { kind: "cli" }, session_ids: ["session:cli"] },
        { info: { kind: "app" }, session_ids: sessions },
      ] });
    }
    const session = args[args.indexOf("--session") + 1];
    const blocks = Object.keys(screens).filter((key) => key.startsWith(`${session}/`))
      .map((key) => ({ block_id: key.split("/")[1] }));
    if (args[0] === "api") {
      return JSON.stringify({ active_window_id: "window:1", windows: [
        { window_id: "window:0", focused_block_id: "block:hidden", layers: [] },
        { window_id: "window:1", focused_block_id: blocks[0].block_id, layers: [{ blocks }] },
      ] });
    }
    const screen = screens[`${session}/${args[args.indexOf("--block") + 1]}`];
    if (screen === undefined) throw new Error("block not found");
    return screen;
  };
}

test("finds the pane that shows the file, preferring the session the app last focused", () => {
  const run = fake_rex({
    "session:a/block:a1": "$ ls", "session:a/block:a2": "see docs/plan.md",
    "session:b/block:b1": "nothing", "session:b/block:b2": "open plan.md here",
  });
  assert.deepEqual(find_origin(run, "/work/docs/plan.md", undefined),
    { session: "session:a", block: "block:a2" });
  assert.deepEqual(find_origin(run, "/work/docs/plan.md", "session:b"),
    { session: "session:b", block: "block:b2" });
});

test("falls back to the app's focused pane, and fails when there is no such pane", () => {
  const run = fake_rex({ "session:a/block:a1": "$ ls", "session:b/block:b1": "a link" });
  assert.deepEqual(find_origin(run, "/work/plan.md", "session:b"),
    { session: "session:b", block: "block:b1" });
  assert.throws(() => find_origin(run, "/work/plan.md", undefined), /No Rex pane/);
  assert.throws(() => find_origin(run, "/work/plan.md", "session:closed"), /No Rex pane/);
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

test("opener rejects anything it does not handle before invoking Rex", () => {
  for (const target of ["/etc/hosts", "rex-opener://open/abc", "missing.md", ""]) {
    assert.throws(() => execFileSync(process.execPath, [
      new URL("./open.mjs", import.meta.url).pathname, target,
    ], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
    (error) => error.status === 1 && /Not a file Rex Opener opens|ENOENT/.test(error.stderr));
  }
});
