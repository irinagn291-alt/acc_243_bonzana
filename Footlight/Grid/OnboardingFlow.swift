import SwiftUI

/// Three full-page stages before the grid is the root.
/// Skip still writes one pet and one routine and sets the completion flag.
/// Settings can present this flow again.
struct OnboardingFlow: View {
    @ObservedObject var session: HouseSession
    @State private var page = 0

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: StageMeasure.steps(2)) {
                Spacer(minLength: 0)
                Image(artName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: StageMeasure.steps(36))
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
                Text(title)
                    .font(StageType.font(.title, bold: true))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line)
                    .font(StageType.font(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button(action: advance) {
                    StageVerb(title: "Continue")
                }
                .buttonStyle(StagePressStyle())
                Button {
                    Task { await session.finishOnboarding(skip: true) }
                } label: {
                    Text("Skip")
                        .font(StageType.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(StagePressStyle())
            }
            .padding(StageMeasure.steps(3))
        }
    }

    private var artName: String {
        switch page {
        case 0: return "ftl_Onboarding1"
        case 1: return "ftl_Onboarding2"
        default: return "ftl_Onboarding3"
        }
    }

    private var title: String {
        switch page {
        case 0: return "Each pet has a column"
        case 1: return "Swipe the top open chore"
        default: return "The curtain seals the day"
        }
    }

    private var line: String {
        switch page {
        case 0:
            return "Each pet has its own column. Chores stack in order inside that column."
        case 1:
            return "Swipe the top open chore to strike it. A swipe lower in the column keeps the order."
        default:
            return "The curtain seals the day when every chore is struck, and the streak rail records that seal."
        }
    }

    private func advance() {
        if page < 2 {
            page += 1
        } else {
            Task { await session.finishOnboarding(skip: false) }
        }
    }
}
