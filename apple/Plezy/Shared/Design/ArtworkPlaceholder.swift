import SwiftUI
import PlezyKit

/// What stands in for missing artwork, filling its frame: the raised surface with the kind's symbol in the middle, a
/// third of the frame's shorter side; a circle for a person or an artist, the frame's own shape otherwise. No kind's
/// symbol is a control's (an episode's is a TV, not a play symbol), so a placeholder never reads as a button.
struct ArtworkPlaceholder: View {
    let kind: PlaceholderKind

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height) / 3
            Image(systemName: kind.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Palette.surfaceContainerHighest)
        .clipShape(kind.circular ? AnyShape(Circle()) : AnyShape(Rectangle()))
        .accessibilityHidden(true)
    }
}

extension PlaceholderKind {
    /// The SF Symbol the placeholder shows.
    var systemImage: String {
        switch self {
        case .movie: "film"
        case .show, .episode: "tv"
        case .album: "opticaldisc"
        case .track: "music.note"
        case .artist: "music.microphone"
        case .person: "person.fill"
        case .playlist: "music.note.list"
        case .collection: "rectangle.stack.fill"
        case .channel: "antenna.radiowaves.left.and.right"
        }
    }
}
