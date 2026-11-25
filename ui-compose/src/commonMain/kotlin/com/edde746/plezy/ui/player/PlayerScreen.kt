package com.edde746.plezy.ui.player

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import com.edde746.plezy.presentation.player.SkipBadge
import com.edde746.plezy.presentation.player.TransportFlash
import com.edde746.plezy.ui.icons.PlezyIcons
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.exclude
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.changedToDown
import androidx.compose.ui.input.pointer.changedToUp
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.PointerIcon
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.pointerHoverIcon
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.input.pointer.util.addPointerInputChange
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.node.GlobalPositionAwareModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.ContentStripSwipe
import com.edde746.plezy.presentation.player.ControlsScrim
import com.edde746.plezy.presentation.player.LevelIndicator
import com.edde746.plezy.presentation.player.LevelKind
import com.edde746.plezy.presentation.player.InfoSection
import com.edde746.plezy.presentation.player.PictureInPictureHost
import com.edde746.plezy.presentation.player.PlayerCentre
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.ScreenLockState
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.presentation.player.UnlockButton
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.components.LocalBackPress
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.appArea
import com.edde746.plezy.ui.components.beyond
import com.edde746.plezy.ui.focus.focusHome
import com.edde746.plezy.ui.focus.ownsArrows
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.probe.perfMark
import com.edde746.plezy.ui.theme.OnVideoTheme
import com.edde746.plezy.ui.watch.MismatchPrompt
import com.edde746.plezy.ui.watch.PlayBlockedCard
import com.edde746.plezy.ui.watch.ReconnectingPill
import kotlin.math.max
import kotlin.math.roundToInt
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * The player (the shared `PlayerStore` decides, this only renders [state] and forwards input): [video]
 * under a transparent layer of controls. The video reaches the display's edges: the window keeps the app clear of
 * the display cutout and the system bars, shown or hidden ([appArea], Android); the player takes the hidden bars' room
 * back (its place is the safe drawing area, [WindowInsets.safeDrawing]), and the video is laid out beyond the
 * player's place by as much as remains, under them, as video players do; the controls keep to the player's place.
 *
 * Input: keys go to [onInput] before any focused control sees them (with key-up, and auto-repeat marked), so the
 * keymap decides and only what it leaves alone moves focus or presses the focused button; Back goes to the store as
 * [PlayerCommand.Back] once, on its release. In an open menu (its sheet too) Backspace and Home reach the store only
 * where a focused text field (the subtitle search) left them alone: elsewhere in the menu Backspace closes it, not the
 * player. Mouse and pen clicks on the video go with the platform's click count (the store tells a click from a double
 * click), pointer moves say whether they are over the controls, the wheel goes as notches, and the fingers on a touch
 * screen go as they are ([playerTouch]): the store makes taps, skips, holds,
 * pinches and edge swipes of them. The held speed shows with the transient message, a swipe's level on its side.
 * Buttons, menus and the seek bar send [onCommand] directly.
 *
 * Menus open in a [com.edde746.plezy.ui.components.PlezySheet] on phones, tablets and TV (a bottom sheet, a side
 * panel), which holds focus and takes Back itself while it is open; on desktop in a panel above the controls, over the
 * button that opened it, where the pointer already is, with the video and the timeline still in view. The options
 * ([PlayerMenu.OPTIONS]) and their pages open the same way, a page in place of the options.
 *
 * @param timeline the store's timeline ([com.edde746.plezy.presentation.player.PlayerStore.timeline]): the timeline's
 *   row and the live label collect it while they show, and nothing does while the controls are down.
 * @param config the store's config: the seek step the buttons use, the volume range.
 * @param onControlsHeightChanged how much of the video's height the bottom controls cover, from its bottom edge (0
 *   in picture-in-picture): the store keeps subtitles above them while they show. A new one (another store's) is told
 *   at once.
 * @param backEnabled the system back goes to the store; off while the player leaves (a Back then belongs to the
 *   screen beneath).
 * @param pictureInPicture the app shows in a picture-in-picture window: only [video], which stays where it is so its
 *   surface lives on into and out of the window.
 * @param pictureInPictureHost the platform's picture in picture (null: no PiP button).
 * @param onPictureInPictureFailed why the picture-in-picture button's start failed (`PlayerStore.onPictureInPictureFailed`).
 * @param playbackInfo the playback info's sections ([PlayerStore.playbackInfo]'s), shown while
 *   [PlayerUiState.playbackInfo] says; [onPlaybackInfoFrame] hears each frame while the card shows.
 * @param castingFrom "Casting from <device>" while a cast plays here: a line under the title.
 */
@Composable
fun PlayerScreen(
    state: PlayerUiState,
    timeline: StateFlow<TimelineState>,
    config: PlayerConfig,
    onCommand: (PlayerCommand) -> Unit,
    onInput: (InputEvent) -> Boolean,
    onTimelineFocusChanged: (Boolean) -> Unit,
    onControlsHeightChanged: (Double) -> Unit,
    modifier: Modifier = Modifier,
    backEnabled: Boolean = true,
    pictureInPicture: Boolean = false,
    pictureInPictureHost: PictureInPictureHost? = null,
    onPictureInPictureFailed: (String) -> Unit = {},
    playbackInfo: StateFlow<List<InfoSection>>? = null,
    onPlaybackInfoFrame: (Long) -> Unit = {},
    castingFrom: String? = null,
    video: @Composable () -> Unit,
) {
    val formFactor = LocalWindowLayout.current.formFactor
    val inputModes = LocalInputModeManager.current
    val input by rememberUpdatedState(onInput)
    val rootFocus = remember { FocusRequester() }
    val focus = remember { PlayerFocus() }
    val regions = remember { ControlRegions() }
    // The key each physical key's press gave, which its release goes as: a key-up may type nothing (AltGr let go
    // first), so it can't be read again from the event.
    val downKeys = remember { HashMap<Key, InputKey>() }
    val backPress = LocalBackPress.current
    var bounds by remember { mutableStateOf(Rect.Zero) }
    val videoInsets = WindowInsets.safeDrawing

    val current by rememberUpdatedState(state)

    // [bubbling]: the key's way back up from the focused element, which left it alone.
    fun onKey(event: KeyEvent, bubbling: Boolean): Boolean {
        val key = (if (event.type == KeyEventType.KeyUp) downKeys[event.key] else null) ?: event.toInputKey() ?: return false
        // In an open menu Backspace and Home are a focused text field's (the subtitle search's) to edit with: they reach
        // the store only from elsewhere in the menu, where Backspace is Back (it closes the menu, not the player). A
        // release goes on only after its press did: the field takes a press, not its release.
        if ((current.menu != null && (key == InputKey.BACKSPACE || key == InputKey.HOME)) != bubbling) return false
        if (event.type == KeyEventType.KeyUp && downKeys.remove(event.key) == null && bubbling) return false
        if (key == InputKey.BACK) return backPress.handle(event) { onCommand(PlayerCommand.Back) }
        return when (event.type) {
            KeyEventType.KeyDown ->
                input(InputEvent.KeyDown(key, event.inputModifiers, repeat = downKeys.put(event.key, key) != null, source = event.inputSource()))
            KeyEventType.KeyUp -> input(InputEvent.KeyUp(key))
            else -> false
        }
    }

    // Keys held as focus leaves the player are released here: their key-up goes where focus is then (a sheet), or
    // nowhere while nothing has it (a menu's page replaced under focus), and a key still noted as held reads its next
    // press as a repeat, which the store drops.
    fun releaseKeys() {
        for (key in downKeys.values) input(InputEvent.KeyUp(key))
        downKeys.clear()
    }

    // Where focus belongs in the player as it is now ([focusHome]'s home, and the effect below once a change has
    // settled): an error's primary action, a watch-together room's Play (with keys), on TV the sleep timer's Continue,
    // the prompt button while the controls are down and play/pause (the options for a guest whose playback controls
    // are off) while they are up; the player itself otherwise (also while the playback opens: no controls to focus
    // yet), so keys reach the store. A TV or handheld menu's sheet holds focus itself.
    fun home(): Boolean {
        val now = current
        val tv = formFactor == FormFactor.TV
        return when {
            now.error != null -> focus.error.requestFocus() || rootFocus.requestFocus()
            now.menu != null && formFactor != FormFactor.DESKTOP -> false
            now.watch?.playBlocked != null && inputModes.inputMode == InputMode.Keyboard -> focus.watchPrompt.requestFocus() || rootFocus.requestFocus()
            tv && now.stillWatching != null -> focus.stillWatching.requestFocus()
            tv && now.prompt != null && !now.controlsVisible -> focus.prompt.requestFocus() || rootFocus.requestFocus()
            tv && now.controlsVisible ->
                focus.playPause.requestFocus() || focus.menuButtons.focus(PlayerMenu.OPTIONS).requestFocus() || rootFocus.requestFocus()
            else -> rootFocus.requestFocus()
        }
    }

    Box(
        modifier
            .fillMaxSize()
            // Over the hidden system bars, which the app's own place keeps clear of so it stays put as they come and go.
            .beyond(WindowInsets.appArea.exclude(videoInsets))
            // The perf runs' mark: the player's first draw.
            .perfMark("player.shown", "", ready = true)
            .onGloballyPositioned {
                bounds = it.boundsInRoot()
                regions.origin = bounds.topLeft
            }
            // Hover, observed before any control handles it: over the controls they stay up. A mouse resting on the
            // player gets a move of Compose's own when what lies under it changes (a control appearing there): only a
            // move to somewhere else than where the mouse was is the viewer's (any input stops an automatic skip's
            // countdown). A hover's previousPosition is no help: Compose keeps none for a pointer that isn't down.
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    var at = Offset.Unspecified
                    val pressed = HashSet<Long>()
                    while (true) {
                        val event = awaitPointerEvent(PointerEventPass.Initial)
                        val change = event.changes.firstOrNull() ?: continue
                        // A press on the controls keeps them up until it lifts, a slider's drag out of the player too.
                        for (pointer in event.changes) {
                            if (pointer.changedToDown() && regions.contains(pointer.position) && pressed.add(pointer.id.value)) {
                                input(InputEvent.PointerDown(pointer.id.value))
                            }
                            if (pointer.changedToUp() && pressed.remove(pointer.id.value)) input(InputEvent.PointerUp(pointer.id.value))
                        }
                        if (change.type != PointerType.Mouse) continue
                        when (event.type) {
                            PointerEventType.Move, PointerEventType.Enter -> if (change.position != at) {
                                at = change.position
                                input(InputEvent.PointerMove)
                            }
                            PointerEventType.Exit -> {
                                at = Offset.Unspecified
                                input(InputEvent.PointerExit)
                            }
                        }
                    }
                }
            }
            .pointerHoverIcon(if (state.controlsVisible || formFactor != FormFactor.DESKTOP) PointerIcon.Default else HiddenPointerIcon)
            .onPreviewKeyEvent { onKey(it, bubbling = false) }
            .onKeyEvent { onKey(it, bubbling = true) }
            .onFocusChanged {
                focus.inPlayer = it.hasFocus
                val onControl = it.hasFocus && !it.isFocused
                if (onControl != focus.onControl) input(InputEvent.ControlFocus(onControl))
                focus.onControl = onControl
                if (!it.hasFocus) releaseKeys()
            }
            .focusHome(::home)
            // The video takes every arrow (seeks, raises the controls): they don't show focus.
            .ownsArrows { true }
            .focusRequester(rootFocus)
            .focusable(),
    ) {
        // Harness name `player.video`: the player is open, its controls up or not.
        Box(Modifier.fillMaxSize().beyond(videoInsets).layoutProbe("player.video", reportsFocus = false)) { video() }
        // Until the playing item's first frame the picture stays black: the last item's frame never shows under the new
        // item's title, nor the new item's first frames under "Opening…".
        if (!state.hasFirstFrame) {
            Box(Modifier.fillMaxSize().beyond(videoInsets).background(Color.Black).layoutProbe("player.videoCover", reportsFocus = false))
        }
        // The top bar's buttons a narrow bar moved, which the options sheet offers in their place.
        val movedBarButtons = remember { MovedBarButtons() }
        // In picture-in-picture: the video alone (the window's own actions play, pause and seek).
        if (!pictureInPicture) {
            // Everything over the video draws in its white (OnVideoTheme), the controls named or not.
            OnVideoTheme {
                CompositionLocalProvider(
                    LocalPictureInPictureHost provides pictureInPictureHost,
                    LocalPictureInPictureFailed provides onPictureInPictureFailed,
                    LocalMovedBarButtons provides movedBarButtons,
                ) {
                    PlayerOverlays(
                        state, timeline, config, focus, regions, bounds, videoInsets, onCommand, onInput, onTimelineFocusChanged, onControlsHeightChanged,
                        playbackInfo, onPlaybackInfoFrame, castingFrom, onSheetKey = { onKey(it, bubbling = true) },
                    )
                }
            }
        }
    }

    // A key brought the controls up for the keyboard or the remote to move through: Play/Pause takes focus.
    LaunchedEffect(state.playPauseFocus) {
        if (state.playPauseFocus == 0 || !state.controlsVisible || state.menu != null) return@LaunchedEffect
        // The controls are laid out by the next frame.
        withFrameNanos { }
        focus.playPause.requestFocus()
    }

    // No controls in picture-in-picture: nothing for subtitles to clear.
    LaunchedEffect(pictureInPicture, onControlsHeightChanged) { if (pictureInPicture) onControlsHeightChanged(0.0) }
    // One effect places focus, from the player's first frame on; a second request elsewhere (one of a panel's own)
    // would race it. Keys must keep reaching the store: when the controls (or a panel) that had focus go away, the
    // player takes it back. An error's primary action takes focus, also when the error comes with the first frame (a
    // stream that fails at once); where it can't (Android's touch mode) the player keeps it. A watch-together room's
    // Play (the player refused to start in a playing room) takes it the same way with keys. On TV the sleep timer's
    // Continue takes focus while its card shows; the prompt button (skip, up next) takes it as it comes up by itself,
    // over the controls too unless
    // the viewer is scrubbing, and while the controls are down (Select presses it then); otherwise the controls take
    // focus when they appear, starting at play/pause (the options for a guest whose playback controls are off), also
    // when the first frame brings them (the player held focus while the playback opened), when Down brings them up from
    // the prompt button and when the button, past its own seconds, comes back with them ([PlayerPrompt.withControls]);
    // once a menu sheet has slid away and given focus back to the player, the menu's
    // button takes it (play/pause when the button is gone). The prompt button gone with focus on it sends focus to
    // play/pause; a control the viewer moved to from it keeps it. Focus that drops otherwise (the focused control
    // disabled or gone: Previous at the first episode) goes where [home] puts it ([focusHome]).
    var openMenu by remember { mutableStateOf<PlayerMenu?>(null) }
    var promptWasShown by remember { mutableStateOf(false) }
    val stillWatchingShown = state.stillWatching != null
    val promptShown = state.prompt != null
    val canPlayPause = state.canPlayPause
    val playBlockedShown = state.watch?.playBlocked != null
    LaunchedEffect(state.controlsVisible, state.menu, state.error?.primary?.action, stillWatchingShown, promptShown, canPlayPause, playBlockedShown, state.hasFirstFrame) {
        val closed = openMenu.takeIf { state.menu == null }
        openMenu = state.menu
        val promptAppeared = promptShown && !promptWasShown && state.prompt?.withControls == false
        val promptGone = promptWasShown && !promptShown
        promptWasShown = promptShown
        when {
            state.error != null -> home()
            state.menu != null -> Unit
            playBlockedShown && inputModes.inputMode == InputMode.Keyboard -> {
                // The card is laid out by the next frame.
                withFrameNanos { }
                home()
            }
            stillWatchingShown && formFactor == FormFactor.TV -> {
                // The card is laid out by the next frame.
                withFrameNanos { }
                home()
            }
            promptShown && formFactor == FormFactor.TV && (promptAppeared || !state.controlsVisible) -> {
                // Over the controls in the middle of a scrub, focus stays where the viewer scrubs.
                if (state.controlsVisible && state.scrubbing) return@LaunchedEffect
                // The button is laid out by the next frame.
                withFrameNanos { }
                if (!focus.prompt.requestFocus()) rootFocus.requestFocus()
            }
            state.controlsVisible && formFactor == FormFactor.TV -> {
                if (promptGone) {
                    // The focus the button had is gone by the next frame.
                    withFrameNanos { }
                    if (focus.onControl) return@LaunchedEffect
                }
                if (closed != null) {
                    var frames = 0
                    while (!focus.inPlayer && frames++ < SHEET_EXIT_FRAMES) withFrameNanos { }
                    if (focus.menuButtons.focus(closed).requestFocus()) return@LaunchedEffect
                }
                home()
            }
            // The phone and tablet sheets give focus back themselves (to the player, in touch mode).
            closed != null && formFactor == FormFactor.HANDHELD -> Unit
            else -> rootFocus.requestFocus()
        }
    }
    // The system back: Android's back gesture, and a remote's Back from Android 13 (predictive back) before its key-up,
    // reach the app as a navigation event. It backs out of the innermost layer; with none left the store closes the
    // player.
    SystemBackHandler(enabled = backEnabled) { onCommand(PlayerCommand.Back) }
}

/** How long a closing menu sheet may take to slide away and give focus back: about half a second. */
private const val SHEET_EXIT_FRAMES = 30

/**
 * The scrim behind the controls, over the whole video, by whether the picture is HDR ([ControlsScrim]): eased from black
 * at the top and bottom edges to clear, the top edge reaching far enough under the title and the episode line (whose
 * far side is [titleBottom] pixels down the video, 0 before the top bar lays out) that they read over a white frame.
 */
private fun Modifier.scrim(hdr: Boolean, titleBottom: Float): Modifier = drawWithCache {
    val top = ControlsScrim.reach(titleBottom, size.height)
    val brush = Brush.verticalGradient(*ControlsScrim.stops(hdr, top = top).map { it.position to Color.Black.copy(alpha = it.alpha) }.toTypedArray())
    onDrawBehind { drawRect(brush) }
}

/**
 * The player's layers above the video: the click and wheel surface, the controls, and every panel. [bounds] is the
 * player in root coordinates, and the video reaches beyond it by [videoInsets]; the share of the video's height the
 * controls cover goes to [onControlsHeightChanged]. Keys a menu's sheet left alone go to [onSheetKey].
 *
 * Nothing over the video meets the controls, and nothing keeps further from the edges than that needs:
 * - The messages at the top (the held speed and the transient message, [TopMessages]) sit side by side in the top
 *   bar's row, centred and level with close, the same with the controls up or down, where the room between close and
 *   the title's text and the room pill holds them; else (a phone upright, a long title) under the top bar. A seek's
 *   seconds show on the side it went, and a play or pause with the controls down in the middle, as the same messages.
 * - With the controls up, the bottom-trailing corner (the sleep timer's card above the prompt button) sits directly
 *   above the bottom bar's top row (the timeline row; live, the buttons), its trailing edge on the row's. With the
 *   controls down, at their own bottom margin.
 * - The playback info sits in a top trailing corner clear of every control ([PlaybackInfoCard], [infoRooms]): with the
 *   controls up under the top bar's buttons and title (not its margin), above the bottom bar's top row (clear of the
 *   chapters and queue hint over it) and the corner, and beside or above a phone's transport; with them down at the
 *   player's margins above the corner. With a desktop menu open it goes beside or above the menu, or where neither
 *   has room, away. It takes no touch and no focus.
 * - Over an error, the error's black ([ErrorPanel]) covers everything but the top bar, which goes above it.
 */
@Composable
private fun BoxScope.PlayerOverlays(
    state: PlayerUiState,
    timeline: StateFlow<TimelineState>,
    config: PlayerConfig,
    focus: PlayerFocus,
    regions: ControlRegions,
    bounds: Rect,
    videoInsets: WindowInsets,
    onCommand: (PlayerCommand) -> Unit,
    onInput: (InputEvent) -> Boolean,
    onTimelineFocusChanged: (Boolean) -> Unit,
    onControlsHeightChanged: (Double) -> Unit,
    playbackInfo: StateFlow<List<InfoSection>>?,
    onPlaybackInfoFrame: (Long) -> Unit,
    castingFrom: String?,
    onSheetKey: (KeyEvent) -> Boolean,
) {
    val input by rememberUpdatedState(onInput)
    val metrics = rememberPlayerMetrics()
    val density = LocalDensity.current
    // How far up from the player's bottom edge the controls reach (to the bottom bar's top), in pixels, once they have
    // been laid out; their top in root coordinates from that (a desktop menu stays above it).
    var controlsReach by remember { mutableIntStateOf(-1) }
    val controlsHeight = if (controlsReach < 0 || bounds.height <= 0f) 0f else controlsReach.toFloat().coerceAtMost(bounds.height)
    val controlsTop = if (controlsReach < 0) Float.NaN else bounds.bottom - controlsHeight
    // The bars' parts that the messages at the top and the corner go beside, as the bars last laid out (the top bar's
    // with the controls up only).
    var topReach by remember { mutableStateOf<TopBarReach?>(null) }
    var bottomReach by remember { mutableStateOf<BottomBarReach?>(null) }
    // Subtitles are placed on the video's plane, which reaches below the player by the inset there (none while the
    // system bars are hidden, but for a cutout on that edge).
    val videoTop = videoInsets.getTop(density)
    val videoBottom = videoInsets.getBottom(density)
    val formFactor = LocalWindowLayout.current.formFactor
    val desktop = formFactor == FormFactor.DESKTOP
    val handheld = formFactor == FormFactor.HANDHELD
    val panelMenu = state.menu
    val window by LocalWindowSize.current
    // A menu docked along the right edge at full height (the long lists on the desktop; every menu but the room's on a
    // phone or tablet on its side) would cut the centre transport and the timeline in two: they step aside while it's
    // open, the top bar's Back and title staying, and come back as it closes.
    val docked = panelMenu != null &&
        (desktop && panelMenu.docksOnDesktop || handheld && window.width > window.height && panelMenu.docksInLandscape)
    // With the bottom bar stepped aside the subtitles drop to the video's bottom, rising again by its last height as it
    // comes back. Again for a new callback (another store) with the same height.
    val liftHeight = if (docked) 0f else controlsHeight
    LaunchedEffect(liftHeight, bounds.height, videoTop, videoBottom, onControlsHeightChanged) {
        val videoHeight = bounds.height + videoTop + videoBottom
        if (bounds.height > 0f) onControlsHeightChanged((if (liftHeight > 0f) (liftHeight + videoBottom) / videoHeight else 0f).toDouble())
    }
    // Panels above the controls; before the controls' first layout, about where they will be.
    val aboveControls = if (controlsHeight > 0f) with(density) { controlsHeight.toDp() } + 12.dp else 128.dp
    val belowTopBar = metrics.vertical + metrics.button + 12.dp
    // The bottom-trailing corner's card and prompt button (laid out below), while either shows: their height in pixels.
    val cornerShown = state.stillWatching != null || state.prompt != null
    var cornerHeight by remember { mutableIntStateOf(0) }
    // What the playback info keeps clear of, as last laid out: from the player's top left the centre transport and an
    // open desktop menu, in pixels (the top bar's reach is [topReach]).
    var transport by remember { mutableStateOf<Rect?>(null) }
    var menuBounds by remember { mutableStateOf<Rect?>(null) }

    // While a desktop menu's panel is open a screen reader reaches it alone, as it does a sheet (the overlay host hides
    // what lies under one): the video and the controls are hidden from it, not from the pointer.
    val desktopMenuOpen = desktop && panelMenu != null
    val underMenu = if (desktopMenuOpen) Modifier.clearAndSetSemantics { } else Modifier
    // The video itself: touches, clicks and the wheel. Controls above it take their own pointer input. A screen reader
    // reaches it as the button that shows or hides the controls.
    Box(
        Modifier
            .fillMaxSize()
            .then(
                if (desktopMenuOpen) {
                    Modifier
                } else {
                    Modifier.semantics {
                        role = Role.Button
                        contentDescription = if (state.controlsVisible) T.videoControls.hidePlaybackControls else T.videoControls.showPlaybackControls
                        onClick {
                            onCommand(PlayerCommand.ToggleControls)
                            true
                        }
                    }
                },
            )
            .playerTouch({ input(it) })
            .videoClicks { input(it) }
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent()
                        if (event.type != PointerEventType.Scroll) continue
                        val change = event.changes.firstOrNull() ?: continue
                        // Compose reports a notch as 1, wheel-down positive; the store takes pixels, as a notch scrolls 20.
                        val deltaY = change.scrollDelta.y.toDouble() * WHEEL_NOTCH_PIXELS
                        if (deltaY != 0.0 && input(InputEvent.Wheel(deltaY))) change.consume()
                    }
                }
            },
    )

    // Over the error, above its black: Back and the title stay over it, with no scrim to dim its column.
    val overError = state.error != null
    AnimatedVisibility(state.controlsVisible, Modifier.zIndex(if (overError) 1f else 0f), enter = fadeIn(tween(200)), exit = fadeOut(tween(200))) {
        Box(Modifier.fillMaxSize().then(underMenu)) {
            if (!overError) {
                val titleBottom = topReach?.let { it.bottom + videoTop.toFloat() } ?: 0f
                Box(Modifier.fillMaxSize().beyond(videoInsets).scrim(state.hdrPicture, titleBottom))
            }
            PlayerTopBar(
                state = state,
                buttons = focus.menuButtons,
                onCommand = onCommand,
                onReach = { topReach = it },
                liveBadge = state.mode == PlaybackMode.LIVE,
                menus = handheld,
                castingFrom = castingFrom,
                modifier = Modifier.align(Alignment.TopCenter).controlRegion(regions, "top"),
            )
            // Over the error, the top bar's title and Back alone: nothing behind its black to reach. Nothing else before
            // the first frame. A scrub's preview rises over it, so it fades out while the viewer scrubs and back after.
            if (handheld && state.showsPlaybackControls && state.hasFirstFrame && !docked) {
                AnimatedVisibility(!state.scrubbing, Modifier.align(Alignment.Center), enter = fadeIn(tween(200)), exit = fadeOut(tween(200))) {
                    CentreTransport(
                        state,
                        focus,
                        onCommand,
                        Modifier.controlRegion(regions, "centre").onGloballyPositioned {
                            transport = it.boundsInRoot().translate(-bounds.topLeft)
                        },
                    )
                }
            }
            if (state.showsPlaybackControls && state.hasFirstFrame && !docked) {
                // A phone's swipe up on the bar opens the chapters and the queue ([ContentStripSwipe]).
                val swipe = if (handheld && state.hasStripContent) Modifier.stripSwipe(onCommand) else Modifier
                PlayerBottomBar(
                    state = state,
                    timeline = timeline,
                    config = config,
                    focus = focus,
                    onCommand = onCommand,
                    onTimelineFocusChanged = onTimelineFocusChanged,
                    onControlsHeight = { controlsReach = it },
                    onReach = { bottomReach = it },
                    // The wheel over the bottom controls (the volume's slider among them) goes to the player as over the
                    // video: once, wherever it turns.
                    modifier = Modifier.align(Alignment.BottomCenter).then(swipe).wheelToPlayer { input(it) }.controlRegion(regions, "bottom"),
                )
            }
        }
    }

    when (val centre = state.centre) {
        is PlayerCentre.Loading -> LoadingOverlay(centre.text, state.hdrPicture, Modifier.align(Alignment.Center))
        // The error goes last, over the menus too.
        is PlayerCentre.Error, null -> Unit
    }

    if (state.osd != null || state.heldSpeed != null) {
        TopMessages({ topReach }, below = belowTopBar + 12.dp) {
            state.heldSpeed?.let { HeldSpeedMessage(it, state.hdrPicture) }
            state.osd?.let { OsdMessage(it, state.osdIcon?.vector, state.hdrPicture) }
        }
    }
    SeekMessage(state.skipBadge, state.hdrPicture, metrics.edge)
    PlayPauseMessage(state.transportFlash, state.hdrPicture, Modifier.align(Alignment.Center))

    // A swipe's level on the side it is swiped on, vertically centred, 20 dp in from the player's edge (the player
    // already keeps clear of a display cutout).
    val lastLevel = remember { arrayOfNulls<LevelIndicator>(1) }
    state.level?.let { lastLevel[0] = it }
    lastLevel[0]?.let { level ->
        val left = level.kind == LevelKind.BRIGHTNESS
        AnimatedVisibility(
            state.level != null,
            Modifier.align(if (left) Alignment.CenterStart else Alignment.CenterEnd).padding(horizontal = 20.dp),
            enter = fadeIn(tween(160)),
            exit = fadeOut(tween(160)),
        ) {
            LevelBar(level, state.hdrPicture)
        }
    }

    // The playback info's readings come while it shows.
    val info = state.playbackInfo
    if (info?.visible == true && playbackInfo != null) {
        val frame by rememberUpdatedState(onPlaybackInfoFrame)
        LaunchedEffect(Unit) { while (true) withFrameNanos { frame(it) } }
    }
    if (info != null && playbackInfo != null) {
        val sections by playbackInfo.collectAsState()
        val up = state.controlsVisible
        fun Rect.toDp() = with(density) { DpRect(left.toDp(), top.toDp(), right.toDp(), bottom.toDp()) }
        val picture = with(density) { DpSize(bounds.width.toDp(), bounds.height.toDp()) }
        val corner = if (cornerShown) with(density) { cornerHeight.toDp() } + 12.dp else 0.dp
        // With the controls up, above the bottom bar's top row as the corner is (the bar's hint over the row is kept
        // clear of where it is), else above the controls as first laid out.
        val bar = bottomReach.takeIf { controlsHeight > 0f }
        val aboveBar = bar?.let { with(density) { it.topRow.toDp() } + 12.dp } ?: aboveControls
        val rooms = infoRooms(
            width = picture.width,
            top = if (up) topReach?.let { with(density) { it.bottom.toDp() } + 12.dp } ?: belowTopBar else metrics.vertical,
            bottom = picture.height - (if (up) aboveBar else metrics.vertical) - corner,
            side = metrics.edge,
            transport = transport.takeIf { up && handheld && state.showsPlaybackControls && state.hasFirstFrame }?.toDp(),
            hint = bar?.hint?.takeIf { up }?.translate(0f, bounds.height)?.toDp(),
            menu = menuBounds.takeIf { desktop && panelMenu?.docksOnDesktop == false }?.toDp(),
            ltr = LocalLayoutDirection.current == LayoutDirection.Ltr,
        )
        PlaybackInfoCard(sections, rooms, picture, info.visible)
    }

    // With the controls up, directly above the bottom bar's top row, its trailing edge on the row's. With the controls
    // down, in the bottom-trailing corner at their own margins. The card and the prompt button move as the controls
    // fade: the sleep timer's question over the button, should both come at once.
    if (cornerShown) {
        val up by animateFloatAsState(if (state.controlsVisible) 1f else 0f, tween(200), label = "corner")
        Column(
            Modifier.align(Alignment.BottomEnd)
                .padding(horizontal = metrics.edge)
                .layout { measurable, constraints ->
                    val corner = measurable.measure(constraints)
                    val gap = 12.dp.roundToPx()
                    val bar = bottomReach
                    val above = if (controlsHeight <= 0f || bar == null) aboveControls.roundToPx() else bar.topRow + gap
                    val hidden = metrics.vertical.roundToPx()
                    val bottom = hidden + ((above - hidden) * up).roundToInt()
                    layout(corner.width, corner.height) { corner.place(0, -bottom) }
                }
                .onSizeChanged { cornerHeight = it.height }
                .then(underMenu),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalAlignment = Alignment.End,
        ) {
            state.stillWatching?.let { StillWatchingCard(it, focus, onCommand, Modifier.controlRegion(regions, "stillWatching")) }
            state.prompt?.let { PromptButton(it, focus, onCommand, Modifier.controlRegion(regions, "prompt")) }
        }
    }

    // Watch Together: the reconnecting pill over the video, the Play of a player that refused to start in a playing
    // room, and the question when the room offers a copy of another length.
    state.watch?.let { watch ->
        watch.reconnecting?.let { ReconnectingPill(it, Modifier.align(Alignment.BottomCenter).padding(bottom = 120.dp)) }
        watch.playBlocked?.let { blocked ->
            PlayBlockedCard(
                blocked,
                focus.watchPrompt,
                onCommand,
                Modifier.align(Alignment.BottomEnd).padding(end = 24.dp, bottom = 100.dp).controlRegion(regions, "watchBlocked"),
            )
        }
        MismatchPrompt(watch, menuOpen = state.menu != null, onCommand)
    }

    // The last menu stays in its sheet while the sheet slides away. Composed before a desktop menu's panel: a docked
    // page that goes back to the menu it opened from at its button gives focus back as it closes (to the entry that
    // opened it, now gone), and the panel's entry takes it after that.
    val sheetMenu = panelMenu?.takeIf { !desktop || it.docksOnDesktop }
    val lastMenu = remember { arrayOfNulls<PlayerMenu>(1) }
    sheetMenu?.let { lastMenu[0] = it }
    (sheetMenu ?: lastMenu[0])?.let { menu -> PlayerMenuSheet(menu, visible = sheetMenu != null, state, onCommand, onSheetKey) }

    // On the desktop the short menus open at their buttons; the chapters, the queue and the pages that need the room
    // (the shaders with their descriptions, the file info, the subtitle search) dock along the right edge at full
    // height with a close button, as every menu's sheet does elsewhere.
    if (desktop) {
        // The menus shown, docked ones too: back from a docked page on the menu it opened from, focus returns to the
        // entry that opened it.
        val pages = remember { PageMemory() }
        if (panelMenu != null) pages.show(panelMenu, state) else pages.forget()
        panelMenu?.takeIf { !it.docksOnDesktop }?.let { menu ->
            // The session sheet opens over the room pill, or over the settings it was opened from outside a room.
            val anchor = focus.menuButtons.rect(menu) ?: focus.menuButtons.rect(PlayerMenu.OPTIONS)
            // Above the corner's cards or skip button too, as the info panel is: they stay usable. Decided as the menu
            // opens, from those showing then: one that comes, goes or changes size while it's open (the skip button
            // leaving as the intro ends) doesn't move its rows from under the pointer. The menu covers one that comes.
            val corner = remember(menu) { if (cornerShown) cornerHeight + with(density) { 12.dp.toPx() } else 0f }
            AnchoredMenu(anchor = anchor, player = bounds, limit = controlsTop - corner, edge = metrics.edge) {
                PlayerMenuPanel(
                    menu,
                    state,
                    pages,
                    onCommand,
                    Modifier.controlRegion(regions, "menu").onGloballyPositioned { menuBounds = it.boundsInRoot().translate(-bounds.topLeft) },
                )
            }
        }
    }

    state.error?.let { error ->
        ErrorPanel(error, focus, onCommand, topBar = belowTopBar, videoInsets = videoInsets, modifier = Modifier.controlRegion(regions, "error"))
    }

    // Over everything else: no touch reaches what lies under a locked screen.
    state.screenLock?.let { lock -> ScreenLockShield(lock, state.hdrPicture, onCommand, input) }
}

/**
 * A seek's seconds ([PlayerUiState.skipBadge], summed while the seeks go one way) as a transient message on the side it
 * went, with the rewind or fast-forward icon, vertically centred and [edge] in from the player's side. It fades in and
 * out with the store's badge. Back and forward are left and right in every language. Harness name `player.skipBadge`.
 */
@Composable
private fun BoxScope.SeekMessage(badge: SkipBadge?, hdr: Boolean, edge: Dp) {
    val last = remember { arrayOfNulls<SkipBadge>(1) }
    badge?.let { last[0] = it }
    val shown = last[0] ?: return
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        AnimatedVisibility(
            badge != null,
            Modifier.align(if (shown.forward) Alignment.CenterEnd else Alignment.CenterStart).padding(horizontal = edge),
            enter = fadeIn(tween(150)),
            exit = fadeOut(tween(300)),
        ) {
            OsdMessage(shown.label, if (shown.forward) PlezyIcons.FastForward else PlezyIcons.FastRewind, hdr, probe = "player.skipBadge")
        }
    }
}

/**
 * A play or pause that landed with the controls down ([PlayerUiState.transportFlash]): "Playing" or "Paused" with its
 * icon as a transient message in the middle, while the store shows it. Harness name `player.transportFlash`.
 */
@Composable
private fun PlayPauseMessage(flash: TransportFlash?, hdr: Boolean, modifier: Modifier) {
    val last = remember { arrayOfNulls<TransportFlash>(1) }
    flash?.let { last[0] = it }
    val shown = last[0] ?: return
    AnimatedVisibility(flash != null, modifier, enter = fadeIn(tween(150)), exit = fadeOut(tween(150))) {
        OsdMessage(
            if (shown.paused) T.videoControls.playbackPaused else T.videoControls.playbackResumed,
            if (shown.paused) PlezyIcons.Pause else PlezyIcons.PlayArrow,
            hdr,
            probe = "player.transportFlash",
        )
    }
}

/**
 * The locked screen ([ScreenLockState]): a shield over the whole player that takes every touch and gives it to the
 * store as it is ([playerTouch]), which makes a tap show or hide the unlock button and a second finger hide it. The
 * unlock button sits at the top centre, inside the safe area: a finger, or a mouse's or pen's press, that goes down on
 * it is [PlayerCommand.UnlockHold] until it lifts, which unlocks once held long enough. TalkBack reaches the button as a
 * button, which unlocks at once ([PlayerCommand.UnlockPress]). Harness names: `player.lockShield`, `player.unlock`.
 */
@Composable
private fun BoxScope.ScreenLockShield(lock: ScreenLockState, hdr: Boolean, onCommand: (PlayerCommand) -> Unit, onInput: (InputEvent) -> Boolean) {
    // The shield's and the button's bounds in the root, as last laid out.
    var shield by remember { mutableStateOf(Rect.Zero) }
    var button by remember { mutableStateOf(Rect.Zero) }
    val shown by rememberUpdatedState(lock.unlock != null)
    val command by rememberUpdatedState(onCommand)
    val input by rememberUpdatedState(onInput)
    Box(
        Modifier
            .fillMaxSize()
            .layoutProbe("player.lockShield")
            .onGloballyPositioned { shield = it.boundsInRoot() }
            // Before the button's own handling: its touches reach the store with the rest.
            .playerTouch(
                { input(it) },
                PointerEventPass.Initial,
                holdArea = { if (shown) button.translate(-shield.topLeft) else null },
                onHold = { command(PlayerCommand.UnlockHold(it)) },
            ),
    ) {
        val lastUnlock = remember { arrayOfNulls<UnlockButton>(1) }
        lock.unlock?.let { lastUnlock[0] = it }
        lastUnlock[0]?.let { unlock ->
            AnimatedVisibility(
                lock.unlock != null,
                Modifier.align(Alignment.TopCenter).padding(top = 16.dp),
                enter = fadeIn(tween(200)),
                exit = fadeOut(tween(200)),
            ) {
                UnlockButtonPill(unlock, hdr, onUnlock = { command(PlayerCommand.UnlockPress) }, Modifier.onGloballyPositioned { button = it.boundsInRoot() })
            }
        }
    }
}

/**
 * The messages at the top (the held speed, the transient message): side by side in the top bar's row, centred on
 * the player and level with close, 12 dp clear of close, the title's text and the room pill, where the room
 * between those holds them; else (a phone upright, a long title, before the bar's first layout) [below] the player's
 * top, under the bar, one above the other. [row] is the bar as it last laid out with the controls up: the messages stay
 * put as the controls come and go.
 */
@Composable
private fun TopMessages(row: () -> TopBarReach?, below: Dp, content: @Composable () -> Unit) {
    Layout(content, Modifier.fillMaxSize()) { measurables, constraints ->
        // A message is at most 80 % of the player's width.
        val messages = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0, maxWidth = (constraints.maxWidth * 0.8f).roundToInt())) }
        val spacing = 8.dp.roundToPx()
        val gap = 12.dp.roundToPx()
        val width = constraints.maxWidth
        val inRow = messages.sumOf { it.width } + spacing * (messages.size - 1)
        // Centred on the player: both sides kept as far in as the further one reaches, and a gap.
        val bar = row()?.takeIf { inRow <= width - 2 * (max(it.leading, it.trailing) + gap) }
        layout(width, constraints.maxHeight) {
            if (bar != null) {
                var x = (width - inRow) / 2
                for (message in messages) {
                    message.placeRelative(x, bar.middle - message.height / 2)
                    x += message.width + spacing
                }
            } else {
                var y = below.roundToPx()
                for (message in messages) {
                    message.placeRelative((width - message.width) / 2, y)
                    y += message.height + spacing
                }
            }
        }
    }
}

/**
 * Places [content] above [limit] (root coordinates: the controls' top, or the corner's cards' over them), centred on
 * [anchor] (the menu's button) and kept inside the [player], [edge] from its sides as the controls are: a desktop menu
 * opens where the pointer is and leaves the timeline uncovered. Without an anchor, at the end.
 */
@Composable
private fun AnchoredMenu(anchor: Rect?, player: Rect, limit: Float, edge: Dp, content: @Composable () -> Unit) {
    val density = LocalDensity.current
    val margin = with(density) { 12.dp.roundToPx() }
    val side = with(density) { edge.roundToPx() }
    Layout(content, Modifier.fillMaxSize()) { measurables, constraints ->
        val bottom = when {
            !limit.isNaN() -> limit - player.top
            anchor != null -> anchor.top - player.top
            else -> constraints.maxHeight * 0.8f
        }.roundToInt() - margin
        val panel = measurables.first().measure(
            Constraints(maxWidth = (constraints.maxWidth - 2 * side).coerceAtLeast(0), maxHeight = (bottom - margin).coerceAtLeast(0)),
        )
        layout(constraints.maxWidth, constraints.maxHeight) {
            val center = (anchor?.center?.x?.minus(player.left))?.roundToInt() ?: (constraints.maxWidth - side - panel.width / 2)
            val x = (center - panel.width / 2).coerceIn(side, (constraints.maxWidth - side - panel.width).coerceAtLeast(side))
            panel.place(x, (bottom - panel.height).coerceAtLeast(margin))
        }
    }
}

/**
 * Focus targets the player moves focus to (TV, an error's action, and after a menu closes), the menu buttons, and
 * whether the player (its controls, or the player itself) holds focus: a menu sheet holds it elsewhere until it has
 * gone. [onControl]: one of the player's controls holds it, not the player itself.
 */
internal class PlayerFocus {
    val playPause = FocusRequester()
    val stillWatching = FocusRequester()
    val prompt = FocusRequester()
    val error = FocusRequester()
    /** A room's Play, while the player refused to start in a playing room ([com.edde746.plezy.presentation.watch.PlayerWatchUi.playBlocked]). */
    val watchPrompt = FocusRequester()
    val menuButtons = MenuButtons()
    var inPlayer = false
    var onControl = false
}

/**
 * The playback info's rooms ([PlaybackInfoCard]) in a player [width] wide, from its top left: between [top] and
 * [bottom] (what the controls and the corner leave), [side] in from its sides. A phone's centre [transport] splits it
 * into the room beside it (trailing) and the room above it; a room across the bottom bar's [hint] ends above the hint.
 * An open desktop [menu] leaves of a room it covers the part beside it (leading) and the part above it: the card never
 * goes over the menu.
 */
private fun infoRooms(width: Dp, top: Dp, bottom: Dp, side: Dp, transport: DpRect?, hint: DpRect?, menu: DpRect?, ltr: Boolean): List<DpRect> {
    val gap = 12.dp
    val all = DpRect(side, top, width - side, bottom)
    val split = if (transport == null) {
        listOf(all)
    } else {
        listOf(
            if (ltr) all.copy(left = transport.right + gap) else all.copy(right = transport.left - gap),
            all.copy(bottom = transport.top - gap),
        )
    }
    val rooms = split.map { room ->
        if (hint != null && room.left < hint.right && hint.left < room.right) room.copy(bottom = minOf(room.bottom, hint.top - gap)) else room
    }
    if (menu == null) return rooms
    return rooms.flatMap { room ->
        if (room.left >= menu.right || menu.left >= room.right || room.top >= menu.bottom || menu.top >= room.bottom) {
            listOf(room)
        } else {
            listOf(
                if (ltr) room.copy(right = minOf(room.right, menu.left - gap)) else room.copy(left = maxOf(room.left, menu.right + gap)),
                room.copy(bottom = minOf(room.bottom, menu.top - gap)),
            )
        }
    }
}

/** Where the controls are, in root coordinates, so a hover can tell whether it rests on them. */
private class ControlRegions {
    /** The player's own position in the root. */
    var origin: Offset = Offset.Zero
    val rects = HashMap<String, Rect>()

    fun contains(local: Offset): Boolean {
        val point = local + origin
        return rects.values.any { it.contains(point) }
    }
}

/**
 * The menus the desktop docks along the right edge rather than opening at their buttons: the long lists, and the pages
 * that need the room (the shaders' descriptions, the file info's rows, the subtitle search's field and results).
 */
private val PlayerMenu.docksOnDesktop: Boolean
    get() = this == PlayerMenu.CHAPTERS || this == PlayerMenu.QUEUE || this == PlayerMenu.CONTENT_STRIP ||
        this == PlayerMenu.SHADERS || this == PlayerMenu.FILE_INFO || this == PlayerMenu.SUBTITLE_SEARCH

/** The menus a phone or tablet held on its side docks along the right edge ([PlayerMenuSheet]): all but the room's. */
internal val PlayerMenu.docksInLandscape: Boolean
    get() = this != PlayerMenu.WATCH_TOGETHER

/**
 * Registers this element as part of the controls under [name] (a hover over it keeps them up) and keeps clicks on its
 * empty parts from reaching the video beneath.
 */
private fun Modifier.controlRegion(regions: ControlRegions, name: String): Modifier =
    this then ControlRegionElement(regions, name) then Modifier.pointerInput(Unit) {
        awaitPointerEventScope { while (true) awaitPointerEvent() }
    }

private data class ControlRegionElement(val regions: ControlRegions, val name: String) : ModifierNodeElement<ControlRegionNode>() {
    override fun create() = ControlRegionNode(regions, name)

    override fun update(node: ControlRegionNode) {
        node.regions.rects.remove(node.name)
        node.regions = regions
        node.name = name
    }
}

private class ControlRegionNode(var regions: ControlRegions, var name: String) : Modifier.Node(), GlobalPositionAwareModifierNode {
    override fun onGloballyPositioned(coordinates: LayoutCoordinates) {
        regions.rects[name] = coordinates.boundsInRoot()
    }

    override fun onDetach() {
        regions.rects.remove(name)
    }
}

/** The pixels one wheel notch scrolls, as the store measures the wheel. */
private const val WHEEL_NOTCH_PIXELS = 20.0

/** The wheel, once a control under it left it alone, to the player as [InputEvent.Wheel] (in the store's pixels). */
private fun Modifier.wheelToPlayer(onInput: (InputEvent) -> Boolean): Modifier = pointerInput(Unit) {
    awaitPointerEventScope {
        while (true) {
            val event = awaitPointerEvent(PointerEventPass.Final)
            if (event.type != PointerEventType.Scroll) continue
            val change = event.changes.firstOrNull()?.takeIf { !it.isConsumed } ?: continue
            // Compose reports a notch as 1, wheel-down positive; the store takes pixels, as a notch scrolls 20.
            val deltaY = change.scrollDelta.y.toDouble() * WHEEL_NOTCH_PIXELS
            if (deltaY != 0.0 && onInput(InputEvent.Wheel(deltaY))) change.consume()
        }
    }
}

/**
 * A vertical swipe up on a phone's bottom controls: as the finger lifts past halfway up the swipe's reach, or flicked
 * up ([ContentStripSwipe]), it opens the chapters and the queue ([PlayerMenu.CONTENT_STRIP]). The timeline's own
 * horizontal drags are its own.
 */
private fun Modifier.stripSwipe(onCommand: (PlayerCommand) -> Unit): Modifier = pointerInput(onCommand) {
    val velocity = VelocityTracker()
    var progress = 0f
    detectVerticalDragGestures(
        onDragStart = {
            velocity.resetTracking()
            progress = 0f
        },
        onDragEnd = {
            if (ContentStripSwipe.opens(progress, velocity.calculateVelocity().y.toDp().value)) {
                onCommand(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP))
            }
        },
    ) { change, amount ->
        change.consume()
        velocity.addPointerInputChange(change)
        progress = ContentStripSwipe.drag(progress, amount.toDp().value)
    }
}
