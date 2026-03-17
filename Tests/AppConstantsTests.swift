// ABOUTME: Tests for config-directory resolution across app, debug, and test contexts.
// ABOUTME: Keeps XCTest persistence isolated from the app's real project roster.

import XCTest
@testable import FactoryFloor

final class AppConstantsTests: XCTestCase {
    func testDebugBuildFallsBackToReleaseDirectoryWhenDebugDirectoryIsMissing() {
        let base = URL(fileURLWithPath: "/tmp/factoryfloor-config")

        let resolved = resolvedConfigDirectory(
            appID: "factoryfloor-debug",
            environment: [:],
            defaultConfigBase: base,
            isDebugBuild: true,
            isRunningTests: false
        ) { path in
            path == base.appendingPathComponent("factoryfloor").path
        }

        XCTAssertEqual(resolved, base.appendingPathComponent("factoryfloor"))
    }

    func testTestsUseDedicatedConfigDirectoryWithoutFallback() {
        let base = URL(fileURLWithPath: "/tmp/factoryfloor-config")

        let resolved = resolvedConfigDirectory(
            appID: "factoryfloor-debug",
            environment: [:],
            defaultConfigBase: base,
            isDebugBuild: true,
            isRunningTests: true
        ) { path in
            path == base.appendingPathComponent("factoryfloor").path
        }

        XCTAssertEqual(resolved, base.appendingPathComponent("factoryfloor-debug-tests"))
    }
}
