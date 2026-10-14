import XCTest
@testable import Footlight

final class FootlightTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    func testDayCompleteIffEveryActiveRoutineHasAStrike() {
        let today = date(2026, 9, 27)
        let key = Daykey.make(from: today, calendar: calendar)
        var document = household(on: today).document
        XCTAssertFalse(GridFold.isDayComplete(document, daykey: key))

        let active = GridFold.activeRoutines(in: document)
        for routine in active.dropLast() {
            document.strikeMarks.append(strike(for: routine, in: document, daykey: key, at: today))
        }
        XCTAssertFalse(GridFold.isDayComplete(document, daykey: key))

        if let last = active.last {
            document.strikeMarks.append(strike(for: last, in: document, daykey: key, at: today))
        }
        XCTAssertTrue(GridFold.isDayComplete(document, daykey: key))

        document.routines[document.routines.count - 1].isActive = false
        let stillActive = GridFold.activeRoutines(in: document)
        document.strikeMarks.removeAll { mark in
            stillActive.contains(where: { $0.id == mark.routineID }) == false
        }
        XCTAssertTrue(GridFold.isDayComplete(document, daykey: key))
    }

    /// Walks sealed days only. Not an OLS fit. Not a COSC band.
    func testStreakWalksBackwardOnlyWhileDaysStayComplete() {
        let today = date(2026, 9, 27)
        let yesterday = date(2026, 9, 26)
        let gap = date(2026, 9, 25)
        let todayKey = Daykey.make(from: today, calendar: calendar)
        let yesterdayKey = Daykey.make(from: yesterday, calendar: calendar)
        let gapKey = Daykey.make(from: gap, calendar: calendar)
        var document = household(on: today).document
        let routines = GridFold.activeRoutines(in: document)

        XCTAssertEqual(GridFold.streak(in: document, endingAt: todayKey, calendar: calendar), 0)

        for routine in routines {
            document.strikeMarks.append(strike(for: routine, in: document, daykey: yesterdayKey, at: yesterday))
        }
        XCTAssertEqual(GridFold.streak(in: document, endingAt: todayKey, calendar: calendar), 0)

        for routine in routines {
            document.strikeMarks.append(strike(for: routine, in: document, daykey: todayKey, at: today))
        }
        XCTAssertEqual(GridFold.streak(in: document, endingAt: todayKey, calendar: calendar), 2)

        for routine in routines {
            document.strikeMarks.append(strike(for: routine, in: document, daykey: gapKey, at: gap))
        }
        XCTAssertEqual(GridFold.streak(in: document, endingAt: todayKey, calendar: calendar), 3)

        document.strikeMarks.removeAll { $0.daykey == yesterdayKey && $0.routineID == routines[0].id }
        XCTAssertEqual(GridFold.streak(in: document, endingAt: todayKey, calendar: calendar), 1)
    }

    func testPrimaryVerbEmptyPopulatedAndInvalid() {
        let today = date(2026, 9, 27)
        let key = Daykey.make(from: today, calendar: calendar)
        var empty = GridDocument.empty
        empty.calendar = calendar
        let blank = GridRelay.swipe(document: &empty, cueID: UUID(), daykey: key, now: today)
        XCTAssertEqual(blank, .refused(.blankGrid))
        XCTAssertEqual(GridFold.make(document: empty, daykey: key, calendar: calendar).phase, .blank)

        var house = household(on: today)
        let struck = GridRelay.swipe(document: &house.document, cueID: house.mothTop.id, daykey: key, now: today)
        guard case .struck = struck else {
            XCTFail("Expected a strike on the column head")
            return
        }
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .clearing)

        let unknown = GridRelay.swipe(document: &house.document, cueID: UUID(), daykey: key, now: today)
        XCTAssertEqual(unknown, .refused(.unknownCue))
    }

    func testColumnRelayTwist() {
        let today = date(2026, 9, 27)
        let key = Daykey.make(from: today, calendar: calendar)
        var house = household(on: today)
        let order = house.document.cues.map(\.id)

        let leap = GridRelay.swipe(document: &house.document, cueID: house.mothNext.id, daykey: key, now: today)
        guard case .leaped(_, let phase) = leap else {
            XCTFail("A lower cue writes a leap")
            return
        }
        XCTAssertEqual(phase, .open)
        XCTAssertTrue(house.document.strikeMarks.isEmpty)
        XCTAssertEqual(house.document.cues.map(\.id), order)

        let lead = GridRelay.swipe(document: &house.document, cueID: house.mothTop.id, daykey: key, now: today)
        guard case .struck = lead else {
            XCTFail("Column head writes a strike")
            return
        }
        XCTAssertEqual(
            ColumnHeadResolver.head(in: house.document, petID: house.mothTop.petID, daykey: key)?.cueID,
            house.mothNext.id
        )
        let next = GridRelay.swipe(document: &house.document, cueID: house.mothNext.id, daykey: key, now: today)
        guard case .struck = next else {
            XCTFail("The new column head writes a strike")
            return
        }
        let other = GridRelay.swipe(document: &house.document, cueID: house.brambleTop.id, daykey: key, now: today)
        guard case .sealed = other else {
            XCTFail("The last open routine seals the curtain")
            return
        }
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .curtain)
        XCTAssertEqual(house.document.curtainMarks.filter { $0.daykey == key }.count, 1)

        let refused = GridRelay.swipe(document: &house.document, cueID: house.mothNext.id, daykey: key, now: today)
        XCTAssertEqual(refused, .refused(.curtainSealed))
        XCTAssertEqual(house.document.cues.map(\.id), order)
    }

    func testFoldPhasesAndPeel() {
        let today = date(2026, 9, 27)
        let key = Daykey.make(from: today, calendar: calendar)
        var house = household(on: today)
        house.document.routines[1].isActive = false
        house.document.cues[1].isActive = false
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .open)

        let peelOpen = PeelStrike.apply(to: &house.document, daykey: key, now: today)
        XCTAssertEqual(peelOpen, .refused(.peelOnOpen))

        _ = GridRelay.swipe(document: &house.document, cueID: house.mothTop.id, daykey: key, now: today)
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .clearing)
        _ = GridRelay.swipe(document: &house.document, cueID: house.brambleTop.id, daykey: key, now: today)
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .curtain)

        let reopened = PeelStrike.apply(to: &house.document, daykey: key, now: today)
        guard case .peeled = reopened else {
            XCTFail("Peel removes the last strike")
            return
        }
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .clearing)
        XCTAssertTrue(house.document.curtainMarks.filter { $0.daykey == key }.isEmpty)

        _ = PeelStrike.apply(to: &house.document, daykey: key, now: today)
        XCTAssertEqual(GridFold.make(document: house.document, daykey: key, calendar: calendar).phase, .open)
        XCTAssertTrue(house.document.strikeMarks.filter { $0.daykey == key }.isEmpty)
    }

    func testSingleCueSealsOnTheSameCommitThatLeavesOpen() {
        let today = date(2026, 9, 27)
        let key = Daykey.make(from: today, calendar: calendar)
        var document = GridDocument.empty
        document.calendar = calendar
        let pet = PetRecord(name: "Moth", species: "Cat", accentSlot: "violet")
        let routine = RoutineRecord(petID: pet.id, title: "Morning feed", sortOrder: 0, isActive: true)
        let cue = CueRecord(
            petID: pet.id,
            routineID: routine.id,
            title: routine.title,
            sortOrder: 0,
            isActive: true
        )
        document.pets = [pet]
        document.routines = [routine]
        document.cues = [cue]
        let commit = GridRelay.swipe(document: &document, cueID: cue.id, daykey: key, now: today)
        guard case .sealed = commit else {
            XCTFail("One active routine folds Open straight to Curtain")
            return
        }
        XCTAssertEqual(GridFold.make(document: document, daykey: key, calendar: calendar).phase, .curtain)
    }

    func testDaykeyRollKeepsPriorMarksAndOpensTheNewDay() {
        let today = date(2026, 9, 27, hour: 23)
        let tomorrow = date(2026, 9, 28, hour: 1)
        let todayKey = Daykey.make(from: today, calendar: calendar)
        let tomorrowKey = Daykey.make(from: tomorrow, calendar: calendar)
        XCTAssertEqual(todayKey, 20260927)
        XCTAssertEqual(tomorrowKey, 20260928)
        var house = household(on: today)
        _ = GridRelay.swipe(document: &house.document, cueID: house.mothTop.id, daykey: todayKey, now: today)
        let rolled = GridFold.make(document: house.document, daykey: tomorrowKey, calendar: calendar)
        XCTAssertEqual(rolled.phase, .open)
        XCTAssertFalse(house.document.strikeMarks.filter { $0.daykey == todayKey }.isEmpty)
        XCTAssertTrue(house.document.strikeMarks.filter { $0.daykey == tomorrowKey }.isEmpty)
        XCTAssertNotNil(rolled.columns.first?.head)
    }

    func testPersistenceRoundTripResetAndRecovery() async {
        let today = date(2026, 9, 27)
        let harness = Harness(calendar: calendar)
        let house = household(on: today)
        await harness.store.replaceDocument(house.document)
        await harness.store.flush()

        let reloaded = harness.reopen()
        await reloaded.store.load()
        let snapshot = await reloaded.store.snapshot()
        XCTAssertEqual(snapshot.pets.map(\.name), house.document.pets.map(\.name))
        XCTAssertEqual(snapshot.cues.map(\.id), house.document.cues.map(\.id))
        XCTAssertNil(snapshot.recoveryNotice)

        let encoded = await reloaded.store.snapshot()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data: Data?
        do {
            data = try encoder.encode(encoded)
        } catch {
            data = nil
        }
        let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        XCTAssertTrue(text.contains("\"schemaVersion\":1"))
        XCTAssertFalse(text.contains("streak"))

        await reloaded.store.resetAllData()
        let removed = await reloaded.store.projectionData()
        XCTAssertNil(removed)
        XCTAssertFalse(FileManager.default.fileExists(atPath: harness.fileURL.path))
        let cleared = await reloaded.store.snapshot()
        XCTAssertTrue(cleared.pets.isEmpty)

        await harness.store.replaceDocument(house.document)
        await harness.store.flush()
        await harness.store.replaceProjectionData(Data([0x7B, 0x7D]))
        let fromFile = harness.reopen()
        await fromFile.store.load()
        let restored = await fromFile.store.snapshot()
        XCTAssertEqual(restored.pets.count, house.document.pets.count)
        XCTAssertNotNil(restored.recoveryNotice)

        let backup = harness.fileURL.appendingPathComponent("", isDirectory: false)
        _ = backup
        guard let good = try? Data(contentsOf: harness.fileURL) else {
            XCTFail("Expected a grid file")
            return
        }
        do {
            try good.write(to: harness.backupURL, options: .atomic)
            try Data("broken".utf8).write(to: harness.fileURL, options: .atomic)
        } catch {
            XCTFail("Could not stage a corrupt grid")
            return
        }
        await harness.store.replaceProjectionData(Data("broken".utf8))
        let fromBackup = harness.reopen()
        await fromBackup.store.load()
        let backupPets = await fromBackup.store.snapshot()
        XCTAssertEqual(backupPets.pets.count, house.document.pets.count)

        do {
            try Data("nope".utf8).write(to: harness.fileURL, options: .atomic)
            try Data("nope".utf8).write(to: harness.backupURL, options: .atomic)
        } catch {
            XCTFail("Could not stage a fully corrupt grid")
            return
        }
        await harness.store.replaceProjectionData(Data("nope".utf8))
        let empty = harness.reopen()
        await empty.store.load()
        let failed = await empty.store.snapshot()
        XCTAssertTrue(failed.pets.isEmpty)
        XCTAssertNotNil(failed.recoveryNotice)

        let foreign = #"{"schemaVersion":9,"pets":[]}"#
        XCTAssertNil(GridStore.decode(Data(foreign.utf8)))
    }

    func testSimulatorSeedOnceAndDeviceNeverSeeds() async {
        let seeded = Harness(calendar: calendar)
        await seeded.store.bootstrap(isSimulator: true)
        let seededDocument = await seeded.store.snapshot()
        let names = seededDocument.pets.map(\.name)
        XCTAssertGreaterThanOrEqual(names.count, 3)
        XCTAssertTrue(seededDocument.onboardingComplete)
        let key = Daykey.make(from: Date(), calendar: calendar)
        let fold = GridFold.make(
            document: seededDocument,
            daykey: key,
            calendar: calendar
        )
        XCTAssertEqual(fold.phase, .clearing)
        XCTAssertNotNil(fold.columns.first?.head)
        XCTAssertNotEqual(fold.columns.first?.head?.cueID, fold.columns.first?.cues.first?.id)

        await seeded.store.bootstrap(isSimulator: true)
        let seededAgain = await seeded.store.snapshot()
        XCTAssertEqual(seededAgain.pets.map(\.name), names)

        let device = Harness(calendar: calendar)
        await device.store.bootstrap(isSimulator: false)
        let deviceDocument = await device.store.snapshot()
        XCTAssertTrue(deviceDocument.pets.isEmpty)
        let seededFlag = await device.store.hasDemoSeedFlag()
        XCTAssertFalse(seededFlag)
    }

    func testReviewLaunchParsesArguments() {
        XCTAssertEqual(
            ReviewLaunch.screen(from: ["Footlight", "-ReviewScreen", "today"]),
            "today"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(from: ["Footlight", "-ReviewScreen", "log"]),
            "log"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(from: ["Footlight", "-ReviewScreen", "goals"]),
            "goals"
        )
        XCTAssertNil(ReviewLaunch.screen(from: ["Footlight"]))
        XCTAssertNil(ReviewLaunch.screen(from: ["-ReviewScreen"]))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = TimeZone(secondsFromGMT: 0)
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    private func household(on day: Date) -> Household {
        var document = GridDocument.empty
        document.calendar = calendar
        let moth = PetRecord(name: "Moth", species: "Cat", accentSlot: "violet")
        let bramble = PetRecord(name: "Bramble", species: "Dog", accentSlot: "ink")
        let mothFeed = RoutineRecord(petID: moth.id, title: "Morning feed", sortOrder: 0, isActive: true)
        let mothWalk = RoutineRecord(petID: moth.id, title: "Evening walk", sortOrder: 1, isActive: true)
        let brambleFeed = RoutineRecord(petID: bramble.id, title: "Morning feed", sortOrder: 0, isActive: true)
        let mothTop = cue(mothFeed)
        let mothNext = cue(mothWalk)
        let brambleTop = cue(brambleFeed)
        document.pets = [moth, bramble]
        document.routines = [mothFeed, mothWalk, brambleFeed]
        document.cues = [mothTop, mothNext, brambleTop]
        _ = day
        return Household(
            document: document,
            mothTop: mothTop,
            mothNext: mothNext,
            brambleTop: brambleTop
        )
    }

    private func cue(_ routine: RoutineRecord) -> CueRecord {
        CueRecord(
            petID: routine.petID,
            routineID: routine.id,
            title: routine.title,
            sortOrder: routine.sortOrder,
            isActive: routine.isActive
        )
    }

    private func strike(for routine: RoutineRecord, in document: GridDocument, daykey: Int, at date: Date) -> StrikeMark {
        let cue = document.cues.first { $0.routineID == routine.id }
        return StrikeMark(
            cueID: cue?.id ?? routine.id,
            routineID: routine.id,
            petID: routine.petID,
            daykey: daykey,
            struckAt: date
        )
    }
}

private struct Household {
    var document: GridDocument
    var mothTop: CueRecord
    var mothNext: CueRecord
    var brambleTop: CueRecord
}

private struct Harness {
    let suiteName: String
    let directory: URL
    let store: GridStore
    let calendar: Calendar

    var fileURL: URL { directory.appendingPathComponent("grid.json") }
    var backupURL: URL { directory.appendingPathComponent("grid.json.backup") }

    init(calendar: Calendar) {
        let name = "ftl.grid.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? UserDefaults.standard
        defaults.removePersistentDomain(forName: name)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        self.suiteName = name
        self.directory = directory
        self.calendar = calendar
        self.store = GridStore(
            suiteName: name,
            directory: directory,
            cacheDirectory: directory.appendingPathComponent("cache", isDirectory: true),
            calendar: calendar,
            saveDelay: .milliseconds(400)
        )
    }

    func reopen() -> Harness {
        Harness(suiteName: suiteName, directory: directory, calendar: calendar)
    }

    private init(suiteName: String, directory: URL, calendar: Calendar) {
        self.suiteName = suiteName
        self.directory = directory
        self.calendar = calendar
        self.store = GridStore(
            suiteName: suiteName,
            directory: directory,
            cacheDirectory: directory.appendingPathComponent("cache", isDirectory: true),
            calendar: calendar,
            saveDelay: .milliseconds(400)
        )
    }
}
