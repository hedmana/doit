import Foundation
import Testing
@testable import DoitCore

struct TodoListTests {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_790_000_000)

    func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now)! }

    func titles(_ list: TodoList, _ todos: [Todo]) -> [String] {
        list.todos(from: todos, now: now, calendar: calendar).map(\.title)
    }

    @Test func datesRouteToLists() {
        let tomorrow = calendar.startOfDay(for: day(1))
        let todos = [
            Todo(title: "overdue", date: day(-2)),
            Todo(title: "later", date: day(5)),
            Todo(title: "end of today", date: tomorrow.addingTimeInterval(-1)),
            Todo(title: "start of tomorrow", date: tomorrow),
            Todo(title: "undated"),
        ]
        #expect(titles(.today, todos) == ["overdue", "end of today"])
        #expect(titles(.upcoming, todos) == ["start of tomorrow", "later"])
        #expect(titles(.anytime, todos) == ["undated"])
    }

    @Test func urgentAlsoAppearsInDateList() {
        let todos = [Todo(title: "fire", date: now, isUrgent: true), Todo(title: "calm", date: now)]
        #expect(titles(.urgent, todos) == ["fire"])
        #expect(titles(.today, todos) == ["fire", "calm"])
    }

    @Test func completedOnlyInLogbookNewestFirst() {
        var older = Todo(title: "older", date: now, isUrgent: true)
        older.completedAt = day(-1)
        var newer = Todo(title: "newer")
        newer.completedAt = now
        let todos = [older, newer]
        for list in TodoList.allCases where list != .logbook {
            #expect(titles(list, todos).isEmpty)
        }
        #expect(titles(.logbook, todos) == ["newer", "older"])
    }
}
