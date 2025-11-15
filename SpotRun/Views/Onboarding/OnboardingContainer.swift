import SwiftUI
import SpotRunCore

struct OnboardingContainer: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var step: Int = 0

    var body: some View {
        TabView(selection: $step) {
            OnboardingExplainerView(onNext: goToNext)
                .tag(0)
            PermissionsStepView(onComplete: goToNext)
                .tag(1)
            MaxHRZoneStepView(onComplete: goToNext)
                .tag(2)
            SpotifyConnectStepView(onFinish: {
                model.spotifyStatus = .connected
                model.handleOnboardingCompletion()
            })
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.black.ignoresSafeArea())
    }

    private func goToNext() {
        withAnimation {
            step = min(step + 1, 3)
        }
    }
}
