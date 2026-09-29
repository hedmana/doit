import DoitCore
import SwiftUI

// Shared by the To-Do menu bar menu and the list context menu
struct TodoMenu: View {
    let store: TodoStore
    let ids: Set<Todo.ID>

    var body: some View {
        let todos = store.todos.filter { ids.contains($0.id) }
        let isOpen = todos.contains { !$0.isCompleted }
        let isUrgent = !todos.isEmpty && todos.allSatisfy(\.isUrgent)
        Group {
            Button(isOpen || todos.isEmpty ? "Complete" : "Reopen") { withAnimation { store.toggleComplete(ids) } }
                .keyboardShortcut("k")
            Divider()
            Group {
                Button("Schedule for Today") { schedule(0) }
                    .keyboardShortcut("t")
                Button("Schedule for Tomorrow") { schedule(1) }
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                Button("Remove Date") { schedule(nil) }
                    .keyboardShortcut("r")
                    .disabled(todos.allSatisfy { $0.date == nil })
                Button(isUrgent ? "Remove Urgent" : "Mark Urgent") { store.update(ids) { $0.isUrgent = !isUrgent } }
                    .keyboardShortcut("u", modifiers: [.command, .shift])
            }
            .disabled(!isOpen)
            Divider()
            Button("Delete") { withAnimation { store.delete(ids) } }
        }
        .disabled(todos.isEmpty)
    }

    private func schedule(_ days: Int?) {
        withAnimation { store.schedule(ids, daysFromNow: days) }
    }
}

struct TodoCommands: Commands {
    let store: TodoStore
    @FocusedValue(\.selectedTodos) private var selection

    var body: some Commands {
        CommandMenu("To-Do") { TodoMenu(store: store, ids: selection ?? []) }
    }
}

struct SelectedTodosKey: FocusedValueKey {
    typealias Value = Set<Todo.ID>
}

extension FocusedValues {
    var selectedTodos: Set<Todo.ID>? {
        get { self[SelectedTodosKey.self] }
        set { self[SelectedTodosKey.self] = newValue }
    }
}
