package com.edde746.plezy.livetv.playback

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** One live recovery attempt: failures are reported once, a recovered session is adopted or released, never both. */
class LiveStreamRetryTest {
    private enum class Stage { RECOVER, LOOKUP, OPEN }

    private class Harness(val failAt: Stage? = null) {
        var staleAt: Stage? = null
        val calls = mutableListOf<Stage>()
        val failures = mutableListOf<Exception>()
        var current = true
        var finished = false
        var adopted = false
        var discarded = false
        var activeSession: Any? = null
        var recoveredSession: Any? = null

        suspend fun run(): LiveStreamRetryResult = runLiveStreamRetry(
            recover = { stage(Stage.RECOVER) { recoveredSession ?: Any() } },
            lookupStreamUrl = { stage(Stage.LOOKUP) { "https://example.com/live" } },
            open = { stage(Stage.OPEN) {} },
            isCurrent = { current },
            adoptSession = { adopted = true },
            currentSession = { activeSession },
            reportFailure = { failures += it },
            discardSession = { discarded = true },
            onFinished = { finished = true },
        )

        private fun <T> stage(stage: Stage, value: () -> T): T {
            calls += stage
            if (staleAt == stage) current = false
            if (failAt == stage) throw IllegalStateException("$stage failed")
            return value()
        }
    }

    @Test
    fun aRecoverFailureIsReportedAndFinishesTheRetry() = runTest {
        val harness = Harness(failAt = Stage.RECOVER)
        assertEquals(LiveStreamRetryResult.FAILED, harness.run())
        assertEquals(1, harness.failures.size)
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertFalse(harness.discarded)
    }

    @Test
    fun aStreamUrlFailureIsReportedAndReleasesTheRecoveredSession() = runTest {
        val harness = Harness(failAt = Stage.LOOKUP)
        assertEquals(LiveStreamRetryResult.FAILED, harness.run())
        assertEquals(1, harness.failures.size)
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertTrue(harness.discarded)
    }

    @Test
    fun anOpenFailureIsReportedAndReleasesTheRecoveredSession() = runTest {
        val harness = Harness(failAt = Stage.OPEN)
        assertEquals(LiveStreamRetryResult.FAILED, harness.run())
        assertEquals(1, harness.failures.size)
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertTrue(harness.discarded)
    }

    @Test
    fun theRecoveredSessionIsAdoptedAfterASuccessfulOpen() = runTest {
        val harness = Harness()
        assertEquals(LiveStreamRetryResult.SUCCEEDED, harness.run())
        assertEquals(listOf(Stage.RECOVER, Stage.LOOKUP, Stage.OPEN), harness.calls)
        assertTrue(harness.failures.isEmpty())
        assertTrue(harness.finished)
        assertTrue(harness.adopted)
        assertFalse(harness.discarded)
    }

    @Test
    fun aStaleAttemptDoesNotReportItsFailure() = runTest {
        val harness = Harness(failAt = Stage.LOOKUP).apply { staleAt = Stage.LOOKUP }
        assertEquals(LiveStreamRetryResult.STALE, harness.run())
        assertTrue(harness.failures.isEmpty())
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertTrue(harness.discarded)
    }

    @Test
    fun aFailedRetryKeepsARecoveredSessionThatIsStillCurrent() = runTest {
        // Jellyfin's recover returns the receiver: releasing it would end the session that keeps playing.
        val session = Any()
        val harness = Harness(failAt = Stage.OPEN).apply {
            activeSession = session
            recoveredSession = session
        }
        assertEquals(LiveStreamRetryResult.FAILED, harness.run())
        assertEquals(1, harness.failures.size)
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertFalse(harness.discarded)
    }

    @Test
    fun aFailedRetryReleasesARecoveredSessionOtherThanTheCurrentOne() = runTest {
        val harness = Harness(failAt = Stage.OPEN).apply {
            activeSession = Any()
            recoveredSession = Any()
        }
        assertEquals(LiveStreamRetryResult.FAILED, harness.run())
        assertEquals(1, harness.failures.size)
        assertTrue(harness.finished)
        assertFalse(harness.adopted)
        assertTrue(harness.discarded)
    }
}
