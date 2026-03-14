// ABOUTME: Application settings pane displayed in the detail area.
// ABOUTME: Language, tmux mode, tool detection, default apps.

import SwiftUI

struct SettingsView: View {
    @AppStorage("ff2.languageOverride") private var languageOverride: String = ""
    @AppStorage("ff2.tmuxMode") private var tmuxMode: Bool = false
    @AppStorage("ff2.defaultTerminal") private var defaultTerminal: String = ""
    @AppStorage("ff2.defaultBrowser") private var defaultBrowser: String = ""

    @State private var toolStatus = ToolStatus()
    @State private var installedTerminals: [AppInfo] = []
    @State private var installedBrowsers: [AppInfo] = []

    var body: some View {
        Form {
            // MARK: - Session
            Section("Session") {
                Toggle("Tmux Mode", isOn: $tmuxMode)
                Text("Makes sessions persist across app restarts. Sessions are lost on system restart.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Language
            Section("Language") {
                Picker("Language", selection: $languageOverride) {
                    ForEach(availableLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .onChange(of: languageOverride) { _, newValue in
                    applyLanguage(newValue)
                }

                if !languageOverride.isEmpty {
                    Text("Restart the app for the language change to take effect.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Installed Tools
            Section("Installed Tools") {
                ToolRow(name: "tmux", status: toolStatus.tmux)
                ToolRow(name: "claude", status: toolStatus.claude)
                ToolRow(name: "gh", status: toolStatus.gh, detail: toolStatus.ghAuth)
            }

            // MARK: - Default Terminal
            Section("Default Terminal") {
                if installedTerminals.isEmpty {
                    Text("No supported terminals found")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Terminal", selection: $defaultTerminal) {
                        Text("None").tag("")
                        ForEach(installedTerminals) { app in
                            Text(app.name).tag(app.bundleID)
                        }
                    }
                }
            }

            // MARK: - Default Browser
            Section("Default Browser") {
                if installedBrowsers.isEmpty {
                    Text("No supported browsers found")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Browser", selection: $defaultBrowser) {
                        Text("System Default").tag("")
                        ForEach(installedBrowsers) { app in
                            Text(app.name).tag(app.bundleID)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            toolStatus = await ToolStatus.detect()
            installedTerminals = AppInfo.detectTerminals()
            installedBrowsers = AppInfo.detectBrowsers()
        }
    }

    // MARK: - Language

    private var availableLanguages: [(code: String, name: String)] {
        var languages: [(String, String)] = [("", NSLocalizedString("System Default", comment: ""))]
        let bundles = Bundle.main.localizations.filter { $0 != "Base" }.sorted()
        for code in bundles {
            let nativeLocale = Locale(identifier: code)
            let name = nativeLocale.localizedString(forLanguageCode: code) ?? code
            languages.append((code, name.capitalized))
        }
        return languages
    }

    private func applyLanguage(_ code: String) {
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }
}

// MARK: - Tool Detection

enum BinaryStatus {
    case notFound
    case found(String) // path

    var isInstalled: Bool {
        if case .found = self { return true }
        return false
    }

    var path: String? {
        if case .found(let p) = self { return p }
        return nil
    }
}

struct ToolStatus {
    var tmux: BinaryStatus = .notFound
    var claude: BinaryStatus = .notFound
    var gh: BinaryStatus = .notFound
    var ghAuth: String?

    static func detect() async -> ToolStatus {
        var status = ToolStatus()
        status.tmux = findBinary("tmux")
        status.claude = findBinary("claude")
        status.gh = findBinary("gh")

        if status.gh.isInstalled {
            status.ghAuth = checkGhAuth()
        }

        return status
    }

    private static func findBinary(_ name: String) -> BinaryStatus {
        let searchPaths = [
            "/usr/local/bin/\(name)",
            "/opt/homebrew/bin/\(name)",
            "/usr/bin/\(name)",
            "\(NSHomeDirectory())/.local/bin/\(name)",
        ]

        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return .found(path)
            }
        }

        // Try which as fallback
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !path.isEmpty { return .found(path) }
            }
        } catch {}

        return .notFound
    }

    private static func checkGhAuth() -> String? {
        let process = Process()
        let pipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "status"]
        process.standardOutput = pipe
        process.standardError = errPipe
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return "Authenticated"
            } else {
                return "Not authenticated"
            }
        } catch {
            return nil
        }
    }
}

private struct ToolRow: View {
    let name: String
    let status: BinaryStatus
    var detail: String?

    var body: some View {
        HStack {
            Text(name)
                .font(.system(.body, design: .monospaced))
            Spacer()
            if let path = status.path {
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(detail == "Authenticated" ? .green : .orange)
                        .padding(.trailing, 4)
                }
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("Not found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App Detection

struct AppInfo: Identifiable {
    let name: String
    let bundleID: String
    var id: String { bundleID }

    private static func isAppInstalled(_ bundleID: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }

    static func detectTerminals() -> [AppInfo] {
        let candidates: [(String, String)] = [
            ("Ghostty", "com.mitchellh.ghostty"),
            ("iTerm2", "com.googlecode.iterm2"),
            ("Terminal", "com.apple.Terminal"),
            ("Warp", "dev.warp.Warp-Stable"),
            ("Alacritty", "org.alacritty"),
            ("kitty", "net.kovidgoyal.kitty"),
        ]
        return candidates.compactMap { (name, id) in
            isAppInstalled(id) ? AppInfo(name: name, bundleID: id) : nil
        }
    }

    static func detectBrowsers() -> [AppInfo] {
        let candidates: [(String, String)] = [
            ("Safari", "com.apple.Safari"),
            ("Google Chrome", "com.google.Chrome"),
            ("Firefox", "org.mozilla.firefox"),
            ("Arc", "company.thebrowser.Browser"),
            ("Brave", "com.brave.Browser"),
            ("Microsoft Edge", "com.microsoft.edgemac"),
            ("Opera", "com.operasoftware.Opera"),
        ]
        return candidates.compactMap { (name, id) in
            isAppInstalled(id) ? AppInfo(name: name, bundleID: id) : nil
        }
    }
}
