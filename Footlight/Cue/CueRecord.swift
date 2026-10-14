import Foundation

/// One block in a pet column, produced from a routine and stacked by sort order.
/// Identity is the cue id. List position is never identity.
struct CueRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var petID: UUID
    var routineID: UUID
    var title: String
    var sortOrder: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        petID: UUID,
        routineID: UUID,
        title: String,
        sortOrder: Int,
        isActive: Bool
    ) {
        self.id = id
        self.petID = petID
        self.routineID = routineID
        self.title = title
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
}
