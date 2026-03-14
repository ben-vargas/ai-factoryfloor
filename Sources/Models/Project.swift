// ABOUTME: Data model for a project, which maps a name to a working directory.
// ABOUTME: Each project gets its own independent terminal surface.

import Foundation

struct Project: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var directory: String

    init(name: String, directory: String, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.directory = directory
    }
}
