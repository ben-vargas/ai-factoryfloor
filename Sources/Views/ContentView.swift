// ABOUTME: Main application view composing the sidebar and terminal content area.
// ABOUTME: Uses NavigationSplitView for the sidebar/detail pattern.

import SwiftUI

struct ContentView: View {
    @State private var projects: [Project] = ProjectStore.load()
    @State private var selectedProjectID: UUID?
    @StateObject private var surfaceCache = TerminalSurfaceCache()

    var body: some View {
        NavigationSplitView {
            ProjectSidebar(
                projects: $projects,
                selectedProjectID: $selectedProjectID
            )
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 350)
        } detail: {
            if let selectedProjectID, let project = projects.first(where: { $0.id == selectedProjectID }) {
                TerminalContainerView(
                    projectID: project.id,
                    workingDirectory: project.directory
                )
                .id(project.id)
            } else {
                VStack(spacing: 12) {
                    Text("No project selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Add a project from the sidebar to get started.")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(surfaceCache)
        .onChange(of: projects) { _, newValue in
            ProjectStore.save(newValue)
        }
    }
}

enum ProjectStore {
    private static let key = "ff2.projects"

    static func load() -> [Project] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Project].self, from: data)) ?? []
    }

    static func save(_ projects: [Project]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
