import DoitCore
import SwiftUI

@main
struct DoitApp: App {
    @State private var store = TodoStore(fileURL: UserDefaults.standard.url(forKey: "storeURL") ?? TodoStore.defaultURL)

    var body: some Scene {
        Window("Doit", id: "main") {
            ContentView()
                .environment(store)
                .frame(minWidth: 700, minHeight: 450)
        }
        .commands { TodoCommands(store: store) }
    }
}
