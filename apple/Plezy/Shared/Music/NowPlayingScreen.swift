import SwiftUI
import PlezyKit

/// Now Playing's store with its state, playhead, lyric line and volume mirrored for the views: each drawn by the view
/// that needs it, so the playhead's ticks redraw the seek bar alone.
@MainActor
final class NowPlayingModel {
    let store: NowPlayingStore
    let state: StoreObserver<NowPlayingUiState>
    let progress: StoreObserver<MusicProgress>
    let activeLine: StoreObserver<KotlinInt>
    let volume: StoreObserver<KotlinDouble>

    init?(_ store: NowPlayingStore?) {
        guard let store else { return nil }
        self.store = store
        state = StoreObserver(store.state)
        progress = StoreObserver(store.progress)
        activeLine = StoreObserver(store.activeLyricLine)
        volume = StoreObserver(store.volume)
    }
}

#if !os(macOS)
/// Now Playing (`NowPlayingStore`) on iPhone, iPad and Apple TV, a full-screen cover while it is the top screen
/// (`AppShell`; the Mac has its playback bar and full-window player, `MacNowPlaying`): the track's blurred artwork
/// behind everything (30 %, on a TV 22 %; the plain background on the reduced visual effects tier), then one of three
/// layouts (`nowPlayingLayout`):
///
/// - Portrait: the bar (close, "Playing from …", the cast button, ⋮), the artwork or the lyrics, the title and artist, the seek bar, the
///   transport, then Lyrics and Queue. A drag down closes it.
/// - Wide (landscape from 800 pt): the bar, then the artwork or lyrics beside the title, the seek bar, the transport,
///   Lyrics and the sleep timer under it, and the queue inline under them.
/// - TV: the artwork or lyrics beside "Playing from …" with the cast button and ⋮, the title (two lines), the artist, the seek bar, the
///   transport, then Lyrics and Queue; focus starts on Play/Pause.
///
/// ⋯ opens the track's item menu (the shared `MediaMenu`: its host is the shell's, or on iPhone and Apple TV the
/// cover's), the moon the Sleep timer's choices (a system menu); Queue opens the queue sheet. The session ending
/// closes it (the store takes its route off the stack). The remote's Play/Pause reaches the session through the
/// system's Now Playing commands (`NowPlayingCenter`).
struct NowPlayingScreen: View {
    let app: AppModel

    @State private var model: NowPlayingModel?
    @State private var queueOpen = false
    @State private var dismissDrag: CGFloat = 0
    @FocusState private var focus: NowPlayingFocus?
    @Environment(\.dimens) private var dimens
    @Environment(\.formFactor) private var formFactor
    @Environment(\.reducedEffects) private var reducedEffects

    init(app: AppModel) {
        self.app = app
        _model = State(initialValue: NowPlayingModel(app.session.musicNowPlaying()))
    }

    var body: some View {
        if let model {
            let state = model.state.state
            GeometryReader { proxy in
                let unit = dimens.unit
                let layout = MusicUiKt.nowPlayingLayout(
                    tv: formFactor == .tv, width: Double(proxy.size.width / unit), height: Double(proxy.size.height / unit)
                )
                ZStack {
                    NowPlayingBackground(artwork: state.track?.artwork, tv: layout == .tv)
                    if let track = state.track {
                        content(layout: layout, track: track, state: state, model: model, size: proxy.size)
                            .offset(y: dismissDrag)
                    }
                }
                .appSheet(isPresented: $queueOpen, id: "music.queuePanel", size: .panel) {
                    QueueSheet(queue: state.queue, playing: state.isPlaying, store: model.store) { queueOpen = false }
                }
            }
            .background(Palette.background)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("music.np.screen")
            .backAction { if queueOpen { queueOpen = false } else { close() } }
            .defaultFocus($focus, .playPause)
            // A closed sheet leaves focus nowhere (the chrome under the screen takes none): back to Play/Pause, so the
            // remote's Menu reaches the screen again.
            .onChange(of: queueOpen) { _, open in
                guard !open else { return }
                // A moment after the sheet's state goes, once the sheet is gone.
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    focus = .playPause
                }
            }
            .task { await model.state.observe() }
        }
    }

    // MARK: Layouts

    @ViewBuilder
    private func content(layout: NowPlayingLayout, track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel, size: CGSize) -> some View {
        switch layout {
        case .tv: tvLayout(track: track, state: state, model: model)
        case .wide: wideLayout(track: track, state: state, model: model, size: size)
        default: portraitLayout(track: track, state: state, model: model, size: size)
        }
    }

    /// The portrait column as it is when it fits the screen, the artwork taking the height the rest leaves; when it
    /// doesn't (a phone in landscape at a large text size, where the artwork had no height left), the column scrolls
    /// with the artwork at its least.
    private func portraitLayout(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel, size: CGSize) -> some View {
        ViewThatFits(in: .vertical) {
            portraitColumn(track: track, state: state, model: model, size: size)
            ScrollView(.vertical) {
                portraitColumn(track: track, state: state, model: model, size: size)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The least side of the portrait column's artwork (or lyrics), in points before `unit`.
    private static let artworkMinimum: CGFloat = 120

    private func portraitColumn(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel, size: CGSize) -> some View {
        let unit = dimens.unit
        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar(state: state, model: model)
                artworkOrLyrics(track: track, state: state, model: model, tv: false)
                    .frame(minHeight: Self.artworkMinimum * unit)
                    .padding(.horizontal, 24 * unit)
                    .padding(.vertical, 8 * unit)
                trackInfo(track: track, model: model, centered: true)
                    .padding(.horizontal, 32 * unit)
                    .padding(.top, 8 * unit)
            }
            .contentShape(Rectangle())
            #if os(iOS)
            .gesture(dismissGesture(height: size.height))
            #endif
            MusicSeekBar(progress: model.progress, store: model.store)
                .padding(.horizontal, 16 * unit)
                .padding(.top, 8 * unit)
            MusicTransport(state: state, store: model.store, focus: $focus)
            utilityRow(state: state, model: model)
                .padding(.bottom, 8 * unit)
        }
    }

    private func wideLayout(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel, size: CGSize) -> some View {
        let unit = dimens.unit
        let inner = size.width - 48 * unit - 32 * unit
        return VStack(spacing: 0) {
            topBar(state: state, model: model)
            HStack(alignment: .top, spacing: 32 * unit) {
                artworkOrLyrics(track: track, state: state, model: model, tv: false)
                    .frame(width: inner * 9 / 20)
                VStack(alignment: .leading, spacing: 0) {
                    trackInfo(track: track, model: model, centered: false)
                    MusicSeekBar(progress: model.progress, store: model.store)
                        .padding(.top, 8 * unit)
                    MusicTransport(state: state, store: model.store, focus: $focus)
                        .frame(maxWidth: .infinity)
                    // Lyrics and the sleep timer on a row of their own under the transport: beside it they ran over Next
                    // and Repeat in a narrow column.
                    HStack(spacing: 4 * unit) {
                        lyricsButton(state: state, model: model)
                        MusicSleepTimerMenu(options: state.sleepTimer, store: model.store)
                        Spacer(minLength: 0)
                    }
                    .shelfFocusSection()
                    QueueList(queue: state.queue, playing: state.isPlaying, store: model.store)
                        .padding(.vertical, 12 * unit)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .background(Palette.background.opacity(0.55), in: RoundedRectangle(cornerRadius: Radius.large * unit, style: .continuous))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.large * unit, style: .continuous))
                        .padding(.top, 12 * unit)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24 * unit)
            .padding(.bottom, 20 * unit)
        }
    }

    private func tvLayout(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        let unit = dimens.unit
        return GeometryReader { proxy in
            let inner = proxy.size.width - 112 * unit - 48 * unit
            HStack(spacing: 48 * unit) {
                artworkOrLyrics(track: track, state: state, model: model, tv: true)
                    .frame(width: inner * 4 / 9)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.playingFrom ?? "")
                                .font(.subheadline)
                                .foregroundStyle(NowPlayingBackground.secondaryText)
                                .lineLimit(1)
                                .accessibilityIdentifier("music.np.playingFrom")
                            castingFromLine
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        CastButton(look: .nowPlaying, id: "music.np.cast")
                        overflow(state: state, model: model)
                    }
                    Text(track.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.onBackground)
                        .lineLimit(2)
                        .padding(.top, 8 * unit)
                        .accessibilityIdentifier("music.np.title")
                    if let artist = track.artist {
                        Text(artist)
                            .font(.callout)
                            .foregroundStyle(NowPlayingBackground.secondaryText)
                            .lineLimit(1)
                            .padding(.top, 4 * unit)
                    }
                    MusicSeekBar(progress: model.progress, store: model.store)
                        .padding(.top, 28 * unit)
                    MusicTransport(state: state, store: model.store, focus: $focus)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8 * unit)
                    utilityRow(state: state, model: model)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 56 * unit)
            .padding(.vertical, 40 * unit)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: Pieces

    /// Close, "Playing from …" (with "Casting from …" under it while this device plays a cast), the cast button and ⋯
    /// over the screen.
    private func topBar(state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        let unit = dimens.unit
        return HStack(spacing: 0) {
            MusicIconButton(systemImage: "chevron.down", label: T.shared.common.close, size: 22, id: "music.np.close", action: close)
            VStack(spacing: 2) {
                Text(state.playingFrom ?? "")
                    .font(.footnote)
                    .foregroundStyle(NowPlayingBackground.secondaryText)
                    .lineLimit(1)
                    .accessibilityIdentifier("music.np.playingFrom")
                castingFromLine
            }
            .frame(maxWidth: .infinity)
            CastButton(look: .nowPlaying, id: "music.np.cast")
            overflow(state: state, model: model)
        }
        .padding(.horizontal, 8 * unit)
        .padding(.top, 4 * unit)
    }

    /// "Casting from <device>" while this device plays a cast (`music.np.castingFrom`).
    @ViewBuilder
    private var castingFromLine: some View {
        if let castingFrom = app.cast.receiverState.state.castingFrom {
            Label(castingFrom, systemImage: "tv.badge.wifi")
                .accessibilityLabel(castingFrom)
                .font(.caption)
                .foregroundStyle(NowPlayingBackground.secondaryText)
                .lineLimit(1)
                .accessibilityIdentifier("music.np.castingFrom")
        }
    }

    /// ⋯: the current track's item menu in the system's menu (`SystemItemMenu`).
    private func overflow(state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        Image(systemName: "ellipsis")
            .font(.body.weight(.semibold))
            .roundGlassLabel(.circle, menu: true)
            .accessibilityIdentifier("music.np.more")
            .modifier(SystemItemMenu(open: { openMenu(model) }, item: state.track?.globalKey ?? "", kind: .menu))
            .menuIndicator(.hidden)
            .roundGlassControl(.circle, menu: true)
            .accessibilityLabel(T.shared.common.options)
            .accessibilityIdentifier("music.np.more")
    }

    /// The current track's item menu.
    private func openMenu(_ model: NowPlayingModel) {
        guard let item = model.store.item else { return }
        app.session.mediaActions.menu.open(item: item, place: .anywhere, extras: [], playTrailer: nil, onRow: [])
    }

    private func trackInfo(track: MusicTrackUi, model: NowPlayingModel, centered: Bool) -> some View {
        let unit = dimens.unit
        return VStack(alignment: centered ? .center : .leading, spacing: 2 * unit) {
            Text(track.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.onBackground)
                .lineLimit(1)
                .accessibilityIdentifier("music.np.title")
            if let artist = track.artist {
                Button { model.store.openArtist() } label: {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(NowPlayingBackground.secondaryText)
                        .lineLimit(1)
                }
                .buttonStyle(PressDimButtonStyle())
                .disabled(!track.artistLinked)
                .accessibilityIdentifier("music.np.artist")
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }

    @ViewBuilder
    private func artworkOrLyrics(track: MusicTrackUi, state: NowPlayingUiState, model: NowPlayingModel, tv: Bool) -> some View {
        if state.showLyrics {
            NowPlayingLyrics(state: state, model: model) { focus = .playPause }
                .transition(.opacity)
        } else {
            NowPlayingArtwork(artwork: track.artwork, playing: state.isPlaying, tv: tv)
                .transition(.opacity)
        }
    }

    private func lyricsButton(state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        MusicIconButton(
            systemImage: "quote.bubble.fill", label: T.shared.music.lyrics, size: 22, id: "music.np.lyrics", isOn: state.showLyrics
        ) {
            withAnimation(reducedEffects ? nil : .easeOut(duration: 0.2)) { model.store.toggleLyrics() }
        }
    }

    private func utilityRow(state: NowPlayingUiState, model: NowPlayingModel) -> some View {
        HStack(spacing: 16 * dimens.unit) {
            lyricsButton(state: state, model: model)
            MusicIconButton(systemImage: "list.bullet", label: T.shared.music.queue, size: 22, active: false, id: "music.np.queue") {
                queueOpen = true
            }
            MusicSleepTimerMenu(options: state.sleepTimer, store: model.store)
        }
        .shelfFocusSection()
    }

    private func close() {
        _ = app.navigator.back()
    }

    #if os(iOS)
    /// Down past a quarter of the screen, or flung down, closes it; otherwise it settles back.
    private func dismissGesture(height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in dismissDrag = max(value.translation.height, 0) }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                if value.translation.height > height * 0.25 || velocity > 500 {
                    close()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { dismissDrag = 0 }
                }
            }
    }
    #endif
}
#endif

/// What Now Playing puts focus on: Play/Pause, at first and after a sheet.
enum NowPlayingFocus: Hashable {
    case playPause
}

/// The track's artwork, square: 85 % of its column's width at most (on a TV 62 % of the height), rounder while paused,
/// the music note without one.
private struct NowPlayingArtwork: View {
    let artwork: Artwork?
    let playing: Bool
    let tv: Bool

    @Environment(\.dimens) private var dimens

    var body: some View {
        GeometryReader { proxy in
            let unit = dimens.unit
            let side = CGFloat(MusicUiKt.nowPlayingArtworkSide(
                layout: tv ? .tv : .portrait, width: Double(proxy.size.width), height: Double(proxy.size.height)
            ))
            MusicArtwork(artwork: artwork, cornerRadius: (playing ? Radius.large : 28) * unit)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .effectsAnimation(.spring(duration: 0.35), value: playing)
        }
        .accessibilityIdentifier("music.np.artwork")
    }
}

/// The lyrics pane with its lyric line observed here, so the line's changes redraw the pane alone.
struct NowPlayingLyrics: View {
    let state: NowPlayingUiState
    let model: NowPlayingModel
    let onExit: () -> Void

    var body: some View {
        LyricsView(lyrics: state.lyrics, active: Int(model.activeLine.state.int32Value), onSeek: { model.store.seekToLyric(index: Int32($0)) }, onExit: onExit)
            .task { await model.activeLine.observe() }
    }
}

/// The track's artwork blurred past recognition, faint over the background (30 %, on a TV 22 %); on the reduced visual
/// effects tier the plain background.
struct NowPlayingBackground: View {
    let artwork: Artwork?
    let tv: Bool

    /// Secondary text over it ("Playing from …", the artist, the times) and the symbols of controls that are off or
    /// muted: the text colour at 75 %. The system's secondary grey is itself partly see-through and fell to about 3.5:1
    /// over pastel artwork (symbols to 2.7:1); this reads at 4.5:1 or more over any artwork, light theme or dark.
    @MainActor static var secondaryText: Color { Palette.onBackground.opacity(0.75) }

    @Environment(\.reducedEffects) private var reducedEffects

    var body: some View {
        ZStack {
            Palette.background
            if artwork != nil, !reducedEffects {
                RemoteImage(artwork: artwork)
                    .blur(radius: 60, opaque: true)
                    .opacity(tv ? 0.22 : 0.3)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
