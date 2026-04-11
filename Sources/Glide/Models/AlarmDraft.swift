import Foundation

struct AlarmDraft {
    enum Selection: Equatable {
        case countdown(TimeInterval)
        case clockTime(hour: Int, minute: Int)

        var title: String {
            title(language: .current)
        }

        func title(language: AppLanguage) -> String {
            AlarmTextFormatter.selectionTitle(self, language: language)
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

    func resolvedMessage(language: AppLanguage = .current) -> String {
        let trimmedCustom = customMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCustom.isEmpty {
            return trimmedCustom
        }

        let trimmedPreset = selectedPreset.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPreset.isEmpty ? AppStrings.defaultAlarmTitle : trimmedPreset
    }

    func makeAlarm(now: Date = Date(), language: AppLanguage = .current) -> Alarm {
        Alarm(
            kind: selection.kind(),
            triggerDate: selection.previewDate(now: now),
            message: resolvedMessage(language: language),
            sound: soundEnabled ? selectedSound : nil
        )
    }
}
