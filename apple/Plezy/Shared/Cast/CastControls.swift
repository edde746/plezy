import SwiftUI
import PlezyKit

extension View {
    /// The cast control sheet while it is open (`CastSenderUiState.controlsOpen`, from the bar): a sheet on iPhone and
    /// iPad, a `TrailingPanel` on Apple TV; closed by the user (Close, a swipe, the remote's Menu),
    /// `CastSender.closeControls`. Only while `presenting` (no cover over the shell). The Mac docks the controls at the
    /// window's trailing edge instead, beside its cast bar (`macMusicPlayer`, `CastControlsPanel`).
    @ViewBuilder
    func castControls(_ cast: CastModel, presenting: Bool) -> some View {
        #if os(macOS)
        self
        #else
        let state = cast.senderState.state
        appSheet(
            isPresented: Binding(
                get: { presenting && state.casting && state.controlsOpen },
                set: { if !$0, cast.senderState.state.controlsOpen { cast.sender.closeControls() } }
            ),
            id: "cast.controls.panel",
            size: .panel
        ) {
            SheetPage(
                id: "cast.controls",
                title: T.shared.cast.title,
                close: SheetAction(title: T.shared.common.close, id: "cast.controls.close", action: cast.sender.closeControls)
            ) {
                CastControlsForm(cast: cast)
            }
        }
        #endif
    }

    /// The sender's notice (`CastNotice`: the receiver unreachable, pairing refused, the server unreachable from the
    /// receiver, playback failed, playback ended) as the app's toast while `shown` (`cast.notice`), on the error colour
    /// but for an ending; dismissed once shown (`CastSender.dismissNotice`). The shell shows it while no cover is up (in
    /// the shown screen's band, `relay`), the player's and Now Playing's covers while they are, in a band their views
    /// stand above, uncut (nothing there scrolls under it).
    func castNotice(_ cast: CastModel, shown: Bool, in relay: ToastRelay? = nil) -> some View {
        let notice = shown ? cast.senderState.state.notice : nil
        return toast(notice?.message, id: "cast.notice", isError: notice.map { $0.kind != .ended } ?? false, in: relay, cutsContent: false) {
            cast.sender.dismissNotice()
        }
    }
}

/// The controls of what the target plays (`CastNowPlaying`): the artwork, the title and "Casting to <device>"; the seek
/// bar with the position and the duration (not live); Previous, back 10 s, Play/Pause, forward 10 s and Next; the
/// audio, subtitle and quality choices where the receiver offers them; the receiver's volume where it has one; then
/// Stop and Disconnect. While nothing plays, the receiver's name, "Ready to cast" and Disconnect.
///
/// Accessibility identifiers: `cast.controls.title`, `cast.controls.target`, `cast.controls.seek`,
/// `cast.controls.position`, `cast.controls.previous`, `cast.controls.seekBack`, `cast.controls.playPause`,
/// `cast.controls.seekForward`, `cast.controls.next`, `cast.controls.audio`, `cast.controls.subtitles`,
/// `cast.controls.quality`, `cast.controls.volume`, `cast.controls.stop`, `cast.controls.disconnect`.
struct CastControlsForm: View {
    let cast: CastModel

    var body: some View {
        let state = cast.senderState.state
        let sender = cast.sender
        Form {
            Section {
                HStack(spacing: 14) {
                    CastArtwork(url: state.nowPlaying?.artworkUrl, kind: state.target?.kind)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.nowPlaying?.title ?? state.receiverName)
                            .font(.headline)
                            .lineLimit(2)
                            .accessibilityIdentifier("cast.controls.title")
                        if let subtitle = state.nowPlaying?.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Palette.onSurfaceVariant)
                                .lineLimit(1)
                        }
                        // Nothing playing: the device's name over "Ready to cast", as the bar has it.
                        Text(state.nowPlaying == nil ? state.barIdleText ?? "" : T.shared.cast.bar.castingTo(name: state.receiverName))
                            .font(.footnote)
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .lineLimit(1)
                            .accessibilityIdentifier("cast.controls.target")
                    }
                }
            }
            if let playing = state.nowPlaying {
                Section {
                    if playing.canSeek {
                        CastSeekBar(playing: playing, sender: sender)
                    }
                    transport(playing, sender: sender)
                }
                if !playing.audioTracks.isEmpty || !playing.subtitleTracks.isEmpty || !playing.qualities.isEmpty {
                    Section {
                        choice(T.shared.cast.controls.audio, playing.audioTracks, id: "cast.controls.audio") { sender.selectAudio(key: $0) }
                        choice(T.shared.cast.controls.subtitles, playing.subtitleTracks, id: "cast.controls.subtitles") { sender.selectSubtitle(key: $0) }
                        choice(T.shared.cast.controls.quality, playing.qualities, id: "cast.controls.quality") { sender.selectQuality(key: $0) }
                    }
                }
                if let volume = playing.volume {
                    Section(T.shared.cast.controls.volume) {
                        CastVolume(volume: Int(volume.intValue), sender: sender)
                    }
                }
            }
            Section {
                if state.nowPlaying != nil {
                    Button(action: sender.stop) {
                        Label(T.shared.cast.controls.stop, systemImage: "stop.fill")
                    }
                    .accessibilityIdentifier("cast.controls.stop")
                }
                Button(role: .destructive, action: sender.disconnect) {
                    Label(T.shared.cast.controls.disconnect, systemImage: "xmark.circle").destructiveLabel()
                }
                .accessibilityIdentifier("cast.controls.disconnect")
            }
        }
        .settingsForm()
    }

    /// Previous, back 10 s, Play/Pause, forward 10 s and Next on one row (seeking only where the item seeks).
    private func transport(_ playing: CastNowPlaying, sender: CastSender) -> some View {
        HStack(spacing: 0) {
            control("backward.end.fill", T.shared.cast.controls.previous, "cast.controls.previous", enabled: playing.hasPrevious, action: sender.previous)
            if playing.canSeek {
                control("gobackward.10", T.shared.cast.controls.seekBack, "cast.controls.seekBack") { sender.seekBy(seconds: -10) }
            }
            control(
                playing.paused ? "play.fill" : "pause.fill", playing.paused ? T.shared.common.play : T.shared.common.pause,
                "cast.controls.playPause", size: 34, action: sender.togglePause
            )
            if playing.canSeek {
                control("goforward.10", T.shared.cast.controls.seekForward, "cast.controls.seekForward") { sender.seekBy(seconds: 10) }
            }
            control("forward.end.fill", T.shared.cast.controls.next, "cast.controls.next", enabled: playing.hasNext, action: sender.next)
        }
        .frame(maxWidth: .infinity)
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private func control(
        _ symbol: String, _ label: String, _ id: String, size: CGFloat = 22, enabled: Bool = true, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        #if !os(tvOS)
        .buttonStyle(.borderless)
        #endif
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    /// A choice of the receiver's (a track, a quality), the selected one checked; none without options.
    @ViewBuilder
    private func choice(_ title: String, _ options: [CastOption], id: String, select: @escaping (String) -> Void) -> some View {
        if !options.isEmpty {
            Picker(title, selection: Binding(get: { options.first(where: \.selected)?.key ?? "" }, set: select)) {
                ForEach(options, id: \.key) { option in
                    Text(option.detail.map { "\(option.label) · \($0)" } ?? option.label).tag(option.key)
                }
            }
            .accessibilityIdentifier(id)
        }
    }
}

/// The seek bar: the position and the duration under it; a drag seeks where it ends (`CastSender.seekTo`). Apple TV,
/// which has no slider, shows the played part; its row's ±10 s seek.
private struct CastSeekBar: View {
    let playing: CastNowPlaying
    let sender: CastSender

    /// The position a drag holds, until it ends.
    @State private var drag: Double?

    var body: some View {
        VStack(spacing: 4) {
            #if os(tvOS)
            ProgressView(value: Double(playing.progress))
                .accessibilityIdentifier("cast.controls.seek")
            #else
            Slider(
                value: Binding(get: { drag ?? playing.positionSeconds }, set: { drag = $0 }),
                in: 0...max(playing.durationSeconds, 1)
            ) { editing in
                if !editing, let drag {
                    sender.seekTo(seconds: drag)
                    self.drag = nil
                }
            }
            .accessibilityLabel(T.shared.cast.title)
            .accessibilityValue(playing.position)
            .accessibilityIdentifier("cast.controls.seek")
            #endif
            HStack {
                Text(playing.position).accessibilityIdentifier("cast.controls.position")
                Spacer()
                Text(playing.duration)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Palette.onSurfaceVariant)
        }
    }
}

/// The receiver's volume, 0–100: a slider that sets it as the drag ends; on Apple TV, which has no slider, quieter and
/// louder by 10.
private struct CastVolume: View {
    let volume: Int
    let sender: CastSender

    @State private var drag: Double?

    var body: some View {
        #if os(tvOS)
        HStack(spacing: 24) {
            Button { sender.setVolume(percent: Int32(max(0, volume - 10))) } label: {
                Image(systemName: "speaker.minus.fill")
            }
            .accessibilityLabel(T.shared.cast.controls.volume)
            Text("\(volume)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 60)
                .accessibilityIdentifier("cast.controls.volume")
            Button { sender.setVolume(percent: Int32(min(100, volume + 10))) } label: {
                Image(systemName: "speaker.plus.fill")
            }
            .accessibilityLabel(T.shared.cast.controls.volume)
        }
        .frame(maxWidth: .infinity)
        .focusSection()
        #else
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill").foregroundStyle(Palette.onSurfaceVariant)
            // No step: the Mac draws a stepped slider's tick marks under it. The volume sent is rounded.
            Slider(value: Binding(get: { drag ?? Double(volume) }, set: { drag = $0 }), in: 0...100) { editing in
                if !editing, let drag {
                    sender.setVolume(percent: Int32(drag.rounded()))
                    self.drag = nil
                }
            }
            .accessibilityLabel(T.shared.cast.controls.volume)
            .accessibilityValue("\(Int((drag ?? Double(volume)).rounded()))")
            .accessibilityIdentifier("cast.controls.volume")
            Image(systemName: "speaker.wave.3.fill").foregroundStyle(Palette.onSurfaceVariant)
        }
        #endif
    }
}

#if os(macOS)
/// The Mac's cast controls (`CastControlsForm`), docked at the window's trailing edge as the music's side panel is
/// (`macMusicPlayer`): its title over the form, Close (Escape) beside it, `CastSender.closeControls`.
///
/// Accessibility identifiers: `cast.controls`, `cast.controls.close` and the form's.
struct CastControlsPanel: View {
    let cast: CastModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(T.shared.cast.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                SheetCloseButton(title: T.shared.common.close, id: "cast.controls.close", action: cast.sender.closeControls)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            CastControlsForm(cast: cast)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cast.controls")
    }
}
#endif
