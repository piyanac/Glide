import Foundation

struct AlarmMessagePreset: Identifiable, Equatable, Codable {
    static let defaultsCatalogVersion = 2

    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }

    static let defaults: [AlarmMessagePreset] = [
        AlarmMessagePreset(text: AppStrings.defaultAlarmTitle),
        AlarmMessagePreset(text: "Claude reset"),
        AlarmMessagePreset(text: "Codex reset"),
        AlarmMessagePreset(text: "Gemini reset"),
        AlarmMessagePreset(text: "Copilot reset"),
    ]

    static func migratedPresetsIfNeeded(
        from presets: [AlarmMessagePreset],
        catalogVersion: Int
    ) -> (presets: [AlarmMessagePreset], catalogVersion: Int) {
        guard catalogVersion < defaultsCatalogVersion else {
            return (presets, catalogVersion)
        }

        let existingTexts = Set(presets.map(\.text))
        let missingDefaults = defaults.filter { !existingTexts.contains($0.text) }
        return (presets + missingDefaults, defaultsCatalogVersion)
    }
}
