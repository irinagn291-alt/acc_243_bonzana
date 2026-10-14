import Foundation

/// A committed strike on one cue for one YYYYMMDD daykey.
/// This is the chore log. A day is complete only when every active routine has one.
struct StrikeMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var cueID: UUID
    var routineID: UUID
    var petID: UUID
    var daykey: Int
    var struckAt: Date

    init(
        id: UUID = UUID(),
        cueID: UUID,
        routineID: UUID,
        petID: UUID,
        daykey: Int,
        struckAt: Date
    ) {
        self.id = id
        self.cueID = cueID
        self.routineID = routineID
        self.petID = petID
        self.daykey = daykey
        self.struckAt = struckAt
    }
}
