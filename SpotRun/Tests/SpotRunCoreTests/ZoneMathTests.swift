import XCTest
@testable import SpotRunCore

final class ZoneMathTests: XCTestCase {
    func testDefaultZonesCoverExpectedRanges() {
        let zones = HRZone.defaultZones
        XCTAssertEqual(zones.count, 5)
        XCTAssertEqual(zones.first?.bpmRange(maxHR: 200), 100...120)
        XCTAssertEqual(zones.last?.bpmRange(maxHR: 200), 180...200)
    }

    func testZoneDecisionEngineHysteresis() {
        let range = 140...160
        let engine = ZoneDecisionEngine(zoneRange: range)
        var states: [ZoneState] = []
        let delegate = TestDelegate { state in
            states.append(state)
        }
        engine.delegate = delegate

        let samples = [
            HeartRateSample(bpm: 139, date: .init()),
            HeartRateSample(bpm: 141, date: .init()),
            HeartRateSample(bpm: 142, date: .init()),
            HeartRateSample(bpm: 143, date: .init())
        ]
        samples.forEach { engine.add(sample: $0) }

        XCTAssertTrue(states.contains(.inZone))

        let outSamples = [
            HeartRateSample(bpm: 170, date: .init()),
            HeartRateSample(bpm: 171, date: .init()),
            HeartRateSample(bpm: 172, date: .init())
        ]
        outSamples.forEach { engine.add(sample: $0) }

        XCTAssertEqual(states.last, .outOfZone)
        withExtendedLifetime(delegate) {}
    }

    func testSessionCoordinatorPaceGate() throws {
        let health = MockHealthService()
        let motion = MockMotionService()
        let spotify = MockSpotifyService()
        let audioEngine = AudioPolicyEngine()
        let storage = InMemoryStorageService()
        let analytics = MockAnalyticsService()
        try storage.save(settings: UserSettings(
            maxHeartRate: 190,
            selectedZoneId: 2,
            minimumPaceEnabled: true,
            minimumPaceKmh: 2.5,
            treadmillModeEnabled: false,
            autoDJEnabled: false,
            preferredPlaylistId: nil
        ))

        let coordinator = SessionCoordinator(
            healthService: health,
            motionService: motion,
            spotifyService: spotify,
            audioEngine: audioEngine,
            storage: storage,
            analytics: analytics,
            configuration: .init(),
            zoneRange: 114...133
        )

        for _ in 0..<3 {
            coordinator.handleHeartRate(HeartRateSample(bpm: 120, date: .init()))
        }
        coordinator.handlePace(PaceSample(speedMetersPerSecond: 1.0, date: .init()))

        XCTAssertTrue(analytics.recordedEvents.contains { event in
            if case let .stateChange(_, to, _) = event {
                return to == .playing
            }
            return false
        })
    }
}

private final class TestDelegate: ZoneDecisionEngineDelegate {
    private let handler: (ZoneState) -> Void

    init(handler: @escaping (ZoneState) -> Void) {
        self.handler = handler
    }

    func zoneDecisionEngine(_ engine: ZoneDecisionEngine, didUpdate state: ZoneState) {
        handler(state)
    }
}

private final class MockHealthService: HealthService {
    var authorizationStatus: HealthAuthorizationStatus = .authorized

    func requestAuthorization() async throws {}
    func observeHeartRate(_ handler: @escaping (HeartRateSample) -> Void) {}
    func stopObservingHeartRate() {}
    func currentVO2Max() async throws -> Double? { nil }
    func userProfile() async throws -> UserProfile { UserProfile(dateOfBirth: nil, biologicalSex: nil) }
    func startWorkoutSession(mode: WorkoutMode) async throws {}
    func endWorkoutSession() async throws -> WorkoutSummary {
        WorkoutSummary(duration: 0, averageHeartRate: nil, maxHeartRate: nil, distance: nil, steps: nil, timeInZoneSeconds: 0)
    }
}

private final class MockMotionService: MotionService {
    func observePace(_ handler: @escaping (PaceSample) -> Void) {}
    func stopObservingPace() {}
    func observeSteps(_ handler: @escaping (StepsSample) -> Void) {}
    func stopObservingSteps() {}
    func currentActivity() async throws -> MotionActivity { .unknown }
}

private final class MockSpotifyService: SpotifyService {
    var authorizationStatus: SpotifyAuthorizationStatus = .notConnected

    func connect() async throws {}
    func disconnect() {}
    func resume() async throws {}
    func pause() async throws {}
    func skipToNext() async throws {}
    func currentPlaybackState() async throws -> SpotifyPlayback { SpotifyPlayback(state: .stopped, track: nil) }
    func prepareAutoDJPlaylist(for zone: HRZone, settings: AutoDJSettings) async throws -> Playlist {
        Playlist(id: "auto", name: "Auto DJ", description: nil, artworkURL: nil)
    }
    func availablePlaylists() async throws -> [Playlist] { [] }
}

private final class MockAnalyticsService: AnalyticsService {
    private(set) var recordedEvents: [AnalyticsEvent] = []

    func track(event: AnalyticsEvent) {
        recordedEvents.append(event)
    }
}
