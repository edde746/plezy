import SwiftUI
import PlezyKit

/// A detail screen's action row (`ActionRow`): Play (its label, "S1E2", beside the symbol; Resume to accessibility when
/// it resumes), split with the version menu's chevron when the item has several versions (`playControl`), the cast button
/// (`CastButton`; on phones it sits in the navigation bar instead, `castInTopBar`), the trailer, Shuffle (a show's or
/// season's), the download button (`download`, not on Apple TV), the watched toggle, the watchlist button (the
/// environment's watchlist model: `DetailWatchlistButton`), then ⋯ (online only): the item's shared menu
/// (`menu`, `MediaMenu.open` at `MediaDetailStore.menuPlace`) without the entries of the buttons the row shows
/// (`onRow`), with Play trailer when the item has one and the row doesn't show it, and the row's own extra first: Play
/// from beginning for a show or season that resumes (a movie's and an episode's menu has its own). Disabled Play while
/// the item or its episodes load. An episode's or an extra's menu can open over the row: its glass stops taking touches
/// while one is open (`OpenItemMenu`).
///
/// Off a TV the row compacts to the width it is given: first the trailer and the watchlist go, then the download button,
/// then Shuffle, then the watched toggle, each back in ⋯ as it goes. On a TV (`focus` set: the screen's focus state,
/// Play's key `DetailActionRow.playKey`) every action shows. The page places the track status under the row.
struct DetailActionRow: View {
    let actions: DetailActionsUi
    let kind: MediaKind?
    let store: MediaDetailStore
    let menu: MediaMenu
    var download: DownloadButtonSpec?
    var focus: FocusState<String?>.Binding?

    static let playKey = "detail.play"

    /// How much of the row shows, from all of it down to Play, the versions and ⋯.
    private enum Level: Int, Comparable {
        case full, medium, compact, narrow, minimal

        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    @Environment(\.dimens) private var dimens
    @Environment(\.formFactor) private var formFactor
    @Environment(StoreModel<DetailWatchlistStore, DetailWatchlistUi?>.self) private var watchlist: StoreModel<DetailWatchlistStore, DetailWatchlistUi?>?

    var body: some View {
        if focus != nil {
            buttons(.full)
        } else {
            ViewThatFits(in: .horizontal) {
                buttons(.full)
                buttons(.medium)
                buttons(.compact)
                buttons(.narrow)
                buttons(.minimal)
            }
        }
    }

    /// Play's chevron, the narrower end segment of Play's split capsule (`playControl`): the system's menu of the item's
    /// versions where it has several (`detail.version.<i>`), the one Play plays checked, then where the server
    /// transcodes the Quality submenu (`detail.quality`, `detail.quality.<i>`), the quality Play plays at checked; a pick
    /// plays it. Its value names the checked ones (a Mac's menu items don't report their check). On Apple TV the chevron
    /// has its focus back as the menu closes.
    private var versionsButton: some View {
        let versions = actions.versions.enumerated().map { index, version in
            ItemMenuEntry(label: version, id: "detail.version.\(index)", selected: index == actions.version) {
                store.playVersion(index: Int32(index))
            }
        }
        let qualities = actions.qualities.enumerated().map { index, quality in
            ItemMenuEntry(label: quality, id: "detail.quality.\(index)", selected: index == actions.quality) {
                store.playQuality(index: Int32(index))
            }
        }
        let quality = ItemMenuEntry(
            label: T.shared.videoControls.qualityColumnHeader, systemImage: "slider.horizontal.3", id: "detail.quality", submenu: qualities
        ) {}
        return Menu {
            ItemMenuEntries(entries: versions, probe: "detail.version")
            if !qualities.isEmpty {
                if !versions.isEmpty { Divider() }
                ItemMenuEntries(entries: [quality], probe: "detail.quality")
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.body.weight(.bold))
                .actionLabel()
                .splitSegment(end: 12)
        }
        .menuIndicator(.hidden)
        #if os(macOS)
        .menuStyle(.button)
        #endif
        .splitSegmentStyle()
        .disabled(!actions.playEnabled)
        .accessibilityLabel(T.shared.mediaMenu.playVersion)
        .accessibilityValue(
            [actions.versions.indices.contains(Int(actions.version)) ? actions.versions[Int(actions.version)] : nil,
             actions.qualities.indices.contains(Int(actions.quality)) ? actions.qualities[Int(actions.quality)] : nil]
                .compactMap { $0 }.joined(separator: ", ")
        )
        .accessibilityIdentifier("detail.versions")
    }

    private func buttons(_ level: Level) -> some View {
        ActionRow(spacing: 8 * dimens.unit) {
            playControl
            if formFactor != .compact {
                CastButton(look: .detail, id: "detail.castTo")
            }
            if level == .full, actions.trailer {
                IconButton(systemImage: "play.rectangle", label: T.shared.tooltips.playTrailer, id: "detail.trailer", action: store.playTrailer)
            }
            if level <= .compact, actions.shuffle {
                IconButton(systemImage: "shuffle", label: T.shared.tooltips.shufflePlay, id: "detail.shuffle", action: store.shuffle)
            }
            #if !os(tvOS)
            if level <= .medium, let download {
                DetailDownloadButton(spec: download, onPress: store.pressDownload)
            }
            #endif
            if level <= .narrow, actions.canMarkWatched {
                IconButton(
                    // Watched shows a check, unwatched the outlined eye: a filled and an outlined eye barely differ.
                    systemImage: actions.watched ? "checkmark.circle" : watchedSymbol(false),
                    label: actions.watched ? T.shared.tooltips.markAsUnwatched : T.shared.tooltips.markAsWatched,
                    id: "detail.watched",
                    action: store.toggleWatched
                )
            }
            if level == .full, let watchlist {
                DetailWatchlistButton(model: watchlist, focus: focus)
            }
            if actions.more {
                let label = Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .roundGlassLabel(.circle, menu: true)
                // The system's menu, its entries read as it shows (`SystemItemMenu`), under the button on the Mac
                // whatever opened it; the identifier on its label as well, which the focused button reports.
                let more = label.accessibilityIdentifier("detail.more")
                    // Read again as what the row shows changes, not only the actions (the download button comes later).
                    .modifier(SystemItemMenu(open: { openMenu(level) }, item: [AnyHashable(actions), AnyHashable(onRow(level))], kind: .menu, warm: true))
                    .menuIndicator(.hidden)
                    .roundGlassControl(.circle, menu: true)
                    .accessibilityLabel(T.shared.common.options)
                    .accessibilityIdentifier("detail.more")
                if let focus {
                    more.focused(focus, equals: "detail.more")
                } else {
                    more
                }
            }
        }
    }

    /// Play, and where the item has versions or qualities to pick from, its chevron (`versionsButton`) beside it in one
    /// split capsule: Play's fill, a hairline between the two, the chevron's end narrower, the row's height. Each
    /// segment is a control of its own, as tall as the capsule.
    @ViewBuilder
    private var playControl: some View {
        if actions.versions.isEmpty && actions.qualities.isEmpty {
            playButton(segment: false)
        } else {
            HStack(spacing: 0) {
                playButton(segment: true)
                Divider().padding(.vertical, IconButton.circleInset)
                versionsButton
            }
            .fixedSize()
            .splitCapsule()
        }
    }

    @ViewBuilder
    private func playButton(segment: Bool) -> some View {
        let label = HStack(spacing: 6) {
            Image(systemName: "play.fill")
            if let label = actions.playLabel {
                Text(label).fontWeight(.semibold)
            }
        }
        .padding(.horizontal, actions.playLabel == nil ? 4 : 0)
        .actionLabel()
        let button = Group {
            if segment {
                Button(action: store.play) { label.splitSegment(end: 16) }
                    .splitSegmentStyle()
            } else {
                Button(action: store.play) { label }
                    .buttonProminence(.primary)
                    .buttonBorderShape(.capsule)
            }
        }
        .disabled(!actions.playEnabled)
        .accessibilityLabel(actions.resume ? T.shared.common.resume : T.shared.common.play)
        .accessibilityValue(actions.playLabel ?? "")
        .accessibilityIdentifier("detail.play")
        if let focus {
            button.focused(focus, equals: Self.playKey)
        } else {
            button
        }
    }

    /// The buttons the row shows at `level`, whose entries its ⋯ leaves out.
    private func onRow(_ level: Level) -> Set<RowAction> {
        var shown: Set<RowAction> = []
        if !actions.versions.isEmpty || !actions.qualities.isEmpty { shown.insert(.versions) }
        if level == .full, actions.trailer { shown.insert(.trailer) }
        if level <= .compact, actions.shuffle { shown.insert(.shuffle) }
        #if !os(tvOS)
        if level <= .medium, download != nil { shown.insert(.download) }
        #endif
        if level <= .narrow, actions.canMarkWatched { shown.insert(.watched) }
        if level == .full, watchlist != nil { shown.insert(.watchlist) }
        return shown
    }

    /// Opens the item's shared menu, with Play trailer and the row's extra (first in the menu), without what the row
    /// shows at `level`.
    private func openMenu(_ level: Level) {
        guard let item = store.menuItem() else { return }
        var extras: [MenuExtra] = []
        if actions.resume, kind == .show || kind == .season {
            extras.append(MenuExtra(id: "detail_play_from_beginning", label: T.shared.mediaMenu.playFromBeginning, icon: .replay, leading: true, run: store.playFromStart))
        }
        menu.open(item: item, place: store.menuPlace, extras: extras, playTrailer: actions.trailer ? store.playTrailer : nil, onRow: onRow(level))
    }
}

private extension View {
    /// A segment's label in Play's split capsule: the row's line (`actionLabel`) padded to the round buttons' height
    /// (`IconButton.circleInset` above and below), `end` from the capsule's end, the whole segment taking presses.
    func splitSegment(end: CGFloat) -> some View {
        padding(.vertical, IconButton.circleInset)
            .padding(.horizontal, end)
            .contentShape(Rectangle())
    }

    /// A segment of Play's split capsule: plain in the capsule's glass (`splitCapsule`); on Apple TV lit white while
    /// focused, as a TV surface is.
    @ViewBuilder
    func splitSegmentStyle() -> some View {
        #if os(tvOS)
        buttonStyle(SurfaceButtonStyle(fill: .clear, radius: 100))
        #else
        self
        #endif
    }

    /// Play's split capsule: Play's fill (the primary glass, its segments plain inside it); on Apple TV the unfocused
    /// primary tone, a focused segment lighting up inside it.
    @ViewBuilder
    func splitCapsule() -> some View {
        #if os(tvOS)
        background(Palette.primary.opacity(0.16), in: Capsule())
        #else
        glassCapsule(filled: true)
        #endif
    }
}

extension MediaDetailStore {
    /// Where the detail's menus open: on its show's own screen, so they offer no Go to series to it.
    var menuPlace: MenuPlace {
        MenuPlace(continueWatching: false, collectionId: nil, seriesId: seriesId(), albumId: nil, artistId: nil)
    }

    /// Opens the menu of the episode row `episodeId` (`MediaDetailStore.episodeItem`), offline too.
    func openEpisodeMenu(_ episodeId: String, in menu: MediaMenu) {
        guard let item = episodeItem(episodeId: episodeId) else { return }
        menu.open(item: item, place: menuPlace, extras: [], playTrailer: nil, onRow: [])
    }

    /// Opens the menu of the season `seasonId` (`MediaDetailStore.seasonItem`); nothing offline.
    func openSeasonMenu(_ seasonId: String, in menu: MediaMenu) {
        guard let item = seasonItem(seasonId: seasonId) else { return }
        menu.open(item: item, place: menuPlace, extras: [], playTrailer: nil, onRow: [])
    }
}
