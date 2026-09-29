import Foundation
import Testing
@testable import DoitCore

struct TodoListTests {
    let calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
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

    @Test func newTodoLandsInItsList() {
        for list in TodoList.allCases where list != .logbook {
            #expect(titles(list, [list.newTodo(titled: "new", now: now, calendar: calendar)]) == ["new"])
        }
    }

    @Test func logbookGroupsByCompletionDayNewestFirst() {
        let completions = [day(-1), now, day(-1).addingTimeInterval(60), now.addingTimeInterval(-60)]
        let todos = completions.enumerated().map { index, date in
            var todo = Todo(title: "\(index)")
            todo.completedAt = date
            return todo
        }
        let days = TodoList.logbookDays(from: todos, calendar: calendar)
        #expect(days.map(\.day) == [calendar.startOfDay(for: now), calendar.startOfDay(for: day(-1))])
        #expect(days.map { $0.todos.map(\.title) } == [["1", "3"], ["2", "0"]])
    }
}
