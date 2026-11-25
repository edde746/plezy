#if os(macOS)
import SwiftUI
import PlezyKit

/// The Mac's music player, as Apple Music's on macOS 26: a floating playback bar at the foot of the content
/// (`MacPlaybackBar`), the queue or the lyrics in a side panel beside the screen in use (`MacPlayerPanel`), and Now
/// Playing as the full-window player over the whole window (`MacFullPlayer`), opened from the bar's track.
///
/// The bar and the panel follow the shell's own Now Playing store (`MacPlayerModel`); the full-window player takes the
/// Now Playing route's, which closes it as the session ends.
@MainActor
@Observable
final class MacPlayerModel {
    /// What the side panel shows.
    enum Pane: Hashable { case queue, lyrics }

    @ObservationIgnored let nowPlaying: NowPlayingModel
    /// The side panel's pane, nil while it is closed.
    private(set) var pane: Pane?

    init?(session: AppSession) {
        guard let nowPlaying = NowPlayingModel(session.musicScreens.nowPlaying()) else { return nil }
        self.nowPlaying = nowPlaying
    }

    /// Shows `pane` in the side panel, or closes it (nil). The store loads the lyrics only while its lyrics show.
    func show(_ pane: Pane?) {
        self.pane = pane
        if nowPlaying.state.state.showLyrics != (pane == .lyrics) { nowPlaying.store.toggleLyrics() }
    }

    /// `pane` shown, or the panel closed if it already shows it (the bar's Lyrics and Queue).
    func toggle(_ pane: Pane) {
        show(self.pane == pane ? nil : pane)
    }

    /// Mirrors the store until the calling task is cancelled (the shell goes), then closes it.
    func run() async {
        await nowPlaying.state.observe()
        nowPlaying.store.close()
    }
}

extension EnvironmentValues {
    /// The room the Mac's playback bar takes at the foot of the content, 0 without it (`musicBarRoom`).
    @Entry var musicBarRoom: CGFloat = 0
}

extension View {
    /// A screen's content clears the Mac's playback bar at its foot: it scrolls under the bar and stops above it.
    func musicBarRoom() -> some View {
        modifier(MusicBarRoom())
    }

    /// The Mac's player on the split view (`AppShell`): the playback bar over the detail column (clear of the sidebar,
    /// `sidebarWidth` wide, 0 while it is hidden) while music plays and Now Playing isn't up, the side panel as the
    /// window's inspector, and the bar's room for the screens. While this device casts, the cast bar (`MacCastBar`) in
    /// the playback bar's place and, while open, the cast controls (`CastControlsPanel`) as the inspector.
    func macMusicPlayer(_ model: MacPlayerModel?, chrome: MusicChromeModel, sidebarWidth: CGFloat, nowPlaying: Bool) -> some View {
        modifier(MacMusicPlayer(model: model, chrome: chrome, sidebarWidth: sidebarWidth, nowPlaying: nowPlaying))
    }
}

private struct MusicBarRoom: ViewModifier {
    @Environment(\.musicBarRoom) private var room

    func body(content: Content) -> some View {
        content.safeAreaPadding(.bottom, room)
    }
}

private struct MacMusicPlayer: ViewModifier {
    let model: MacPlayerModel?
    let chrome: MusicChromeModel
    let sidebarWidth: CGFloat
    let nowPlaying: Bool

    @Environment(\.cast) private var cast

    /// The bar's height and the margin under it.
    static let barHeight: CGFloat = 52
    static let margin: CGFloat = 12

    func body(content: Content) -> some View {
        let state = chrome.state.state
        let casting = cast?.senderState.state.casting == true && !nowPlaying
        let shown = model != nil && state.visible && state.track != nil && !nowPlaying && !casting
        let controls = casting && cast?.senderState.state.controlsOpen == true
        content
            .environment(\.musicBarRoom, shown || casting ? Self.barHeight + Self.margin * 2 : 0)
            .overlay(alignment: .bottom) {
                Group {
                    if casting, let cast {
                        MacCastBar(cast: cast)
                    } else if shown, let model {
                        MacPlaybackBar(model: model, chrome: chrome)
                    }
                }
                .frame(height: Self.barHeight)
                .padding(.horizontal, 20)
                .padding(.bottom, Self.margin)
                .padding(.leading, sidebarWidth)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            // The side panel: the cast controls while they are open (from the cast bar), else the music's pane.
            .inspector(isPresented: Binding(
                get: { controls || (shown && model?.pane != nil) },
                set: { if !$0 { if controls { cast?.sender.closeControls() } else { model?.show(nil) } } }
            )) {
                Group {
                    if controls, let cast {
                        CastControlsPanel(cast: cast)
                    } else if let model {
                        MacPlayerPanel(model: model)
                    }
                }
                .inspectorColumnWidth(min: 280, ideal: 320, max: 420)
            }
    }
}

/// The playback bar: Shuffle, Previous, Play/Pause, Next and Repeat; the track (its artwork, title and artist over a
/// thin scrubber), which opens the full-window player and on a right click the track's item menu; then ⋯ (the item
/// menu), the sleep timer, Lyrics and Queue (filled while their pane shows, `MacPaneToggle`), the volume, and Stop. In Liquid Glass
/// (the system's regular material before macOS 26). Narrow, it drops the volume and the sleep timer, which the
/// full-window player keeps.
private struct MacPlaybackBar: View {
    let model: MacPlayerModel
    let chrome: MusicChromeModel

    var body: some View {
        let state = model.nowPlaying.state.state
        let store = model.nowPlaying.store
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                control("shuffle", T.shared.common.shuffle, "music.bar.shuffle", isOn: state.shuffled, action: store.toggleShuffle)
                control("backward.fill", T.shared.music.previousTrack, "music.bar.previous", enabled: state.canGoPrevious, action: store.previous)
                control(
                    state.isPlaying ? "pause.fill" : "play.fill", state.isPlaying ? T.shared.common.pause : T.shared.common.play,
                    "music.bar.playPause", size: 20, action: store.togglePlayPause
                )
                control("forward.fill", T.shared.music.nextTrack, "music.bar.next", enabled: state.canGoNext, action: store.next)
                control(state.repeatMode.systemImage, state.repeatMode.label, "music.bar.repeat", isOn: state.repeatMode != .off, action: store.cycleRepeat)
            }
            if let track = state.track {
                MacBarTrack(track: track, model: model, chrome: chrome)
                    .frame(minWidth: 160, maxWidth: 420)
                    .frame(maxWidth: .infinity)
            }
            ViewThatFits(in: .horizontal) {
                trailing(state: state, full: true)
                trailing(state: state, full: false)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .modifier(BarGlass())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("music.bar")
        .task { await model.nowPlaying.state.observe() }
    }

    private func trailing(state: NowPlayingUiState, full: Bool) -> some View {
        let store = model.nowPlaying.store
        return HStack(spacing: 6) {
            control("ellipsis", T.shared.common.options, "music.bar.more", action: chrome.openMenu)
            if full { MusicSleepTimerMenu(options: state.sleepTimer, store: store, size: 14, id: "music.bar.sleep") }
            MacPaneToggle(symbol: "quote.bubble", label: T.shared.music.lyrics, id: "music.bar.lyrics", on: model.pane == .lyrics) { model.toggle(.lyrics) }
            MacPaneToggle(symbol: "list.bullet", label: T.shared.music.queue, id: "music.bar.queue", on: model.pane == .queue) { model.toggle(.queue) }
            if full { MusicVolumeCluster(volume: model.nowPlaying.volume, store: store, width: 90, id: "music.bar.volume") }
            control("xmark", T.shared.music.stopPlayback, "music.bar.stop", action: chrome.store.dismiss)
        }
        .fixedSize()
    }

    /// A plain symbol button, or a toggle (`isOn` set) in `toggleDisc`'s look; not `enabled`, its symbol is faint and it
    /// takes no clicks.
    private func control(
        _ symbol: String, _ label: String, _ id: String, size: CGFloat = 14, isOn: Bool? = nil, enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let isOn {
                    Image(systemName: symbol).toggleDisc(isOn, diameter: 28)
                } else {
                    Image(systemName: symbol).foregroundStyle(Palette.onBackground)
                }
            }
            .font(.system(size: size, weight: .semibold))
            .opacity(enabled ? 1 : 0.45)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(PressDimButtonStyle())
        .tooltip(label)
        .accessibilityLabel(label)
        .toggleState(isOn)
        .accessibilityIdentifier(id)
    }
}

/// Lyrics or Queue, a toggle of the pane it shows: on a filled disc while its pane shows (`toggleDisc`), as Now
/// Playing's other toggles; for VoiceOver and the UI tests its value says On or Off and it is selected while on
/// (`toggleState`).
private struct MacPaneToggle: View {
    let symbol: String
    let label: String
    let id: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .toggleDisc(on, diameter: 28)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDimButtonStyle())
        .tooltip(label)
        .accessibilityLabel(label)
        .toggleState(on)
        .accessibilityIdentifier(id)
    }
}

/// The bar's track: the artwork, the title and artist over a thin scrubber a drag seeks along. A click on the artwork,
/// title or artist opens the full-window player; a right click the track's item menu.
private struct MacBarTrack: View {
    let track: MusicTrackUi
    let model: MacPlayerModel
    let chrome: MusicChromeModel

    var body: some View {
        HStack(spacing: 10) {
            Button(action: chrome.store.open) {
                HStack(spacing: 10) {
                    MusicArtwork(artwork: track.artwork, cornerRadius: Radius.small)
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Palette.onBackground)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.subheadline)
                                .foregroundStyle(Palette.onSurfaceVariant)
                        }
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .tooltip(T.shared.music.nowPlaying)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(track.title)
            .accessibilityValue(track.artist ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("music.bar.open")
            .mediaMenuTrigger(chrome.openMenu, item: track)
        }
        .overlay(alignment: .bottom) {
            MacBarScrubber(progress: model.nowPlaying.progress, store: model.nowPlaying.store)
                .padding(.leading, 46)
                .offset(y: 7)
        }
    }
}

/// The bar's scrubber: the played part of the track on a 3 pt track; a drag (or a click) seeks there.
private struct MacBarScrubber: View {
    let progress: StoreObserver<MusicProgress>
    let store: NowPlayingStore

    @State private var dragFraction: Double?

    var body: some View {
        let progress = progress.state
        let fraction = dragFraction ?? Double(progress.fraction)
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.outline)
                Capsule().fill(Palette.onSurfaceVariant).frame(width: max(width * fraction, 0))
            }
            .frame(height: 3)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard progress.durationMillis > 0, width > 0 else { return }
                        dragFraction = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { _ in
                        if let dragFraction { store.seekToFraction(fraction: Float(dragFraction)) }
                        dragFraction = nil
                    }
            )
        }
        .frame(height: 9)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(T.shared.music.nowPlaying)
        .accessibilityValue(progress.positionLabel)
        .accessibilityIdentifier("music.bar.seek")
        .accessibilityAdjustableAction { direction in
            store.stepSeek(forward: direction == .increment, repeat: false)
            store.endStepSeek()
        }
        .task { await self.progress.observe() }
    }
}

/// Liquid Glass in a capsule (the system's regular material before macOS 26), with a hairline and a soft shadow: the
/// playback bar's and the cast bar's (`MacCastBar`).
struct BarGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.outline.opacity(0.5)))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        }
    }
}

/// The side panel: Queue or Lyrics, picked over it. The queue with its title, count and controls, rows dragged by
/// their handles to reorder and removed by their ×; the lyrics synced, a line clicked seeks to it.
private struct MacPlayerPanel: View {
    let model: MacPlayerModel

    var body: some View {
        let state = model.nowPlaying.state.state
        VStack(spacing: 12) {
            Picker(T.shared.music.nowPlaying, selection: Binding(get: { model.pane ?? .queue }, set: { model.show($0) })) {
                Text(T.shared.music.queue).tag(MacPlayerModel.Pane.queue)
                Text(T.shared.music.lyrics).tag(MacPlayerModel.Pane.lyrics)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .accessibilityIdentifier("music.panel.pane")
            if model.pane == .lyrics {
                NowPlayingLyrics(state: state, model: model.nowPlaying) {}
                    .padding(.horizontal, 8)
            } else {
                QueueSheet(queue: state.queue, playing: state.isPlaying, store: model.nowPlaying.store, showsTitle: false) { model.show(nil) }
            }
        }
        .padding(.top, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("music.panel")
    }
}

/// Now Playing on the Mac, the full-window player over the whole window while it is the top screen (`AppShell`): the
/// track's artwork blurred behind everything; the artwork, the title and artist (the artist opens their screen) with
/// ⋯ (the track's item menu), the seek bar and the transport in a column; beside it the lyrics or the queue while one
/// is picked. Close top leading; "Casting from …" top centre while this device plays a cast; the cast button, the sleep
/// timer and the volume top trailing; Lyrics and Queue bottom trailing. Space
/// plays and pauses, Escape closes it (as Close does), back to the screen under it.
struct MacFullPlayer: View {
    let app: AppModel

    @State private var model: NowPlayingModel?
    @State private var queueShown = false
    @FocusState private var focus: NowPlayingFocus?
    /// The player holds the keyboard's focus (buttons take none without full keyboard access), so Space reaches it.
    @FocusState private var keyFocus: Bool

    init(app: AppModel) {
        self.app = app
        _model = State(initialValue: NowPlayingModel(app.session.musicNowPlaying()))
    }

    var body: some View {
        if let model {
            let state = model.state.state
            ZStack {
                NowPlayingBackground(artwork: state.track?.artwork, tv: false)
                if let track = state.track {
                    HStack(spacing: 56) {
                        column(track: track, state: state, model: model)
                            .frame(width: 340)
                        if state.showLyrics {
                            NowPlayingLyrics(state: state, model: model) { keyFocus = true }
                                .frame(maxWidth: 560)
                        } else if queueShown {
                            QueueSheet(queue: state.queue, playing: state.isPlaying, store: model.store) { queueShown = false }
                                .frame(maxWidth: 520, maxHeight: 560)
                        }
                    }
                    .padding(.horizontal, 64)
                    .padding(.vertical, 56)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .topLeading) {
                glassButton("xmark", T.shared.common.close, "music.np.close", action: close)
                    .padding(14)
            }
            .overlay(alignment: .top) {
                if let castingFrom = app.cast.receiverState.state.castingFrom {
                    Label(castingFrom, systemImage: "tv.badge.wifi")
                        .accessibilityLabel(castingFrom)
                        .font(.callout)
                        .foregroundStyle(NowPlayingBackground.secondaryText)
                        .lineLimit(1)
                        .frame(height: 36)
                        .padding(14)
                        .accessibilityIdentifier("music.np.castingFrom")
                }
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    CastButton(look: .nowPlaying, id: "music.np.cast")
                    MusicSleepTimerMenu(options: state.sleepTimer, store: model.store, size: 15)
                    MusicVolumeCluster(volume: model.volume, store: model.store, width: 110)
                }
                .padding(.horizontal, 10)
                .frame(height: 36)
                .modifier(BarGlass())
                .padding(14)
            }
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 4) {
                    MacPaneToggle(symbol: "quote.bubble", label: T.shared.music.lyrics, id: "music.np.lyrics", on: state.showLyrics) {
                        if queueShown { queueShown = false }
                        model.store.toggleLyrics()
                    }
                    MacPaneToggle(symbol: "list.bullet", label: T.shared.music.queue, id: "music.np.queue", on: queueShown && !state.showLyrics) {
                        if state.showLyrics { model.store.toggleLyrics() }
                        queueShown.toggle()
                    }
                }
                .padding(.horizontal, 6)
                .frame(height: 36)
                .modifier(BarGlass())
                .padding(14)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("music.np.screen")
            // An empty view behind the player holds the keyboard's focus, not the player: a focused ancestor reads as
            // focus in every button under it, which drew their focus rings.
            .background {
                Color.clear
                    .focusable()
                    .focusEffectDisabled()
                    .focused($keyFocus)
                    .onKeyPress(.space) {
                        model.store.togglePlayPause()
                        return .handled
                    }
            }
            .onAppear { keyFocus = true }
            .backAction(close)
            .task { await model.state.observe() }
        }
    }

    private func column(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            MusicArtwork(artwork: track.artwork, cornerRadius: Radius.large)
                .frame(width: 340, height: 340)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
                .accessibilityIdentifier("music.np.artwork")
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.onBackground)
                        .lineLimit(1)
                        .accessibilityIdentifier("music.np.title")
                    if let artist = track.artist {
                        Button { model.store.openArtist() } label: {
                            Text(artist)
                                .font(.body)
                                .foregroundStyle(NowPlayingBackground.secondaryText)
                                .lineLimit(1)
                        }
                        .buttonStyle(PressDimButtonStyle())
                        .disabled(!track.artistLinked)
                        .accessibilityIdentifier("music.np.artist")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                glassButton("ellipsis", T.shared.common.options, "music.np.more") { openMenu(model) }
            }
            MusicSeekBar(progress: model.progress, store: model.store)
                .padding(.horizontal, -24)
            MusicTransport(state: state, store: model.store, focus: $focus)
                .frame(maxWidth: .infinity)
        }
    }

    private func glassButton(_ symbol: String, _ label: String, _ id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.onBackground)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(PressDimButtonStyle())
        .modifier(BarGlass())
        .tooltip(label)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    /// The current track's item menu.
    private func openMenu(_ model: NowPlayingModel) {
        guard let item = model.store.item else { return }
        app.session.mediaActions.menu.open(item: item, place: .anywhere, extras: [], playTrailer: nil, onRow: [])
    }

    private func close() {
        _ = app.navigator.back()
    }
}
#endif
