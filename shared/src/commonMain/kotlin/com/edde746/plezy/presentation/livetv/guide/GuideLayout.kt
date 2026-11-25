package com.edde746.plezy.presentation.livetv.guide

/**
 * The guide grid's measures, in density-independent points (Compose `dp`, SwiftUI points), the same on every UI: half an
 * hour is [SLOT_WIDTH] wide, a channel row [ROW_HEIGHT] high, and the window shows [WINDOW_HOURS] hours.
 */
object GuideLayout {
    const val SLOT_WIDTH: Double = 180.0
    const val CHANNEL_COLUMN_WIDTH: Double = 132.0
    const val ROW_HEIGHT: Double = 64.0
    const val SOURCE_HEADER_ROW_HEIGHT: Double = 40.0
    const val TIME_HEADER_HEIGHT: Double = 40.0
    const val MINUTES_PER_SLOT: Int = 30
    const val SLOT_SECONDS: Long = MINUTES_PER_SLOT * 60L
    const val WINDOW_HOURS: Int = 6
    const val WINDOW_SECONDS: Long = WINDOW_HOURS * 3600L

    /** What ◀ and ▶ move the window by. */
    const val SHIFT_HOURS: Int = 2

    /** A program block is never narrower, however short its airing. */
    const val MIN_BLOCK_WIDTH: Double = 6.0

    /** From a program block's edges to its text. */
    const val TEXT_PADDING: Double = 10.0

    /** A program block with less room than this for its text shows none, not a cut word. */
    const val MIN_TEXT_WIDTH: Double = 48.0

    /** The red now line over the time header and the rows. */
    const val NOW_LINE_WIDTH: Double = 2.0

    /** The reload overlay: black at this alpha over the grid, with a spinner [RELOAD_SPINNER_SIZE] across. */
    const val RELOAD_SCRIM_ALPHA: Double = 0x33 / 255.0
    const val RELOAD_SPINNER_SIZE: Double = 28.0

    /** A vertical focus scroll animates this long, easing out; horizontal ones jump. */
    const val VERTICAL_SCROLL_MILLIS: Int = 150

    /** The grid's width: the window's slots side by side. */
    const val GRID_WIDTH: Double = WINDOW_SECONDS.toDouble() / SLOT_SECONDS * SLOT_WIDTH
}

/** Where [epochSeconds] falls across the grid of the window starting at [windowStart] (epoch seconds). */
fun guideOffsetAt(epochSeconds: Long, windowStart: Long): Double =
    (epochSeconds - windowStart).toDouble() / GuideLayout.SLOT_SECONDS * GuideLayout.SLOT_WIDTH

/**
 * Whether a block at [left] of [width] is laid out with the grid scrolled to [scrollOffset] in a [viewportWidth] wide
 * view: one slot of overscan each side, so the next D-pad target exists before a horizontal jump reaches it.
 */
fun guideBlockVisible(left: Double, width: Double, scrollOffset: Double, viewportWidth: Double): Boolean {
    val visibleStart = if (scrollOffset > GuideLayout.SLOT_WIDTH) scrollOffset - GuideLayout.SLOT_WIDTH else 0.0
    val visibleEnd = scrollOffset + viewportWidth + GuideLayout.SLOT_WIDTH
    return left + width >= visibleStart && left <= visibleEnd
}

/**
 * Where the text of a block at [left] of [width] starts, from the block's leading edge, with the grid scrolled to
 * [scrollOffset]: [GuideLayout.TEXT_PADDING] in, and for a block begun before the time shown as much further as the
 * view's start, so its title stays in view. Null when that leaves less than [GuideLayout.MIN_TEXT_WIDTH] for the text
 * before the block's end ([gap], the gap between blocks, and [GuideLayout.TEXT_PADDING] there): no text, not a cut word.
 */
fun guideBlockTextInset(left: Double, width: Double, scrollOffset: Double, gap: Double): Double? {
    val inset = GuideLayout.TEXT_PADDING + (scrollOffset - left).coerceIn(0.0, width)
    return inset.takeIf { width - gap - it - GuideLayout.TEXT_PADDING >= GuideLayout.MIN_TEXT_WIDTH }
}

/**
 * The horizontal offset that brings [nowOffset] into a [viewportWidth] wide view at the start of a slot, so the view
 * starts where that slot's airings do, none of them a sliver under the channel column, within 0…[maxScroll]: the slot a
 * third of the way before now where now's own slot then shows whole (a TV's wide view: what aired before shows too);
 * else now's own slot (a phone's narrow view: the airings on now shown whole from their start); else, in a view
 * narrower than a slot, now a third of the way across.
 */
fun guideScrollToNowOffset(nowOffset: Double, viewportWidth: Double, maxScroll: Double): Double {
    val third = (nowOffset - viewportWidth / 3).coerceAtLeast(0.0)
    val earlier = kotlin.math.floor(third / GuideLayout.SLOT_WIDTH) * GuideLayout.SLOT_WIDTH
    val nowSlot = kotlin.math.floor(nowOffset / GuideLayout.SLOT_WIDTH) * GuideLayout.SLOT_WIDTH
    val start = when {
        nowSlot + GuideLayout.SLOT_WIDTH <= earlier + viewportWidth -> earlier
        GuideLayout.SLOT_WIDTH <= viewportWidth -> nowSlot
        else -> third
    }
    return start.coerceIn(0.0, maxScroll.coerceAtLeast(0.0))
}

/**
 * The horizontal offset that brings a block starting at [left] into view: the view starting where the block does, when
 * it starts before [currentOffset] or past 100 points from the view's end, so nothing of the block before it shows as a
 * sliver under the channel column; null when it is in view already.
 */
fun guideProgramScrollOffset(left: Double, currentOffset: Double, viewportWidth: Double, maxScroll: Double): Double? {
    if (left >= currentOffset && left <= currentOffset + viewportWidth - 100.0) return null
    return left.coerceIn(0.0, maxScroll.coerceAtLeast(0.0))
}

/**
 * The vertical offset that brings a channel row at [rowTop] fully into a [viewportHeight] view scrolled to
 * [viewportTop] (its top edge when above, its bottom edge when below); null when it is in view. Animate it over
 * [GuideLayout.VERTICAL_SCROLL_MILLIS] and move the channel column with it.
 */
fun guideRowScrollOffset(rowTop: Double, viewportTop: Double, viewportHeight: Double, maxScroll: Double): Double? {
    val target = when {
        rowTop < viewportTop -> rowTop
        rowTop + GuideLayout.ROW_HEIGHT > viewportTop + viewportHeight -> rowTop + GuideLayout.ROW_HEIGHT - viewportHeight
        else -> return null
    }
    return target.coerceIn(0.0, maxScroll.coerceAtLeast(0.0))
}
