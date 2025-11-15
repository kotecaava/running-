import SwiftUI
import SpotRunCore

struct SpotifyConnectStepView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var minPaceEnabled: Bool = true
    @State private var minPace: Double = 2.5
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Connect Spotify")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 32)

            VStack(spacing: 16) {
                Button(action: connectSpotify) {
                    HStack {
                        Image(systemName: "music.note")
                        Text(model.spotifyStatus == .connected ? "Connected" : "Connect Spotify")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if model.spotifyStatus == .connected {
                    Text("Choose a playlist now or stick with Auto-DJ recommendations per zone.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Spotify app required. Tap to authorize.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)

            Toggle(isOn: $minPaceEnabled) {
                VStack(alignment: .leading) {
                    Text("Require min pace")
                        .font(.headline)
                    Text("Default 2.5 km/h • Keeps music honest")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .padding(.horizontal, 24)

            if minPaceEnabled {
                VStack(alignment: .leading) {
                    Text("Minimum pace")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Slider(value: $minPace, in: 1...6, step: 0.1)
                    Text(String(format: "%.1f km/h", minPace))
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: {
                model.updatePaceRequirement(isEnabled: minPaceEnabled, pace: minPace)
                onFinish()
            }) {
                Text("Finish")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(model.spotifyStatus == .connected ? Color.white : Color.white.opacity(0.3))
                    .foregroundStyle(Color.black.opacity(model.spotifyStatus == .connected ? 1 : 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }
            .disabled(model.spotifyStatus != .connected)

            Spacer(minLength: 24)
        }
        .onAppear {
            minPaceEnabled = model.userSettings.minimumPaceEnabled
            minPace = model.userSettings.minimumPaceKmh
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func connectSpotify() {
        model.markSpotifyConnected()
        Task {
            await model.loadPlaylists()
        }
    }
}
