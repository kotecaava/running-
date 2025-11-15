import Foundation

@MainActor
protocol SessionCoordinatorDelegate: AnyObject {
    func sessionCoordinator(_ coordinator: SessionCoordinator, didUpdate metrics: LiveMetrics)
    func sessionCoordinator(_ coordinator: SessionCoordinator, didChangePlaybackState playbackState: PlaybackState)
    func sessionCoordinatorDidRequireSpotifyConnection(_ coordinator: SessionCoordinator)
}

@MainActor
final class SessionCoordinator {
    struct Configuration {
        var minimumPaceKmh: Double
        var minimumStepsPerMinute: Int
        var paceWindowSeconds: TimeInterval
        var requireMinPace: Bool
    }

    private let healthService: HealthService
    private let motionService: MotionService
    private let spotifyService: SpotifyService
    private let audioEngine: AudioPolicyEngine
    private let analytics: AnalyticsService
    private let configuration: Configuration
    private let zoneRange: ClosedRange<Int>

    weak var delegate: SessionCoordinatorDelegate?

    private var liveMetrics = LiveMetrics()
    private var mode: WorkoutMode = .outdoor
    private var consecutiveInZone = 0
    private var consecutiveOutOfZone = 0
    private var lastHeartRateDate: Date?
    private var lastZoneState: ZoneState = .unknown
    private var paceSamples: [PaceSample] = []
    private var watchdogTask: Task<Void, Never>?
    private var isRunning = false

    init(
        healthService: HealthService,
        motionService: MotionService,
        spotifyService: SpotifyService,
        audioEngine: AudioPolicyEngine,
        analytics: AnalyticsService,
        configuration: Configuration,
        zoneRange: ClosedRange<Int>
    ) {
        self.healthService = healthService
        self.motionService = motionService
        self.spotifyService = spotifyService
        self.audioEngine = audioEngine
        self.analytics = analytics
        self.configuration = configuration
        self.zoneRange = zoneRange
    }

    func startSession(mode: WorkoutMode) async {
        guard !isRunning else { return }
        isRunning = true
        self.mode = mode
        audioEngine.onPlaybackChange = { [weak self] state in
            guard let self else { return }
            liveMetrics.playbackState = state
            delegate?.sessionCoordinator(self, didChangePlaybackState: state)
            analytics.track(event: .stateChange(from: self.lastPlaybackState, to: state, reason: "engine"))
            self.lastPlaybackState = state
            self.pushMetricsUpdate()
        }
        audioEngine.startSession()

        do {
            try await spotifyService.resume()
        } catch {
            analytics.track(event: .error(message: "Spotify resume failed: \(error.localizedDescription)"))
            delegate?.sessionCoordinatorDidRequireSpotifyConnection(self)
        }

        do {
            try await healthService.startWorkoutSession(mode: mode)
        } catch {
            analytics.track(event: .error(message: "HK start failed: \(error.localizedDescription)"))
        }

        healthService.observeHeartRate { [weak self] sample in
            guard let self else { return }
            Task { @MainActor in
                self.handleHeartRate(sample)
            }
        }

        motionService.observePace { [weak self] sample in
            guard let self else { return }
            Task { @MainActor in
                self.handlePace(sample)
            }
        }

        motionService.observeSteps { [weak self] sample in
            guard let self else { return }
            Task { @MainActor in
                self.liveMetrics.stepsPerMinute = sample.stepsPerMinute
                self.evaluateSensors()
                self.pushMetricsUpdate()
            }
        }

        startWatchdog()
    }

    func stopSession() async -> WorkoutSummary? {
        guard isRunning else { return nil }
        isRunning = false
        watchdogTask?.cancel()
        watchdogTask = nil
        healthService.stopObservingHeartRate()
        motionService.stopObservingPace()
        motionService.stopObservingSteps()
        audioEngine.stopSession()
        var summary: WorkoutSummary?
        do {
            summary = try await healthService.endWorkoutSession()
        } catch {
            analytics.track(event: .error(message: "HK end failed: \(error.localizedDescription)"))
        }
        do {
            try await spotifyService.pause()
        } catch {
            analytics.track(event: .error(message: "Spotify pause failed: \(error.localizedDescription)"))
        }
        return summary
    }

    private var lastPlaybackState: PlaybackState = .stopped

    private func handleHeartRate(_ sample: HeartRateSample) {
        lastHeartRateDate = sample.date
        liveMetrics.heartRateBpm = sample.bpm
        evaluateZone(with: sample.bpm)
        evaluateSensors()
        pushMetricsUpdate()
    }

    private func handlePace(_ sample: PaceSample) {
        paceSamples.append(sample)
        let cutoff = Date().addingTimeInterval(-configuration.paceWindowSeconds)
        paceSamples = paceSamples.filter { $0.date >= cutoff }
        if !paceSamples.isEmpty {
            let average = paceSamples.map { $0.speedMetersPerSecond }.reduce(0, +) / Double(paceSamples.count)
            liveMetrics.paceKmh = average * 3.6
        }
        evaluateSensors()
        pushMetricsUpdate()
    }

    private func evaluateZone(with bpm: Int) {
        let expanded = (zoneRange.lowerBound - 2)...(zoneRange.upperBound + 2)
        let inRange = expanded.contains(bpm)
        if inRange {
            consecutiveInZone += 1
            consecutiveOutOfZone = 0
        } else {
            consecutiveOutOfZone += 1
            consecutiveInZone = 0
        }

        if inRange && consecutiveInZone >= 3 {
            updateZoneState(.inZone)
        } else if !inRange && consecutiveOutOfZone >= 3 {
            updateZoneState(.outOfZone)
        }
    }

    private func updateZoneState(_ newState: ZoneState) {
        guard newState != lastZoneState else { return }
        lastZoneState = newState
        liveMetrics.zoneState = newState
        evaluateSensors()
    }

    private func evaluateSensors() {
        let paceRequirementMet: Bool
        if configuration.requireMinPace {
            switch mode {
            case .outdoor:
                if let pace = liveMetrics.paceKmh {
                    paceRequirementMet = pace >= configuration.minimumPaceKmh
                } else {
                    paceRequirementMet = false
                }
            case .treadmill:
                if let steps = liveMetrics.stepsPerMinute {
                    paceRequirementMet = steps >= configuration.minimumStepsPerMinute
                } else {
                    paceRequirementMet = false
                }
            }
        } else {
            paceRequirementMet = true
        }
        liveMetrics.isPaceRequirementMet = paceRequirementMet

        let zoneOk = liveMetrics.zoneState == .inZone

        if zoneOk && paceRequirementMet {
            audioEngine.requestPlay()
        } else {
            let reason: PauseReason
            if liveMetrics.zoneState == .unknown {
                reason = PauseReason.sensorSoft
            } else if !paceRequirementMet && configuration.requireMinPace {
                reason = .pace
            } else {
                reason = .zone
            }
            audioEngine.requestPause(reason: reason)
        }
    }

    private func startWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await self.checkSensorTimeout()
            }
        }
    }

    private func checkSensorTimeout() {
        guard isRunning else { return }
        let now = Date()
        if let last = lastHeartRateDate {
            let delta = now.timeIntervalSince(last)
            if delta > 20 {
                updateZoneState(.unknown)
                audioEngine.requestPause(reason: .sensorHard)
            } else if delta > 10 {
                updateZoneState(.unknown)
                audioEngine.requestPause(reason: .sensorSoft)
            }
        }
    }

    private func pushMetricsUpdate() {
        delegate?.sessionCoordinator(self, didUpdate: liveMetrics)
    }
}
