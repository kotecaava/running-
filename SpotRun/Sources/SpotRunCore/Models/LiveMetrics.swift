import Foundation

public struct LiveMetrics: Equatable {
    public var heartRateBpm: Int?
    public var paceKmh: Double?
    public var stepsPerMinute: Int?
    public var zoneState: ZoneState
    public var playbackState: PlaybackState
    public var lastSampleDate: Date?

    public init(
        heartRateBpm: Int? = nil,
        paceKmh: Double? = nil,
        stepsPerMinute: Int? = nil,
        zoneState: ZoneState = .unknown,
        playbackState: PlaybackState = .stopped,
        lastSampleDate: Date? = nil
    ) {
        self.heartRateBpm = heartRateBpm
        self.paceKmh = paceKmh
        self.stepsPerMinute = stepsPerMinute
        self.zoneState = zoneState
        self.playbackState = playbackState
        self.lastSampleDate = lastSampleDate
    }
}

public enum ZoneState: Equatable {
    case inZone
    case outOfZone
    case unknown
}

public enum PlaybackState: Equatable {
    case playing
    case paused
    case fadingIn
    case fadingOut
    case stopped
}
