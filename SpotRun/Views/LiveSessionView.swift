import SwiftUI

struct LiveSessionView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var glow = false

    var body: some View {
        VStack(spacing: 24) {
            header
            heartRateCard
            paceRow
            playbackControls
            Spacer()
            sessionControls
        }
        .padding()
        .background(LinearGradient(colors: backgroundColors(), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("SpotRun Session")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(model.mode == .outdoor ? "Outdoor" : "Treadmill")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            Spacer()
            Label("Watch", systemImage: "applewatch")
                .foregroundStyle(.white)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var heartRateCard: some View {
        VStack(spacing: 16) {
            Text("Heart Rate")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Text(model.liveMetrics.heartRateBpm.map { "\($0)" } ?? "--")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(zoneLabel())
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            zoneBar
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(glow ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: glow ? Color.white.opacity(0.4) : .clear, radius: glow ? 20 : 0)
    }

    private var zoneBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(Color.white)
                    .frame(width: CGFloat(zoneProgress()) * geometry.size.width)
            }
        }
        .frame(height: 12)
    }

    private var paceRow: some View {
        HStack(spacing: 16) {
            metricTile(title: "Pace", value: paceString(), systemImage: "figure.run")
            metricTile(title: "Cadence", value: stepsString(), systemImage: "shoeprints.fill")
        }
    }

    private func metricTile(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusHeadline())
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(statusSubheadline())
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button(action: { }) {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private func statusHeadline() -> String {
        if !model.liveMetrics.isPaceRequirementMet && model.userSettings.minimumPaceEnabled {
            return "Pick up the pace"
        }
        switch model.liveMetrics.zoneState {
        case .inZone:
            return "In Zone — music up"
        case .outOfZone:
            return "Find your zone"
        case .unknown:
            return "Waiting for heart rate"
        }
    }

    private func statusSubheadline() -> String {
        if !model.liveMetrics.isPaceRequirementMet && model.userSettings.minimumPaceEnabled {
            return "Hit at least \(String(format: "%.1f", model.userSettings.minimumPaceKmh)) km/h to keep playing"
        }
        switch model.liveMetrics.zoneState {
        case .inZone:
            return "Stay steady to keep the beat going"
        case .outOfZone:
            return "Ease up or push to return between \(zoneRange().lowerBound)-\(zoneRange().upperBound) bpm"
        case .unknown:
            return "Make sure your heart-rate sensor is connected"
        }
    }

    private func zoneRange() -> ClosedRange<Int> {
        guard let zone = HRZone.defaultZones.first(where: { $0.id == model.userSettings.selectedZoneId }) else {
            return 0...0
        }
        return zone.bpmRange(maxHR: model.userSettings.maxHeartRate)
    }

    private var sessionControls: some View {
        HStack(spacing: 16) {
            Button(action: { model.endSession() }) {
                Label("End", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Button(action: { }) {
                Label(model.liveMetrics.playbackState == .playing ? "Pause" : "Resume", systemImage: model.liveMetrics.playbackState == .playing ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func paceString() -> String {
        if let pace = model.liveMetrics.paceKmh {
            return String(format: "%.1f km/h", pace)
        }
        return "--"
    }

    private func stepsString() -> String {
        if let steps = model.liveMetrics.stepsPerMinute {
            return "\(steps) spm"
        }
        return "--"
    }

    private func zoneLabel() -> String {
        switch model.liveMetrics.zoneState {
        case .inZone: return "In Zone"
        case .outOfZone: return "Out of Zone"
        case .unknown: return "Waiting for HR"
        }
    }

    private func zoneProgress() -> Double {
        guard let bpm = model.liveMetrics.heartRateBpm,
              let zone = HRZone.defaultZones.first(where: { $0.id == model.userSettings.selectedZoneId }) else {
            return 0
        }
        let range = zone.bpmRange(maxHR: model.userSettings.maxHeartRate)
        let clamped = min(max(Double(bpm - range.lowerBound) / Double(range.upperBound - range.lowerBound), 0), 1)
        return clamped
    }

    private func backgroundColors() -> [Color] {
        switch model.userSettings.selectedZoneId {
        case 1: return [.blue.opacity(0.7), .black]
        case 2: return [.teal, .black]
        case 3: return [.green, .black]
        case 4: return [.orange, .black]
        case 5: return [.red, .black]
        default: return [.gray, .black]
        }
    }
}
