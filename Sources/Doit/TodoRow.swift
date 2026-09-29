import DoitCore
import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let now: Date
    let list: TodoList
    let editing: FocusState<Todo.ID?>.Binding
    @Environment(TodoStore.self) private var store
    @State private var title: String
    @State private var isPickingDate = false
    @State private var isHovering = false

    init(todo: Todo, now: Date, list: TodoList, editing: FocusState<Todo.ID?>.Binding) {
        self.todo = todo
        self.now = now
        self.list = list
        self.editing = editing
        _title = State(initialValue: todo.title)
    }

    var body: some View {
        HStack {
            Button {
                withAnimation { store.toggleComplete([todo.id]) }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .focused(editing, equals: todo.id)
                .disabled(todo.isCompleted)
                .onSubmit(commitTitle)
                .onChange(of: editing.wrappedValue == todo.id) { _, isEditing in if !isEditing { commitTitle() } }
                .onChange(of: todo.title) { title = todo.title }

            if todo.isUrgent && list != .urgent {
                Image(systemName: "flag.fill").foregroundStyle(.orange)
            }

            if !todo.isCompleted {
                Button { isPickingDate = true } label: { dateLabel }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isPickingDate) { datePicker }
            }
        }
        .onHover { isHovering = $0 }
    }

    @ViewBuilder private var dateLabel: some View {
        let calendar = Calendar.current
        // Upcoming shows dates as section headers, Today implies today
        if let date = todo.date, list != .upcoming, !(list == .today && calendar.isDate(date, inSameDayAs: now)) {
            let isOverdue = date < calendar.startOfDay(for: now)
            Text(dayText(date, calendar: calendar))
                .font(.callout)
                .foregroundStyle(isOverdue ? .red : .secondary)
        } else {
            Image(systemName: "calendar").foregroundStyle(.tertiary).opacity(isHovering || isPickingDate ? 1 : 0)
        }
    }

    private var datePicker: some View {
        VStack {
            DatePicker("When", selection: Binding(get: { todo.date ?? now }, set: { date in
                store.update([todo.id]) { $0.date = Calendar.current.startOfDay(for: date) }
                isPickingDate = false
            }), displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            Button("Remove Date") {
                withAnimation { store.schedule([todo.id], daysFromNow: nil) }
                isPickingDate = false
            }
            .disabled(todo.date == nil)
        }
        .padding()
    }

    private func dayText(_ date: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private func commitTitle() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            title = todo.title
            return
        }
        if trimmed != todo.title { store.update([todo.id]) { $0.title = trimmed } }
    }
}
