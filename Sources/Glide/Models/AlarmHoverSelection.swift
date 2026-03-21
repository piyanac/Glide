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
        switch zone {
        case .cancel:
            return AlarmHoverPreview(title: "Cancel")
        case .shortTimer:
            return AlarmHoverPreview(title: duration?.selectionDurationText ?? "1 sec")
        case .longTimer:
            let targetDate = now.addingTimeInterval(duration ?? 3600)
            return AlarmHoverPreview(title: AlarmHoverPreview.absoluteTimeString(for: targetDate, relativeTo: now))
        }
    }

    private func mappedDuration(minimum: TimeInterval, maximum: TimeInterval) -> TimeInterval {
        let span = maximum - minimum
        let curvedX = pow(normalizedX, 1.2)
        return minimum + span * curvedX
    }
}

struct AlarmHoverPreview: Equatable {
    let title: String

    static func absoluteTimeString(for targetDate: Date, relativeTo now: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = calendar.isDate(targetDate, inSameDayAs: now) ? "HH:mm" : "MM/dd HH:mm"
        return formatter.string(from: targetDate)
    }
}

extension TimeInterval {
    var selectionDurationText: String {
        let totalSeconds = max(Int(self.rounded()), 1)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

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
    }
}
