import SwiftUI
import PlezyKit

/// A rating site's logo beside its score, `height` tall in the logo's own aspect (`RatingIcon.aspect`): the rating
/// sites' logos in their own colours, the trackers' marks (`RatingIcon.trakt` and the others) in the foreground style.
///
/// The images are in RatingLogos.xcassets, named by their `id`s (`RatingIcon.id`, `TrackerService.id`, `BackendKind.id`,
/// `seerr`), each an SVG kept as vector data: the brands' own SVGs, the marks as templates (AniList's blue "L" a layer
/// of its own colour, `anilist_accent`), Metacritic's roundel and Letterboxd's three dots from Wikimedia Commons (public
/// domain there, below the threshold of originality). The marks are their owners' trademarks, shown only to say whose
/// score follows or which service a row names.
struct RatingLogo: View {
    let icon: RatingIcon
    let height: CGFloat

    var body: some View {
        RatingMark(name: icon.id)
            .frame(width: height * CGFloat(icon.aspect), height: height)
    }
}

/// `service`'s mark, `size` square, in the foreground style: a rating sheet's row, a Services list's entry.
struct TrackerLogo: View {
    let service: TrackerService
    var size: CGFloat = 20

    var body: some View {
        RatingMark(name: service.id).frame(width: size, height: size)
    }
}

/// Seerr's mark, `size` square, in the foreground style.
struct SeerrLogo: View {
    var size: CGFloat = 20

    var body: some View {
        RatingMark(name: "seerr").frame(width: size, height: size)
    }
}

/// `backend`'s mark (Plex's chevron, Jellyfin's, Emby's), `size` square, in the foreground style.
struct BackendLogo: View {
    let backend: BackendKind
    var size: CGFloat = 16

    var body: some View {
        RatingMark(name: backend.id).frame(width: size, height: size)
    }
}

/// The catalog's image `name`, fitted to its frame; AniList's over its blue "L", TMDB's on its navy plate. Decoration:
/// the view beside it says whose it is.
private struct RatingMark: View {
    let name: String

    private static let tmdbNavy = Color(red: 13 / 255, green: 37 / 255, blue: 63 / 255)

    var body: some View {
        ZStack {
            if name == "anilist" {
                Image("anilist_accent").resizable().aspectRatio(contentMode: .fit)
            }
            Image(name).resizable().aspectRatio(contentMode: .fit)
                .padding(name == "tmdb" ? 2 : 0)
        }
        // TMDB's light teal reads weakly on a light background: on its own navy plate, as TMDB shows it.
        .background {
            if name == "tmdb" { RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Self.tmdbNavy) }
        }
        .accessibilityIgnoresInvertColors()
        .accessibilityHidden(true)
    }
}
