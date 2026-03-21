import AppKit
import SwiftUI

@MainActor
final class AlertPresenter: ObservableObject {
    private let store: AlarmStore
    private var queue: [Alarm] = []
    private var windowController: BlockingAlertWindowController?

    init(store: AlarmStore) {
        self.store = store
    }

    func enqueue(_ alarm: Alarm) {
        queue.append(alarm)
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard windowController == nil, !queue.isEmpty else { return }

        let nextAlarm = queue.removeFirst()
        nextAlarm.sound?.play()

        let controller = BlockingAlertWindowController(alarm: nextAlarm) { [weak self] alarm in
            Task { @MainActor in
                self?.store.dismissAlarm(id: alarm.id)
                self?.windowController?.close()
                self?.windowController = nil
                self?.presentNextIfNeeded()
            }
        }

        windowController = controller
        controller.show()
    }
}

@MainActor
private final class BlockingAlertWindowController: NSWindowController {
    private let alarm: Alarm
    private let onDismiss: (Alarm) -> Void

    init(alarm: Alarm, onDismiss: @escaping (Alarm) -> Void) {
        self.alarm = alarm
        self.onDismiss = onDismiss

        let content = BlockingAlertView(alarm: alarm) { [alarm] in
            onDismiss(alarm)
        }

        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovable = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.contentView = NSHostingView(rootView: content)

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
