import SwiftUI
import PlezyKit

#if os(macOS)
/// The Mac's controls (see `PlayerOverlay`).
struct DesktopControls: View {
    let playback: PlayerModel
    let state: PlayerUiState
    /// The keyboard's focus among the controls: the timeline and play/pause (`ScrubBar`).
    let focus: FocusState<PlayerFocus?>.Binding
    /// The control bar's frame in global coordinates, as it lays out: the subtitle lift, and the corner directly above
    /// it (`PlayerOverlay`).
    let onControlBar: (CGRect) -> Void
    /// How far the title row's buttons and the title's text reach from the overlay's leading side, as they lay out: the
    /// messages at the top go on the row where they clear them (`PlayerOverlay`).
    let onTopRowLeading: (CGFloat) -> Void

    /// The bottom of the title row (global), as it last laid out: how far the scrim's top edge reaches (`PlayerScrim`).
    @State private var titleBottom: CGFloat?

    var body: some View {
        let store = playback.store
        if state.controlsVisible {
            // The window's title bar is the top safe area (the window extends the player under it): the title sits
            // on its line, beside the window's buttons. In full screen there is none, and the row keeps its height in a
            // window around the copies of the buttons (`PlayerWindowButtons`).
            GeometryReader { proxy in
                let titleBar = proxy.safeAreaInsets.top
                ZStack {
                    PlayerScrim(titleBottom: titleBottom)
                    VStack(spacing: 0) {
                        DesktopTitleBar(
                            state: state,
                            store: store,
                            pictureInPicture: playback.surface.pictureInPicture,
                            height: titleBar,
                            onReach: onTopRowLeading
                        )
                        .controlRegion(store)
                        .playbackInfoObstacle()
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { titleBottom = $0 }
                        Spacer(minLength: 0)
                        // Over the error, the title row alone (`showsPlaybackControls`); nothing before the first frame.
                        if state.showsPlaybackControls && state.hasFirstFrame {
                            ControlBar(playback: playback, state: state, focus: focus)
                                .controlRegion(store)
                                .playbackInfoObstacle()
                                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onControlBar($0) }
                                .padding(.horizontal, 32)
                                .padding(.bottom, 20)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .transition(.opacity)
        }
    }
}

/// Back, picture in picture (as on iOS, beside back; not over the error) and the title, on the line of the window's
/// buttons (the window has no toolbar or title while the player is up), live without a rewind window the LIVE pill at
/// its end (`LiveBadge`); in full screen the row hosts copies of the buttons where the title bar has them in a window,
/// and keeps its height. Back sits in the row's middle, so the messages at the top centred in the row are level with it
/// (`PlayerOverlay`).
struct DesktopTitleBar: View {
    let state: PlayerUiState
    let store: PlayerStore
    let pictureInPicture: PictureInPicture
    /// The title bar's height; none in full screen.
    let height: CGFloat
    /// The title's trailing edge in the overlay's coordinate space, as it lays out: how far the row's buttons and the
    /// title's text reach from its leading side.
    let onReach: (CGFloat) -> Void

    @Environment(\.playerWindowButtons) private var windowButtons

    /// The row's height: the title bar's, `titleBar`; in full screen, where there is none, the window's buttons' row's.
    static func height(titleBar: CGFloat, windowButtons: PlayerWindowButtons?) -> CGFloat {
        titleBar > 0 ? titleBar : windowButtons?.rowHeight ?? PlayerWindowButtons.titleBarHeight
    }

    var body: some View {
        HStack(spacing: 8) {
            PlayerIconButton(systemImage: "chevron.backward", label: T.shared.nav.player.close, id: "player.back") {
                store.dispatch(command: PlayerCommandClose.shared)
            }
            if state.showsPlaybackControls {
                PictureInPictureButton(pictureInPicture: pictureInPicture)
                CastButton(look: .player, id: "player.cast")
            }
            PlayerTitle(state: state)
                .onGeometryChange(for: CGFloat?.self) { proxy in
                    proxy.bounds(of: .named(PlayerOverlay.space)).map { proxy.size.width - $0.minX }
                } action: { if let reach = $0 { onReach(reach) } }
            Spacer(minLength: 0)
            if state.mode == .live { LiveBadge() }
        }
        .padding(.leading, 76)
        .padding(.trailing, 16)
        .frame(height: Self.height(titleBar: height, windowButtons: windowButtons))
        .overlay(alignment: .topLeading) {
            if let windowButtons {
                PlayerWindowButtonsHost(buttons: windowButtons)
                    .frame(width: windowButtons.view.frame.width, height: windowButtons.view.frame.height)
                    .padding(.leading, windowButtons.origin.x)
                    .padding(.top, windowButtons.origin.y)
            }
        }
    }
}

/// The floating control bar (`player.bar.bottom`): the volume, back/play/forward (between the previous and the next
/// chapter for a video with chapters, and between the previous and the next episode for an episode of a series; back,
/// play/pause, forward and the timeline disabled while a watch-together room keeps playback from this device), the room
/// pill, the menus, the options menu (with the playback info) and full screen; under them the timeline with its times
/// inline. Live, no timeline: play/pause stays in the middle and the other buttons in their places (the LIVE pill is
/// the title bar's); with a rewind window the timeline is back as the window and the go-to-live label comes right after
/// play/pause. Clicks between the buttons are the bar's, not the video's (no play/pause, no full screen).
private struct ControlBar: View {
    let playback: PlayerModel
    let state: PlayerUiState
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        let store = playback.store
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                VolumeControl(volume: state.volume, store: store)
                    .frame(maxWidth: .infinity, alignment: .leading)
                PlayerTransport(playback: playback, state: state, spacing: 14, focus: focus)
                HStack(spacing: 4) {
                    if state.mode == .liveWindow {
                        LiveLabel(timeline: playback.timeline, store: store)
                            .padding(.leading, PlayerMetrics.liveLabelGap)
                        Spacer(minLength: 8)
                    }
                    PlayerWatchIndicator(state: state, store: store)
                    PlayerMenuBar(playback: playback, state: state)
                    PlayerIconButton(
                        systemImage: state.fullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                        label: state.fullscreen ? T.shared.nav.player.exitFullscreen : T.shared.nav.player.fullscreen,
                        id: "player.fullscreen"
                    ) {
                        store.dispatch(command: PlayerCommandToggleFullscreen.shared)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if state.showsTimeline {
                TimelineRow(state: state, timeline: playback.timeline, store: store, focus: focus)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: 720)
        .playerGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .scrubBubbleGlass()
        .scrubBubble()
        .contentShape(Rectangle())
        .onTapGesture {}
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("player.bar.bottom")
        // The timeline moves as the video plays: followed while the bar shows it.
        .task { await playback.timeline.observe() }
    }
}

/// Mute and a volume slider (the Mac; phones and TVs have hardware volume) from 0 to the volume's top
/// (`VolumeState.maxPercent`), marked at 100 % with a short bar when the top is above it.
private struct VolumeControl: View {
    let volume: VolumeState
    let store: PlayerStore

    var body: some View {
        HStack(spacing: 4) {
            PlayerIconButton(
                systemImage: volume.muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: volume.muted ? T.shared.player.volume.unmute : T.shared.player.volume.mute,
                id: "player.mute"
            ) {
                store.dispatch(command: PlayerCommandToggleMute.shared)
            }
            Slider(
                value: Binding(
                    get: { volume.muted ? 0 : Double(volume.fraction) },
                    set: { store.dispatch(command: PlayerCommandSetVolume(percent: $0 * Double(volume.maxPercent))) }
                )
            )
            .controlSize(.mini)
            .frame(width: PlayerMetrics.volumeWidth)
            .background {
                if volume.maxPercent > 100 {
                    GeometryReader { proxy in
                        // The track runs between the knob's centres at either end.
                        let inset = PlayerMetrics.volumeKnobRadius
                        let x = inset + (proxy.size.width - 2 * inset) * 100 / CGFloat(volume.maxPercent)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Palette.onVideo.opacity(0.6))
                            .frame(width: 2, height: 12)
                            .position(x: x, y: proxy.size.height / 2)
                    }
                }
            }
            .accessibilityLabel(T.shared.player.volume.title)
            .accessibilityValue(volume.label)
            .accessibilityIdentifier("player.volume")
        }
    }
}
#endif
