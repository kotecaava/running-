import Foundation

public final class ConsoleAnalyticsService: AnalyticsService {
    public init() {}

    public func track(event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event)")
        #endif
    }
}
