import SwiftUI
import WatchKit

struct NowPlayingView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 6) {
                // Album art
                AlbumArtView(imageData: connectivity.albumArtData)
                    .frame(
                        width: min(geometry.size.width - 16, 100),
                        height: min(geometry.size.width - 16, 100)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Track info
                VStack(spacing: 2) {
                    Text(connectivity.trackTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    if let artist = connectivity.trackArtist {
                        Text(artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)

                // Remote progress bar
                if connectivity.remoteDuration > 0 {
                    ProgressView(
                        value: min(connectivity.remotePosition, connectivity.remoteDuration),
                        total: connectivity.remoteDuration
                    )
                    .tint(.white.opacity(0.6))
                    .scaleEffect(y: 0.5)
                    .padding(.horizontal, 8)
                }

                // Playback controls
                PlaybackControlsView()
                    .padding(.top, 2)

                // Volume + Play on Watch
                HStack(spacing: 16) {
                    // Volume down
                    Button(action: {
                        WKInterfaceDevice.current().play(.directionDown)
                        connectivity.sendCommand(.volumeDown)
                    }) {
                        Image(systemName: "speaker.minus.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Volume up
                    Button(action: {
                        WKInterfaceDevice.current().play(.directionUp)
                        connectivity.sendCommand(.volumeUp)
                    }) {
                        Image(systemName: "speaker.plus.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Play on Watch
                    if PlexWatchClient.shared.hasCredentials {
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            connectivity.requestPlayPhoneQueue()
                        }) {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 8)
    }
}

struct AlbumArtView: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct PlaybackControlsView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        HStack(spacing: 20) {
            // Previous
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                connectivity.sendCommand(.previous)
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .disabled(!connectivity.canGoPrevious)
            .opacity(connectivity.canGoPrevious ? 1.0 : 0.4)

            // Play/Pause
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                connectivity.sendCommand(connectivity.isPlaying ? .pause : .play)
            }) {
                Image(systemName: connectivity.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
            }
            .buttonStyle(.plain)

            // Next
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                connectivity.sendCommand(.next)
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .disabled(!connectivity.canGoNext)
            .opacity(connectivity.canGoNext ? 1.0 : 0.4)
        }
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(WatchConnectivityManager.shared)
}
