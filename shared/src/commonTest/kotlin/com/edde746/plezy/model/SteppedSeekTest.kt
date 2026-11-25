package com.edde746.plezy.model

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class SteppedSeekTest {
    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    private fun jumps() = MutableSharedFlow<Duration?>(extraBufferCapacity = 16)

    private fun TestScope.emit(flow: MutableSharedFlow<Duration?>, target: Duration?) {
        assertTrue(flow.tryEmit(target))
        runCurrent()
    }

    @Test
    fun steppedMultiplierPreservesSharedAccelerationTiers() {
        assertEquals(1.5, steppedSeekMultiplier(0))
        assertEquals(1.5, steppedSeekMultiplier(5))
        assertEquals(3.0, steppedSeekMultiplier(6))
        assertEquals(3.0, steppedSeekMultiplier(15))
        assertEquals(6.0, steppedSeekMultiplier(16))
        assertEquals(6.0, steppedSeekMultiplier(30))
        assertEquals(10.0, steppedSeekMultiplier(31))
    }

    @Test
    fun rapidStepsAccumulateAndDebounceIntoOneSeek() = runTest {
        var position = 20.seconds
        val seeks = mutableListOf<Duration>()
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { position }, { 2.minutes }, { seeks += it })

        accumulator.seekBy(10.seconds)
        accumulator.seekBy(15.seconds)
        accumulator.seekBy((-5).seconds)

        assertEquals(40.seconds, accumulator.pendingPosition)
        elapse(799.milliseconds)
        assertEquals(emptyList(), seeks)
        elapse(1.milliseconds)
        assertEquals(listOf(40.seconds), seeks)

        // A slow player still reports the old position: the next burst builds on the pinned target.
        accumulator.seekBy(10.seconds)
        accumulator.flush()
        assertEquals(listOf(40.seconds, 50.seconds), seeks)

        position = 50.seconds
        elapse(2.seconds)
        assertNull(accumulator.pendingPosition)
        accumulator.dispose()
    }

    @Test
    fun clampsTargetsAndCancelPreventsAPendingSeek() = runTest {
        val seeks = mutableListOf<Duration>()
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { 5.seconds }, { 30.seconds }, { seeks += it })

        accumulator.seekBy(1.minutes)
        assertEquals(30.seconds, accumulator.pendingPosition)
        accumulator.cancel()
        elapse(1.seconds)
        assertEquals(emptyList(), seeks)
        assertNull(accumulator.pendingPosition)
        accumulator.dispose()
    }

    @Test
    fun reportsTheDistanceTheClampLetThroughNotTheStepAskedFor() = runTest {
        // Three 10 s steps back from 0:25 travel 10, 10 and 5; after that nothing, and the pin stays at zero.
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { 25.seconds }, { 1.minutes }, {})

        val step = (-10).seconds
        assertEquals((-10).seconds, accumulator.seekBy(step))
        assertEquals((-10).seconds, accumulator.seekBy(step))
        assertEquals((-5).seconds, accumulator.seekBy(step))
        assertEquals(Duration.ZERO, accumulator.seekBy(step))
        assertEquals(Duration.ZERO, accumulator.pendingPosition)
        accumulator.dispose()
    }

    @Test
    fun aFreshPressAlreadyAtAnEdgeArmsNothing() = runTest {
        var position = Duration.ZERO
        val seeks = mutableListOf<Duration>()
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { position }, { 1.minutes }, { seeks += it })

        assertEquals(Duration.ZERO, accumulator.seekBy((-10).seconds))
        assertNull(accumulator.pendingPosition)
        elapse(1.seconds)
        assertEquals(emptyList(), seeks)

        // A position reported past the end counts as the end.
        position = 1.minutes + 500.milliseconds
        assertEquals(Duration.ZERO, accumulator.seekBy(10.seconds))
        assertNull(accumulator.pendingPosition)
        assertEquals(-(9.seconds + 500.milliseconds), accumulator.seekBy((-10).seconds))
        assertEquals(50.seconds + 500.milliseconds, accumulator.pendingPosition)
        elapse(1.seconds)
        assertEquals(listOf(50.seconds + 500.milliseconds), seeks)
        accumulator.dispose()
    }

    @Test
    fun aSeekFromElsewhereRetiresThePinSoTheNextStepRebases() = runTest {
        var position = 20.seconds
        val seeks = mutableListOf<Duration>()
        var abandonments = 0
        val playerJumps = jumps()
        val accumulator = DebouncedSeekAccumulator(
            backgroundScope, { position }, { 10.minutes }, { seeks += it },
            onBurstAbandoned = { abandonments++ }, playheadJumps = playerJumps,
        )

        accumulator.seekBy(10.seconds)
        accumulator.flush()
        assertEquals(listOf(30.seconds), seeks)
        // The accumulator's own commit, echoed back by the player.
        position = 30.seconds
        emit(playerJumps, 30.seconds)
        assertEquals(30.seconds, accumulator.pendingPosition)
        assertEquals(0, abandonments, "its own seek is not a foreign one")

        // The viewer drops the playhead elsewhere on the timeline.
        position = 5.minutes
        emit(playerJumps, 5.minutes)
        assertNull(accumulator.pendingPosition)
        assertEquals(1, abandonments)

        accumulator.seekBy(10.seconds)
        accumulator.flush()
        assertEquals(5.minutes + 10.seconds, seeks.last(), "the skip is relative to the timeline jump, not the superseded target")
        accumulator.dispose()
    }

    @Test
    fun aSeekFromElsewhereMidBurstDropsTheUndispatchedTarget() = runTest {
        var position = 20.seconds
        val seeks = mutableListOf<Duration>()
        val playerJumps = jumps()
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { position }, { 10.minutes }, { seeks += it }, playheadJumps = playerJumps)

        accumulator.seekBy(10.seconds)
        position = 5.minutes
        emit(playerJumps, 5.minutes)

        elapse(2.seconds)
        assertEquals(emptyList(), seeks, "the debounce belonged to a burst the foreign seek abandoned")
        assertNull(accumulator.pendingPosition)
        accumulator.dispose()
    }

    @Test
    fun onBurstAbandonedStaysOutOfTheOrdinaryStepAndSettlePaths() = runTest {
        var position = 20.seconds
        var abandonments = 0
        var changes = 0
        val playerJumps = jumps()
        val accumulator = DebouncedSeekAccumulator(
            backgroundScope, { position }, { 10.minutes }, {},
            onChanged = { changes++ }, onBurstAbandoned = { abandonments++ }, playheadJumps = playerJumps,
        )

        // Repeated presses move the target: previews repaint, but no press is a foreign seek.
        accumulator.seekBy(10.seconds)
        accumulator.seekBy(10.seconds)
        accumulator.seekBy(10.seconds)
        assertEquals(3, changes)
        assertEquals(0, abandonments)

        // Nor is the natural settle once playback reaches the target.
        accumulator.flush()
        position = 50.seconds
        elapse(2.seconds)
        assertNull(accumulator.pendingPosition)
        assertEquals(0, abandonments)
        accumulator.dispose()
    }

    @Test
    fun aRetiredAccumulatorStopsListeningToThePlayer() = runTest {
        val playerJumps = jumps()
        val accumulator = DebouncedSeekAccumulator(backgroundScope, { 20.seconds }, { 10.minutes }, {}, playheadJumps = playerJumps)
        assertEquals(1, playerJumps.subscriptionCount.value)

        accumulator.seekBy(10.seconds)
        accumulator.dispose()
        runCurrent()
        assertEquals(0, playerJumps.subscriptionCount.value)
    }

    @Test
    fun aJumpWithNoReportedDestinationIsAlwaysForeign() = runTest {
        val seeks = mutableListOf<Duration>()
        var abandonments = 0
        val playerJumps = jumps()
        var position = 20.seconds
        val accumulator = DebouncedSeekAccumulator(
            backgroundScope, { position }, { 10.minutes }, { seeks += it },
            onBurstAbandoned = { abandonments++ }, playheadJumps = playerJumps,
        )

        accumulator.seekBy(10.seconds)
        accumulator.flush()
        assertEquals(30.seconds, accumulator.pendingPosition)

        // mpv's subtitle seek picks its own cue, so the destination is unknown.
        position = 2.minutes
        emit(playerJumps, null)

        assertNull(accumulator.pendingPosition)
        assertEquals(1, abandonments)

        accumulator.seekBy(10.seconds)
        accumulator.flush()
        assertEquals(2.minutes + 10.seconds, seeks.last())
        accumulator.dispose()
    }

    @Test
    fun rebindingToAnotherPlayerDropsTheOldPinAndItsStream() = runTest {
        var abandonments = 0
        val oldPlayer = jumps()
        val newPlayer = jumps()
        val accumulator = DebouncedSeekAccumulator(
            backgroundScope, { 20.seconds }, { 10.minutes }, {},
            onBurstAbandoned = { abandonments++ }, playheadJumps = oldPlayer,
        )

        accumulator.seekBy(10.seconds)
        accumulator.attachPlayheadJumps(newPlayer)
        runCurrent()

        assertEquals(0, oldPlayer.subscriptionCount.value)
        assertNull(accumulator.pendingPosition, "the pin described the retired player, whose echo will never arrive")
        assertEquals(1, abandonments, "the burst was dropped, so its running total is stale too")

        // A late event from the retired player doesn't reach the accumulator.
        accumulator.seekBy(10.seconds)
        oldPlayer.tryEmit(4.minutes)
        runCurrent()
        assertNotNull(accumulator.pendingPosition)
        assertEquals(1, abandonments)

        emit(newPlayer, 6.minutes)
        assertNull(accumulator.pendingPosition, "the new player is what it listens to now")
        assertEquals(2, abandonments)
        accumulator.dispose()
    }
}
