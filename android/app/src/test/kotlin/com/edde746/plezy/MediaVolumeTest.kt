package com.edde746.plezy

import com.edde746.plezy.AndroidDeviceLevels.Companion.levelOfStep
import com.edde746.plezy.AndroidDeviceLevels.Companion.stepOfLevel
import kotlin.test.Test
import kotlin.test.assertEquals

/** The player's volume swipe over the media stream's steps, from the stream's least step (not 0 on every device) up. */
class MediaVolumeTest {
    @Test
    fun theLeastStepIsLevelZeroAndTheMostIsOne() {
        assertEquals(0.0, levelOfStep(3, min = 3, max = 15))
        assertEquals(0.5, levelOfStep(9, min = 3, max = 15))
        assertEquals(1.0, levelOfStep(15, min = 3, max = 15))
        assertEquals(0.4, levelOfStep(6, min = 0, max = 15))
    }

    @Test
    fun aStreamWithoutARangeReadsZero() {
        assertEquals(0.0, levelOfStep(5, min = 5, max = 5))
        assertEquals(0.0, levelOfStep(5, min = 6, max = 5))
    }

    @Test
    fun aLevelSetsTheNearestStepBetweenTheLeastAndTheMost() {
        assertEquals(3, stepOfLevel(0.0, min = 3, max = 15))
        assertEquals(9, stepOfLevel(0.5, min = 3, max = 15))
        assertEquals(15, stepOfLevel(1.0, min = 3, max = 15))
        assertEquals(4, stepOfLevel(0.05, min = 3, max = 15))
        assertEquals(6, stepOfLevel(0.4, min = 0, max = 15))
    }

    @Test
    fun aLevelOutsideZeroToOneStaysWithinTheStreamsSteps() {
        assertEquals(3, stepOfLevel(-0.5, min = 3, max = 15))
        assertEquals(15, stepOfLevel(1.5, min = 3, max = 15))
    }
}
