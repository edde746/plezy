import SwiftUI
import PlezyKit

/// A media item's card (`MediaCardUi`) in a shelf or a grid: the artwork at `shape`'s aspect (a circle for an artist)
/// with its badges, then the title and the caption, one line each (the title a grid's lines, two at the compact
/// densities) so every card of a row has the same height (the
/// caption's line kept when there is none); the title and the caption's lead open their details where the card links
/// them (`CardLinkText`, `LinkedCaption`). With `caption` false the artwork alone (the TV's full-card layout), but on
/// tvOS the focused card still shows its caption, in room every card of the row keeps for it, so the row doesn't move
/// as focus does. `width` is the card's; `Dimens.cardWidth(shape)` when nil (a shelf's card), where an accessibility
/// text size widens the card to its title's longest word, so no word is broken.
///
/// One button: the tvOS card style lifts the artwork on focus; elsewhere it dims while pressed and shows the focus ring
/// on keyboard focus. With `onOpen` a tap, a click or Select opens it; without, it is focusable and opens nothing.
/// `menu`, when not empty, is its item menu (`itemMenu`); `onMenu`, where given, opens the shared item menu instead
/// (`mediaMenuTrigger`). `focus` puts it in a screen's focus state. To accessibility it is one element, `card.<id>`:
/// the title, the caption and its state.
struct PosterCard: View {
    let card: MediaCardUi
    let shape: CardShape_
    var width: CGFloat?
    var caption = true
    var focus: CardFocus?
    var onOpen: (() -> Void)?
    var menu: [ItemMenuEntry] = []
    var onMenu: (() -> Void)?
    /// Where the card sits in a grid ("Row 2 of 5, column 3 of 4"), read after its state.
    var position: String?

    @Environment(\.dimens) private var dimens
    /// Between the artwork and the caption: a grid's (`GridCells.titleGap`), else a row's (`captionGap`).
    @Environment(\.cardTitleGap) private var titleGap
    @Environment(\.cardTitleLines) private var titleLines
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openRoute) private var openRoute
    #if os(tvOS)
    /// The card's button has focus.
    @State private var focused = false
    #endif
    /// The title's longest word at the current text size.
    @State private var wordWidth: CGFloat = 0

    static let titleFont = Font.subheadline.weight(.semibold)

    var body: some View {
        let artworkWidth = width ?? dimens.cardWidth(shape)
        let height = artworkWidth / CGFloat(shape.aspect)
        VStack(alignment: .leading, spacing: titleGap) {
            button(width: artworkWidth, height: height)
            if keepsCaptionRoom { captionLabel }
        }
        .frame(width: widensToWords ? max(artworkWidth, ceil(wordWidth)) : artworkWidth, alignment: .leading)
    }

    @ViewBuilder
    private func button(width: CGFloat, height: CGFloat) -> some View {
        let clip = CardArtworkShape(circular: card.placeholder.circular)
        let artwork = CardArtwork(card: card, size: CGSize(width: width, height: height))
            .clipShape(clip)
            .contentShape(clip)
            .focusRing(radius: card.placeholder.circular ? height / 2 : Radius.medium)
            #if os(tvOS)
            .background { FocusReporter(focused: $focused) }
            #endif
        if let onOpen {
            // The artwork named too: on Apple TV the button the focus engine reports is the system's, named by its
            // content, inside the element the modifiers below make.
            Button(action: onOpen) { artwork.accessibilityElement(children: .ignore).accessibilityLabel(card.title) }
                .cardButtonStyle(circular: card.placeholder.circular)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(card.title)
                .accessibilityValue([card.accessibilityState, position ?? ""].filter { !$0.isEmpty }.joined(separator: ", "))
                .accessibilityIdentifier("card.\(card.id)")
                .viewDetailsAction(card.titleLink, open: openRoute)
                .cardFocus(focus)
                .itemMenu(entries: menu, probe: "card.\(card.id).menu")
                .mediaMenuTrigger(onMenu, item: card)
        } else {
            artwork
                #if os(tvOS)
                .focusable()
                .hoverEffect(.highlight)
                #else
                // A hardware keyboard's focus (Tab, the arrows) only: a touch or a click doesn't focus a card.
                .focusable(interactions: .activate)
                .focusEffectDisabled()
                #endif
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(card.title)
                .accessibilityValue([card.accessibilityState, position ?? ""].filter { !$0.isEmpty }.joined(separator: ", "))
                .accessibilityIdentifier("card.\(card.id)")
                .viewDetailsAction(card.titleLink, open: openRoute)
                .cardFocus(focus)
        }
    }

    /// The title and caption under the artwork: two lines each at the accessibility text sizes, the title on a grid's
    /// lines (`cardTitleLines`) where it gives more, all kept on every card so a row's cards stay as tall.
    private var captionLabel: some View {
        let lines = dynamicTypeSize.isAccessibilitySize ? 2 : 1
        return VStack(alignment: .leading, spacing: 2) {
            CardLinkText(text: card.title, route: card.titleLink)
                .font(Self.titleFont)
                .foregroundStyle(Palette.onBackground)
                .lineLimit(max(lines, titleLines), reservesSpace: true)
                .background(alignment: .topLeading) {
                    if widensToWords {
                        ZStack(alignment: .leading) {
                            ForEach(Array(card.title.split(whereSeparator: \.isWhitespace).enumerated()), id: \.offset) { _, word in
                                Text(word).font(Self.titleFont).fixedSize()
                            }
                        }
                        .fixedSize()
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { wordWidth = $0 }
                    }
                }
            LinkedCaption(text: card.caption ?? " ", link: card.captionLink)
                .font(.caption)
                .foregroundStyle(Palette.onSurfaceVariant)
                .lineLimit(lines, reservesSpace: true)
        }
        .opacity(showsCaption ? 1 : 0)
        .accessibilityHidden(true)
    }

    /// A shelf's card at an accessibility text size, whose title wraps onto two lines: as wide as its longest word.
    private var widensToWords: Bool {
        width == nil && dynamicTypeSize.isAccessibilitySize
    }

    /// The caption's room is laid out: with the caption, and on tvOS for the focused card's caption.
    private var keepsCaptionRoom: Bool {
        #if os(tvOS)
        true
        #else
        caption
        #endif
    }

    private var showsCaption: Bool {
        #if os(tvOS)
        caption || focused
        #else
        caption
        #endif
    }

    /// Between the artwork and its caption in a row of cards (a shelf, a detail's row): 2, whatever the grid spacing
    /// (a grid's follows it: `GridCells.titleGap`); on tvOS the focused card lifts and grows, and the caption stays
    /// clear.
    nonisolated static var captionGap: CGFloat {
        #if os(tvOS)
        16
        #else
        2
        #endif
    }
}

extension EnvironmentValues {
    /// The gap between a card's artwork and its caption (`PosterCard`): a grid sets its own (`GridCells.titleGap`).
    @Entry var cardTitleGap: CGFloat = PosterCard.captionGap
    /// The lines a card's title takes (`PosterCard`): a grid sets its own (`GridCells.titleLines`), else one.
    @Entry var cardTitleLines = 1
}

/// A card's key in its screen's `@FocusState`: the state is `key` while the card's button has focus, and setting it to
/// `key` moves focus there.
struct CardFocus {
    let binding: FocusState<String?>.Binding
    let key: String
}

extension View {
    @ViewBuilder
    func cardFocus(_ focus: CardFocus?) -> some View {
        if let focus { focused(focus.binding, equals: focus.key) } else { self }
    }
}

#if os(tvOS)
/// Inside a button's label: copies whether that button has focus into `focused`.
struct FocusReporter: View {
    @Binding var focused: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Color.clear.onChange(of: isFocused, initial: true) { focused = isFocused }
    }
}
#endif

extension MediaCardUi {
    /// The card's state to accessibility: its caption, watched, the progress, the unwatched count.
    var accessibilityState: String {
        var parts: [String] = []
        if let caption { parts.append(caption) }
        if let progress {
            parts.append(T.shared.accessibility.mediaCardPartiallyWatched(percent: String(Int((progress.doubleValue * 100).rounded()))))
        } else if watched {
            parts.append(T.shared.accessibility.mediaCardWatched)
        }
        if let unwatchedLabel { parts.append(unwatchedLabel) }
        parts.append(contentsOf: qualityLabels)
        return parts.joined(separator: ", ")
    }
}

/// A card's artwork outline: a circle for an artist, else the medium radius's rounded rectangle.
struct CardArtworkShape: Shape {
    let circular: Bool

    func path(in rect: CGRect) -> Path {
        circular
            ? Circle().path(in: rect)
            : RoundedRectangle(cornerRadius: Radius.medium, style: .continuous).path(in: rect)
    }
}

/// The artwork and its badges, `size` points: the highest surface while it loads; without artwork (or when it fails)
/// the item's icon on it. The artwork is the card's `primaryArtwork`, its `retryArtwork` once that fails; a failed
/// `artwork` is remembered (`FailedArtwork`), so later cards start at the fallback. Blurred past recognition where the
/// card says (`blurred`: an unwatched episode's own still while spoilers are hidden). The quality labels down the
/// leading corner, the watched check or the unwatched count at the trailing one, the progress along the foot
/// (`ArtworkProgress`).
struct CardArtwork: View {
    let card: MediaCardUi
    let size: CGSize

    var body: some View {
        ZStack {
            Palette.surfaceContainerHighest
            let primary = card.primaryArtwork
            RemoteImage(artwork: primary, fallback: card.retryArtwork, blurred: card.blurred, size: size) { failed in
                if failed { ArtworkPlaceholder(kind: card.placeholder) }
            } onResult: { outcome in
                if outcome == .failed, let primary, primary.isEqual(card.artwork), card.fallbackArtwork != nil {
                    FailedArtwork.shared.remember(artwork: primary)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            if !card.qualityLabels.isEmpty, !card.placeholder.circular {
                // Hidden: the card's value says them.
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(card.qualityLabels.prefix(3), id: \.self) { BadgeView(text: $0) }
                }
                .padding(6)
                .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let label = card.unwatchedLabel, !card.watched {
                BadgeView(text: label, emphasis: .strong).padding(6).accessibilityHidden(true)
            } else if card.watched, card.progress == nil {
                // Hidden: SwiftUI names a checkmark symbol "Selected"; the card's value says "Watched". White on the
                // scrim whatever the theme: it sits on the artwork.
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Palette.scrim.opacity(0.55))
                    .font(.title3)
                    .padding(6)
                    .accessibilityHidden(true)
            }
        }
        .overlay {
            if let progress = card.progress {
                ArtworkProgress(value: progress.doubleValue)
            }
        }
    }
}

/// Progress on artwork (a poster, a Continue Watching card, an episode's thumbnail), one look wherever it sits there:
/// a capsule filled to `value` (0–1) in the primary colour on a 30 % track of it, inset from the artwork's sides and
/// bottom, over a scrim fading from 60 % black at the bottom edge to clear over the lowest 30 % of the artwork, so the
/// bar reads on light artwork too. Laid over the artwork, whose size it takes.
struct ArtworkProgress: View {
    let value: Double

    #if os(tvOS)
    private static let height: CGFloat = 6
    private static let inset: CGFloat = 10
    #else
    private static let height: CGFloat = 4
    private static let inset: CGFloat = 8
    #endif

    var body: some View {
        GeometryReader { geometry in
            let track = max(geometry.size.width - 2 * Self.inset, 0)
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Palette.scrim.opacity(0.6), Palette.scrim.opacity(0)], startPoint: .bottom, endPoint: .top)
                    .frame(height: geometry.size.height * 0.3)
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.primary.opacity(0.3))
                    Capsule().fill(Palette.primary).frame(width: track * min(max(value, 0), 1))
                }
                .frame(width: track, height: Self.height)
                .clipShape(Capsule())
                .padding(.bottom, Self.inset)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A card's place while its item is on its way: the artwork's outline and bars on its title's and caption's lines, on
/// the cards' fill. Each line keeps the room `PosterCard`'s takes (its font, its lines, the gap above), so the card
/// that takes its place is as tall and the page doesn't jump when the items arrive. Nothing in it takes focus.
struct BlankCard: View {
    let shape: CardShape_
    var width: CGFloat?

    @Environment(\.dimens) private var dimens
    @Environment(\.cardTitleGap) private var titleGap
    @Environment(\.cardTitleLines) private var titleLines
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let width = width ?? dimens.cardWidth(shape)
        let lines = dynamicTypeSize.isAccessibilitySize ? 2 : 1
        VStack(alignment: .leading, spacing: titleGap) {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .fill(Palette.surfaceContainer)
                .frame(width: width, height: width / CGFloat(shape.aspect))
            VStack(alignment: .leading, spacing: 2) {
                line(PosterCard.titleFont, lines: max(lines, titleLines), bar: width * 0.7, height: 12)
                line(.caption, lines: lines, bar: width * 0.4, height: 10)
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityHidden(true)
    }

    /// `lines` lines of text in `font`, as much room as a card's line of it takes, with a bar `bar` wide on it.
    private func line(_ font: Font, lines: Int, bar: CGFloat, height: CGFloat) -> some View {
        Text(verbatim: " ")
            .font(font)
            .lineLimit(lines, reservesSpace: true)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: Radius.extraSmall, style: .continuous)
                    .fill(Palette.surfaceContainer)
                    .frame(width: bar, height: height)
            }
    }
}
