import SwiftUI

struct MenuBarRootView: View {
    private static let alarmRowHeight: CGFloat = 68
    private static let alarmListMaxHeight: CGFloat = 240

    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var addAlarmPresenter: AddAlarmPresenter

    @State private var editingAlarm: Alarm?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                addAlarmPresenter.show()
            } label: {
                Label(AppStrings.addAlarm, systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Divider()

            if store.sortedAlarms.isEmpty {
                EmptyAlarmStateView()
                    .frame(height: 180)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.sortedAlarms) { alarm in
                            AlarmRowView(
                                alarm: alarm,
                                onEdit: {
                                    editingAlarm = alarm
                                },
                                onDelete: {
                                    store.removeAlarm(id: alarm.id)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: alarmListHeight)
            }

            Divider()

            HStack {
                Button {
                    openWindow(id: "preferences")
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)

                Spacer()

                Button(AppStrings.quit) {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
        .sheet(item: $editingAlarm) { alarm in
            AlarmEditView(alarm: alarm)
        }
    }

    private var alarmListHeight: CGFloat {
        min(CGFloat(store.sortedAlarms.count) * Self.alarmRowHeight, Self.alarmListMaxHeight)
    }
}

private struct EmptyAlarmStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "alarm")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(AppStrings.noActiveAlarms)
                .font(.system(size: 16, weight: .semibold))
            Text(AppStrings.emptyAlarmDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}

private struct AlarmRowView: View {
    let alarm: Alarm
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(alarm.detailText(referenceDate: context.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
        }
    }
}
