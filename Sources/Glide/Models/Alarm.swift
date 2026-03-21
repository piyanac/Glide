import Foundation

enum AlarmKind: Equatable, Codable {
    case countdown(duration: TimeInterval)
    case clockTime(hour: Int, minute: Int)
}

enum AlarmState: String, Equatable, Codable {
    case scheduled
    case firing
    case dismissed
}

struct Alarm: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: AlarmKind
    let triggerDate: Date
    var message: String
    var sound: AlarmSound?
    var state: AlarmState

    init(
        id: UUID = UUID(),
        kind: AlarmKind,
        triggerDate: Date,
        message: String,
        sound: AlarmSound?,
        state: AlarmState = .scheduled
    ) {
        self.id = id
        self.kind = kind
        self.triggerDate = triggerDate
        self.message = message
        self.sound = sound
        self.state = state
    }

    var title: String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Alarm" : trimmed
    }

    func detailText(referenceDate: Date) -> String {
        switch kind {
        case .countdown:
            let remaining = max(triggerDate.timeIntervalSince(referenceDate), 0)
            return "Countdown · \(remaining.formattedCountdown)"
        case let .clockTime(hour, minute):
            return "At \(Self.clockFormatter.string(from: triggerDate)) · \(String(format: "%02d:%02d", hour, minute))"
        }
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()
}

extension TimeInterval {
    var formattedCountdown: String {
        let totalSeconds = Int(self.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        }

        return String(format: "%02dm %02ds", minutes, seconds)
    }
}
