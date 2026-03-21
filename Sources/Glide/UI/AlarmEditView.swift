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
            Text("Edit Alarm")
                .font(.system(size: 24, weight: .bold))

            Text(alarm.detailText(referenceDate: Date()))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Alarm", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3, reservesSpace: true)

            Toggle("Play Sound", isOn: $soundEnabled)

            Picker("Sound", selection: $selectedSound) {
                ForEach(AlarmSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
            .disabled(!soundEnabled)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
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
