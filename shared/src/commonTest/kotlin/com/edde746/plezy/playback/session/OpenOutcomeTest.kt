package com.edde746.plezy.playback.session

import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

class OpenOutcomeTest {
    private var deadlines = 0

    private fun TestScope.outcome(deadline: Duration? = null) = OpenOutcome(backgroundScope, deadline) { deadlines++ }

    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun aFailedLoadSettlesEveryWaiterFalseWithoutThrowing() = runTest {
        val outcome = outcome()
        outcome.onFileStarted()
        outcome.onFailed()
        assertFalse(outcome.fileLoaded.await())
        assertFalse(outcome.firstFrame.await())
        assertTrue(outcome.failed)
        assertFalse(outcome.aborted)
    }

    @Test
    fun abortSettlesEveryPendingWaiterAndIsIdempotent() = runTest {
        val outcome = outcome()
        outcome.abort("fatal player error")
        outcome.abort("session closed")
        assertFalse(outcome.fileLoaded.await())
        assertFalse(outcome.firstFrame.await())
        assertEquals("fatal player error", outcome.abortReason)
        assertTrue(outcome.settled)
        outcome.onFileStarted()
        outcome.onFileLoaded()
        outcome.onFirstFrame()
        assertFalse(outcome.firstFrame.await(), "nothing revives a settled open")
    }

    @Test
    fun successResolvesTrueAndALaterFailureDoesntFlipIt() = runTest {
        val outcome = outcome()
        outcome.onFileStarted()
        outcome.onFileLoaded()
        assertTrue(outcome.fileLoaded.await())
        assertFalse(outcome.settled)
        outcome.onFailed()
        assertTrue(outcome.fileLoaded.await(), "the loaded verdict stands")
        assertFalse(outcome.firstFrame.await())

        val rendered = outcome()
        rendered.onFileStarted()
        rendered.onFirstFrame()
        assertTrue(rendered.fileLoaded.await())
        assertTrue(rendered.firstFrame.await())
        rendered.abort("too late")
        assertFalse(rendered.aborted)
        assertTrue(rendered.firstFrame.await())
    }

    @Test
    fun signalsBeforeThisAttemptStartsItsFileAreThePreviousFiles() = runTest {
        val outcome = outcome()
        outcome.onFirstFrame()
        outcome.onFileLoaded()
        outcome.onFailed()
        assertFalse(outcome.settled)
        assertFalse(outcome.failed)
        outcome.onFileStarted()
        outcome.onFileLoaded()
        outcome.onFirstFrame()
        assertTrue(outcome.firstFrame.await())
    }

    @Test
    fun theDeadlineCountsFromTheLoadStartAndTellsTheOwnerAfterTheWaitersSettled() = runTest {
        val outcome = outcome(30.seconds)
        elapse(1.minutes)
        assertFalse(outcome.settled, "no clock before the load starts")
        outcome.onFileStarted()
        elapse(29.seconds)
        assertFalse(outcome.settled)
        outcome.onFileStarted()
        elapse(29.seconds)
        assertFalse(outcome.settled, "a reopen restarts the budget")
        assertEquals(0, deadlines)
        elapse(1.seconds)
        assertFalse(outcome.firstFrame.await())
        assertTrue(outcome.aborted)
        assertEquals("no load progress for 30s", outcome.abortReason)
        assertEquals(1, deadlines)
    }

    @Test
    fun aSlowLoadThatKeepsProgressingOutlivesTheDeadlineAndAStallAfterItFails() = runTest {
        val outcome = outcome(30.seconds)
        outcome.onProgress()
        elapse(1.minutes)
        assertFalse(outcome.settled, "the previous file's progress starts no clock")
        outcome.onFileStarted()
        elapse(29.seconds)
        outcome.onFileLoaded()
        elapse(29.seconds)
        repeat(8) {
            outcome.onProgress()
            elapse(15.seconds)
        }
        assertFalse(outcome.settled)
        assertEquals(0, deadlines)
        elapse(15.seconds)
        assertTrue(outcome.aborted)
        assertEquals(1, deadlines)
    }

    @Test
    fun aDeadlineTheEngineBeatsNeverFires() = runTest {
        val outcome = outcome(30.seconds)
        outcome.onFileStarted()
        outcome.onFailed()
        elapse(1.minutes)
        assertTrue(outcome.failed)
        assertEquals(0, deadlines)

        val rendered = outcome(30.seconds)
        rendered.onFileStarted()
        rendered.onFirstFrame()
        elapse(1.minutes)
        assertTrue(rendered.settled)
        assertEquals(0, deadlines)
    }
}
