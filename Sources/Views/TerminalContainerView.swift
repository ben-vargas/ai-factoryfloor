// ABOUTME: Hosts a workstream's two terminals: claude (main) and workspace (secondary).
// ABOUTME: Manages the lifecycle of terminal surfaces, caching them for fast switching.

import SwiftUI

extension Notification.Name {
    static let terminalSurfaceClosed = Notification.Name("ff2.terminalSurfaceClosed")
}

/// Deterministic UUID derived from a base UUID and a salt string.
func derivedUUID(from base: UUID, salt: String) -> UUID {
    var hasher = Hasher()
    hasher.combine(base)
    hasher.combine(salt)
    let hash = hasher.finalize()
    // Build a deterministic UUID from the hash
    var bytes = UUID().uuid
    withUnsafeMutableBytes(of: &bytes) { buf in
        withUnsafeBytes(of: hash) { hashBuf in
            for i in 0..<min(buf.count, hashBuf.count) {
                buf[i] = hashBuf[i]
            }
        }
    }
    return UUID(uuid: bytes)
}

struct TerminalContainerView: View {
    let workstreamID: UUID
    let workingDirectory: String
    let projectName: String
    let workstreamName: String

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache
    @EnvironmentObject var appEnv: AppEnvironment

    private var claudeID: UUID { workstreamID }
    private var workspaceID: UUID { derivedUUID(from: workstreamID, salt: "workspace") }

    private var claudePath: String? {
        appEnv.toolStatus.claude.path
    }

    var body: some View {
        VSplitView {
            // Claude terminal (main, takes ~70%)
            SingleTerminalView(
                surfaceID: claudeID,
                workingDirectory: workingDirectory,
                command: claudePath,
                environmentVars: envVars
            )
            .frame(minHeight: 100)

            // Workspace terminal (secondary)
            SingleTerminalView(
                surfaceID: workspaceID,
                workingDirectory: workingDirectory,
                initialInput: "ls\n",
                environmentVars: envVars
            )
            .frame(minHeight: 60, idealHeight: 150)
        }
    }

    private var envVars: [String: String] {
        [
            "FF_PROJECT": projectName,
            "FF_WORKSTREAM": workstreamName,
        ]
    }
}

/// NSViewRepresentable for a single terminal surface.
struct SingleTerminalView: NSViewRepresentable {
    let surfaceID: UUID
    let workingDirectory: String
    var command: String?
    var initialInput: String?
    var environmentVars: [String: String] = [:]

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard let app = TerminalApp.shared.app else { return }

        let terminalView = surfaceCache.surface(
            for: surfaceID,
            app: app,
            workingDirectory: workingDirectory,
            command: command,
            initialInput: initialInput,
            environmentVars: environmentVars
        )

        if terminalView.superview !== container {
            container.subviews.forEach { $0.removeFromSuperview() }
            container.addSubview(terminalView)
            terminalView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                terminalView.topAnchor.constraint(equalTo: container.topAnchor),
                terminalView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                terminalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                terminalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        DispatchQueue.main.async {
            terminalView.setFocused(true)
        }
    }
}

/// Caches terminal surfaces so switching workstreams doesn't destroy/recreate them.
final class TerminalSurfaceCache: ObservableObject {
    private var surfaces: [UUID: TerminalView] = [:]
    private var surfaceParams: [UUID: SurfaceParams] = [:]

    struct SurfaceParams {
        let workingDirectory: String
        let command: String?
        let initialInput: String?
        let environmentVars: [String: String]
    }

    init() {
        NotificationCenter.default.addObserver(
            forName: .terminalSurfaceClosed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let closedView = notification.object as? TerminalView else { return }
            self.handleSurfaceClosed(closedView)
        }
    }

    func surface(for id: UUID, app: ghostty_app_t, workingDirectory: String, command: String? = nil, initialInput: String? = nil, environmentVars: [String: String] = [:]) -> TerminalView {
        if let existing = surfaces[id] {
            existing.workstreamID = id
            return existing
        }
        let view = TerminalView(app: app, workingDirectory: workingDirectory, command: command, initialInput: initialInput, environmentVars: environmentVars)
        view.workstreamID = id
        surfaces[id] = view
        surfaceParams[id] = SurfaceParams(workingDirectory: workingDirectory, command: command, initialInput: initialInput, environmentVars: environmentVars)
        return view
    }

    func removeSurface(for id: UUID) {
        surfaces.removeValue(forKey: id)
        surfaceParams.removeValue(forKey: id)
    }

    /// Remove both claude and workspace surfaces for a workstream.
    func removeWorkstreamSurfaces(for workstreamID: UUID) {
        removeSurface(for: workstreamID)
        removeSurface(for: derivedUUID(from: workstreamID, salt: "workspace"))
    }

    private func handleSurfaceClosed(_ closedView: TerminalView) {
        guard let (id, _) = surfaces.first(where: { $0.value === closedView }) else { return }
        guard let params = surfaceParams[id],
              let app = TerminalApp.shared.app else { return }

        surfaces.removeValue(forKey: id)
        let newView = TerminalView(app: app, workingDirectory: params.workingDirectory, command: params.command, initialInput: params.initialInput, environmentVars: params.environmentVars)
        newView.workstreamID = id
        surfaces[id] = newView

        objectWillChange.send()
    }
}
