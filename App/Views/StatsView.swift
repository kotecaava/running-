import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Weekly Zone Minutes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                heatmapPlaceholder
                trendPlaceholder
                Spacer()
            }
            .padding()
            .navigationTitle("Stats")
        }
    }

    private var heatmapPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 160)
            .overlay(
                VStack {
                    Text("Calendar heat map coming soon")
                        .foregroundStyle(.secondary)
                    Text("Complete 10+ minutes in your zone to light up a day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            )
    }

    private var trendPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 160)
            .overlay(
                VStack {
                    Text("Trends")
                        .font(.headline)
                    Text("Track your best streak and time-in-zone by week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            )
    }
}
