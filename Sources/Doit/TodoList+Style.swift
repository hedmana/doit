import DoitCore
import SwiftUI

extension TodoList {
    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .today: "star.fill"
        case .upcoming: "calendar"
        case .anytime: "square.stack.fill"
        case .urgent: "flag.fill"
        case .logbook: "book.closed.fill"
        }
    }

    var tint: Color {
        switch self {
        case .today: .yellow
        case .upcoming: .red
        case .anytime: .teal
        case .urgent: .orange
        case .logbook: .green
        }
    }
}
