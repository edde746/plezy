package com.edde746.plezy.playback.session

/**
 * Leaving a video at [positionSeconds] of [durationSeconds] counts as having finished it: past [CREDITS_THRESHOLD] of
 * it, or past [creditsStart], the start of its credits to the end (from its chapters, `SkipSegments`; a player app
 * reports none). Before that a movie stays resumable, watched or not.
 */
internal fun pastCredits(positionSeconds: Double, durationSeconds: Double, creditsStart: Double? = null): Boolean =
    durationSeconds > 0 &&
        (positionSeconds > durationSeconds * CREDITS_THRESHOLD || (creditsStart != null && positionSeconds >= creditsStart))

/** The share of a video past which leaving it counts as having finished it ([pastCredits]). */
internal const val CREDITS_THRESHOLD = 0.9
