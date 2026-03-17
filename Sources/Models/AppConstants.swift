// ABOUTME: Central place for app-wide constants.
// ABOUTME: Debug builds use separate IDs so they can run alongside release builds.

import Foundation

func resolvedConfigDirectory(
    appID: String,
    environment: [String: String],
    defaultConfigBase: URL,
    isDebugBuild: Bool,
    isRunningTests: Bool,
    fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
) -> URL {
    let configBase: URL
    if let xdg = environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
        configBase = URL(fileURLWithPath: xdg)
    } else {
        configBase = defaultConfigBase
    }

    if isRunningTests {
        return configBase.appendingPathComponent("\(appID)-tests")
    }

    let dir = configBase.appendingPathComponent(appID)
    if isDebugBuild, !fileExists(dir.path) {
        let releaseDir = configBase.appendingPathComponent("factoryfloor")
        if fileExists(releaseDir.path) {
            return releaseDir
        }
    }

    return dir
}

enum AppConstants {
    #if DEBUG
    static let appID = "factoryfloor-debug"
    static let appName = "Factory Floor Debug"
    static let urlScheme = "factoryfloor-debug"
    #else
    static let appID = "factoryfloor"
    static let appName = "Factory Floor"
    static let urlScheme = "factoryfloor"
    #endif

    /// Config directory: ~/.config/factoryfloor[-debug]/ (respects XDG_CONFIG_HOME).
    /// Falls back to the release config directory if the debug one doesn't exist.
    static var configDirectory: URL {
        resolvedConfigDirectory(
            appID: appID,
            environment: ProcessInfo.processInfo.environment,
            defaultConfigBase: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config"),
            isDebugBuild: {
                #if DEBUG
                true
                #else
                false
                #endif
            }(),
            isRunningTests: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        )
    }

    /// Worktrees are always shared between debug and release builds.
    static var worktreesDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".factoryfloor")
            .appendingPathComponent("worktrees")
    }
}
