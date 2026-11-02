import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { glow_arguments, read_ticket, refresh_preview, SUPPORT_DIRECTORY } from "./bridge.mjs";

try {
  const ticket = read_ticket(process.argv[2]);
  const { rex, glow } = JSON.parse(
    readFileSync(join(SUPPORT_DIRECTORY, "programs.json"), "utf8"),
  );
  execFileSync(rex, [
    "--server", ticket.server, "--autostart=false",
    "block", "inspect", ticket.block, "--session", ticket.session, "--json",
  ], { timeout: 10000, stdio: ["ignore", "pipe", "pipe"] });
  const output = execFileSync(rex, glow_arguments(ticket, glow), {
    timeout: 15000, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"],
  });
  try {
    await refresh_preview((args) => execFileSync(rex, [
      "--server", ticket.server, "--autostart=false", "--timeout", "1s", ...args,
    ], { timeout: 1500, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
    ticket, JSON.parse(output), glow);
  } catch (error) {
    process.stderr.write(`Rex Glow opened, but automatic refresh failed: ${error.message}. ` +
      "Press r in the preview to refresh manually.\n");
  }
  process.stdout.write(output);
} catch (error) {
  process.stderr.write(`Rex Glow: ${error.stderr?.toString().trim() || error.message}\n`);
  process.exitCode = 1;
}
