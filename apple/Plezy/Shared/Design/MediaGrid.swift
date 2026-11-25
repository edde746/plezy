import SwiftUI
import PlezyKit

/// The app's grid of cards (a library's, a View all's, a collection's, a person's, an artist's, the downloads'): lazy
/// rows of `cells`' fixed columns (`Dimens.grid`), the rows half as far apart again as the columns, the cards'
/// captions `cells.titleGap` under their artwork (`gridCards`).
struct CardGrid<Content: View>: View {
    let cells: GridCells
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(columns: cells.items, alignment: .leading, spacing: cells.spacing * 1.5, content: content)
            .gridCards(cells)
    }
}

/// A library's items as a grid of cards (`CardGrid`); `caption` as each card's (`PosterCard`); `onOpen`, `menu` and
/// `onMenu`, where given, each card's.
struct MediaGrid: View {
    let items: [MediaCardUi]
    let shape: CardShape_
    let cells: GridCells
    var caption = true
    var onOpen: ((MediaCardUi) -> Void)?
    var menu: ((MediaCardUi) -> [ItemMenuEntry])?
    var onMenu: ((MediaCardUi) -> Void)?

    var body: some View {
        CardGrid(cells: cells) {
            ForEach(items, id: \.id) { card in
                PosterCard(
                    card: card, shape: shape, width: cells.cell, caption: caption, onOpen: onOpen.map { open in { open(card) } },
                    menu: menu?(card) ?? [], onMenu: onMenu.map { open in { open(card) } }
                )
            }
        }
        .shelfFocusSection()
    }
}

/// A library's items as a list: each row the artwork, then the title, the caption and the summary (as many lines as
/// the library density gives it, none for a spoiler); `onOpen`, `menu` and `onMenu`, where given, each row's. With
/// `focus`, a row has the screen's focus as its card's id.
struct MediaList: View {
    let items: [MediaCardUi]
    let shape: CardShape_
    let density: Int32
    var onOpen: ((MediaCardUi) -> Void)?
    var menu: ((MediaCardUi) -> [ItemMenuEntry])?
    var onMenu: ((MediaCardUi) -> Void)?
    var focus: FocusState<String?>.Binding?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(items, id: \.id) { card in
                MediaListRow(
                    card: card, shape: shape, density: density, onOpen: onOpen.map { open in { open(card) } },
                    menu: menu?(card) ?? [], onMenu: onMenu.map { open in { open(card) } }
                )
                .cardFocus(focus.map { CardFocus(binding: $0, key: card.id) })
            }
        }
        .shelfFocusSection()
    }
}

/// One item of `MediaList`: the artwork (a poster card's width, scaled by the density as the grid's minimum is), then
/// the title (two lines; one where it links to a detail), the metadata line ("PG-13 • 2006 • 2h 10m • 7.7★ • Studio"),
/// the subtitle (an episode's "S1 E4 · Title" with its season link, an artist) and the summary. A button where it
/// opens: on tvOS the surface row's focus, elsewhere the press dim and the keyboard focus ring.
struct MediaListRow: View {
    let card: MediaCardUi
    let shape: CardShape_
    let density: Int32
    let onOpen: (() -> Void)?
    var menu: [ItemMenuEntry] = []
    var onMenu: (() -> Void)?

    @Environment(\.dimens) private var dimens
    @Environment(\.openRoute) private var openRoute

    var body: some View {
        if let onOpen {
            Button(action: onOpen) { content }
                .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.medium))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(card.title)
                .accessibilityValue(card.accessibilityState)
                .accessibilityIdentifier("card.\(card.id)")
                .viewDetailsAction(card.titleLink, open: openRoute)
                .itemMenu(entries: menu, probe: "card.\(card.id).menu")
                .mediaMenuTrigger(onMenu, item: card)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(card.title)
                .accessibilityValue(card.accessibilityState)
                .accessibilityIdentifier("card.\(card.id)")
                .viewDetailsAction(card.titleLink, open: openRoute)
                #if os(tvOS)
                .focusable()
                #endif
        }
    }

    private var content: some View {
        let width = dimens.posterWidth * (0.5 + 0.1 * CGFloat(min(max(density, 1), 5) - 1)) * (shape == .wide ? 1.6 : 1)
        return HStack(alignment: .top, spacing: dimens.gutter) {
            CardArtwork(card: card, size: CGSize(width: width, height: width / CGFloat(shape.aspect)))
                .clipShape(CardArtworkShape(circular: card.placeholder.circular))
            VStack(alignment: .leading, spacing: 4) {
                CardLinkText(text: card.title, route: card.titleLink)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(card.titleLink == nil ? 2 : 1)
                if let metadata = card.listMetadata {
                    Text(metadata)
                        .font(.subheadline)
                        .mutedForeground()
                        .lineLimit(1)
                }
                if let subtitle = card.listSubtitle {
                    LinkedCaption(text: subtitle, link: card.captionLink)
                        .font(.subheadline)
                        .mutedForeground()
                        .lineLimit(1)
                }
                if let summary = card.summary {
                    Text(summary)
                        .font(.footnote)
                        .mutedForeground()
                        .lineLimit(Int(ListRowLayout.companion.summaryLines(density: density)))
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .contentShape(Rectangle())
    }
}
