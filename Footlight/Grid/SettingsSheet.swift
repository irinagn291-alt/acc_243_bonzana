import SwiftUI

/// Settings sheet. Re-run onboarding, reset the grid, and open contact.
/// Reset confirms that every pet, routine, and mark will be erased.
struct SettingsSheet: View {
    @ObservedObject var session: HouseSession
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    private let contact = URL(string: "https://footlight-grid.pro/contact-us")

    var body: some View {
        NavigationStack {
            Group {
                if let notice = session.document.recoveryNotice, session.document.pets.isEmpty {
                    VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
                        Text("Settings could not read the grid")
                            .font(StageType.font(.title, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                        Text(notice)
                            .font(StageType.font(.body))
                            .foregroundStyle(DesignTokens.ink)
                        Button("Try again") {
                            Task { await session.reload() }
                        }
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(minHeight: StageMeasure.steps(6))
                        .buttonStyle(StagePressStyle())
                        controls
                        Spacer(minLength: 0)
                    }
                    .padding(StageMeasure.steps(3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    Form {
                        Section {
                            Text(summaryLine)
                                .font(StageType.font(.body))
                                .foregroundStyle(DesignTokens.ink)
                        }
                        if let notice = session.document.recoveryNotice {
                            Section {
                                Text(notice)
                                    .font(StageType.font(.caption))
                                    .foregroundStyle(DesignTokens.ink)
                                Button("Try again") {
                                    Task { await session.reload() }
                                }
                                .frame(minHeight: StageMeasure.steps(6))
                            }
                        }
                        Section {
                            controls
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(DesignTokens.bg)
            .tint(DesignTokens.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("Close")
                            .font(StageType.font(.headline, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityLabel("Close settings")
                }
            }
        }
        .confirmationDialog(
            "Reset the grid?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Erase the grid", role: .destructive) {
                Task { await session.resetGrid() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(resetWarning)
        }
    }

    private var summaryLine: String {
        let pets = StageType.digits(session.document.pets.count)
        let chores = StageType.digits(session.document.routines.count)
        if session.document.pets.isEmpty {
            return "The grid has no pets yet."
        }
        return "\(pets) pets on the grid. \(chores) chores."
    }

    private var resetWarning: String {
        "Every pet, routine, and mark will be erased."
    }

    @ViewBuilder
    private var controls: some View {
        Button {
            session.replayOnboarding()
        } label: {
            Text("Run onboarding again")
                .font(StageType.font(.body, bold: true))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6), alignment: .leading)
        }
        .buttonStyle(StagePressStyle())
        Button {
            confirmReset = true
        } label: {
            Text("Reset all data")
                .font(StageType.font(.body, bold: true))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6), alignment: .leading)
        }
        .buttonStyle(StagePressStyle())
        if let contact {
            Link(destination: contact) {
                Text("Contact Footlight")
                    .font(StageType.font(.body, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6), alignment: .leading)
            }
        } else {
            Text("The contact page is unavailable.")
                .font(StageType.font(.caption))
                .foregroundStyle(DesignTokens.ink)
        }
    }
}
