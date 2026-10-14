import Foundation

/// The top unstruck cue in one pet column.
/// Only this cue accepts a swipe that writes a StrikeMark.
struct ColumnHead: Equatable, Sendable {
    var petID: UUID
    var cueID: UUID
    var routineID: UUID
}

enum ColumnHeadResolver {
    /// Cues in a column, top to bottom, by routine priority.
    static func stackedCues(in document: GridDocument, petID: UUID) -> [CueRecord] {
        GridFold.activeCues(in: document)
            .filter { $0.petID == petID }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    static func head(in document: GridDocument, petID: UUID, daykey: Int) -> ColumnHead? {
        let struck = struckRoutineIDs(in: document, daykey: daykey)
        guard let cue = stackedCues(in: document, petID: petID).first(where: { struck.contains($0.routineID) == false }) else {
            return nil
        }
        return ColumnHead(petID: petID, cueID: cue.id, routineID: cue.routineID)
    }

    static func struckRoutineIDs(in document: GridDocument, daykey: Int) -> Set<UUID> {
        Set(document.strikeMarks.filter { $0.daykey == daykey }.map(\.routineID))
    }
}
