import AppKit
import SwiftUI

struct AppHelpCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .help) {
            Button {
                open(.privacyPolicy)
            } label: {
                Label(AppStrings.privacyPolicy, systemImage: "arrow.up.right.square")
            }

            Button {
                open(.support)
            } label: {
                Label(AppStrings.glideSupport, systemImage: "arrow.up.right.square")
            }
        }
    }

    private func open(_ destination: Destination) {
        let links = AppHelpLinks.localized(for: .current)

        switch destination {
        case .privacyPolicy:
            NSWorkspace.shared.open(links.privacyPolicyURL)
        case .support:
            NSWorkspace.shared.open(links.supportURL)
        }
    }

    private enum Destination {
        case privacyPolicy
        case support
    }
}
