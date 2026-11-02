import { execFileSync } from "node:child_process";
import {
  lstatSync, mkdirSync, readlinkSync, symlinkSync, writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { SUPPORT_DIRECTORY, TICKET_DIRECTORY } from "./bridge.mjs";

if (process.platform !== "darwin") throw new Error("Rex Glow requires macOS");

const source = dirname(fileURLToPath(import.meta.url));
const find = (name) => execFileSync("/usr/bin/which", [name], { encoding: "utf8" }).trim();
const rex = find("rex");
const glow = find("glow");
const bundle = join(homedir(), "Applications", "Rex Glow.app");
const contents = join(bundle, "Contents");
const binary = join(contents, "MacOS", "RexGlow");
const log = join(SUPPORT_DIRECTORY, "handler.log");
const link = join(homedir(), ".pi", "agent", "extensions", "rex-glow");
const escape = (value) => value.replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");

try {
  if (!lstatSync(link).isSymbolicLink() ||
      resolve(dirname(link), readlinkSync(link)) !== source) {
    throw new Error(`Refusing to replace existing extension: ${link}`);
  }
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}

execFileSync(find("npm"), ["ci", "--ignore-scripts", "--no-audit", "--no-fund"],
  { cwd: source, stdio: "inherit" });

mkdirSync(dirname(binary), { recursive: true });
mkdirSync(TICKET_DIRECTORY, { recursive: true, mode: 0o700 });
writeFileSync(join(SUPPORT_DIRECTORY, "programs.json"),
  JSON.stringify({ rex, glow }), { mode: 0o600 });
writeFileSync(join(SUPPORT_DIRECTORY, "glow.yml"),
  "mouse: true\npager: false\nwidth: 80\nstyle: auto\n", { mode: 0o600 });
writeFileSync(log, "", { flag: "a", mode: 0o600 });
writeFileSync(join(contents, "Info.plist"), `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RexGlow</string>
<key>CFBundleIdentifier</key><string>local.rex-glow</string>
<key>CFBundleName</key><string>Rex Glow</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSUIElement</key><true/>
<key>CFBundleURLTypes</key><array><dict>
<key>CFBundleURLName</key><string>local.rex-glow</string>
<key>CFBundleURLSchemes</key><array><string>rex-glow</string></array>
</dict></array>
<key>RexGlowNode</key><string>${escape(process.execPath)}</string>
<key>RexGlowScript</key><string>${escape(join(source, "open.mjs"))}</string>
<key>RexGlowLog</key><string>${escape(log)}</string>
</dict></plist>
`);
execFileSync("/usr/bin/swiftc", [join(source, "Handler.swift"), "-o", binary],
  { stdio: "inherit" });
execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", bundle],
  { stdio: "inherit" });
execFileSync(
  "/System/Library/Frameworks/CoreServices.framework/Frameworks/" +
  "LaunchServices.framework/Support/lsregister",
  ["-f", bundle], { stdio: "inherit" },
);
execFileSync("/usr/bin/swift", ["-e", `
import Foundation
import CoreServices
let result = LSSetDefaultHandlerForURLScheme(
  "rex-glow" as CFString, "local.rex-glow" as CFString)
if result != noErr { fatalError("URL registration failed") }
`], { stdio: "inherit" });
mkdirSync(dirname(link), { recursive: true });
try {
  symlinkSync(source, link);
} catch (error) {
  if (error.code !== "EEXIST") throw error;
}
process.stdout.write(`Installed ${bundle}\nLinked ${link}\nRun /reload in Pi.\n`);
