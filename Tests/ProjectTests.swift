// ABOUTME: Tests for the Project model.
// ABOUTME: Validates creation, identity, and equality behavior.

import XCTest
@testable import ff2

final class ProjectTests: XCTestCase {
    func testCreation() {
        let project = Project(name: "myapp", directory: "/Users/test/myapp")
        XCTAssertEqual(project.name, "myapp")
        XCTAssertEqual(project.directory, "/Users/test/myapp")
    }

    func testUniqueIDs() {
        let a = Project(name: "a", directory: "/a")
        let b = Project(name: "b", directory: "/b")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testExplicitID() {
        let id = UUID()
        let project = Project(name: "test", directory: "/test", id: id)
        XCTAssertEqual(project.id, id)
    }

    func testHashable() {
        let id = UUID()
        let a = Project(name: "test", directory: "/test", id: id)
        let b = Project(name: "test", directory: "/test", id: id)
        XCTAssertEqual(a, b)

        var set: Set<Project> = []
        set.insert(a)
        XCTAssertTrue(set.contains(b))
    }

    func testMutableProperties() {
        var project = Project(name: "old", directory: "/old")
        project.name = "new"
        project.directory = "/new"
        XCTAssertEqual(project.name, "new")
        XCTAssertEqual(project.directory, "/new")
    }

    func testCodableRoundTrip() throws {
        let projects = [
            Project(name: "alpha", directory: "/Users/test/alpha"),
            Project(name: "beta", directory: "/Users/test/beta"),
        ]
        let data = try JSONEncoder().encode(projects)
        let decoded = try JSONDecoder().decode([Project].self, from: data)
        XCTAssertEqual(projects, decoded)
    }

    func testCodablePreservesID() throws {
        let original = Project(name: "test", directory: "/test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.directory, decoded.directory)
    }

    func testProjectStoreRoundTrip() {
        let projects = [
            Project(name: "one", directory: "/one"),
            Project(name: "two", directory: "/two"),
        ]
        ProjectStore.save(projects)
        let loaded = ProjectStore.load()
        XCTAssertEqual(projects, loaded)
    }
}
