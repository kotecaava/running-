import Foundation

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
        healthService: HealthService = PreviewHealthService(),
        motionService: MotionService = PreviewMotionService(),
        spotifyService: SpotifyService = PreviewSpotifyService(),
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

        self.healthStatus = healthService.authorizationStatus
        self.spotifyStatus = spotifyService.authorizationStatus
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
            analytics: analytics,
            configuration: .init(
                minimumPaceKmh: userSettings.minimumPaceKmh,
                minimumStepsPerMinute: 60,
                paceWindowSeconds: 5,
                requireMinPace: userSettings.minimumPaceEnabled
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
            let reportedSummary = summary ?? await coordinator?.stopSession()
            await MainActor.run {
                self.coordinator = nil
                let defaultSummary = WorkoutSummary(
                    duration: 0,
                    averageHeartRate: nil,
                    maxHeartRate: nil,
                    distance: nil,
                    steps: nil,
                    timeInZoneSeconds: 0
                )
                self.route = .summary(reportedSummary ?? defaultSummary)
            }
        }
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
        mode = enabled ? .treadmill : .outdoor
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

    nonisolated func sessionCoordinator(_ coordinator: SessionCoordinator, didChangePlaybackState playbackState: PlaybackState) {
        Task { @MainActor in
            self.liveMetrics.playbackState = playbackState
        }
    }

    nonisolated func sessionCoordinatorDidRequireSpotifyConnection(_ coordinator: SessionCoordinator) {
        Task { @MainActor in
            self.spotifyStatus = .notConnected
        }
    }
}
