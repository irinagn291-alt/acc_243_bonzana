import Foundation

/// The only seam between the fold and storage.
/// Memory is the source of truth. UserDefaults key `ftl.grid.v1` and the
/// Application Support file are projections. Writes are debounced, flushed
/// when the scene leaves the foreground, and immediate after a reset.
actor GridStore {
    static let storageKey = "ftl.grid.v1"

    private let defaults: UserDefaults
    private let fileURL: URL
    private let backupURL: URL
    private let cacheDirectory: URL
    private let saveDelay: Duration
    private var document: GridDocument
    private var saveTask: Task<Void, Never>?
    private var saveGeneration = 0
    private var lastWriteFailed = false

    init(
        suiteName: String?,
        directory: URL,
        cacheDirectory: URL,
        calendar: Calendar = .current,
        saveDelay: Duration = .milliseconds(400)
    ) {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        self.fileURL = directory.appendingPathComponent("grid.json", isDirectory: false)
        self.backupURL = directory.appendingPathComponent("grid.json.backup", isDirectory: false)
        self.cacheDirectory = cacheDirectory
        self.saveDelay = saveDelay
        self.document = GridDocument.empty
        self.document.calendar = calendar
    }

    static func live(calendar: Calendar = .current) -> GridStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let root = support.appendingPathComponent("Bonzana", isDirectory: true)
        let caches = cache.appendingPathComponent("Bonzana", isDirectory: true)
        return GridStore(suiteName: nil, directory: root, cacheDirectory: caches, calendar: calendar)
    }

    func snapshot() -> GridDocument {
        document
    }

    func recoveryNotice() -> String? {
        document.recoveryNotice
    }

    func projectionData() -> Data? {
        defaults.data(forKey: Self.storageKey)
    }

    func replaceProjectionData(_ data: Data) {
        defaults.set(data, forKey: Self.storageKey)
    }

    func hasDemoSeedFlag() -> Bool {
        defaults.bool(forKey: DemoSeed.defaultsKey)
    }

    /// Loads the projection, then applies the simulator seed at most once.
    func bootstrap(isSimulator: Bool) async {
        await load()
        let already = defaults.bool(forKey: DemoSeed.defaultsKey)
        guard DemoSeed.shouldApply(isSimulator: isSimulator, alreadySeeded: already) else {
            return
        }
        document = DemoSeed.document(now: Date(), calendar: document.calendar)
        defaults.set(true, forKey: DemoSeed.defaultsKey)
        await flush()
    }

    func load() async {
        prepareDirectories()
        let defaultsData = defaults.data(forKey: Self.storageKey)
        if let defaultsData, let decoded = Self.decode(defaultsData) {
            document = attachingCalendar(decoded)
            return
        }
        if let fileData = read(fileURL), let decoded = Self.decode(fileData) {
            var restored = attachingCalendar(decoded)
            if defaultsData != nil {
                restored.recoveryNotice = "The saved grid could not be read. The last good file was restored."
            }
            document = restored
            return
        }
        if let backupData = read(backupURL), let decoded = Self.decode(backupData) {
            var restored = attachingCalendar(decoded)
            restored.recoveryNotice = "The saved grid could not be read. The previous copy was restored."
            document = restored
            return
        }
        var empty = GridDocument.empty
        empty.calendar = document.calendar
        let hadBytes = defaultsData != nil || fileExists(fileURL) || fileExists(backupURL)
        if hadBytes {
            empty.recoveryNotice = "The saved grid could not be read. An empty grid is ready."
        }
        document = empty
    }

    func fold(on date: Date) -> GridFold {
        let key = Daykey.make(from: date, calendar: document.calendar)
        return GridFold.make(document: document, daykey: key, calendar: document.calendar)
    }

    func swipe(cueID: UUID, on date: Date) async -> GridCommit {
        let key = Daykey.make(from: date, calendar: document.calendar)
        let commit = GridRelay.swipe(document: &document, cueID: cueID, daykey: key, now: date)
        if Self.persists(commit) {
            scheduleSave()
        }
        return commit
    }

    func peel(on date: Date) async -> GridCommit {
        let key = Daykey.make(from: date, calendar: document.calendar)
        let commit = PeelStrike.apply(to: &document, daykey: key, now: date)
        if Self.persists(commit) {
            scheduleSave()
        }
        return commit
    }

    func replaceDocument(_ next: GridDocument) async {
        var copy = next
        copy.schemaVersion = GridDocument.currentSchema
        copy.calendar = document.calendar
        document = copy
        scheduleSave()
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        let calendar = document.calendar
        document = GridDocument.empty
        document.calendar = calendar
        defaults.removeObject(forKey: Self.storageKey)
        remove(fileURL)
        remove(backupURL)
    }

    /// Scene became inactive or background. A force-quit must keep the last mark.
    func flushForSceneExit() async {
        await flush()
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        saveGeneration += 1
        await writeProjection()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveGeneration += 1
        let generation = saveGeneration
        let delay = saveDelay
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard Task.isCancelled == false else { return }
            await self?.writeIfCurrent(generation)
        }
    }

    private func writeIfCurrent(_ generation: Int) async {
        guard generation == saveGeneration else { return }
        await writeProjection()
    }

    private func writeProjection() async {
        let snapshot = document
        let encoded: Data
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            encoded = try encoder.encode(snapshot)
        } catch {
            lastWriteFailed = true
            return
        }
        prepareDirectories()
        if let current = read(fileURL), Self.decode(current) != nil {
            do {
                try current.write(to: backupURL, options: .atomic)
            } catch {
                lastWriteFailed = true
            }
        }
        do {
            try encoded.write(to: fileURL, options: .atomic)
            defaults.set(encoded, forKey: Self.storageKey)
            lastWriteFailed = false
        } catch {
            lastWriteFailed = true
        }
    }

    private func prepareDirectories() {
        let fileManager = FileManager.default
        let root = fileURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: root.path) == false {
            do {
                try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
            } catch {
                lastWriteFailed = true
            }
        }
        if fileManager.fileExists(atPath: cacheDirectory.path) == false {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                lastWriteFailed = true
            }
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var cache = cacheDirectory
        do {
            try cache.setResourceValues(values)
        } catch {
            lastWriteFailed = true
        }
    }

    private func attachingCalendar(_ decoded: GridDocument) -> GridDocument {
        var copy = decoded
        copy.calendar = document.calendar
        copy.recoveryNotice = nil
        return copy
    }

    private func read(_ url: URL) -> Data? {
        guard fileExists(url) else { return nil }
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    private func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private func remove(_ url: URL) {
        guard fileExists(url) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            lastWriteFailed = true
        }
    }

    private static func persists(_ commit: GridCommit) -> Bool {
        switch commit {
        case .struck, .leaped, .sealed, .peeled:
            return true
        case .refused:
            return false
        }
    }

    static func decode(_ data: Data) -> GridDocument? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(GridDocument.self, from: data)
        } catch {
            return nil
        }
    }
}
