import Foundation

/// A chore attached to one pet, ordered inside that pet's column.
/// Active routines are the only ones the day-complete rule counts.
struct RoutineRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var petID: UUID
    var title: String
    var sortOrder: Int
    var isActive: Bool

    init(id: UUID = UUID(), petID: UUID, title: String, sortOrder: Int, isActive: Bool) {
        self.id = id
        self.petID = petID
        self.title = title
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
}
