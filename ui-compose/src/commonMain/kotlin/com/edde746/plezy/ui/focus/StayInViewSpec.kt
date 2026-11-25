package com.edde746.plezy.ui.focus

import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size

/**
 * A scrolling column's or row's scrolling: an element that takes focus wholly in view stays where it is; one out of
 * view comes in as [platform] brings it (Android TV pivots it to 30 % of the height or width; elsewhere it comes just
 * inside the edge it was past). Without it, focus landing in a column (the wide details, TV's More panel, the player's
 * room panel) would scroll the lines above it off the screen, and in the Streams list's row of chips the chips before
 * it. In view means clear of [before] and [after] (px) at the container's ends, its top and bottom or its left and
 * right: a row's padding, which it scrolls across but where its chips go out of sight, or a sheet list's fades. An
 * element wholly on screen but within them moves the least that clears them, into the room between them (the first one
 * back to its place at rest); one past an edge comes in as [platform] brings it.
 */
internal class StayInViewSpec(private val platform: BringIntoViewSpec, private val before: Float = 0f, private val after: Float = 0f) : BringIntoViewSpec {
    override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float = when {
        offset >= before && offset + size <= containerSize - after -> 0f
        offset >= 0f && offset + size <= containerSize -> if (offset < before) offset - before else offset + size - (containerSize - after)
        else -> platform.calculateScrollDistance(offset - before, size, containerSize - before - after)
    }
}
