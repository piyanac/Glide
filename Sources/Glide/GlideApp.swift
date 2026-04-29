import AppKit
import SwiftUI

@main
struct GlideApp: App {
    @StateObject private var preferences: AppPreferences
    @StateObject private var store: AlarmStore
    @StateObject private var alertPresenter: AlertPresenter
    @StateObject private var addAlarmPresenter: AddAlarmPresenter
    @StateObject private var scheduler: AlarmScheduler
    @StateObject private var menuState: MenuStateController
    private let persistenceCoordinator: AppStatePersistenceCoordinator

    init() {
        let persistence = AppStatePersistence()
        let snapshot = persistence.load()
        let preferences = AppPreferences(
            playSoundByDefault: snapshot.playSoundByDefault,
            defaultSound: snapshot.defaultSound,
            showDurationsUnderFiveHoursAsHourMinute: snapshot.showDurationsUnderFiveHoursAsHourMinute,
            messagePresets: snapshot.messagePresets
        )
        let store = AlarmStore(alarms: snapshot.alarms)
        let alertPresenter = AlertPresenter(store: store)
        let addAlarmPresenter = AddAlarmPresenter(store: store, preferences: preferences)
        let scheduler = AlarmScheduler(store: store, alertPresenter: alertPresenter)
        let menuState = MenuStateController(store: store)
        let persistenceCoordinator = AppStatePersistenceCoordinator(persistence: persistence)
        persistenceCoordinator.connect(store: store, preferences: preferences)

        _preferences = StateObject(wrappedValue: preferences)
        _store = StateObject(wrappedValue: store)
        _alertPresenter = StateObject(wrappedValue: alertPresenter)
        _addAlarmPresenter = StateObject(wrappedValue: addAlarmPresenter)
        _scheduler = StateObject(wrappedValue: scheduler)
        _menuState = StateObject(wrappedValue: menuState)
        self.persistenceCoordinator = persistenceCoordinator

        NSApplication.shared.setActivationPolicy(.accessory)
        scheduler.start()
    }

    var body: some Scene {
        MenuBarExtra(menuState.statusTitle, systemImage: menuState.statusSymbolName) {
            MenuBarRootView()
                .environmentObject(preferences)
                .environmentObject(store)
                .environmentObject(alertPresenter)
                .environmentObject(addAlarmPresenter)
                .environmentObject(menuState)
        }
        .menuBarExtraStyle(.window)

        Window(AppStrings.preferencesTitle, id: "preferences") {
            PreferencesView()
                .environmentObject(preferences)
                .frame(minWidth: 420, idealWidth: 420, minHeight: 360, idealHeight: 380)
        }
        .windowResizability(.contentSize)
        .commands {
            AppHelpCommands()
        }
    }
}
