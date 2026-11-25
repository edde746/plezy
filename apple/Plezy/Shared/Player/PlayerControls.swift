import SwiftUI
import PlezyKit

/// Everything drawn over the video, all of it from `PlayerUiState`, in each platform's own player layout (as close to
/// the system player as a custom mpv surface allows):
///
/// - iOS and iPadOS (`TouchControls`): Liquid Glass controls as the system player has them: close and picture in
///   picture top left, the room pill, the audio and subtitle menus, the chapters, the queue and the options menu top
///   right, back/play/forward in the middle (between the previous and the next episode for an episode of a series),
///   the title and the timeline with its times inline at the bottom.
/// - macOS (`DesktopControls`): the title beside the window's buttons and a floating glass control bar, as QuickTime
///   Player has them; the window shows no toolbar or title of its own while the player is up (`PlayerWindowChrome`).
/// - tvOS (`TVControls`): the system player's transport bar: the title and the menu buttons over a timeline with its
///   times under it; a menu or the options open in a card above their button, the chapters, the queue and the playback
///   info in a panel across the bottom (`PlayerTVPanel`). Its buttons are `PlayerTVButtonStyle`'s platters.
///
/// A live playback (`PlaybackMode.live`) has no timeline and no back or forward (`PlayerUiState.showsTimeline`,
/// `showsSeekButtons`): the live label (`LiveLabel`) shows right after play/pause (the Mac's control bar; on tvOS
/// play/pause takes the timeline's place), or where the timeline starts where play/pause is in the middle (iOS). With a
/// rewind window (`PlaybackMode.liveWindow`) the timeline is back as the window, from its start to the live edge, still
/// without back or forward, and the live label is the go-to-live button: on the Mac where it was, on iOS in the time
/// left's place on the timeline row, on tvOS first among the transport bar's buttons.
///
/// The timeline (its bar, its times, the live label and a scrub's preview) draws from `PlayerModel.timeline`, which
/// moves several times a second as the video plays: only those views read it, so nothing else is drawn again as it
/// moves, and each platform's controls observe it while they show it, so with the controls down nothing follows it.
///
/// Over the controls: the loading spinner with the store's text, the transient message (volume, speed, zoom, track,
/// the room's toasts, with its symbol) and the held finger's speed at the top, the play/pause flash in the middle and the
/// seek badge at the side it went (`PlayerFeedback`), the level a swipe changed at its edge, the room's reconnecting
/// pill, a room's Play card and the sleep timer's "Still watching?" card above the prompt button (skip, up next) at the
/// bottom-trailing corner, above the bottom controls while they show, and the error. Over all of them the playback
/// info's card (`PlaybackInfoCard`), in room that none of the controls, menus and corner cards showing take.
///
/// The error is full screen: the player is black behind it from edge to edge, and the controls over it are the title
/// and back alone, where the platform's controls have them (`PlayerUiState.showsPlaybackControls`): close on iOS, back
/// and the title on the Mac, the title on Apple TV; no transport, timeline or live label, menus, picture in picture or
/// room pill: the error's buttons are all there is to reach.
///
/// While picture in picture runs (iOS), the controls are close and the picture in picture button alone, and they stay
/// up: AVKit's placeholder is where the video was, and the PiP window has the playback's own controls (`TouchControls`).
/// On the Mac the player's area says the video plays in picture in picture (`MacPictureInPicturePlaceholder`).
///
/// On iOS and iPadOS nothing over the video meets the controls, in either orientation on any size, and nothing keeps
/// further from the edges than that needs:
/// - The messages at the top (the transient message, the held finger's speed, and the loading text while the controls
///   show) sit side by side in the top bar's row, centred and level with its buttons, the same with the controls up or
///   down, where the room between its two groups of buttons holds them (an iPad, an iPhone in landscape). Where it
///   doesn't (an iPhone upright) they go under the top bar and keep above what is in the middle, the transport or the
///   loading spinner, one above the other where there is room, else side by side.
/// - A swipe's level (`PlayerLevelIndicator`) stands at the edge of the side swiped, vertically centred, inside the
///   safe area: the brightness at the left, the volume at the right.
/// - With the controls up, the corner sits directly above the timeline, its trailing edge on the timeline's, beside the
///   title lines; above them where it would meet them (a long title, a narrow screen). Where it reaches up beside the
///   centre transport (an iPhone in landscape) it narrows to the room beside it.
/// - While the store loads with the controls up, the spinner is in play/pause and its text among those messages; with
///   the controls down, both are in the middle, where nothing else is.
/// - An error takes the middle alone (`centreAlone`): nothing plays, so no transport and no bottom bar show with it, and
///   it sits centred under the top bar and the messages, scrolling where it is taller than that room.
///
/// On the Mac, in a window and in full screen:
/// - The messages at the top sit side by side on the title bar's row, centred on the window, level with back and as tall
///   (`PlayerOsdMessage`), the same with the controls up or down, where they keep clear of the title's text (and the
///   buttons before it) by a gap: clear of the window's top edge as back is. Where they don't clear the title (a long
///   title, a narrow window) they go under the row.
/// - With the controls up, the corner sits directly above the control bar, its trailing edge on the bar's: in from the
///   window's edge where the window is wider than the bar.
/// Buttons, menus and the timeline send `PlayerCommand`s straight to the store.
struct PlayerOverlay: View {
    let playback: PlayerModel
    let state: PlayerUiState
    let focus: FocusState<PlayerFocus?>.Binding
    /// The top of the bottom controls in global coordinates, as they lay out (the subtitle lift).
    let onControlsTop: (CGFloat) -> Void

    /// The overlay's frame, the top of the bottom controls, on iOS the centre transport's frame and on the Mac the
    /// control bar's (the last they laid out), in global coordinates, and the corner's height: where the corner's card
    /// and button go. On iOS also the trailing edge of the title lines and the top of the timeline (global), where the
    /// corner goes beside the title; the frame of the loading spinner and its text in the middle, and the height of the
    /// messages at the top: where those messages and what takes the middle alone go.
    @State private var bounds = CGRect.zero
    @State private var controlsTop: CGFloat?
    #if os(iOS)
    @State private var transport: CGRect?
    /// The centre transport's last frame while it showed: where it stands while a card hides it (`cardHidesTransport`).
    @State private var lastTransport: CGRect?
    @State private var titleTrailing: CGFloat?
    @State private var timelineTop: CGFloat?
    @State private var spinner: CGRect?
    @State private var statusHeight: CGFloat = 0
    #elseif os(macOS)
    @State private var controlBar: CGRect?
    /// The copies of the window's buttons in full screen, which set the title row's height there (`DesktopTitleBar`).
    @Environment(\.playerWindowButtons) private var windowButtons
    #elseif os(tvOS)
    /// The top of the transport bar's buttons (global), which a menu opens above.
    @State private var buttonsTop: CGFloat?
    /// The menu buttons' frames (global), by the tab each opens (`PlayerMenuButtonFrames`).
    @State private var menuButtons: [PlayerPanelTab: CGRect] = [:]
    @Environment(\.layoutDirection) private var layoutDirection
    #endif
    #if !os(tvOS)
    /// How far the top bar's row reaches from the overlay's sides, as it last laid out with the controls up: on iOS its
    /// two groups of buttons; on the Mac, whose title row holds nothing on its right, the window's buttons, back,
    /// picture in picture and the title's text. Kept while they are down: the overlay keeps to the safe area and what
    /// the row holds doesn't change as the device turns, so neither do these distances.
    @State private var topRowLeading: CGFloat?
    #if os(iOS)
    @State private var topRowTrailing: CGFloat?
    #endif

    /// The overlay's coordinate space, where the controls measure the top bar's row.
    nonisolated static let space = "PlayerOverlay"
    #endif
    @State private var cornerHeight: CGFloat = 0

    var body: some View {
        let store = playback.store
        let reportControlsTop: (CGFloat) -> Void = { top in
            controlsTop = top
            onControlsTop(top)
        }
        ZStack {
            // The error is full screen: the player black behind it from edge to edge, under the controls left with it
            // (`PlayerErrorPanel`).
            if state.centre is PlayerCentreError {
                Color.black.ignoresSafeArea()
            }
            #if os(tvOS)
            let tab = PlayerPanelTab(state)
            // The panel across the bottom takes the transport bar's place, as AVKit's info panel does.
            if !(tab?.isPanelTab ?? false) {
                TVControls(playback: playback, state: state, focus: focus, onControlsTop: reportControlsTop) { buttonsTop = $0 }
            }
            if let tab {
                PlayerTVPanel(tab: tab, state: state, store: store, focus: focus)
                    .playbackInfoObstacle()
                    .padding(.trailing, menuTrailing(tab))
                    .padding(.bottom, tab.isPanelTab ? 0 : menuBottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: tab.isPanelTab ? .bottom : .bottomTrailing)
                    .transition(.opacity)
            }
            #elseif os(macOS)
            // The video is in the picture-in-picture window: the player's area says so, behind the controls.
            if playback.surface.pictureInPicture.active {
                MacPictureInPicturePlaceholder()
            }
            DesktopControls(
                playback: playback,
                state: state,
                focus: focus,
                onControlBar: { bar in
                    controlBar = bar
                    reportControlsTop(bar.minY)
                },
                // Only as the controls show: going away, they may lay out once more as they fade.
                onTopRowLeading: { if playback.state.state.controlsVisible { topRowLeading = $0 } }
            )
            #else
            TouchControls(
                playback: playback,
                state: state,
                centreAlone: centreAlone,
                pictureInPicture: inPictureInPicture,
                transportHidden: cardHidesTransport,
                onControlsTop: reportControlsTop,
                onTitleTrailing: { titleTrailing = $0 },
                onTimelineTop: { timelineTop = $0 },
                // Only as the controls show (in picture in picture all along): going away, they may lay out once more
                // as they fade.
                onTopRowLeading: { if controlsShow { topRowLeading = $0 } },
                onTopRowTrailing: { if controlsShow { topRowTrailing = $0 } }
            ) {
                transport = $0
                if let frame = $0 { lastTransport = frame }
            }
                // Going away, they fade out for a moment: a tap meanwhile goes to the video, which brings them back,
                // not to a fading button, which goes before the touch ends and never acts on it. In picture in picture
                // they stay.
                .allowsHitTesting(state.controlsVisible || inPictureInPicture)
            #endif
            if case .loading(let loading)? = onEnum(of: state.centre) {
                #if os(iOS)
                if !playbackControlsUp {
                    LoadingOverlay(text: loading.text)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { spinner = $0 }
                        .onDisappear { spinner = nil }
                        .allowsHitTesting(false)
                }
                #else
                LoadingOverlay(text: loading.text)
                    .allowsHitTesting(false)
                #endif
            }
            if let flash = state.transportFlash {
                PlayerTransportFlash(flash: flash).allowsHitTesting(false)
            }
            if let badge = state.skipBadge {
                PlayerSkipBadge(badge: badge, width: bounds.width).allowsHitTesting(false)
            }
            if state.osd != nil || state.heldSpeed != nil || loadingTextAtTop != nil {
                #if os(iOS)
                ViewThatFits(in: .horizontal) {
                    // In the top bar's row, centred and level with its buttons, where they fit between its groups.
                    if let topRowSide {
                        HStack(spacing: 10) { messages }
                            .fixedSize()
                            .frame(minHeight: PlayerMetrics.button)
                            .padding(.horizontal, topRowSide)
                    }
                    // Else under the top bar.
                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 10) { messages }
                        HStack(spacing: 10) { messages }
                    }
                    .padding(.top, PlayerMetrics.osdTop - PlayerMetrics.barInset)
                }
                // The messages' glass, one row or column of it.
                .glassGroup(spacing: 10)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { statusHeight = $0 }
                .onDisappear { statusHeight = 0 }
                .frame(maxHeight: statusRoom, alignment: .top)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, PlayerMetrics.barInset)
                .allowsHitTesting(false)
                #elseif os(macOS)
                // The window's title bar is the top safe area, as for `DesktopControls`.
                GeometryReader { proxy in
                    let titleBar = proxy.safeAreaInsets.top
                    ViewThatFits(in: .horizontal) {
                        // On the title row, centred and level with back, where they clear the title.
                        if let topRowSide {
                            HStack(spacing: 10) { messages }
                                .fixedSize()
                                .frame(height: DesktopTitleBar.height(titleBar: titleBar, windowButtons: windowButtons))
                                .padding(.horizontal, topRowSide)
                        }
                        // Else under the row.
                        VStack(spacing: 10) { messages }
                            .padding(.top, titleBar + PlayerMetrics.osdTop)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
                #else
                VStack(spacing: 10) { messages }
                    .glassGroup(spacing: 10)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, PlayerMetrics.osdTop)
                    .allowsHitTesting(false)
                #endif
            }
            // The level a swipe changed, at the edge of the side swiped (as seen, in every language) and fading in and
            // out with it.
            ZStack {
                if let level = state.level {
                    PlayerLevelIndicator(level: level)
                        .padding(.horizontal, PlayerLevelIndicator.edge)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: level.kind == .brightness ? .leading : .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.16), value: state.level?.kind)
            PlayerWatchStatus(state: state)
            if state.stillWatching != nil || state.prompt != nil || state.watch?.playBlocked != nil {
                #if os(iOS)
                // Beside the title lines where it fits there, else above them.
                ViewThatFits(in: .horizontal) {
                    if let beside = cornerBesideTitle {
                        corner(bottom: beside.bottom).padding(.leading, beside.leading)
                    }
                    corner(bottom: cornerBottom)
                }
                #else
                corner(bottom: cornerBottom)
                #endif
            }
            if let error = state.centre as? PlayerCentreError {
                PlayerErrorPanel(error: error.error, store: store, focus: focus)
                    .controlRegion(store)
                    .playbackInfoObstacle()
                    #if os(iOS)
                    .modifier(CentreAlone(top: aloneTop))
                    #endif
            }
        }
        .overlayPreferenceValue(PlaybackInfoObstacles.self) { obstacles in
            if let info = state.playbackInfo {
                PlaybackInfoCard(info: info, playback: playback, obstacles: obstacles)
            }
        }
        #if os(iOS)
        // The text over the video grows to the first accessibility size and no further: past it the bars' rows took
        // the video's height. The buttons' symbols grow with it (`PlayerIconButton`); a long press shows one large.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        #endif
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { bounds = $0 }
        #if os(tvOS)
        .onPreferenceChange(PlayerMenuButtonFrames.self) { menuButtons = $0 }
        #endif
        #if !os(tvOS)
        .coordinateSpace(.named(Self.space))
        #endif
        .animation(.easeOut(duration: 0.2), value: state.controlsVisible)
        .animation(.easeOut(duration: 0.2), value: state.osd)
        .animation(.easeOut(duration: 0.25), value: PlayerPanelTab(state))
        .animation(.easeOut(duration: 0.2), value: state.prompt?.kind)
        // The transient message (volume, speed, a room's notice) is gone in a moment, wherever VoiceOver is.
        .announcing(state.osd)
    }

    #if os(tvOS)
    /// A menu's distance from the overlay's bottom: AVKit's, 24 pt above the buttons.
    private var menuBottom: CGFloat {
        guard let buttonsTop, bounds.maxY > buttonsTop else { return PlayerMetrics.overlayGap }
        return bounds.maxY - buttonsTop + PlayerMetrics.overlayGap
    }

    /// A menu's trailing edge on its button's, as AVKit's: its button's distance in from the row's trailing end (the
    /// last button's, on the left in a right-to-left language); the panel across the bottom, which has no button, none.
    private func menuTrailing(_ tab: PlayerPanelTab) -> CGFloat {
        guard let button = menuButtons[tab] else { return 0 }
        let frames = menuButtons.values
        if layoutDirection == .rightToLeft { return button.minX - (frames.map(\.minX).min() ?? button.minX) }
        return (frames.map(\.maxX).max() ?? button.maxX) - button.maxX
    }
    #endif

    /// The messages at the top: the transient message with its symbol, the speed a held finger plays at and, on iOS
    /// with the controls up, the loading text (its spinner is in play/pause then).
    @ViewBuilder private var messages: some View {
        if let osd = state.osd { PlayerOsdMessage(text: osd, icon: state.osdIcon) }
        if let speed = state.heldSpeed { PlayerHeldSpeedMessage(text: speed) }
        if let text = loadingTextAtTop { LoadingText(text: text) }
    }

    private var loadingTextAtTop: String? {
        #if os(iOS)
        playbackControlsUp ? (state.centre as? PlayerCentreLoading)?.text : nil
        #else
        nil
        #endif
    }

    #if os(iOS)
    /// An error: nothing plays, so it takes the middle without the transport and the bottom bar.
    private var centreAlone: Bool {
        state.centre is PlayerCentreError
    }

    /// Picture in picture runs: AVKit's placeholder is where the video was, under close and the PiP button alone.
    private var inPictureInPicture: Bool { playback.surface.pictureInPicture.active }

    /// The controls show (in picture in picture close and its button, all along), read from the store when a layout
    /// reports rather than from the state the body was built with.
    private var controlsShow: Bool { playback.state.state.controlsVisible || inPictureInPicture }
    #endif

    /// The bottom controls (on iOS also the centre transport) show: the controls are up, and on iOS picture in picture
    /// doesn't run.
    private var playbackControlsUp: Bool {
        #if os(iOS)
        state.controlsVisible && !inPictureInPicture
        #else
        state.controlsVisible
        #endif
    }

    #if os(iOS)
    /// The most the messages at the top may take from the top bar's row down: to what is in the middle (the transport
    /// with the controls up, the loading spinner without) less a gap; nil without anything there.
    private var statusRoom: CGFloat? {
        guard !centreAlone, let middle = playbackControlsUp ? transport : spinner, bounds.height > 0 else { return nil }
        return max(0, middle.minY - bounds.minY - PlayerMetrics.barInset - PlayerMetrics.overlayGap)
    }

    /// Where what takes the middle alone starts: under the top bar and the messages at the top.
    private var aloneTop: CGFloat {
        guard statusHeight > 0 else { return PlayerMetrics.osdTop }
        return max(PlayerMetrics.osdTop, PlayerMetrics.barInset + statusHeight + PlayerMetrics.overlayGap)
    }

    /// With the controls up, where the corner goes directly above the timeline beside the title lines: the leading edge
    /// of the room past them (and a gap), and the corner's bottom; nil with the controls down or the middle alone.
    private var cornerBesideTitle: (leading: CGFloat, bottom: CGFloat)? {
        guard playbackControlsUp, !centreAlone, let titleTrailing, let timelineTop, bounds.maxY > timelineTop else { return nil }
        return (titleTrailing - bounds.minX + PlayerMetrics.overlayGap, bounds.maxY - timelineTop + PlayerMetrics.overlayGap)
    }
    #endif

    #if !os(tvOS)
    /// How far the messages at the top keep from both of the overlay's sides to sit centred on the top bar's row, a gap
    /// from what it holds: on iOS between its two groups of buttons, on the Mac past the title. Nil before the row has
    /// laid out.
    private var topRowSide: CGFloat? {
        #if os(macOS)
        topRowLeading.map { $0 + PlayerMetrics.overlayGap }
        #else
        guard let topRowLeading, let topRowTrailing else { return nil }
        return max(topRowLeading, topRowTrailing) + PlayerMetrics.overlayGap
        #endif
    }
    #endif

    /// A room's Play card and the sleep timer's card above the prompt button, `bottom` above the overlay's bottom, its
    /// trailing edge on the controls' (`cornerTrailing`). While narrowed beside the transport its height counts only as
    /// it shrinks (a card gone): a card narrowed there grows taller, which would then keep it narrowed where at its whole
    /// width it fits under the transport (an iPhone Duo's short landscape).
    private func corner(bottom: CGFloat) -> some View {
        let narrowed = cornerMaxWidth(bottom: bottom).map { $0 < PlayerMetrics.cardWidth } ?? false
        return VStack(alignment: .trailing, spacing: PlayerMetrics.overlayGap) {
            if let blocked = state.watch?.playBlocked {
                PlayerWatchPromptCard(blocked: blocked, store: playback.store, focus: focus)
            }
            if let stillWatching = state.stillWatching {
                PlayerStillWatchingCard(stillWatching: stillWatching, store: playback.store, focus: focus)
            }
            // Apple TV: not over an open panel or card (Watch Together, the options, the tracks); back as it closes.
            if let prompt = state.prompt, !tvPanelOpen {
                PlayerPromptButton(prompt: prompt, store: playback.store, focus: focus)
            }
        }
        .controlRegion(playback.store)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            if !narrowed || height < cornerHeight { cornerHeight = height }
        }
        // The cards' and the prompt button's glass, one column of it.
        .glassGroup(spacing: PlayerMetrics.overlayGap)
        .playbackInfoObstacle()
        // A card's width at most: the card fills it, the prompt button hugs its label within it.
        .frame(maxWidth: min(PlayerMetrics.cardWidth, cornerMaxWidth(bottom: bottom) ?? .infinity), alignment: .trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, cornerTrailing)
        .padding(.bottom, bottom)
        .animation(.easeOut(duration: 0.2), value: bottom)
        .transition(.opacity)
    }

    /// Apple TV with a panel or a menu's card open (`PlayerPanelTab`); false elsewhere.
    private var tvPanelOpen: Bool {
        #if os(tvOS)
        PlayerPanelTab(state) != nil
        #else
        false
        #endif
    }

    /// The room under the corner's card and button: above the bottom controls while they show, else the corner's margin
    /// (the controls' own distance from the safe area's bottom).
    private var cornerBottom: CGFloat {
        guard playbackControlsUp, let top = controlsTop, bounds.maxY > top else { return PlayerMetrics.cornerInset }
        return bounds.maxY - top + PlayerMetrics.overlayGap
    }

    /// The corner's distance from the overlay's trailing side: on the Mac with the controls up, the control bar's,
    /// which is narrower than a wide window; else the controls' margin.
    private var cornerTrailing: CGFloat {
        #if os(macOS)
        guard state.controlsVisible, let controlBar, bounds.maxX > controlBar.maxX else { return PlayerMetrics.edge }
        return bounds.maxX - controlBar.maxX
        #else
        PlayerMetrics.edge
        #endif
    }

    /// The widest the corner may be with its bottom `bottom` above the overlay's: on iOS, where it would reach up beside
    /// the centre transport (iPhone in landscape), the room between the transport and the trailing edge; elsewhere a
    /// card's width.
    private func cornerMaxWidth(bottom: CGFloat) -> CGFloat? {
        #if os(iOS)
        guard let transport, bounds.width > 0 else { return nil }
        let cornerTop = bounds.maxY - bottom - cornerHeight
        guard cornerTop < transport.maxY + PlayerMetrics.overlayGap else { return nil }
        return bounds.maxX - transport.maxX - PlayerMetrics.overlayGap - PlayerMetrics.edge
        #else
        nil
        #endif
    }

    #if os(iOS)
    /// A card (still watching, a room's Play) reaches up beside the centre transport and can't fit there (an iPhone
    /// Duo's short landscape, whose sensor housing narrows the room): the card answers what the transport would do, so it
    /// takes the transport's place at its whole width. Judged on the transport's last frame, which stays while it is
    /// hidden.
    private var cardHidesTransport: Bool {
        guard state.stillWatching != nil || state.watch?.playBlocked != nil, let lastTransport, bounds.width > 0 else { return false }
        let cornerTop = bounds.maxY - cornerBottom - cornerHeight
        guard cornerTop < lastTransport.maxY + PlayerMetrics.overlayGap else { return false }
        return bounds.maxX - lastTransport.maxX - PlayerMetrics.overlayGap - PlayerMetrics.edge < PlayerMetrics.cardMinWidth
    }
    #endif
}

extension PlayerUiState {
    /// The video has shown its first frame.
    var hasFirstFrame: Bool { status != .resolving && status != .opening }
}

/// The title and the episode line: under it, beside it on the Mac's title bar, above it on tvOS (AVKit's place, the
/// title on up to two lines there, 871 pt across as AVKit's).
/// VoiceOver's and Switch Control's adjustment of the timeline: ten seconds each way, whatever the seek step.
let timelineAdjustSeconds: Double = 10

/// The title and the episode line, and while this device plays a cast "Casting from <device>" after them
/// (`player.castingFrom`), semibold with its symbol so it reads at a glance beside the smaller episode line. Their text
/// is the title's colour with a light shadow, over the scrim's edge that reaches in under them (`PlayerScrim`): over a
/// white frame it reads at 4.5:1 or more.
struct PlayerTitle: View {
    let state: PlayerUiState

    @Environment(\.cast) private var cast

    var body: some View {
        let castingFrom = cast?.receiverState.state.castingFrom
        Group {
            #if os(macOS)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                title
                if let castingFrom { castingFromLine(castingFrom) }
            }
            #else
            VStack(alignment: .leading, spacing: 2) {
                title
                if let castingFrom { castingFromLine(castingFrom) }
            }
            #endif
        }
        #if os(tvOS)
        // AVKit's title width.
        .frame(maxWidth: 871, alignment: .leading)
        #endif
    }

    private var title: some View {
        Group {
            #if os(macOS)
            HStack(alignment: .firstTextBaseline, spacing: 8) { lines }
            #elseif os(tvOS)
            VStack(alignment: .leading, spacing: 6) {
                if let subtitle = state.subtitle {
                    Text(subtitle).font(PlayerMetrics.subtitleFont).lineLimit(1)
                }
                Text(state.title).font(PlayerMetrics.titleFont).lineLimit(2)
            }
            #else
            VStack(alignment: .leading, spacing: 2) { lines }
            #endif
        }
        #if !os(tvOS)
        .lineLimit(1)
        #endif
        .shadow(color: .black.opacity(0.4), radius: 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("player.title")
    }

    private func castingFromLine(_ text: String) -> some View {
        Label(text, systemImage: "tv.badge.wifi")
            .accessibilityLabel(text)
            .font(PlayerMetrics.subtitleFont.weight(.semibold))
            .lineLimit(1)
            .shadow(color: .black.opacity(0.4), radius: 6)
            .accessibilityIdentifier("player.castingFrom")
    }

    #if !os(tvOS)
    @ViewBuilder
    private var lines: some View {
        Text(state.title).font(PlayerMetrics.titleFont)
        if let subtitle = state.subtitle {
            Text(subtitle).font(PlayerMetrics.subtitleFont)
        }
    }
    #endif
}

#if !os(tvOS)
/// The position, the timeline and the time left on one line (`0:15 ━━━━─── −0:15`), the time left followed by the
/// clock time the video ends at (`−0:15 · 21:43`, `TimelineState.finishClock`) while something remains. A live
/// window's (`−1:30 ━━━━━━─`) has where the window starts on the left and no time left: the bar ends at the live edge;
/// on iOS the live label, the go-to-live button, takes the time left's place (`LiveLabel`). Time runs left to right in
/// every language: playback controls aren't mirrored (UIKit's `.playback` content), so the row keeps its order in
/// Arabic, as the keys and the video's taps that seek do. On the Mac the timeline takes the keyboard's focus
/// (`ScrubBar`).
struct TimelineRow: View {
    let state: PlayerUiState
    /// The timeline (`PlayerModel.timeline`), which the row reads for its times and its bar.
    let timeline: StoreObserver<TimelineState>
    let store: PlayerStore
    var focus: FocusState<PlayerFocus?>.Binding?

    var body: some View {
        let now = timeline.state
        HStack(spacing: PlayerMetrics.timelineSpacing) {
            Text(now.position)
                .accessibilityIdentifier("player.position")
            ScrubBar(state: state, timeline: now, store: store, focus: focus)
                .accessibilityIdentifier("player.scrub")
            if state.mode == .liveWindow {
                #if os(iOS)
                LiveLabel(timeline: timeline, store: store)
                #endif
            } else {
                Text(now.finishClock.isEmpty ? now.remaining : "\(now.remaining) · \(now.finishClock)")
                    .accessibilityLabel(now.endsAt.isEmpty ? now.remaining : "\(now.remaining), \(now.endsAt)")
                    .accessibilityIdentifier("player.remaining")
            }
        }
        .font(PlayerMetrics.timeFont)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.layoutDirection, .leftToRight)
    }
}
#endif

/// A live playback without a rewind window: "LIVE" in a red pill at the end of the top bar (`player.liveBadge`), read
/// as "Live". Nothing below: no time played, no other live label.
struct LiveBadge: View {
    var body: some View {
        Text(T.shared.player.live.badge)
            .font(PlayerMetrics.timeFont.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Palette.onVideo)
            #if os(tvOS)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            #else
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            #endif
            .background(Palette.live, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(T.shared.player.live.atEdge)
            .accessibilityIdentifier("player.liveBadge")
    }
}

/// A rewind window's go-to-live button, as on Android TV: a dot, then the store's live text
/// (`TimelineState.liveLabel`) in the timeline's time style; at the live edge the dot red and `● LIVE`, behind it the
/// dot in the text's colour muted and the time behind (`● LIVE · −0:38`, read as `Go to live`, `Live · 0:38 behind`);
/// on tvOS a pill of the transport bar's buttons, focused as they are (`PlayerFocus.goToLive`).
struct LiveLabel: View {
    /// The timeline (`PlayerModel.timeline`): the live label's text, the live edge and the spoken live text.
    let timeline: StoreObserver<TimelineState>
    let store: PlayerStore
    var focus: FocusState<PlayerFocus?>.Binding?

    var body: some View {
        let now = timeline.state
        Button {
            store.dispatch(command: PlayerCommandGoToLive.shared)
        } label: {
            content(dot: now.atLiveEdge ? AnyShapeStyle(Palette.live) : AnyShapeStyle(.secondary), label: now.liveLabel)
                #if os(tvOS)
                .frame(height: PlayerMetrics.buttonFrame)
                #else
                .frame(minHeight: PlayerMetrics.button)
                .contentShape(Rectangle())
                #endif
        }
        #if os(tvOS)
        .buttonStyle(PlayerTVButtonStyle(shape: Capsule(), insets: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)))
        #else
        .buttonStyle(PlayerPressStyle())
        #endif
        .modifier(OptionalPlayerFocus(focus: focus, target: .goToLive))
        .accessibilityLabel(T.shared.player.live.goToLive)
        .accessibilityValue(now.positionLabel)
        .accessibilityIdentifier("player.live")
    }

    private func content(dot: AnyShapeStyle, label: String) -> some View {
        HStack(spacing: PlayerMetrics.liveDotGap) {
            Circle()
                .fill(dot)
                .frame(width: PlayerMetrics.liveDot, height: PlayerMetrics.liveDot)
            Text(label)
                .font(PlayerMetrics.timeFont)
                .lineLimit(1)
        }
        .fixedSize()
    }
}

#if os(iOS) || os(macOS)
/// Back, play/pause and forward by the seek step (named for it, "Seek backward 10 seconds"), disabled while a
/// watch-together room keeps playback from this device; for an episode of a series or an item of a queue between the
/// previous and the next buttons, each enabled as `PlayerUiState.episodes` has it; on the Mac, with chapters, the
/// previous and the next chapter's buttons inside them, their tooltips the chapter each goes to
/// (`PlayerUiState.previousChapterTitle`): iOS's centre transport and the Mac's in its control bar, at each one's sizes
/// (`PlayerMetrics.transportPlay`). Apple TV has its episode buttons in its button row, and Select on the timeline
/// plays. Live, play/pause alone: nothing seeks, or a rewind window's timeline does. Left to right in every language, as
/// the timeline (`TimelineRow`). On the Mac play/pause takes the keyboard's focus from the timeline
/// (`PlayerFocus.playPause`).
struct PlayerTransport: View {
    let playback: PlayerModel
    let state: PlayerUiState
    let spacing: CGFloat
    /// The store loads: play/pause shows the spinner (iOS's centre transport, where the spinner would be).
    var loading = false
    var focus: FocusState<PlayerFocus?>.Binding?

    var body: some View {
        let store = playback.store
        let seek = Double(state.seekSeconds)
        HStack(spacing: spacing) {
            if let episodes = state.episodes {
                EpisodeButton(
                    direction: .previous,
                    episodes: episodes,
                    store: store,
                    size: PlayerMetrics.transportEpisode,
                    iconSize: PlayerMetrics.transportEpisodeIcon
                )
            }
            #if os(macOS)
            if showsChapters {
                chapterButton(previous: true)
            }
            #endif
            // A guest of a host-only room has them off, but play/pause while its player paused here alone, whose Play
            // catches up with the room (`canPlayPause`).
            HStack(spacing: spacing) {
                if state.showsSeekButtons {
                    PlayerIconButton(
                        systemImage: SkipSymbol.back(seek),
                        label: T.shared.videoControls.seekBackwardButton(seconds: SkipSymbol.seconds(seek)),
                        id: "player.rewind",
                        size: PlayerMetrics.transportSkip,
                        iconSize: PlayerMetrics.transportSkipIcon
                    ) {
                        store.dispatch(command: PlayerCommandSeekBy(seconds: -seek))
                    }
                    .transportGlass()
                    .disabled(!state.canControl)
                }
                PlayerIconButton(
                    systemImage: state.paused ? "play.fill" : "pause.fill",
                    label: state.playPauseLabel,
                    id: "player.playPause",
                    size: PlayerMetrics.transportPlay,
                    iconSize: PlayerMetrics.transportPlayIcon,
                    busy: loading
                ) {
                    store.dispatch(command: PlayerCommandTogglePause.shared)
                }
                .transportGlass()
                .modifier(OptionalPlayerFocus(focus: focus, target: .playPause))
                .disabled(!state.canPlayPause)
                if state.showsSeekButtons {
                    PlayerIconButton(
                        systemImage: SkipSymbol.forward(seek),
                        label: T.shared.videoControls.seekForwardButton(seconds: SkipSymbol.seconds(seek)),
                        id: "player.fastForward",
                        size: PlayerMetrics.transportSkip,
                        iconSize: PlayerMetrics.transportSkipIcon
                    ) {
                        store.dispatch(command: PlayerCommandSeekBy(seconds: seek))
                    }
                    .transportGlass()
                    .disabled(!state.canControl)
                }
            }
            #if os(macOS)
            if showsChapters {
                chapterButton(previous: false)
            }
            #endif
            if let episodes = state.episodes {
                EpisodeButton(
                    direction: .next,
                    episodes: episodes,
                    store: store,
                    size: PlayerMetrics.transportEpisode,
                    iconSize: PlayerMetrics.transportEpisodeIcon
                )
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    #if os(macOS)
    /// A video with chapters: the chapter buttons show.
    private var showsChapters: Bool { state.mode == .video && !state.chapters.isEmpty }

    /// The previous or the next chapter's button (`player.previousChapter`, `player.nextChapter`), its tooltip the
    /// chapter it goes to; off while a watch-together room keeps seeking from this device. The system's skip symbols
    /// with two arrows, filled as play's, so they don't take the episode buttons' one-arrow symbols beside them.
    private func chapterButton(previous: Bool) -> some View {
        PlayerIconButton(
            systemImage: previous ? "backward.end.alt.fill" : "forward.end.alt.fill",
            label: previous ? T.shared.videoControls.previousChapterButton : T.shared.videoControls.nextChapterButton,
            id: previous ? "player.previousChapter" : "player.nextChapter",
            tooltip: previous ? state.previousChapterTitle : state.nextChapterTitle
        ) {
            playback.store.dispatch(command: previous ? PlayerCommandPreviousChapter.shared : PlayerCommandNextChapter.shared)
        }
        .disabled(!state.canControl)
    }
    #endif
}

/// Starts picture in picture (or stops it), selected while it runs; disabled while the video can't go into PiP: before
/// mpv shows it, and where the device has no PiP.
struct PictureInPictureButton: View {
    let pictureInPicture: PictureInPicture

    var body: some View {
        PlayerIconButton(
            systemImage: pictureInPicture.active ? "pip.exit" : "pip.enter",
            label: T.shared.nav.player.pictureInPicture,
            id: "player.pip"
        ) {
            pictureInPicture.toggle()
        }
        .disabled(!pictureInPicture.possible && !pictureInPicture.active)
        // Its symbol alone draws the state: VoiceOver says it as selected.
        .accessibilityAddTraits(pictureInPicture.active ? .isSelected : [])
    }
}

#if os(macOS)
/// Where the video was while it plays in the picture-in-picture window: the PiP symbol (48 pt) over "Playing in
/// Picture-in-Picture", centred in the player's area behind the controls.
struct MacPictureInPicturePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pip")
                .font(.system(size: 48))
            Text(T.shared.videoControls.pipActive)
                .font(.headline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("player.pipPlaceholder")
    }
}
#endif
#endif

/// The previous or the next episode's button (`player.previous`, `player.next`) beside the transport, off and dimmed
/// without an entry that way that this device may start (`PlayerUiState.episodes`): on tvOS still focusable, its press
/// ignored (`playerOff`), so focus stays on it as it turns off and on (Previous back at the start after a restart);
/// Previous named "Restart" past the first seconds, where it restarts what plays, and both naming an episode only for
/// an episode (`EpisodeButtons.previousLabel`, `.nextLabel`, the Mac's tooltip too); on iOS on its own glass, as the
/// transport's other buttons, on tvOS the player's button style, which dims it itself, and focus as
/// `PlayerFocus.previousEpisode` or `.nextEpisode`.
struct EpisodeButton: View {
    enum Direction { case previous, next }

    let direction: Direction
    let episodes: EpisodeButtons
    let store: PlayerStore
    var size: CGFloat = PlayerMetrics.button
    var iconSize: CGFloat = PlayerMetrics.icon
    /// The player's focus (tvOS).
    var focus: FocusState<PlayerFocus?>.Binding?

    var body: some View {
        let previous = direction == .previous
        let command: any PlayerCommand = previous ? PlayerCommandPreviousEpisode.shared : PlayerCommandNextEpisode.shared
        let on = previous ? episodes.previous : episodes.next
        PlayerIconButton(
            systemImage: previous ? "backward.end.fill" : "forward.end.fill",
            label: previous ? episodes.previousLabel : episodes.nextLabel,
            id: previous ? "player.previous" : "player.next",
            size: size,
            iconSize: iconSize
        ) {
            if on { store.dispatch(command: command) }
        }
        .transportGlass()
        .modifier(OptionalPlayerFocus(focus: focus, target: previous ? .previousEpisode : .nextEpisode))
        .playerOff(!on)
    }
}

private extension View {
    /// A transport button's own glass on iOS, over the video; the Mac's sit on the control bar's, and tvOS's draw their
    /// own platter.
    @ViewBuilder
    func transportGlass() -> some View {
        #if os(iOS)
        playerGlass(in: Circle(), interactive: true)
        #else
        self
        #endif
    }
}

/// The skip symbols for the seek step (`gobackward.10`), where SF Symbols has one; each name spelled out for
/// an SF Symbols check.
enum SkipSymbol {
    private static let backs = [
        5: "gobackward.5", 10: "gobackward.10", 15: "gobackward.15", 30: "gobackward.30",
        45: "gobackward.45", 60: "gobackward.60", 75: "gobackward.75", 90: "gobackward.90",
    ]
    private static let forwards = [
        5: "goforward.5", 10: "goforward.10", 15: "goforward.15", 30: "goforward.30",
        45: "goforward.45", 60: "goforward.60", 75: "goforward.75", 90: "goforward.90",
    ]

    static func back(_ seconds: Double) -> String { step(backs, seconds) ?? "gobackward" }
    static func forward(_ seconds: Double) -> String { step(forwards, seconds) ?? "goforward" }

    /// The step in whole seconds for the seek buttons' names ("Seek backward 10 seconds").
    static func seconds(_ seconds: Double) -> String {
        seconds == seconds.rounded() ? String(Int(seconds)) : String(seconds)
    }

    private static func step(_ symbols: [Int: String], _ seconds: Double) -> String? {
        let whole = Int(seconds)
        return Double(whole) == seconds ? symbols[whole] : nil
    }
}

#if !os(tvOS)
/// The timeline, as the system player draws it: a thin bar with the played and buffered parts filled and chapter marks,
/// no thumb; it grows taller while scrubbing (and on the Mac under the pointer), the preview's thumbnail (the server's
/// frames, `ScrubState.frame`), its time, its offset and its chapter in a bubble above it. On the Mac the pointer
/// resting over the bar shows the same for the second under it (`PlayerCommandHoverTimeline`). Drag or click to scrub,
/// committed on release, anywhere in a band a button tall (44 pt on iOS, 28 on the Mac) around the drawn bar; on the Mac
/// the band reaches into the control bar's gaps above and below it, so the bar keeps its place. VoiceOver and Switch
/// Control adjust it: up and down seek by the seek step at once, and a double-tap does nothing (a tap at its middle
/// would seek there). (Apple TV's is `TVTimeline`.)
///
/// On the Mac it takes the keyboard's focus (Tab; a ring around it then): Left and Right seek through the store's keys
/// as on the video, Up hides the controls (or goes to the prompt button while it shows), Down goes to play/pause.
private struct ScrubBar: View {
    let state: PlayerUiState
    /// The timeline as its row read it (`PlayerModel.timeline`).
    let timeline: TimelineState
    let store: PlayerStore
    var focus: FocusState<PlayerFocus?>.Binding?

    #if os(macOS)
    @State private var hovered = false
    /// The 4 pt step of the bar the pointer rests over (`PlayerCommandHoverTimeline`), -1 off it.
    @State private var hoverStep = -1
    #endif
    /// A drag of the bar is under way; SwiftUI resets it as the drag ends, released or cancelled.
    @GestureState private var dragging = false
    /// The store scrubs for a drag of the bar's, until its release commits it (`cancelScrub` otherwise).
    @State private var scrubbing = false

    /// The bar's band as drawn, with the bubble above it.
    private static let drawn = PlayerMetrics.button * 0.6

    var body: some View {
        GeometryReader { proxy in
            track(raised: isRaised)
                .frame(height: Self.drawn)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                #if os(macOS)
                .onContinuousHover { phase in hover(phase, width: proxy.size.width) }
                #endif
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragging) { _, dragging, _ in dragging = true }
                        .onChanged { drag in
                            scrubbing = true
                            let fraction = min(max(drag.location.x / max(proxy.size.width, 1), 0), 1)
                            store.dispatch(command: PlayerCommandScrubTo(fraction: fraction))
                        }
                        .onEnded { _ in
                            scrubbing = false
                            store.dispatch(command: PlayerCommandCommitScrub.shared)
                        }
                )
                // A guest in a host-only room can't seek (`PlayerUiState.canSeek`).
                .disabled(!state.canSeek)
        }
        // A drag that ended without its release (the system cancelled it, seeking went off meanwhile) or whose bar went
        // leaves no scrub behind. Checked once the event's `onEnded` has run, whichever of the two SwiftUI runs first.
        .onChange(of: dragging) { _, dragging in
            if !dragging { Task { cancelScrub() } }
        }
        .onDisappear { cancelScrub() }
        .frame(height: PlayerMetrics.button)
        #if os(macOS)
        .onHover { hovered = $0 }
        .modifier(MacTimelineKeys(state: state, store: store, focus: focus))
        #endif
        #if DEBUG
        // UI tests (XCUITest's pointer doesn't reach the Mac's bar; a touch screen has none): `-timelinePreview
        // <fraction>` shows the preview of that place as a pointer resting there does.
        .onAppear {
            let fraction = UserDefaults.standard.double(forKey: "timelinePreview")
            guard fraction > 0 else { return }
            #if os(macOS)
            hovered = true
            #endif
            store.dispatch(command: PlayerCommandHoverTimeline(fraction: KotlinDouble(value: fraction)))
        }
        #endif
        .accessibilityElement()
        .accessibilityLabel(T.shared.videoControls.timelineSlider)
        .accessibilityValue(timeline.positionLabel)
        .accessibilityAdjustableAction { direction in
            guard state.canSeek else { return }
            switch direction {
            case .increment: store.dispatch(command: PlayerCommandSeekBy(seconds: timelineAdjustSeconds))
            case .decrement: store.dispatch(command: PlayerCommandSeekBy(seconds: -timelineAdjustSeconds))
            @unknown default: break
            }
        }
        // Without an action of its own, a double-tap would tap the bar's middle: a seek to the middle of the video.
        .accessibilityAction {}
        #if os(macOS)
        .padding(.vertical, (Self.drawn - PlayerMetrics.button) / 2)
        #endif
    }

    /// Ends the store's scrub of a drag that never came to its release: seeking went off meanwhile commits it (the store
    /// refuses the seek where seeking went), anything else drops it (`PlayerCommandCancelScrub`).
    private func cancelScrub() {
        guard scrubbing else { return }
        scrubbing = false
        store.dispatch(command: state.canSeek ? PlayerCommandCancelScrub.shared : PlayerCommandCommitScrub.shared)
    }

    #if os(macOS)
    /// The pointer over a video's bar: the store hears the 4 pt step it rests over, for the bar's tooltip.
    private func hover(_ phase: HoverPhase, width: CGFloat) {
        guard state.canSeek, state.mode == .video else { return }
        var step = -1
        if case .active(let at) = phase { step = Int(at.x / 4) }
        guard step != hoverStep else { return }
        hoverStep = step
        let fraction = step < 0 || width <= 0 ? nil : KotlinDouble(value: min(max((Double(step) * 4 + 2) / width, 0), 1))
        store.dispatch(command: PlayerCommandHoverTimeline(fraction: fraction))
    }
    #endif

    /// The pointer is over the bar (the Mac).
    private var isRaised: Bool {
        #if os(macOS)
        hovered
        #else
        false
        #endif
    }

    /// The bar, and where its bubble goes; `raised` (the Mac's pointer over it) thickens the bar, scrubbing more so.
    /// While the video plays the played part moves on at each frame between the store's reports
    /// (`TimelineState.progressNow`).
    private func track(raised: Bool) -> some View {
        let scrub = timeline.scrub
        #if os(macOS)
        let height: CGFloat = scrub != nil ? 10 : raised ? 8 : 5
        #else
        let height: CGFloat = scrub != nil ? 14 : 6
        #endif
        return GeometryReader { proxy in
            let width = proxy.size.width
            TimelineView(.animation(paused: timeline.motion == nil)) { _ in
                let progress = Double(scrub?.progress ?? timeline.progressNow())
                ZStack(alignment: .leading) {
                    Rectangle().fill(Palette.onVideo.opacity(0.25))
                    Rectangle().fill(Palette.onVideo.opacity(0.4))
                        .frame(width: width * clamp(Double(timeline.buffered)))
                    Rectangle().fill(Palette.onVideo)
                        .frame(width: width * clamp(progress))
                    // Chapter starts as gaps in the bar.
                    ForEach(Array(timeline.chapters.enumerated()), id: \.offset) { _, mark in
                        Rectangle()
                            .fill(.black.opacity(0.6))
                            .frame(width: 2)
                            .offset(x: width * CGFloat(truncating: mark) - 1)
                    }
                }
            }
            .frame(height: height)
            .clipShape(Capsule())
            .frame(maxHeight: .infinity)
            // The scrub's preview, else (the Mac) the second under the pointer: its bubble drawn over the glass that
            // holds the timeline (`scrubBubble`).
            .anchorPreference(key: ScrubBubbleKey.self, value: .bounds) { bar in
                (scrub ?? timeline.hover).map { ScrubBubblePlace(scrub: $0, bar: bar) }
            }
        }
        .animation(.easeOut(duration: 0.15), value: height)
    }

    private func clamp(_ value: Double) -> CGFloat { CGFloat(min(max(value, 0), 1)) }
}

#if os(macOS)
/// The Mac timeline's keyboard focus (`ScrubBar`): focusable as `PlayerFocus.scrub` (Tab reaches it where the system's
/// keyboard navigation is on), its own ring showing it. Up hides the controls, or goes to the prompt button while it
/// shows; Down goes to play/pause; every other key goes to the store as on the video (Left and Right seek).
private struct MacTimelineKeys: ViewModifier {
    let state: PlayerUiState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding?

    func body(content: Content) -> some View {
        if let focus {
            content
                .focusable()
                .focused(focus, equals: .scrub)
                .focusRing(radius: 8)
                .onKeyPress(phases: .all) { press in
                    handle(press, focus: focus) ? .handled : .ignored
                }
        } else {
            content
        }
    }

    private func handle(_ press: KeyPress, focus: FocusState<PlayerFocus?>.Binding) -> Bool {
        // The Mac's arrow keys come flagged as the numeric pad's: only a held Shift, Control, Option or Command counts.
        if press.phase != .up, press.modifiers.isDisjoint(with: [.shift, .control, .option, .command]) {
            switch press.key {
            case .upArrow:
                if state.prompt != nil {
                    focus.wrappedValue = .prompt
                } else {
                    store.dispatch(command: PlayerCommandHideControls.shared)
                }
                return true
            case .downArrow:
                focus.wrappedValue = .playPause
                return true
            default:
                break
            }
        }
        return PlayerKeys.handle(press, to: store)
    }
}
#endif

/// Where the timeline's bubble goes: the scrub or hover it shows, the bar's band (`ScrubBar`) and the glass that holds
/// the bar (`scrubBubbleGlass`).
private struct ScrubBubblePlace {
    let scrub: ScrubState
    let bar: Anchor<CGRect>
    var glass: Anchor<CGRect>?
}

private struct ScrubBubbleKey: PreferenceKey {
    static var defaultValue: ScrubBubblePlace? { nil }

    static func reduce(value: inout ScrubBubblePlace?, nextValue: () -> ScrubBubblePlace?) {
        value = value ?? nextValue()
    }
}

extension View {
    /// Marks this view as the glass that holds the timeline (the Mac's control bar, iOS's timeline capsule): the
    /// timeline's bubble goes above its top edge, so no edge of the glass crosses the thumbnail or the time, and
    /// neither covers a control in it.
    func scrubBubbleGlass() -> some View {
        transformAnchorPreference(key: ScrubBubbleKey.self, value: .bounds) { place, glass in place?.glass = glass }
    }

    /// Draws the timeline's bubble over this view and everything in it: called on the controls' container, so no
    /// control drawn after the timeline (iOS's centre transport) crosses it.
    func scrubBubble() -> some View {
        overlayPreferenceValue(ScrubBubbleKey.self, alignment: .topLeading) { place in
            if let place {
                GeometryReader { proxy in
                    let bar = proxy[place.bar]
                    ScrubBubble(scrub: place.scrub, bar: bar, top: place.glass.map { proxy[$0].minY } ?? bar.minY)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

/// The scrub preview (or the second the Mac's pointer rests over) centred over its place, kept inside the bar, 8 pt
/// above the glass that holds the bar: the server's frame there (`ScrubThumbnail`), then its time, its offset and its
/// chapter on the glass.
private struct ScrubBubble: View {
    let scrub: ScrubState
    /// The bar's band, in the coordinates of the view the bubble is drawn over.
    let bar: CGRect
    /// The top edge of the glass that holds the bar, in the same coordinates.
    let top: CGFloat

    @State private var size = CGSize.zero

    var body: some View {
        VStack(spacing: 6) {
            if let frame = scrub.frame {
                ScrubThumbnail(frame: frame, width: Self.thumbnailWidth)
            }
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text(scrub.position)
                    if !scrub.offset.isEmpty { Text(scrub.offset) }
                }
                .font(PlayerMetrics.timeFont)
                if let chapter = scrub.chapter {
                    Text(chapter).font(.caption).lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .playerGlass(in: Capsule())
        }
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .offset(x: bar.minX + min(max(anchor - size.width / 2, 0), max(bar.width - size.width, 0)), y: top - (size.height + 8))
        .accessibilityHidden(true)
    }

    /// The preview's place along the bar.
    private var anchor: CGFloat { bar.width * CGFloat(min(max(Double(scrub.progress), 0), 1)) }

    /// The thumbnail's width: Plezy's 160 pt.
    private static let thumbnailWidth: CGFloat = 160
}
#endif

/// The loading spinner with the store's text ("Preparing stream…", "Buffering…").
private struct LoadingOverlay: View {
    let text: String?

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .largeSpinner()
                .tint(Palette.onVideo)
            if let text { LoadingText(text: text) }
        }
    }
}

/// The store's loading text on its glass: under the spinner, or on iOS with the controls up among the messages at the
/// top (`PlayerOverlay`).
private struct LoadingText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .playerGlass(in: Capsule())
            .accessibilityIdentifier("player.loading")
    }
}

#if os(iOS)
/// What takes the middle alone (an error) centred in the room from `top` (under the top bar and the messages there) to
/// the bottom, scrolling where it is taller than that room.
private struct CentreAlone: ViewModifier {
    let top: CGFloat

    func body(content: Content) -> some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, top)
        .padding(.bottom, PlayerMetrics.edge)
    }
}
#endif
