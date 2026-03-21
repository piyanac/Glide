import Foundation

enum AlarmDateResolver {
    static func countdownDate(from now: Date, duration: TimeInterval) -> Date {
        now.addingTimeInterval(duration)
    }

    static func nextClockTime(hour: Int, minute: Int, now: Date) -> Date {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)

        var components = DateComponents()
        components.year = nowComponents.year
        components.month = nowComponents.month
        components.day = nowComponents.day
        components.hour = hour
        components.minute = minute
        components.second = 0

        let sameDay = calendar.date(from: components) ?? now
        if sameDay > now {
            return sameDay
        }

        return calendar.date(byAdding: .day, value: 1, to: sameDay) ?? sameDay
    }
}
