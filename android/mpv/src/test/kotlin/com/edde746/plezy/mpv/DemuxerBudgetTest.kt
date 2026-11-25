package com.edde746.plezy.mpv

import android.content.ComponentCallbacks2
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DemuxerBudgetTest {
    private val mib = 1024L * 1024L

    @Test
    fun anUnknownHeapClassKeepsMpvsDefaults() {
        assertNull(DemuxerBudget.forHeapClassMB(0))
        assertNull(DemuxerBudget.forHeapClassMB(-1))
    }

    @Test
    fun theHeapClassPicksTheTier() {
        assertEquals(DemuxerBudget(32 * mib, 16 * mib), DemuxerBudget.forHeapClassMB(256))
        assertEquals(DemuxerBudget(64 * mib, 32 * mib), DemuxerBudget.forHeapClassMB(257))
        assertEquals(DemuxerBudget(64 * mib, 32 * mib), DemuxerBudget.forHeapClassMB(512))
        assertEquals(DemuxerBudget(100 * mib, 48 * mib), DemuxerBudget.forHeapClassMB(513))
    }

    @Test
    fun theStreamRingIsCappedByTheHeapClass() {
        assertEquals(64 * mib, DemuxerBudget.streamRingCapBytes(0))
        assertEquals(32 * mib, DemuxerBudget.streamRingCapBytes(256))
        assertEquals(64 * mib, DemuxerBudget.streamRingCapBytes(512))
        assertEquals(128 * mib, DemuxerBudget.streamRingCapBytes(513))
    }

    @Test
    fun runningLowFreesTheBackCacheAndLeavesReadAheadAlone() {
        for (heapClass in listOf(256, 512, 1024)) {
            val steady = DemuxerBudget.forHeapClassMB(heapClass)!!
            val low = DemuxerBudget.forTrimLevel(heapClass, ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)!!
            assertEquals(steady.aheadBytes, low.aheadBytes, "heap class $heapClass")
            assertEquals(0L, low.backBytes, "heap class $heapClass")
        }
    }

    @Test
    fun runningCriticalShrinksTheTotalButNeverBelowTheTightestTier() {
        val tightest = DemuxerBudget.forHeapClassMB(256)!!
        for (heapClass in listOf(256, 512, 1024)) {
            val steady = DemuxerBudget.forHeapClassMB(heapClass)!!
            val critical = DemuxerBudget.forTrimLevel(heapClass, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)!!
            assertTrue(critical.totalBytes < steady.totalBytes, "heap class $heapClass")
            assertTrue(critical.aheadBytes >= tightest.aheadBytes, "heap class $heapClass")
        }
    }

    @Test
    fun criticalPressureKeepsSixSecondsOfTheStream() {
        val remux = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 10_000_000L)!!
        assertEquals(DemuxerBudget(60_000_000L, 0), remux)
        val episode = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 2_000_000L)!!
        assertEquals(32 * mib, episode.aheadBytes)
        val above = DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 100_000_000L)!!
        assertEquals(DemuxerBudget(64 * mib, 0), above)
    }

    @Test
    fun theByteRateIsTheFasterOfTheCachedSpanAndTheFileAverage() {
        assertEquals(10_000_000L, DemuxerBudget.streamByteRate(33_500_000L, 3.35, 45_000_000_000L, 6250.0))
        assertEquals(7_200_000L, DemuxerBudget.streamByteRate(2_000_000L, 0.2, 7_200_000_000L, 1000.0))
        assertEquals(0L, DemuxerBudget.streamByteRate(0L, 0.0, 0L, 0.0))
        assertEquals(0L, DemuxerBudget.streamByteRate(5_000_000L, 0.0, 5_000_000L, 0.0))
    }

    @Test
    fun aLevelThatIsNoMemoryPressureAsksForNothing() {
        assertNull(DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN))
        @Suppress("DEPRECATION")
        assertNull(DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE))
        assertNull(DemuxerBudget.forTrimLevel(0, ComponentCallbacks2.TRIM_MEMORY_COMPLETE))
    }

    @Test
    fun aMilderLevelAfterAHarsherOneCannotGrowTheBudget() {
        val steady = DemuxerBudget.forHeapClassMB(1024)!!
        val critical = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)!!
        val low = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)!!
        assertTrue(low.aheadBytes > critical.aheadBytes)
        assertEquals(critical, steady.narrowedTo(critical).narrowedTo(low))
    }

    @Test
    fun theWayBackClimbsReadAheadARungAtATimeAndRestoresTheBackCacheLast() {
        val steady = DemuxerBudget.forHeapClassMB(1024)!!
        val critical = steady.narrowedTo(DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)!!)
        val steps = generateSequence(critical) { it.widenedToward(steady) }.toList()
        assertEquals(
            listOf(DemuxerBudget(32 * mib, 0), DemuxerBudget(64 * mib, 0), DemuxerBudget(100 * mib, 0), DemuxerBudget(100 * mib, 48 * mib)),
            steps,
        )
        assertEquals(DemuxerBudget(64 * mib, 0), DemuxerBudget(60 * mib, 0).widenedToward(steady))
        assertNull(steady.widenedToward(steady))
    }

    @Test
    fun theWayBackNeverPassesASteadyBudgetOffTheLadder() {
        val steady = DemuxerBudget(50 * mib, 20 * mib)
        val ahead = DemuxerBudget(32 * mib, 0).widenedToward(steady)!!
        assertEquals(DemuxerBudget(50 * mib, 0), ahead)
        assertEquals(steady, ahead.widenedToward(steady))
        assertEquals(DemuxerBudget(150 * mib, 0), DemuxerBudget(100 * mib, 0).widenedToward(DemuxerBudget(150 * mib, 50 * mib)))
    }

    @Test
    fun wideningNeedsFourTimesTheStepAboveTheKillerThresholdAndNeverUnderLowMemory() {
        val current = DemuxerBudget(32 * mib, 0)
        val next = DemuxerBudget(64 * mib, 0)
        val threshold = 200 * mib
        val needed = 4 * 32 * mib
        assertTrue(current.canWiden(next, threshold + needed, threshold, lowMemory = false))
        assertFalse(current.canWiden(next, threshold + needed - 1, threshold, lowMemory = false))
        assertFalse(current.canWiden(next, threshold + 10 * needed, threshold, lowMemory = true))
        val floor = 256 * mib
        assertTrue(current.canWiden(next, floor + needed, 0, lowMemory = false))
        assertFalse(current.canWiden(next, floor + needed - 1, -1, lowMemory = false))
    }
}
