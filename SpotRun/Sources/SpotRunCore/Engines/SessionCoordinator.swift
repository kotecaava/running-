import Foundation

public protocol SessionCoordinatorDelegate: AnyObject {
    func sessionCoordinator(_ coordinator: SessionCoordinator, didUpdate metrics: LiveMetrics)
    func sessionCoordinator(_ coordinator: SessionCoordinator, didChangePlaybackState playbackState: PlaybackState)
    func sessionCoordinatorDidRequireSpotifyConnection(_ coordinator: SessionCoordinator)
}

public final class SessionCoordinator {
    public struct Configuration {
        public let minimumPaceKmh: Double
        public let minimumStepsPerMinute: Int
        public let paceWindowSeconds: TimeInterval

        public init(minimumPaceKmh: Double = 2.5, minimumStepsPerMinute: Int = 60, paceWindowSeconds: TimeInterval = 5) {
            self.minimumPaceKmh = minimumPaceKmh
            self.minimumStepsPerMinute = minimumStepsPerMinute
            self.paceWindowSeconds = paceWindowSeconds
        }
    }

    private let healthService: HealthService
    private let motionService: MotionService
    private let spotifyService: SpotifyService
    private let audioEngine: AudioPolicyEngine
    private let storage: StorageService
    private let analytics: AnalyticsService
    private let configuration: Configuration
    private var zoneEngine: ZoneDecisionEngine
    private var metrics = LiveMetrics()
    private var lastHeartRateSample: HeartRateSample?
    private var paceSamples: [PaceSample] = []
    private var stepsSamples: [StepsSample] = []

    public weak var delegate: SessionCoordinatorDelegate?

    public init(
        healthService: HealthService,
        motionService: MotionService,
        spotifyService: SpotifyService,
        audioEngine: AudioPolicyEngine,
        storage: StorageService,
        analytics: AnalyticsService,
        configuration: Configuration,
        zoneRange: ClosedRange<Int>
    ) {
        self.healthService = healthService
        self.motionService = motionService
        self.spotifyService = spotifyService
        self.audioEngine = audioEngine
        self.storage = storage
        self.analytics = analytics
        self.configuration = configuration
        self.zoneEngine = ZoneDecisionEngine(zoneRange: zoneRange)
        self.zoneEngine.delegate = self
    }

    public func startSession(mode: WorkoutMode) async {
        audioEngine.startSession()
        analytics.track(event: .sessionStarted(mode: mode))
        await startObservingSensors()
        do {
            try await healthService.startWorkoutSession(mode: mode)
        } catch {
            analytics.track(event: .error(message: "Failed to start workout: \(error.localizedDescription)"))
        }
    }

    public func stopSession() async {
        motionService.stopObservingPace()
        motionService.stopObservingSteps()
        healthService.stopObservingHeartRate()
        audioEngine.reset()
        do {
            let summary = try await healthService.endWorkoutSession()
            analytics.track(event: .sessionEnded(summary: summary))
        } catch {
            analytics.track(event: .error(message: "Failed to end workout: \(error.localizedDescription)"))
        }
    }

    private func startObservingSensors() async {
        healthService.observeHeartRate { [weak self] sample in
            self?.handleHeartRate(sample)
        }

        motionService.observePace { [weak self] sample in
            self?.handlePace(sample)
        }

        motionService.observeSteps { [weak self] sample in
            self?.handleSteps(sample)
        }
    }

    func handleHeartRate(_ sample: HeartRateSample) {
        lastHeartRateSample = sample
        zoneEngine.add(sample: sample)
        metrics.heartRateBpm = sample.bpm
        metrics.lastSampleDate = sample.date
        notifyMetrics()
    }

    func handlePace(_ sample: PaceSample) {
        paceSamples.append(sample)
        let windowStart = Date().addingTimeInterval(-configuration.paceWindowSeconds)
        paceSamples = paceSamples.filter { $0.date >= windowStart }
        let validSpeeds = paceSamples.compactMap { $0.speedMetersPerSecond }.filter { $0 >= 0.5 }
        let averageSpeed = validSpeeds.isEmpty ? nil : validSpeeds.reduce(0, +) / Double(validSpeeds.count)
        metrics.paceKmh = averageSpeed.map { $0 * 3.6 }
        evaluatePlayback()
        notifyMetrics()
    }

    func handleSteps(_ sample: StepsSample) {
        stepsSamples.append(sample)
        let windowStart = Date().addingTimeInterval(-configuration.paceWindowSeconds)
        stepsSamples = stepsSamples.filter { $0.date >= windowStart }
        let averageSteps = stepsSamples.isEmpty ? nil : Int(Double(stepsSamples.reduce(0) { $0 + $1.stepsPerMinute }) / Double(stepsSamples.count))
        metrics.stepsPerMinute = averageSteps
        evaluatePlayback()
        notifyMetrics()
    }

    private func evaluatePlayback() {
        guard let settings = try? storage.loadSettings(),
              HRZone.defaultZones.first(where: { $0.id == settings.selectedZoneId }) != nil else {
            return
        }

        let isPaceSatisfied: Bool
        if settings.minimumPaceEnabled {
            if settings.treadmillModeEnabled {
                if let steps = metrics.stepsPerMinute {
                    isPaceSatisfied = steps >= configuration.minimumStepsPerMinute
                } else {
                    isPaceSatisfied = false
                }
            } else {
                if let pace = metrics.paceKmh {
                    isPaceSatisfied = pace >= configuration.minimumPaceKmh
                } else {
                    isPaceSatisfied = false
                }
            }
        } else {
            isPaceSatisfied = true
        }

        let previousPlaybackState = metrics.playbackState
        metrics.zoneState = zoneEngine.state

        let reason: String
        switch (zoneEngine.state, isPaceSatisfied) {
        case (.inZone, true):
            audioEngine.requestPlay()
            metrics.playbackState = .playing
            reason = "in_zone"
        case (.unknown, _):
            audioEngine.requestPause(reason: PauseReason(cause: .sensorLost, shouldPausePlayback: false, volumeFloor: 0.2))
            metrics.playbackState = .fadingOut
            reason = "sensor_lost"
        case (.inZone, false):
            audioEngine.requestPause(reason: PauseReason(cause: .paceRequirementFailed, shouldPausePlayback: true))
            metrics.playbackState = .fadingOut
            reason = "pace_failed"
        default:
            audioEngine.requestPause(reason: PauseReason(cause: .outOfZone, shouldPausePlayback: true))
            metrics.playbackState = .fadingOut
            reason = "out_of_zone"
        }

        if previousPlaybackState != metrics.playbackState {
            analytics.track(event: .stateChange(from: previousPlaybackState, to: metrics.playbackState, reason: reason))
        }
    }

    private func notifyMetrics() {
        delegate?.sessionCoordinator(self, didUpdate: metrics)
    }
}

extension SessionCoordinator: ZoneDecisionEngineDelegate {
    public func zoneDecisionEngine(_ engine: ZoneDecisionEngine, didUpdate state: ZoneState) {
        metrics.zoneState = state
        evaluatePlayback()
        notifyMetrics()
    }
}

public protocol AnalyticsService: AnyObject {
    func track(event: AnalyticsEvent)
}

public enum AnalyticsEvent: Equatable {
    case onboardingCompleted
    case permissionsGranted([String])
    case spotifyConnected
    case sessionStarted(mode: WorkoutMode)
    case stateChange(from: PlaybackState, to: PlaybackState, reason: String)
    case timeInZone(seconds: TimeInterval)
    case sessionEnded(summary: WorkoutSummary)
    case streakIncremented
    case error(message: String)
}
