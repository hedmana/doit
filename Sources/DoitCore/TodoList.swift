import Foundation

public enum TodoList: String, CaseIterable, Identifiable, Sendable {
    case today, upcoming, anytime, urgent, logbook

    public var id: Self { self }

    public func todos(from all: [Todo], now: Date = .now, calendar: Calendar = .current) -> [Todo] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let open = all.filter { !$0.isCompleted }
        switch self {
        case .today: return open.filter { $0.date ?? .distantFuture < tomorrow }
        case .upcoming: return open.filter { $0.date ?? .distantPast >= tomorrow }.sorted { $0.date! < $1.date! }
        case .anytime: return open.filter { $0.date == nil }
        case .urgent: return open.filter(\.isUrgent)
        case .logbook: return all.filter(\.isCompleted).sorted { $0.completedAt! > $1.completedAt! }
        }
    }

    public var isGroupedByDay: Bool { self == .upcoming || self == .logbook }

    public func days(from all: [Todo], now: Date = .now, calendar: Calendar = .current) -> [(day: Date, todos: [Todo])] {
        var days: [(day: Date, todos: [Todo])] = []
        for todo in todos(from: all, now: now, calendar: calendar) {
            let day = calendar.startOfDay(for: self == .logbook ? todo.completedAt! : todo.date!)
            if days.last?.day == day { days[days.count - 1].todos.append(todo) } else { days.append((day, [todo])) }
        }
        return days
    }

    public func newTodo(titled title: String, now: Date = .now, calendar: Calendar = .current) -> Todo {
        let today = calendar.startOfDay(for: now)
        switch self {
        case .today: return Todo(title: title, date: today)
        case .upcoming: return Todo(title: title, date: calendar.date(byAdding: .day, value: 1, to: today))
        case .urgent: return Todo(title: title, isUrgent: true)
        case .anytime, .logbook: return Todo(title: title)
        }
    }
}
