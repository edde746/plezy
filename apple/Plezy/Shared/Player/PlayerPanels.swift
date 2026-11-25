import SwiftUI
import PlezyKit

/// What the Apple TV's panel shows, from the store's state: the open menu's card (`PlayerMenu.parent`: a delay and an
/// audio setting's page belong to their track menu, More subtitles, its languages and the subtitle search to the
/// subtitles, an option's page to the options, and here the watch-together room panel too); nil while no menu is open.
/// The chapters and the queue are the tabs of the panel across the bottom, as AVKit's info panel has them; each other
/// menu opens a card of its own above its button.
enum PlayerPanelTab: Hashable {
    case chapters
    case queue
    case subtitles
    case audio
    case options

    init?(_ state: PlayerUiState) {
        switch state.menu?.parent {
        case .audio, .audioChannels, .audioOutput: self = .audio
        case .subtitles, .tracks, .subtitleSearch: self = .subtitles
        case .chapters, .contentStrip: self = .chapters
        case .queue: self = .queue
        case nil: return nil
        // The options, and the room panel, a page of the Options tab on Apple TV.
        case .options, .speed, .customSpeed, .subtitleDelay, .audioDelay, .moreSubtitles, .subtitleLanguage, .videoFit, .zoom,
             .shaders, .sleepTimer, .watchTogether, .versions, .fileInfo, .dolbyVisionConversion, .httpStatus:
            self = .options
        }
    }

    /// A tab of the panel across the bottom (`PlayerTVPanel`), not a menu's card above its button.
    var isPanelTab: Bool { self == .chapters || self == .queue }
}

/// The prompt button (`PlayerUiState.prompt`): the skip button (`player.skip`, "Skip intro" after a fast-forward
/// symbol) or up next (`player.upNext`, "S1E2 · Please Remain Calm" after a skip-next symbol, the shuffle symbol from a
/// shuffled queue), one capsule on the
/// player's glass. Pressing it does the store's `PlayerPrompt.command` (skip the segment, play the next episode). While
/// it counts down (an automatic skip, auto-play of the next episode) a white fill grows from its leading edge, a step
/// every tenth of a second (`PlayerPrompt.progress`); the store stops that at any input, which leaves the plain button.
/// It hugs its label up to the width the corner gives it (`PlayerOverlay`), past which the label's text is cut short
/// and its lead (the episode's code) never is. It takes focus on tvOS as it comes up by itself (`PlayerFocus.prompt`;
/// not as it comes back with the controls past its own seconds, `PlayerPrompt.withControls`), where Select presses it
/// and the remote's moves go to the store (with the controls down, Down brings them up and left and right scrub; with
/// them up the store leaves the moves to focus); the video layer stays disabled meanwhile, so a press never reaches the
/// store's Select as well. VoiceOver reads what it does (`PlayerPrompt.label`: up next's says it plays the next
/// episode) and, while it counts down, the seconds left (`PlayerPrompt.countdown`).
struct PlayerPromptButton: View {
    let prompt: PlayerPrompt
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        let upNext = prompt.kind == .upNext
        Button {
            store.dispatch(command: prompt.command)
        } label: {
            Label {
                HStack(spacing: 0) {
                    if let lead = prompt.lead { Text(lead).fixedSize() }
                    Text(prompt.text).truncationMode(.tail)
                }
            } icon: {
                Image(systemName: upNext ? (prompt.shuffled ? "shuffle" : "forward.end.fill") : "forward.fill")
            }
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(CountdownButtonStyle(progress: prompt.progress?.doubleValue, step: 0.1))
        .playerGlass(in: Capsule())
        .focused(focus, equals: .prompt)
        #if os(tvOS)
        .onMoveCommand { direction in
            switch direction {
            case .up: RemotePress.send(.up, to: store)
            case .down: RemotePress.send(.down, to: store)
            case .left: RemotePress.send(.left, to: store)
            case .right: RemotePress.send(.right, to: store)
            @unknown default: break
            }
        }
        #endif
        .accessibilityLabel(prompt.label)
        .accessibilityValue(prompt.countdown ?? "")
        .accessibilityIdentifier(upNext ? "player.upNext" : "player.skip")
    }
}

/// The sleep timer's question as a card above the prompt button (`player.stillWatching`), as wide as the corner it
/// sits in (`PlayerOverlay`): a small "Pausing in 25 seconds" (`StillWatchingState.countdown`, also the card's
/// accessibility value), the line "Still watching?", then Continue (`KeepWatching`) and Pause. Pause, what happens once
/// the countdown runs out, fills from its leading edge as it does (`StillWatchingState.progress`); Continue takes focus
/// on tvOS (`PlayerFocus.stillWatching`). The question is announced as the card shows, not the countdown's ticks.
struct PlayerStillWatchingCard: View {
    let stillWatching: StillWatchingState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: PlayerMetrics.cardSpacing) {
            Text(stillWatching.countdown)
                .font(PlayerMetrics.cardLabelFont)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityIdentifier("player.stillWatching.countdown")
            Text(T.shared.player.stillWatching.title).font(PlayerMetrics.cardTitleFont).lineLimit(1)
            CardButtons { insets in
                Button(T.shared.player.stillWatching.keepWatching) { store.dispatch(command: PlayerCommandKeepWatching.shared) }
                    .buttonStyle(CountdownButtonStyle(progress: nil, insets: insets))
                    .focused(focus, equals: .stillWatching)
                    .accessibilityIdentifier("player.stillWatching.keepWatching")
                Button(T.shared.player.stillWatching.pause) { store.dispatch(command: PlayerCommandPause.shared) }
                    .buttonStyle(CountdownButtonStyle(progress: Double(stillWatching.progress), insets: insets))
                    .accessibilityValue(stillWatching.countdown)
                    .accessibilityIdentifier("player.stillWatching.pause")
            }
            .padding(.top, PlayerMetrics.cardSpacing)
        }
        .padding(PlayerMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .playerGlass(in: RoundedRectangle(cornerRadius: PlayerMetrics.cardRadius, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityValue(stillWatching.countdown)
        .accessibilityIdentifier("player.stillWatching")
        .announcing(T.shared.player.stillWatching.title)
    }
}

/// A card's two buttons side by side. On iOS, where the card is narrowed beside the centre transport (an iPhone in
/// landscape), with less room inside them (`PlayerMetrics.cardNarrowButtonInsets`), else one above the other.
private struct CardButtons<Buttons: View>: View {
    @ViewBuilder let buttons: (EdgeInsets) -> Buttons

    var body: some View {
        #if os(iOS)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PlayerMetrics.cardButtonSpacing) { buttons(PlayerMetrics.cardButtonInsets) }
            HStack(spacing: PlayerMetrics.cardButtonSpacing) { buttons(PlayerMetrics.cardNarrowButtonInsets) }
            VStack(alignment: .leading, spacing: PlayerMetrics.cardButtonSpacing) { buttons(PlayerMetrics.cardButtonInsets) }
        }
        #else
        HStack(spacing: PlayerMetrics.cardButtonSpacing) { buttons(PlayerMetrics.cardButtonInsets) }
        #endif
    }
}

/// The corner's capsules, the still-watching card's two buttons and the prompt button: a translucent white capsule with
/// white text; with `progress` (Pause, a counting prompt) a solid white fill grows over it from the leading edge, the
/// text turning black where the fill has reached, running on through each `step` (seconds) of the countdown. tvOS:
/// focus brightens the capsule and rings it inside its edge (one without a countdown turns white with black text),
/// without growing it, so a card's two keep one height, and a click shrinks it a little (`tvPressed`); elsewhere a
/// press dims it and keyboard focus rings it.
private struct CountdownButtonStyle: ButtonStyle {
    let progress: Double?
    var step: Double = 1
    /// Room around the label inside the capsule.
    var insets = PlayerMetrics.cardButtonInsets

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, progress: progress, step: step, insets: insets)
    }

    private struct Face: View {
        let configuration: Configuration
        let progress: Double?
        let step: Double
        let insets: EdgeInsets

        @Environment(\.isFocused) private var focused

        var body: some View {
            // A button without a countdown focused on tvOS is white throughout, as the player's other focused buttons are.
            let filled = CGFloat(min(max(progress ?? (tvFocused ? 1 : 0), 0), 1))
            let label = configuration.label
                .font(PlayerMetrics.cardButtonFont)
                .lineLimit(1)
                .padding(insets)
            ZStack {
                label.foregroundStyle(Palette.onVideo)
                // The same label again, black under the fill: drawn only, or the button would say its label twice.
                label.foregroundStyle(Color.black).mask(alignment: .leading) { fillShape(filled) }.accessibilityHidden(true)
            }
            .background {
                Capsule()
                    .fill(Palette.onVideo.opacity(tvFocused ? 0.45 : 0.22))
                    .overlay(alignment: .leading) { fillShape(filled).foregroundStyle(Palette.onVideo) }
                    .clipShape(Capsule())
            }
            .contentShape(Capsule())
            // The countdown moves a step at a time: the fill runs on through each step.
            .animation(progress == nil ? nil : .linear(duration: step), value: filled)
            #if os(tvOS)
            .overlay { if focused { Capsule().strokeBorder(Palette.onVideo, lineWidth: 4) } }
            .shadow(color: .black.opacity(focused ? 0.4 : 0), radius: 12, y: 6)
            .animation(.easeOut(duration: 0.15), value: focused)
            .tvPressed(configuration.isPressed)
            #else
            .opacity(configuration.isPressed ? 0.75 : 1)
            .focusRing(radius: 22)
            #endif
        }

        private var tvFocused: Bool {
            #if os(tvOS)
            focused
            #else
            false
            #endif
        }

        /// The filled part: `fraction` of the width from the leading edge.
        private func fillShape(_ fraction: CGFloat) -> some View {
            GeometryReader { geometry in
                Rectangle().frame(width: geometry.size.width * fraction)
            }
        }
    }
}

/// The failure with its buttons (`ErrorState.buttons`, in order; `player.error.<action>`: retry, transcode, close), full
/// screen: the player is black behind it from edge to edge (`PlayerOverlay`, under the top bar's close, the Mac's back
/// and title, Apple TV's title), and the symbol, the texts and the buttons sit on that, centred, with no card around
/// them; the texts within `PlayerMetrics.errorMaxWidth`. The buttons are the player's panel buttons
/// (`playerActionStyle`: glass, the primary one prominent), side by side where they fit the screen's width, else one
/// above the other, each as wide as the others
/// (`PlayerMetrics.errorStackedWidth`); an upright iPhone (or an iPad window as narrow) always stacks them. The primary
/// one takes focus on tvOS (`PlayerFocusContext.error`), where the failure is announced; on iPhone, iPad and the Mac
/// VoiceOver moves to its title as it shows.
struct PlayerErrorPanel: View {
    let error: ErrorState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding
    @AccessibilityFocusState private var titleFocused: Bool

    @ScaledMetric(relativeTo: .title) private var symbolSize: CGFloat = 36
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var widthClass
    @Environment(\.verticalSizeClass) private var heightClass
    #endif

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: symbolSize))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                Text(error.title).font(.title2.weight(.bold)).multilineTextAlignment(.center)
                    .accessibilityFocused($titleFocused)
                Text(error.message).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: PlayerMetrics.errorMaxWidth)
            Group {
                if upright {
                    stacked
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PlayerMetrics.errorActionSpacing) { actions(stacked: false) }
                        stacked
                    }
                }
            }
            // The buttons' glass, one row or column of it.
            .glassGroup(spacing: PlayerMetrics.errorActionSpacing)
            .padding(.top, 18)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("player.error")
        .task(id: error.message) {
            #if os(tvOS)
            announce(error.title + "\n" + error.message)
            #else
            titleFocused = true
            #endif
        }
        .padding(24)
    }

    /// A narrow, tall screen (an upright iPhone, an iPad window as narrow): the buttons one above the other.
    private var upright: Bool {
        #if os(iOS)
        widthClass == .compact && heightClass == .regular
        #else
        false
        #endif
    }

    private var stacked: some View {
        VStack(spacing: PlayerMetrics.errorActionSpacing) { actions(stacked: true) }
            .frame(maxWidth: PlayerMetrics.errorStackedWidth)
    }

    /// The buttons; `stacked`, each as wide as the column they are in.
    private func actions(stacked: Bool) -> some View {
        ForEach(error.buttons, id: \.action) { button in
            Button { store.dispatch(command: button.command) } label: {
                Text(button.label).lineLimit(1).frame(maxWidth: stacked ? .infinity : nil)
            }
            .playerActionStyle(prominent: button.primary)
            .focused(focus, equals: .error(button.action))
            .accessibilityIdentifier(button.action.identifier)
        }
    }
}

extension ErrorAction {
    /// The button's accessibility identifier: `player.error.retry`.
    var identifier: String { "player.error.\((self as __ErrorAction).probeName)" }
}

/// A transient message (volume, speed, a track change by key, a room's notice; `player.osd`), after its symbol where it
/// has one (`PlayerUiState.osdIcon`).
struct PlayerOsdMessage: View {
    let text: String
    var icon: OsdIcon?

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let icon { Image(systemName: icon.systemImage) }
        }
        .labelStyle(.titleAndIcon)
        .font(.headline)
        .padding(.horizontal, 18)
        #if os(macOS)
        // Back's height: on the title row it sits level with back and as tall (`PlayerOverlay`).
        .frame(height: PlayerMetrics.button)
        #else
        .padding(.vertical, 8)
        #endif
        .playerGlass(in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityIdentifier("player.osd")
    }
}

/// The level a swipe changed (`PlayerUiState.level`), at the edge of the side swiped (`PlayerOverlay`): an upright
/// capsule filled from the bottom to the level in light grey, the brightness's or the volume's symbol
/// and the percent in its middle, white over the rest and dark over the fill; read as the level's label
/// (`player.level`). On iOS and iPadOS 26 the capsule is the player's clear glass (`playerGlass`), whose dimming is the
/// unfilled track; before 26 it is dark (darker over an HDR picture, `ControlsScrim`) with a light track. In the glass
/// the fill is solid, not white-tinted glass: on iOS 27 the tinted glass came out as white as a white sky behind it
/// (243 against 244-255) and the clear glass's tint streaked round the symbol, where the solid fill stays apart from
/// white (225) and from black (194), so the level and the dark symbol and percent on it read over either.
struct PlayerLevelIndicator: View {
    let level: LevelIndicator
    @Environment(\.hdrPicture) private var hdr

    /// Its distance in from the safe area's edge.
    static let edge: CGFloat = 20
    private static let size = CGSize(width: 54, height: 184)

    var body: some View {
        capsule
            .animation(.linear(duration: 0.09), value: level.fraction)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(level.label)
            .accessibilityIdentifier("player.level")
    }

    @ViewBuilder private var capsule: some View {
        #if os(iOS)
        if PlayerMetrics.clearGlass {
            levels(track: .clear)
                .clipShape(Capsule())
                .playerGlass(in: Capsule())
        } else {
            dark
        }
        #else
        dark
        #endif
    }

    /// The capsule before iOS 26.
    private var dark: some View {
        levels(track: Palette.onVideo.opacity(0.14))
            .background(Color.black.opacity(Double(ControlsScrim.shared.alpha(alpha: 0.6, hdr: hdr))))
            .clipShape(Capsule())
    }

    /// The track, the fill from the bottom to the level, and the symbol and percent over both.
    private func levels(track: Color) -> some View {
        let fill = Self.size.height * CGFloat(level.fraction)
        return ZStack {
            track
            content.foregroundStyle(Palette.onVideo)
            Palette.onVideo.opacity(0.74)
                .frame(height: fill)
                .frame(maxHeight: .infinity, alignment: .bottom)
            content.foregroundStyle(Color.black.opacity(0.86))
                .mask {
                    Rectangle()
                        .frame(height: fill)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    /// The symbol over the percent, centred in the whole capsule (so the fill's mask lines up with it).
    private var content: some View {
        VStack(spacing: 6) {
            Image(systemName: level.kind == .brightness ? "sun.max.fill" : "speaker.wave.2.fill")
                .font(.system(size: 24))
            Text(level.percent)
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The speed a finger held on the video plays at ("2×", `PlayerUiState.heldSpeed`), as the transient message looks on
/// a touch screen (`player.heldSpeed`).
struct PlayerHeldSpeedMessage: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "forward.fill")
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .playerGlass(in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityIdentifier("player.heldSpeed")
    }
}

#if os(iOS)
/// The locked screen (`PlayerUiState.screenLock`): a shield over the whole player that takes every touch and gives it
/// to the store as it is (`PlayerTouchSurface`), which makes a tap show or hide the unlock button and a second finger
/// hide it, with the unlock button at the top centre while it shows (`player.unlock`). A finger or a pointer that goes
/// down on the button is `PlayerCommand.UnlockHold` until it lifts, which unlocks once held long enough
/// (`UnlockButton.HOLD_MILLIS`). VoiceOver activates the button as a button, which unlocks at once.
struct ScreenLockShield: View {
    let lock: ScreenLockState
    let store: PlayerStore
    @Environment(\.hdrPicture) private var hdr

    /// The button's frame in global coordinates, as it last laid out.
    @State private var buttonFrame = CGRect.null

    var body: some View {
        ZStack(alignment: .top) {
            PlayerTouchSurface(store: store, holdArea: lock.unlock == nil ? .null : buttonFrame)
                .ignoresSafeArea()
                .accessibilityIdentifier("player.lockShield")
            if let unlock = lock.unlock {
                pill(unlock)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { buttonFrame = $0 }
                    // The shield under it tells a finger on it from one beside it.
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(unlock.label)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { store.dispatch(command: PlayerCommandUnlockPress.shared) }
                    .accessibilityIdentifier("player.unlock")
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lock.unlock == nil)
    }

    /// A dark capsule (black 60 %, darker over an HDR picture: `ControlsScrim`, as the level and the held speed's
    /// grounds) with the lock and "Hold to unlock" in white, which reads at least 4.5:1 over a white frame; the clear
    /// glass of the other chips lets a bright frame through. While held, a white fill grows across it from its leading
    /// edge over the hold's length, the lock and the text black where it covers them; let go, the fill is gone.
    private func pill(_ unlock: UnlockButton) -> some View {
        let label = Label(unlock.label, systemImage: "lock.fill")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        let filled: CGFloat = unlock.holding ? 1 : 0
        return ZStack {
            label.foregroundStyle(Palette.onVideo)
            // The same label again, black under the fill: drawn only, or the button would say its label twice.
            label.foregroundStyle(Color.black).mask(alignment: .leading) { fill(filled) }.accessibilityHidden(true)
        }
        .background(alignment: .leading) { fill(filled).foregroundStyle(.white) }
        .background(Color.black.opacity(Double(ControlsScrim.shared.alpha(alpha: 0.6, hdr: hdr))))
        .clipShape(Capsule())
        .animation(unlock.holding ? .linear(duration: Double(UnlockButton.companion.HOLD_MILLIS) / 1000) : nil, value: filled)
    }

    /// The fill, `fraction` of the pill's width from its leading edge.
    private func fill(_ fraction: CGFloat) -> some View {
        GeometryReader { proxy in
            Rectangle().frame(width: proxy.size.width * fraction)
        }
    }
}
#endif
