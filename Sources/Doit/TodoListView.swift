import DoitCore
import SwiftUI

struct TodoListView: View {
    let list: TodoList
    let now: Date
    @Environment(TodoStore.self) private var store
    @State private var newTitle = ""
    @FocusState private var isAdding: Bool

    var body: some View {
        List {
            if list != .logbook {
                HStack {
                    Image(systemName: "plus").foregroundStyle(.secondary)
                    TextField("New To-Do", text: $newTitle)
                        .textFieldStyle(.plain)
                        .focused($isAdding)
                        .onSubmit(add)
                }
            }
            ForEach(list.todos(from: store.todos, now: now)) { todo in
                TodoRow(todo: todo, now: now, hidesToday: list == .today)
            }
        }
        .navigationTitle(list.title)
        .toolbar {
            Button("New To-Do", systemImage: "plus") { isAdding = true }
                .keyboardShortcut("n")
                .disabled(list == .logbook)
        }
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        withAnimation { store.add(list.newTodo(titled: title, now: now)) }
        newTitle = ""
        isAdding = true
    }
}
