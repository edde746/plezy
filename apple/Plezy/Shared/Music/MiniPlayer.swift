import SwiftUI
import PlezyKit

extension EnvironmentValues {
    /// The shell's music chrome (`MusicChromeModel`): the mini-player and Apple TV's Now Playing tab read it.
    @Entry var musicChrome: MusicChromeModel?
    /// The tab view holds the mini-player as its bottom accessory (iOS 26.1 and later), so the stacks under it don't
    /// dock their own.
    @Entry var miniPlayerInAccessory = false
}

extension View {
    /// The mini-player docked at the foot of this content area (a destination's stack) while music plays, where the tab
    /// view doesn't hold it as its bottom accessory: iPad's split view and the tab bar before iOS 26.1. While this device
    /// casts, the cast bar (`CastBar`) in its place. Never on a TV, which has its Now Playing and Casting tabs, nor on
    /// the Mac, which has its playback bar (`MacNowPlaying`).
    func musicMiniPlayer() -> some View {
        modifier(MiniPlayerInset())
    }

    /// The mini-player as the tab view's bottom accessory, shown while music plays (iOS 26.1 and later); while this
    /// device casts, the cast bar (`CastBar`) in its place.
    @ViewBuilder
    func musicMiniPlayerAccessory(_ chrome: MusicChromeModel, cast: CastModel) -> some View {
        #if os(iOS)
        if #available(iOS 26.1, *) {
            let state = chrome.state.state
            let casting = cast.senderState.state.casting
            tabViewBottomAccessory(isEnabled: casting || state.visible && state.track != nil) {
                if casting {
                    CastBar(cast: cast, docked: false)
                } else if let track = state.track {
                    MiniPlayerBar(track: track, state: state, chrome: chrome, docked: false)
                }
            }
            .environment(\.miniPlayerInAccessory, true)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// The fallback dock: the bar in the bottom safe area on the system's bar material, a hairline over it.
private struct MiniPlayerInset: ViewModifier {
    @Environment(\.musicChrome) private var chrome
    @Environment(\.cast) private var cast
    @Environment(\.formFactor) private var formFactor
    @Environment(\.miniPlayerInAccessory) private var inAccessory

    func body(content: Content) -> some View {
        #if os(iOS)
        if formFactor != .tv, !inAccessory {
            let state = chrome?.state.state
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                Group {
                    if let cast, cast.senderState.state.casting {
                        CastBar(cast: cast, docked: true)
                    } else if let chrome, let state, state.visible, let track = state.track {
                        MiniPlayerBar(track: track, state: state, chrome: chrome, docked: true)
                    }
                }
                .frame(height: 56)
                .background(.bar)
                .overlay(alignment: .top) { Divider() }
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if os(iOS)
/// The mini-player: the track's artwork, title and artist, then Play/Pause, Next and Stop (✕, which ends the session).
/// Docked across the content, the played part of the track runs as a thin line along its foot; the tab bar's accessory
/// shows none. A tap opens Now Playing (the buttons act alone), a long press or right click opens the track's item menu
/// (`MusicChromeModel.openMenu`), a sideways swipe stops the session too.
private struct MiniPlayerBar: View {
    let track: MusicTrackUi
    let state: MiniPlayerUiState
    let chrome: MusicChromeModel
    /// In the fallback dock (a bar across the content), not the tab view's accessory capsule.
    let docked: Bool

    @State private var swipe: CGFloat = 0

    var body: some View {
        let store = chrome.store
        HStack(spacing: 4) {
            Button(action: store.open) {
                HStack(spacing: 10) {
                    MusicArtwork(artwork: track.artwork, cornerRadius: Radius.small)
                        .frame(width: docked ? 40 : 30, height: docked ? 40 : 30)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(track.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, docked ? 12 : 8)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(track.title)
            .accessibilityValue(track.artist ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("music.mini.open")
            .mediaMenuTrigger(chrome.openMenu, item: track)
            control(
                state.isPlaying ? "pause.fill" : "play.fill", state.isPlaying ? T.shared.common.pause : T.shared.common.play,
                "music.mini.playPause", store.togglePlayPause
            )
            control("forward.fill", T.shared.music.nextTrack, "music.mini.next", enabled: state.canGoNext, store.next)
            control("xmark", T.shared.music.stopPlayback, "music.mini.close", store.dismiss)
        }
        .padding(.trailing, 8)
        // The docked bar's played part along its foot; the tab bar's accessory has none, as Apple Music's hasn't.
        .overlay(alignment: .bottom) { if docked { MiniPlayerProgress(progress: chrome.progress) } }
        .offset(x: swipe)
        .opacity(1 - min(abs(swipe) / 300, 0.6))
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) { swipe = value.translation.width }
                }
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.width - value.translation.width
                    if abs(value.translation.width) > 120 || abs(velocity) > 600 {
                        store.dismiss()
                    }
                    withAnimation(.easeOut(duration: 0.2)) { swipe = 0 }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("music.mini")
    }

    /// A plain symbol button; not `enabled`, its symbol is faint and it takes no taps.
    private func control(_ symbol: String, _ label: String, _ id: String, enabled: Bool = true, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .opacity(enabled ? 1 : 0.45)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(PressDimButtonStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}

/// The played part of the track as a thin line from the leading edge: its own view, so the playhead's ticks redraw it
/// alone.
private struct MiniPlayerProgress: View {
    let progress: StoreObserver<KotlinFloat>

    var body: some View {
        GeometryReader { proxy in
            Palette.primary
                .frame(width: proxy.size.width * CGFloat(progress.state.floatValue), height: 2)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 2)
        .task { await progress.observe() }
        .accessibilityHidden(true)
    }
}
#endif
