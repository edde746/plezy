import Accessibility
import SwiftUI

/// Speaks `text` with VoiceOver without moving its focus: a message that shows where the user isn't (a toast, the
/// player's message). Debug builds also keep it for the UI tests (`AnnouncementLog`).
@MainActor
func announce(_ text: String) {
    AccessibilityNotification.Announcement(text).post()
    #if DEBUG
    AnnouncementLog.shared.texts.append(text)
    #endif
}

extension View {
    /// Announces `text` (`announce`) as the view shows it and each time it changes to another; nil says nothing.
    func announcing(_ text: String?) -> some View {
        onChange(of: text, initial: true) { _, text in
            if let text { announce(text) }
        }
    }

    /// Debug builds: the UI tests' probes of what was announced (`AnnouncementProbe`), of the music session's Now
    /// Playing (`MusicNowPlayingProbe`) and of artwork resizing (`ArtworkResizeProbe`, when asked for) over this view.
    /// The window's root has them, and so does each presentation that covers it (a cover takes the screens under it out
    /// of XCUITest's reach); on the Mac also the probes of the players' video teardown (`VideoTeardownProbe`) and of
    /// the music player's gapless proof (`MusicGaplessProbe`).
    /// Release builds: the view as it is.
    func announcementProbe() -> some View {
        #if DEBUG && os(macOS)
        overlay {
            AnnouncementProbe()
            MusicNowPlayingProbe()
            ArtworkResizeProbe()
            VideoTeardownProbe()
            MusicGaplessProbe()
        }
        #elseif DEBUG
        overlay {
            AnnouncementProbe()
            MusicNowPlayingProbe()
            ArtworkResizeProbe()
        }
        #else
        self
        #endif
    }
}
