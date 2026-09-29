import Foundation
import Observation
import os

@MainActor
@Observable
public final class TodoStore {
    public nonisolated static let defaultURL = URL.applicationSupportDirectory.appending(path: "doit/todos.json")

    public private(set) var todos: [Todo] = []
    private let fileURL: URL

    public init(fileURL: URL = TodoStore.defaultURL) {
        self.fileURL = fileURL
        load()
    }

    public func add(_ todo: Todo) {
        todos.append(todo)
        save()
    }

    public func update(_ id: Todo.ID, _ change: (inout Todo) -> Void) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        change(&todos[index])
        save()
    }

    public func toggleComplete(_ id: Todo.ID, now: Date = .now) {
        update(id) { $0.completedAt = $0.isCompleted ? nil : now }
    }

    public func delete(_ id: Todo.ID) {
        todos.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            todos = try Self.decoder.decode([Todo].self, from: Data(contentsOf: fileURL))
        } catch {
            // Move the unreadable file aside so the next save cannot overwrite user data
            let backup = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            Self.logger.error("Unreadable \(self.fileURL.path), moved to \(backup.path): \(error)")
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.encoder.encode(todos).write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Saving \(self.fileURL.path) failed: \(error)")
        }
    }

    private static let logger = Logger(subsystem: "com.hedmana.doit", category: "store")

    private static let encoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
