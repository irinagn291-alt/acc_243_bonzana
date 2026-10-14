import Foundation

/// A household animal that owns one column on the cap grid.
/// The fold groups active cues under this identity. The column accent is a
/// named slot the UI maps through DesignTokens. It is never a stored hex.
struct PetRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var species: String
    /// Closed slot name. The screen pairs it with the pet name so colour is never the only signal.
    var accentSlot: String

    init(id: UUID = UUID(), name: String, species: String, accentSlot: String) {
        self.id = id
        self.name = name
        self.species = species
        self.accentSlot = accentSlot
    }
}
