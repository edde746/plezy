package com.edde746.plezy.playback.queue

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class SleepTimerTest {
    private class Counts {
        var prompts = 0
        var completions = 0
    }

    /** A timer on the test's clock, with its prompts and completions counted as they emit. */
    private fun TestScope.sleepTimer(counts: Counts = Counts()): Pair<SleepTimer, Counts> {
        val timer = SleepTimer(backgroundScope, testScheduler.timeSource)
        val dispatcher = UnconfinedTestDispatcher(testScheduler)
        backgroundScope.launch(dispatcher) { timer.prompts.collect { counts.prompts++ } }
        backgroundScope.launch(dispatcher) { timer.completed.collect { counts.completions++ } }
        return timer to counts
    }

    private fun TestScope.advance(by: kotlin.time.Duration) {
        advanceTimeBy(by)
        runCurrent()
    }

    @Test
    fun durationExpiryEmitsOnePromptWithoutCompletingPlayback() = runTest {
        val (timer, counts) = sleepTimer()
        var pauses = 0
        timer.bindPlayback(Any()) { pauses++ }
        timer.start(3.seconds)

        advanceTimeBy(2.seconds)
        assertEquals(1.seconds, timer.remaining)
        assertEquals(0, counts.prompts)

        advanceTimeBy(999.milliseconds)
        assertEquals(1.milliseconds, timer.remaining)
        assertEquals(0, counts.prompts)

        advance(1.milliseconds)
        assertEquals(1, counts.prompts)
        assertEquals(0, pauses)
        assertFalse(timer.state.value.active)
        assertNull(timer.remaining)

        advance(1.minutes)
        assertEquals(1, counts.prompts)
    }

    @Test
    fun replacementKeepsEndOfVideoArmedAndAStaleReleaseCannotDetachItsSuccessor() = runTest {
        val (timer, counts) = sleepTimer()
        val outgoing = Any()
        val successor = Any()
        val paused = mutableListOf<Any>()
        timer.bindPlayback(outgoing) { paused += outgoing }
        timer.armEndOfVideo()

        timer.bindPlayback(successor) { paused += successor }
        timer.unbindPlayback(outgoing)
        timer.restartIfNeeded()
        assertTrue(timer.state.value.endOfVideo)

        timer.notifyVideoCompleted()
        timer.notifyVideoCompleted()
        runCurrent()
        assertEquals(listOf(successor), paused)
        assertEquals(1, counts.completions)
        assertFalse(timer.state.value.active)
    }

    @Test
    fun replacementPreservesTheCountdownAndItsBindingSurvivesDurationCompletion() = runTest {
        val (timer, counts) = sleepTimer()
        val outgoing = Any()
        val successor = Any()
        val paused = mutableListOf<Any>()
        timer.bindPlayback(outgoing) { paused += outgoing }
        timer.start(6.seconds)
        advanceTimeBy(2.seconds)

        timer.bindPlayback(successor) { paused += successor }
        timer.unbindPlayback(outgoing)
        timer.restartIfNeeded()
        assertEquals(4.seconds, timer.remaining, "the deadline is untouched")
        assertFalse(timer.state.value.endOfVideo)

        advanceTimeBy(3.seconds)
        assertEquals(0, counts.prompts)
        advance(1.seconds)
        assertEquals(1, counts.prompts)
        assertTrue(paused.isEmpty())

        // Duration expiry prompts instead of pausing. A later stop selection still targets the successor, without
        // binding a callback again.
        timer.armEndOfVideo()
        timer.notifyVideoCompleted()
        assertEquals(listOf(successor), paused)
    }

    @Test
    fun extensionDelaysThePromptButRestartUsesTheSelectedDurationAndKeepsPlaybackBound() = runTest {
        val (timer, counts) = sleepTimer()
        var pauses = 0
        timer.bindPlayback(Any()) { pauses++ }
        timer.start(2.seconds)
        timer.extend(2.seconds)

        advanceTimeBy(2.seconds)
        assertEquals(0, counts.prompts)
        assertEquals(2.seconds, timer.remaining)
        assertEquals(2.seconds, timer.state.value.duration, "the duration chosen is unchanged by the extension")
        advance(2.seconds)
        assertEquals(1, counts.prompts)

        timer.restart()
        assertEquals(2.seconds, timer.remaining)
        advance(2.seconds)
        assertEquals(2, counts.prompts)
        assertEquals(0, pauses)

        timer.armEndOfVideo()
        timer.notifyVideoCompleted()
        assertEquals(1, pauses)
    }

    @Test
    fun ordinaryExitRestartsADurationTimerOnceWithItsOriginalSelectionOnReentry() = runTest {
        val (timer, counts) = sleepTimer()
        val outgoing = Any()
        val successor = Any()
        val paused = mutableListOf<Any>()
        timer.bindPlayback(outgoing) { paused += outgoing }
        timer.start(4.seconds)
        timer.extend(2.seconds)
        advanceTimeBy(2.seconds)
        timer.unbindPlayback(outgoing)
        advance(6.seconds)
        assertEquals(1, counts.prompts)

        timer.bindPlayback(successor) { paused += successor }
        timer.restartIfNeeded()
        assertEquals(4.seconds, timer.remaining)
        advanceTimeBy(1.seconds)
        timer.restartIfNeeded()
        assertEquals(3.seconds, timer.remaining)
        advance(3.seconds)
        assertEquals(2, counts.prompts)
        assertTrue(paused.isEmpty())

        timer.armEndOfVideo()
        timer.notifyVideoCompleted()
        assertEquals(listOf(successor), paused)
    }

    @Test
    fun exitingWhileTheDurationPromptIsPendingRestartsOnTheNextPlayback() = runTest {
        val (timer, counts) = sleepTimer()
        val outgoing = Any()
        timer.bindPlayback(outgoing) {}
        timer.start(2.seconds)
        advance(2.seconds)
        assertEquals(1, counts.prompts)
        assertFalse(timer.state.value.active)

        timer.unbindPlayback(outgoing)
        timer.bindPlayback(Any()) {}
        timer.restartIfNeeded()
        advance(1.seconds)
        assertEquals(1, counts.prompts)
        advance(1.seconds)
        assertEquals(2, counts.prompts)
    }

    @Test
    fun ordinaryExitReleasesPlaybackAndReentryRestoresEndOfVideoWithAFreshOwner() = runTest {
        val (timer, _) = sleepTimer()
        val outgoing = Any()
        val successor = Any()
        val paused = mutableListOf<Any>()
        timer.bindPlayback(outgoing) { paused += outgoing }
        timer.armEndOfVideo()
        timer.unbindPlayback(outgoing)

        // Completion while no playback is bound does not reach the old player.
        timer.notifyVideoCompleted()
        assertTrue(paused.isEmpty())
        timer.bindPlayback(successor) { paused += successor }
        timer.restartIfNeeded()
        assertTrue(timer.state.value.endOfVideo)
        timer.notifyVideoCompleted()
        assertEquals(listOf(successor), paused)
    }

    @Test
    fun cancellingADurationPreventsItsPromptAndRestartWithoutDetachingPlayback() = runTest {
        val (timer, counts) = sleepTimer()
        var pauses = 0
        timer.bindPlayback(Any()) { pauses++ }
        timer.start(2.seconds)
        advanceTimeBy(1.seconds)
        timer.cancel()
        timer.restart()
        timer.restartIfNeeded()
        advance(1.minutes)
        assertEquals(0, counts.prompts)
        assertFalse(timer.state.value.active)

        timer.armEndOfVideo()
        timer.notifyVideoCompleted()
        assertEquals(1, pauses)
    }

    @Test
    fun cancellingAPendingEndOfVideoRestartCannotReviveTheOldMode() = runTest {
        val (timer, counts) = sleepTimer()
        val outgoing = Any()
        var pauses = 0
        timer.bindPlayback(outgoing) { pauses++ }
        timer.armEndOfVideo()
        timer.unbindPlayback(outgoing)
        timer.notifyVideoCompleted()
        timer.cancel()

        timer.bindPlayback(Any()) { pauses++ }
        timer.restartIfNeeded()
        timer.notifyVideoCompleted()
        assertFalse(timer.state.value.active)
        assertEquals(0, pauses)

        timer.start(2.seconds)
        timer.restartIfNeeded()
        timer.notifyVideoCompleted()
        advance(2.seconds)
        assertEquals(1, counts.prompts)
        assertEquals(0, pauses)
    }

    @Test
    fun changingDurationCancelsTheEarlierDeadlineRatherThanAddingASecondTimer() = runTest {
        val (timer, counts) = sleepTimer()
        timer.start(2.seconds)
        advanceTimeBy(1.seconds)
        timer.start(5.seconds)

        advance(1.seconds)
        assertEquals(0, counts.prompts)
        advance(4.seconds)
        assertEquals(1, counts.prompts)
        advance(5.seconds)
        assertEquals(1, counts.prompts)
    }

    @Test
    fun switchingTimerModesOnlyRespondsToTheSelectedCompletionTrigger() = runTest {
        val (timer, counts) = sleepTimer()
        var pauses = 0
        timer.bindPlayback(Any()) { pauses++ }
        timer.start(2.seconds)
        timer.armEndOfVideo()
        advance(3.seconds)
        assertEquals(0, counts.prompts)
        timer.notifyVideoCompleted()
        assertEquals(1, pauses)

        timer.armEndOfVideo()
        timer.start(2.seconds)
        timer.notifyVideoCompleted()
        assertEquals(1, pauses)
        advance(2.seconds)
        assertEquals(1, counts.prompts)
    }

    @Test
    fun aDeadlineMovedIntoThePastAsksAtTheNextSecondAndKeepWatchingRestartsTheOriginalDuration() = runTest {
        val (timer, counts) = sleepTimer()
        timer.start(30.minutes)
        timer.extend((-31).minutes)
        advance(1.seconds)

        // The question consumed the countdown: the timer waits on the answer with its duration kept.
        assertEquals(1, counts.prompts)
        assertFalse(timer.state.value.active)
        assertEquals(30.minutes, timer.state.value.duration)

        // Keep watching (Continue, or Back on the question).
        timer.restart()
        assertTrue(timer.state.value.active)
        assertEquals(30.minutes, timer.remaining)
        assertEquals(30.minutes, timer.state.value.duration)
    }

    @Test
    fun theStateShowsTheTimeLeftEachSecond() = runTest {
        val (timer, _) = sleepTimer()
        timer.start(1.minutes)
        assertEquals(SleepTimer.State(duration = 1.minutes, remaining = 1.minutes), timer.state.value)
        advance(1.seconds)
        assertEquals(59.seconds, timer.state.value.remaining)
        timer.cancel()
        assertEquals(SleepTimer.State(), timer.state.value)
    }
}
