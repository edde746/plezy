import SwiftUI
import PlezyKit

/// A music detail screen's frame: its content in a vertical scroll view inside the page's readable column, the screen's
/// title in the system navigation bar (its back button going back on every platform; on the Mac a bar with the title
/// fades in once the header's title has scrolled under the toolbar, `titleBand`); while `loading`, its spinner
/// alone (`music.loading`), nothing laid out until the screen's data is in. `identifier` names the screen for the UI
/// tests (`music.album`).
struct MusicDetailScroll<Content: View>: View {
    let title: String
    let identifier: String
    let loading: Bool
    /// Given the content's width and the screen's height.
    @ViewBuilder let content: (_ width: CGFloat, _ height: CGFloat) -> Content

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides
    @Environment(\.formFactor) private var formFactor

    var body: some View {
        Group {
            if loading {
                LoadingStateView().accessibilityIdentifier("music.loading")
            } else {
                GeometryReader { proxy in
                    let sides = formFactor == .tv ? dimens.screenPadding : max(screenSides.leading, dimens.screenPadding)
                    ScrollView(.vertical) {
                        content(proxy.size.width - 2 * sides, proxy.size.height)
                            .padding(.horizontal, sides)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                            #if os(macOS)
                            .titleScrollRoom(viewport: proxy.size.height)
                            #endif
                    }
                    .scrollClipDisabled(formFactor == .tv)
                    #if os(macOS)
                    .titleBand(title, top: proxy.safeAreaInsets.top)
                    #endif
                }
            }
        }
        #if !os(tvOS)
        // Pushed with no title on Apple TV, as Detail is: the header names the screen, and the tab bar stays above it.
        // Elsewhere the title is the back menu's and the window's; the bar shows none over the header's.
        .navigationTitle(title)
        .inlineNavigationTitle()
        .titleInContent()
        .castInTopBar(id: "music.cast")
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

/// A music screen's failure (the error with Retry) or "No items available" in the content's place.
struct MusicLoadState: View {
    let load: LoadState
    let error: String?
    let onRetry: () -> Void

    var body: some View {
        BrowsePlaceholder(load: load, error: error, onRetry: onRetry, emptyMessage: T.shared.messages.noItemsAvailable, emptySymbol: "music.note")
            .frame(minHeight: 240)
    }
}

/// An album's, an artist's or a playlist's header (`MusicHeaderUi`), as Detail's headline and action row: below
/// `MUSIC_HEADER_WIDE_FROM` across, the artwork over the centred title, lines and actions; from there the artwork beside
/// them. The artist line of an album opens the artist; the bio shows three lines until tapped.
struct MusicDetailHeader<Actions: View>: View {
    let header: MusicHeaderUi
    let width: CGFloat
    var placeholder: PlaceholderKind = .album
    var compactArtwork: CGFloat = 200
    var wideAlignment: VerticalAlignment = .bottom
    var onArtist: (() -> Void)?
    @ViewBuilder let actions: () -> Actions

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let tv = formFactor == .tv
        if width < CGFloat(MusicCardsKt.MUSIC_HEADER_WIDE_FROM) {
            VStack(spacing: 16) {
                artwork(compactArtwork)
                info(centered: true)
                actionRow
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: wideAlignment, spacing: tv ? 48 : 24) {
                artwork(tv ? 320 : 180)
                VStack(alignment: .leading, spacing: 16) {
                    info(centered: false)
                    actionRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionRow: some View {
        actions().shelfFocusSection()
    }

    private func artwork(_ side: CGFloat) -> some View {
        MusicArtwork(artwork: header.artwork, placeholder: placeholder, cornerRadius: Radius.large)
            .frame(width: side, height: side)
    }

    private func info(centered: Bool) -> some View {
        VStack(alignment: centered ? .center : .leading, spacing: 4) {
            PageHeading(title: header.title, id: "music.header.title")
                .multilineTextAlignment(centered ? .center : .leading)
                #if os(macOS)
                .anchorPreference(key: DetailTitleFrame.self, value: .bounds) { $0 }
                #endif
            if let artist = header.artist {
                if header.artistLinked, let onArtist {
                    Button(action: onArtist) {
                        Text(artist)
                            .font(.title3.weight(.medium))
                            .accentForeground()
                    }
                    #if os(tvOS)
                    .buttonStyle(SurfaceButtonStyle(fill: .clear, outset: EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)))
                    #else
                    .buttonStyle(PressDimButtonStyle())
                    #endif
                    .accessibilityIdentifier("music.header.artist")
                } else {
                    Text(artist)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Palette.onBackground)
                }
            }
            if let meta = header.meta {
                Text(meta)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .multilineTextAlignment(centered ? .center : .leading)
            }
            if let bio = header.bio {
                DetailOverview(text: bio, id: "music.header.bio")
                    .padding(.top, 8)
                    .frame(maxWidth: 720, alignment: centered ? .center : .leading)
            }
        }
    }
}

/// The music detail screens' actions (album, artist, playlist), laid out as Detail's action row is: one row that never
/// wraps or cuts a label, the widest that fits (`ViewThatFits`). First Play (prominent), the cast button (`CastButton`;
/// on phones it sits in the navigation bar instead, `castInTopBar`) and Shuffle (glass) with its label, Instant Mix
/// where the server offers it, the screen's own round buttons (`extras`: an album's download, a playlist's download
/// actions) and ⋯ with the screen's item menu in the system's menu (`onMenu`, where it has one) or its own entries
/// (`menuEntries`: a playlist's Delete Playlist); then Shuffle as a round button; then Shuffle (and Instant Mix, which
/// the item menu holds already) behind ⋯, Play keeping its label beside the round buttons. A label is never dropped
/// for width: a control that can't show its label is a round button instead. A track's menu can open over the row: its
/// glass stops taking touches while one is open (`OpenItemMenu`).
struct MusicActions<Extras: View>: View {
    let onPlay: () -> Void
    let onShuffle: () -> Void
    var onInstantMix: (() -> Void)?
    /// Opens the screen's item menu (`MediaMenu.open`) with these extra entries last, without the entries of the buttons
    /// the row shows (Play, Instant Mix and `extrasOnRow`), behind ⋯ (`menuProbe` its identifier); nil: no ⋯ until
    /// Shuffle or `menuEntries` need one.
    var onMenu: (([MenuExtra], Set<RowAction>) -> Void)?
    var menuProbe = "music.more"
    /// The buttons among `extras` whose entries ⋯ leaves out (an album's download).
    var extrasOnRow: Set<RowAction> = []
    /// ⋯'s entries where the screen has no item menu, after the folded Shuffle and Instant Mix: ⋯ shows at every width.
    var menuEntries: [ItemMenuEntry] = []
    /// Play's key in the page's focus (Apple TV's playlist page opens on it).
    var playFocus: (binding: FocusState<String?>.Binding, key: String)?
    @ViewBuilder var extras: () -> Extras

    @Environment(\.formFactor) private var formFactor

    /// How much of the row shows on its own, from all of it down to Play, the screen's round buttons and ⋯.
    private enum Level {
        case full, iconShuffle, compact
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(.full)
            row(.iconShuffle)
            row(.compact)
        }
    }

    private func row(_ level: Level) -> some View {
        ActionRow(spacing: 8) {
            ActionButton(title: T.shared.common.play, id: "music.play", prominence: .primary, systemImage: "play.fill", fullWidth: false, action: onPlay)
                .optionalFocus(playFocus)
            if formFactor != .compact {
                CastButton(look: .detail, id: "music.cast")
            }
            switch level {
            case .full:
                ActionButton(title: T.shared.common.shuffle, id: "music.shuffle", systemImage: "shuffle", fullWidth: false, action: onShuffle)
            case .iconShuffle:
                IconButton(systemImage: "shuffle", label: T.shared.common.shuffle, id: "music.shuffle", action: onShuffle)
            case .compact:
                EmptyView()
            }
            if level != .compact, let onInstantMix {
                IconButton(systemImage: "wand.and.stars", label: T.shared.music.instantMix, id: "music.instantMix", action: onInstantMix)
            }
            extras()
            if let onMenu {
                let shuffle = level == .compact ? [MenuExtra(id: "music_shuffle", label: T.shared.common.shuffle, icon: .shuffle, leading: false, run: onShuffle)] : []
                let onRow = extrasOnRow.union(level != .compact && onInstantMix != nil ? [.play, .instantMix] : [.play])
                // The system's menu, its entries read as it shows (`SystemItemMenu`), as Detail's ⋯; read again as what
                // the row shows changes (the download button comes later).
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .roundGlassLabel(.circle, menu: true)
                    .accessibilityIdentifier(menuProbe)
                    .modifier(SystemItemMenu(open: { onMenu(shuffle, onRow) }, item: [AnyHashable("\(menuProbe).\(level)"), AnyHashable(onRow)], kind: .menu, warm: true))
                    .menuIndicator(.hidden)
                    .roundGlassControl(.circle, menu: true)
                    #if os(macOS)
                    .tooltip(T.shared.common.options)
                    #endif
                    .accessibilityLabel(T.shared.common.options)
                    .accessibilityIdentifier(menuProbe)
            } else if level == .compact || !menuEntries.isEmpty {
                ActionMenuButton(entries: (level == .compact ? folded : []) + menuEntries, probe: menuProbe)
            }
        }
    }

    /// Shuffle and Instant Mix as ⋯'s entries where the screen has no item menu.
    private var folded: [ItemMenuEntry] {
        var entries = [ItemMenuEntry(label: T.shared.common.shuffle, systemImage: "shuffle", id: "music.shuffle", action: onShuffle)]
        if let onInstantMix {
            entries.append(ItemMenuEntry(label: T.shared.music.instantMix, systemImage: "wand.and.stars", id: "music.instantMix", action: onInstantMix))
        }
        return entries
    }
}

extension MusicActions where Extras == EmptyView {
    init(onPlay: @escaping () -> Void, onShuffle: @escaping () -> Void, onInstantMix: (() -> Void)?) {
        self.init(onPlay: onPlay, onShuffle: onShuffle, onInstantMix: onInstantMix) { EmptyView() }
    }
}
