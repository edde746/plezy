import SwiftUI
import PlezyKit

#if os(iOS)
/// The iOS and iPadOS controls (see `PlayerOverlay`). An iPad's pointer resting on them keeps them up
/// (`controlRegion`). A swipe up on the bottom bar opens the chapters (else the queue) as a tap on its button does
/// (`ContentStripSwipe`: past half its 150 pt reach or flung faster than 200 pt/s; a mostly sideways drag, a scrub, is
/// none of it).
struct TouchControls: View {
    let playback: PlayerModel
    let state: PlayerUiState
    /// An error takes the middle (`PlayerOverlay`): no transport, no bottom bar.
    let centreAlone: Bool
    /// Picture in picture runs: close and its button alone, up all along; no menus, transport or bottom bar.
    let pictureInPicture: Bool
    /// A card takes the centre transport's place (`PlayerOverlay`): no transport.
    let transportHidden: Bool
    let onControlsTop: (CGFloat) -> Void
    /// The trailing edge of the title lines and the top of the timeline in global coordinates, as they lay out: the
    /// corner goes between the two where it fits (`PlayerOverlay`).
    let onTitleTrailing: (CGFloat) -> Void
    let onTimelineTop: (CGFloat) -> Void
    /// How far the top bar's leading group of buttons reaches from the overlay's leading side, and its trailing group
    /// from the trailing side, as they lay out: the messages at the top go between the two where they fit
    /// (`PlayerOverlay`).
    let onTopRowLeading: (CGFloat) -> Void
    let onTopRowTrailing: (CGFloat) -> Void
    /// The centre transport's frame in global coordinates, as it lays out; nil once it is gone.
    let onTransport: (CGRect?) -> Void

    /// The top of the bottom bar (the title lines'), global, as it last laid out: how far the scrim's bottom edge
    /// reaches (`PlayerScrim`).
    @State private var titleTop: CGFloat?

    var body: some View {
        let store = playback.store
        let bottomBar = !centreAlone && !pictureInPicture && state.hasFirstFrame
        if state.controlsVisible || pictureInPicture {
            ZStack {
                PlayerScrim(titleTop: bottomBar ? titleTop : nil)
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        HStack(spacing: 0) {
                            PlayerIconButton(systemImage: "xmark", label: T.shared.nav.player.close, id: "player.back") {
                                store.dispatch(command: PlayerCommandClose.shared)
                            }
                            // Over the error, close alone (`showsPlaybackControls`): nothing to act on but the error.
                            if state.showsPlaybackControls {
                                PictureInPictureButton(pictureInPicture: playback.surface.pictureInPicture)
                                if !pictureInPicture {
                                    CastButton(look: .player, id: "player.cast")
                                }
                            }
                        }
                        .playerGlass(in: Capsule())
                        .onGeometryChange(for: CGFloat?.self) { proxy in
                            proxy.bounds(of: .named(PlayerOverlay.space)).map { proxy.size.width - $0.minX }
                        } action: { if let reach = $0 { onTopRowLeading(reach) } }
                        Spacer(minLength: 0)
                        HStack(alignment: .top, spacing: 12) {
                            if state.mode == .live && !pictureInPicture {
                                LiveBadge().frame(height: PlayerMetrics.button)
                            }
                            if state.showsPlaybackControls && !pictureInPicture {
                                PlayerWatchIndicator(state: state, store: store)
                                PlayerMenuBar(playback: playback, state: state)
                                    .playerGlass(in: Capsule())
                            }
                        }
                        .onGeometryChange(for: CGFloat?.self) { proxy in
                            proxy.bounds(of: .named(PlayerOverlay.space)).map(\.maxX)
                        } action: { if let reach = $0 { onTopRowTrailing(reach) } }
                    }
                    // The capsules' glass, one row of it.
                    .glassGroup(spacing: 12)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("player.bar.top")
                    .controlRegion(store)
                    .playbackInfoObstacle()
                    Spacer(minLength: 0)
                    if bottomBar {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 10) {
                                PlayerTitle(state: state)
                            }
                            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxX } action: { onTitleTrailing($0) }
                            // Live without a window: no timeline row and no label in its place (the top bar's LIVE).
                            Group {
                                if !state.showsTimeline {
                                    Color.clear.frame(height: 0)
                                } else {
                                    TimelineRow(state: state, timeline: playback.timeline, store: store)
                                        .padding(.horizontal, 18)
                                        .frame(minHeight: 44)
                                        .playerGlass(in: Capsule())
                                        .scrubBubbleGlass()
                                }
                            }
                            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { onTimelineTop($0) }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("player.bar.bottom")
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: {
                            titleTop = $0
                            onControlsTop($0)
                        }
                        .controlRegion(store)
                        .playbackInfoObstacle()
                        .contentShape(Rectangle())
                        .simultaneousGesture(listSwipe, including: listMenu == nil ? .subviews : .all)
                        // The timeline moves as the video plays: followed while this bar shows it.
                        .task { await playback.timeline.observe() }
                    }
                }
                .padding(.horizontal, PlayerMetrics.edge)
                .padding(.vertical, PlayerMetrics.barInset)
                if !centreAlone && !pictureInPicture && !transportHidden && state.hasFirstFrame {
                    CentreTransport(playback: playback, state: state, onFrame: onTransport)
                        .controlRegion(store)
                        .playbackInfoObstacle()
                }
            }
            // The timeline's preview over the centre transport too.
            .scrubBubble()
            .transition(.opacity)
        }
    }
}

private extension TouchControls {
    /// What a swipe up on the bottom bar opens: the chapters, else the queue; nil without either.
    var listMenu: PlayerMenu? {
        !state.chapters.isEmpty ? .chapters : !state.queue.isEmpty ? .queue : nil
    }

    /// The swipe up that opens `listMenu` (`ContentStripSwipe`).
    var listSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { drag in
                let dy = drag.translation.height
                guard let menu = listMenu, abs(dy) > abs(drag.translation.width) * 1.5 else { return }
                // The velocity over the drag's last moment, as SwiftUI predicts the end a quarter second on.
                let velocity = Float((drag.predictedEndTranslation.height - dy) * 4)
                let rule = ContentStripSwipe.shared
                if rule.opens(progress: rule.drag(progress: 0, dy: Float(dy)), velocity: velocity) {
                    playback.store.dispatch(command: PlayerCommandOpenMenu(menu: menu))
                }
            }
    }
}

/// The transport (`PlayerTransport`) in the middle of the video, as the system player has it, each button on its own
/// glass, the episode buttons a size smaller than the seek buttons. While the store loads, the spinner is in
/// play/pause, where it would otherwise sit behind the button.
private struct CentreTransport: View {
    let playback: PlayerModel
    let state: PlayerUiState
    /// The row's frame in global coordinates, as it lays out, nil once it is gone: the up-next card and the messages at
    /// the top keep clear of it.
    let onFrame: (CGRect?) -> Void

    @Environment(\.horizontalSizeClass) private var widthClass
    @Environment(\.verticalSizeClass) private var heightClass

    var body: some View {
        PlayerTransport(playback: playback, state: state, spacing: spacing, loading: state.centre is PlayerCentreLoading)
            // The buttons' glass, one row of it.
            .glassGroup(spacing: spacing)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("player.transport")
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrame($0) }
            .onDisappear { onFrame(nil) }
    }

    /// The system player's 36 pt between three buttons, and between five on an iPad's full screen (regular width and
    /// height); 16 pt between five elsewhere: 336 pt in all, within the 16 pt margins of a 375 pt iPhone in portrait,
    /// and in landscape leaving up next room beside them.
    private var spacing: CGFloat {
        state.episodes == nil || (widthClass == .regular && heightClass == .regular) ? 36 : 16
    }
}
#endif
