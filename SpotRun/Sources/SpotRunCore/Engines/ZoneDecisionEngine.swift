import Foundation

public protocol ZoneDecisionEngineDelegate: AnyObject {
    func zoneDecisionEngine(_ engine: ZoneDecisionEngine, didUpdate state: ZoneState)
}

public final class ZoneDecisionEngine {
    public struct Configuration {
        public let hysteresisBpm: Int
        public let requiredConsecutiveSamples: Int
        public let heartRateGapTimeout: TimeInterval
        public let maxHeartRateGapTimeout: TimeInterval

        public init(
            hysteresisBpm: Int = 2,
            requiredConsecutiveSamples: Int = 3,
            heartRateGapTimeout: TimeInterval = 10,
            maxHeartRateGapTimeout: TimeInterval = 20
        ) {
            self.hysteresisBpm = hysteresisBpm
            self.requiredConsecutiveSamples = requiredConsecutiveSamples
            self.heartRateGapTimeout = heartRateGapTimeout
            self.maxHeartRateGapTimeout = maxHeartRateGapTimeout
        }
    }

    private let zoneRange: ClosedRange<Int>
    private let configuration: Configuration
    private var samples: [HeartRateSample] = []
    private(set) public var state: ZoneState = .unknown {
        didSet {
            guard oldValue != state else { return }
            delegate?.zoneDecisionEngine(self, didUpdate: state)
        }
    }

    public weak var delegate: ZoneDecisionEngineDelegate?

    public init(zoneRange: ClosedRange<Int>, configuration: Configuration = Configuration()) {
        self.zoneRange = zoneRange
        self.configuration = configuration
    }

    public func add(sample: HeartRateSample) {
        samples.append(sample)
        samples = samples.suffix(configuration.requiredConsecutiveSamples)

        if samples.count < configuration.requiredConsecutiveSamples {
            return
        }

        let allInZone = samples.allSatisfy { sample in
            let lower = zoneRange.lowerBound - configuration.hysteresisBpm
            let upper = zoneRange.upperBound + configuration.hysteresisBpm
            return sample.bpm >= lower && sample.bpm <= upper
        }

        if allInZone {
            state = .inZone
        } else if samples.allSatisfy({ $0.bpm < zoneRange.lowerBound - configuration.hysteresisBpm || $0.bpm > zoneRange.upperBound + configuration.hysteresisBpm }) {
            state = .outOfZone
        }
    }

    public func handleSensorPause(lastSampleDate: Date, now: Date = Date()) {
        let gap = now.timeIntervalSince(lastSampleDate)
        if gap >= configuration.maxHeartRateGapTimeout {
            state = .unknown
        } else if gap >= configuration.heartRateGapTimeout {
            state = .outOfZone
        }
    }
}
