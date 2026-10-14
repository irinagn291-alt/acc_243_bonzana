import Foundation

/// Simulator-only opening company. Several pets, several cues, and a strike
/// already on the first cue of the lead column so the next swipe is the second
/// cue or another column head. A device never receives this document.
enum DemoSeed {
    static let defaultsKey = "ftl.demo.v1"

    static func shouldApply(isSimulator: Bool, alreadySeeded: Bool) -> Bool {
        isSimulator && alreadySeeded == false
    }

    static func document(now: Date, calendar: Calendar) -> GridDocument {
        let moth = PetRecord(name: "Moth", species: "Cat", accentSlot: "violet")
        let bramble = PetRecord(name: "Bramble", species: "Dog", accentSlot: "ink")
        let pike = PetRecord(name: "Pike", species: "Bird", accentSlot: "mist")

        let mothFeed = routine(pet: moth, title: "Morning feed", sortOrder: 0)
        let mothWalk = routine(pet: moth, title: "Evening walk", sortOrder: 1)
        let brambleFeed = routine(pet: bramble, title: "Morning feed", sortOrder: 0)
        let brambleMeds = routine(pet: bramble, title: "Evening meds", sortOrder: 1)
        let pikeFeed = routine(pet: pike, title: "Morning feed", sortOrder: 0)

        let cues = [mothFeed, mothWalk, brambleFeed, brambleMeds, pikeFeed].map(cue(from:))
        let lead = cues[0]
        let daykey = Daykey.make(from: now, calendar: calendar)
        let strike = StrikeMark(
            cueID: lead.id,
            routineID: lead.routineID,
            petID: lead.petID,
            daykey: daykey,
            struckAt: now
        )
        return GridDocument(
            schemaVersion: GridDocument.currentSchema,
            pets: [moth, bramble, pike],
            routines: [mothFeed.routine, mothWalk.routine, brambleFeed.routine, brambleMeds.routine, pikeFeed.routine],
            cues: cues,
            strikeMarks: [strike],
            leapMarks: [],
            curtainMarks: [],
            onboardingComplete: true,
            recoveryNotice: nil,
            calendar: calendar
        )
    }

    private struct Pair {
        var routine: RoutineRecord
        var cueID: UUID
    }

    private static func routine(pet: PetRecord, title: String, sortOrder: Int) -> Pair {
        let routine = RoutineRecord(
            petID: pet.id,
            title: title,
            sortOrder: sortOrder,
            isActive: true
        )
        return Pair(routine: routine, cueID: UUID())
    }

    private static func cue(from pair: Pair) -> CueRecord {
        CueRecord(
            id: pair.cueID,
            petID: pair.routine.petID,
            routineID: pair.routine.id,
            title: pair.routine.title,
            sortOrder: pair.routine.sortOrder,
            isActive: pair.routine.isActive
        )
    }
}
