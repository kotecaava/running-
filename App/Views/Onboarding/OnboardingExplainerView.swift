import SwiftUI

struct OnboardingExplainerView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Pick a heart-rate zone. When you’re in it, your music plays. Drop below — it fades. Train smarter with rhythm.")
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Image(systemName: "waveform.path.ecg")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .foregroundStyle(.pink)
                .shadow(radius: 20)
            Spacer()
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }
            Button("How it works") {
                // Present sheet in future iterations
            }
            .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}
