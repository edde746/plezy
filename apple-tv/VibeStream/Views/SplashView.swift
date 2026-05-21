import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.85

    private var splashImageName: String {
        if let raw = UserDefaults.standard.string(forKey: "selectedAppIcon"),
           let variant = AppIconVariant(rawValue: raw) {
            return variant.splashImageName
        }
        return "AppLogo"
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Image(splashImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 500, height: 500)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
                logoScale = 1
            }
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeIn(duration: 0.3)) {
                logoOpacity = 0
            }
            try? await Task.sleep(for: .seconds(0.3))
            isFinished = true
        }
    }
}
