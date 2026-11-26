package com.edde746.plezy.ui.components

import androidx.compose.animation.core.animate
import androidx.compose.animation.core.spring
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Rect
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.layout
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.requireLayoutCoordinates
import androidx.compose.ui.relocation.BringIntoViewModifierNode
import androidx.compose.ui.relocation.bringIntoView
import androidx.compose.foundation.gestures.ScrollScope
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sign
import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.node.DrawModifierNode
import androidx.compose.ui.node.LayoutAwareModifierNode
import kotlinx.coroutines.launch

/**
 * A TV grid's moves as focus goes from row to row, made in a layer. A move eases the layer's [offset] along the spring
 * the platform scrolls with, over rows already laid out past the grid's bounds, and once the layer is at rest scrolls
 * the grid there in one frame that shows nothing new (the layer goes back as the grid scrolls). The frames of the
 * motion move the layer alone: nothing is laid out, composed or drawn again in them. A move asked for while one is
 * under way (a held key) scrolls the grid to where it shows first. The scroll stays in progress until the grid is at
 * rest, as a scroll animation's would.
 */
internal class GridMotion(private val state: LazyGridState) {
    /** How far (px) the grid shows below where it lies: negative while the layer moves it up ahead of the scroll. */
    var offset by mutableFloatStateOf(0f)
        private set

    /** Asked for ([ask]) and not begun. */
    private var asked = 0f

    /** Begun and not scrolled: where the layer is taking the grid ([offset] goes to minus this). */
    private var target = 0f

    /** Moves not scrolled yet: a card rests where it lies less these. */
    val ahead: Float get() = asked + target

    private var velocity = 0f
    private var moves = 0

    /** Asks for the grid to move [distance] px more (content up for a positive one); the next [move] makes it. */
    fun ask(distance: Float) {
        asked += distance
    }

    /**
     * Moves the grid by what was asked for, the layer first, at most [reach] px ahead of the scroll (a longer move
     * scrolls the rest at once), then scrolls it there at rest. A move that comes before an earlier one has begun takes
     * its distance too.
     */
    suspend fun move(reach: Float) {
        val move = ++moves
        val speed = velocity
        var begun = false
        try {
            state.scroll {
                begun = true
                // A move under way: the grid scrolls to where it shows, and goes on from there.
                if (offset != 0f) settle()
                target = limit(target + asked)
                asked = 0f
                if (abs(target) > reach) {
                    val scrolled = scrollBy(target - reach * sign(target))
                    offset += scrolled
                    target -= scrolled
                }
                try {
                    animate(offset, -target, speed, MotionSpring) { value, v ->
                        offset = value
                        velocity = v
                    }
                    velocity = 0f
                    settle()
                } finally {
                    // Stopped by another scroll (a letter's jump): the grid shows where it lies. A move after this one
                    // goes on from where this one was.
                    if (move == moves) {
                        offset = 0f
                        target = 0f
                        velocity = 0f
                    }
                }
            }
        } finally {
            // Stopped by another scroll before it began: what it was to move isn't coming.
            if (!begun && move == moves) asked = 0f
        }
    }

    /** Scrolls the grid to where the layer shows it, and the layer back. */
    private fun ScrollScope.settle() {
        val scrolled = scrollBy(-offset)
        offset += scrolled
        target -= scrolled
    }

    /** [distance] as far as the grid can scroll: to its first row's top, its last row's foot. */
    private fun limit(distance: Float): Float {
        val info = state.layoutInfo
        val first = info.visibleItemsInfo.firstOrNull()?.takeIf { it.index == 0 }
        val last = info.visibleItemsInfo.lastOrNull()?.takeIf { it.index == info.totalItemsCount - 1 }
        val back = first?.let { -it.offset.y.toFloat() - offset } ?: Float.MAX_VALUE
        val forth = last?.let { (it.offset.y + it.size.height + info.afterContentPadding - info.viewportEndOffset).toFloat() + offset }
            ?: Float.MAX_VALUE
        return distance.coerceIn(-back.coerceAtLeast(0f), forth.coerceAtLeast(0f))
    }

    private var grid: LayoutCoordinates? = null
    private var reach = 0

    /** The grid's coordinates (its layout, the layer aside) and how far past each end it is laid out. */
    fun placed(coordinates: LayoutCoordinates, reach: Int) {
        grid = coordinates
        this.reach = reach
    }

    /** Whether [item] shows, at the layer's offset, or lies within a row of its own height and [gap] px of the bounds. */
    fun nearView(item: LayoutCoordinates, gap: Float): Boolean {
        val grid = grid?.takeIf { it.isAttached } ?: return true
        if (!item.isAttached) return true
        // Read without observing it: the offset moves the layer, and must not draw the items again.
        val shift = Snapshot.withoutReadObservation { offset }
        val top = grid.localPositionOf(item, Offset.Zero).y - reach + shift
        // A row past the bounds, and as far again as the layer is still to move.
        val row = item.size.height + gap + abs(target + shift)
        val shown = grid.size.height - 2 * reach
        return top + item.size.height > -row && top < shown + row
    }
}

/** How far past each end a grid [gridMotion] moves is laid out (px): half the window, more than the row a move brings in. */
@Composable
internal fun gridMotionReach(): Int = LocalWindowInfo.current.containerSize.height / 2

/**
 * Moves this grid by [motion] as focus goes through it, as [platform] would bring each focused card into view: the grid
 * laid out [reach] px taller at its top and bottom, past its bounds, which clip it (rows out of sight, ready for the
 * layer to show as it moves). The grid's own scrolling for focus goes to none ([com.edde746.plezy.ui.focus.StaysPut]),
 * and its content is padded by [reach] at both ends, so it rests where it would without.
 */
internal fun Modifier.gridMotion(motion: GridMotion, reach: Int, platform: BringIntoViewSpec): Modifier = this
    .clip(VisibleRows)
    .layout { measurable, constraints ->
        val placeable = measurable.measure(
            constraints.copy(minHeight = constraints.minHeight + 2 * reach, maxHeight = constraints.maxHeight + 2 * reach),
        )
        layout(placeable.width, placeable.height - 2 * reach) { placeable.place(0, -reach) }
    }
    .graphicsLayer { translationY = motion.offset.roundToInt().toFloat() }
    .then(GridMotionElement(motion, reach, platform))

/** The grid's bounds top to bottom, and as wide as its cards' focus may grow past its sides. */
private val VisibleRows = GenericShape { size, _ -> addRect(Rect(-size.width, 0f, size.width * 2, size.height)) }

/** The spring the platform scrolls into view with. */
private val MotionSpring = spring<Float>()

/**
 * Draws this item of a grid [motion] moves only while it shows, or lies within a row (its own height and [gap] px) of
 * the grid's bounds, where the next move may bring it in: the rows laid out past that are there to be moved in later,
 * and drawing them would cost every frame. Decided as the grid draws its items (after a scroll), at the layer's offset.
 */
internal fun Modifier.drawnNearView(motion: GridMotion, gap: Float): Modifier = this then DrawnNearViewElement(motion, gap)

private data class DrawnNearViewElement(val motion: GridMotion, val gap: Float) : ModifierNodeElement<DrawnNearViewNode>() {
    override fun create() = DrawnNearViewNode(motion, gap)

    override fun update(node: DrawnNearViewNode) {
        node.motion = motion
        node.gap = gap
    }
}

private class DrawnNearViewNode(var motion: GridMotion, var gap: Float) :
    Modifier.Node(),
    DrawModifierNode,
    LayoutAwareModifierNode {
    private var placed: LayoutCoordinates? = null

    override fun onPlaced(coordinates: LayoutCoordinates) {
        placed = coordinates
    }

    override fun ContentDrawScope.draw() {
        val item = placed
        if (item == null || motion.nearView(item, gap)) drawContent()
    }
}

private data class GridMotionElement(val motion: GridMotion, val reach: Int, val platform: BringIntoViewSpec) :
    ModifierNodeElement<GridMotionNode>() {
    override fun create() = GridMotionNode(motion, reach, platform)

    override fun update(node: GridMotionNode) {
        node.motion = motion
        node.reach = reach
        node.platform = platform
    }
}

/**
 * Takes the grid's requests to bring a card into view (the grid itself scrolls for none): where each will rest (its
 * layout's place, less the moves not scrolled yet; the layer's offset aside). The requests of a frame (a card's and its
 * labels') make one move, at the next frame, for the one a scrolling container would pick: the largest that fits.
 */
private class GridMotionNode(var motion: GridMotion, var reach: Int, var platform: BringIntoViewSpec) :
    Modifier.Node(),
    BringIntoViewModifierNode,
    LayoutAwareModifierNode {
    override fun onPlaced(coordinates: LayoutCoordinates) {
        motion.placed(coordinates, reach)
    }

    private val asked = ArrayList<Rect>()

    override suspend fun bringIntoView(childCoordinates: LayoutCoordinates, boundsProvider: () -> Rect?) {
        if (!childCoordinates.isAttached) return
        val bounds = boundsProvider() ?: return
        val grid = requireLayoutCoordinates()
        val rect = Rect(grid.localPositionOf(childCoordinates, bounds.topLeft), bounds.size).translate(0f, -motion.ahead)
        val distance = distance(rect)
        if (distance != 0f) {
            if (asked.isEmpty()) {
                coroutineScope.launch {
                    withFrameNanos { }
                    move()
                }
            }
            asked += rect
        }
        // Then for whatever holds the grid, at the place the card comes to rest.
        bringIntoView { rect.translate(0f, -distance) }
    }

    /** The whole pixels [platform] would scroll to bring [rect] into view, as a scrolling grid moves by. */
    private fun distance(rect: Rect): Float {
        val shown = (requireLayoutCoordinates().size.height - 2 * reach).toFloat()
        return platform.calculateScrollDistance(rect.top - reach, rect.height, shown).roundToInt().toFloat()
    }

    private fun move() {
        val shown = requireLayoutCoordinates().size.height - 2 * reach
        asked.sortBy { it.height }
        val rect = asked.lastOrNull { it.height <= shown } ?: asked.first()
        asked.clear()
        val distance = distance(rect)
        if (distance == 0f) return
        motion.ask(distance)
        coroutineScope.launch { motion.move(reach.toFloat()) }
    }
}
