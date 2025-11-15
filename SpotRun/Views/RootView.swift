import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppViewModel

    var body: some View {
        switch model.route {
        case .splash:
            SplashView()
        case .onboarding:
            OnboardingContainer()
        case .home:
            MainTabView()
        case .liveSession:
            LiveSessionView()
        case .summary(let summary):
            SessionSummaryView(summary: summary)
        }
    }
}
