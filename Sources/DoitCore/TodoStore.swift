import Foundation
import Observation
import os

@MainActor
@Observable
public final class TodoStore {
    public nonisolated static let defaultURL = URL.applicationSupportDirectory.appending(path: "doit/todos.json")

    public private(set) var todos: [Todo] = []
    @ObservationIgnored public var undoManager: UndoManager?
    private let fileURL: URL

    public init(fileURL: URL = TodoStore.defaultURL) {
        self.fileURL = fileURL
        load()
    }

    public func add(_ todo: Todo) {
        commit { $0.append(todo) }
    }

    public func update(_ ids: Set<Todo.ID>, _ change: (inout Todo) -> Void) {
        commit { todos in
            for index in todos.indices where ids.contains(todos[index].id) { change(&todos[index]) }
        }
    }

    public func toggleComplete(_ ids: Set<Todo.ID>, now: Date = .now) {
        update(ids) { $0.completedAt = $0.isCompleted ? nil : now }
    }

    public func schedule(_ ids: Set<Todo.ID>, daysFromNow days: Int?, now: Date = .now, calendar: Calendar = .current) {
        let date = days.flatMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now)) }
        update(ids) { $0.date = date }
    }

    public func delete(_ ids: Set<Todo.ID>) {
        commit { $0.removeAll { ids.contains($0.id) } }
    }

    private func commit(_ change: (inout [Todo]) -> Void) {
        let previous = todos
        change(&todos)
        undoManager?.registerUndo(withTarget: self) { $0.commit { $0 = previous } }
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
