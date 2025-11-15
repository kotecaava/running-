import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var showZonePicker = false
    @State private var showPlaylist = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                modeToggle
                startButton
                quickSettings
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showZonePicker) {
                ZonePickerView(isPresented: $showZonePicker)
                    .environmentObject(model)
            }
            .sheet(isPresented: $showPlaylist) {
                PlaylistPickerView(isPresented: $showPlaylist)
                    .environmentObject(model)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greeting())
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            if let zone = currentZone() {
                let range = zone.bpmRange(maxHR: model.userSettings.maxHeartRate)
                Text("Zone \(zone.id) • \(range.lowerBound)–\(range.upperBound) bpm")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeToggle: some View {
        HStack {
            modeButton(.outdoor, title: "Outdoor")
            modeButton(.treadmill, title: "Treadmill")
        }
    }

    private func modeButton(_ mode: WorkoutMode, title: String) -> some View {
        Button {
            withAnimation {
                model.mode = mode
            }
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(model.mode == mode ? Color.white : Color.white.opacity(0.1))
                .foregroundStyle(model.mode == mode ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var startButton: some View {
        Button(action: model.startSession) {
            Text("Start Session")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(model.spotifyStatus == .connected && model.healthStatus == .authorized ? Color.green : Color.gray.opacity(0.4))
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.top, 16)
        }
        .disabled(!(model.spotifyStatus == .connected && model.healthStatus == .authorized))
        .simultaneousGesture(LongPressGesture(minimumDuration: 1.0).onEnded { _ in
            model.startSession()
        })
    }

    private var quickSettings: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    showZonePicker = true
                } label: {
                    SettingChip(title: "Zone", value: currentZoneLabel())
                }
                Button {
                    showPlaylist = true
                } label: {
                    SettingChip(title: "Playlist", value: model.preferredPlaylistName)
                }
            }
            HStack {
                SettingChip(title: "Time", value: "30 min")
                SettingChip(title: "Pace", value: String(format: "%.1f km/h", model.userSettings.minimumPaceKmh))
            }
        }
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Great to see you!"
        }
    }

    private func currentZone() -> HRZone? {
        HRZone.defaultZones.first { $0.id == model.userSettings.selectedZoneId }
    }

    private func currentZoneLabel() -> String {
        guard let zone = currentZone() else { return "Select" }
        switch zone.id {
        case 1: return "Recovery"
        case 2: return "Aerobic"
        case 3: return "Tempo"
        case 4: return "Threshold"
        case 5: return "Intervals"
        default: return zone.name
        }
    }
}

private struct SettingChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct ZonePickerView: View {
    @EnvironmentObject private var model: AppViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Zones") {
                    ForEach(HRZone.defaultZones) { zone in
                        Button {
                            model.updateZoneSelection(zone)
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(zone.name)
                                    Text(description(for: zone))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if zone.id == model.userSettings.selectedZoneId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Zone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }

    private func description(for zone: HRZone) -> String {
        switch zone.id {
        case 1: return "50–60%: recovery"
        case 2: return "60–70%: build endurance"
        case 3: return "70–80%: tempo"
        case 4: return "80–90%: threshold"
        case 5: return "90–100%: sprints"
        default: return ""
        }
    }
}

struct PlaylistPickerView: View {
    @EnvironmentObject private var model: AppViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Suggested") {
                    Button("Auto-DJ per zone") {
                        model.selectPlaylist(nil)
                        isPresented = false
                    }
                }

                Section("Playlists") {
                    ForEach(model.playlists) { playlist in
                        Button {
                            model.selectPlaylist(playlist)
                            isPresented = false
                        } label: {
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                if playlist.id == model.userSettings.preferredPlaylistId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .task {
            await model.loadPlaylists()
        }
    }
}
