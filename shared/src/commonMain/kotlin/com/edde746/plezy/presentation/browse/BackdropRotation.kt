package com.edde746.plezy.presentation.browse

/**
 * A backdrop's turn through an item's [count] backgrounds: [index] the one to show, [failed] the ones that failed to
 * load, which the rotation skips from then on. A new item starts a new rotation at its first background.
 */
data class BackdropRotation(val count: Int, val index: Int = 0, val failed: Set<Int> = emptySet()) {
    /** The backgrounds that haven't failed. */
    val usable: Int get() = count - failed.size

    /** The background to show: [index], else the next that hasn't failed; null once every one has. */
    val current: Int? get() = (0 until count).map { (index + it) % count }.firstOrNull { it !in failed }

    /** The next background that hasn't failed, wrapping; as it is with no other. */
    fun advance(): BackdropRotation = nextAfter(index)?.let { copy(index = it) } ?: this

    /** Background [at] failed to load: skipped from now on, and the rotation moves on past it at once. */
    fun fail(at: Int): BackdropRotation {
        if (at in failed || at !in 0 until count) return this
        val next = copy(failed = failed + at)
        return next.nextAfter(at)?.let { next.copy(index = it) } ?: next
    }

    private fun nextAfter(from: Int): Int? = (1..count).map { (from + it) % count }.firstOrNull { it !in failed }

    companion object {
        /** The backdrop turns to its next background every 10 s, fading it in over 280 ms. */
        const val ROTATION_MILLIS = 10_000L
        const val CROSSFADE_MILLIS = 280

        /**
         * Whether the backgrounds turn: the backdrop is [active] (its page settled), the app is [visible], neither the
         * reduced effects tier ([reducedTier]) nor reduced motion asks for stillness, and two backgrounds are usable.
         */
        fun rotates(rotation: BackdropRotation, active: Boolean, visible: Boolean, reducedTier: Boolean, reducedMotion: Boolean): Boolean =
            active && visible && !reducedTier && !reducedMotion && rotation.usable > 1

        /** The crossfade between backgrounds ([CROSSFADE_MILLIS]): none under reduced motion or on the reduced effects tier. */
        fun fadeMillis(reducedTier: Boolean, reducedMotion: Boolean): Int = if (reducedTier || reducedMotion) 0 else CROSSFADE_MILLIS
    }
}
