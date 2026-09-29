import Foundation

public struct Todo: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var title: String
    public var date: Date?
    public var isUrgent: Bool
    public var createdAt = Date()
    public var completedAt: Date?

    public init(title: String, date: Date? = nil, isUrgent: Bool = false) {
        self.title = title
        self.date = date
        self.isUrgent = isUrgent
    }

    public var isCompleted: Bool { completedAt != nil }
}
