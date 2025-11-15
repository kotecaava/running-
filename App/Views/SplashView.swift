import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var model: AppViewModel
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "figure.run.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.white)
                    .opacity(isActive ? 1 : 0.4)
                    .scaleEffect(isActive ? 1 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)

                Text("SpotRun")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                Text("Pick a heart-rate zone. Music plays only when you’re in it.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            isActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                Task { @MainActor in
                    if model.route == .splash {
                        model.advanceFromSplash()
                    }
                }
            }
        }
    }
}
