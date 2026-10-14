import SwiftUI

/// Routines sheet. Attach feed, walk, or meds to a pet.
/// Sort order and the active flag decide the column stack.
struct RoutineSheet: View {
    @ObservedObject var session: HouseSession
    @Environment(\.dismiss) private var dismiss
    @State private var routines: [RoutineRecord] = []
    @State private var titleChoice = "Morning feed"
    @State private var petID: UUID?
    @State private var sortOrder = 0
    @State private var isActive = true
    @State private var error: String?
    @State private var editingID: UUID?
    @State private var pendingDelete: IndexSet?
    @State private var saving = false

    private let titles = ["Morning feed", "Evening walk", "Evening meds"]

    var body: some View {
        NavigationStack {
            Group {
                if let notice = session.document.recoveryNotice, routines.isEmpty, session.document.pets.isEmpty {
                    errorState(notice)
                } else if session.document.pets.isEmpty {
                    emptyPets
                } else if routines.isEmpty && error == nil && editingID == nil {
                    emptyChores
                } else {
                    form
                }
            }
            .background(DesignTokens.bg)
            .tint(DesignTokens.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chores")
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("Close")
                            .font(StageType.font(.headline, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityLabel("Close chores")
                }
            }
        }
        .onAppear {
            routines = session.document.routines
            petID = session.document.pets.first?.id
        }
        .confirmationDialog(
            "Delete this chore?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if $0 == false { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    routines.remove(atOffsets: pendingDelete)
                    Task { await session.saveRoutines(routines) }
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(deleteWarning)
        }
    }

    private var deleteWarning: String {
        "This chore leaves the grid, and its strike for today leaves with it."
    }

    private var emptyPets: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Spacer(minLength: 0)
            Image("ftl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: StageMeasure.steps(20), maxHeight: StageMeasure.steps(20))
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Text("No chores yet")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text(needsPetLine)
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: 0)
            Button {
                dismiss()
                session.petsPresented = true
            } label: {
                StageVerb(title: "Add a pet")
            }
            .buttonStyle(StagePressStyle())
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var needsPetLine: String {
        "Add a pet before attaching a routine."
    }

    private var emptyChores: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Spacer(minLength: 0)
            Image("ftl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: StageMeasure.steps(24), maxHeight: StageMeasure.steps(24))
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Text("No chores yet")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text("Attach feed, walk, or meds to a pet.")
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                addFirstChore()
            } label: {
                StageVerb(title: "Add a chore")
            }
            .buttonStyle(StagePressStyle(loading: saving))
            .disabled(saving)
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Text("Chores could not be shown")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text(message)
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: 0)
            Button("Try again") {
                Task {
                    await session.reload()
                    routines = session.document.routines
                }
            }
            .font(StageType.font(.headline, bold: true))
            .foregroundStyle(DesignTokens.ink)
            .frame(minHeight: StageMeasure.steps(6))
            .buttonStyle(StagePressStyle())
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var form: some View {
        Form {
            if let error {
                Text(error)
                    .font(StageType.font(.caption))
                    .foregroundStyle(DesignTokens.ink)
            }
            if let notice = session.document.recoveryNotice {
                Text(notice)
                    .font(StageType.font(.caption))
                    .foregroundStyle(DesignTokens.ink)
                Button("Try again") {
                    Task {
                        await session.reload()
                        routines = session.document.routines
                    }
                }
                .frame(minHeight: StageMeasure.steps(6))
            }
            Section {
                ForEach(routines) { routine in
                    Button {
                        editingID = routine.id
                        titleChoice = routine.title
                        petID = routine.petID
                        sortOrder = routine.sortOrder
                        isActive = routine.isActive
                    } label: {
                        VStack(alignment: .leading, spacing: StageMeasure.unit) {
                            Text(routine.title)
                                .font(StageType.font(.headline, bold: true))
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(1)
                            Text(rowLine(routine))
                                .font(StageType.font(.caption))
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6), alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StagePressStyle())
                }
                .onDelete { offsets in
                    pendingDelete = offsets
                }
            } header: {
                Text("On the grid")
                    .font(StageType.font(.caption, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .textCase(nil)
            }
            Section {
                editorFields
            } header: {
                Text("Attach")
                    .font(StageType.font(.caption, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .textCase(nil)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var sortLine: String {
        "Sort \(StageType.digits(sortOrder))"
    }

    private var editorFields: some View {
        Group {
            Picker("Chore", selection: $titleChoice) {
                ForEach(titles, id: \.self) { Text($0).tag($0) }
            }
            Picker("Pet", selection: $petID) {
                ForEach(session.document.pets) { pet in
                    Text(pet.name).tag(Optional(pet.id))
                }
            }
            Stepper(value: $sortOrder, in: 0...20) {
                Text(sortLine)
                    .font(StageType.font(.body))
            }
            Toggle("Active", isOn: $isActive)
            Button {
                commit()
            } label: {
                StageVerb(title: "Save chore")
            }
            .buttonStyle(StagePressStyle(loading: saving))
            .disabled(saving || petID == nil)
        }
    }

    private func rowLine(_ routine: RoutineRecord) -> String {
        let pet = session.document.pets.first(where: { $0.id == routine.petID })?.name ?? "Pet"
        let flag = routine.isActive ? "Active" : "Paused"
        return "\(pet). Order \(StageType.digits(routine.sortOrder)). \(flag)."
    }

    private func addFirstChore() {
        guard let petID = session.document.pets.first?.id else {
            error = "Choose a pet before saving this chore."
            return
        }
        saving = true
        routines = [
            RoutineRecord(petID: petID, title: "Morning feed", sortOrder: 0, isActive: true)
        ]
        Task {
            await session.saveRoutines(routines)
            saving = false
        }
    }

    private func commit() {
        guard let petID else {
            error = "Choose a pet before saving this chore."
            return
        }
        error = nil
        saving = true
        if let editingID, let index = routines.firstIndex(where: { $0.id == editingID }) {
            routines[index].title = titleChoice
            routines[index].petID = petID
            routines[index].sortOrder = sortOrder
            routines[index].isActive = isActive
        } else {
            routines.append(
                RoutineRecord(petID: petID, title: titleChoice, sortOrder: sortOrder, isActive: isActive)
            )
        }
        editingID = nil
        Task {
            await session.saveRoutines(routines)
            saving = false
        }
    }
}
