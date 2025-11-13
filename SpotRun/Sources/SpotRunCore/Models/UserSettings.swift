import Foundation

public struct UserSettings: Codable, Equatable {
    public var maxHeartRate: Int
    public var selectedZoneId: Int
    public var minimumPaceEnabled: Bool
    public var minimumPaceKmh: Double
    public var treadmillModeEnabled: Bool
    public var autoDJEnabled: Bool
    public var preferredPlaylistId: String?

    public init(
        maxHeartRate: Int,
        selectedZoneId: Int,
        minimumPaceEnabled: Bool,
        minimumPaceKmh: Double,
        treadmillModeEnabled: Bool,
        autoDJEnabled: Bool,
        preferredPlaylistId: String? = nil
    ) {
        self.maxHeartRate = maxHeartRate
        self.selectedZoneId = selectedZoneId
        self.minimumPaceEnabled = minimumPaceEnabled
        self.minimumPaceKmh = minimumPaceKmh
        self.treadmillModeEnabled = treadmillModeEnabled
        self.autoDJEnabled = autoDJEnabled
        self.preferredPlaylistId = preferredPlaylistId
    }
}

public extension UserSettings {
    static func `default`(age: Int) -> UserSettings {
        let estimatedMax = max(150, 220 - age)
        return UserSettings(
            maxHeartRate: estimatedMax,
            selectedZoneId: 2,
            minimumPaceEnabled: true,
            minimumPaceKmh: 2.5,
            treadmillModeEnabled: false,
            autoDJEnabled: true,
            preferredPlaylistId: nil
        )
    }
}
