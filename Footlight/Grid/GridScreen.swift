import SwiftUI

/// Today. The cap grid never leaves this root.
/// Column-head strike is the swipe on the top open cue.
/// Pets, Routines, Settings, and the curtain ledger arrive as sheets.
struct GridScreen: View {
    @ObservedObject var session: HouseSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            if session.isReady == false {
                loading
            } else if session.fold.phase == .blank {
                blank
            } else {
                stage
            }
            if session.sealVisible {
                Image("ftl_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StageMeasure.steps(16), height: StageMeasure.steps(16))
                    .accessibilityLabel("Strike saved")
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : StageMotion.ease, value: session.fold.phase)
        .animation(reduceMotion ? nil : StageMotion.ease, value: session.sealVisible)
        .animation(reduceMotion ? nil : StageMotion.ease, value: session.isReady)
    }

    private var rowHeight: CGFloat {
        _ = dynamicTypeSize
        return StageMeasure.cueRowHeight
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            crop
                .padding(.horizontal, StageMeasure.steps(3))
            plaque
                .padding(.horizontal, StageMeasure.steps(3))
            if let notice = session.document.recoveryNotice {
                noticeCard(notice)
                    .padding(.horizontal, StageMeasure.steps(3))
            }
            CapGridView(
                fold: session.fold,
                document: session.document,
                rowHeight: rowHeight,
                railHeight: StageMeasure.railHeight,
                isBusy: session.isBusy,
                onSwipe: { cueID in
                    Task { await session.swipe(cueID: cueID) }
                }
            )
            .id(session.fold.phase)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, StageMeasure.steps(2))
    }

    private var loading: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            crop
            RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(height: StageMeasure.steps(16))
                .overlay(
                    RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                        .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
                )
                .redacted(reason: .placeholder)
            HStack(alignment: .top, spacing: StageMeasure.unit) {
                columnGhost(count: 2)
                columnGhost(count: 2)
                columnGhost(count: 1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StageMeasure.steps(3))
        .padding(.top, StageMeasure.steps(2))
        .accessibilityLabel("Opening the grid")
    }

    private func columnGhost(count: Int) -> some View {
        VStack(spacing: StageMeasure.unit) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                    .fill(DesignTokens.surface)
                    .frame(height: rowHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                            .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var crop: some View {
        ZStack {
            DesignTokens.surface
            Image("ftl_HeaderDecor")
                .resizable()
                .scaledToFill()
        }
        .frame(maxWidth: .infinity)
        .frame(height: StageMeasure.steps(16))
        .clipShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
        )
        .accessibilityHidden(true)
    }

    private var plaque: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            HStack(alignment: .top, spacing: StageMeasure.steps(2)) {
                VStack(alignment: .leading, spacing: StageMeasure.unit) {
                    Text("Today")
                        .font(StageType.font(.caption, bold: true))
                        .foregroundStyle(DesignTokens.muted)
                    Text(session.dayLine)
                        .font(StageType.font(.title, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(session.nextTapLine)
                        .font(StageType.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                moreControl
            }
            if session.canUndo {
                Button {
                    Task { await session.peel() }
                } label: {
                    Text("Undo last strike")
                        .font(StageType.font(.headline, bold: true))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6))
                        .background(DesignTokens.bg)
                        .clipShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                                .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
                }
                .buttonStyle(StagePressStyle())
                .disabled(session.isBusy)
                .accessibilityLabel("Undo the last strike")
            }
        }
        .padding(StageMeasure.steps(2))
        .background {
            ZStack {
                Image("ftl_CardBackdrop")
                    .resizable()
                    .scaledToFill()
                DesignTokens.surface.opacity(0.88)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
        )
    }

    private var moreControl: some View {
        Menu {
            Button("Pets") { session.petsPresented = true }
            Button("Chores") { session.routinesPresented = true }
            Button("Seals") { session.curtainPresented = true }
            Button("Settings") { session.settingsPresented = true }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(StageType.font(.headline, bold: true))
                .foregroundStyle(DesignTokens.ink)
                .frame(width: StageMeasure.steps(6), height: StageMeasure.steps(6))
                .background(DesignTokens.bg)
                .clipShape(RoundedRectangle(cornerRadius: StageMeasure.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: StageMeasure.chip, style: .continuous)
                        .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: StageMeasure.chip, style: .continuous))
        }
        .buttonStyle(StagePressStyle())
        .accessibilityLabel("More")
    }

    private var blank: some View {
        VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
            HStack {
                Button("Settings") { session.settingsPresented = true }
                    .font(StageType.font(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(minHeight: StageMeasure.steps(6))
                    .buttonStyle(StagePressStyle())
                    .accessibilityLabel("Open settings")
                Spacer()
            }
            Spacer(minLength: 0)
            Image("ftl_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: StageMeasure.steps(28), maxHeight: StageMeasure.steps(28))
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            Text("No chores yet")
                .font(StageType.font(.title, bold: true))
                .foregroundStyle(DesignTokens.ink)
            Text(session.emptyLine)
                .font(StageType.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                session.petsPresented = true
            } label: {
                StageVerb(title: "Add a pet")
            }
            .buttonStyle(StagePressStyle())
            .accessibilityLabel("Add a pet")
        }
        .padding(StageMeasure.steps(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func noticeCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: StageMeasure.unit) {
            Text(text)
                .font(StageType.font(.caption))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await session.reload() }
            }
            .font(StageType.font(.headline, bold: true))
            .foregroundStyle(DesignTokens.ink)
            .frame(minHeight: StageMeasure.steps(6))
            .buttonStyle(StagePressStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(StageMeasure.steps(2))
        .stageCard()
    }
}
