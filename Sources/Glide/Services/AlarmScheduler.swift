import Foundation

@MainActor
final class AlarmScheduler: ObservableObject {
    private let store: AlarmStore
    private let alertPresenter: AlertPresenter
    private var timer: Timer?
    private var isRunning = false

    init(store: AlarmStore, alertPresenter: AlertPresenter) {
        self.store = store
        self.alertPresenter = alertPresenter
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(now: Date())
            }
        }

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func tick(now: Date) {
        store.activateDueAlarms(now: now).forEach { alarm in
            alertPresenter.enqueue(alarm)
        }
    }
}
