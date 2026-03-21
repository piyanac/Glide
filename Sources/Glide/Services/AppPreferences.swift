import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    @Published var playSoundByDefault = true
    @Published var defaultSound: AlarmSound = .glass
    @Published var messagePresets = AlarmMessagePreset.defaults

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
