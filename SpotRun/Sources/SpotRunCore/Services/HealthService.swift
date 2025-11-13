import Foundation

public protocol HealthService: AnyObject {
    var authorizationStatus: HealthAuthorizationStatus { get }
    func requestAuthorization() async throws
    func observeHeartRate(_ handler: @escaping (HeartRateSample) -> Void)
    func stopObservingHeartRate()
    func currentVO2Max() async throws -> Double?
    func userProfile() async throws -> UserProfile
    func startWorkoutSession(mode: WorkoutMode) async throws
    func endWorkoutSession() async throws -> WorkoutSummary
}

public enum HealthAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}

public struct HeartRateSample: Equatable {
    public let bpm: Int
    public let date: Date

    public init(bpm: Int, date: Date) {
        self.bpm = bpm
        self.date = date
    }
}

public struct UserProfile: Equatable {
    public let dateOfBirth: DateComponents?
    public let biologicalSex: BiologicalSex?

    public init(dateOfBirth: DateComponents?, biologicalSex: BiologicalSex?) {
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
    }
}

public enum BiologicalSex: Equatable {
    case female
    case male
    case other
    case notSet
}

public enum WorkoutMode: Equatable {
    case outdoor
    case treadmill
}

public struct WorkoutSummary: Equatable {
    public let duration: TimeInterval
    public let averageHeartRate: Int?
    public let maxHeartRate: Int?
    public let distance: Double?
    public let steps: Int?
    public let timeInZoneSeconds: TimeInterval

    public init(
        duration: TimeInterval,
        averageHeartRate: Int?,
        maxHeartRate: Int?,
        distance: Double?,
        steps: Int?,
        timeInZoneSeconds: TimeInterval
    ) {
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.distance = distance
        self.steps = steps
        self.timeInZoneSeconds = timeInZoneSeconds
    }
}
