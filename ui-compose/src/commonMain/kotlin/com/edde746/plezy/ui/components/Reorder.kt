package com.edde746.plezy.ui.components

import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerIcon
import androidx.compose.ui.input.pointer.pointerHoverIcon
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.zIndex
import kotlin.math.abs

/**
 * Dragging items of a list to a new place (desktop mouse, touch): the dragged item follows the pointer, the items it
 * passes make room, and dropping reports the item's key and its new index. Keyboard and D-pad users move items with
 * the rows' up and down buttons (or move mode) instead.
 */
@Stable
internal class ReorderState(private val spacingPx: Float) {
    /** The key of the item being dragged, or null. */
    var dragging: String? by mutableStateOf(null)
        private set

    private var offset by mutableFloatStateOf(0f)
    private var from = -1
    private var count = 0

    // Each item's height by its place in the list, as last measured there.
    private val heights = HashMap<Int, Int>()

    /** How far each item the dragged one passes moves to make room: the dragged item's height and the spacing. */
    private val step: Float get() = if (dragging == null) 0f else (heights[from] ?: 0) + spacingPx

    /**
     * Where the dragged item drops: past each item, one after the other, once the drag has gone half of that item's own
     * height (with the spacing) beyond the items before it, so it drops where it is drawn among rows of any height.
     */
    private val target: Int
        get() {
            val direction = if (offset > 0f) 1 else -1
            var left = abs(offset)
            var to = from
            while (to + direction in 0 until count) {
                val passed = (heights[to + direction] ?: break) + spacingPx
                if (left < passed / 2) break
                left -= passed
                to += direction
            }
            return to
        }

    internal fun measured(index: Int, height: Int) {
        heights[index] = height
    }

    internal fun start(key: String, index: Int, count: Int) {
        dragging = key
        from = index
        this.count = count
        offset = 0f
    }

    internal fun drag(dy: Float) {
        offset += dy
    }

    internal fun end(onMove: (key: String, toIndex: Int) -> Unit) {
        val key = dragging ?: return
        val to = target
        val moved = to != from
        cancel()
        if (moved) onMove(key, to)
    }

    internal fun cancel() {
        dragging = null
        offset = 0f
        from = -1
    }

    /** How far the item [key] at [index] is drawn from its place while an item is dragged. */
    internal fun shift(key: String, index: Int): Float {
        val dragged = dragging ?: return 0f
        if (key == dragged) return offset
        val to = target
        return when {
            index in (from + 1)..to -> -step
            index in to until from -> step
            else -> 0f
        }
    }
}

/** A [ReorderState] for a list whose items are [spacing] apart. */
@Composable
internal fun rememberReorderState(spacing: Dp): ReorderState {
    val px = with(LocalDensity.current) { spacing.toPx() }
    return remember(px) { ReorderState(px) }
}

/**
 * An item of a reorderable list: measured (again at each new [index]), drawn where the drag puts it, and above the
 * others while dragged.
 */
internal fun Modifier.reorderItem(state: ReorderState, key: String, index: Int): Modifier =
    layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        state.measured(index, placeable.height)
        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
    }
        .zIndex(if (state.dragging == key) 1f else 0f)
        .graphicsLayer { translationY = state.shift(key, index) }

/**
 * Dragging the item [key] at [index] of [count] by this element; dropping calls [onMove] with its new index. Presses
 * that never move stay the element's own (a button's click).
 */
internal fun Modifier.reorderDrag(state: ReorderState, key: String, index: Int, count: Int, onMove: (key: String, toIndex: Int) -> Unit): Modifier =
    pointerInput(state, key, index, count) {
        detectDragGestures(
            onDragStart = { state.start(key, index, count) },
            onDragEnd = { state.end(onMove) },
            onDragCancel = { state.cancel() },
            onDrag = { change, amount ->
                change.consume()
                state.drag(amount.y)
            },
        )
    }

/**
 * The drag handle of the item [key] at [index] of [count] ([reorderDrag]). A press on the handle is the drag's alone:
 * the row around it never takes it as a click, whether or not the pointer then moves.
 */
internal fun Modifier.reorderHandle(state: ReorderState, key: String, index: Int, count: Int, onMove: (key: String, toIndex: Int) -> Unit): Modifier =
    pointerHoverIcon(PointerIcon.Hand)
        // After the drag below has seen each change (the main pass reaches the handle's inner modifier first), so the
        // row's click, an ancestor, finds the press and its release taken.
        .pointerInput(Unit) {
            awaitPointerEventScope {
                while (true) awaitPointerEvent().changes.forEach { if (it.pressed || it.previousPressed) it.consume() }
            }
        }
        .reorderDrag(state, key, index, count, onMove)
