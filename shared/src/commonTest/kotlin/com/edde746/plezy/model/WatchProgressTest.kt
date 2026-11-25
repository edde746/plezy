package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class WatchProgressTest {
    @Test
    fun falseForZeroOrNegativeDuration() {
        assertFalse(isWatchedProgress(positionMs = 1000, durationMs = 0, threshold = 0.9))
        assertFalse(isWatchedProgress(positionMs = 1000, durationMs = -1, threshold = 0.9))
    }

    @Test
    fun exactThresholdCountsAsWatched() {
        assertTrue(isWatchedProgress(positionMs = 90, durationMs = 100, threshold = 0.9))
    }

    @Test
    fun justBelowThresholdIsNotWatched() {
        assertFalse(isWatchedProgress(positionMs = 89, durationMs = 100, threshold = 0.9))
    }

    @Test
    fun positionPastDurationIsWatched() {
        assertTrue(isWatchedProgress(positionMs = 110, durationMs = 100, threshold = 0.9))
    }

    @Test
    fun zeroPositionIsNotWatched() {
        assertFalse(isWatchedProgress(positionMs = 0, durationMs = 100, threshold = 0.9))
    }
}
