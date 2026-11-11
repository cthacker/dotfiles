import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import {
  find_origin, glow_arguments, open_in_editor, read_target, refresh_preview, SUPPORT_DIRECTORY,
} from "./bridge.mjs";

try {
  const [target = "", hint] = process.argv.slice(2);
  const { path, viewer } = read_target(target);
  const { rex, glow, nvim } = JSON.parse(
    readFileSync(join(SUPPORT_DIRECTORY, "programs.json"), "utf8"),
  );
  const { REX_SESSION: session, REX_BLOCK: block } = process.env;
  const server = session && block ? process.env.REX_SERVER : undefined;
  const rex_call = (timeout = 1500) => (args) => execFileSync(rex, [
    ...(server ? ["--server", server] : []), "--autostart=false", "--timeout", "1s", ...args,
  ], {
    timeout, encoding: "utf8", maxBuffer: 64 * 1024 * 1024, stdio: ["ignore", "pipe", "pipe"],
  });
  const origin = {
    ...(session && block ? { server, session, block } : find_origin(rex_call(), path, hint)), path,
  };
  if (!/^session:[a-f0-9-]+$/.test(origin.session) || !/^block:[a-f0-9-]+$/.test(origin.block) ||
      (origin.server && !origin.server.startsWith("unix:///"))) {
    throw new Error("Invalid Rex destination");
  }
  rex_call(10000)(["block", "inspect", origin.block, "--session", origin.session, "--json"]);
  const launch = (args) => execFileSync(rex, args, {
    timeout: 15000, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"],
  });
  if (viewer === "glow") {
    const output = launch(glow_arguments(origin, glow));
    try {
      await refresh_preview(rex_call(), origin, JSON.parse(output), glow);
    } catch (error) {
      process.stderr.write(`The Glow preview opened, but automatic refresh failed: ${error.message}. ` +
        "Press r in the preview to refresh manually.\n");
    }
    process.stdout.write(output);
  } else {
    const { foreground } = JSON.parse(rex_call()(
      ["block", "call", "--session", origin.session, "--block", origin.block, "process"]));
    open_in_editor({ call: rex_call(), launch, nvim }, origin, foreground?.cwd ?? dirname(path));
  }
} catch (error) {
  process.stderr.write(`Rex Opener: ${error.stderr?.toString().trim() || error.message}\n`);
  process.exitCode = 1;
}
