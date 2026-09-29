import DoitCore
import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let now: Date
    let list: TodoList
    @Environment(TodoStore.self) private var store
    @State private var title: String
    @State private var isPickingDate = false
    @State private var isHovering = false
    @FocusState private var isEditing: Bool

    init(todo: Todo, now: Date, list: TodoList) {
        self.todo = todo
        self.now = now
        self.list = list
        _title = State(initialValue: todo.title)
    }

    var body: some View {
        HStack {
            Button {
                withAnimation { store.toggleComplete(todo.id) }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .focused($isEditing)
                .disabled(todo.isCompleted)
                .onSubmit(commitTitle)
                .onChange(of: isEditing) { if !isEditing { commitTitle() } }
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
        .contextMenu {
            if !todo.isCompleted {
                Button(todo.isUrgent ? "Remove Urgent" : "Mark Urgent") { store.update(todo.id) { $0.isUrgent.toggle() } }
                Button("Schedule for Today") { schedule(daysFromNow: 0) }
                Button("Schedule for Tomorrow") { schedule(daysFromNow: 1) }
                Button("Remove Date") { schedule(daysFromNow: nil) }.disabled(todo.date == nil)
                Divider()
            }
            Button("Delete", role: .destructive) { withAnimation { store.delete(todo.id) } }
        }
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
                store.update(todo.id) { $0.date = Calendar.current.startOfDay(for: date) }
                isPickingDate = false
            }), displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            Button("Remove Date") {
                schedule(daysFromNow: nil)
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

    private func schedule(daysFromNow days: Int?) {
        let calendar = Calendar.current
        withAnimation {
            store.update(todo.id) { todo in
                todo.date = days.flatMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now)) }
            }
        }
    }

    private func commitTitle() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            title = todo.title
            return
        }
        if trimmed != todo.title { store.update(todo.id) { $0.title = trimmed } }
    }
}
