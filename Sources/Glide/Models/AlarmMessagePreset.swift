import Foundation

struct AlarmMessagePreset: Identifiable, Equatable, Codable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }

    static let defaults: [AlarmMessagePreset] = [
        AlarmMessagePreset(text: "Alarm"),
    ]
}
