@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.livetv.playback

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** Relative live skips coalesce into one reopen and report only the travel the window lets through. */
class LiveSeekAccumulatorTest {
    private val seeks = mutableListOf<Long>()
    private var currentEpoch = 1000L
    private var window: LiveSeekBounds? = LiveSeekBounds(0, 1_000_000)
    private var changes = 0
    private var seekThrows = false
    private var seekSucceeds = true
    private var gate: CompletableDeferred<Unit>? = null

    private fun build(scope: CoroutineScope) = LiveSeekAccumulator(
        scope = scope,
        seek = { target ->
            seeks += target
            gate?.await()
            if (seekThrows) throw IllegalStateException("seek failed")
            seekSucceeds
        },
        currentEpoch = { currentEpoch },
        bounds = { window },
        onChanged = { changes++ },
    )

    private fun TestScope.elapse(millis: Long) {
        advanceTimeBy(millis.milliseconds)
        runCurrent()
    }

    @Test
    fun aRapidBurstIsOneSeekAtTheSummedTarget() = runTest {
        val acc = build(backgroundScope)
        repeat(14) { acc.seekBy(15) }
        runCurrent()
        assertTrue(seeks.isEmpty(), "nothing fires while the burst arrives")
        elapse(300)
        assertEquals(listOf(1210L), seeks)
    }

    @Test
    fun pressesAccumulateOffThePendingTargetNotTheLaggingEpoch() = runTest {
        val acc = build(backgroundScope)
        acc.seekBy(15)
        assertEquals(1015L, acc.pendingEpoch)
        currentEpoch = 99_999
        acc.seekBy(15)
        assertEquals(1030L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(1030L), seeks)
    }

    @Test
    fun forwardSkipsClampToTheLiveEdgeAndReportOnlyTheTravelLetThrough() = runTest {
        window = LiveSeekBounds(950, 1050)
        val acc = build(backgroundScope)
        assertEquals(50L, acc.seekBy(100))
        assertEquals(1050L, acc.pendingEpoch)
        assertEquals(0L, acc.seekBy(100))
        assertEquals(1050L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(1050L), seeks)
    }

    @Test
    fun backwardSkipsClampToTheWindowStart() = runTest {
        window = LiveSeekBounds(950, 1050)
        val acc = build(backgroundScope)
        assertEquals(-50L, acc.seekBy(-100))
        assertEquals(950L, acc.pendingEpoch)
    }

    @Test
    fun aSkipClampedToTheCurrentBoundaryDoesNotReopen() = runTest {
        window = LiveSeekBounds(950, 1050)
        val acc = build(backgroundScope)
        currentEpoch = 1050
        assertEquals(0L, acc.seekBy(15))
        assertNull(acc.pendingEpoch)
        currentEpoch = 950
        assertEquals(0L, acc.seekBy(-15))
        assertNull(acc.pendingEpoch)
        elapse(300)
        assertTrue(seeks.isEmpty())
        assertEquals(0, changes)
    }

    @Test
    fun aRewindFromPastAStaleLiveEdgeTravelsTheFullStep() = runTest {
        window = LiveSeekBounds(950, 1050)
        val acc = build(backgroundScope)
        currentEpoch = 1060
        assertEquals(0L, acc.seekBy(15))
        assertNull(acc.pendingEpoch)
        assertEquals(-5L, acc.seekBy(-5))
        assertEquals(1055L, acc.pendingEpoch)
        assertEquals(-10L, acc.seekBy(-10))
        assertEquals(1045L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(1045L), seeks)
    }

    @Test
    fun aSkipFromBehindARolledPastWindowStartLandsOnTheStart() = runTest {
        window = LiveSeekBounds(950, 1050)
        val acc = build(backgroundScope)
        currentEpoch = 940
        assertEquals(0L, acc.seekBy(-5))
        assertNull(acc.pendingEpoch)
        assertEquals(10L, acc.seekBy(5))
        assertEquals(950L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(950L), seeks)
    }

    @Test
    fun aWindowMovingUnderAPendingBurstNeverReportsTravelAgainstThePress() = runTest {
        window = LiveSeekBounds(900, 1050)
        val acc = build(backgroundScope)
        assertEquals(-50L, acc.seekBy(-50))
        assertEquals(950L, acc.pendingEpoch)
        window = LiveSeekBounds(960, 1060)
        assertEquals(0L, acc.seekBy(-10))
        assertEquals(960L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(960L), seeks)
    }

    @Test
    fun aRewindFromTheCaptureBufferEdgeStillSeeks() = runTest {
        window = LiveSeekBounds(950, 1050)
        currentEpoch = 1050
        val acc = build(backgroundScope)
        acc.seekBy(-15)
        assertEquals(1035L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(1035L), seeks)
    }

    @Test
    fun aPressDuringTheSeekFlushesTheNewerTargetRightAfter() = runTest {
        gate = CompletableDeferred()
        val acc = build(backgroundScope)
        acc.seekBy(15)
        elapse(300)
        assertEquals(listOf(1015L), seeks)
        acc.seekBy(15)
        val first = gate!!
        gate = null
        first.complete(Unit)
        runCurrent()
        assertEquals(listOf(1015L, 1030L), seeks)
    }

    @Test
    fun newerInputIsDispatchedAfterAFailedCalibration() = newerInputAfterAnExpiredDebounce(throws = false)

    @Test
    fun newerInputIsDispatchedAfterAFailedReopen() = newerInputAfterAnExpiredDebounce(throws = true)

    private fun newerInputAfterAnExpiredDebounce(throws: Boolean) = runTest {
        val completions = mutableListOf<CompletableDeferred<Boolean>>()
        val acc = LiveSeekAccumulator(
            scope = backgroundScope,
            seek = { target ->
                seeks += target
                val completion = CompletableDeferred<Boolean>()
                completions += completion
                completion.await()
            },
            currentEpoch = { currentEpoch },
            bounds = { window },
        )
        acc.seekBy(15)
        elapse(300)
        acc.seekBy(15)
        elapse(300)
        assertEquals(listOf(1015L), seeks)
        assertEquals(1030L, acc.pendingEpoch)

        if (throws) completions.first().completeExceptionally(IllegalStateException("source replacement failed")) else completions.first().complete(false)
        runCurrent()
        assertEquals(listOf(1015L, 1030L), seeks)
        assertEquals(1030L, acc.pendingEpoch)

        completions.last().complete(true)
        runCurrent()
        assertNull(acc.pendingEpoch)
        currentEpoch = 1045
        acc.seekBy(15)
        elapse(300)
        assertEquals(listOf(1015L, 1030L, 1060L), seeks)
        completions.last().complete(true)
        runCurrent()
    }

    @Test
    fun thePendingTargetIsUnpinnedOnlyOnceTheClockIsCalibrated() = runTest {
        gate = CompletableDeferred()
        val acc = build(backgroundScope)
        acc.seekBy(15)
        elapse(300)
        assertEquals(1015L, acc.pendingEpoch)
        advanceTimeBy(10.seconds)
        runCurrent()
        assertEquals(1015L, acc.pendingEpoch, "elapsed time is no evidence that the source clock is calibrated")
        gate!!.complete(Unit)
        runCurrent()
        assertNull(acc.pendingEpoch)
    }

    @Test
    fun aFreshBurstAfterSettlingStartsFromTheLiveEpoch() = runTest {
        val acc = build(backgroundScope)
        acc.seekBy(15)
        elapse(300)
        assertNull(acc.pendingEpoch)
        currentEpoch = 1015
        acc.seekBy(15)
        elapse(300)
        assertEquals(listOf(1015L, 1030L), seeks)
    }

    @Test
    fun aFailedReopenReleasesThePin() = runTest {
        seekThrows = true
        val acc = build(backgroundScope)
        acc.seekBy(15)
        assertEquals(1015L, acc.pendingEpoch)
        elapse(300)
        assertEquals(listOf(1015L), seeks)
        assertNull(acc.pendingEpoch)
    }

    @Test
    fun aFailedCalibrationReleasesThePin() = runTest {
        seekSucceeds = false
        val acc = build(backgroundScope)
        acc.seekBy(15)
        elapse(300)
        assertEquals(listOf(1015L), seeks)
        assertNull(acc.pendingEpoch)
    }

    @Test
    fun cancelDropsThePendingTargetAndItsSeek() = runTest {
        val acc = build(backgroundScope)
        acc.seekBy(15)
        assertEquals(1015L, acc.pendingEpoch)
        acc.cancel()
        assertNull(acc.pendingEpoch)
        elapse(300)
        assertTrue(seeks.isEmpty())
    }

    @Test
    fun withoutASeekableWindowNothingHappens() = runTest {
        window = null
        val acc = build(backgroundScope)
        acc.seekBy(15)
        assertNull(acc.pendingEpoch)
        elapse(300)
        assertTrue(seeks.isEmpty())
    }

    @Test
    fun changesAreSignalledWhenTheTargetMovesAndWhenItClears() = runTest {
        val acc = build(backgroundScope)
        acc.seekBy(15)
        assertEquals(1, changes)
        elapse(300)
        assertEquals(2, changes)
    }
}
