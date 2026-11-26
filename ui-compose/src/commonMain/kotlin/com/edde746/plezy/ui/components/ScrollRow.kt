package com.edde746.plezy.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.FlingBehavior
import androidx.compose.foundation.gestures.ScrollableDefaults
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.MutatePriority
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.isPrimaryPressed
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.min
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.focus.desktopApp
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.rememberNavigationClearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import kotlin.math.abs
import kotlin.math.exp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch

/**
 * Every horizontally scrolling row of the app (a shelf's cards, the season chips, a row of chips): a [LazyRow] that a
 * touch screen and a trackpad scroll, and a remote or the keyboard as focus moves along it.
 *
 * On the desktop (Windows, Linux; not in its TV layout) a mouse scrolls it too:
 * - Its edges fade where more of the row lies beyond them ([edgeFades]), more the further it goes, up to [FadeWidth];
 *   an edge where the row ends doesn't fade. The start edge is the rail's end where the row reaches under it.
 * - While the pointer is over it, round ‹ and › buttons at its ends ([PageButton]) scroll it by [PAGE] of its width;
 *   each shows only while the row can scroll its way.
 * - A press of the left button that moves past the touch slop drags it, flung on release ([dragToScroll]): the card
 *   under the press doesn't open; a press that doesn't move is a click.
 * - The wheel over it scrolls it sideways, vertical turns too, smoothly ([wheelToScroll]), and only while it can move
 *   that way: at its end the wheel scrolls the page. A wheel already scrolling the page goes on doing so as the row comes
 *   under the pointer (a row takes the wheel once it has rested over it [LATCH_MS], or it took the last turn), so rows
 *   scrolling past don't catch the page's scroll.
 * Elsewhere it is a plain [LazyRow].
 *
 * [modifier] is the row's own (its focus handling, harness name), as [LazyRow]'s.
 */
@Composable
fun ScrollRow(
    modifier: Modifier = Modifier,
    state: LazyListState = rememberLazyListState(),
    contentPadding: PaddingValues = PaddingValues(0.dp),
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalAlignment: Alignment.Vertical = Alignment.Top,
    content: LazyListScope.() -> Unit,
) {
    if (!pointerRows()) {
        LazyRow(modifier, state, contentPadding, horizontalArrangement = horizontalArrangement, verticalAlignment = verticalAlignment, content = content)
        return
    }
    val scope = rememberCoroutineScope()
    val fling = ScrollableDefaults.flingBehavior()
    val wheel = remember(state, scope) { WheelScroll(state, scope) }
    var hovered by remember { mutableStateOf(false) }
    var height by remember { mutableIntStateOf(0) }
    // Where the row reaches under the rail, its visible start is the rail's end.
    val (placed, hidden) = rememberNavigationClearance(0.dp, 0.dp)
    val density = LocalDensity.current
    // The list's scroll runs towards its end: left in a left-to-right row, right in a right-to-left one.
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    Box(
        placed
            .onSizeChanged { height = it.height }
            .pointerInput(state, fling, rtl) { dragToScroll(state, fling, scope, if (rtl) 1f else -1f) }
            .pointerInput(state) { wheelToScroll(state, wheel) { hovered = it } },
    ) {
        LazyRow(
            Modifier.edgeFades(state, hidden).then(modifier),
            state,
            contentPadding,
            horizontalArrangement = horizontalArrangement,
            verticalAlignment = verticalAlignment,
            content = content,
        )
        val size = min(LocalPlezyDimens.current.iconButtonSize, with(density) { height.toDp() })
        val page = { with(density) { PAGE * (state.layoutInfo.viewportSize.width - hidden.toPx()) } }
        PageButton(hovered && state.canScrollBackward, back = true, size, Modifier.align(Alignment.CenterStart).padding(start = hidden + ButtonInset)) {
            scope.launch { state.animateScrollBy(-page()) }
        }
        PageButton(hovered && state.canScrollForward, back = false, size, Modifier.align(Alignment.CenterEnd).padding(end = ButtonInset)) {
            scope.launch { state.animateScrollBy(page()) }
        }
    }
}

/**
 * One of [ScrollRow]'s buttons, ‹ ([back]) or ›, a dark circle over the cards as over a picture, fading in and out with
 * [shown]. Only the pointer uses it: focus passes it by, the row's own focus moves doing its job.
 */
@Composable
private fun PageButton(shown: Boolean, back: Boolean, size: Dp, modifier: Modifier, onClick: () -> Unit) {
    AnimatedVisibility(shown, modifier, enter = fadeIn(tween(FADE_MS)), exit = fadeOut(tween(FADE_MS))) {
        PlezyIconButton(
            if (back) PlezyIcons.ChevronLeft else PlezyIcons.ChevronRight,
            if (back) T.accessibility.scrollBack else T.accessibility.scrollForward,
            onClick,
            Modifier.focusProperties { canFocus = false },
            style = IconButtonStyle.OVER_PICTURE,
            size = size,
        )
    }
}

/**
 * Fades the row's start edge (from [hidden] in, where the rail covers it) and its end edge over [FadeWidth], each as far
 * as the row has content beyond it within that width: none at a row's true end, a full fade once a card lies past it.
 */
private fun Modifier.edgeFades(state: LazyListState, hidden: Dp): Modifier = drawWithContent {
    val width = FadeWidth.toPx()
    val back = (state.backwardRoom() / width).coerceIn(0f, 1f)
    val forward = (state.forwardRoom() / width).coerceIn(0f, 1f)
    if (back == 0f && forward == 0f) {
        drawContent()
        return@drawWithContent
    }
    // Above and below the row, room for what reaches past it (a focused card's ring), as the row's own clip leaves.
    val room = FadeOverflow.toPx()
    val top = -room
    val bottom = size.height + room
    drawIntoCanvas { canvas ->
        canvas.saveLayer(Rect(0f, top, size.width, bottom), Paint())
        drawContent()
        val rtl = layoutDirection == LayoutDirection.Rtl
        val start = if (rtl) size.width - hidden.toPx() else hidden.toPx()
        val end = if (rtl) 0f else size.width
        val inward = if (rtl) -width else width
        fade(start, start + inward, if (rtl) size.width else 0f, back, top, bottom)
        fade(end, end - inward, end, forward, top, bottom)
        canvas.restore()
    }
}

/**
 * Masks the layer from [edge] (at 1 - [strength] opacity, as is everything from [outer] to it) to [inner] (whole).
 */
private fun DrawScope.fade(edge: Float, inner: Float, outer: Float, strength: Float, top: Float, bottom: Float) {
    if (strength == 0f) return
    val left = minOf(outer, inner)
    val right = maxOf(outer, inner)
    drawRect(
        Brush.horizontalGradient(0f to Color.Black.copy(alpha = 1f - strength), 1f to Color.Black, startX = edge, endX = inner),
        topLeft = Offset(left, top),
        size = Size(right - left, bottom - top),
        blendMode = BlendMode.DstIn,
    )
}

/** How far the row's content reaches before its start edge: a card's width or more once the first is gone. */
private fun LazyListState.backwardRoom(): Float = if (firstVisibleItemIndex > 0) Float.MAX_VALUE else firstVisibleItemScrollOffset.toFloat()

/** How far the row's content reaches past its end edge: a card's width or more while the last isn't in view. */
private fun LazyListState.forwardRoom(): Float {
    val info = layoutInfo
    val last = info.visibleItemsInfo.lastOrNull() ?: return 0f
    if (last.index < info.totalItemsCount - 1) return Float.MAX_VALUE
    return (last.offset + last.size + info.afterContentPadding - info.viewportEndOffset).toFloat()
}

/**
 * Drags the row with the mouse's left button as a finger drags it: once the press has moved past the touch slop the
 * moves are the row's (consumed, so the card under the press takes no click), and the release flings it with the
 * pointer's speed. A press that stays within the slop is left to the card. Touch and pen drag the row themselves.
 * [sign]: the scroll's sign for a move to the right.
 */
private suspend fun PointerInputScope.dragToScroll(state: LazyListState, fling: FlingBehavior, scope: CoroutineScope, sign: Float) = awaitEachGesture {
    val down = awaitFirstDown(requireUnconsumed = false)
    if (down.type != PointerType.Mouse || !currentEvent.buttons.isPrimaryPressed) return@awaitEachGesture
    val tracker = VelocityTracker()
    tracker.addPosition(down.uptimeMillis, down.position)
    var deltas: Channel<Float>? = null
    var velocity = 0f
    try {
        while (true) {
            val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id } ?: break
            if (!change.pressed) {
                if (deltas != null) {
                    change.consume()
                    velocity = sign * tracker.calculateVelocity().x
                }
                break
            }
            tracker.addPosition(change.uptimeMillis, change.position)
            if (deltas == null) {
                if (abs(change.position.x - down.position.x) <= viewConfiguration.touchSlop) continue
                val drag = Channel<Float>(Channel.UNLIMITED)
                deltas = drag
                scope.launch {
                    state.scroll(MutatePriority.UserInput) {
                        for (delta in drag) scrollBy(delta)
                        with(fling) { performFling(velocity) }
                    }
                }
            }
            change.consume()
            deltas.trySend(sign * (change.position.x - change.previousPosition.x))
        }
    } finally {
        deltas?.close()
    }
}

/**
 * The pointer over the row ([hover] as it comes and goes) and the wheel turned over it: a vertical turn (with Shift too)
 * not taken by anything inside scrolls the row sideways while it can move that way, a turn down towards its end. The
 * row takes a turn while it took the last one ([LATCH_MS]), else once the pointer has rested over it and the wheel has
 * scrolled nothing else for [LATCH_MS]; a turn it leaves goes on to the page.
 */
private suspend fun PointerInputScope.wheelToScroll(state: LazyListState, wheel: WheelScroll, hover: (Boolean) -> Unit) = awaitPointerEventScope {
    var since = NEVER
    var taken = NEVER
    var passed = NEVER
    while (true) {
        val event = awaitPointerEvent()
        val change = event.changes.firstOrNull() ?: continue
        if (change.type != PointerType.Mouse) continue
        val now = change.uptimeMillis
        when (event.type) {
            PointerEventType.Exit -> {
                since = NEVER
                hover(false)
            }
            PointerEventType.Enter, PointerEventType.Move -> if (since == NEVER) {
                since = now
                hover(true)
            }
            PointerEventType.Scroll -> {
                if (since == NEVER) since = now
                val turn = change.scrollDelta.y
                when {
                    // The row's own scroll took it (a trackpad's sideways swipe).
                    change.isConsumed -> taken = now
                    turn == 0f -> passed = now
                    else -> {
                        val latched = now - taken < LATCH_MS
                        val rested = now - passed >= LATCH_MS && now - since >= LATCH_MS
                        val movable = if (turn > 0f) state.canScrollForward else state.canScrollBackward
                        if ((latched || rested) && movable) {
                            change.consume()
                            taken = now
                            wheel.add(turn * WHEEL_STEP * state.layoutInfo.viewportSize.width)
                        } else {
                            passed = now
                        }
                    }
                }
            }
        }
    }
}

/**
 * The wheel's scroll of a row, eased: each turn adds its distance to what is still to go, which the row covers frame by
 * frame, the bigger part first ([WHEEL_EASE_NANOS]), stopping at the row's end.
 */
private class WheelScroll(private val state: LazyListState, private val scope: CoroutineScope) {
    private var remaining = 0f
    private var job: Job? = null

    fun add(distance: Float) {
        remaining += distance
        if (job?.isActive == true) return
        job = scope.launch {
            try {
                state.scroll(MutatePriority.UserInput) {
                    var last = withFrameNanos { it }
                    while (remaining != 0f) {
                        val now = withFrameNanos { it }
                        // The last pixel whole: the turns add up to their distance exactly.
                        val step = if (abs(remaining) <= 1f) remaining else remaining * (1f - exp(-(now - last) / WHEEL_EASE_NANOS))
                        last = now
                        remaining -= step
                        if (abs(scrollBy(step)) < abs(step) - 0.5f) break
                    }
                }
            } finally {
                remaining = 0f
            }
        }
    }
}

/** How wide a [ScrollRow]'s edge fades. */
private val FadeWidth = 48.dp

/**
 * How wide [ScrollRow]'s edge fades are here: none where it draws none. A row scrolled to an item leaves this much of
 * the row before it, so the item shows whole, clear of the fade, with the end of the one before it in the fade.
 */
@Composable
internal fun scrollRowFade(): Dp = if (pointerRows()) FadeWidth else 0.dp

/** Whether a [ScrollRow] here is the mouse's: the desktop's, not in its TV layout. */
@Composable
private fun pointerRows(): Boolean = desktopApp && LocalWindowLayout.current.formFactor != FormFactor.TV

/** How far above and below a [ScrollRow] its fades' layer reaches. */
private val FadeOverflow = 32.dp

/** How far a [ScrollRow]'s buttons sit in from its edges. */
private val ButtonInset = 8.dp

/** How much of a [ScrollRow]'s width a button scrolls it. */
private const val PAGE = 0.8f

/**
 * How much of a [ScrollRow]'s width one turn of the wheel scrolls it: three twentieths, as Compose scrolls a list on
 * Windows.
 */
private const val WHEEL_STEP = 0.15f

/** How quickly a [ScrollRow] covers the wheel's distance: about two thirds of what is left every 50 ms. */
private const val WHEEL_EASE_NANOS = 50_000_000f

/** How long a [ScrollRow]'s hold on the wheel, or the page's, outlasts the last turn; and the rest that hands it over. */
private const val LATCH_MS = 300L

/** How long a [ScrollRow]'s buttons take to fade in and out. */
private const val FADE_MS = 200

private const val NEVER = Long.MIN_VALUE / 2
