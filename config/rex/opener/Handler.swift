import AppKit

final class OpenHandler: NSObject, NSApplicationDelegate {
    private var pending = 0
    private var log: FileHandle?

    private func setting(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    private func note(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
        try? log?.write(contentsOf: Data(line.utf8))
    }

    private func done() {
        pending -= 1
        if pending == 0 { NSApplication.shared.terminate(nil) }
    }

    private func requester() -> String {
        let sender = NSAppleEventManager.shared().currentAppleEvent?
            .attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value
        let app = sender.flatMap { NSRunningApplication(processIdentifier: $0) }
        return app?.bundleIdentifier ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    private func session_hint(_ bundle: String) -> String? {
        let stored = CFPreferencesCopyAppValue(
            "Workspace.lastFocusedSession" as CFString, bundle as CFString)
        guard let data = stored as? Data,
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return value["sessionID"] as? String
    }

    private func forward(_ url: URL) {
        let editors = Bundle.main.object(forInfoDictionaryKey: "RexOpenerFallbacks")
            as? [String: String] ?? [:]
        let editor = URL(fileURLWithPath: editors[url.pathExtension.lowercased()]
            ?? editors["txt"] ?? "/System/Applications/TextEdit.app")
        pending += 1
        NSWorkspace.shared.open(
            [url], withApplicationAt: editor, configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            DispatchQueue.main.async {
                if let error = error { self.note("fallback failed: \(error.localizedDescription)") }
                self.done()
            }
        }
    }

    private func preview(_ url: URL, hint: String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: setting("RexOpenerNode") ?? "")
        process.arguments = [setting("RexOpenerScript") ?? "", url.absoluteString] +
            (hint.map { [$0] } ?? [])
        process.standardOutput = log
        process.standardError = log
        process.terminationHandler = { finished in
            DispatchQueue.main.async {
                if finished.terminationStatus != 0 { self.forward(url) }
                self.done()
            }
        }
        pending += 1
        do {
            try process.run()
        } catch {
            note("could not start the opener: \(error.localizedDescription)")
            forward(url)
            done()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if log == nil, let path = setting("RexOpenerLog") {
            log = FileHandle(forWritingAtPath: path)
            _ = try? log?.seekToEnd()
        }
        let bundle = requester()
        let from_rex = bundle.hasPrefix("com.superlogical.rex")
        pending += 1
        for url in urls {
            if from_rex {
                note("preview \(url.path) for \(bundle)")
                preview(url, hint: session_hint(bundle))
            } else {
                note("pass \(url.path) from \(bundle) to the fallback editor")
                forward(url)
            }
        }
        done()
    }
}

let application = NSApplication.shared
let handler = OpenHandler()
application.delegate = handler
application.setActivationPolicy(.prohibited)
application.run()
