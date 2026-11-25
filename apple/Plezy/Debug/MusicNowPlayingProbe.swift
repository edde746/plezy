import SwiftUI

/// Debug builds: what the music session's Now Playing last published (`NowPlayingCenter.published` of the music
/// center, `AppleAppPlatform.musicNowPlaying`), empty while no music shows.
@MainActor
@Observable
final class MusicNowPlayingLog {
    static let shared = MusicNowPlayingLog()

    var published = ""
}

/// Debug builds: the music session's Now Playing (`MusicNowPlayingLog`: `title=…; state=…; …; next=…; previous=…;
/// skip=…`, `none` while no music shows) as the label of an element the UI tests read (`music.nowPlaying`), since
/// XCUITest can't read `MPNowPlayingInfoCenter`.
struct MusicNowPlayingProbe: View {
    var body: some View {
        let published = MusicNowPlayingLog.shared.published
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: published.isEmpty ? "none" : published))
            .accessibilityIdentifier("music.nowPlaying")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}
