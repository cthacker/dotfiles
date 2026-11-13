import { execFileSync } from "node:child_process";
import {
  existsSync, mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { CODE, MARKDOWN, SUPPORT_DIRECTORY } from "./bridge.mjs";

if (process.platform !== "darwin") throw new Error("Rex Opener requires macOS");

const source = dirname(fileURLToPath(import.meta.url));
const find = (name) => execFileSync("/usr/bin/which", [name], { encoding: "utf8" }).trim();
const bundle = join(homedir(), "Applications", "Rex Opener.app");
const log = join(SUPPORT_DIRECTORY, "handler.log");
const programs = join(SUPPORT_DIRECTORY, "programs.json");
const TEXTEDIT = "/System/Applications/TextEdit.app";
const lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/" +
  "LaunchServices.framework/Support/lsregister";
const escape = (value) => value.replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const strings = (values) => values.map((value) => `<string>${escape(value)}</string>`).join("");
const swift = (code) => execFileSync("/usr/bin/swift", ["-e", `
import AppKit
import UniformTypeIdentifiers
${code}`], { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] }).trim();

// macOS sets default applications per type, not per extension, and several extensions can
// share a type (.cpp and .cc are both public.c-plus-plus-source). So everything here works per
// type. Returns the current application for each type the handled extensions belong to, and the
// extensions that have no declared type (macOS gives them a "dyn." one).
const current_openers = () => JSON.parse(swift(`
var types: [String: String] = [:]
var undeclared: [String] = []
for name in ${JSON.stringify([...MARKDOWN, ...CODE])} {
  guard let type = UTType(filenameExtension: name) else { continue }
  if type.isDynamic { undeclared.append(name) }
  types[type.identifier] = NSWorkspace.shared.urlForApplication(toOpen: type)?.path ?? ""
}
let found: [String: Any] = ["types": types, "undeclared": undeclared]
print(String(data: try! JSONSerialization.data(withJSONObject: found), encoding: .utf8)!)
`));

// Makes each application the default for its type. Returns one line per type it could not
// change, starting with the type.
const open_with = (pairs) => !pairs.length ? [] : swift(`
let pairs: [[String]] = ${JSON.stringify(pairs)}
var pending = pairs.count
for pair in pairs {
  NSWorkspace.shared.setDefaultApplication(
    at: URL(fileURLWithPath: pair[1]), toOpen: UTType(pair[0])!
  ) { error in
    if let error = error { print("\\(pair[0]): \\(error.localizedDescription)") }
    DispatchQueue.main.async { pending -= 1 }
  }
}
while pending > 0 { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
`).split("\n").filter(Boolean);

const info_plist = (types, undeclared, previous) => `<?xml version="1.0" encoding="UTF-8"?>
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
<key>LSItemContentTypes</key><array>${strings(types)}</array>
</dict><dict>
<key>CFBundleTypeName</key><string>Source</string>
<key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>CFBundleTypeExtensions</key><array>${strings(undeclared)}</array>
</dict></array>
<key>RexOpenerFallbacks</key><dict>
${Object.entries(previous).map(([type, application]) =>
    `<key>${escape(type)}</key><string>${escape(application)}</string>`).join("\n")}
</dict>
<key>RexOpenerNode</key><string>${escape(process.execPath)}</string>
<key>RexOpenerScript</key><string>${escape(join(source, "open.mjs"))}</string>
<key>RexOpenerLog</key><string>${escape(log)}</string>
</dict></plist>
`;

let saved = {};
try {
  saved = JSON.parse(readFileSync(programs, "utf8"));
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}
const previous = saved.previous ?? {};

if (process.argv[2] === "remove") {
  const failures = open_with(Object.entries(previous));
  if (failures.length) {
    process.stderr.write("Could not give these types back to their previous application:\n" +
      `${failures.join("\n")}\nNothing was removed. Run this again to retry.\n`);
    process.exit(1);
  }
  execFileSync(lsregister, ["-u", bundle], { stdio: "ignore" });
  rmSync(bundle, { recursive: true, force: true });
  rmSync(SUPPORT_DIRECTORY, { recursive: true, force: true });
  process.stdout.write(`Removed ${bundle}\nEach type opens with its previous application again.\n`);
} else {
  const rex = find("rex");
  const glow = find("glow");
  const nvim = find("nvim");
  const { types, undeclared } = current_openers();
  for (const [type, application] of Object.entries(types)) {
    if (application && application !== bundle) previous[type] = application;
    previous[type] ??= TEXTEDIT;
  }
  const dropped = Object.keys(previous).filter((type) => !(type in types));

  // Build and sign a complete new app beside the installed one, then swap it in, so a failed
  // build or swap leaves the working app as it was.
  mkdirSync(dirname(bundle), { recursive: true });
  const staging = mkdtempSync(join(dirname(bundle), ".rex-opener-"));
  const fresh = join(staging, "Rex Opener.app");
  const replaced = join(staging, "replaced.app");
  try {
    mkdirSync(join(fresh, "Contents", "MacOS"), { recursive: true });
    writeFileSync(join(fresh, "Contents", "Info.plist"),
      info_plist(Object.keys(types).filter((type) => !type.startsWith("dyn.")), undeclared,
        previous));
    execFileSync("/usr/bin/swiftc", [join(source, "Handler.swift"), "-o",
      join(fresh, "Contents", "MacOS", "RexOpener")], { stdio: "inherit" });
    execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", fresh], { stdio: "inherit" });
    if (existsSync(bundle)) renameSync(bundle, replaced);
    try {
      renameSync(fresh, bundle);
    } catch (error) {
      if (existsSync(replaced)) renameSync(replaced, bundle);
      throw error;
    }
  } catch (error) {
    // Keep the old app if it could not be put back, and say where it is.
    if (existsSync(replaced)) {
      process.stderr.write(`The previous app is kept at ${replaced}\n`);
      throw error;
    }
    rmSync(staging, { recursive: true, force: true });
    throw error;
  }
  rmSync(staging, { recursive: true, force: true });

  // Types no longer in the lists go back to their previous application. One macOS refuses
  // stays listed, so the next run or a removal tries it again.
  const unrestored = open_with(dropped.map((type) => [type, previous[type]]));
  for (const type of dropped) {
    if (!unrestored.some((line) => line.startsWith(`${type}:`))) delete previous[type];
  }
  mkdirSync(SUPPORT_DIRECTORY, { recursive: true, mode: 0o700 });
  writeFileSync(programs, JSON.stringify({ rex, glow, nvim, previous }), { mode: 0o600 });
  writeFileSync(join(SUPPORT_DIRECTORY, "glow.yml"),
    "mouse: true\npager: false\nwidth: 80\nstyle: auto\n", { mode: 0o600 });
  writeFileSync(log, "", { flag: "a", mode: 0o600 });
  execFileSync(lsregister, ["-f", bundle], { stdio: "inherit" });
  const failures = open_with(Object.keys(types).map((type) => [type, bundle]));
  const registered = Object.entries(current_openers().types)
    .filter(([, application]) => application === bundle).map(([type]) => type);
  process.stdout.write(`Installed ${bundle}\nOpens from Rex: ${registered.join(" ")}\n` +
    (failures.length ? `Could not register:\n${failures.join("\n")}\n` : "") +
    (dropped.length ? `No longer handled: ${dropped.join(" ")}\n` : "") +
    (unrestored.length
      ? `Still opened by this app because macOS kept it as their default:\n` +
        `${unrestored.join("\n")}\n`
      : "") +
    `Elsewhere each type opens with its previous application, listed in ${programs}\n`);
}
