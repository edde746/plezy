package com.edde746.plezy.mpv.video.hdr

import kotlin.math.ceil
import kotlin.math.floor

/**
 * Where the video plane's subsurface sits and how large it is, in logical (surface) units for
 * wl_subsurface.set_position and wp_viewport.set_destination. Its buffer's size is [bufferExtent]'s.
 */
internal data class PlaneRect(val x: Int, val y: Int, val width: Int, val height: Int)

/**
 * The plane for the rect at ([x], [y]) sized [width] × [height] in physical pixels, on an output of [scale] physical
 * pixels per logical one, inside a parent whose view sits at ([offsetX], [offsetY]) logical units.
 *
 * The plane is biased outward on both edges, so it always covers the rect: an undersized plane shows whatever is
 * behind the transparent window through the seam. The origin is floored (not truncated, which would move a negative
 * origin inward) and the far edge is taken to the next whole unit, the extent measured between the two. A degenerate
 * rect is still one unit, because a zero-sized buffer or destination is not legal.
 *
 * The viewport scales the buffer to the destination ([bufferExtent]), so the scale may be fractional and the buffer
 * needs no multiple-of-scale rule. A scale below 1 or not finite is treated as 1. Arithmetic is 64-bit because the
 * inputs are unvalidated Ints: the far edge and the offset sum both overflow Int near its ends. Results are clamped so
 * the buffer at [scale] or less stays representable, at the cost of coverage only for a rect that is not representable
 * anyway.
 */
internal fun planeRect(
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    scale: Double,
    offsetX: Int = 0,
    offsetY: Int = 0,
): PlaneRect {
    val s = usable(scale)
    return PlaneRect(
        x = surfacePosition(x, s, offsetX),
        y = surfacePosition(y, s, offsetY),
        width = logicalExtent(x, width, s),
        height = logicalExtent(y, height, s),
    )
}

/**
 * The pixels per surface unit of the plane's buffer: the output's own scale [outputScale] (the compositor's preferred
 * scale for the plane, fractional ones included: 1.15 at 115 %) where it is under the window's [surfaceScale] (the
 * toolkit's whole scale, 2 there, at which mpv would render three times the pixels the output shows); [surfaceScale]
 * without one. Never above [surfaceScale], which is all the window's own content has, nor below 1.
 */
internal fun bufferScale(surfaceScale: Double, outputScale: Double?): Double {
    val surface = usable(surfaceScale)
    return if (outputScale == null || !outputScale.isFinite()) surface else outputScale.coerceIn(1.0, surface)
}

/** One side of the plane's buffer, in pixels, for [logical] surface units at [scale]: rounded up, at least 1, within Int. */
internal fun bufferExtent(logical: Int, scale: Double): Int =
    ceil(logical * usable(scale)).toLong().coerceIn(1, Int.MAX_VALUE.toLong()).toInt()

private fun usable(scale: Double): Double = if (scale.isFinite() && scale >= 1.0) scale else 1.0

private fun originUnits(position: Int, scale: Double): Long = floor(position / scale).toLong()

private fun surfacePosition(position: Int, scale: Double, offset: Int): Int =
    (originUnits(position, scale) + offset).coerceIn(Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong()).toInt()

/** Far edge minus origin, at least 1 and at most what keeps the buffer within Int. */
private fun logicalExtent(position: Int, extent: Int, scale: Double): Int {
    val end = ceil((position.toLong() + extent) / scale).toLong()
    val cap = floor(Int.MAX_VALUE / scale).toLong().coerceAtLeast(1)
    return (end - originUnits(position, scale)).coerceIn(1, cap).toInt()
}
