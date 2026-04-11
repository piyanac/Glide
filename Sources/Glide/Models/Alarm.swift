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
        return trimmed.isEmpty ? AppStrings.defaultAlarmTitle : trimmed
    }

    func detailText(referenceDate: Date, language: AppLanguage = .current) -> String {
        switch kind {
        case .countdown:
            let remaining = max(triggerDate.timeIntervalSince(referenceDate), 0)
            return AlarmTextFormatter.countdownDetail(remaining: remaining, language: language)
        case let .clockTime(hour, minute):
            return AlarmTextFormatter.clockTimeDetail(
                triggerDate: triggerDate,
                hour: hour,
                minute: minute,
                language: language
            )
        }
    }
}

extension TimeInterval {
    func formattedCountdown(language: AppLanguage = .current) -> String {
        let totalSeconds = Int(self.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        switch language {
        case .english:
            if hours > 0 {
                return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
            }

            return String(format: "%02dm %02ds", minutes, seconds)
        case .traditionalChinese:
            if hours > 0 {
                return String(format: "%02d 小時 %02d 分 %02d 秒", hours, minutes, seconds)
            }

            return String(format: "%02d 分 %02d 秒", minutes, seconds)
        }
    }
}

enum AppLanguage: Equatable {
    case english
    case traditionalChinese

    static var current: Self {
        from(localizationIdentifier: L10n.localizationIdentifier)
    }

    static func from(localizationIdentifier: String) -> Self {
        let normalized = localizationIdentifier
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        if normalized.hasPrefix("zh-hant") {
            return .traditionalChinese
        }

        return .english
    }

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_US_POSIX")
        case .traditionalChinese:
            return Locale(identifier: "zh_Hant_TW")
        }
    }

    var localizationIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .traditionalChinese:
            return "zh-Hant"
        }
    }
}

enum L10n {
    #if SWIFT_PACKAGE
    private static let bundle = Bundle.module
    #else
    private static let bundle = Bundle.main
    #endif

    private static let table = "Localizable"

    static var localizationIdentifier: String {
        bundle.preferredLocalizations.first ?? bundle.developmentLocalization ?? "en"
    }

    static func string(_ key: String, default defaultValue: String, language: AppLanguage? = nil) -> String {
        localizedBundle(for: language).localizedString(forKey: key, value: defaultValue, table: table)
    }

    static func format(
        _ key: String,
        default defaultValue: String,
        language: AppLanguage? = nil,
        locale: Locale? = nil,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key, default: defaultValue, language: language),
            locale: locale ?? AppLanguage.current.locale,
            arguments: arguments
        )
    }

    private static func localizedBundle(for language: AppLanguage?) -> Bundle {
        guard
            let language,
            let path = bundle.path(forResource: language.localizationIdentifier, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else {
            return bundle
        }

        return localizedBundle
    }
}

enum AppStrings {
    static var appName: String { "Glide" }
    static var preferencesTitle: String { L10n.string("window.preferences.title", default: "Preferences") }
    static var addAlarm: String { L10n.string("menu.add_alarm", default: "Add Alarm") }
    static var quit: String { L10n.string("menu.quit", default: "Quit") }
    static var noActiveAlarms: String { L10n.string("menu.empty.title", default: "No Active Alarms") }
    static var emptyAlarmDescription: String {
        L10n.string("menu.empty.body", default: "Create a countdown or direct-time alarm from the button above.")
    }
    static var privacyPolicy: String { L10n.string("menu.help.privacy_policy", default: "Privacy Policy") }
    static var glideSupport: String { L10n.string("menu.help.support", default: "Glide Support") }
    static var generalTab: String { L10n.string("prefs.tab.general", default: "General") }
    static var alarmMessagesTab: String { L10n.string("prefs.tab.messages", default: "Alarm Messages") }
    static var tabPickerLabel: String { L10n.string("prefs.tab.accessibility_label", default: "Tab") }
    static var playSoundByDefault: String { L10n.string("prefs.play_sound_by_default", default: "Play sound by default") }
    static var showDurationsUnderFiveHoursAsHourMinute: String {
        L10n.string(
            "prefs.show_durations_under_five_hours_as_hour_minute",
            default: "Show durations under 5 hours as hour and minute"
        )
    }
    static var defaultSound: String { L10n.string("prefs.default_sound", default: "Default sound") }
    static var presetPlaceholder: String { L10n.string("prefs.preset.placeholder", default: "Preset") }
    static var newPresetMessage: String { L10n.string("prefs.new_preset.placeholder", default: "New preset message") }
    static var add: String { L10n.string("common.add", default: "Add") }
    static var editAlarm: String { L10n.string("edit_alarm.title", default: "Edit Alarm") }
    static var messagePlaceholder: String { defaultAlarmTitle }
    static var playSound: String { L10n.string("alarm.play_sound", default: "Play Sound") }
    static var sound: String { L10n.string("alarm.sound", default: "Sound") }
    static var cancel: String { L10n.string("common.cancel", default: "Cancel") }
    static var save: String { L10n.string("common.save", default: "Save") }
    static var alertHeader: String { L10n.string("alert.header", default: "Alarm") }
    static var dismiss: String { L10n.string("alert.dismiss", default: "Dismiss") }
    static var previewTimeLabel: String { L10n.string("panel.preview.time_label", default: "Set an alarm at") }
    static var previewMessageLabel: String { L10n.string("panel.preview.message_label", default: "Set message to") }
    static var previewPlaceholder: String { "--:--" }
    static var customizeMessage: String { L10n.string("panel.customize.title", default: "Customize Message") }
    static var customMessage: String { L10n.string("panel.custom_message.label", default: "Custom Message") }
    static var back: String { L10n.string("common.back", default: "Back") }
    static var createAlarm: String { L10n.string("panel.create_alarm", default: "Create Alarm") }
    static var customize: String { L10n.string("panel.preview.customize", default: "Customize...") }
    static var defaultAlarmTitle: String { L10n.string("alarm.default_title", default: "Alarm") }
    static var noAlarmsScheduled: String { L10n.string("status.no_alarms", default: "No alarms scheduled") }
}

enum AlarmTextFormatter {
    static func countdownDetail(remaining: TimeInterval, language: AppLanguage = .current) -> String {
        L10n.format(
            "alarm.detail.countdown",
            default: "Countdown · %@",
            language: language,
            locale: language.locale,
            remaining.formattedCountdown(language: language)
        )
    }

    static func clockTimeDetail(
        triggerDate: Date,
        hour: Int,
        minute: Int,
        language: AppLanguage = .current
    ) -> String {
        let selectedTime = String(format: "%02d:%02d", hour, minute)
        let formattedDate = formattedAlarmDate(triggerDate, language: language)
        return L10n.format(
            "alarm.detail.clock_time",
            default: "At %@ · %@",
            language: language,
            locale: language.locale,
            formattedDate,
            selectedTime
        )
    }

    static func formattedAlarmDate(_ date: Date, language: AppLanguage = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func absoluteTimeString(
        for targetDate: Date,
        relativeTo now: Date,
        language: AppLanguage = .current,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.calendar = calendar
        formatter.dateFormat = calendar.isDate(targetDate, inSameDayAs: now) ? "HH:mm" : (language == .english ? "MM/dd HH:mm" : "M/d HH:mm")
        return formatter.string(from: targetDate)
    }

    static func selectionTitle(_ selection: AlarmDraft.Selection, language: AppLanguage = .current) -> String {
        switch selection {
        case let .countdown(duration):
            return L10n.format(
                "draft.selection.countdown",
                default: "%@ countdown",
                language: language,
                locale: language.locale,
                duration.selectionDurationText(language: language)
            )
        case let .clockTime(hour, minute):
            return L10n.format(
                "draft.selection.clock_time",
                default: "Alarm at %02d:%02d",
                language: language,
                locale: language.locale,
                hour,
                minute
            )
        }
    }

    static func customizeSummary(
        selection: AlarmDraft.Selection,
        previewDate: Date,
        language: AppLanguage = .current
    ) -> String {
        let selectionTitle = self.selectionTitle(selection, language: language)
        let formattedDate = formattedAlarmDate(previewDate, language: language)
        return L10n.format(
            "panel.customize.ends_at",
            default: "%@ · ends %@",
            language: language,
            locale: language.locale,
            selectionTitle,
            formattedDate
        )
    }

    static func soundDisplayName(_ sound: AlarmSound, language: AppLanguage = .current) -> String {
        _ = language
        switch sound {
        case .basso:
            return L10n.string("sound.basso", default: "Basso", language: language)
        case .blow:
            return L10n.string("sound.blow", default: "Blow", language: language)
        case .bottle:
            return L10n.string("sound.bottle", default: "Bottle", language: language)
        case .frog:
            return L10n.string("sound.frog", default: "Frog", language: language)
        case .funk:
            return L10n.string("sound.funk", default: "Funk", language: language)
        case .glass:
            return L10n.string("sound.glass", default: "Glass", language: language)
        case .hero:
            return L10n.string("sound.hero", default: "Hero", language: language)
        case .ping:
            return L10n.string("sound.ping", default: "Ping", language: language)
        case .pop:
            return L10n.string("sound.pop", default: "Pop", language: language)
        case .submarine:
            return L10n.string("sound.submarine", default: "Submarine", language: language)
        case .tink:
            return L10n.string("sound.tink", default: "Tink", language: language)
        }
    }
}
