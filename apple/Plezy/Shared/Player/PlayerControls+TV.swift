import SwiftUI
import PlezyKit

#if os(tvOS)
/// The Apple TV's transport bar, AVKit's (as measured): the chapters, the queue and the playback info open in the
/// panel across the bottom by Down from the timeline (live: play/pause), as Down from AVKit's timeline opens its info
/// panel, on its first tab (the chapters where the video has them); the playback info also from the options menu. From
/// the bottom up, the timeline with its times under it (`TVTimeline`), and over it the episode line and the title on the
/// left, the buttons on the right, their bottoms level: the room pill, the previous and the next episode (for an episode
/// of a series), then the menus (`PlayerMenuBar`). The timeline takes focus when the controls come up: Select plays or
/// pauses, left and right on the click-pad scrub (the store's keymap), up reaches the buttons (a disabled episode button
/// takes no focus, and one that turns off under focus hands it to the timeline: `PlayerFocus.target`). While a menu is
/// open the bar stays out of focus's way; as it closes, focus goes back to the button that opened it
/// (`PlayerFocus.panelOpener`), as AVKit's does. Live, no timeline: play/pause in its place takes focus as it would,
/// and the LIVE pill comes first among the buttons (`LiveBadge`). With a rewind window the timeline is back as the
/// window (its left and right scrub within it as a video's) and the live label, the go-to-live button, comes first
/// among the buttons instead.
struct TVControls: View {
    let playback: PlayerModel
    let state: PlayerUiState
    let focus: FocusState<PlayerFocus?>.Binding
    let onControlsTop: (CGFloat) -> Void
    /// The top of the buttons (global), which a menu opens above.
    let onButtonsTop: (CGFloat) -> Void

    /// The top of the title lines (global), as they last laid out: how far the scrim's bottom edge reaches
    /// (`PlayerScrim`).
    @State private var titleTop: CGFloat?

    var body: some View {
        let store = playback.store
        // Over the error the title alone, where the bar has it (`showsPlaybackControls`): no buttons or timeline (live:
        // play/pause and the live label) behind it to focus.
        if state.controlsVisible, !state.showsPlaybackControls {
            ZStack(alignment: .bottomLeading) {
                PlayerScrim(titleTop: titleTop)
                PlayerTitle(state: state)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { titleTop = $0 }
                    .playbackInfoObstacle()
            }
            .transition(.opacity)
        } else if state.controlsVisible {
            ZStack(alignment: .bottom) {
                PlayerScrim(titleTop: titleTop)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 32) {
                        PlayerTitle(state: state)
                        Spacer(minLength: 32)
                        HStack(spacing: PlayerMetrics.menuSpacing) {
                            if state.mode == .live {
                                LiveBadge()
                            } else if state.mode == .liveWindow {
                                LiveLabel(timeline: playback.timeline, store: store, focus: focus)
                            }
                            PlayerWatchIndicator(state: state, store: store)
                            if let episodes = state.episodes {
                                // Previous before next in every language, as the timeline under them runs.
                                HStack(spacing: PlayerMetrics.menuSpacing) {
                                    EpisodeButton(direction: .previous, episodes: episodes, store: store, focus: focus)
                                    EpisodeButton(direction: .next, episodes: episodes, store: store, focus: focus)
                                }
                                .environment(\.layoutDirection, .leftToRight)
                            }
                            CastButton(look: .player, id: "player.cast")
                            PlayerMenuBar(playback: playback, state: state, focus: focus)
                        }
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { onButtonsTop($0) }
                    }
                    .focusSection()
                    Group {
                        // Nothing to drive before the first frame.
                        if !state.hasFirstFrame {
                            EmptyView()
                        } else if !state.showsTimeline {
                            HStack(spacing: PlayerMetrics.liveLabelGap) {
                                PlayerIconButton(
                                    systemImage: state.paused ? "play.fill" : "pause.fill",
                                    label: state.playPauseLabel,
                                    id: "player.playPause"
                                ) {
                                    store.dispatch(command: PlayerCommandTogglePause.shared)
                                }
                                .focused(focus, equals: .playPause)
                                .playerDisabled(!state.canPlayPause)
                                .onMoveCommand { if $0 == .down { openPanel(state: state, store: store) } }
                            }
                        } else {
                            TVTimeline(state: state, timeline: playback.timeline, store: store, focus: focus)
                        }
                    }
                    .padding(.top, 32)
                }
                .playbackInfoObstacle()
                // 44 pt above the screen's bottom, inside the bottom safe area, where AVKit's Info tab ended.
                .padding(.bottom, 44)
                .ignoresSafeArea(edges: .bottom)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: {
                    titleTop = $0
                    onControlsTop($0)
                }
                // The timeline moves as the video plays: followed while the bar shows it.
                .task { await playback.timeline.observe() }
            }
            // Under a menu only its own controls take focus (over the error the bar is the title alone, above); under a
            // menu the bar keeps its strength.
            .disabled(PlayerPanelTab(state) != nil)
            .environment(\.playerControlsAside, PlayerPanelTab(state) != nil)
            .transition(.opacity)
        }
    }
}

/// Apple TV's timeline, AVKit's (as measured): a 14 pt capsule across the safe area with a white playhead,
/// 2 × 17 pt, on it always; the played part (and the buffered part past it) and the chapter starts, as gaps, show only
/// while the timeline has focus or a scrub runs, which is how its focus shows (the bar keeps its height). Under it the
/// elapsed time centred on the playhead (the paused symbol after it) and the time left at the bar's end, white with
/// focus, secondary without; the time left gives way where the elapsed time reaches it. A live window's
/// (`PlaybackMode.liveWindow`) has where the window starts at the bar's start in the time left's style, and under the
/// playhead only the paused symbol and a scrub's preview (`−0:40`, `LIVE`); the window's start gives way to those. While
/// scrubbing the playhead and the elapsed time are the preview's, and above the playhead its offset and its chapter. The
/// bar is a focusable button: Select commits a scrub or, with none, plays or pauses (the bar is named by that action);
/// left and right on the click-pad scrub through the store's keymap; Down, with no scrub, opens the panel across the
/// bottom (`openPanel`). The time left carries the clock time the video ends at (`−0:15 · 21:43`). The
/// times and the paused symbol sit outside the
/// button: a button whose label held them, changing as it played, reported no focus that came to it after a change (an
/// episode's Previous, then Down: the timeline drew its focus and XCUITest found no focused element), as a panel
/// row relabelled for another page did (`PlayerTVPanel`'s `.id`). VoiceOver's Left and Right move its cursor, not focus:
/// its swipe up and down on the bar seek by the seek step at once instead. Left to right in every language, as the
/// remote's Left and Right and its swipes scrub (`TimelineRow`).
private struct TVTimeline: View {
    let state: PlayerUiState
    /// The timeline (`PlayerModel.timeline`), which the bar and its times read.
    let timeline: StoreObserver<TimelineState>
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    @State private var width: CGFloat = 0
    @State private var elapsedWidth: CGFloat = 0
    @State private var remainingWidth: CGFloat = 0
    @State private var markerWidth: CGFloat = 0

    private static let bar: CGFloat = 14
    private static let needle = CGSize(width: 2, height: 17)
    private static let timesGap: CGFloat = 8
    private static let markerGap: CGFloat = 6

    var body: some View {
        let now = timeline.state
        // While the video plays the playhead moves on at each frame between the store's reports
        // (`TimelineState.progressNow`), and the elapsed time under it with it.
        TimelineView(.animation(paused: now.motion == nil)) { _ in
            content(now)
        }
    }

    private func content(_ now: TimelineState) -> some View {
        let scrub = now.scrub
        let lit = focus.wrappedValue == .scrub || scrub != nil
        let playhead = width * clamp(Double(scrub?.progress ?? now.progressNow()))
        let elapsedX = min(max(playhead - elapsedWidth / 2, 0), max(width - elapsedWidth, 0))
        return VStack(alignment: .leading, spacing: Self.timesGap) {
            Button {
                if !RemotePress.send(.select, to: store) { store.dispatch(command: PlayerCommandTogglePause.shared) }
            } label: {
                track(now, playhead: playhead, lit: lit)
            }
            .buttonStyle(VideoLayerButtonStyle())
            .focused(focus, equals: .scrub)
            .onMoveCommand { direction in
                switch direction {
                case .left: RemotePress.send(.left, to: store)
                case .right: RemotePress.send(.right, to: store)
                case .down where scrub == nil: openPanel(state: state, store: store)
                default: break
                }
            }
            .accessibilityLabel(state.playPauseLabel)
            .accessibilityValue(now.positionLabel)
            .accessibilityAdjustableAction { direction in
                guard state.canSeek else { return }
                switch direction {
                case .increment: store.dispatch(command: PlayerCommandSeekBy(seconds: timelineAdjustSeconds))
                case .decrement: store.dispatch(command: PlayerCommandSeekBy(seconds: -timelineAdjustSeconds))
                @unknown default: break
                }
            }
            .accessibilityIdentifier("player.scrub")
            .overlay(alignment: .bottomLeading) {
                if let scrub {
                    marker(scrub)
                        .offset(x: min(max(playhead - markerWidth / 2, 0), max(width - markerWidth, 0)), y: -(Self.bar + Self.markerGap))
                }
            }
            ZStack(alignment: .leading) {
                HStack(spacing: 8) {
                    if let text = scrub?.position ?? (state.mode == .liveWindow ? nil : now.position) {
                        Text(text)
                    }
                    if state.paused, scrub == nil {
                        Image(systemName: "pause.circle")
                    }
                }
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { elapsedWidth = $0 }
                .offset(x: elapsedX)
                // The time left at the bar's end; a live window's start at its start.
                Text(state.mode == .liveWindow ? now.position : now.finishClock.isEmpty ? now.remaining : "\(now.remaining) · \(now.finishClock)")
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { remainingWidth = $0 }
                    .frame(maxWidth: .infinity, alignment: state.mode == .liveWindow ? .leading : .trailing)
                    .opacity(sideHidden(elapsedX: elapsedX) ? 0 : 1)
                    .accessibilityIdentifier(state.mode == .liveWindow ? "player.position" : "player.remaining")
            }
            .font(PlayerMetrics.timelineTimeFont)
            .foregroundStyle(lit ? Palette.onVideo : Palette.onVideoSecondary)
            .lineLimit(1)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .animation(.easeOut(duration: 0.15), value: lit)
        .environment(\.layoutDirection, .leftToRight)
    }

    /// The bar: AVKit's colours, sampled over its dark scrim (`#1A1A1A`): the rest white 11 % with focus and 6 %
    /// without, the played part white 52 %, the buffered part white 20 %.
    private func track(_ now: TimelineState, playhead: CGFloat, lit: Bool) -> some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Palette.onVideo.opacity(lit ? 0.11 : 0.06))
            if lit {
                Rectangle().fill(Palette.onVideo.opacity(0.2))
                    .frame(width: width * clamp(Double(now.buffered)))
                Rectangle().fill(Palette.onVideo.opacity(0.52))
                    .frame(width: playhead)
                ForEach(Array(now.chapters.enumerated()), id: \.offset) { _, mark in
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 2)
                        .offset(x: width * CGFloat(truncating: mark) - 1)
                }
            }
        }
        .frame(height: Self.bar)
        .clipShape(Capsule())
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Palette.onVideo)
                .frame(width: Self.needle.width, height: Self.needle.height)
                .offset(x: playhead - Self.needle.width / 2)
        }
    }

    /// Above the playhead while scrubbing: how far the preview is from the position, and its chapter.
    private func marker(_ scrub: ScrubState) -> some View {
        VStack(spacing: 2) {
            Text(scrub.offset).font(PlayerMetrics.timelineTimeFont)
            if let chapter = scrub.chapter {
                Text(chapter).font(.caption2).lineLimit(1)
            }
        }
        .foregroundStyle(Palette.onVideo)
        .shadow(color: .black.opacity(0.5), radius: 6)
        .fixedSize()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { markerWidth = $0 }
        .accessibilityHidden(true)
    }

    /// The time left (a live window's start) gives way where what is under the playhead, at `elapsedX`, reaches it.
    private func sideHidden(elapsedX: CGFloat) -> Bool {
        if state.mode == .liveWindow { return elapsedWidth > 0 && elapsedX < remainingWidth + 16 }
        return elapsedX + elapsedWidth + 16 > width - remainingWidth
    }

    private func clamp(_ value: Double) -> CGFloat { CGFloat(min(max(value, 0), 1)) }
}
#endif

#if os(tvOS)
/// Opens the panel across the bottom on its first tab (`PlayerTVPanel.tabs`): the chapters where the video has them,
/// else the queue, else the playback info.
@MainActor
func openPanel(state: PlayerUiState, store: PlayerStore) {
    guard let first = PlayerTVPanel.tabs(state).first else { return }
    PlayerTVPanel.open(first, state: state, store: store)
}
#endif
