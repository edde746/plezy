import SwiftUI
import WidgetKit

@main
struct PlezyWatchApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared

    init() {
        // Initialize remote logger immediately on app launch
        rlog("[App] PlezyWatch launched — remote logger connected")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivity)
        }
    }
}
