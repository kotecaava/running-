import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject private var model: AppViewModel
    let summary: WorkoutSummary

    var body: some View {
        VStack(spacing: 24) {
            Text("Session Complete")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 32)

            VStack(spacing: 16) {
                summaryRow(title: "Time in zone", value: formattedTime(summary.timeInZoneSeconds))
                summaryRow(title: "Avg HR", value: summary.averageHeartRate.map { "\($0) bpm" } ?? "--")
                summaryRow(title: "Max HR", value: summary.maxHeartRate.map { "\($0) bpm" } ?? "--")
                if let distance = summary.distance {
                    summaryRow(title: "Distance", value: String(format: "%.2f km", distance))
                }
                if let steps = summary.steps {
                    summaryRow(title: "Steps", value: "\(steps)")
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 12) {
                Text("Share the streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("I powered my playlist with Zone \(model.userSettings.selectedZoneId)")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Spacer()

            Button(action: { model.route = .home }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
        }
        .font(.title3)
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%dm %02ds", minutes, secs)
    }
}
