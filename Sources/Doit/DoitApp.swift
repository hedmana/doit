import DoitCore
import SwiftUI

@main
struct DoitApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        Window("Doit", id: "main") {
            ContentView()
                .environment(store)
                .frame(minWidth: 700, minHeight: 450)
        }
    }
}
