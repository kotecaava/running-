import SwiftUI
import SpotRunCore

struct MaxHRZoneStepView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var maxHR: Double = 180
    @State private var selectedZoneId: Int = 2
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Tune your zone")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 32)

            VStack(alignment: .leading, spacing: 16) {
                Text("Max heart rate")
                    .font(.headline)
                    .foregroundStyle(.white)
                Slider(value: $maxHR, in: 150...210, step: 1)
                Text("\(Int(maxHR)) bpm")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                Text("Select your focus zone")
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(HRZone.defaultZones) { zone in
                    zoneRow(zone)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            Button(action: {
                model.updateMaxHeartRate(Int(maxHR))
                if let selected = HRZone.defaultZones.first(where: { $0.id == selectedZoneId }) {
                    model.updateZoneSelection(selected)
                }
                onComplete()
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            maxHR = Double(model.userSettings.maxHeartRate)
            selectedZoneId = model.userSettings.selectedZoneId
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func zoneRow(_ zone: HRZone) -> some View {
        let isSelected = zone.id == selectedZoneId
        let range = zone.bpmRange(maxHR: Int(maxHR))
        return Button {
            selectedZoneId = zone.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label(for: zone))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(range.lowerBound)–\(range.upperBound) bpm")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color.white.opacity(isSelected ? 0.18 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func label(for zone: HRZone) -> String {
        switch zone.id {
        case 1: return "Zone 1 • Recovery"
        case 2: return "Zone 2 • Aerobic base"
        case 3: return "Zone 3 • Tempo"
        case 4: return "Zone 4 • Threshold"
        case 5: return "Zone 5 • Intervals"
        default: return zone.name
        }
    }
}
