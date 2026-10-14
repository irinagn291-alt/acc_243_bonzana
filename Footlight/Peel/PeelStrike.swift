import Foundation

/// Removes the latest StrikeMark for a daykey.
/// Refused while the fold is Open or Blank. Drops that daykey's CurtainMark
/// when any active cue is left without a strike.
enum PeelStrike {
    static func apply(
        to document: inout GridDocument,
        daykey: Int,
        now: Date
    ) -> GridCommit {
        let fold = GridFold.make(document: document, daykey: daykey, calendar: document.calendar)
        switch fold.phase {
        case .blank:
            return .refused(.blankGrid)
        case .open:
            return .refused(.peelOnOpen)
        case .clearing, .curtain:
            break
        }
        guard let index = document.strikeMarks.lastIndex(where: { $0.daykey == daykey }) else {
            return .refused(.peelOnOpen)
        }
        let removed = document.strikeMarks.remove(at: index)
        if GridFold.isDayComplete(document, daykey: daykey) == false {
            document.curtainMarks.removeAll { $0.daykey == daykey }
        }
        return .peeled(removed, at: now)
    }
}
