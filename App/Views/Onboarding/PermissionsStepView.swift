import SwiftUI
import SpotRunCore

struct PermissionsStepView: View {
    @EnvironmentObject private var model: AppViewModel
    let onComplete: () -> Void

    @State private var healthGranted = false
    @State private var motionGranted = false
    @State private var locationGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Unlock SpotRun")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 32)

            permissionRow(title: "Health", description: "Heart rate & max HR", granted: healthGranted) {
                healthGranted = true
                model.healthStatus = .authorized
            }
            permissionRow(title: "Motion", description: "Steps & cadence", granted: motionGranted) {
                motionGranted.toggle()
            }
            permissionRow(title: "Location", description: "Outdoor pace tracking", granted: locationGranted) {
                locationGranted.toggle()
            }
            permissionRow(title: "Notifications", description: "Streaks & reminders", granted: notificationsGranted) {
                notificationsGranted.toggle()
            }

            Spacer()

            Button(action: onComplete) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(healthGranted ? Color.white : Color.white.opacity(0.3))
                    .foregroundStyle(Color.black.opacity(healthGranted ? 1 : 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }
            .disabled(!healthGranted)

            Button("Skip & configure later", action: onComplete)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .background(Color.black.ignoresSafeArea())
    }

    private func permissionRow(title: String, description: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: granted ? "checkmark.seal.fill" : "chevron.right")
                    .foregroundStyle(granted ? .green : .white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
