import DoitCore
import SwiftUI

struct ContentView: View {
    @Environment(TodoStore.self) private var store
    @Environment(\.undoManager) private var undoManager
    @State private var selection: TodoList? = .today
    @State private var now = Date.now

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach([TodoList.today, .upcoming, .anytime, .urgent]) { sidebarRow($0) }
                }
                Section { sidebarRow(.logbook) }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if let selection {
                TodoListView(list: selection, now: now)
                    .id(selection)
            }
        }
        .onAppear { store.undoManager = undoManager }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            now = .now
        }
    }

    private func sidebarRow(_ list: TodoList) -> some View {
        Label {
            Text(list.title)
        } icon: {
            Image(systemName: list.icon).foregroundStyle(list.tint)
        }
        .badge(list == .logbook ? 0 : list.todos(from: store.todos, now: now).count)
        .tag(list)
    }
}
