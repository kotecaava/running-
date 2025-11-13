import Foundation
import Combine
import SpotRunCore

@MainActor
final class AppViewModel: ObservableObject {
    enum Route {
        case splash
        case onboarding
        case home
        case liveSession
        case summary(WorkoutSummary)
    }

    @Published var route: Route = .splash
    @Published var userSettings: UserSettings
    @Published var liveMetrics = LiveMetrics()
    @Published var spotifyStatus: SpotifyAuthorizationStatus = .notConnected
    @Published var healthStatus: HealthAuthorizationStatus = .notDetermined
    @Published var mode: WorkoutMode = .outdoor
    @Published var playlists: [Playlist] = []

    var preferredPlaylistName: String {
        if let id = userSettings.preferredPlaylistId,
           let match = playlists.first(where: { $0.id == id }) {
            return match.name
        }
        return "Auto-DJ"
    }

    private let healthService: HealthService
    private let motionService: MotionService
    private let spotifyService: SpotifyService
    private let storage: StorageService
    private let analytics: AnalyticsService
    private let audioEngine: AudioPolicyEngine
    private var coordinator: SessionCoordinator?

    init(
        healthService: HealthService = MockedHealthService(),
        motionService: MotionService = MockedMotionService(),
        spotifyService: SpotifyService = MockedSpotifyService(),
        storage: StorageService = InMemoryStorageService(),
        analytics: AnalyticsService = ConsoleAnalyticsService()
    ) {
        self.healthService = healthService
        self.motionService = motionService
        self.spotifyService = spotifyService
        self.storage = storage
        self.analytics = analytics
        self.audioEngine = AudioPolicyEngine()

        if let stored = try? storage.loadSettings() {
            self.userSettings = stored
        } else {
            self.userSettings = .default(age: 30)
            try? storage.save(settings: userSettings)
        }

    }

    func advanceFromSplash() {
        if healthStatus == .authorized && spotifyStatus == .connected {
            route = .home
        } else {
            route = .onboarding
        }
    }

    func handleOnboardingCompletion() {
        route = .home
        analytics.track(event: .onboardingCompleted)
    }

    func startSession() {
        guard spotifyStatus == .connected else {
            return
        }

        coordinator = SessionCoordinator(
            healthService: healthService,
            motionService: motionService,
            spotifyService: spotifyService,
            audioEngine: audioEngine,
            storage: storage,
            analytics: analytics,
            configuration: .init(
                minimumPaceKmh: userSettings.minimumPaceKmh,
                minimumStepsPerMinute: 60,
                paceWindowSeconds: 5
            ),
            zoneRange: selectedZoneRange()
        )
        coordinator?.delegate = self
        route = .liveSession
        Task {
            await coordinator?.startSession(mode: mode)
        }
    }

    func endSession(summary: WorkoutSummary? = nil) {
        Task {
            await coordinator?.stopSession()
        }
        route = .summary(summary ?? WorkoutSummary(duration: 0, averageHeartRate: nil, maxHeartRate: nil, distance: nil, steps: nil, timeInZoneSeconds: 0))
    }

    func updateZoneSelection(_ zone: HRZone) {
        userSettings.selectedZoneId = zone.id
        try? storage.save(settings: userSettings)
    }

    func updateMaxHeartRate(_ value: Int) {
        userSettings.maxHeartRate = value
        try? storage.save(settings: userSettings)
    }

    func updatePaceRequirement(isEnabled: Bool, pace: Double) {
        userSettings.minimumPaceEnabled = isEnabled
        userSettings.minimumPaceKmh = pace
        try? storage.save(settings: userSettings)
    }

    func markSpotifyConnected() {
        spotifyStatus = .connected
        analytics.track(event: .spotifyConnected)
    }

    func loadPlaylists() async {
        guard spotifyStatus == .connected else { return }
        do {
            let list = try await spotifyService.availablePlaylists()
            await MainActor.run {
                self.playlists = list
            }
        } catch {
            analytics.track(event: .error(message: "Failed to load playlists: \(error.localizedDescription)"))
        }
    }

    func selectPlaylist(_ playlist: Playlist?) {
        userSettings.preferredPlaylistId = playlist?.id
        try? storage.save(settings: userSettings)
    }

    func setAutoDJ(enabled: Bool) {
        userSettings.autoDJEnabled = enabled
        try? storage.save(settings: userSettings)
    }

    func setTreadmillMode(_ enabled: Bool) {
        userSettings.treadmillModeEnabled = enabled
        try? storage.save(settings: userSettings)
    }

    private func selectedZoneRange() -> ClosedRange<Int> {
        guard let zone = HRZone.defaultZones.first(where: { $0.id == userSettings.selectedZoneId }) else {
            return 100...120
        }
        return zone.bpmRange(maxHR: userSettings.maxHeartRate)
    }
}

extension AppViewModel: SessionCoordinatorDelegate {
    nonisolated func sessionCoordinator(_ coordinator: SessionCoordinator, didUpdate metrics: LiveMetrics) {
        Task { @MainActor in
            self.liveMetrics = metrics
        }
    }

    nonisolated func sessionCoordinator(_ coordinator: SessionCoordinator, didChangePlaybackState playbackState: PlaybackState) {}

    nonisolated func sessionCoordinatorDidRequireSpotifyConnection(_ coordinator: SessionCoordinator) {}
}

private final class MockedHealthService: HealthService {
    var authorizationStatus: HealthAuthorizationStatus = .authorized
    private var handler: ((HeartRateSample) -> Void)?

    func requestAuthorization() async throws {}

    func observeHeartRate(_ handler: @escaping (HeartRateSample) -> Void) {
        self.handler = handler
        Task {
            for bpm in stride(from: 110, through: 140, by: 5) {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                handler(HeartRateSample(bpm: bpm, date: Date()))
            }
        }
    }

    func stopObservingHeartRate() {
        handler = nil
    }

    func currentVO2Max() async throws -> Double? { nil }
    func userProfile() async throws -> UserProfile { UserProfile(dateOfBirth: nil, biologicalSex: nil) }
    func startWorkoutSession(mode: WorkoutMode) async throws {}
    func endWorkoutSession() async throws -> WorkoutSummary { WorkoutSummary(duration: 0, averageHeartRate: 125, maxHeartRate: 150, distance: 3.2, steps: 4000, timeInZoneSeconds: 1200) }
}

private final class MockedMotionService: MotionService {
    func observePace(_ handler: @escaping (PaceSample) -> Void) {
        Task {
            while true {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                handler(PaceSample(speedMetersPerSecond: 1.2, date: Date()))
            }
        }
    }

    func stopObservingPace() {}

    func observeSteps(_ handler: @escaping (StepsSample) -> Void) {
        Task {
            while true {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                handler(StepsSample(stepsPerMinute: 80, date: Date()))
            }
        }
    }

    func stopObservingSteps() {}
    func currentActivity() async throws -> MotionActivity { .running }
}

private final class MockedSpotifyService: SpotifyService {
    var authorizationStatus: SpotifyAuthorizationStatus = .connected

    func connect() async throws {}
    func disconnect() {}
    func resume() async throws {}
    func pause() async throws {}
    func skipToNext() async throws {}
    func currentPlaybackState() async throws -> SpotifyPlayback {
        SpotifyPlayback(state: .playing, track: Track(id: "demo", name: "Demo", artist: "SpotRun", artworkURL: nil, duration: 200))
    }

    func prepareAutoDJPlaylist(for zone: HRZone, settings: AutoDJSettings) async throws -> Playlist {
        Playlist(id: "auto-\(zone.id)", name: "Auto DJ Zone \(zone.id)", description: nil, artworkURL: nil)
    }

    func availablePlaylists() async throws -> [Playlist] {
        [Playlist(id: "fav", name: "Favorite", description: "Your go-to mix", artworkURL: nil)]
    }
}
