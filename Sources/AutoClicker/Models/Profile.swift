import Foundation

struct TimingProfile: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var seconds: [Int]
    var advanceKey: AdvanceKey
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        seconds: [Int],
        advanceKey: AdvanceKey = .space,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.seconds = seconds
        self.advanceKey = advanceKey
        self.updatedAt = updatedAt
    }
}
