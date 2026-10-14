import CoreText
import SwiftUI

/// Spacing, radii, and the hairline elevation shared by every surface.
/// Cards and sheets use `card`. Chips and small controls use `chip`.
enum StageMeasure {
    static let unit: CGFloat = 8
    static let card: CGFloat = 24
    static let chip: CGFloat = 10
    static let hairline: CGFloat = 1

    static func steps(_ count: Int) -> CGFloat {
        unit * CGFloat(count)
    }

    /// Minimum cue block. Layout may grow it so the tallest column fills the stage.
    static var cueRowHeight: CGFloat {
        let title = StageType.uiFont(.headline, bold: true).lineHeight
        let pet = StageType.uiFont(.caption).lineHeight
        let state = StageType.uiFont(.caption, bold: true).lineHeight
        let raw = title * 2 + pet + state + steps(5)
        return max(steps(12), ceil(raw / unit) * unit)
    }

    static var railHeight: CGFloat {
        let body = StageType.uiFont(.body).lineHeight
        let raw = body * 2 + steps(3)
        return max(steps(8), ceil(raw / unit) * unit)
    }
}

enum StageMotion {
    static let fade: TimeInterval = 0.18
    static var ease: Animation { .easeOut(duration: fade) }
}

enum StageType {
    enum Step {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    static func font(_ step: Step, bold: Bool = false) -> Font {
        Font(uiFont(step, bold: bold))
    }

    static func uiFont(_ step: Step, bold: Bool = false) -> UIFont {
        let size: CGFloat
        let style: UIFont.TextStyle
        switch step {
        case .display:
            size = 32
            style = .largeTitle
        case .title:
            size = 24
            style = .title2
        case .headline:
            size = 20
            style = .headline
        case .body:
            size = 17
            style = .body
        case .caption:
            size = 14
            style = .caption1
        case .micro:
            size = 12
            style = .caption2
        }
        let name = bold ? "Palatino-Bold" : "Palatino-Roman"
        let base = UIFont(name: name, size: size)
            ?? UIFont(name: "Palatino-Roman", size: size)
            ?? UIFont(name: "Palatino-Bold", size: size)!
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    static func calendarDay(_ daykey: Int) -> String {
        guard let date = Daykey.startDate(for: daykey) else {
            return digits(daykey)
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    static func digits(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func digitUIFont(_ step: Step, bold: Bool = false) -> UIFont {
        let base = uiFont(step, bold: bold)
        let features: [UIFontDescriptor.AttributeName: Any] = [
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
                ],
            ],
        ]
        let descriptor = base.fontDescriptor.addingAttributes(features)
        return UIFont(descriptor: descriptor, size: 0)
    }

    static func digitFont(_ step: Step, bold: Bool = false) -> Font {
        Font(digitUIFont(step, bold: bold))
    }
}

/// Press, disabled, and loading share one style. Travel is a slight scale.
/// Reduce Motion keeps the opacity change and drops the scale.
struct StagePressStyle: ButtonStyle {
    var loading: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled && loading == false ? (configuration.isPressed ? 0.72 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && isEnabled && loading == false && reduceMotion == false ? 0.98 : 1)
            .animation(reduceMotion ? nil : StageMotion.ease, value: configuration.isPressed)
    }
}

/// Accent fill, 24pt radius, and the same 1pt hairline the cards use.
struct StageVerb: View {
    var title: String

    var body: some View {
        Text(title)
            .font(StageType.font(.headline, bold: true))
            .foregroundStyle(DesignTokens.bg)
            .frame(maxWidth: .infinity, minHeight: StageMeasure.steps(6))
            .background(DesignTokens.accent)
            .clipShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous)
                    .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: StageMeasure.card, style: .continuous))
    }
}

extension View {
    func stageCard() -> some View {
        modifier(StageElevation(radius: StageMeasure.card))
    }

    func stageChip() -> some View {
        modifier(StageElevation(radius: StageMeasure.chip))
    }
}

private struct StageElevation: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(DesignTokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DesignTokens.muted, lineWidth: StageMeasure.hairline)
            )
    }
}

enum AccentSlot {
    static let choices = ["violet", "ink", "mist"]

    static func color(for slot: String) -> Color {
        switch slot {
        case "ink":
            return DesignTokens.ink
        case "mist":
            return DesignTokens.muted
        default:
            return DesignTokens.accent
        }
    }

    static func label(for slot: String) -> String {
        switch slot {
        case "ink":
            return "Ink"
        case "mist":
            return "Mist"
        default:
            return "Violet"
        }
    }
}
