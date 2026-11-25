package com.edde746.plezy.ui.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Gradient stops taking [color] from alpha [from] at [start] to alpha [to] at [end] (either way round), eased at both
 * ends ([eased]): the fade meets what lies past its ends without a change of slope, so it shows no edge there. Every
 * backdrop's fade is one of these.
 */
internal fun fadeStops(color: Color, start: Float, end: Float, from: Float, to: Float = 0f): Array<Pair<Float, Color>> {
    val stops = Array(FADE_STEPS + 1) { i ->
        val t = i / FADE_STEPS.toFloat()
        (start + (end - start) * t) to color.copy(alpha = from + (to - from) * eased(t))
    }
    return if (end < start) stops.reversedArray() else stops
}

/** A fade's share done at [t] of its way (smoothstep): flat at both ends. */
internal fun eased(t: Float): Float = t * t * (3 - 2 * t)

/** The straight pieces of a [fadeStops] curve: enough that a fade across a TV's width shows no corners. */
private const val FADE_STEPS = 16

/**
 * A sheet's scrolling list's edges: while [above] (a row of the list is hidden above its top or cut there past its
 * label's margin: [hidesRowsAbove]) the sheet's surface lies over the list's top [SCROLL_EDGE_FADE], easing out to clear
 * ([fadeStops]), so the rows above read as cut off rather than as the list's start; while [below] ([hidesRowsBelow]) the
 * same over its bottom, so the rows below read as more to come (TV's sort panels). A row whose label shows whole is
 * never faded for an edge that holds nothing more: a faded label reads as disabled.
 */
@Composable
internal fun Modifier.scrollEdgeFades(above: () -> Boolean, below: () -> Boolean): Modifier {
    val color = PlezyColors.Surface
    return drawWithContent {
        drawContent()
        val fade = SCROLL_EDGE_FADE.toPx().coerceAtMost(size.height)
        if (above()) {
            drawRect(Brush.verticalGradient(*fadeStops(color, 0f, 1f, from = 1f), startY = 0f, endY = fade), size = Size(size.width, fade))
        }
        if (below()) {
            val top = size.height - fade
            drawRect(Brush.verticalGradient(*fadeStops(color, 1f, 0f, from = 1f), startY = top, endY = size.height), topLeft = Offset(0f, top), size = Size(size.width, fade))
        }
    }
}

/** The height of a [scrollEdgeFades] fade, which a focused row is kept clear of. */
internal val SCROLL_EDGE_FADE = 40.dp

/**
 * Whether a row of this list is hidden above its top, or cut there by more than the list's padding (a sheet list's is
 * its rows' focus reach, under their label's margin): not just its top padding scrolled away, or a row's margin.
 */
internal fun LazyListState.hidesRowsAbove(): Boolean {
    val info = layoutInfo
    val first = info.visibleItemsInfo.firstOrNull() ?: return false
    return first.index > 0 || first.offset < info.viewportStartOffset - info.beforeContentPadding
}

/** Whether a row of this list is hidden below its bottom, or cut there by more than the list's padding. */
internal fun LazyListState.hidesRowsBelow(): Boolean {
    val info = layoutInfo
    val last = info.visibleItemsInfo.lastOrNull() ?: return false
    return last.index < info.totalItemsCount - 1 || last.offset + last.size > info.viewportEndOffset + info.afterContentPadding
}

/** Whether a scrolling column padded by [paddingPx] at both ends hides a row above its top or cuts it past [paddingPx]. */
internal fun ScrollState.hidesRowsAbove(paddingPx: Int): Boolean = value > 2 * paddingPx

/** Whether a scrolling column padded by [paddingPx] at both ends hides a row below its bottom or cuts it past [paddingPx]. */
internal fun ScrollState.hidesRowsBelow(paddingPx: Int): Boolean = value < maxValue - 2 * paddingPx
