import Combine
import Foundation

@MainActor
final class MenuStateController: ObservableObject {
    @Published private(set) var statusTitle = "Glide"
    @Published private(set) var statusSymbolName = "timer"
    @Published private(set) var nextAlarmSummary = "No alarms scheduled"

    private var cancellables = Set<AnyCancellable>()

    init(store: AlarmStore) {
        store.$alarms
            .receive(on: RunLoop.main)
            .sink { [weak self] alarms in
                self?.update(from: alarms)
            }
            .store(in: &cancellables)
    }

    private func update(from alarms: [Alarm]) {
        let activeAlarms = alarms
            .filter { $0.state != .dismissed }
            .sorted { $0.triggerDate < $1.triggerDate }

        statusTitle = activeAlarms.isEmpty ? "Glide" : "\(activeAlarms.count)"
        statusSymbolName = activeAlarms.isEmpty ? "timer" : "alarm.fill"

        if let nextAlarm = activeAlarms.first {
            nextAlarmSummary = nextAlarm.detailText(referenceDate: Date())
        } else {
            nextAlarmSummary = "No alarms scheduled"
        }
    }
}
