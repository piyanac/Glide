import AppKit

enum AlarmSound: String, CaseIterable, Codable, Identifiable {
    case basso = "Basso"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case glass = "Glass"
    case hero = "Hero"
    case ping = "Ping"
    case pop = "Pop"
    case submarine = "Submarine"
    case tink = "Tink"

    var id: String { rawValue }

    var displayName: String { rawValue }

    func play() {
        NSSound(named: NSSound.Name(rawValue))?.play()
    }
}
