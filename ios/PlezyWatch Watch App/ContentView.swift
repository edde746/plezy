import SwiftUI

// MARK: - App Mode

/// The app's operational mode
enum AppMode: CustomStringConvertible {
  case idle
  case localPlaying
  case localBrowsing

  var description: String {
    switch self {
    case .idle: return "idle"
    case .localPlaying: return "localPlaying"
    case .localBrowsing: return "localBrowsing"
    }
  }
}

struct ContentView: View {
  @EnvironmentObject var connectivity: WatchConnectivityManager
  @ObservedObject private var audioPlayer = WatchAudioPlayer.shared

  var body: some View {
    Group {
      switch connectivity.appMode {
      case .localPlaying:
        LocalPlaybackView()
      case .localBrowsing:
        IdleView()
      case .idle:
        IdleView()
      }
    }
    .instrumentState("appMode", in: "ContentView", value: connectivity.appMode)
    .instrumentState("hasQueue", in: "ContentView", value: audioPlayer.hasQueue)
    .onChange(of: connectivity.appMode) { old, new in
      WatchInstrument.log(.navigation, "route \(String(describing: old)) → \(String(describing: new))")
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(WatchConnectivityManager.shared)
}
