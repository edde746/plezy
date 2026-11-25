import SwiftUI
import PlezyKit

/// Now Playing's seek bar (`MusicProgress`): a thin track in the text colour on the outline, the times under its ends,
/// a thumb only while it is dragged. A drag seeks where it is let go. With a remote or a keyboard it takes focus (a
/// fill behind it) and left and right step 10 s, faster while held (`NowPlayingStore.stepSeek`), seeking once the key
/// is let go or focus leaves. It observes the playhead itself, so the screen around it never redraws for it.
struct MusicSeekBar: View {
    let progress: StoreObserver<MusicProgress>
    let store: NowPlayingStore

    @Environment(\.dimens) private var dimens
    @State private var dragFraction: Double?
    @FocusState private var focused: Bool
    #if os(tvOS)
    @State private var lastMove: (forward: Bool, at: Date)?
    #endif

    var body: some View {
        let unit = dimens.unit
        let progress = progress.state
        let fraction = dragFraction ?? Double(progress.fraction)
        let hasDuration = progress.durationMillis > 0
        VStack(spacing: 2 * unit) {
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.outline).frame(height: 4 * unit)
                    Capsule().fill(Palette.onBackground).frame(width: max(width * fraction, 0), height: 4 * unit)
                    if dragFraction != nil {
                        Capsule()
                            .fill(Palette.onBackground)
                            .frame(width: 4 * unit, height: 18 * unit)
                            .offset(x: min(max(width * fraction - 2 * unit, 0), width - 4 * unit))
                    }
                }
                .frame(height: proxy.size.height)
                .contentShape(Rectangle())
                #if !os(tvOS)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard hasDuration, width > 0 else { return }
                            dragFraction = min(max(value.location.x / width, 0), 1)
                        }
                        .onEnded { _ in
                            if let dragFraction { store.seekToFraction(fraction: Float(dragFraction)) }
                            dragFraction = nil
                        }
                )
                #endif
            }
            .frame(height: 20 * unit)
            HStack {
                Text(dragFraction.map { progress.positionAt(fraction: $0) } ?? progress.positionLabel)
                Spacer()
                Text(dragFraction.map { progress.remainingAt(fraction: $0) } ?? progress.remainingLabel)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(NowPlayingBackground.secondaryText)
            .padding(.horizontal, 24 * unit)
        }
        .padding(.vertical, 4 * unit)
        .background {
            if focused {
                RoundedRectangle(cornerRadius: Radius.large * unit, style: .continuous)
                    .fill(Palette.onBackground.opacity(FocusTokens.shared.TEXT_FILL_ALPHA))
            }
        }
        #if os(tvOS)
        .focusable()
        #else
        // A keyboard's focus only: a touch or a click drags.
        .focusable(interactions: .activate)
        #endif
        .focusEffectDisabled()
        .focused($focused)
        .onChange(of: focused) { _, now in if !now { store.endStepSeek() } }
        #if os(tvOS)
        .onMoveCommand { direction in
            let forward: Bool
            switch direction {
            case .left: forward = false
            case .right: forward = true
            default: return
            }
            // The remote repeats a held direction: a step the same way within a moment of the last is a repeat.
            let repeating = lastMove.map { $0.forward == forward && Date.now.timeIntervalSince($0.at) < 0.35 } ?? false
            lastMove = (forward, .now)
            store.stepSeek(forward: forward, repeat: repeating)
        }
        #else
        .onKeyPress(keys: [.leftArrow, .rightArrow], phases: [.down, .repeat, .up]) { press in
            if press.phase == .up {
                store.endStepSeek()
            } else {
                store.stepSeek(forward: press.key == .rightArrow, repeat: press.phase == .repeat)
            }
            return .handled
        }
        #endif
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(T.shared.music.nowPlaying)
        .accessibilityValue(progress.positionLabel)
        .accessibilityIdentifier("music.seekBar")
        .accessibilityAdjustableAction { direction in
            store.stepSeek(forward: direction == .increment, repeat: false)
            store.endStepSeek()
        }
        .task { await self.progress.observe() }
    }
}

/// The transport: Shuffle (in the text colour while on), Previous, Play/Pause (72 pt, a spinner while the track
/// loads), Next, Repeat (cycling off, all, one; in the text colour while on).
struct MusicTransport: View {
    let state: NowPlayingUiState
    let store: NowPlayingStore
    var focus: FocusState<NowPlayingFocus?>.Binding

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        HStack(spacing: 8 * unit) {
            MusicIconButton(systemImage: "shuffle", label: T.shared.common.shuffle, size: 22, id: "music.np.shuffle", isOn: state.shuffled, action: store.toggleShuffle)
            MusicIconButton(systemImage: "backward.end.fill", label: T.shared.music.previousTrack, size: 30, id: "music.np.previous", action: store.previous)
                .disabled(!state.canGoPrevious)
            PlayPauseButton(playing: state.isPlaying, loading: state.loading, action: store.togglePlayPause)
                .focused(focus, equals: .playPause)
            MusicIconButton(systemImage: "forward.end.fill", label: T.shared.music.nextTrack, size: 30, id: "music.np.next", action: store.next)
                .disabled(!state.canGoNext)
            MusicIconButton(
                systemImage: state.repeatMode.systemImage, label: state.repeatMode.label, size: 22,
                id: "music.np.repeat", isOn: state.repeatMode != .off, action: store.cycleRepeat
            )
        }
        .padding(.vertical, 8 * unit)
        .shelfFocusSection()
    }
}

/// The sleep timer's choices in the system's menu, in the video player's groups: Stop at (Off, End of track) and Timer
/// (the durations), the running one checked; the button a plain symbol among the controls beside it, a toggle's look
/// (`MusicIconButton`: muted while off, on a filled disc while a timer runs), naming the running choice to VoiceOver.
struct MusicSleepTimerMenu: View {
    let options: [SleepTimerOptionUi]
    let store: NowPlayingStore
    var size: CGFloat = 22
    var id = "music.np.sleep"

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        let selected = options.firstIndex(where: \.selected) ?? 0
        let indexed = Array(options.enumerated())
        Menu {
            Section(T.shared.videoControls.sleepTimerStopAtHeader) {
                choices(indexed.filter { !($0.element.choice is SleepTimerChoiceMinutes) })
            }
            Section(T.shared.videoControls.sleepTimerDurationHeader) {
                choices(indexed.filter { $0.element.choice is SleepTimerChoiceMinutes })
            }
        } label: {
            MusicSymbol(
                systemImage: selected == 0 ? "moon.zzz" : "moon.zzz.fill", size: size * unit,
                style: AnyShapeStyle(selected == 0 ? NowPlayingBackground.secondaryText : ToggleDisc.symbol)
            )
            .frame(width: (size + 22) * unit, height: (size + 22) * unit)
            .contentShape(Circle())
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(SurfaceButtonStyle(fill: selected == 0 ? .clear : ToggleDisc.fill, radius: (size + 22) * unit / 2))
        #if os(macOS)
        .tooltip(T.shared.music.sleepTimer)
        #endif
        .accessibilityLabel(T.shared.music.sleepTimer)
        .accessibilityValue(options.indices.contains(selected) ? options[selected].label : "")
        .accessibilityIdentifier(id)
    }

    /// A toggle per choice: the system's menu checks the running one.
    private func choices(_ entries: [(offset: Int, element: SleepTimerOptionUi)]) -> some View {
        ForEach(entries, id: \.offset) { index, option in
            Toggle(option.label, isOn: Binding(get: { option.selected }, set: { _ in store.setSleepTimer(choice: option.choice) }))
                .accessibilityIdentifier("music.sleep.\(index)")
        }
    }
}

#if os(macOS)
/// The Mac's volume: the level's speaker and a slider (0–100) `width` wide; a drag is heard at once (`previewVolume`)
/// and kept when let go (`commitVolume`).
struct MusicVolumeCluster: View {
    let volume: StoreObserver<KotlinDouble>
    let store: NowPlayingStore
    var width: CGFloat = 140
    var id = "music.np.volume"

    @State private var dragging: Double?

    var body: some View {
        let value = dragging ?? volume.state.doubleValue
        HStack(spacing: 4) {
            Image(systemName: symbol(MusicUiKt.volumeLevel(volume: value)))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(width: 22)
            Slider(
                value: Binding(get: { value }, set: { dragging = $0; store.previewVolume(volume: $0) }),
                in: 0...100
            ) { editing in
                if !editing, let dragging {
                    store.commitVolume(volume: dragging)
                    self.dragging = nil
                }
            }
            .tint(Palette.onBackground)
            .frame(width: width)
            .accessibilityIdentifier(id)
        }
        .task { await volume.observe() }
    }

    private func symbol(_ level: VolumeLevel) -> String {
        switch level {
        case .off: "speaker.slash.fill"
        case .low: "speaker.wave.1.fill"
        default: "speaker.wave.3.fill"
        }
    }
}
#endif
