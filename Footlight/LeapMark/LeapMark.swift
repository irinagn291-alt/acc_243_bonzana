import Foundation

/// A swipe that landed below the column head.
/// Order of cues stays put. The fold phase does not change.
struct LeapMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var cueID: UUID
    var petID: UUID
    var daykey: Int
    var leapedAt: Date

    init(id: UUID = UUID(), cueID: UUID, petID: UUID, daykey: Int, leapedAt: Date) {
        self.id = id
        self.cueID = cueID
        self.petID = petID
        self.daykey = daykey
        self.leapedAt = leapedAt
    }
}
