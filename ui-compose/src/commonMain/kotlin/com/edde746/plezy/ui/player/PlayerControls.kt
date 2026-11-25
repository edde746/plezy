package com.edde746.plezy.ui.player

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Constraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PlainTooltip
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TooltipBox
import androidx.compose.material3.TooltipDefaults
import androidx.compose.material3.rememberTooltipState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.node.GlobalPositionAwareModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.isSpecified
import coil3.compose.AsyncImage
import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.VideoFit
import com.edde746.plezy.presentation.player.ControlsScrim
import com.edde746.plezy.presentation.player.MovableBarButton
import com.edde746.plezy.presentation.player.PictureInPictureHost
import com.edde746.plezy.presentation.player.PictureInPictureRules
import com.edde746.plezy.presentation.player.PictureInPictureVideo
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.PlaybackStatus
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.ScrubState
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.presentation.player.TopBarButtons
import com.edde746.plezy.presentation.player.VolumeState
import com.edde746.plezy.presentation.watch.PlayerWatchUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.beyond
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import com.edde746.plezy.ui.cast.CastingFromLine
import com.edde746.plezy.ui.cast.LocalCastSender
import com.edde746.plezy.ui.cast.castIcon
import com.edde746.plezy.ui.watch.RoomPill
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

/**
 * The controls' sizes for the window at hand: compact on every form factor, a step larger on TV. The controls keep
 * [edge] from the window's sides (the screen padding: overscan-safe on TV) and [vertical] from its top and bottom; icon
 * buttons reach [inset] past the edge, so their icons line up with the time labels and the title.
 */
@Immutable
internal class PlayerMetrics(
    val tv: Boolean,
    val edge: Dp,
    val vertical: Dp,
    val button: Dp,
    val icon: Dp,
    val playButton: Dp,
    val playIcon: Dp,
    val gap: Dp,
    val timeline: Dp,
) {
    val inset: Dp get() = (button - icon) / 2
}

@Composable
internal fun rememberPlayerMetrics(): PlayerMetrics {
    val layout = LocalWindowLayout.current
    val edge = LocalPlezyDimens.current.screenPadding
    return remember(layout.formFactor, edge) {
        if (layout.formFactor == FormFactor.TV) {
            PlayerMetrics(tv = true, edge = edge, vertical = 28.dp, button = 48.dp, icon = 28.dp, playButton = 56.dp, playIcon = 36.dp, gap = 8.dp, timeline = 40.dp)
        } else {
            PlayerMetrics(tv = false, edge = edge, vertical = 12.dp, button = 40.dp, icon = 24.dp, playButton = 48.dp, playIcon = 32.dp, gap = 2.dp, timeline = 32.dp)
        }
    }
}

/**
 * The menu buttons: where each is, in root coordinates, while it is laid out (a desktop menu opens over the button that
 * opened it, or the settings' when that button is gone: the room pill after leaving a room), and its focus (on
 * TV focus goes back to that button when its menu closes). A menu belongs to its [PlayerMenu.parent]'s button.
 */
internal class MenuButtons {
    private val rects = HashMap<PlayerMenu, Rect>()
    private val requesters = HashMap<PlayerMenu, FocusRequester>()

    fun rect(menu: PlayerMenu): Rect? = rects[menu.parent]

    fun focus(menu: PlayerMenu): FocusRequester = requesters.getOrPut(menu.parent) { FocusRequester() }

    /** This element is [menu]'s button: its place is kept while it is laid out and goes as it leaves. */
    fun place(menu: PlayerMenu): Modifier = MenuButtonElement(this, menu.parent)

    private data class MenuButtonElement(val buttons: MenuButtons, val menu: PlayerMenu) : ModifierNodeElement<MenuButtonNode>() {
        override fun create() = MenuButtonNode(buttons, menu)

        override fun update(node: MenuButtonNode) {
            node.buttons.rects.remove(node.menu)
            node.buttons = buttons
            node.menu = menu
        }
    }

    private class MenuButtonNode(var buttons: MenuButtons, var menu: PlayerMenu) : Modifier.Node(), GlobalPositionAwareModifierNode {
        override fun onGloballyPositioned(coordinates: LayoutCoordinates) {
            buttons.rects[menu] = coordinates.boundsInRoot()
        }

        override fun onDetach() {
            buttons.rects.remove(menu)
        }
    }
}

/**
 * The top bar's row as it last laid out with the controls up, in pixels: how far Back and the title's text (its lines'
 * own width, not the room they have) reach in from the row's leading side, how far its trailing group (the live badge,
 * the room pill, the cast button, the menus) reaches in from its trailing side (0 without one), Back's middle, down
 * from the row's top, and how far down its parts reach ([bottom]: the bar as drawn, without the margin under it). The
 * messages at the top go between the two, level with Back; the playback info goes under [bottom] (PlayerOverlays).
 */
@Immutable
internal data class TopBarReach(val leading: Int, val trailing: Int, val middle: Int, val bottom: Int)

/**
 * The bottom bar as it last laid out, in pixels: its top row's top (the timeline row's; live, the buttons'), up from the
 * bar's bottom edge, and on a phone or tablet the chapters and queue page's hint over that row ([hint], from the bar's
 * bottom-left corner: its top and bottom negative; null without one). The bottom-trailing corner goes directly above
 * the top row; the playback info keeps above the row and clear of the hint (PlayerOverlays).
 */
@Immutable
internal data class BottomBarReach(val topRow: Int, val hint: Rect?)

/** A bar's layout and its named parts', kept as they're placed: [bounds] is a part's in the bar, null once it's gone. */
private class BarParts {
    private var bar: LayoutCoordinates? = null
    private val parts = HashMap<String, LayoutCoordinates>()

    val size: IntSize get() = bar?.size ?: IntSize.Zero

    fun bar(onPlaced: () -> Unit): Modifier = Modifier.onGloballyPositioned {
        bar = it
        onPlaced()
    }

    fun part(name: String, onPlaced: () -> Unit): Modifier = Modifier.onGloballyPositioned {
        parts[name] = it
        onPlaced()
    }

    fun bounds(name: String): Rect? {
        val bar = bar?.takeIf { it.isAttached } ?: return null
        val part = parts[name]?.takeIf { it.isAttached } ?: return null
        return bar.localBoundingBoxOf(part, clipBounds = false)
    }
}

private const val CLOSE = "close"
private const val TITLE = "title"
private const val TRAILING = "trailing"
private const val TOP_ROW = "topRow"
private const val HINT = "hint"

/**
 * Back, then the title and the episode line under it in the title's colour, on the scrim's top edge that reaches under
 * them so both read at 4.5:1 or more over a white frame ([PlayerUiState.title] and
 * [PlayerUiState.subtitle]: the series and "S1 · E2 · Name · 45m" for an episode), and while a cast plays here the
 * "Casting from <device>" line ([castingFrom]); at the end the live badge ([liveBadge]: live, without a rewind window),
 * the room pill in a watch-together room (it opens the session sheet, [PlayerMenu.WATCH_TOGETHER]; not over the error),
 * the cast button ([PlayerCastButton]), then with [menus] (phones and tablets) the menus and the window's buttons
 * ([MenuRow]: Chapters and Queue left to the chapters and queue page a swipe up on the bottom bar opens), of which a
 * bar too narrow for them all moves the rotation lock, the fit, picture in picture and the screen lock, in that order,
 * into the options sheet ([TopBarButtons.moved], told to the sheet by [LocalMovedBarButtons]). While the
 * controls are up [onReach] gets how far its parts reach into the row as they lay out ([TopBarReach]). Harness names:
 * `player.back`, `player.title` (the title's lines, as wide as their text), `player.castingFrom`, `player.liveBadge`,
 * `player.watch`, `player.cast`.
 */
@Composable
internal fun PlayerTopBar(
    state: PlayerUiState,
    buttons: MenuButtons,
    onCommand: (PlayerCommand) -> Unit,
    onReach: (TopBarReach) -> Unit,
    modifier: Modifier = Modifier,
    liveBadge: Boolean = false,
    menus: Boolean = false,
    castingFrom: String? = null,
) {
    val metrics = rememberPlayerMetrics()
    val typography = MaterialTheme.typography
    val ltr = LocalLayoutDirection.current == LayoutDirection.Ltr
    val parts = remember { BarParts() }
    // A phone's or tablet's bar: the title keeps its room and the movable buttons that don't fit move into the options
    // sheet, by the bar's width alone (the part that always stays is the bar less the title and the movable buttons).
    val movedHolder = LocalMovedBarButtons.current
    val present = presentMovableButtons(state)
    var barWidth by remember { mutableIntStateOf(0) }
    var titleWidth by remember { mutableIntStateOf(0) }
    var movableWidth by remember { mutableIntStateOf(0) }
    val titleStyle = (if (metrics.tv) typography.titleLarge else typography.titleMedium).contentDirection()
    val measurer = rememberTextMeasurer()
    val lineWidth = remember(measurer, titleStyle) { measurer.measure("n".repeat(TopBarButtons.TITLE_CHARACTERS), titleStyle).size.width }
    val density = LocalDensity.current
    val moved = if (!menus || !state.showsPlaybackControls || barWidth == 0) {
        emptySet()
    } else {
        with(density) {
            val fixed = barWidth - titleWidth - movableWidth
            TopBarButtons.moved(present, barWidth.toFloat(), fixed.toFloat(), lineWidth.toFloat(), metrics.button.toPx(), metrics.gap.toPx())
        }
    }
    SideEffect { movedHolder.buttons = moved }
    fun report() {
        if (!state.controlsVisible) return
        val close = parts.bounds(CLOSE) ?: return
        val title = parts.bounds(TITLE) ?: return
        val width = parts.size.width
        // The title's lines follow Back: as far as they reach, so does Back.
        val leading = if (ltr) title.right else width - title.left
        val trailingPart = parts.bounds(TRAILING)?.takeIf { it.width > 0f }
        val trailing = trailingPart?.let { if (ltr) width - it.left else it.right } ?: 0f
        val bottom = maxOf(close.bottom, title.bottom, trailingPart?.bottom ?: 0f)
        onReach(TopBarReach(leading.roundToInt(), trailing.roundToInt(), close.center.y.roundToInt(), bottom.roundToInt()))
    }
    // A part that goes (the room pill, as the room ends) lays nothing out: it's left out from the next frame.
    SideEffect { report() }
    Row(
        modifier
            .fillMaxWidth()
            .onSizeChanged { barWidth = it.width }
            .then(parts.bar(::report))
            .padding(start = metrics.edge - metrics.inset, end = metrics.edge - if (menus) metrics.inset else 0.dp, top = metrics.vertical, bottom = metrics.vertical * 2),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        PlayerButton(
            PlezyIcons.ArrowBack,
            T.nav.player.close,
            onClick = { onCommand(PlayerCommand.Close) },
            modifier = parts.part(CLOSE, ::report),
            probe = "player.back",
        )
        Box(Modifier.weight(1f).onSizeChanged { titleWidth = it.width }) {
            Column(parts.part(TITLE, ::report).layoutProbe("player.title", reportsFocus = false)) {
                Text(
                    state.title,
                    style = titleStyle,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                state.subtitle?.let {
                    Text(
                        it,
                        style = if (metrics.tv) typography.bodyMedium else typography.bodySmall,
                        color = PlezyColors.OnVideo,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                castingFrom?.let { CastingFromLine(it, "player.castingFrom", Modifier.padding(top = 2.dp), color = PlezyColors.OnVideo) }
            }
        }
        Row(parts.part(TRAILING, ::report), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            if (liveBadge) LiveBadge()
            if (state.showsPlaybackControls) {
                state.watch?.let { watch ->
                    val open = state.menu == PlayerMenu.WATCH_TOGETHER
                    RoomPill(
                        watch.pill,
                        onClick = { onCommand(if (open) PlayerCommand.CloseMenu else PlayerCommand.OpenMenu(PlayerMenu.WATCH_TOGETHER)) },
                        modifier = Modifier
                            .then(buttons.place(PlayerMenu.WATCH_TOGETHER))
                            .focusRequester(buttons.focus(PlayerMenu.WATCH_TOGETHER)),
                    )
                }
                PlayerCastButton()
            }
            if (menus && state.showsPlaybackControls) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(metrics.gap)) {
                    MenuRow(state, buttons, onCommand, hideStripItems = state.hasStripContent, moved = moved, onMovableWidth = { movableWidth = it })
                }
            }
        }
    }
}

/**
 * The top bar's buttons a narrow bar moved into the options sheet ([TopBarButtons.moved]), as the bar last decided:
 * the options sheet offers a row for each of them and for no other. [PlayerScreen] provides one per player.
 */
@Stable
internal class MovedBarButtons {
    var buttons: Set<MovableBarButton> by mutableStateOf(emptySet())
}

internal val LocalMovedBarButtons = staticCompositionLocalOf { MovedBarButtons() }

/**
 * The player's cast button: the picker opened from the player, where a choice hands over what plays here and closes
 * this player; the connected icon, filled, while casting. Nothing without a [LocalCastSender].
 */
@Composable
private fun PlayerCastButton() {
    val sender = LocalCastSender.current ?: return
    val casting = sender.state.collectAsState().value.casting
    PlayerButton(castIcon(casting), T.cast.title, onClick = { sender.openPicker(fromPlayer = true) }, probe = "player.cast", selected = casting)
}

/** The live channel's "LIVE" badge, in the live red. Harness name `player.liveBadge`. */
@Composable
private fun LiveBadge() {
    Surface(Modifier.layoutProbe("player.liveBadge", reportsFocus = false), shape = MaterialTheme.shapes.extraSmall, color = PlezyColors.Live, contentColor = PlezyColors.OnVideo) {
        Text(T.player.live.badge, Modifier.padding(horizontal = 8.dp, vertical = 2.dp), style = MaterialTheme.typography.labelMedium)
    }
}

/** Whether the bottom controls show yet: not before the video's first frame (the session resolving, the file opening). */
internal val PlayerUiState.hasFirstFrame: Boolean
    get() = status != PlaybackStatus.RESOLVING && status != PlaybackStatus.OPENING

/** Whether there is anything for the chapters and queue page ([PlayerMenu.CONTENT_STRIP]): chapters or a queue. */
internal val PlayerUiState.hasStripContent: Boolean get() = chapters.isNotEmpty() || queue.isNotEmpty()

/** Where the player's picture-in-picture button reports a failed start ([PlayerScreen]'s `onPictureInPictureFailed`). */
internal val LocalPictureInPictureFailed = staticCompositionLocalOf<(String) -> Unit> { {} }

/** The platform's picture in picture for the player's button ([PlayerScreen]'s `pictureInPictureHost`); null: no button. */
internal val LocalPictureInPictureHost = staticCompositionLocalOf<PictureInPictureHost?> { null }

/**
 * The timeline with the position and the time left with the clock time it ends ("−0:15 · 21:43"), then one row of
 * buttons: the transport on the left, the menus on the right, on desktop and TV. On phones and tablets the bar is the
 * timeline alone, its times under it (and with a live window, the go-to-live label): the transport is centred over the video
 * ([CentreTransport]) and the menus sit in the top bar ([PlayerTopBar]). Like the timeline above it, the transport runs left to
 * right in every language. A window too narrow for both groups on one line (a phone upright) puts the menus on a line
 * of their own, at its end, wrapping where even that line is too short. [onControlsHeight] gets the height in pixels
 * from the bar's top row to its bottom edge: everything in it is the controls, which subtitles stay above. [onReach]
 * gets where the top row's top is as it lays out ([BottomBarReach]).
 *
 * The transport: Previous, the previous chapter, back N s, Play/Pause, forward N s, the next chapter, Next (a video);
 * back, Play/Pause, forward and the go-to-live label (live with a rewind window); Play/Pause alone (live: the top bar's
 * LIVE says it).
 * The menus: the volume (desktop), Settings, Audio, Subtitles, Chapters and Queue (not on TV, where Down from the row
 * opens both on one page, [PlayerMenu.CONTENT_STRIP]), picture in picture, the fit, the rotation lock and the screen
 * lock (phones and tablets), always on top (Windows and Linux) and fullscreen (desktop) ([MenuRow]).
 *
 * A watch-together guest of a host-only room has Play/Pause, the skips, the chapters and the timeline off and dimmed
 * (a press says why, [PlayerWatchUi.controlsLocked]); changing the episode is the host's alone
 * ([PlayerWatchUi.canChangeEpisode]). A guest whose player paused here alone while the room plays on has Play/Pause on.
 *
 * On TV and with the keyboard, focus comes to the row on Play/Pause ([PlayerFocus.playPause]). From the timeline, Down
 * goes to Play/Pause and Up to the prompt button while it shows, else to the info card while it shows, else hides the
 * controls.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun PlayerBottomBar(
    state: PlayerUiState,
    timeline: StateFlow<TimelineState>,
    config: PlayerConfig,
    focus: PlayerFocus,
    onCommand: (PlayerCommand) -> Unit,
    onTimelineFocusChanged: (Boolean) -> Unit,
    onControlsHeight: (Int) -> Unit,
    onReach: (BottomBarReach) -> Unit,
    modifier: Modifier = Modifier,
) {
    val metrics = rememberPlayerMetrics()
    val formFactor = LocalWindowLayout.current.formFactor
    val desktop = formFactor == FormFactor.DESKTOP
    val handheld = formFactor == FormFactor.HANDHELD
    val strip = metrics.tv && state.hasStripContent
    val parts = remember { BarParts() }
    fun report() {
        val topRow = parts.bounds(TOP_ROW) ?: return
        val height = parts.size.height.toFloat()
        onReach(BottomBarReach((height - topRow.top).roundToInt(), parts.bounds(HINT)?.translate(0f, -height)))
    }
    SideEffect { report() }
    Column(
        modifier
            .fillMaxWidth()
            .then(parts.bar(::report))
            .padding(start = metrics.edge - metrics.inset, end = metrics.edge - metrics.inset, top = metrics.vertical * 3)
            // Below the bar's top margin: the timeline row, the buttons and the bottom margin.
            .onSizeChanged { onControlsHeight(it.height) }
            .padding(bottom = metrics.vertical),
    ) {
        if (handheld && state.hasStripContent) {
            // The chapters and queue page's hint, as a swipe up on the bar opens it: a tap does too.
            PlayerButton(
                PlezyIcons.KeyboardArrowUp,
                state.menuTitle(PlayerMenu.CONTENT_STRIP),
                onClick = { onCommand(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP)) },
                modifier = Modifier.align(Alignment.CenterHorizontally).then(parts.part(HINT, ::report)),
                probe = "player.strip",
            )
        }
        if (state.showsTimeline) {
            TimelineRow(
                timeline,
                liveWindow = state.mode == PlaybackMode.LIVE_WINDOW,
                seekable = state.canSeek,
                endsAt = state.mode == PlaybackMode.VIDEO,
                stacked = handheld,
                onCommand = onCommand,
                onTimelineFocusChanged = onTimelineFocusChanged,
                modifier = parts.part(TOP_ROW, ::report).padding(horizontal = metrics.inset),
                onVertical = { up ->
                    when {
                        !up -> focus.playPause.requestFocus()
                        state.prompt != null && focus.prompt.requestFocus() -> true
                        else -> {
                            onCommand(PlayerCommand.HideControls)
                            true
                        }
                    }
                },
            )
        }
        if (handheld) {
            // The transport is centred over the video ([CentreTransport]) and the menus are in the top bar; with a live
            // window, the go-to-live label stays here (live without one, the top bar's LIVE says it).
            if (state.mode == PlaybackMode.LIVE_WINDOW) LiveLabel(timeline, onGoToLive = { onCommand(PlayerCommand.GoToLive) })
            return@Column
        }
        ButtonRow(
            gap = metrics.gap,
            modifier = Modifier
                .fillMaxWidth()
                .then(if (state.showsTimeline) Modifier else parts.part(TOP_ROW, ::report))
                .onKeyEvent {
                    // Down from the row: the chapters and the queue, where there are any.
                    if (strip && it.type == KeyEventType.KeyDown && it.key == Key.DirectionDown) {
                        onCommand(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP))
                        true
                    } else {
                        false
                    }
                },
            transport = {
                // Time runs left to right on the timeline in every language, and so does the transport under it.
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(metrics.gap)) {
                        Transport(state, timeline, focus, onCommand, tooltips = desktop)
                    }
                }
            },
            menus = {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(metrics.gap, Alignment.End),
                    verticalArrangement = Arrangement.spacedBy(metrics.gap),
                    itemVerticalAlignment = Alignment.CenterVertically,
                ) {
                    MenuRow(state, focus.menuButtons, onCommand, hideStripItems = strip)
                }
            },
        )
    }
}

/**
 * The bar's button row ([PlayerBottomBar]): the [transport] at the leading edge and the [menus] at the trailing one,
 * centred on one line where the menus fit beside the transport; else the menus on their own line under it (wrapping
 * there as they must), at the trailing edge, [gap] apart. Always inside the width it is given.
 */
@Composable
private fun ButtonRow(gap: Dp, modifier: Modifier, transport: @Composable () -> Unit, menus: @Composable () -> Unit) {
    Layout(contents = listOf(transport, menus), modifier = modifier) { (transportPart, menusPart), constraints ->
        val width = constraints.maxWidth
        val space = gap.roundToPx()
        val left = transportPart.map { it.measure(Constraints(maxWidth = width)) }
        val leftWidth = left.maxOfOrNull { it.width } ?: 0
        val leftHeight = left.maxOfOrNull { it.height } ?: 0
        val room = width - leftWidth - space
        val beside = menusPart.sumOf { it.maxIntrinsicWidth(leftHeight) } <= room
        val right = menusPart.map { it.measure(Constraints(maxWidth = if (beside) room.coerceAtLeast(0) else width)) }
        val rightHeight = right.maxOfOrNull { it.height } ?: 0
        val height = if (beside) maxOf(leftHeight, rightHeight) else leftHeight + (if (rightHeight > 0) space + rightHeight else 0)
        layout(width, height.coerceIn(constraints.minHeight, constraints.maxHeight)) {
            val leftTop = if (beside) (height - leftHeight) / 2 else 0
            left.forEach { it.placeRelative(0, leftTop + (leftHeight - it.height) / 2) }
            val rightTop = if (beside) (height - rightHeight) / 2 else leftHeight + space
            right.forEach { it.placeRelative(width - it.width, rightTop) }
        }
    }
}

/**
 * The transport ([PlayerBottomBar]). The chapter buttons are off without chapters, Previous and Next where there is no
 * episode that way; each off button stays in its place and keeps focus, dimmed. Previous is named "Restart" past the
 * first seconds, where it restarts what plays, and both name an episode only for an episode ([EpisodeButtons]). The
 * seek buttons' icons say their step where there is one for it (5, 10, 30 s). With [tooltips] (desktop) a pointer
 * resting on a chapter button names the chapter it goes to, and on Previous or Next what it does.
 */
@Composable
private fun Transport(
    state: PlayerUiState,
    timeline: StateFlow<TimelineState>,
    focus: PlayerFocus,
    onCommand: (PlayerCommand) -> Unit,
    tooltips: Boolean,
) {
    val canControl = state.canControl
    val video = state.mode == PlaybackMode.VIDEO
    val whole = state.seekSeconds
    val seconds = whole.toDouble()
    val chapters = state.chapters.isNotEmpty()
    val seeks = state.showsSeekButtons || state.mode == PlaybackMode.LIVE_WINDOW
    val previousLabel = state.episodes?.previousLabel ?: T.videoControls.previousButton
    val nextLabel = state.episodes?.nextLabel ?: T.videoControls.nextButton
    if (video) {
        PlayerButton(
            PlezyIcons.SkipPrevious,
            previousLabel,
            onClick = { onCommand(PlayerCommand.PreviousEpisode) },
            probe = "player.previous",
            available = state.episodes?.previous == true,
            tooltip = if (tooltips) previousLabel else null,
        )
        PlayerButton(
            PlezyIcons.FirstPage,
            T.videoControls.previousChapterButton,
            onClick = { onCommand(PlayerCommand.PreviousChapter) },
            probe = "player.previousChapter",
            available = canControl && chapters,
            tooltip = if (tooltips) state.previousChapterTitle.orEmpty() else null,
        )
    }
    if (seeks) {
        PlayerButton(
            replayIcon(whole),
            T.videoControls.seekBackwardButton(whole.toString()),
            onClick = { onCommand(PlayerCommand.SeekBy(-seconds)) },
            probe = "player.rewind",
            available = canControl,
        )
    }
    PlayerButton(
        if (state.paused) PlezyIcons.PlayArrow else PlezyIcons.Pause,
        state.playPauseLabel,
        onClick = { onCommand(PlayerCommand.TogglePause) },
        probe = "player.playPause",
        large = true,
        available = state.canPlayPause,
        focusRequester = focus.playPause,
    )
    if (seeks) {
        PlayerButton(
            forwardIcon(whole),
            T.videoControls.seekForwardButton(whole.toString()),
            onClick = { onCommand(PlayerCommand.SeekBy(seconds)) },
            probe = "player.fastForward",
            available = canControl,
        )
    }
    if (video) {
        PlayerButton(
            PlezyIcons.LastPage,
            T.videoControls.nextChapterButton,
            onClick = { onCommand(PlayerCommand.NextChapter) },
            probe = "player.nextChapter",
            available = canControl && chapters,
            tooltip = if (tooltips) state.nextChapterTitle.orEmpty() else null,
        )
        PlayerButton(
            PlezyIcons.SkipNext,
            nextLabel,
            onClick = { onCommand(PlayerCommand.NextEpisode) },
            probe = "player.next",
            available = state.episodes?.next == true,
            tooltip = if (tooltips) nextLabel else null,
        )
    } else if (state.mode == PlaybackMode.LIVE_WINDOW) {
        // The go-to-live pill's own padding stands in for the label's gap: its text stays where it was. Live without a
        // window, the top bar's LIVE says it.
        LiveLabel(timeline, onGoToLive = { onCommand(PlayerCommand.GoToLive) })
    }
}

/**
 * A phone's or tablet's transport, centred over the video, each button on a black circle at half opacity so it reads
 * over any picture: Previous, back by the seek step, Play/Pause, forward by it and Next (a video; the seeks where
 * [PlayerUiState.showsSeekButtons]), Play/Pause alone (live). As iOS's centre transport: the episode buttons a size
 * smaller than the seek buttons, 36 dp between three buttons and between five on a tablet, 16 dp between five on a
 * phone (336 dp in all, inside a 360 dp phone's margins). The double tap on either side of the video and the timeline
 * seek too; the chapters are on the chapters and queue page a swipe up on the bar opens. Previous and Next where there
 * is nothing that way ([PlayerUiState.episodes]) keep their place, dimmed; a host-only room's guest has Play/Pause and
 * the seeks dimmed as in [Transport].
 */
@Composable
internal fun CentreTransport(
    state: PlayerUiState,
    focus: PlayerFocus,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier = Modifier,
) {
    val video = state.mode == PlaybackMode.VIDEO
    val whole = state.seekSeconds
    val seconds = whole.toDouble()
    val window = LocalWindowSize.current.value
    val tablet = minOf(window.width, window.height) >= TabletMinSide
    val episodes = state.episodes
    val gap = if (episodes == null || tablet) 36.dp else 16.dp
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(gap)) {
            if (video && episodes != null) {
                PlayerButton(
                    PlezyIcons.SkipPrevious,
                    episodes.previousLabel,
                    onClick = { onCommand(PlayerCommand.PreviousEpisode) },
                    probe = "player.previous",
                    available = episodes.previous,
                    size = CentreEpisodeButton,
                    iconSize = CentreEpisodeIcon,
                    background = CentreCircle,
                )
            }
            if (video && state.showsSeekButtons) {
                PlayerButton(
                    replayIcon(whole),
                    T.videoControls.seekBackwardButton(whole.toString()),
                    onClick = { onCommand(PlayerCommand.SeekBy(-seconds)) },
                    probe = "player.rewind",
                    available = state.canControl,
                    size = CentreSeekButton,
                    iconSize = CentreSeekIcon,
                    background = CentreCircle,
                )
            }
            PlayerButton(
                if (state.paused) PlezyIcons.PlayArrow else PlezyIcons.Pause,
                state.playPauseLabel,
                onClick = { onCommand(PlayerCommand.TogglePause) },
                probe = "player.playPause",
                available = state.canPlayPause,
                focusRequester = focus.playPause,
                size = CentrePlayButton,
                iconSize = CentrePlayIcon,
                background = CentreCircle,
            )
            if (video && state.showsSeekButtons) {
                PlayerButton(
                    forwardIcon(whole),
                    T.videoControls.seekForwardButton(whole.toString()),
                    onClick = { onCommand(PlayerCommand.SeekBy(seconds)) },
                    probe = "player.fastForward",
                    available = state.canControl,
                    size = CentreSeekButton,
                    iconSize = CentreSeekIcon,
                    background = CentreCircle,
                )
            }
            if (video && episodes != null) {
                PlayerButton(
                    PlezyIcons.SkipNext,
                    episodes.nextLabel,
                    onClick = { onCommand(PlayerCommand.NextEpisode) },
                    probe = "player.next",
                    available = episodes.next,
                    size = CentreEpisodeButton,
                    iconSize = CentreEpisodeIcon,
                    background = CentreCircle,
                )
            }
        }
    }
}

/** iOS's centre transport sizes: the episode buttons, the seek buttons and Play/Pause. */
private val CentreEpisodeButton = 44.dp
private val CentreEpisodeIcon = 24.dp
private val CentreSeekButton = 56.dp
private val CentreSeekIcon = 28.dp
private val CentrePlayButton = 72.dp
private val CentrePlayIcon = 40.dp
private val CentreCircle = Color.Black.copy(alpha = 0.5f)

/** A window this short on its shorter side is a phone's; a tablet's is at least this. */
private val TabletMinSide = 600.dp

/** The seek-back icon for a step of [seconds]: numbered for 5, 10 and 30 s, else plain. */
internal fun replayIcon(seconds: Int): ImageVector = when (seconds) {
    5 -> PlezyIcons.Replay5
    10 -> PlezyIcons.Replay10
    30 -> PlezyIcons.Replay30
    else -> PlezyIcons.Replay
}

/** The seek-forward icon for a step of [seconds]: numbered for 5, 10 and 30 s, else plain. */
internal fun forwardIcon(seconds: Int): ImageVector = when (seconds) {
    5 -> PlezyIcons.Forward5
    10 -> PlezyIcons.Forward10
    30 -> PlezyIcons.Forward30
    else -> PlezyIcons.Forward
}

/**
 * The menus and the window's buttons, in this order: the volume (desktop), Settings (marked while a zoom or a shader is
 * on, [PlayerUiState.settingsHighlighted]), Audio and Subtitles (each where there is a choice; Subtitles struck through
 * while the subtitle shortcut hid them, [PlayerUiState.subtitlesHidden]), Chapters and Queue (where there are any; on TV
 * the chapters and queue page holds them instead, [hideStripItems]), picture in picture, the picture's fit (cycling
 * letterbox, fill and stretch, its icon the fit now), the rotation lock (phones and tablets), the screen lock (phones
 * and tablets), always on top (Windows and Linux) and fullscreen (desktop). Of these the [MovableBarButton]s [moved]
 * into the options sheet ([TopBarButtons]) stay out, and with [onMovableWidth] the others sit in a row of their own
 * whose width goes to it. Harness names: `player.options`, `player.audio`, `player.subtitles`, `player.chapters`,
 * `player.queue`, `player.pip`, `player.fit`, `player.rotation`, `player.lock`, `player.alwaysOnTop`,
 * `player.fullscreen`. Each names itself in a tooltip under a pointer resting on it or a long press.
 */
@Composable
private fun MenuRow(
    state: PlayerUiState,
    buttons: MenuButtons,
    onCommand: (PlayerCommand) -> Unit,
    hideStripItems: Boolean,
    moved: Set<MovableBarButton> = emptySet(),
    onMovableWidth: ((Int) -> Unit)? = null,
) {
    val formFactor = LocalWindowLayout.current.formFactor
    if (formFactor == FormFactor.DESKTOP) VolumeControl(state.volume, onCommand)
    MenuButton(PlezyIcons.Tune, T.videoControls.settingsButton, PlayerMenu.OPTIONS, state.menu, buttons, onCommand, "player.options", adjusted = state.settingsHighlighted)
    if (state.showsAudioMenu) {
        MenuButton(PlezyIcons.Audiotrack, T.player.menu.audio, PlayerMenu.AUDIO, state.menu, buttons, onCommand, "player.audio")
    }
    if (state.showsSubtitleMenu) {
        MenuButton(
            if (state.subtitlesHidden) PlezyIcons.SubtitlesOff else PlezyIcons.Subtitles,
            T.player.menu.subtitles,
            PlayerMenu.SUBTITLES,
            state.menu,
            buttons,
            onCommand,
            "player.subtitles",
        )
    }
    if (state.chapters.isNotEmpty() && !hideStripItems) {
        MenuButton(PlezyIcons.MenuBook, T.videoControls.chaptersButton, PlayerMenu.CHAPTERS, state.menu, buttons, onCommand, "player.chapters")
    }
    if (state.queue.isNotEmpty() && !hideStripItems) {
        MenuButton(PlezyIcons.Subscriptions, T.videoControls.queue, PlayerMenu.QUEUE, state.menu, buttons, onCommand, "player.queue")
    }
    val movables: @Composable () -> Unit = {
        LocalPictureInPictureHost.current?.takeIf { MovableBarButton.PICTURE_IN_PICTURE !in moved }?.let { pip ->
            val scope = rememberCoroutineScope()
            val failed = LocalPictureInPictureFailed.current
            PlayerButton(
                PlezyIcons.PictureInPicture,
                T.videoControls.pipButton,
                onClick = {
                    scope.launch {
                        PictureInPictureRules.toggle(pip, video = { PictureInPictureVideo() }, prepare = {}, restore = {}, report = failed)
                    }
                },
                probe = "player.pip",
                tooltip = T.videoControls.pipButton,
            )
        }
        videoFitOption(state)?.takeIf { MovableBarButton.VIDEO_FIT !in moved }?.let { fit ->
            val current = fit.choices.indexOfFirst { it.selected }.coerceAtLeast(0)
            val next = fit.choices.getOrNull((current + 1) % fit.choices.size.coerceAtLeast(1))
            val icon = when ((fit.choices.getOrNull(current)?.command as? PlayerCommand.SetVideoFit)?.fit) {
                VideoFit.COVER -> PlezyIcons.AspectRatio
                VideoFit.FILL -> PlezyIcons.SettingsOverscan
                else -> PlezyIcons.FitScreen
            }
            PlayerButton(icon, T.videoControls.aspectRatioButton, onClick = { next?.let { onCommand(it.command) } }, probe = "player.fit", value = fit.value, tooltip = T.videoControls.aspectRatioButton)
        }
        state.rotationLocked?.takeIf { MovableBarButton.ROTATION_LOCK !in moved }?.let { locked ->
            PlayerButton(
                if (locked) PlezyIcons.ScreenLockRotation else PlezyIcons.ScreenRotation,
                if (locked) T.videoControls.unlockRotation else T.videoControls.lockRotation,
                onClick = { onCommand(PlayerCommand.ToggleRotationLock) },
                probe = "player.rotation",
                tooltip = if (locked) T.videoControls.unlockRotation else T.videoControls.lockRotation,
            )
        }
        if (formFactor == FormFactor.HANDHELD && MovableBarButton.SCREEN_LOCK !in moved) {
            PlayerButton(PlezyIcons.Lock, T.videoControls.lockScreen, onClick = { onCommand(PlayerCommand.LockScreen) }, probe = "player.lock", tooltip = T.videoControls.lockScreen)
        }
    }
    if (onMovableWidth == null) {
        movables()
    } else {
        val gap = rememberPlayerMetrics().gap
        Row(Modifier.onSizeChanged { onMovableWidth(it.width) }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(gap)) {
            movables()
        }
    }
    state.alwaysOnTop?.let { onTop ->
        PlayerButton(
            PlezyIcons.Layers,
            T.videoControls.alwaysOnTopButton,
            onClick = { onCommand(PlayerCommand.ToggleAlwaysOnTop) },
            probe = "player.alwaysOnTop",
            selected = onTop,
            checked = onTop,
            tooltip = T.videoControls.alwaysOnTopButton,
        )
    }
    if (formFactor == FormFactor.DESKTOP) {
        PlayerButton(
            if (state.fullscreen) PlezyIcons.FullscreenExit else PlezyIcons.Fullscreen,
            if (state.fullscreen) T.videoControls.exitFullscreenButton else T.videoControls.fullscreenButton,
            onClick = { onCommand(PlayerCommand.ToggleFullscreen) },
            probe = "player.fullscreen",
            tooltip = if (state.fullscreen) T.videoControls.exitFullscreenButton else T.videoControls.fullscreenButton,
        )
    }
}

private fun videoFitOption(state: PlayerUiState): PlayerOption? =
    state.videoFit ?: state.options.firstOrNull { it.id == PlayerOptionId.VIDEO_FIT }

/** The [MovableBarButton]s a phone's or tablet's top bar has for [state], in it or moved. */
@Composable
private fun presentMovableButtons(state: PlayerUiState): Set<MovableBarButton> {
    val pip = LocalPictureInPictureHost.current != null
    val handheld = LocalWindowLayout.current.formFactor == FormFactor.HANDHELD
    return buildSet {
        if (pip) add(MovableBarButton.PICTURE_IN_PICTURE)
        if (videoFitOption(state) != null) add(MovableBarButton.VIDEO_FIT)
        if (state.rotationLocked != null) add(MovableBarButton.ROTATION_LOCK)
        if (handheld) add(MovableBarButton.SCREEN_LOCK)
    }
}

/**
 * `0:15 ━━━━○──── −0:15 · 21:43`: the position, the timeline, the time left and, with [endsAt] (a video), the clock
 * time it ends (read as "Ends at 21:43"), as [timeline] has them now; [seekable] false: no seeking. [stacked] (phones
 * and tablets) puts the times under the bar, the position at its start and the time left at its end. A live window's
 * has where the window starts on the left and nothing on the right: the bar ends at the live edge. Up and Down on the
 * focused bar go where [onVertical] takes them, unless the remote is scrubbing it.
 */
@Composable
private fun TimelineRow(
    timeline: StateFlow<TimelineState>,
    liveWindow: Boolean,
    seekable: Boolean,
    endsAt: Boolean,
    stacked: Boolean,
    onCommand: (PlayerCommand) -> Unit,
    onTimelineFocusChanged: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    onVertical: (up: Boolean) -> Boolean,
) {
    val metrics = rememberPlayerMetrics()
    val style = timeStyle()
    val now by timeline.collectAsState()
    @Composable
    fun Scrub(modifier: Modifier) = ScrubBar(
        timeline = now,
        height = metrics.timeline,
        seekable = seekable,
        live = liveWindow,
        onCommand = onCommand,
        onFocusChanged = onTimelineFocusChanged,
        modifier = modifier
            .layoutProbe("player.scrub")
            .onKeyEvent {
                val up = it.key == Key.DirectionUp
                val vertical = up || it.key == Key.DirectionDown
                it.type == KeyEventType.KeyDown && vertical && now.scrub == null && onVertical(up)
            },
    )

    @Composable
    fun Remaining() {
        if (now.remaining.isEmpty()) return
        val clock = endsAt && now.finishClock.isNotEmpty()
        Text(
            if (clock) "${now.remaining} · ${now.finishClock}" else now.remaining,
            style = style,
            color = PlezyColors.OnVideo,
            maxLines = 1,
            modifier = Modifier
                .layoutProbe("player.remaining", reportsFocus = false)
                .then(if (clock) Modifier.semantics { contentDescription = "${now.remaining}, ${now.endsAt}" } else Modifier),
        )
    }
    // Time runs left to right on a timeline in every language: the bar is drawn, hit-tested and keyed that way.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        if (stacked) {
            Column(modifier.fillMaxWidth()) {
                Scrub(Modifier.fillMaxWidth())
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    TimeLabel(now.position, style, PlezyColors.OnVideo, "player.position")
                    Remaining()
                }
            }
        } else {
            Row(modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                TimeLabel(now.position, style, PlezyColors.OnVideo, "player.position")
                Scrub(Modifier.weight(1f))
                Remaining()
            }
        }
    }
}

/** The timeline's times' style, with tabular figures: they don't shift as the digits change. */
@Composable
private fun timeStyle(): TextStyle =
    (if (rememberPlayerMetrics().tv) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelLarge).copy(fontFeatureSettings = "tnum")

@Composable
private fun TimeLabel(text: String, style: TextStyle, color: Color, probe: String) {
    Text(text, style = style, color = color, maxLines = 1, modifier = Modifier.layoutProbe(probe, reportsFocus = false))
}

/**
 * A live window's go-to-live button ([onGoToLive]): `● LIVE`, a red dot ([PlezyColors.Live]) then the live text
 * ([TimelineState.liveLabel]) in the timeline's time style, read as "Go to live" and [TimelineState.positionLabel], as
 * [timeline] has them now; a pill focused and pressed as every control is. Behind the live edge the dot is the text's
 * colour muted and the label has the time behind (`● LIVE · −0:40`). Harness name `player.live`.
 */
@Composable
private fun LiveLabel(timeline: StateFlow<TimelineState>, modifier: Modifier = Modifier, onGoToLive: () -> Unit) {
    val now by timeline.collectAsState()
    val metrics = rememberPlayerMetrics()
    PlezySurface(
        onClick = onGoToLive,
        modifier = modifier
            .height(metrics.button)
            .layoutProbe("player.live")
            .clearAndSetSemantics {
                contentDescription = "${T.liveTv.goToLive}${T.detail.listSeparator}${now.positionLabel}"
                role = Role.Button
                onClick { onGoToLive(); true }
            },
        shape = CircleShape,
        color = Color.Transparent,
        contentColor = PlezyColors.OnVideo,
        contentAlignment = Alignment.Center,
    ) {
        Row(Modifier.padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            val text = LocalContentColor.current
            Box(Modifier.size(10.dp).background(if (now.atLiveEdge) PlezyColors.Live else text.copy(alpha = 0.6f), CircleShape))
            Text(now.liveLabel, style = timeStyle(), color = text, maxLines = 1)
        }
    }
}

@Composable
private fun MenuButton(
    icon: ImageVector,
    label: String,
    menu: PlayerMenu,
    open: PlayerMenu?,
    buttons: MenuButtons,
    onCommand: (PlayerCommand) -> Unit,
    probe: String,
    adjusted: Boolean = false,
) {
    // A menu's pages belong to the button that opened it: the delays and the subtitle pages to the track menus, the
    // settings' pages to the settings.
    val owns = open?.parent == menu
    PlayerButton(
        icon,
        label,
        onClick = { onCommand(if (owns) PlayerCommand.CloseMenu else PlayerCommand.OpenMenu(menu)) },
        modifier = buttons.place(menu),
        probe = probe,
        selected = owns,
        adjusted = adjusted,
        focusRequester = buttons.focus(menu),
        tooltip = label,
    )
}

/** The volume's step for the keys: 5 %. */
private const val VOLUME_STEP = 5f

/**
 * Desktop's volume: mute (the speaker, crossed out while muted) and a slider from 0 to the volume's top
 * ([VolumeState.maxPercent]), marked at 100 % when the top is above it. With the keyboard focus rests on mute: Enter
 * there starts adjusting, Left and Right then move the volume 5 % a press (each press from the last one's value, before
 * the store has answered the one before), and Enter, Up, Down or focus leaving stops; a click mutes and unmutes. A drag
 * on the slider sets the volume as it goes. The wheel over it goes to the player as anywhere over the controls
 * (PlayerOverlays). Harness names: `player.mute`, `player.volume`.
 */
@Composable
internal fun VolumeControl(volume: VolumeState, onCommand: (PlayerCommand) -> Unit) {
    var adjusting by remember { mutableStateOf(false) }
    // The level the last change asked for, until the store answers with a new one.
    var pending by remember(volume.percent, volume.muted) { mutableFloatStateOf(if (volume.muted) 0f else volume.percent.toFloat()) }
    val top = volume.maxPercent.toFloat()
    fun set(percent: Float) {
        pending = percent.coerceIn(0f, top)
        onCommand(PlayerCommand.SetVolume(pending.toDouble()))
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        PlayerButton(
            if (volume.muted) PlezyIcons.VolumeOff else PlezyIcons.VolumeUp,
            if (adjusting) T.videoControls.volumeSlider else if (volume.muted) T.videoControls.unmuteButton else T.videoControls.muteButton,
            onClick = { onCommand(PlayerCommand.ToggleMute) },
            probe = "player.mute",
            value = if (adjusting) volume.label else null,
            selected = adjusting,
            modifier = Modifier
                .onFocusChanged { if (!it.isFocused) adjusting = false }
                .onPreviewKeyEvent { event ->
                    val select = event.key == Key.Enter || event.key == Key.NumPadEnter || event.key == Key.DirectionCenter
                    if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent select || adjusting && (event.key == Key.DirectionLeft || event.key == Key.DirectionRight)
                    when {
                        select -> {
                            adjusting = !adjusting
                            true
                        }
                        !adjusting -> false
                        event.key == Key.DirectionLeft -> {
                            set(pending - VOLUME_STEP)
                            true
                        }
                        event.key == Key.DirectionRight -> {
                            set(pending + VOLUME_STEP)
                            true
                        }
                        event.key == Key.DirectionUp || event.key == Key.DirectionDown -> {
                            adjusting = false
                            false
                        }
                        else -> false
                    }
                },
        )
        VolumeSlider(
            value = pending / top,
            mark = if (top > 100f) 100f / top else null,
            active = adjusting,
            onValueChange = { set(it * top) },
            modifier = Modifier
                .width(96.dp)
                .layoutProbe("player.volume", reportsFocus = false)
                .semantics {
                    contentDescription = T.videoControls.volumeSlider
                    stateDescription = volume.label
                },
        )
    }
}

/**
 * The volume, drawn as the timeline is: a thin track filled up to the value and a small round thumb; [mark], where the
 * slider goes past 100 %, a short bar across the track at 100 % (a fraction of the track). A press sets the level where
 * it lands and a drag moves it, each step going out at once ([onValueChange]); under the pointer, a drag or while the
 * keys adjust it ([active]) the thumb and the track grow a step. Screen readers set it as a progress. The keys reach it
 * through mute ([VolumeControl]), so it takes no focus itself.
 */
@Composable
private fun VolumeSlider(value: Float, mark: Float?, active: Boolean, onValueChange: (Float) -> Unit, modifier: Modifier = Modifier) {
    val interaction = remember { MutableInteractionSource() }
    val hovered by interaction.collectIsHoveredAsState()
    var dragging by remember { mutableStateOf(false) }
    val grown = hovered || dragging || active
    val change by rememberUpdatedState(onValueChange)
    val fraction = value.coerceIn(0f, 1f)
    val reach = VolumeThumbMax / 2
    val ltr = LocalLayoutDirection.current == LayoutDirection.Ltr
    BoxWithConstraints(
        modifier
            .height(VolumeThumbMax)
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(fraction, 0f..1f)
                setProgress { change(it.coerceIn(0f, 1f)); true }
            }
            .hoverable(interaction)
            .pointerInput(ltr) {
                // The track starts and ends [reach] inside the slider: the thumb's middle reaches each end.
                val past = reach.toPx()
                fun at(x: Float): Float {
                    val track = size.width - 2 * past
                    val along = if (track > 0) ((x - past) / track).coerceIn(0f, 1f) else 0f
                    return if (ltr) along else 1f - along
                }
                awaitEachGesture {
                    val down = awaitFirstDown()
                    down.consume()
                    dragging = true
                    change(at(down.position.x))
                    try {
                        while (true) {
                            val event = awaitPointerEvent()
                            val pointer = event.changes.firstOrNull { it.id == down.id } ?: break
                            if (!pointer.pressed) {
                                pointer.consume()
                                break
                            }
                            if (pointer.positionChanged()) {
                                pointer.consume()
                                change(at(pointer.position.x))
                            }
                        }
                    } finally {
                        dragging = false
                    }
                }
            }
            .padding(horizontal = reach),
        contentAlignment = Alignment.CenterStart,
    ) {
        Canvas(Modifier.fillMaxWidth().height(VolumeThumb)) {
            val track = (if (grown) 6.dp else 4.dp).toPx()
            val top = (size.height - track) / 2
            val radius = CornerRadius(track / 2)
            val filled = size.width * fraction
            // The fill grows from the slider's start, as the thumb moves: the right in a right-to-left layout.
            val rtl = layoutDirection == LayoutDirection.Rtl
            val start = if (rtl) size.width - filled else 0f
            drawRoundRect(PlezyColors.ProgressTrack, topLeft = Offset(0f, top), size = Size(size.width, track), cornerRadius = radius)
            drawRoundRect(PlezyColors.OnVideo, topLeft = Offset(start, top), size = Size(filled, track), cornerRadius = radius)
            // The 100 % mark stands out above and below the track.
            if (mark != null) {
                val width = VolumeMarkWidth.toPx()
                val x = size.width * (if (rtl) 1f - mark else mark) - width / 2
                drawRoundRect(PlezyColors.OnVideoMuted, topLeft = Offset(x, 0f), size = Size(width, size.height), cornerRadius = CornerRadius(width / 2))
            }
        }
        val thumb = if (grown) VolumeThumbMax else VolumeThumb
        Box(
            Modifier
                .graphicsLayer {
                    val centre = maxWidth.toPx() * (if (ltr) fraction else 1f - fraction)
                    translationX = centre - (thumb / 2).toPx()
                }
                .size(thumb)
                .background(PlezyColors.OnVideo, CircleShape),
        )
    }
}

/** The volume thumb's diameter at rest (and the 100 % mark's height), and under the pointer, a drag or the keys. */
private val VolumeThumb = 12.dp
private val VolumeThumbMax = 16.dp
private val VolumeMarkWidth = 2.dp

/** How far a screen reader's increase or decrease on the timeline seeks. */
private const val ACCESSIBLE_SEEK_SECONDS = 10.0

/**
 * The timeline: played, buffered and chapter marks (gaps at the chapters' starts); while scrubbing
 * ([TimelineState.scrub]) a bubble above the preview's position with its frame where there is one, its time and offset
 * and its chapter; so does a mouse resting over a video's bar ([TimelineState.hover]), the store told where at each
 * 4 dp it moves ([PlayerCommand.HoverTimeline]). Drag or click to scrub (committed on release), on the bar or anywhere
 * on its thumb: at the bar's ends (its start, a live window's edge) half the thumb lies past the bar, so the pointer
 * area reaches half the largest thumb past each end. Focusable while [seekable], so the keys can scrub while it has
 * focus; focus (while focus shows) thickens the bar and haloes the thumb. While the video plays the played part and the
 * thumb move on at each frame between the store's reports ([TimelineState.progressNow]); only drawing and placing them
 * read it, so nothing is composed again for it.
 */
@Composable
private fun ScrubBar(
    timeline: TimelineState,
    height: Dp,
    seekable: Boolean,
    live: Boolean,
    onCommand: (PlayerCommand) -> Unit,
    onFocusChanged: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val interaction = remember { MutableInteractionSource() }
    val seekableNow by rememberUpdatedState(seekable)
    val hovered by interaction.collectIsHoveredAsState()
    val focusedRaw by interaction.collectIsFocusedAsState()
    val focused = focusedRaw && isFocusVisible()
    val scrub = timeline.scrub
    val progress = scrub?.progress ?: timeline.progress
    val motion = timeline.motion
    val frame = remember { mutableLongStateOf(0L) }
    LaunchedEffect(motion) {
        if (motion != null) while (true) withFrameNanos { frame.longValue = it }
    }

    /** The played fraction for the frame being drawn. */
    fun played(): Float {
        frame.longValue
        return (scrub?.progress ?: timeline.progressNow()).coerceIn(0f, 1f)
    }
    val active = scrub != null || hovered || focused
    val reach = ScrubThumbFocused / 2
    BoxWithConstraints(
        modifier
            .height(height)
            .semantics {
                contentDescription = T.player.timeline
                progressBarRangeInfo = ProgressBarRangeInfo(progress, 0f..1f)
                stateDescription = timeline.positionLabel
                // A screen reader's increase or decrease (a live window's too): ten seconds on or back, one whole seek.
                if (seekable) {
                    setProgress { fraction ->
                        if (fraction != progress) onCommand(PlayerCommand.SeekBy(if (fraction > progress) ACCESSIBLE_SEEK_SECONDS else -ACCESSIBLE_SEEK_SECONDS))
                        true
                    }
                }
            }
            .onFocusChanged { onFocusChanged(it.isFocused) }
            .focusable(enabled = seekable, interactionSource = interaction)
            .beyond(WindowInsets(left = reach, right = reach))
            .hoverable(interaction)
            .pointerInput(seekable) {
                if (!seekable) return@pointerInput
                // The bar starts and ends [reach] inside the pointer area.
                val past = reach.roundToPx()
                val bar = size.width - 2 * past
                fun fraction(x: Float) = if (bar > 0) ((x - past) / bar).coerceIn(0f, 1f).toDouble() else 0.0
                awaitEachGesture {
                    val down = awaitFirstDown()
                    down.consume()
                    onCommand(PlayerCommand.ScrubTo(fraction(down.position.x)))
                    var ended = false
                    try {
                        while (true) {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull { it.id == down.id }
                            if (change == null) break
                            if (!change.pressed) {
                                change.consume()
                                ended = true
                                onCommand(PlayerCommand.CommitScrub)
                                break
                            }
                            if (change.positionChanged()) {
                                change.consume()
                                onCommand(PlayerCommand.ScrubTo(fraction(change.position.x)))
                            }
                        }
                    } finally {
                        // Not released on the bar: the timeline stopped seeking mid-drag, which commits the preview
                        // (the store refuses it where seeking went), or the pointer went or the bar did (picture in
                        // picture), which drops it.
                        if (!ended) onCommand(if (seekableNow) PlayerCommand.CancelScrub else PlayerCommand.CommitScrub)
                    }
                }
            }
            .pointerInput(seekable, live) {
                if (!seekable || live) return@pointerInput
                val past = reach.roundToPx()
                val step = HoverStep.roundToPx().coerceAtLeast(1)
                // The 4 dp step the mouse is over, -1 off the bar (or pressing it: a scrub).
                var at = -1
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent()
                        val change = event.changes.firstOrNull() ?: continue
                        if (change.type != PointerType.Mouse) continue
                        val next = if (event.type == PointerEventType.Exit || change.pressed) -1 else change.position.x.roundToInt() / step
                        if (next == at) continue
                        at = next
                        val bar = size.width - 2 * past
                        val fraction = if (next < 0 || bar <= 0) null else ((next * step + step / 2f - past) / bar).coerceIn(0f, 1f).toDouble()
                        onCommand(PlayerCommand.HoverTimeline(fraction))
                    }
                }
            }
            .padding(horizontal = reach),
        contentAlignment = Alignment.CenterStart,
    ) {
        val barHeight = when {
            focused -> 8.dp
            active -> 6.dp
            else -> 4.dp
        }
        val chapters = timeline.chapters
        Canvas(Modifier.fillMaxWidth().height(barHeight)) {
            val radius = CornerRadius(size.height / 2)
            drawRoundRect(PlezyColors.ProgressTrack, cornerRadius = radius)
            drawRoundRect(PlezyColors.ProgressTrack, size = Size(size.width * timeline.buffered.coerceIn(0f, 1f), size.height), cornerRadius = radius)
            drawRoundRect(PlezyColors.OnVideo, size = Size(size.width * played(), size.height), cornerRadius = radius)
            // Chapter starts as gaps in the bar.
            val gap = 2.dp.toPx()
            for (mark in chapters) {
                if (mark <= 0f || mark >= 1f) continue
                drawRect(Color.Black.copy(alpha = 0.7f), topLeft = Offset(size.width * mark - gap / 2, 0f), size = Size(gap, size.height))
            }
        }
        val thumb = when {
            focused -> ScrubThumbFocused
            active -> ScrubThumbActive
            else -> ScrubThumb
        }
        // Focus (scrubbing with the keys) haloes the thumb, hugging it.
        if (focused) {
            val halo = thumb + 12.dp
            Box(Modifier.graphicsLayer { translationX = maxWidth.toPx() * played() - (halo / 2).toPx() }.size(halo).background(PlezyColors.OnVideo.copy(alpha = 0.24f), CircleShape))
        }
        Box(Modifier.graphicsLayer { translationX = maxWidth.toPx() * played() - (thumb / 2).toPx() }.size(thumb).background(PlezyColors.OnVideo, CircleShape))
        (scrub ?: timeline.hover)?.let { tip -> ScrubBubble(tip, anchorX = maxWidth * tip.progress.coerceIn(0f, 1f), maxWidth = maxWidth) }
    }
    // A bar that goes (the controls hiding) takes its hover with it.
    val hovering by rememberUpdatedState(timeline.hover != null)
    DisposableEffect(Unit) {
        onDispose { if (hovering) onCommand(PlayerCommand.HoverTimeline(null)) }
    }
}

/** The step a mouse moves over the timeline in before the store hears of it. */
private val HoverStep = 4.dp

/** The timeline's thumb's diameter at rest, under the pointer or scrubbing, and with focus (scrubbing with the keys). */
private val ScrubThumb = 12.dp
private val ScrubThumbActive = 16.dp
private val ScrubThumbFocused = 20.dp

/**
 * The scrub's bubble, centred over the preview and kept inside the bar, above it: the preview's frame where there is one
 * ([ScrubState.frame], [ScrubFrameWidth] wide, as tall as its shape makes it), then its time and offset, and the
 * chapter's name where it has one. It takes its own height, not the bar's, so the frame keeps its shape. Harness names
 * `player.scrubTooltip`, its frame `player.scrubFrame`.
 */
@Composable
private fun ScrubBubble(scrub: ScrubState, anchorX: Dp, maxWidth: Dp) {
    var bubble by remember { mutableStateOf(IntSize.Zero) }
    val frame = scrub.frame
    Surface(
        shape = MaterialTheme.shapes.small,
        color = PlezyColors.SurfaceHigh,
        contentColor = PlezyColors.OnVideo,
        modifier = Modifier
            .wrapContentHeight(unbounded = true)
            // Centred over the preview, kept inside the bar, above it.
            .offset {
                val left = (anchorX.roundToPx() - bubble.width / 2).coerceIn(0, (maxWidth.roundToPx() - bubble.width).coerceAtLeast(0))
                IntOffset(left, -(bubble.height / 2 + 24.dp.roundToPx()))
            }
            .layoutProbe("player.scrubTooltip", reportsFocus = false)
            .onSizeChanged { bubble = it }
            .widthIn(max = 280.dp),
    ) {
        Column(Modifier.padding(horizontal = if (frame == null) 12.dp else 6.dp, vertical = 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            if (frame != null) {
                ScrubFrameImage(frame)
                Spacer(Modifier.height(4.dp))
            }
            Text(if (scrub.offset.isEmpty()) scrub.position else "${scrub.position}  ${scrub.offset}", style = MaterialTheme.typography.labelLarge.copy(fontFeatureSettings = "tnum"), maxLines = 1)
            scrub.chapter?.let { Text(it, style = MaterialTheme.typography.labelMedium.contentDirection(), maxLines = 1, overflow = TextOverflow.Ellipsis) }
        }
    }
}

/** The scrub bubble's frame's width. */
private val ScrubFrameWidth = 160.dp

/** A scrub frame at [ScrubFrameWidth]: its encoded image, or its tile cut out of the sprite sheet. */
@Composable
private fun ScrubFrameImage(frame: ScrubFrame) {
    val height = ScrubFrameWidth / frame.aspectRatio.toFloat().coerceAtLeast(0.1f)
    val box = Modifier.layoutProbe("player.scrubFrame", reportsFocus = false).size(ScrubFrameWidth, height).clip(MaterialTheme.shapes.extraSmall)
    when (frame) {
        is ScrubFrame.Bytes -> AsyncImage(frame.bytes, contentDescription = null, box, contentScale = ContentScale.Crop)
        is ScrubFrame.SheetTile -> Box(box.clipToBounds()) {
            AsyncImage(
                frame.sheetUrl,
                contentDescription = null,
                Modifier
                    .wrapContentSize(Alignment.TopStart, unbounded = true)
                    .requiredSize(ScrubFrameWidth * frame.sheetColumns, height * frame.sheetRows)
                    .offset(x = -ScrubFrameWidth * frame.tileColumn, y = -height * frame.tileRow),
                contentScale = ContentScale.FillBounds,
            )
        }
    }
}

/**
 * A round player button: icon only, [label] for accessibility (and [value] after it, [checked] for a toggle).
 * Transparent over the video, a translucent tint hovered or pressed ([PlezySurface]); [large] for Play/Pause;
 * [selected] fills it (its menu is open, a toggle is on), [filled] gives it the tonal fill of a button on a panel; with
 * [adjusted] a dot at its corner says a setting behind it is away from its default. Focus fills it with the primary
 * colour (and grows it on TV), as every control does. Not [enabled] it takes no focus or press; not [available] it keeps
 * its place and focus, dimmed, and a press does nothing. With a [tooltip] a pointer resting on it shows that text over
 * it while the text isn't empty. On a touch screen it takes taps in a finger's least target around it. [size] and
 * [iconSize] override the metrics' sizes and [background] fills it at rest (the centred transport's).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun PlayerButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    probe: String? = null,
    large: Boolean = false,
    selected: Boolean = false,
    filled: Boolean = false,
    enabled: Boolean = true,
    available: Boolean = true,
    adjusted: Boolean = false,
    checked: Boolean? = null,
    value: String? = null,
    focusRequester: FocusRequester? = null,
    tooltip: String? = null,
    size: Dp = Dp.Unspecified,
    iconSize: Dp = Dp.Unspecified,
    background: Color = Color.Transparent,
) {
    if (tooltip != null && LocalWindowLayout.current.formFactor != FormFactor.TV) {
        TooltipBox(
            TooltipDefaults.rememberPlainTooltipPositionProvider(),
            { PlainTooltip { Text(tooltip) } },
            rememberTooltipState(),
            focusable = false,
            enableUserInput = tooltip.isNotEmpty(),
        ) {
            PlayerButton(icon, label, onClick, modifier, probe, large, selected, filled, enabled, available, adjusted, checked, value, focusRequester, size = size, iconSize = iconSize, background = background)
        }
        return
    }
    val metrics = rememberPlayerMetrics()
    PlezySurface(
        onClick = { if (available) onClick() },
        modifier = modifier
            .size(if (size.isSpecified) size else if (large) metrics.playButton else metrics.button)
            .then(if (probe != null) Modifier.layoutProbe(probe) else Modifier)
            .then(if (focusRequester != null) Modifier.focusRequester(focusRequester) else Modifier)
            .semantics {
                (value ?: checked?.let { if (it) T.player.options.on else T.player.options.off })?.let { stateDescription = it }
                if (!available) disabled()
            },
        shape = CircleShape,
        color = when {
            selected -> PlezyColors.SurfaceHighest
            filled -> PlezyColors.SurfaceHigh
            else -> background
        },
        contentColor = PlezyColors.OnVideo,
        enabled = enabled,
        role = Role.Button,
        selected = selected,
        contentAlignment = Alignment.Center,
        hitTarget = true,
    ) {
        val content = LocalContentColor.current
        Icon(
            icon,
            contentDescription = label,
            Modifier.size(if (iconSize.isSpecified) iconSize else if (large) metrics.playIcon else metrics.icon),
            tint = if (available) content else content.copy(alpha = UnavailableAlpha),
        )
        if (adjusted) {
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(metrics.inset / 2)
                    .size(6.dp)
                    .background(content, CircleShape)
                    .then(if (probe != null) Modifier.layoutProbe("$probe.adjusted", reportsFocus = false) else Modifier),
            )
        }
    }
}

/** An unavailable control's icon: dimmed, in its place. */
private const val UnavailableAlpha = 0.38f

/**
 * The loading spinner with the store's text ("Preparing stream…", "Buffering…") on black, darker over an HDR picture
 * ([hdr], [ControlsScrim]).
 */
@Composable
internal fun LoadingOverlay(text: String?, hdr: Boolean, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        PlayerLoadingIndicator()
        if (text != null) {
            Surface(shape = CircleShape, color = Color.Black.copy(alpha = ControlsScrim.alpha(0.6f, hdr)), contentColor = PlezyColors.OnVideo) {
                Text(text, Modifier.padding(horizontal = 14.dp, vertical = 6.dp), style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}
