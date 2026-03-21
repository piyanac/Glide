import Foundation

struct AlarmDraft {
    enum Selection: Equatable {
        case countdown(TimeInterval)
        case clockTime(hour: Int, minute: Int)

        var title: String {
            switch self {
            case let .countdown(duration):
                return "\(duration.selectionDurationText) countdown"
            case let .clockTime(hour, minute):
                return String(format: "Alarm at %02d:%02d", hour, minute)
            }
        }

        var triggerDate: Date {
            previewDate(now: Date())
        }

        func previewDate(now: Date) -> Date {
            switch self {
            case let .countdown(duration):
                return AlarmDateResolver.countdownDate(from: now, duration: duration)
            case let .clockTime(hour, minute):
                return AlarmDateResolver.nextClockTime(hour: hour, minute: minute, now: now)
            }
        }

        func kind() -> AlarmKind {
            switch self {
            case let .countdown(duration):
                return .countdown(duration: duration)
            case let .clockTime(hour, minute):
                return .clockTime(hour: hour, minute: minute)
            }
        }
    }

    var selection: Selection
    var selectedPreset: String
    var customMessage: String
    var soundEnabled: Bool
    var selectedSound: AlarmSound

    func resolvedMessage() -> String {
        let trimmedCustom = customMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCustom.isEmpty {
            return trimmedCustom
        }

        let trimmedPreset = selectedPreset.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPreset.isEmpty ? "Alarm" : trimmedPreset
    }

    func makeAlarm(now: Date = Date()) -> Alarm {
        Alarm(
            kind: selection.kind(),
            triggerDate: selection.previewDate(now: now),
            message: resolvedMessage(),
            sound: soundEnabled ? selectedSound : nil
        )
    }
}
