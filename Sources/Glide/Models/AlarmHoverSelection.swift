import Foundation

enum AlarmHoverZone {
    case cancel
    case shortTimer
    case longTimer
}

struct AlarmHoverSelection: Equatable {
    let zone: AlarmHoverZone
    let normalizedX: Double

    init(zone: AlarmHoverZone, normalizedX: Double) {
        self.zone = zone
        self.normalizedX = min(max(normalizedX, 0), 1)
    }

    var duration: TimeInterval? {
        switch zone {
        case .cancel:
            return nil
        case .shortTimer:
            return mappedDuration(minimum: 1, maximum: 59 * 60)
        case .longTimer:
            return mappedDuration(minimum: 60 * 60, maximum: 24 * 60 * 60)
        }
    }

    var draftSelection: AlarmDraft.Selection? {
        guard let duration else { return nil }
        return .countdown(duration)
    }

    func preview(now: Date) -> AlarmHoverPreview {
        preview(now: now, preferHourMinuteDisplayUnderFiveHours: false)
    }

    private func mappedDuration(minimum: TimeInterval, maximum: TimeInterval) -> TimeInterval {
        let span = maximum - minimum
        let curvedX = pow(normalizedX, 1.2)
        return minimum + span * curvedX
    }
}

struct AlarmHoverPreview: Equatable {
    let title: String

    static func absoluteTimeString(
        for targetDate: Date,
        relativeTo now: Date,
        language: AppLanguage = .current,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        AlarmTextFormatter.absoluteTimeString(
            for: targetDate,
            relativeTo: now,
            language: language,
            calendar: calendar
        )
    }
}

extension AlarmHoverSelection {
    func preview(
        now: Date,
        preferHourMinuteDisplayUnderFiveHours: Bool
    ) -> AlarmHoverPreview {
        switch zone {
        case .cancel:
            return AlarmHoverPreview(title: AppStrings.cancel)
        case .shortTimer:
            return AlarmHoverPreview(
                title: duration?.selectionDurationText(
                    language: .current,
                    preferHourMinuteDisplayUnderFiveHours: preferHourMinuteDisplayUnderFiveHours
                ) ?? TimeInterval(1).selectionDurationText(
                    language: .current,
                    preferHourMinuteDisplayUnderFiveHours: preferHourMinuteDisplayUnderFiveHours
                )
            )
        case .longTimer:
            if let duration, preferHourMinuteDisplayUnderFiveHours, duration <= 5 * 60 * 60 {
                return AlarmHoverPreview(
                    title: duration.selectionDurationText(
                        language: .current,
                        preferHourMinuteDisplayUnderFiveHours: true
                    )
                )
            }

            let targetDate = now.addingTimeInterval(duration ?? 3600)
            return AlarmHoverPreview(title: AlarmHoverPreview.absoluteTimeString(for: targetDate, relativeTo: now))
        }
    }
}

extension TimeInterval {
    func selectionDurationText(
        language: AppLanguage = .current,
        preferHourMinuteDisplayUnderFiveHours: Bool = false
    ) -> String {
        let totalSeconds = max(Int(self.rounded()), 1)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let fiveHoursInSeconds = 5 * 60 * 60

        if preferHourMinuteDisplayUnderFiveHours, totalSeconds <= fiveHoursInSeconds {
            let roundedUpMinutes = max(Int(ceil(Double(totalSeconds) / 60.0)), 1)
            let displayHours = roundedUpMinutes / 60
            let displayMinutes = roundedUpMinutes % 60

            switch language {
            case .english:
                if displayHours == 0 {
                    return "\(displayMinutes)m"
                }
                if displayMinutes == 0 {
                    return "\(displayHours)h"
                }
                return "\(displayHours)h \(displayMinutes)m"
            case .traditionalChinese:
                if displayHours == 0 {
                    return "\(displayMinutes) 分"
                }
                if displayMinutes == 0 {
                    return "\(displayHours) 時"
                }
                return "\(displayHours) 時 \(displayMinutes) 分"
            }
        }

        switch language {
        case .english:
            if hours > 0 {
                if minutes == 0 {
                    return hours == 1 ? "1 hour" : "\(hours) hours"
                }
                return "\(hours)h \(minutes)m"
            }

            if minutes > 0 {
                if seconds == 0 {
                    return minutes == 1 ? "1 minute" : "\(minutes) minutes"
                }
                return "\(minutes)m \(seconds)s"
            }

            return totalSeconds == 1 ? "1 sec" : "\(totalSeconds) sec"
        case .traditionalChinese:
            if hours > 0 {
                if minutes == 0 {
                    return "\(hours) 小時"
                }
                return "\(hours) 小時 \(minutes) 分"
            }

            if minutes > 0 {
                if seconds == 0 {
                    return "\(minutes) 分鐘"
                }
                return "\(minutes) 分 \(seconds) 秒"
            }

            return "\(totalSeconds) 秒"
        }
    }
}
