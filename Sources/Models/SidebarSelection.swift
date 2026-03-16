// ABOUTME: Represents the selected item in the sidebar.
// ABOUTME: Can be either a project or a workstream, enabling single-selection across both.

import Foundation

enum SidebarSelection: Hashable, Codable {
    case project(UUID)
    case workstream(UUID)
    case settings
    case help

    var projectID: UUID? {
        if case .project(let id) = self { return id }
        return nil
    }

    var workstreamID: UUID? {
        if case .workstream(let id) = self { return id }
        return nil
    }

    // MARK: - Persistence

    private static let key = "factoryfloor.selection"

    static func loadSaved() -> SidebarSelection? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SidebarSelection.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}

enum SidebarState {
    private static let expandedKey = "factoryfloor.expandedProjects"

    static func loadExpanded() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: expandedKey),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else { return [] }
        return ids
    }

    static func saveExpanded(_ ids: Set<UUID>) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: expandedKey)
    }
}
