package com.edde746.plezy.presentation.player

/**
 * A phone's and a tablet's swipe of the content strip (the chapters and the queue) over the bottom controls, one rule
 * for every UI. The strip follows the finger: [EXTENT] of travel takes it from closed to open, so a swipe up of
 * [EXTENT] opens it fully and one down as far closes it. As the finger lifts it settles open or closed: open when flung
 * up (faster than [FLING] a second), or past halfway and not flung down.
 */
object ContentStripSwipe {
    /** The travel, in dp (points), from closed to open. */
    const val EXTENT = 150f

    /** A swipe faster than this, in dp (points) a second, is a fling. */
    const val FLING = 200f

    /** The strip's openness, 0 closed to 1 open, after a vertical move of [dy] (up negative) from [progress]. */
    fun drag(progress: Float, dy: Float): Float = (progress - dy / EXTENT).coerceIn(0f, 1f)

    /** Whether the strip settles open at [progress] as the finger lifts at [velocity] (up negative). */
    fun opens(progress: Float, velocity: Float): Boolean = velocity < -FLING || progress > 0.5f && velocity < FLING
}
