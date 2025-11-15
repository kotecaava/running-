import Foundation

protocol HealthService {
    var authorizationStatus: HealthAuthorizationStatus { get }
    func requestAuthorization() async throws
    func observeHeartRate(_ handler: @escaping (HeartRateSample) -> Void)
    func stopObservingHeartRate()
    func currentVO2Max() async throws -> Double?
    func userProfile() async throws -> UserProfile
    func startWorkoutSession(mode: WorkoutMode) async throws
    func endWorkoutSession() async throws -> WorkoutSummary
}

protocol MotionService {
    func observePace(_ handler: @escaping (PaceSample) -> Void)
    func stopObservingPace()
    func observeSteps(_ handler: @escaping (StepsSample) -> Void)
    func stopObservingSteps()
    func currentActivity() async throws -> MotionActivity
}

protocol SpotifyService {
    var authorizationStatus: SpotifyAuthorizationStatus { get }
    func connect() async throws
    func disconnect()
    func resume() async throws
    func pause() async throws
    func skipToNext() async throws
    func currentPlaybackState() async throws -> SpotifyPlayback
    func prepareAutoDJPlaylist(for zone: HRZone, settings: AutoDJSettings) async throws -> Playlist
    func availablePlaylists() async throws -> [Playlist]
}

protocol StorageService {
    func save(settings: UserSettings) throws
    func loadSettings() throws -> UserSettings
}

protocol AnalyticsService {
    func track(event: AnalyticsEvent)
}

final class InMemoryStorageService: StorageService {
    private var settings: UserSettings?

    func save(settings: UserSettings) throws {
        self.settings = settings
    }

    func loadSettings() throws -> UserSettings {
        if let settings {
            return settings
        } else {
            throw NSError(domain: "SpotRun", code: 404, userInfo: [NSLocalizedDescriptionKey: "No stored settings"])
        }
    }
}

struct ConsoleAnalyticsService: AnalyticsService {
    func track(event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics]", event)
        #endif
    }
}

final class PreviewHealthService: HealthService {
    var authorizationStatus: HealthAuthorizationStatus = .authorized
    private var heartRateTask: Task<Void, Never>?

    func requestAuthorization() async throws {}

    func observeHeartRate(_ handler: @escaping (HeartRateSample) -> Void) {
        heartRateTask?.cancel()
        heartRateTask = Task {
            var bpm = 120
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                bpm += Int.random(in: -3...3)
                handler(HeartRateSample(bpm: max(90, bpm), date: Date()))
            }
        }
    }

    func stopObservingHeartRate() {
        heartRateTask?.cancel()
        heartRateTask = nil
    }

    func currentVO2Max() async throws -> Double? { 42.0 }

    func userProfile() async throws -> UserProfile {
        UserProfile(dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()), biologicalSex: "other")
    }

    func startWorkoutSession(mode: WorkoutMode) async throws {}

    func endWorkoutSession() async throws -> WorkoutSummary {
        WorkoutSummary(
            duration: 45 * 60,
            averageHeartRate: 132,
            maxHeartRate: 168,
            distance: 7.4,
            steps: 8200,
            timeInZoneSeconds: 1800
        )
    }
}

final class PreviewMotionService: MotionService {
    private var paceTask: Task<Void, Never>?
    private var stepsTask: Task<Void, Never>?

    func observePace(_ handler: @escaping (PaceSample) -> Void) {
        paceTask?.cancel()
        paceTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                let speed = Double.random(in: 1.5...3.5)
                handler(PaceSample(speedMetersPerSecond: speed, date: Date()))
            }
        }
    }

    func stopObservingPace() {
        paceTask?.cancel()
        paceTask = nil
    }

    func observeSteps(_ handler: @escaping (StepsSample) -> Void) {
        stepsTask?.cancel()
        stepsTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                handler(StepsSample(stepsPerMinute: Int.random(in: 60...170), date: Date()))
            }
        }
    }

    func stopObservingSteps() {
        stepsTask?.cancel()
        stepsTask = nil
    }

    func currentActivity() async throws -> MotionActivity { .running }
}

final class PreviewSpotifyService: SpotifyService {
    var authorizationStatus: SpotifyAuthorizationStatus = .connected

    func connect() async throws {}

    func disconnect() {}

    func resume() async throws {}

    func pause() async throws {}

    func skipToNext() async throws {}

    func currentPlaybackState() async throws -> SpotifyPlayback {
        SpotifyPlayback(
            state: .playing,
            track: Track(id: "demo", name: "Keep Pace", artist: "SpotRun", artworkURL: nil, duration: 210)
        )
    }

    func prepareAutoDJPlaylist(for zone: HRZone, settings: AutoDJSettings) async throws -> Playlist {
        Playlist(id: "auto-\(zone.id)", name: "Auto DJ Zone \(zone.id)", description: nil, artworkURL: nil)
    }

    func availablePlaylists() async throws -> [Playlist] {
        [
            Playlist(id: "fav", name: "Favorite Highs", description: "Your top energy tracks", artworkURL: nil),
            Playlist(id: "tempo", name: "Tempo Builder", description: "Keep things steady", artworkURL: nil)
        ]
    }
}
