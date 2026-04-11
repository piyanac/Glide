import SwiftUI

struct PreferencesView: View {
    private static let appVersionDisplayText: String = {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(AppStrings.appName) \(version)(\(buildNumber))"
    }()

    private enum Tab: CaseIterable, Identifiable {
        case general
        case messages

        var id: Self { self }

        var title: String {
            switch self {
            case .general:
                return AppStrings.generalTab
            case .messages:
                return AppStrings.alarmMessagesTab
            }
        }
    }

    @EnvironmentObject private var preferences: AppPreferences

    @State private var selectedTab: Tab = .general
    @State private var newPresetText = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker(AppStrings.tabPickerLabel, selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
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
            Toggle(AppStrings.playSoundByDefault, isOn: $preferences.playSoundByDefault)
            Toggle(
                AppStrings.showDurationsUnderFiveHoursAsHourMinute,
                isOn: $preferences.showDurationsUnderFiveHoursAsHourMinute
            )

            Picker(AppStrings.defaultSound, selection: $preferences.defaultSound) {
                ForEach(AlarmSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }

            Text(Self.appVersionDisplayText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var messagesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            List {
                ForEach($preferences.messagePresets) { $preset in
                    HStack {
                        TextField(AppStrings.presetPlaceholder, text: $preset.text)
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
                TextField(AppStrings.newPresetMessage, text: $newPresetText)
                    .textFieldStyle(.roundedBorder)

                Button(AppStrings.add) {
                    preferences.addPreset(newPresetText)
                    newPresetText = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
