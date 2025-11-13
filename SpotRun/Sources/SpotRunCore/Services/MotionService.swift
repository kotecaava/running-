import Foundation

public protocol MotionService: AnyObject {
    func observePace(_ handler: @escaping (PaceSample) -> Void)
    func stopObservingPace()
    func observeSteps(_ handler: @escaping (StepsSample) -> Void)
    func stopObservingSteps()
    func currentActivity() async throws -> MotionActivity
}

public struct PaceSample: Equatable {
    public let speedMetersPerSecond: Double?
    public let date: Date

    public init(speedMetersPerSecond: Double?, date: Date) {
        self.speedMetersPerSecond = speedMetersPerSecond
        self.date = date
    }
}

public struct StepsSample: Equatable {
    public let stepsPerMinute: Int
    public let date: Date

    public init(stepsPerMinute: Int, date: Date) {
        self.stepsPerMinute = stepsPerMinute
        self.date = date
    }
}

public enum MotionActivity: Equatable {
    case stationary
    case walking
    case running
    case unknown
}
