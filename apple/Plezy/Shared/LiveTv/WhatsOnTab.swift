import SwiftUI
import PlezyKit

/// The What's On tab (`WhatsOnUiState`): a spinner before the first rows, the empty text, else the servers' rows of
/// airings under their titles (the live TV symbol), each a poster card (an episode as its series' poster) with its title
/// and caption, sized as the grid's (the TV rail's on a TV). A card tunes an airing on now, opens a show's schedule or
/// the details (`WhatsOnStore.tap`); a long press opens the details.
///
/// Accessibility identifiers: `livetv.whatsOn`, `livetv.whatsOn.loading`, `livetv.whatsOn.empty`,
/// `livetv.whatsOn.card.<row>.<index>`.
struct WhatsOnTab: View {
    let app: AppModel
    let state: WhatsOnUiState
    let store: WhatsOnStore
    var focus: FocusState<LiveTvField?>.Binding

    @Environment(\.dimens) private var dimens

    var body: some View {
        if state.loading {
            LoadingStateView().accessibilityIdentifier("livetv.whatsOn.loading")
        } else if let empty = state.emptyText {
            Text(empty)
                .font(.body)
                .foregroundStyle(Palette.onBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("livetv.whatsOn.empty")
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: dimens.sectionSpacing) {
                    ForEach(Array(state.hubs.enumerated()), id: \.element.id) { row, hub in
                        ShelfRow(title: hub.title, items: Array(hub.items.enumerated()), id: \.offset) { index, item in
                            WhatsOnCard(
                                app: app, item: item, width: dimens.posterWidth, focus: focus, first: row == 0 && index == 0,
                                id: "livetv.whatsOn.card.\(row).\(index)"
                            ) {
                                store.tap(hubId: hub.id, index: Int32(index))
                            } onLongPress: {
                                store.longPress(hubId: hub.id, index: Int32(index))
                            }
                        }
                    }
                }
                .padding(.vertical, dimens.sectionSpacing)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("livetv.whatsOn")
        }
    }
}

/// An airing's card: its poster (an episode's series poster), its title (the show's for an episode) and caption (the
/// episode's title, else the year). On Apple TV the poster alone is the button, in the card style that lifts the poster
/// (its placeholder with it) with focus, the lines under it; elsewhere the whole card, dimmed while pressed with the
/// keyboard's ring. A long press (Select held) runs `onLongPress`.
private struct WhatsOnCard: View {
    let app: AppModel
    let item: MediaItem
    let width: CGFloat
    /// The tab's focus; the first card of the first row is its `content` stop.
    var focus: FocusState<LiveTvField?>.Binding
    let first: Bool
    let id: String
    let action: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        let episode = item.isEpisode && item.grandparentTitle != nil
        let title = episode ? (item.grandparentTitle ?? "") : item.displayTitle
        let caption = episode ? item.title : item.year.map { String($0.int32Value) }
        let poster = app.liveTvArtwork(serverId: item.serverId, path: item.grandparentThumbPath ?? item.thumbPath, kind: .poster)
        let artwork = RemoteImage(artwork: poster) { failed in
            if failed { ArtworkPlaceholder(kind: episode ? .show : .movie) }
        }
        .background(Palette.surfaceContainerHighest)
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        #if os(tvOS)
        VStack(alignment: .leading, spacing: PosterCard.captionGap) {
            Button(action: action) { artwork }
                .cardButtonStyle()
                .onLongPressGesture(minimumDuration: 0.5, perform: onLongPress)
                .accessibilityLabel(title)
                .accessibilityValue(caption ?? "")
                .accessibilityIdentifier(id)
                .focused(focus, as: .content, when: first)
            lines(title, caption).accessibilityHidden(true)
        }
        .frame(width: width, alignment: .leading)
        #else
        Button(action: action) {
            VStack(alignment: .leading, spacing: PosterCard.captionGap) {
                artwork
                lines(title, caption)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(PressDimButtonStyle())
        .focusRing(radius: Radius.medium)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onLongPress() })
        .accessibilityLabel(title)
        .accessibilityValue(caption ?? "")
        .accessibilityIdentifier(id)
        .focused(focus, as: .content, when: first)
        #endif
    }

    private func lines(_ title: String, _ caption: String?) -> some View {
        VStack(alignment: .leading, spacing: PosterCard.captionGap) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.onBackground)
                .lineLimit(1)
            Text(caption ?? " ")
                .font(.caption)
                .foregroundStyle(Palette.onSurfaceVariant)
                .lineLimit(1)
        }
    }
}
