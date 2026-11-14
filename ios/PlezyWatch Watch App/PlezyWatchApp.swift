import SwiftUI
import WidgetKit

@main
struct PlezyWatchApp: App {
  @StateObject private var watchConnectivity = WatchConnectivityManager.shared

  init() {
    WatchInstrument.log(.lifecycle, "PlezyWatchApp init build=\(BuildInfo.stamp)")
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(watchConnectivity)
        .instrumentScreen("Root") {
          "mode=\(watchConnectivity.appMode)"
        }
        .onAppear {
          WatchInstrument.log(.lifecycle, "WindowGroup appear")
          #if DEBUG
            InstrumentDriver.run(connectivity: watchConnectivity)
          #endif
          if PlexWatchClient.shared.hasCredentials {
            Task {
              await PlexWatchClient.shared.fetchMachineIdentifier()
              await RecentlyPlayedManager.shared.syncFromPlex()
            }
          }
        }
    }
  }
}
