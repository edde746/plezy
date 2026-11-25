import SwiftUI
import PlezyKit

/// What the target plays, at a glance: the artwork (the receiver's kind's icon without one), the title (while nothing
/// plays, "Ready to cast") over "Casting to <device>", Play/Pause while something plays, and Disconnect; a tap opens
/// the controls (`CastSender.openControls`). On iPhone and iPad it takes the music mini-player's place while this
/// device casts (`musicMiniPlayerAccessory`, `musicMiniPlayer`): the tab bar's accessory, or docked across the foot of
/// the content (`docked`, with the played part as a thin line along its foot); the Mac has `MacCastBar`, Apple TV its
/// Casting tab (`CastTabPage`).
///
/// Accessibility identifiers: `cast.bar`, `cast.bar.open`, `cast.bar.playPause`, `cast.bar.disconnect`.
struct CastBar: View {
    let cast: CastModel
    let docked: Bool

    var body: some View {
        let state = cast.senderState.state
        let playing = state.nowPlaying
        HStack(spacing: 4) {
            Button(action: cast.sender.openControls) {
                HStack(spacing: 10) {
                    CastArtwork(url: playing?.artworkUrl, kind: state.target?.kind)
                        .frame(width: docked ? 40 : 30, height: docked ? 40 : 30)
                    CastBarLines(state: state)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, docked ? 12 : 8)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cast.bar.open")
            if let playing {
                control(
                    playing.paused ? "play.fill" : "pause.fill", playing.paused ? T.shared.common.play : T.shared.common.pause,
                    "cast.bar.playPause", cast.sender.togglePause
                )
            }
            control("xmark", T.shared.cast.controls.disconnect, "cast.bar.disconnect", cast.sender.disconnect)
        }
        .padding(.trailing, 8)
        .overlay(alignment: .bottom) {
            if docked, let playing {
                GeometryReader { proxy in
                    Palette.primary
                        .frame(width: proxy.size.width * CGFloat(playing.progress), height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 2)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.bar")
    }

    private func control(_ symbol: String, _ label: String, _ id: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDimButtonStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}

/// The bar's two lines: what plays over "Casting to <device>"; nothing playing, the device over "Ready to cast".
struct CastBarLines: View {
    let state: CastSenderUiState

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(state.nowPlaying?.title ?? state.receiverName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.onBackground)
            Text(state.nowPlaying == nil ? state.barIdleText ?? "" : T.shared.cast.bar.castingTo(name: state.receiverName))
                .font(.caption)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
        .lineLimit(1)
    }
}

extension CastSenderUiState {
    /// The target's name: what its state stream reports, else the picker's.
    var receiverName: String {
        nowPlaying?.receiverName ?? target?.name ?? ""
    }
}

/// What the target plays as a small square: its artwork, the receiver's kind's icon behind it.
struct CastArtwork: View {
    let url: String?
    let kind: CastDeviceKind?

    var body: some View {
        ZStack {
            Palette.surfaceContainerHighest
            Image(systemName: kind?.systemImage ?? "tv")
                .foregroundStyle(Palette.onSurfaceVariant)
            if url != nil {
                RemoteImage(url: url)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
        .accessibilityHidden(true)
    }
}

#if os(macOS)
/// The Mac's cast bar, floating at the foot of the content where the music's playback bar does (`macMusicPlayer`) while
/// this device casts: Play/Pause, then what plays over "Casting to <device>" (a click opens the controls docked at the
/// window's trailing edge, or closes them), then Disconnect.
///
/// Accessibility identifiers: `cast.bar`, `cast.bar.open`, `cast.bar.playPause`, `cast.bar.disconnect`.
struct MacCastBar: View {
    let cast: CastModel

    var body: some View {
        let state = cast.senderState.state
        HStack(spacing: 16) {
            if let playing = state.nowPlaying {
                control(
                    playing.paused ? "play.fill" : "pause.fill", playing.paused ? T.shared.common.play : T.shared.common.pause,
                    "cast.bar.playPause", size: 20, action: cast.sender.togglePause
                )
            }
            Button(action: state.controlsOpen ? cast.sender.closeControls : cast.sender.openControls) {
                HStack(spacing: 10) {
                    CastArtwork(url: state.nowPlaying?.artworkUrl, kind: state.target?.kind)
                        .frame(width: 36, height: 36)
                    CastBarLines(state: state)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDimButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("cast.bar.open")
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            control("xmark", T.shared.cast.controls.disconnect, "cast.bar.disconnect", action: cast.sender.disconnect)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .modifier(BarGlass())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.bar")
    }

    private func control(_ symbol: String, _ label: String, _ id: String, size: CGFloat = 14, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Palette.onBackground)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDimButtonStyle())
        .tooltip(label)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
#endif

#if os(tvOS)
/// Apple TV's Casting tab, shown while this device casts (a TV has no bar at the foot of its screens, as it has a Now
/// Playing tab for music): the controls (`CastControlsForm`) as its page.
struct CastTabPage: View {
    let cast: CastModel

    var body: some View {
        NavigationStack {
            CastControlsForm(cast: cast)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.tab")
    }
}
#endif
