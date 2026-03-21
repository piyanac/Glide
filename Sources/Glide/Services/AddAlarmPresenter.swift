import AppKit
import SwiftUI

@MainActor
final class AddAlarmPresenter: ObservableObject {
    private let store: AlarmStore
    private let preferences: AppPreferences
    private var windowController: AddAlarmWindowController?

    init(store: AlarmStore, preferences: AppPreferences) {
        self.store = store
        self.preferences = preferences
    }

    func show() {
        if let windowController {
            windowController.show()
            return
        }

        let controller = AddAlarmWindowController(store: store, preferences: preferences) { [weak self] in
            self?.windowController = nil
        }
        windowController = controller
        controller.show()
    }

    func close() {
        windowController?.close()
        windowController = nil
    }
}

@MainActor
private final class AddAlarmWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void

    init(store: AlarmStore, preferences: AppPreferences, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovable = false
        window.level = .modalPanel
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true

        let rootView = GlidePanelView(
            store: store,
            preferences: preferences
        ) {
            window.close()
        }
        window.contentView = NSHostingView(rootView: rootView)

        super.init(window: window)
        window.delegate = self
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

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
