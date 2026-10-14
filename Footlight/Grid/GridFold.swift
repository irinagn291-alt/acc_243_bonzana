import Foundation

/// Column-relay fold over cues for one daykey.
/// Blank: no active cue. Open: cues exist and none is struck.
/// Clearing: at least one strike and at least one active routine still open.
/// Curtain: every active routine holds a StrikeMark. Swipe is refused there.
struct GridFold: Equatable, Sendable {
    var daykey: Int
    var phase: GridPhase
    var columns: [PetColumn]
    var streak: Int

    struct PetColumn: Equatable, Sendable, Identifiable {
        var id: UUID { petID }
        var petID: UUID
        var cues: [CueRecord]
        var head: ColumnHead?
    }

    static func activeRoutines(in document: GridDocument) -> [RoutineRecord] {
        let petIDs = Set(document.pets.map(\.id))
        return document.routines.filter { $0.isActive && petIDs.contains($0.petID) }
    }

    static func activeCues(in document: GridDocument) -> [CueRecord] {
        let routineIDs = Set(activeRoutines(in: document).map(\.id))
        return document.cues.filter { $0.isActive && routineIDs.contains($0.routineID) }
    }

    static func isDayComplete(_ document: GridDocument, daykey: Int) -> Bool {
        let routines = activeRoutines(in: document)
        guard routines.isEmpty == false else { return false }
        let struck = ColumnHeadResolver.struckRoutineIDs(in: document, daykey: daykey)
        return routines.allSatisfy { struck.contains($0.id) }
    }

    /// Walks backward from `daykey` and stops at the first incomplete day.
    static func streak(in document: GridDocument, endingAt daykey: Int, calendar: Calendar) -> Int {
        var count = 0
        var cursor: Int? = daykey
        while let key = cursor {
            if isDayComplete(document, daykey: key) == false {
                break
            }
            count += 1
            cursor = Daykey.previous(key, calendar: calendar)
        }
        return count
    }

    static func make(document: GridDocument, daykey: Int, calendar: Calendar) -> GridFold {
        let cues = activeCues(in: document)
        let phase = phase(of: document, daykey: daykey, activeCueCount: cues.count)
        let columns = document.pets.map { pet in
            PetColumn(
                petID: pet.id,
                cues: ColumnHeadResolver.stackedCues(in: document, petID: pet.id),
                head: ColumnHeadResolver.head(in: document, petID: pet.id, daykey: daykey)
            )
        }
        return GridFold(
            daykey: daykey,
            phase: phase,
            columns: columns,
            streak: streak(in: document, endingAt: daykey, calendar: calendar)
        )
    }

    static func phase(of document: GridDocument, daykey: Int, activeCueCount: Int) -> GridPhase {
        if activeCueCount == 0 {
            return .blank
        }
        let struck = ColumnHeadResolver.struckRoutineIDs(in: document, daykey: daykey)
        if struck.isEmpty {
            return .open
        }
        if isDayComplete(document, daykey: daykey) {
            return .curtain
        }
        return .clearing
    }
}

enum GridPhase: String, Codable, Equatable, Sendable {
    case blank
    case open
    case clearing
    case curtain
}

enum GridRefusal: Equatable, Sendable {
    case blankGrid
    case curtainSealed
    case peelOnOpen
    case unknownCue
    case inactiveCue
}

enum GridCommit: Equatable, Sendable {
    case struck(StrikeMark, phase: GridPhase)
    case leaped(LeapMark, phase: GridPhase)
    case sealed(StrikeMark, CurtainMark)
    case peeled(StrikeMark, at: Date)
    case refused(GridRefusal)
}

enum GridRelay {
    /// Right swipe. Column head writes a strike. Any other cue in the column writes a leap.
    static func swipe(
        document: inout GridDocument,
        cueID: UUID,
        daykey: Int,
        now: Date
    ) -> GridCommit {
        let calendar = document.calendar
        let before = GridFold.make(document: document, daykey: daykey, calendar: calendar)
        switch before.phase {
        case .blank:
            return .refused(.blankGrid)
        case .curtain:
            return .refused(.curtainSealed)
        case .open, .clearing:
            break
        }
        guard let cue = document.cues.first(where: { $0.id == cueID }) else {
            return .refused(.unknownCue)
        }
        guard cue.isActive else {
            return .refused(.inactiveCue)
        }
        let head = ColumnHeadResolver.head(in: document, petID: cue.petID, daykey: daykey)
        if head?.cueID == cue.id {
            if document.strikeMarks.contains(where: { $0.routineID == cue.routineID && $0.daykey == daykey }) {
                return .refused(.unknownCue)
            }
            let mark = StrikeMark(
                cueID: cue.id,
                routineID: cue.routineID,
                petID: cue.petID,
                daykey: daykey,
                struckAt: now
            )
            document.strikeMarks.append(mark)
            if GridFold.isDayComplete(document, daykey: daykey) {
                let curtain = CurtainMark(daykey: daykey, sealedAt: now)
                document.curtainMarks.removeAll { $0.daykey == daykey }
                document.curtainMarks.append(curtain)
                return .sealed(mark, curtain)
            }
            let phase = GridFold.phase(
                of: document,
                daykey: daykey,
                activeCueCount: GridFold.activeCues(in: document).count
            )
            return .struck(mark, phase: phase)
        }
        let leap = LeapMark(cueID: cue.id, petID: cue.petID, daykey: daykey, leapedAt: now)
        document.leapMarks.append(leap)
        return .leaped(leap, phase: before.phase)
    }
}
