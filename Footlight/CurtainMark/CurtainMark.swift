import Foundation

/// Written once when every active routine holds a strike for the daykey.
/// The streak rail counts these seals. It is removed when the day is no longer complete.
struct CurtainMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var daykey: Int
    var sealedAt: Date

    init(id: UUID = UUID(), daykey: Int, sealedAt: Date) {
        self.id = id
        self.daykey = daykey
        self.sealedAt = sealedAt
    }
}
