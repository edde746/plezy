import SwiftUI

/// The app's operational mode
enum AppMode {
    case idle
    case remoteControl
    case localPlaying
    case localBrowsing
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
            case .remoteControl:
                NowPlayingView()
            case .idle:
                IdleView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
