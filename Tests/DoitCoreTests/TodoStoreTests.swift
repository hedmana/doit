import Foundation
import Testing
@testable import DoitCore

@MainActor
struct TodoStoreTests {
    let url = FileManager.default.temporaryDirectory.appending(path: "doit-tests-\(UUID().uuidString)/todos.json")

    @Test func persistsAcrossLaunches() {
        let store = TodoStore(fileURL: url)
        var todo = Todo(title: "buy milk", isUrgent: true)
        store.add(todo)
        todo.title = "buy oat milk"
        store.update(todo)
        store.toggleComplete(todo.id)
        let trash = Todo(title: "trash")
        store.add(trash)
        store.delete(trash.id)

        let reloaded = TodoStore(fileURL: url).todos
        #expect(reloaded.map(\.id) == [todo.id])
        #expect(reloaded[0].title == "buy oat milk")
        #expect(reloaded[0].isUrgent && reloaded[0].isCompleted)
    }

    @Test func toggleCompleteRestores() {
        let store = TodoStore(fileURL: url)
        let todo = Todo(title: "a")
        store.add(todo)
        store.toggleComplete(todo.id)
        #expect(store.todos[0].isCompleted)
        store.toggleComplete(todo.id)
        #expect(!store.todos[0].isCompleted)
    }

    @Test func unreadableFileIsBackedUpNotOverwritten() throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let store = TodoStore(fileURL: url)
        #expect(store.todos.isEmpty)
        store.add(Todo(title: "new"))

        let backups = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("corrupt") }
        #expect(try backups.map { try String(contentsOf: $0, encoding: .utf8) } == ["not json"])
    }
}
