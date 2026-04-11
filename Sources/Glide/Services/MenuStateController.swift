import Combine
import Foundation

@MainActor
final class MenuStateController: ObservableObject {
    @Published private(set) var statusTitle = AppStrings.appName
    @Published private(set) var statusSymbolName = "timer"
    @Published private(set) var nextAlarmSummary = AppStrings.noAlarmsScheduled

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

        statusTitle = activeAlarms.isEmpty ? AppStrings.appName : "\(activeAlarms.count)"
        statusSymbolName = activeAlarms.isEmpty ? "timer" : "alarm.fill"

        if let nextAlarm = activeAlarms.first {
            nextAlarmSummary = nextAlarm.detailText(referenceDate: Date())
        } else {
            nextAlarmSummary = AppStrings.noAlarmsScheduled
        }
    }
}
