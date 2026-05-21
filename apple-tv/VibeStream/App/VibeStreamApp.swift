import SwiftUI

@main
struct VibeStreamApp: App {
    @State private var appState = AppState()
    @State private var focusModel = MediaFocusModel()
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)
                    .environment(focusModel)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                        Task { await ImageLoader.shared.clearCache() }
                    }

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "vibestream",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let ratingKey = components.queryItems?.first(where: { $0.name == "ratingKey" })?.value
        else { return }

        switch url.host {
        case "detail":
            appState.deepLinkAction = .detail(ratingKey: ratingKey)
        default:
            appState.deepLinkAction = .play(ratingKey: ratingKey)
        }
    }
}
