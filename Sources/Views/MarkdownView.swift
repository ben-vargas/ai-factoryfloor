// ABOUTME: Thin wrapper around the MarkdownView SPM package.
// ABOUTME: Provides a consistent API for rendering markdown in the app.

import SwiftUI
import MarkdownView

struct MarkdownContentView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownView(text: markdown)
                .padding(16)
        }
    }
}
