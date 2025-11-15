import Foundation

struct HRZone: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let lowerPercentage: Double
    let upperPercentage: Double

    func bpmRange(maxHR: Int) -> ClosedRange<Int> {
        let lower = Int(round(Double(maxHR) * lowerPercentage))
        let upper = Int(round(Double(maxHR) * upperPercentage))
        return lower...max(lower, upper)
    }

    static let defaultZones: [HRZone] = [
        HRZone(id: 1, name: "Zone 1", lowerPercentage: 0.50, upperPercentage: 0.60),
        HRZone(id: 2, name: "Zone 2", lowerPercentage: 0.60, upperPercentage: 0.70),
        HRZone(id: 3, name: "Zone 3", lowerPercentage: 0.70, upperPercentage: 0.80),
        HRZone(id: 4, name: "Zone 4", lowerPercentage: 0.80, upperPercentage: 0.90),
        HRZone(id: 5, name: "Zone 5", lowerPercentage: 0.90, upperPercentage: 1.00)
    ]
}

struct UserSettings: Codable, Equatable {
    var maxHeartRate: Int
    var selectedZoneId: Int
    var minimumPaceEnabled: Bool
    var minimumPaceKmh: Double
    var treadmillModeEnabled: Bool
    var autoDJEnabled: Bool
    var preferredPlaylistId: String?

    static func `default`(age: Int) -> UserSettings {
        UserSettings(
            maxHeartRate: max(150, 220 - age),
            selectedZoneId: 2,
            minimumPaceEnabled: true,
            minimumPaceKmh: 2.5,
            treadmillModeEnabled: false,
            autoDJEnabled: true,
            preferredPlaylistId: nil
        )
    }
}

struct LiveMetrics: Equatable {
    var heartRateBpm: Int?
    var paceKmh: Double?
    var stepsPerMinute: Int?
    var zoneState: ZoneState = .unknown
    var playbackState: PlaybackState = .stopped
    var isPaceRequirementMet: Bool = true
}

enum ZoneState: Equatable {
    case inZone
    case outOfZone
    case unknown
}

enum PlaybackState: Equatable {
    case playing
    case paused
    case fadingIn
    case fadingOut
    case stopped
}

enum WorkoutMode {
    case outdoor
    case treadmill
}

struct WorkoutSummary: Equatable {
    var duration: TimeInterval
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var distance: Double?
    var steps: Int?
    var timeInZoneSeconds: TimeInterval
}

struct HeartRateSample {
    let bpm: Int
    let date: Date
}

struct PaceSample {
    let speedMetersPerSecond: Double
    let date: Date
}

struct StepsSample {
    let stepsPerMinute: Int
    let date: Date
}

enum MotionActivity {
    case running
    case walking
    case stationary
}

enum SpotifyAuthorizationStatus {
    case notConnected
    case connecting
    case connected
    case failed(Error)
}

enum HealthAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}

struct Playlist: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let artworkURL: URL?
}

struct Track: Identifiable, Equatable {
    let id: String
    let name: String
    let artist: String
    let artworkURL: URL?
    let duration: TimeInterval
}

enum SpotifyPlaybackState {
    case playing
    case paused
    case stopped
}

struct SpotifyPlayback {
    var state: SpotifyPlaybackState
    var track: Track?
}

struct AutoDJSettings {
    var targetEnergy: ClosedRange<Double>
    var targetTempo: ClosedRange<Double>

    static func settings(for zone: HRZone) -> AutoDJSettings {
        switch zone.id {
        case 1:
            return AutoDJSettings(targetEnergy: 0.15...0.35, targetTempo: 90...110)
        case 2:
            return AutoDJSettings(targetEnergy: 0.30...0.50, targetTempo: 100...120)
        case 3:
            return AutoDJSettings(targetEnergy: 0.45...0.70, targetTempo: 120...140)
        case 4:
            return AutoDJSettings(targetEnergy: 0.65...0.85, targetTempo: 140...165)
        case 5:
            return AutoDJSettings(targetEnergy: 0.80...1.00, targetTempo: 160...190)
        default:
            return AutoDJSettings(targetEnergy: 0.30...0.60, targetTempo: 100...140)
        }
    }
}

struct UserProfile {
    var dateOfBirth: Date?
    var biologicalSex: String?
}

enum AnalyticsEvent {
    case onboardingCompleted
    case permissionsGranted(kind: String)
    case spotifyConnected
    case sessionStarted(zoneId: Int, paceRequired: Bool, playlistType: String)
    case stateChange(from: PlaybackState, to: PlaybackState, reason: String)
    case timeInZone(seconds: TimeInterval)
    case sessionEnded(duration: TimeInterval, avgHR: Int?, maxHR: Int?)
    case streakIncremented
    case error(message: String)
}
