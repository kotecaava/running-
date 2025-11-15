import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var maxHR: Double = 0
    @State private var treadmillMode = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Stepper(value: $maxHR, in: 140...210, step: 1) {
                        Text("Max heart rate: \(Int(maxHR)) bpm")
                    }
                    .onChange(of: maxHR) { _, newValue in
                        model.updateMaxHeartRate(Int(newValue))
                    }
                }

                Section("Zones") {
                    Picker("Focus zone", selection: Binding(
                        get: { model.userSettings.selectedZoneId },
                        set: { newValue in
                            if let zone = HRZone.defaultZones.first(where: { $0.id == newValue }) {
                                model.updateZoneSelection(zone)
                            }
                        }
                    )) {
                        ForEach(HRZone.defaultZones) { zone in
                            Text(zone.name).tag(zone.id)
                        }
                    }
                    NavigationLink("Calibrate max HR") {
                        Text("Follow a supervised max effort test to update your max heart rate.")
                            .padding()
                    }
                }

                Section("Music") {
                    Toggle("Auto-DJ", isOn: Binding(
                        get: { model.userSettings.autoDJEnabled },
                        set: { model.setAutoDJ(enabled: $0) }
                    ))
                    Button("Re-authorize Spotify", action: model.markSpotifyConnected)
                }

                Section("Sensors") {
                    Toggle("Treadmill mode", isOn: $treadmillMode)
                        .onChange(of: treadmillMode) { _, newValue in
                            model.setTreadmillMode(newValue)
                        }
                    Toggle("Require min pace", isOn: Binding(
                        get: { model.userSettings.minimumPaceEnabled },
                        set: { model.updatePaceRequirement(isEnabled: $0, pace: model.userSettings.minimumPaceKmh) }
                    ))
                    if model.userSettings.minimumPaceEnabled {
                        Slider(value: Binding(
                            get: { model.userSettings.minimumPaceKmh },
                            set: { model.updatePaceRequirement(isEnabled: true, pace: $0) }
                        ), in: 1...8, step: 0.1)
                        Text(String(format: "%.1f km/h", model.userSettings.minimumPaceKmh))
                    }
                }

                Section("Legal") {
                    NavigationLink("Privacy") { Text("Privacy policy placeholder").padding() }
                    NavigationLink("Terms") { Text("Terms placeholder").padding() }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            maxHR = Double(model.userSettings.maxHeartRate)
            treadmillMode = model.userSettings.treadmillModeEnabled
        }
    }
}
