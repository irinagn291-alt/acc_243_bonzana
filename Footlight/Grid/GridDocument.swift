import Foundation

/// In-memory source of truth for one household grid.
/// The file and the UserDefaults blob are projections of this value.
/// Phase, streak, and day totals are folded, never stored.
struct GridDocument: Codable, Equatable, Sendable {
    static let currentSchema = 1

    var schemaVersion: Int
    var pets: [PetRecord]
    var routines: [RoutineRecord]
    var cues: [CueRecord]
    var strikeMarks: [StrikeMark]
    var leapMarks: [LeapMark]
    var curtainMarks: [CurtainMark]
    var onboardingComplete: Bool
    /// Set when a corrupt blob was replaced by a backup or by an empty grid.
    var recoveryNotice: String?

    /// Not encoded. Tests pin a calendar so daykey math stays stable.
    var calendar: Calendar = .current

    static var empty: GridDocument {
        GridDocument(
            schemaVersion: currentSchema,
            pets: [],
            routines: [],
            cues: [],
            strikeMarks: [],
            leapMarks: [],
            curtainMarks: [],
            onboardingComplete: false,
            recoveryNotice: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case pets
        case routines
        case cues
        case strikeMarks
        case leapMarks
        case curtainMarks
        case onboardingComplete
        case recoveryNotice
    }

    init(
        schemaVersion: Int,
        pets: [PetRecord],
        routines: [RoutineRecord],
        cues: [CueRecord],
        strikeMarks: [StrikeMark],
        leapMarks: [LeapMark],
        curtainMarks: [CurtainMark],
        onboardingComplete: Bool,
        recoveryNotice: String?,
        calendar: Calendar = .current
    ) {
        self.schemaVersion = schemaVersion
        self.pets = pets
        self.routines = routines
        self.cues = cues
        self.strikeMarks = strikeMarks
        self.leapMarks = leapMarks
        self.curtainMarks = curtainMarks
        self.onboardingComplete = onboardingComplete
        self.recoveryNotice = recoveryNotice
        self.calendar = calendar
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            pets = try container.decode([PetRecord].self, forKey: .pets)
            routines = try container.decode([RoutineRecord].self, forKey: .routines)
            cues = try container.decode([CueRecord].self, forKey: .cues)
            strikeMarks = try container.decode([StrikeMark].self, forKey: .strikeMarks)
            leapMarks = try container.decode([LeapMark].self, forKey: .leapMarks)
            curtainMarks = try container.decode([CurtainMark].self, forKey: .curtainMarks)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
            recoveryNotice = try container.decodeIfPresent(String.self, forKey: .recoveryNotice)
            calendar = .current
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported grid schema \(version)."
            )
        }
    }
}
