import SwiftUI

/// Pets sheet. Add and edit a name, a species, and a column accent.
/// Delete names the pet and states that its routines leave the grid.
struct PetSheet: View {
    @ObservedObject var session: HouseSession
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var pets: [PetRecord] = []
    @State private var editing: PetRecord?
    @State private var name = ""
    @State private var species = ""
    @State private var accent = "violet"
    @State private var error: String?
    @State private var pendingDelete: PetRecord?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Group {
                if session.document.recoveryNotice != nil && pets.isEmpty && editing == nil {
                    errorState(session.document.recoveryNotice ?? "The saved grid could not be read.")
                } else if pets.isEmpty && editing == nil && error == nil {
                    emptyState
                } else {
                    list
                }
            }
            .background(DesignTokens.bg)
            .tint(DesignTokens.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pets")
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("Close")
                            .font(StageType.font(.headline, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityLabel("Close pets")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { beginNew() } label: {
                        Text("Add")
                            .font(StageType.font(.headline, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityLabel("Add a pet")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
        }
        .onAppear { pets = session.document.pets }
        .confirmationDialog(
            deleteTitle,
            isPresented: Binding(get: { pendingDelete != nil }, set: { if $0 == false { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    pets.removeAll { $0.id == pendingDelete.id }
                    Task { await session.savePets(pets) }
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(deleteMessage)
        }
    }

    private var deleteTitle: String {
        if let pendingDelete {
            return "Delete \(pendingDelete.name)?"
        }
        return "Delete this pet?"
    }

    private var deleteMessage: String {
        if let pendingDelete {
            return "\(pendingDelete.name) leaves the grid. Its routines leave the grid."
        }
        return "Its routines leave the grid."
    }

    private var nameIssue: String? {
        if name.isEmpty && species.isEmpty { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = species.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || kind.isEmpty {
            return "Enter a name and a species before saving."
        }
        return nil
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Spacer(minLength: 0)
            Image("ftl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: StageMeasure.steps(24), maxHeight: StageMeasure.steps(24))
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Text("No pets yet")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text("Add a pet to open a column.")
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: 0)
            Button {
                beginNew()
            } label: {
                StageVerb(title: "Add a pet")
            }
            .buttonStyle(StagePressStyle())
            .accessibilityLabel("Add a pet")
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Text("Pets could not be shown")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text(message)
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: 0)
            Button("Try again") {
                Task {
                    await session.reload()
                    pets = session.document.pets
                }
            }
            .font(StageType.font(.headline, bold: true))
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6))
            .buttonStyle(StagePressStyle())
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var list: some View {
        List {
            if let notice = session.document.recoveryNotice {
                Text(notice)
                    .font(StageType.font(.caption))
                    .foregroundStyle(DesignTokens.ink)
            }
            if let error {
                Text(error)
                    .font(StageType.font(.caption))
                    .foregroundStyle(DesignTokens.ink)
            }
            if editing != nil {
                editor
            }
            ForEach(pets) { pet in
                Button {
                    editing = pet
                    name = pet.name
                    species = pet.species
                    accent = pet.accentSlot
                    error = nil
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: StageMeasure.unit) {
                            Text(pet.name)
                                .font(StageType.font(.headline, bold: true))
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(1)
                            Text(detailLine(pet))
                                .font(StageType.font(.caption))
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(1)
                        }
                        Spacer(minLength: StageMeasure.unit)
                    }
                    .frame(minHeight: StageMeasure.steps(6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(StagePressStyle())
                .listRowBackground(DesignTokens.surface)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        pendingDelete = pet
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            TextField("Name", text: $name)
                .font(StageType.font(.body))
                .focused($focused)
                .textInputAutocapitalization(.words)
            TextField("Species", text: $species)
                .font(StageType.font(.body))
                .focused($focused)
                .textInputAutocapitalization(.words)
            if let nameIssue {
                Text(nameIssue)
                    .font(StageType.font(.caption))
                    .foregroundStyle(DesignTokens.ink)
            }
            Picker("Accent", selection: $accent) {
                ForEach(AccentSlot.choices, id: \.self) { slot in
                    Text(AccentSlot.label(for: slot)).tag(slot)
                }
            }
            .pickerStyle(.segmented)
            Button {
                commitEditor()
            } label: {
                StageVerb(title: "Save pet")
            }
            .buttonStyle(StagePressStyle(loading: saving))
            .disabled(saving || nameIssue != nil || name.isEmpty || species.isEmpty)
            .listRowBackground(DesignTokens.surface)
        }
        .padding(.vertical, StageMeasure.unit)
    }

    private func detailLine(_ pet: PetRecord) -> String {
        "\(pet.species). Accent \(AccentSlot.label(for: pet.accentSlot))."
    }

    private func beginNew() {
        editing = PetRecord(name: "", species: "", accentSlot: "violet")
        name = ""
        species = ""
        accent = "violet"
        error = nil
    }

    private func commitEditor() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = species.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, kind.isEmpty == false else {
            error = "Enter a name and a species before saving."
            return
        }
        error = nil
        saving = true
        if let editing, pets.contains(where: { $0.id == editing.id }) {
            pets = pets.map { pet in
                guard pet.id == editing.id else { return pet }
                var copy = pet
                copy.name = trimmed
                copy.species = kind
                copy.accentSlot = accent
                return copy
            }
        } else {
            pets.append(PetRecord(name: trimmed, species: kind, accentSlot: accent))
        }
        self.editing = nil
        name = ""
        species = ""
        focused = false
        Task {
            await session.savePets(pets)
            saving = false
        }
    }
}
