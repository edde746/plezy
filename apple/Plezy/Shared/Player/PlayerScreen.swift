import SwiftUI
import PlezyKit

#if os(macOS) || os(tvOS)
import Combine
#endif

#if os(macOS)
import Carbon.HIToolbox
#endif

/// The player (the shared `PlayerStore` decides, this only renders its state and forwards input): mpv's
/// surface under a layer of controls (`PlayerOverlay`). Input goes to the store's keymap first, as the platform's raw
/// events:
///
/// - iOS: the fingers on the video as they are (`PlayerTouchSurface`): the store makes skips, taps, holds, two-finger
///   taps, pinches and edge swipes of them (the brightness and the volume through `TouchLevels`, whose volume control
///   sits hidden among these views); a trackpad's, mouse's or Pencil's click as a click; a hardware keyboard's keys,
///   and its Tab's focus moves as `FocusMove`; an iPad's trackpad or mouse pointer moves (over the controls or not), as
///   the Mac's.
///   While the screen is locked (`ScreenLockShield`) a shield over everything takes every touch instead, for the store
///   to show the unlock button by (a finger or pointer held on the button as `UnlockHold`).
/// - macOS: clicks with their click count, pointer moves (over the controls or not), keys with key-up and repeats:
///   Space, the arrows, F for full screen, Esc and the rest of the shared desktop keymap; Tab between the controls as
///   `FocusMove`; the scroll wheel over the video (`PlayerScrollWheel`), which the keymap turns into the volume.
/// - tvOS: the Siri Remote's click-pad presses, Select and Back as key presses while the controls are down (left/right
///   seek, Select pauses), Play/Pause as the OS media controls' toggle (`NowPlayingCenter.remotePlayPause`), controls
///   up or down; with the controls up the focus engine moves between them (the TV keymap leaves
///   the D-pad alone then, but for left and right on the focused timeline, which scrub) and focus follows the store as
///   the Compose TV player's does. The prompt button (skip, up next) takes the remote's presses while it has focus:
///   Select is its own (the video layer is disabled meanwhile, so the store's Select never presses it a second time),
///   its moves go to the store. The focus engine's moves at the user's hand reach the store as `FocusMove`. A horizontal
///   swipe on the touch surface scrubs the timeline (not while live, which has none and seeks nothing); a swipe down
///   opens the playback info, as in the system player.
///
/// Whatever the store leaves alone falls through: Back with nothing left to back out of (a scrub, a menu, the prompt
/// button, the info panel, the controls) closes the player. On iOS VoiceOver's escape does the same.
///
/// While VoiceOver or Switch Control runs the store keeps the controls up (`PlayerStore.onAssistiveTechnologyChanged`):
/// they move through them one at a time, at their own pace.
///
/// While the controls show, subtitles move up clear of them: the view reports how much of the video surface the bottom
/// controls cover (`PlayerStore.onControlsHeightChanged`), none while picture in picture shows the video instead; the
/// engine lifts the subtitles by the part of that over the frame mpv places them in (on iOS the picture).
struct PlayerScreen: View {
    let playback: PlayerModel

    @FocusState private var focus: PlayerFocus?
    /// The video surface's frame and the top of the bottom controls, in global coordinates.
    @State private var surfaceFrame = CGRect.zero
    @State private var controlsTop: CGFloat?
    #if os(tvOS)
    /// The layers focus last followed.
    @State private var focusContext: PlayerFocusContext?
    /// What the open panel gives focus back to as it closes (`PlayerFocus.panelOpener`), taken as it opens: the
    /// playback info opened from the options keeps the options button.
    @State private var panelOpener: PlayerFocus?
    /// The transport bar's menu buttons that show and can take focus, by the tab each opens (`PlayerMenuButtonFrames`).
    @State private var menuButtons: Set<PlayerPanelTab> = []
    #endif
    #if os(macOS)
    /// The window's buttons for the title row in full screen (`PlayerWindowChrome`).
    @State private var windowButtons: PlayerWindowButtons?
    /// The pop-up menus AppKit tracks (a submenu counts as its own), and what keeps the controls up meanwhile.
    @State private var menusTracking = 0
    @State private var menuHold: Task<Void, Never>?
    #endif
    #if os(iOS) || os(macOS)
    /// The options menu's Shaders open dialog and delete question, which outlast the controls (`ShaderPrompts`).
    @State private var shaderPrompts = ShaderPrompts()
    #endif
    #if os(iOS)
    /// The controls draw from the cover's second frame on: its first, which brings the player up, holds the video's
    /// surface alone, so the main thread gets to the video's start sooner.
    @State private var controlsDrawn = false
    /// The video's first frame has shown: the system's volume control and picture in picture are set up from then on,
    /// not in the frames that bring the player up.
    @State private var videoShown = false
    #else
    private let controlsDrawn = true
    #endif
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    var body: some View {
        let state = playback.state.state
        let store = playback.store
        ZStack {
            #if os(iOS)
            if videoShown {
                SystemVolumeControl()
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            #endif
            VideoSurfaceHost(surface: playback.surface)
                #if os(iOS)
                // The picture keeps clear of what the safe area holds at the sides, an iPhone's sensor housing in
                // landscape (the iPhone Duo's cover wider than the picture's bars), as the controls over it do; along the
                // top and bottom it runs to the edges.
                .ignoresSafeArea(edges: .vertical)
                #else
                .ignoresSafeArea()
                #endif
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { surfaceFrame = $0 }
            // Its taps seek on the side of the screen they land on, in every language, as the timeline runs.
            #if os(macOS)
            PlayerInputLayer(
                state: state,
                timeline: playback.videoTimeline,
                store: store,
                focus: $focus,
                commands: PlaybackCommands(state: state, store: store, pictureInPicture: playback.surface.pictureInPicture)
            )
            .environment(\.layoutDirection, .leftToRight)
            #else
            PlayerInputLayer(state: state, timeline: playback.videoTimeline, store: store, focus: $focus)
                .environment(\.layoutDirection, .leftToRight)
            #endif
            if controlsDrawn {
                PlayerOverlay(playback: playback, state: state, focus: $focus) { controlsTop = $0 }
                    #if os(macOS)
                    .environment(\.playerWindowButtons, windowButtons)
                    #endif
                    #if os(iOS)
                    // In landscape nothing of the system's sits along the top edge (an iPhone's sensor housing is at a
                    // side, the status bar is hidden), yet iOS 27.1 gives the iPhone Duo's cover, its vertical bar off for
                    // the player (`verticalBarDisabled`), an 82 pt top safe area there, which put the top bar on the
                    // picture.
                    .ignoresSafeArea(edges: surfaceFrame.width > surfaceFrame.height ? .top : [])
                    #endif
            }
            #if os(iOS)
            // Over everything else: no touch reaches what lies under a locked screen.
            if let lock = state.screenLock { ScreenLockShield(lock: lock, store: store) }
            #endif
            #if DEBUG
            PlayerProbes(playback: playback)
            #endif
        }
        #if os(iOS)
        // VoiceOver's escape (a two-finger scrub) backs out as Back does: a menu, the prompt, then the player.
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { store.dispatch(command: PlayerCommandBack.shared) }
        #endif
        .background(.black)
        .environment(\.colorScheme, .dark)
        .environment(\.hdrPicture, state.hdrPicture)
        // Everything over the video draws in white, `.secondary` in its 60 % (`Palette.onVideo`). tvOS keeps the
        // system's tint (`plezyTheme`); its buttons turn their symbols dark themselves under focus.
        .foregroundStyle(Palette.onVideo, Palette.onVideoSecondary)
        #if !os(tvOS)
        .tint(Palette.onVideo)
        #endif
        .task { await playback.state.observe() }
        #if os(iOS)
        .task { controlsDrawn = true }
        .onChange(of: state.hasFirstFrame, initial: true) { _, shown in
            guard shown, !videoShown else { return }
            videoShown = true
            playback.surface.pictureInPicture.setUp()
        }
        // The player holds landscape while the rotation lock is on and lets every orientation go as it closes; a turn
        // asked for waits for the one under way.
        .background(PlayerOrientation.Transitions())
        .onAppear { PlayerOrientation.playerShown(true, rotationLocked: state.rotationLocked?.boolValue ?? true) }
        .onDisappear { PlayerOrientation.playerShown(false, rotationLocked: state.rotationLocked?.boolValue ?? true) }
        .onChange(of: state.rotationLocked?.boolValue) { _, locked in
            if let locked { PlayerOrientation.rotationLockChanged(locked) }
        }
        #endif
        // The video's position value (`player.video`) follows the timeline while an assistive technology runs, which
        // reads it there (the store keeps the controls up meanwhile, so the timeline shows too).
        .task(id: assistiveTechnology) {
            if assistiveTechnology { await playback.videoTimeline.observe() }
        }
        .onChange(of: subtitleLift, initial: true) { _, lift in store.onControlsHeightChanged(fraction: lift) }
        // VoiceOver and Switch Control move through the controls one at a time: the store keeps them up meanwhile.
        .onChange(of: assistiveTechnology, initial: true) { _, running in store.onAssistiveTechnologyChanged(running: running) }
        // The end time and a live window's clock times on the system's 12/24-hour clock, again when it changes.
        .onAppear { store.setUse24HourClock(value: LiveTvClock.uses24Hour) }
        .onClockChange { store.setUse24HourClock(value: $0) }
        #if os(tvOS)
        // Wherever focus is (the video, a control), the remote's Back goes to the store; its Play/Pause, which tvOS
        // hands the command center instead while the video plays, is one toggle with the command center's.
        .onPlayPauseCommand { playback.nowPlaying.remotePlayPause() }
        .onExitCommand {
            if !RemotePress.send(.back, to: store) { store.dispatch(command: PlayerCommandBack.shared) }
        }
        .background {
            RemoteSwipe(store: store, scrubs: swipeScrubs(state), opensPanel: swipeOpensPanel(state))
        }
        .onPreferenceChange(PlayerMenuButtonFrames.self) { menuButtons = Set($0.keys) }
        // After the update that changed the layers, once the views that take focus exist.
        .task(id: PlayerFocusContext(state)) {
            let new = PlayerFocusContext(state)
            // The first state counts as a change from nothing up: a prompt button or a card already there as the player
            // opens (a play resumed inside an intro) takes focus as it would coming up later.
            let old = focusContext ?? .opening
            focusContext = new
            if new.panel != nil, old.panel == nil { panelOpener = PlayerFocus.panelOpener(state) }
            let target = PlayerFocus.target(from: old, to: new, focused: focus, opener: panelOpener, menuButtons: menuButtons, state: state)
            guard let target else { return }
            // The card's row that had focus went with the card while SwiftUI still held the opener as focused (picking
            // Reset on the zoom page left the remote with nothing focused, More drawn as focused): the target is set
            // again from nothing, so the focus system moves there.
            if focus == target, !Self.focusSystemHasFocus {
                focus = nil
                await Task.yield()
            }
            // When the focused view goes with the change (the menu entry that opened a delay control), tvOS picks the
            // next focus itself a moment later, over this one: the target is set again until it holds, or the user
            // moves focus.
            await FocusRestore.restore($focus, to: target, replacing: true)
        }
        .onChange(of: focus) { _, new in
            store.onTimelineFocusChanged(focused: new == .scrub)
        }
        // A key brought the controls up for the remote to move through: focus goes to the timeline (live: play/pause),
        // unless a menu is open.
        .onChange(of: state.playPauseFocus) { _, serial in
            guard serial > 0, state.controlsVisible, state.menu == nil else { return }
            focus = PlayerFocus.home(state)
        }
        #endif
        #if os(tvOS) || os(iOS)
        // Moving focus with the remote, or with an iPad keyboard's Tab, is using the player: the store sees no key for
        // it, so it hears it as a focus move, which keeps the controls up and stops the prompt's countdown. Only the
        // user's moves, the focus system's updates with a heading: not focus set by the player or by tvOS as a focused
        // view goes.
        .onReceive(NotificationCenter.default.publisher(for: UIFocusSystem.didUpdateNotification)) { notification in
            guard let context = notification.userInfo?[UIFocusSystem.focusUpdateContextUserInfoKey] as? UIFocusUpdateContext,
                  !context.focusHeading.isEmpty else { return }
            _ = store.onInput(event: InputEventFocusMove.shared)
        }
        #endif
        #if os(iOS)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        // The screen's brightness, system-wide, is the screen's own again while picture in picture shows the video.
        .onChange(of: playback.surface.pictureInPicture.showsVideo) { _, shows in
            if shows { TouchLevels.shared.restoreBrightness() }
        }
        #endif
        #if os(iOS) || os(macOS)
        // The sheets over the player, the room's sheet and the shaders' prompts (`PlayerSheets`).
        .playerSheets(playback: playback, prompts: shaderPrompts)
        #endif
        // The watch-together room's question when it offers a copy of another length.
        .watchMismatchPrompt(state, store: store)
        #if os(macOS)
        // Tab and Shift-Tab (its back tab) moving keyboard focus between the controls is using the player, as on iPad:
        // a focused control keeps the keys from the video's layer, so the store hears the move here and keeps the
        // controls up.
        .onKeyPress(keys: [.tab, KeyEquivalent("\u{19}")]) { _ in
            _ = store.onInput(event: InputEventFocusMove.shared)
            return .ignored
        }
        // Over the video the pointer goes with the controls; moving it brings both back (a pointer move).
        .onChange(of: state.controlsVisible) { _, visible in NSCursor.setHiddenUntilMouseMoves(!visible) }
        // The window's toolbar and title step aside for the player's own; its buttons come and go with the controls,
        // in full screen as copies on the title row. A pointer move over the player brings the controls up and keeps
        // them there; the pointer leaving the window hides them at once; under another app's window over this one (the
        // menu bar in full screen), or where a menu of the controls left it (below the window after a pick), it is off
        // them.
        .background {
            PlayerWindowChrome(controlsVisible: state.controlsVisible) {
                store.onFullscreenChanged(fullscreen: $0)
            } onWindowButtons: {
                windowButtons = $0
            } onPointerExit: {
                _ = store.onInput(event: InputEventPointerExit.shared)
            } onPointerMove: {
                _ = store.onInput(event: InputEventPointerMove.shared)
            }
        }
        // A menu of the controls is open while AppKit tracks it: the store opens its menu (the button the pointer was
        // last over), and the controls stay up all the while, as the pointer moving keeps them (`holdForMenus`): a
        // click that opened the menu without a hover first (a synthesized one) names no button, and the controls going
        // down under an open submenu would take it away with the pick in it.
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { notification in
            guard Self.isPlayerMenu(notification) else { return }
            if menusTracking == 0 { PlayerMenuTracking.opened = store.state.value }
            menusTracking += 1
            holdForMenus()
            guard Self.isPopUpMenu(notification), store.state.value.menu == nil, let menu = PlayerMenuTracking.hovered else { return }
            store.dispatch(command: PlayerCommandOpenMenu(menu: menu))
        }
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { notification in
            guard Self.isPlayerMenu(notification) else { return }
            menusTracking = max(0, menusTracking - 1)
            if menusTracking == 0 {
                PlayerMenuTracking.opened = nil
                menuHold?.cancel()
                menuHold = nil
            }
            guard Self.isPopUpMenu(notification), store.state.value.menu?.isNativeMenu == true else { return }
            store.dispatch(command: PlayerCommandCloseMenu.shared)
        }
        #endif
    }

    #if os(tvOS)
    /// The focus system has an item focused in the key window.
    private static var focusSystemHasFocus: Bool {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first else { return false }
        return UIFocusSystem.focusSystem(for: window)?.focusedItem != nil
    }
    #endif

    #if os(macOS)
    /// A pop-up menu (the controls' menus), not the menu bar's.
    private static func isPopUpMenu(_ notification: Notification) -> Bool {
        guard let menu = notification.object as? NSMenu else { return false }
        return menu !== NSApp.mainMenu && menu.supermenu == nil
    }

    /// A menu of the controls or one of its submenus: one outside the menu bar's tree.
    private static func isPlayerMenu(_ notification: Notification) -> Bool {
        guard var menu = notification.object as? NSMenu else { return false }
        while let parent = menu.supermenu { menu = parent }
        return menu !== NSApp.mainMenu
    }

    /// Keeps the controls up while a menu tracks: the store hears the pointer move every second, which restarts their
    /// hiding, until the last menu closes.
    private func holdForMenus() {
        guard menuHold == nil else { return }
        let store = playback.store
        menuHold = Task {
            while !Task.isCancelled {
                _ = store.onInput(event: InputEventPointerMove.shared)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    #endif

    /// The share of the video surface the bottom controls cover, and the gap that keeps a lifted line clear of the
    /// title over them, for the subtitle lift; none while picture in picture shows the video.
    private var subtitleLift: Double {
        guard surfaceFrame.height > 0, let top = controlsTop, surfaceFrame.maxY > top else { return 0 }
        #if os(iOS) || os(macOS)
        if playback.surface.pictureInPicture.active { return 0 }
        #endif
        return Double((surfaceFrame.maxY - top + PlayerMetrics.subtitleGap) / surfaceFrame.height)
    }

    /// VoiceOver or Switch Control runs; in debug builds also the UI tests' stand-in (`SimulatedAssistiveTechnology`).
    private var assistiveTechnology: Bool {
        #if DEBUG
        if SimulatedAssistiveTechnology.running { return true }
        #endif
        return voiceOver || switchControl
    }

    #if os(tvOS)
    /// A swipe scrubs while the video has the remote (the controls down) or the timeline has focus, and nothing else
    /// holds it (`PlayerUiState.remoteHeld`); never while this device can't seek (`canSeek`: live, a guest of a
    /// host-only room).
    private func swipeScrubs(_ state: PlayerUiState) -> Bool {
        guard state.canSeek, !state.remoteHeld else { return false }
        return !state.controlsVisible || focus == .scrub
    }

    /// A swipe down opens the panel across the bottom from the same places (live: play/pause in the timeline's), as
    /// Down from the timeline does.
    private func swipeOpensPanel(_ state: PlayerUiState) -> Bool {
        guard !state.remoteHeld else { return false }
        return !state.controlsVisible || focus == .scrub || focus == .playPause
    }
    #endif
}

/// The video's own input: a full-screen layer under the controls. It is also the video's accessibility element
/// (`player.video`): the title, with the position as its value (`PositionValue`), which the UI tests read to see playback
/// advance.
private struct PlayerInputLayer: View {
    let state: PlayerUiState
    /// The video's timeline (`PlayerModel.videoTimeline`), for its position value.
    let timeline: StoreObserver<TimelineState>
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding
    #if os(macOS)
    /// The Playback menu's player (`AppCommands`), published while the video has the keyboard.
    let commands: PlaybackCommands
    #endif

    #if os(macOS)
    @FocusState private var focused: Bool
    /// The pointer is on the video, not on the controls over it: the scroll wheel there is the player's
    /// (`PlayerScrollWheel`).
    @State private var pointerOnVideo = false
    /// A press on the video outlasted the long-press time: the video plays at 2× until it lifts (`InputEventHold`).
    @State private var holding = false
    #endif

    var body: some View {
        GeometryReader { proxy in
            #if os(tvOS)
            // With the controls down this is the only focusable view, so the remote's presses land here, unless
            // something over the video holds the remote (`remoteHeld`): the prompt button's Select is its own.
            Button { RemotePress.send(.select, to: store) } label: {
                Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
            }
            .buttonStyle(VideoLayerButtonStyle())
            .disabled(state.controlsVisible || state.remoteHeld)
            .focused(focus, equals: .video)
            .onMoveCommand { direction in
                switch direction {
                case .up: RemotePress.send(.up, to: store)
                case .down: RemotePress.send(.down, to: store)
                case .left: RemotePress.send(.left, to: store)
                case .right: RemotePress.send(.right, to: store)
                @unknown default: break
                }
            }
            .accessibilityLabel(state.title)
            .modifier(PositionValue(timeline: timeline))
            .accessibilityIdentifier("player.video")
            #else
            // A screen reader reaches the video as the button that shows or hides the controls, with the position as its
            // value.
            surface(width: proxy.size.width)
                .accessibilityElement()
                .accessibilityLabel(state.controlsVisible ? T.shared.videoControls.hidePlaybackControls : T.shared.videoControls.showPlaybackControls)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { store.dispatch(command: PlayerCommandToggleControls.shared) }
                .modifier(PositionValue(timeline: timeline))
                .accessibilityIdentifier("player.video")
            #endif
        }
        .ignoresSafeArea()
    }

    #if !os(tvOS)
    /// The video's own input, as wide as [width].
    @ViewBuilder
    private func surface(width: CGFloat) -> some View {
        #if os(macOS)
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                let x = Float(location.x / max(width, 1))
                _ = store.onInput(event: InputEventClick(x: x, clickCount: Int32(NSApp.currentEvent?.clickCount ?? 1)))
            }
            // A press held still: 2× from the long-press time until it lifts, as under a finger; no click.
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10) {
                holding = true
                _ = store.onInput(event: InputEventHold(held: true))
            } onPressingChanged: { pressing in
                guard !pressing, holding else { return }
                holding = false
                _ = store.onInput(event: InputEventHold(held: false))
            }
            // The pointer on the video, not on the controls over it. Its moves reach the store from the window
            // (`PlayerWindowChrome`).
            .onContinuousHover { phase in
                pointerOnVideo = phase != .ended
            }
            .background {
                PlayerScrollWheel(onVideo: pointerOnVideo) { store.onInput(event: InputEventWheel(deltaY: -$0 * 20)) }
            }
            .focusable()
            .focusEffectDisabled()
            .focused($focused)
            // The Playback menu's player while the video has the keyboard, as the keys do.
            .focusedValue(\.playbackCommands, commands)
            .onKeyPress(phases: .all) { press in
                PlayerKeys.handle(press, to: store) ? .handled : .ignored
            }
            .onAppear { focused = true }
            // Keys must keep reaching the store: when the delay popover, which a click moved focus into, closes, and
            // when the controls hide (Up from the timeline, which had the keyboard), the video takes focus back.
            .onChange(of: state.menu) { _, menu in if menu == nil { focused = true } }
            .onChange(of: state.controlsVisible) { _, visible in if !visible { focused = true } }
        #else
        PlayerTouchSurface(store: store)
            // A hardware keyboard's keys, without the software keyboard (`HardwareKeys`). The Playback menu's
            // player is the scene's (`playbackCommands(_:)`).
            .background {
                HardwareKeys(store: store, active: state.takesKeys).frame(width: 0, height: 0)
            }
        #endif
    }
    #endif
}

/// The video's accessibility value: the position (`TimelineState.positionLabel`) as `timeline` mirrors it, read here
/// alone, so the position moving redraws nothing else of the video's layer.
private struct PositionValue: ViewModifier {
    let timeline: StoreObserver<TimelineState>

    func body(content: Content) -> some View {
        content.accessibilityValue(timeline.state.positionLabel)
    }
}
