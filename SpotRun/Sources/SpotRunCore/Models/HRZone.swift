import Foundation

public struct HRZone: Identifiable, Codable, Equatable {
    public let id: Int
    public let name: String
    public let lowerPercentage: Double
    public let upperPercentage: Double

    public init(id: Int, name: String, lowerPercentage: Double, upperPercentage: Double) {
        self.id = id
        self.name = name
        self.lowerPercentage = lowerPercentage
        self.upperPercentage = upperPercentage
    }

    public func bpmRange(maxHR: Int) -> ClosedRange<Int> {
        let lower = Int((Double(maxHR) * lowerPercentage).rounded())
        let upper = Int((Double(maxHR) * upperPercentage).rounded())
        return lower...upper
    }
}

public extension HRZone {
    static let defaultZones: [HRZone] = [
        HRZone(id: 1, name: "Zone 1", lowerPercentage: 0.50, upperPercentage: 0.60),
        HRZone(id: 2, name: "Zone 2", lowerPercentage: 0.60, upperPercentage: 0.70),
        HRZone(id: 3, name: "Zone 3", lowerPercentage: 0.70, upperPercentage: 0.80),
        HRZone(id: 4, name: "Zone 4", lowerPercentage: 0.80, upperPercentage: 0.90),
        HRZone(id: 5, name: "Zone 5", lowerPercentage: 0.90, upperPercentage: 1.00)
    ]
}
