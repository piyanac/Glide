import SwiftUI

struct BlockingAlertView: View {
    let alarm: Alarm
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.88),
                    Color(red: 0.12, green: 0.08, blue: 0.02).opacity(0.96),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Alarm")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))

                Text(alarm.title)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)

                Text(alarm.detailText(referenceDate: Date()))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
}
