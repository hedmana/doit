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
}
