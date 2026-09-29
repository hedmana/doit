import Foundation
import Testing
@testable import DoitCore

@MainActor
struct TodoStoreTests {
    let url = FileManager.default.temporaryDirectory.appending(path: "doit-tests-\(UUID().uuidString)/todos.json")

    @Test func persistsAcrossLaunches() {
        let store = TodoStore(fileURL: url)
        let todo = Todo(title: "buy milk", isUrgent: true)
        store.add(todo)
        store.update([todo.id]) { $0.title = "buy oat milk" }
        store.toggleComplete([todo.id])
        let trash = Todo(title: "trash")
        store.add(trash)
        store.delete([trash.id])

        let reloaded = TodoStore(fileURL: url).todos
        #expect(reloaded.map(\.id) == [todo.id])
        #expect(reloaded[0].title == "buy oat milk")
        #expect(reloaded[0].isUrgent && reloaded[0].isCompleted)
    }

    @Test func toggleCompleteRestores() {
        let store = TodoStore(fileURL: url)
        let todo = Todo(title: "a")
        store.add(todo)
        store.toggleComplete([todo.id])
        #expect(store.todos[0].isCompleted)
        store.toggleComplete([todo.id])
        #expect(!store.todos[0].isCompleted)
    }

    @Test func bulkChangesTouchOnlyTheGivenTodos() {
        let store = TodoStore(fileURL: url)
        let todos = ["a", "b", "c"].map { Todo(title: $0) }
        todos.forEach(store.add)
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))
        let ac: Set = [todos[0].id, todos[2].id]

        store.schedule(ac, daysFromNow: 1, now: now)
        #expect(store.todos.map(\.date) == [tomorrow, nil, tomorrow])
        store.schedule(ac, daysFromNow: nil)
        #expect(store.todos.allSatisfy { $0.date == nil })
        store.delete(ac)
        #expect(store.todos.map(\.title) == ["b"])
    }

    @Test func undoAndRedoRestoreChanges() {
        let store = TodoStore(fileURL: url)
        let undo = UndoManager()
        undo.groupsByEvent = false
        store.undoManager = undo
        let todo = Todo(title: "a")
        for change in [{ store.add(todo) }, { store.update([todo.id]) { $0.title = "b" } }, { store.delete([todo.id]) }] {
            undo.beginUndoGrouping()
            change()
            undo.endUndoGrouping()
        }

        undo.undo()
        #expect(store.todos.map(\.title) == ["b"])
        undo.undo()
        #expect(store.todos.map(\.title) == ["a"])
        undo.redo()
        #expect(TodoStore(fileURL: url).todos.map(\.title) == ["b"])
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
