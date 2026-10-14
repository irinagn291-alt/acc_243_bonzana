import Foundation

/// An Int day boundary in YYYYMMDD form.
/// Always derived from `Calendar.startOfDay`, never stored as a running total.
enum Daykey {
    static func make(from date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func startDate(for key: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func previous(_ key: Int, calendar: Calendar = .current) -> Int? {
        guard let start = startDate(for: key, calendar: calendar),
              let prior = calendar.date(byAdding: .day, value: -1, to: start) else {
            return nil
        }
        return make(from: prior, calendar: calendar)
    }
}
