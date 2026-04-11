import SwiftUI

struct AlarmEditView: View {
    let alarm: Alarm

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AlarmStore

    @State private var message: String
    @State private var soundEnabled: Bool
    @State private var selectedSound: AlarmSound

    init(alarm: Alarm) {
        self.alarm = alarm
        _message = State(initialValue: alarm.message)
        _soundEnabled = State(initialValue: alarm.sound != nil)
        _selectedSound = State(initialValue: alarm.sound ?? .glass)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.editAlarm)
                .font(.system(size: 24, weight: .bold))

            Text(alarm.detailText(referenceDate: Date()))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(AppStrings.messagePlaceholder, text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3, reservesSpace: true)

            Toggle(AppStrings.playSound, isOn: $soundEnabled)

            Picker(AppStrings.sound, selection: $selectedSound) {
                ForEach(AlarmSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
            .disabled(!soundEnabled)

            HStack {
                Button(AppStrings.cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(AppStrings.save) {
                    store.updateAlarm(
                        id: alarm.id,
                        message: message,
                        sound: soundEnabled ? selectedSound : nil
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 260)
    }
}
