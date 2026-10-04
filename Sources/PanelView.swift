import SwiftUI

struct SleepPanelView: View {
    var onSleep: () -> Void
    var onQuit: () -> Void

    @State private var sleeping = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: sleeping ? "moon.zzz.fill" : "moon.stars.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(height: 44)
                Text(sleeping ? "Good night" : "Sleep display")
                    .font(.headline)
                Text("Turns the screen off.\nYour Mac keeps running.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            Button(action: sleep) {
                Text("Sleep Display").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider()

            Button("Quit", action: onQuit)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .frame(width: 240)
    }

    private func sleep() {
        guard !sleeping else { return }
        withAnimation { sleeping = true }
        onSleep()
    }
}
