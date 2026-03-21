import SwiftUI

struct PreferencesView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case messages = "Alarm Messages"

        var id: String { rawValue }
    }

    @EnvironmentObject private var preferences: AppPreferences

    @State private var selectedTab: Tab = .general
    @State private var newPresetText = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            Divider()

            Group {
                switch selectedTab {
                case .general:
                    generalTab
                case .messages:
                    messagesTab
                }
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private var generalTab: some View {
        Form {
            Toggle("Play sound by default", isOn: $preferences.playSoundByDefault)

            Picker("Default sound", selection: $preferences.defaultSound) {
                ForEach(AlarmSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var messagesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            List {
                ForEach($preferences.messagePresets) { $preset in
                    HStack {
                        TextField("Preset", text: $preset.text)
                        Spacer()
                        Button(role: .destructive) {
                            preferences.removePreset(id: preset.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .disabled(preferences.messagePresets.count == 1)
                    }
                    .padding(.vertical, 4)
                }
            }

            HStack {
                TextField("New preset message", text: $newPresetText)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    preferences.addPreset(newPresetText)
                    newPresetText = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
