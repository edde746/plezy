import SwiftUI
import PlezyKit
#if os(iOS)
import GameController
#endif

/// A titled, horizontally scrolling row of cards (`SideScroll`: a hub on Home or a library's recommendations, Continue
/// Watching, an item's related rows).
///
/// The row is a focus section: on tvOS (and with a keyboard) moving up or down into it lands on a card of the row, and
/// left/right move between its cards while the row scrolls to keep the focused one in view. Cards lift outside the
/// row's bounds on tvOS, so the scroll view doesn't clip them, but at the side of iOS 27.1's vertical bar, where the
/// row ends at the safe area (`clearOfVerticalBar`).
///
/// - Parameters:
///   - title: the row's heading: one line, but whole at the accessibility text sizes ("Recently Added in Movies" says
///     which library).
///   - id: the key path of an item's stable identity.
///   - loading: the row is loading: a spinner in the heading, before `action`, centred on the title's line. Its place
///     is kept while idle, so the heading neither grows nor moves as it comes and goes.
///   - action: a trailing element in the heading (View all, the hub's server).
///   - end: a card after the last item (a hub's View all card on tvOS).
struct ShelfRow<Data: RandomAccessCollection, ID: Hashable, Action: View, Content: View, End: View>: View {
    let title: String
    let items: Data
    let id: KeyPath<Data.Element, ID>
    var loading = false
    @ViewBuilder var action: () -> Action
    @ViewBuilder var content: (Data.Element) -> Content
    @ViewBuilder var end: () -> End

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(macOS)
    /// The cards' row's height, the scroll view's own: the Mac's horizontal scroll view doesn't take its content's.
    @State private var rowHeight: CGFloat?
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: dimens.headingGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(shelfTitleFont)
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: dimens.gutter)
                // A line of the title's font, which lines up with the title's, the spinner centred on it. A spinner's
                // text baseline is its top, which would put its top on the title's baseline: moved to its bottom, under
                // the line's, the line's sets the slot's. The Mac's regular spinner (32 pt) is taller than the line and
                // would push the cards down from the heading: there it is the small one.
                ZStack {
                    Text(verbatim: " ").font(shelfTitleFont).hidden()
                    Group { if loading { ProgressView() } else { ProgressView().hidden() } }
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                }
                // On the title's baseline but no height of its own in the heading: its smaller line, set lower on the
                // baseline, would reach a fraction of a point under the title's, so a heading with View all would sit
                // taller than one without. None (no slot, so no gap before it) where the row has no action.
                if Action.self != EmptyView.self {
                    action().frame(height: 0)
                }
            }
            .padding(sides.insets)
            SideScroll {
                LazyHStack(alignment: .top, spacing: dimens.gutter) {
                    ForEach(items, id: id) { item in content(item) }
                    end()
                }
                .padding(sides.insets)
                // Room for the focused card to lift (tvOS) or its focus ring, which the row doesn't clip: under the
                // cards; over them the heading's gap holds it (`headingGap`).
                .padding(.bottom, dimens.focusRoom)
                #if os(macOS)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeight = $0 }
                #endif
            }
            #if os(macOS)
            .frame(height: rowHeight)
            #endif
            .scrollClipDisabled()
            .clearOfVerticalBar()
            .shelfFocusSection()
        }
    }
}

/// A shelf's title's font (`ShelfRow`, `LoadingShelf`).
private let shelfTitleFont = Font.title3.weight(.semibold)

extension ShelfRow where End == EmptyView {
    init(
        title: String,
        items: Data,
        id: KeyPath<Data.Element, ID>,
        loading: Bool = false,
        @ViewBuilder action: @escaping () -> Action,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(title: title, items: items, id: id, loading: loading, action: action, content: content, end: { EmptyView() })
    }
}

extension ShelfRow where Action == EmptyView, End == EmptyView {
    init(title: String, items: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(title: title, items: items, id: id, action: { EmptyView() }, content: content)
    }
}

/// A hub (`HubUi`) as a shelf of its cards (`PosterCard`, `caption` as theirs), `hub.<id>` to accessibility. While the
/// hub has more than it shows, `onViewAll` opens its View all: a heading button (`hub.<id>.viewAll`, not on tvOS), and
/// a card after the last (`hub.viewAll`) that the remote's or the keyboard's arrows and Tab reach: on tvOS, on the Mac,
/// and on iPhone and iPad while a keyboard is connected (`KeyboardPresence`). The provider's count of the whole result set where it reports one ("347
/// results", not on tvOS) and the hub's server, where it names one, read in the heading. `onOpen`, `menu`
/// and `onMenu`, where given, are each card's; `focus` puts the cards in the screen's focus state, each card's key
/// `HubShelf.focusKey`.
struct HubShelf: View {
    let hub: HubUi
    var caption = true
    var focus: FocusState<String?>.Binding?
    var onOpen: ((MediaCardUi) -> Void)?
    var menu: ((MediaCardUi) -> [ItemMenuEntry])?
    var onMenu: ((MediaCardUi) -> Void)?
    var onViewAll: (() -> Void)?

    /// A card's key in the screen's focus state.
    static func focusKey(hub: HubUi, card: MediaCardUi) -> String { "\(hub.id)|\(card.id)" }

    #if os(iOS)
    @State private var keyboard = KeyboardPresence.shared
    #endif

    var body: some View {
        let viewAll = hub.more ? onViewAll : nil
        ShelfRow(title: hub.title, items: hub.items, id: \.id) {
            HStack(spacing: 16) {
                #if !os(tvOS)
                if let totalResults = hub.totalResults {
                    Text(totalResults)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(1)
                        .fixedSize()
                        .accessibilityIdentifier("hub.totalResults")
                }
                #endif
                if let serverName = hub.serverName {
                    Text(serverName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(1)
                }
                #if !os(tvOS)
                if let viewAll {
                    HeadingButton(title: T.shared.common.viewAll, id: "hub.\(hub.id).viewAll", action: viewAll)
                }
                #endif
            }
        } content: { card in
            PosterCard(
                card: card, shape: hub.shape, caption: caption,
                focus: focus.map { CardFocus(binding: $0, key: Self.focusKey(hub: hub, card: card)) },
                onOpen: onOpen.map { open in { open(card) } }, menu: menu?(card) ?? [],
                onMenu: onMenu.map { open in { open(card) } }
            )
        } end: {
            if let viewAll, showsSeeAllCard {
                SeeAllCard(shape: hub.shape, focus: focus.map { CardFocus(binding: $0, key: "\(hub.id)|seeAll") }, action: viewAll)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hub.\(hub.id)")
    }

    /// The View all card shows where keys move focus: always on tvOS and the Mac, on iPhone and iPad with a keyboard.
    private var showsSeeAllCard: Bool {
        #if os(iOS)
        keyboard.connected
        #else
        true
        #endif
    }
}

/// The card ending a hub cut short: a chevron over "View all" on the cards' fill, as large as the artwork of the row's
/// cards (`shape`), focused and lifted as the cards are, with the focus ring under a keyboard. Accessibility identifier
/// `hub.viewAll`.
private struct SeeAllCard: View {
    let shape: CardShape_
    let focus: CardFocus?
    let action: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let width = dimens.cardWidth(shape)
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "chevron.forward")
                    .font(.title2.weight(.semibold))
                    .accessibilityHidden(true)
                Text(T.shared.common.viewAll)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Palette.onBackground)
            .frame(width: width, height: width / CGFloat(shape.aspect))
            .background(Palette.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .focusRing(radius: Radius.medium)
        }
        .cardButtonStyle()
        .cardFocus(focus)
        .accessibilityIdentifier("hub.viewAll")
    }
}

#if os(iOS)
/// Whether a hardware keyboard is connected (`GCKeyboard`), followed as one connects and goes.
@MainActor
@Observable
final class KeyboardPresence {
    static let shared = KeyboardPresence()

    private(set) var connected = GCKeyboard.coalesced != nil

    private init() {
        let center = NotificationCenter.default
        _ = center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { KeyboardPresence.shared.connected = true }
        }
        _ = center.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { KeyboardPresence.shared.connected = GCKeyboard.coalesced != nil }
        }
    }
}
#endif

/// A shelf whose items are on their way: `ShelfRow`'s heading (`title` with the row's spinner where it is known, else a
/// bar on the title's line) over a row of blank cards of `shape` (`BlankCard`), as tall as the shelf that takes its
/// place, so the page doesn't move when its items arrive. Nothing in it takes focus or scrolls.
struct LoadingShelf: View {
    var title: String?
    var shape: CardShape_ = .poster

    @Environment(\.screenSides) private var sides

    var body: some View {
        ShelfRow(title: title ?? " ", items: Array(0..<12), id: \.self, loading: title != nil) {
            EmptyView()
        } content: { _ in
            BlankCard(shape: shape)
        }
        .scrollDisabled(true)
        // A line of the title's font on the title's own (their baselines together), a bar half its height inside it.
        .overlay(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
            if title == nil {
                Text(verbatim: " ")
                    .font(shelfTitleFont)
                    .hidden()
                    .frame(width: 160)
                    .background {
                        GeometryReader { line in
                            RoundedRectangle(cornerRadius: Radius.extraSmall, style: .continuous)
                                .fill(Palette.surfaceContainer)
                                .frame(height: line.size.height / 2)
                                .frame(width: line.size.width, height: line.size.height)
                        }
                    }
                    .padding(sides.insets)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title.map { "\($0), \(T.shared.common.loading)" } ?? T.shared.common.loading)
    }
}

/// `rows` shelves whose items are on their way (`LoadingShelf`), headings' bars over blank cards. Nothing in them takes
/// focus.
struct LoadingShelves: View {
    var rows = 3

    @Environment(\.dimens) private var dimens

    var body: some View {
        VStack(alignment: .leading, spacing: dimens.sectionSpacing) {
            ForEach(0..<rows, id: \.self) { _ in LoadingShelf() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(T.shared.common.loading)
        .accessibilityIdentifier("browse.loading")
    }
}

extension View {
    /// A focus section where the platform has them (tvOS, macOS): moving into it lands on one of its elements.
    func shelfFocusSection() -> some View {
        #if os(iOS)
        self
        #else
        focusSection()
        #endif
    }
}
