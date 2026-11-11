import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { CODE, MARKDOWN, SUPPORT_DIRECTORY } from "./bridge.mjs";

if (process.platform !== "darwin") throw new Error("Rex Opener requires macOS");

const source = dirname(fileURLToPath(import.meta.url));
const find = (name) => execFileSync("/usr/bin/which", [name], { encoding: "utf8" }).trim();
const bundle = join(homedir(), "Applications", "Rex Opener.app");
const contents = join(bundle, "Contents");
const binary = join(contents, "MacOS", "RexOpener");
const log = join(SUPPORT_DIRECTORY, "handler.log");
const programs = join(SUPPORT_DIRECTORY, "programs.json");
const lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/" +
  "LaunchServices.framework/Support/lsregister";
const escape = (value) => value.replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const swift = (code) => execFileSync("/usr/bin/swift", ["-e", `
import AppKit
import UniformTypeIdentifiers
${code}`], { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] }).trim();
const current_openers = () => JSON.parse(swift(`
var found: [String: [String: String]] = [:]
for name in ${JSON.stringify([...MARKDOWN, ...CODE])} {
  guard let type = UTType(filenameExtension: name) else { continue }
  found[name] = [
    "type": type.identifier,
    "application": NSWorkspace.shared.urlForApplication(toOpen: type)?.path ?? "",
  ]
}
print(String(data: try! JSONSerialization.data(withJSONObject: found), encoding: .utf8)!)
`));
const open_with = (pairs) => swift(`
let pairs: [[String]] = ${JSON.stringify(pairs)}
var pending = pairs.count
for pair in pairs {
  NSWorkspace.shared.setDefaultApplication(
    at: URL(fileURLWithPath: pair[1]), toOpen: UTType(filenameExtension: pair[0])!
  ) { error in
    if let error = error { print("\\(pair[0]): \\(error.localizedDescription)") }
    DispatchQueue.main.async { pending -= 1 }
  }
}
while pending > 0 { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
`);

let saved = {};
try {
  saved = JSON.parse(readFileSync(programs, "utf8"));
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}
const fallbacks = saved.fallbacks ??
  (saved.fallback ? { md: saved.fallback, markdown: saved.fallback } : {});

if (process.argv[2] === "remove") {
  const failures = open_with(Object.entries(fallbacks));
  execFileSync(lsregister, ["-u", bundle], { stdio: "ignore" });
  rmSync(bundle, { recursive: true, force: true });
  rmSync(SUPPORT_DIRECTORY, { recursive: true, force: true });
  process.stdout.write(`Removed ${bundle}\n` + (failures
    ? `Could not restore the previous opener for:\n${failures}\n`
    : "Each file type opens with its previous application again.\n"));
} else {
  const rex = find("rex");
  const glow = find("glow");
  const nvim = find("nvim");
  const openers = current_openers();
  for (const [extension, { application }] of Object.entries(openers)) {
    if (application && application !== bundle) fallbacks[extension] = application;
    fallbacks[extension] ??= "/System/Applications/TextEdit.app";
  }
  const dropped = Object.keys(fallbacks).filter((name) => !(name in openers));
  const unrestored = dropped.length
    ? open_with(dropped.map((name) => [name, fallbacks[name]])) : "";
  const kept = unrestored.split("\n").map((line) => line.split(":")[0]);
  for (const name of dropped) if (!kept.includes(name)) delete fallbacks[name];
  const dynamic = Object.keys(openers).filter((name) => openers[name].type.startsWith("dyn."));
  const declared = [...new Set(Object.values(openers).map(({ type }) => type))]
    .filter((type) => !type.startsWith("dyn."));
  const strings = (values) => values.map((value) => `<string>${escape(value)}</string>`).join("");

  mkdirSync(dirname(binary), { recursive: true });
  mkdirSync(SUPPORT_DIRECTORY, { recursive: true, mode: 0o700 });
  writeFileSync(programs, JSON.stringify({ rex, glow, nvim, fallbacks }), { mode: 0o600 });
  writeFileSync(join(SUPPORT_DIRECTORY, "glow.yml"),
    "mouse: true\npager: false\nwidth: 80\nstyle: auto\n", { mode: 0o600 });
  writeFileSync(log, "", { flag: "a", mode: 0o600 });
  writeFileSync(join(contents, "Info.plist"), `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RexOpener</string>
<key>CFBundleIdentifier</key><string>local.rex-opener</string>
<key>CFBundleName</key><string>Rex Opener</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSUIElement</key><true/>
<key>CFBundleDocumentTypes</key><array><dict>
<key>CFBundleTypeName</key><string>Text</string>
<key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>LSItemContentTypes</key><array>${strings(declared)}</array>
</dict><dict>
<key>CFBundleTypeName</key><string>Source</string>
<key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>CFBundleTypeExtensions</key><array>${strings(dynamic)}</array>
</dict></array>
<key>RexOpenerFallbacks</key><dict>
${Object.entries(fallbacks).map(([name, application]) =>
    `<key>${escape(name)}</key><string>${escape(application)}</string>`).join("\n")}
</dict>
<key>RexOpenerNode</key><string>${escape(process.execPath)}</string>
<key>RexOpenerScript</key><string>${escape(join(source, "open.mjs"))}</string>
<key>RexOpenerLog</key><string>${escape(log)}</string>
</dict></plist>
`);
  execFileSync("/usr/bin/swiftc", [join(source, "Handler.swift"), "-o", binary],
    { stdio: "inherit" });
  execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", bundle], { stdio: "inherit" });
  execFileSync(lsregister, ["-f", bundle], { stdio: "inherit" });
  const failures = open_with(Object.keys(openers).map((name) => [name, bundle]));
  const registered = Object.entries(current_openers())
    .filter(([, { application }]) => application === bundle).map(([name]) => name);
  process.stdout.write(`Installed ${bundle}\nOpens from Rex: ${registered.join(" ")}\n` +
    (failures ? `Could not register:\n${failures}\n` : "") +
    (dropped.length ? `No longer handled: ${dropped.join(" ")}\n` : "") +
    (unrestored
      ? `Still opened by this app because macOS kept it as their default:\n${unrestored}\n`
      : "") +
    `Elsewhere each type opens with its previous application, listed in ${programs}\n`);
}
