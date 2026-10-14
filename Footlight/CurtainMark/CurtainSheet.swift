import SwiftUI

/// Curtain ledger. History counts CurtainMarks and LeapMarks.
/// The home surface remains the column swipe. This sheet is the ledger.
struct CurtainSheet: View {
    @ObservedObject var session: HouseSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if session.document.curtainMarks.isEmpty && session.document.leapMarks.isEmpty {
                    if let notice = session.document.recoveryNotice {
                        errorState(notice)
                    } else {
                        empty
                    }
                } else {
                    list
                }
            }
            .background(DesignTokens.bg)
            .tint(DesignTokens.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Seals")
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("Close")
                            .font(StageType.font(.headline, bold: true))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .accessibilityLabel("Close the seal ledger")
                }
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Spacer(minLength: 0)
            Image("ftl_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: StageMeasure.steps(24), maxHeight: StageMeasure.steps(24))
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Text("No seals yet")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text("Strike every column and the day writes a seal here.")
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button { dismiss() } label: {
                StageVerb(title: "Back to today")
            }
            .buttonStyle(StagePressStyle())
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            Text("The ledger could not be shown")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text(message)
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: 0)
            Button("Try again") {
                Task { await session.reload() }
            }
            .font(StageType.font(.headline, bold: true))
            .foregroundStyle(DesignTokens.ink)
            .frame(minHeight: StageMeasure.steps(6))
            .buttonStyle(StagePressStyle())
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var list: some View {
        List {
            Section {
                Image("ftl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: StageMeasure.steps(20))
                    .clipped()
                    .accessibilityHidden(true)
                    .listRowBackground(DesignTokens.surface)
            }
            Section {
                if session.document.curtainMarks.isEmpty {
                    Text("No curtain seal is stored.")
                        .font(StageType.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                }
                ForEach(session.document.curtainMarks) { mark in
                    Text(sealLine(mark.daykey))
                        .font(StageType.digitFont(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(minHeight: StageMeasure.steps(6), alignment: .leading)
                }
            } header: {
                Text("Seals")
                    .font(StageType.font(.caption, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .textCase(nil)
            }
            Section {
                if session.document.leapMarks.isEmpty {
                    Text("No lower swipe is stored.")
                        .font(StageType.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                }
                ForEach(session.document.leapMarks) { mark in
                    Text(leapLine(mark.daykey))
                        .font(StageType.digitFont(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(minHeight: StageMeasure.steps(6), alignment: .leading)
                }
            } header: {
                Text("Order kept")
                    .font(StageType.font(.caption, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .textCase(nil)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func sealLine(_ daykey: Int) -> String {
        "Sealed day \(StageType.digits(daykey))."
    }

    private func leapLine(_ daykey: Int) -> String {
        "Order kept on day \(StageType.digits(daykey))."
    }
}
