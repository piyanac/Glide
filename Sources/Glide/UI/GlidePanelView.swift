import SwiftUI

struct GlidePanelView: View {
    private enum Step {
        case selection
        case messageSelection
        case customize
    }

    private enum MessageSelection: Equatable {
        case cancel
        case preset(String)
        case customize
    }

    private let store: AlarmStore
    private let preferences: AppPreferences
    private let onClose: () -> Void

    @State private var step: Step = .selection
    @State private var hoveredSelection: AlarmHoverSelection?
    @State private var hoveredMessageSelection: MessageSelection?
    @State private var committedSelection: AlarmDraft.Selection?
    @State private var selectedPreset = "Alarm"
    @State private var customMessage = ""
    @State private var soundEnabled = true
    @State private var selectedSound: AlarmSound = .glass

    init(store: AlarmStore, preferences: AppPreferences, onClose: @escaping () -> Void) {
        self.store = store
        self.preferences = preferences
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            switch step {
            case .selection:
                selectionZones
            case .messageSelection:
                messageZones
            case .customize:
                Color.black.opacity(0.5).ignoresSafeArea()
            }

            switch step {
            case .selection:
                timePreviewOverlay
            case .messageSelection:
                messagePreviewOverlay
            case .customize:
                if let committedSelection {
                    customizeOverlay(selection: committedSelection)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            selectedPreset = availablePresetTexts.first ?? "Alarm"
            soundEnabled = preferences.playSoundByDefault
            selectedSound = preferences.defaultSound
        }
    }

    private var selectionZones: some View {
        VStack(spacing: 0) {
            SpectrumZoneView(
                isActive: hoveredSelection?.zone == .cancel,
                onHoverChange: { _ in
                    hoveredSelection = AlarmHoverSelection(zone: .cancel, normalizedX: 0)
                },
                onHoverEnd: {
                    hoveredSelection = nil
                },
                onActivate: {
                    onClose()
                }
            )

            SpectrumZoneView(
                isActive: hoveredSelection?.zone == .shortTimer,
                onHoverChange: { normalizedX in
                    hoveredSelection = AlarmHoverSelection(zone: .shortTimer, normalizedX: normalizedX)
                },
                onHoverEnd: {
                    hoveredSelection = nil
                },
                onActivate: {
                    guard let draftSelection = hoveredSelection?.draftSelection else { return }
                    committedSelection = draftSelection
                    hoveredMessageSelection = .preset(availablePresetTexts.first ?? "Alarm")
                    step = .messageSelection
                }
            )

            SpectrumZoneView(
                isActive: hoveredSelection?.zone == .longTimer,
                onHoverChange: { normalizedX in
                    hoveredSelection = AlarmHoverSelection(zone: .longTimer, normalizedX: normalizedX)
                },
                onHoverEnd: {
                    hoveredSelection = nil
                },
                onActivate: {
                    guard let draftSelection = hoveredSelection?.draftSelection else { return }
                    committedSelection = draftSelection
                    hoveredMessageSelection = .preset(availablePresetTexts.first ?? "Alarm")
                    step = .messageSelection
                }
            )
        }
    }

    private var messageZones: some View {
        VStack(spacing: 0) {
            MessageZoneView(
                isActive: hoveredMessageSelection == .cancel,
                onHoverChange: { _ in
                    hoveredMessageSelection = .cancel
                },
                onHoverEnd: {
                    hoveredMessageSelection = nil
                },
                onActivate: {
                    onClose()
                }
            )

            MessageZoneView(
                isActive: {
                    if case .preset = hoveredMessageSelection { return true }
                    return false
                }(),
                onHoverChange: { normalizedX in
                    hoveredMessageSelection = messagePresetSelection(for: normalizedX)
                },
                onHoverEnd: {
                    hoveredMessageSelection = nil
                },
                onActivate: {
                    guard
                        let committedSelection,
                        case let .preset(message) = hoveredMessageSelection
                    else { return }

                    let draft = AlarmDraft(
                        selection: committedSelection,
                        selectedPreset: message,
                        customMessage: "",
                        soundEnabled: preferences.playSoundByDefault,
                        selectedSound: preferences.defaultSound
                    )
                    Task { @MainActor in
                        store.addAlarm(draft.makeAlarm())
                        onClose()
                    }
                }
            )

            MessageZoneView(
                isActive: hoveredMessageSelection == .customize,
                onHoverChange: { _ in
                    hoveredMessageSelection = .customize
                },
                onHoverEnd: {
                    hoveredMessageSelection = nil
                },
                onActivate: {
                    selectedPreset = availablePresetTexts.first ?? "Alarm"
                    step = .customize
                }
            )
        }
    }

    private var timePreviewOverlay: some View {
        let preview = hoveredSelection?.preview(now: Date()) ?? AlarmHoverPreview(title: "--:--")

        return centralPreview(
            label: "Set an alarm at",
            value: preview.title,
            valueSize: 46
        )
    }

    private var messagePreviewOverlay: some View {
        centralPreview(
            label: "Set message to",
            value: hoveredMessagePreview,
            valueSize: 40
        )
    }

    private func centralPreview(label: String, value: String, valueSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.black.opacity(0.52))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
        )
        .padding(40)
    }

    private func customizeOverlay(selection: AlarmDraft.Selection) -> some View {
        let previewDate = selection.previewDate(now: Date())

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customize Message")
                        .font(.system(size: 28, weight: .bold))
                    Text("\(selection.title) · ends \(previewDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Message")
                    .font(.headline)
                TextField("Alarm", text: $customMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)
            }

            Toggle("Play Sound", isOn: $soundEnabled)

            Picker("Sound", selection: $selectedSound) {
                ForEach(AlarmSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
            .disabled(!soundEnabled)

            HStack {
                Button("Back") {
                    step = .messageSelection
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Create Alarm") {
                    let draft = AlarmDraft(
                        selection: selection,
                        selectedPreset: selectedPreset,
                        customMessage: customMessage,
                        soundEnabled: soundEnabled,
                        selectedSound: selectedSound
                    )
                    Task { @MainActor in
                        store.addAlarm(draft.makeAlarm())
                        onClose()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(26)
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 30, y: 10)
        .padding(40)
    }

    private var hoveredMessagePreview: String {
        switch hoveredMessageSelection {
        case .cancel:
            return "Cancel"
        case let .preset(message):
            return message
        case .customize:
            return "Customize..."
        case .none:
            return availablePresetTexts.first ?? "Alarm"
        }
    }

    private var availablePresetTexts: [String] {
        let texts = preferences.messagePresets
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return texts.isEmpty ? ["Alarm"] : texts
    }

    private func messagePresetSelection(for normalizedX: Double) -> MessageSelection {
        let presets = availablePresetTexts
        let clamped = min(max(normalizedX, 0), 0.999_999)
        let index = Int(Double(presets.count) * clamped)
        return .preset(presets[index])
    }
}

private struct SpectrumZoneView: View {
    let isActive: Bool
    let onHoverChange: (Double) -> Void
    let onHoverEnd: () -> Void
    let onActivate: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)

            Color.black.opacity(0.5)
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(isActive ? 0.08 : 0))
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case let .active(location):
                        onHoverChange(location.x / width)
                    case .ended:
                        onHoverEnd()
                    }
                }
                .onTapGesture {
                    onActivate()
                }
        }
    }
}

private struct MessageZoneView: View {
    let isActive: Bool
    let onHoverChange: (Double) -> Void
    let onHoverEnd: () -> Void
    let onActivate: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)

            Color.black.opacity(0.5)
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(isActive ? 0.08 : 0))
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.04))
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case let .active(location):
                        onHoverChange(location.x / width)
                    case .ended:
                        onHoverEnd()
                    }
                }
                .onTapGesture {
                    onActivate()
                }
        }
    }
}
