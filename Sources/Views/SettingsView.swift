// ABOUTME: Application settings panel.
// ABOUTME: Placeholder for future configuration options.

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2.weight(.semibold))

            Text("Nothing to configure yet.")
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400, height: 300)
    }
}
