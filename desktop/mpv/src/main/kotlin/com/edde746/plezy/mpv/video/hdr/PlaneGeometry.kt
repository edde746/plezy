package com.edde746.plezy.mpv.video.hdr

import kotlin.math.ceil
import kotlin.math.floor

/**
 * Where the video plane's subsurface sits and how large it and its buffer are. [x], [y], [width] and [height] are
 * logical (surface) units for wl_subsurface.set_position and wp_viewport.set_destination; [bufferWidth] and
 * [bufferHeight] are the buffer's physical pixels.
 */
internal data class PlaneRect(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
    val bufferWidth: Int,
    val bufferHeight: Int,
)

/**
 * The plane for the rect at ([x], [y]) sized [width] × [height] in physical pixels, on an output of [scale] physical
 * pixels per logical one, inside a parent whose view sits at ([offsetX], [offsetY]) logical units.
 *
 * The plane is biased outward on both edges, so it always covers the rect: an undersized plane shows whatever is
 * behind the transparent window through the seam. The origin is floored (not truncated, which would move a negative
 * origin inward) and the far edge is taken to the next whole unit, the extent measured between the two. A degenerate
 * rect is still one unit, because a zero-sized buffer or destination is not legal.
 *
 * The viewport scales the buffer to the destination, so the scale may be fractional and the buffer needs no
 * multiple-of-scale rule; its size is the logical extent times the scale, rounded up. A scale below 1 or not finite
 * is treated as 1. Arithmetic is 64-bit because the inputs are unvalidated Ints: the far edge and the offset sum both
 * overflow Int near its ends. Results are clamped so the buffer stays representable, at the cost of coverage only for
 * a rect that is not representable anyway.
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
    val s = if (scale.isFinite() && scale >= 1.0) scale else 1.0
    val logicalWidth = logicalExtent(x, width, s)
    val logicalHeight = logicalExtent(y, height, s)
    return PlaneRect(
        x = surfacePosition(x, s, offsetX),
        y = surfacePosition(y, s, offsetY),
        width = logicalWidth,
        height = logicalHeight,
        bufferWidth = bufferExtent(logicalWidth, s),
        bufferHeight = bufferExtent(logicalHeight, s),
    )
}

private fun originUnits(position: Int, scale: Double): Long = floor(position / scale).toLong()

private fun surfacePosition(position: Int, scale: Double, offset: Int): Int =
    (originUnits(position, scale) + offset).coerceIn(Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong()).toInt()

/** Far edge minus origin, at least 1 and at most what keeps the buffer within Int. */
private fun logicalExtent(position: Int, extent: Int, scale: Double): Int {
    val end = ceil((position.toLong() + extent) / scale).toLong()
    val cap = floor(Int.MAX_VALUE / scale).toLong().coerceAtLeast(1)
    return (end - originUnits(position, scale)).coerceIn(1, cap).toInt()
}

private fun bufferExtent(logical: Int, scale: Double): Int =
    ceil(logical * scale).toLong().coerceIn(1, Int.MAX_VALUE.toLong()).toInt()
