import DoitCore
import SwiftUI

struct TodoListView: View {
    let list: TodoList
    let now: Date
    @Environment(TodoStore.self) private var store
    @State private var newTitle = ""
    @State private var selection: Set<Todo.ID> = []
    @FocusState private var isAdding: Bool
    @FocusState private var editing: Todo.ID?

    var body: some View {
        let todos = list.todos(from: store.todos, now: now)
        // Selection keeps ids of todos that left the list (completed, rescheduled); act only on visible ones
        let selected = selection.intersection(todos.map(\.id))
        List(selection: $selection) {
            if list != .logbook {
                HStack {
                    Image(systemName: "plus").foregroundStyle(.secondary)
                    TextField("New To-Do", text: $newTitle)
                        .textFieldStyle(.plain)
                        .focused($isAdding)
                        .onSubmit(add)
                }
            }
            if list.isGroupedByDay {
                ForEach(list.days(from: store.todos, now: now), id: \.day) { group in
                    Section(dayTitle(group.day)) { rows(group.todos) }
                }
            } else {
                rows(todos)
            }
        }
        .contextMenu(forSelectionType: Todo.ID.self) { ids in
            if !ids.isEmpty { TodoMenu(store: store, ids: ids) }
        } primaryAction: { ids in
            if ids.count == 1 { editing = ids.first }
        }
        .onDeleteCommand { withAnimation { store.delete(selected) } }
        .focusedSceneValue(\.selectedTodos, selected)
        .navigationTitle(list.title)
        .toolbar {
            Button("New To-Do", systemImage: "plus") { isAdding = true }
                .keyboardShortcut("n")
                .disabled(list == .logbook)
        }
    }

    private func rows(_ todos: [Todo]) -> some View {
        ForEach(todos) { TodoRow(todo: $0, now: now, list: list, editing: $editing) }
    }

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        let format = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        return day.formatted(calendar.isDate(day, equalTo: now, toGranularity: .year) ? format : format.year())
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        withAnimation { store.add(list.newTodo(titled: title, now: now)) }
        newTitle = ""
        isAdding = true
    }
}
