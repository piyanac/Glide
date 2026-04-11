import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    @Published var playSoundByDefault: Bool
    @Published var defaultSound: AlarmSound
    @Published var showDurationsUnderFiveHoursAsHourMinute: Bool
    @Published var messagePresets: [AlarmMessagePreset]

    init(
        playSoundByDefault: Bool = true,
        defaultSound: AlarmSound = .glass,
        showDurationsUnderFiveHoursAsHourMinute: Bool = false,
        messagePresets: [AlarmMessagePreset] = AlarmMessagePreset.defaults
    ) {
        self.playSoundByDefault = playSoundByDefault
        self.defaultSound = defaultSound
        self.showDurationsUnderFiveHoursAsHourMinute = showDurationsUnderFiveHoursAsHourMinute
        self.messagePresets = messagePresets.isEmpty ? AlarmMessagePreset.defaults : messagePresets
    }

    func addPreset(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messagePresets.append(AlarmMessagePreset(text: trimmed))
    }

    func updatePreset(id: UUID, text: String) {
        guard let index = messagePresets.firstIndex(where: { $0.id == id }) else { return }
        messagePresets[index].text = text
    }

    func removePreset(id: UUID) {
        guard messagePresets.count > 1 else { return }
        messagePresets.removeAll { $0.id == id }
    }
}
