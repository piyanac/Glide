import Foundation

@MainActor
final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [Alarm]

    init(alarms: [Alarm] = []) {
        self.alarms = alarms
    }

    var sortedAlarms: [Alarm] {
        alarms
            .filter { $0.state != .dismissed }
            .sorted { $0.triggerDate < $1.triggerDate }
    }

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        alarms.sort { $0.triggerDate < $1.triggerDate }
    }

    func alarm(id: UUID) -> Alarm? {
        alarms.first { $0.id == id }
    }

    func updateAlarm(id: UUID, message: String, sound: AlarmSound?) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].message = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppStrings.defaultAlarmTitle : message
        alarms[index].sound = sound
    }

    func removeAlarm(id: UUID) {
        alarms.removeAll { $0.id == id }
    }

    func dismissAlarm(id: UUID) {
        removeAlarm(id: id)
    }

    func activateDueAlarms(now: Date) -> [Alarm] {
        let dueIndices = alarms.indices
            .filter { alarms[$0].state == .scheduled && alarms[$0].triggerDate <= now }
            .sorted { alarms[$0].triggerDate < alarms[$1].triggerDate }

        var activated: [Alarm] = []
        for index in dueIndices {
            alarms[index].state = .firing
            activated.append(alarms[index])
        }

        return activated
    }
}
