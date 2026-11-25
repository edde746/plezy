package com.edde746.plezy.input

import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class KeyRepeatTest {
    @Test
    fun aHeldArrowRepeatsAfter400MsThenEvery100MsUntilLetGo() = runTest {
        val repeat = KeyRepeat(backgroundScope, KeyRepeat.ARROW_DELAY_MILLIS, KeyRepeat.ARROW_INTERVAL_MILLIS)
        var steps = 0
        repeat.hold { steps++ }
        runCurrent()
        assertEquals(0, steps, "the press's own step is the caller's")
        advanceTimeBy(399)
        assertEquals(0, steps)
        advanceTimeBy(2)
        assertEquals(1, steps, "the first repeat at 400 ms")
        advanceTimeBy(100 * 3)
        assertEquals(4, steps, "then one every 100 ms")
        repeat.stop()
        advanceTimeBy(1_000)
        assertEquals(4, steps, "nothing after the key is let go")
    }

    @Test
    fun aHeldDelayButtonStepsAt500MsThenEvery200Ms() = runTest {
        val repeat = KeyRepeat(backgroundScope, KeyRepeat.HOLD_DELAY_MILLIS, KeyRepeat.HOLD_INTERVAL_MILLIS)
        val at = mutableListOf<Long>()
        repeat.hold { at += testScheduler.currentTime }
        advanceTimeBy(1_001)
        repeat.stop()
        advanceTimeBy(1_000)
        assertEquals(listOf(500L, 700L, 900L), at)
    }

    @Test
    fun anotherHoldStartsTheDelayAfresh() = runTest {
        val repeat = KeyRepeat(backgroundScope, KeyRepeat.ARROW_DELAY_MILLIS, KeyRepeat.ARROW_INTERVAL_MILLIS)
        val steps = mutableListOf<String>()
        repeat.hold { steps += "right" }
        advanceTimeBy(450)
        repeat.hold { steps += "left" }
        advanceTimeBy(399)
        assertEquals(listOf("right"), steps)
        advanceTimeBy(2)
        assertEquals(listOf("right", "left"), steps)
        repeat.stop()
    }
}
