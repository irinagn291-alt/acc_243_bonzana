import SwiftUI

/// The presentation seam over GridStore.
/// It folds the daykey for Today, commits swipe and peel, and opens sheets.
/// Launch arguments are read once, and only after onboarding is complete.
@MainActor
final class HouseSession: ObservableObject {
    @Published private(set) var document: GridDocument
    @Published private(set) var fold: GridFold
    @Published var showOnboarding: Bool
    @Published var petsPresented = false
    @Published var routinesPresented = false
    @Published var settingsPresented = false
    @Published var curtainPresented = false
    @Published var formError: String?
    @Published private(set) var isReady = false
    @Published private(set) var isBusy = false
    @Published var sealVisible = false

    private let store: GridStore
    private var didReadLaunch = false
    private var dayWatch: Task<Void, Never>?
    private var lastCommitCue: (id: UUID, at: Date)?
    private let clock: () -> Date

    init(store: GridStore, clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.clock = clock
        let empty = GridDocument.empty
        document = empty
        fold = GridFold.make(document: empty, daykey: 0, calendar: empty.calendar)
        showOnboarding = false
    }

    static func live() -> HouseSession {
        HouseSession(store: .live())
    }

    func start() async {
        let simulator = HouseSession.runningInSimulator
        await store.bootstrap(isSimulator: simulator)
        await reload()
        showOnboarding = document.onboardingComplete == false
        isReady = true
        applyLaunchIfReady()
        watchDayChange()
    }

    func refreshDay() async {
        guard isReady else { return }
        await reload()
    }

    func reload() async {
        document = await store.snapshot()
        fold = await store.fold(on: clock())
    }

    func flush() async {
        await store.flushForSceneExit()
    }

    func swipe(cueID: UUID) async {
        let now = clock()
        if let last = lastCommitCue, last.id == cueID, now.timeIntervalSince(last.at) < 0.45 {
            return
        }
        guard isBusy == false else { return }
        isBusy = true
        lastCommitCue = (cueID, now)
        defer { isBusy = false }
        let commit = await store.swipe(cueID: cueID, on: now)
        await reload()
        switch commit {
        case .struck, .sealed:
            HouseHaptic.commit()
            flashSeal()
        case .leaped, .peeled, .refused:
            break
        }
    }

    func peel() async {
        guard isBusy == false else { return }
        isBusy = true
        defer { isBusy = false }
        sealVisible = false
        _ = await store.peel(on: clock())
        await reload()
    }

    private func flashSeal() {
        sealVisible = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            sealVisible = false
        }
    }

    private func watchDayChange() {
        dayWatch?.cancel()
        dayWatch = Task { @MainActor in
            while Task.isCancelled == false {
                let now = clock()
                let start = document.calendar.startOfDay(for: now)
                let next = document.calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(60 * 60)
                let pause = max(1, next.timeIntervalSince(now))
                try? await Task.sleep(for: .seconds(pause))
                if Task.isCancelled { return }
                await reload()
            }
        }
    }

    func finishOnboarding(skip: Bool) async {
        var next = document
        if skip && next.pets.isEmpty {
            let pet = PetRecord(name: "Moth", species: "Cat", accentSlot: "violet")
            let routine = RoutineRecord(petID: pet.id, title: "Morning feed", sortOrder: 0, isActive: true)
            let cue = CueRecord(
                petID: pet.id,
                routineID: routine.id,
                title: routine.title,
                sortOrder: routine.sortOrder,
                isActive: true
            )
            next.pets = [pet]
            next.routines = [routine]
            next.cues = [cue]
        }
        next.onboardingComplete = true
        await store.replaceDocument(next)
        await reload()
        showOnboarding = false
        applyLaunchIfReady()
    }

    func replayOnboarding() {
        showOnboarding = true
        settingsPresented = false
    }

    func resetGrid() async {
        await store.resetAllData()
        await reload()
        showOnboarding = true
        settingsPresented = false
        petsPresented = false
        routinesPresented = false
        curtainPresented = false
    }

    func savePets(_ pets: [PetRecord]) async {
        var next = document
        let kept = Set(pets.map(\.id))
        next.pets = pets
        next.routines.removeAll { kept.contains($0.petID) == false }
        let routineIDs = Set(next.routines.map(\.id))
        next.cues.removeAll { kept.contains($0.petID) == false || routineIDs.contains($0.routineID) == false }
        next.strikeMarks.removeAll { kept.contains($0.petID) == false }
        next.leapMarks.removeAll { kept.contains($0.petID) == false }
        await store.replaceDocument(next)
        await reload()
    }

    func saveRoutines(_ routines: [RoutineRecord]) async {
        var next = document
        next.routines = routines
        var cues = next.cues
        let ids = Set(routines.map(\.id))
        cues.removeAll { ids.contains($0.routineID) == false }
        for routine in routines {
            if let index = cues.firstIndex(where: { $0.routineID == routine.id }) {
                cues[index].petID = routine.petID
                cues[index].title = routine.title
                cues[index].sortOrder = routine.sortOrder
                cues[index].isActive = routine.isActive
            } else {
                cues.append(
                    CueRecord(
                        petID: routine.petID,
                        routineID: routine.id,
                        title: routine.title,
                        sortOrder: routine.sortOrder,
                        isActive: routine.isActive
                    )
                )
            }
        }
        next.cues = cues
        let activeRoutineIDs = Set(routines.map(\.id))
        next.strikeMarks.removeAll { activeRoutineIDs.contains($0.routineID) == false }
        await store.replaceDocument(next)
        await reload()
    }

    var dayLine: String {
        switch fold.phase {
        case .blank:
            return "The stage is empty until a pet has a chore."
        case .open:
            return "Strike the top open chore in a column."
        case .clearing:
            return "Keep striking the top open chore in each column."
        case .curtain:
            return "Every chore is struck. This day is sealed."
        }
    }

    var nextTapLine: String {
        if let head = nextHeadCue() {
            let pet = document.pets.first(where: { $0.id == head.petID })?.name ?? "A pet"
            return "Swipe \(head.title) under \(pet)."
        }
        if fold.phase == .curtain {
            return "Undo the last strike if this seal was early."
        }
        return emptyLine
    }

    var emptyLine: String {
        "Add a pet and a routine"
    }

    var canUndo: Bool {
        fold.phase == .clearing || fold.phase == .curtain
    }

    func pet(for id: UUID) -> PetRecord? {
        document.pets.first { $0.id == id }
    }

    func isStruck(_ cue: CueRecord) -> Bool {
        document.strikeMarks.contains { $0.cueID == cue.id && $0.daykey == fold.daykey }
            || document.strikeMarks.contains { $0.routineID == cue.routineID && $0.daykey == fold.daykey }
    }

    private func nextHeadCue() -> CueRecord? {
        for column in fold.columns {
            guard let head = column.head else { continue }
            return column.cues.first { $0.id == head.cueID }
        }
        return nil
    }

    private func applyLaunchIfReady() {
        guard document.onboardingComplete, showOnboarding == false, didReadLaunch == false else {
            return
        }
        didReadLaunch = true
        switch ReviewLaunch.screen {
        case "log", "routines", "routine":
            routinesPresented = true
        case "goals", "pets", "pet":
            petsPresented = true
        case "settings":
            settingsPresented = true
        case "curtain", "seals":
            curtainPresented = true
        default:
            break
        }
    }

    private static var runningInSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}

@MainActor
enum HouseHaptic {
    static func commit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
