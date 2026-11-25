package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.servers.QueueNavigationStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CompletionLatchTest {
    private fun CompletionLatch.tick(positionMillis: Long, durationMillis: Long = 60_000, promptVisible: Boolean = false, countdownActive: Boolean = false) =
        classifyPosition(positionMillis, durationMillis, promptVisible, countdownActive)

    @Test
    fun positionTicksNeverLatchByThemselves() {
        val latch = CompletionLatch()
        latch.tick(58_000)
        latch.tick(59_200)
        latch.tick(60_000)
        assertFalse(latch.triggered)
    }

    @Test
    fun staysLatchedWhileParkedAtTheEnd() {
        val latch = CompletionLatch().apply { latch() }
        latch.tick(59_400)
        assertTrue(latch.triggered)
    }

    @Test
    fun ignoresTicksWithNoKnownDuration() {
        val latch = CompletionLatch().apply { latch() }
        latch.tick(59_500, durationMillis = 0)
        assertTrue(latch.triggered)
    }

    @Test
    fun reArmsOnlyAfterMovingBackPastTheReArmWindow() {
        val latch = CompletionLatch().apply { latch() }
        latch.tick(58_500)
        assertTrue(latch.triggered, "inside the window: no flap")
        latch.tick(50_000)
        assertFalse(latch.triggered, "clearly out of the end region")
        latch.tick(59_500)
        assertFalse(latch.triggered, "back at the end stays quiet until the engine reports the end")
    }

    @Test
    fun refusesToReArmWhileAPromptOrCountdownIsActive() {
        val latch = CompletionLatch().apply { latch() }
        latch.tick(50_000, promptVisible = true)
        assertTrue(latch.triggered)
        latch.tick(50_000, countdownActive = true)
        assertTrue(latch.triggered)
        latch.tick(50_000)
        assertFalse(latch.triggered)
    }

    @Test
    fun resetClearsUnconditionally() {
        val latch = CompletionLatch().apply { latch() }
        latch.reset()
        assertFalse(latch.triggered)
    }

    @Test
    fun rearmIfClearHonoursPromptAndCountdown() {
        val latch = CompletionLatch().apply { latch() }
        latch.rearmIfClear(promptVisible = true, countdownActive = false)
        assertTrue(latch.triggered)
        latch.rearmIfClear(promptVisible = false, countdownActive = false)
        assertFalse(latch.triggered)
    }

    @Test
    fun theEndPresentsAResolvedNextItem() {
        assertEquals(CompletionAction.PRESENT_NEXT, completionNavigationAction(true, QueueNavigationStatus.FOUND))
    }

    @Test
    fun aQueueWhoseLookupFailedIsLookedUpAgainInsteadOfLeaving() {
        assertEquals(CompletionAction.RETRY_ADJACENT, completionNavigationAction(false, QueueNavigationStatus.FAILED))
    }

    @Test
    fun aStandaloneVideoOrTheQueuesEndLeaves() {
        assertEquals(CompletionAction.EXIT, completionNavigationAction(false, QueueNavigationStatus.UNAVAILABLE))
        assertEquals(CompletionAction.EXIT, completionNavigationAction(false, QueueNavigationStatus.BOUNDARY))
    }

    private fun classify(positionMillis: Long, playerDurationMillis: Long = 0, metadataDurationMillis: Long? = null) =
        classifyEofSignal(positionMillis, playerDurationMillis, metadataDurationMillis)

    @Test
    fun aMidFileEndIsSpurious() {
        assertEquals(EofSignal.SPURIOUS, classify(600_000, 2_520_000, 2_520_000))
    }

    @Test
    fun theServersDurationAnchorsWhenTheEnginesTracksTheCache() {
        assertEquals(EofSignal.SPURIOUS, classify(600_000, 600_000, 2_520_000))
    }

    @Test
    fun anEndAtOrSlightlyShortOfTheDurationIsGenuine() {
        assertEquals(EofSignal.GENUINE, classify(2_520_000, 2_520_000, 2_520_000))
        assertEquals(EofSignal.GENUINE, classify(2_517_000, 2_517_000, 2_520_000))
    }

    @Test
    fun theEnginesDurationWinsWhenTheServerUnderstatesTheFile() {
        assertEquals(EofSignal.GENUINE, classify(2_520_000, 2_520_000, 2_400_000))
    }

    @Test
    fun theServersDurationAloneClassifiesWhenTheEngineHasNone() {
        assertEquals(EofSignal.SPURIOUS, classify(600_000, metadataDurationMillis = 2_520_000))
        assertEquals(EofSignal.GENUINE, classify(2_515_000, metadataDurationMillis = 2_520_000))
    }

    @Test
    fun noDurationIsUnknown() {
        assertEquals(EofSignal.UNKNOWN, classify(600_000))
        assertEquals(EofSignal.UNKNOWN, classify(600_000, metadataDurationMillis = 0))
    }

    @Test
    fun theToleranceBoundaryIsInclusive() {
        assertEquals(EofSignal.GENUINE, classify(2_520_000 - SPURIOUS_EOF_TOLERANCE_MILLIS, 2_520_000))
        assertEquals(EofSignal.SPURIOUS, classify(2_520_000 - SPURIOUS_EOF_TOLERANCE_MILLIS - 1, 2_520_000))
    }

    /** An engine that runs past its duration and reports the end pinned at it: the next episode shows. */
    @Test
    fun anEndReportedAtTheDurationCompletesTheItem() {
        val duration = 2_623_668L
        assertEquals(EofSignal.GENUINE, classify(duration, duration, duration))
        assertEquals(EofSignal.SPURIOUS, classify(1_200_000, duration, duration), "the same end from a stale mid-file position")
    }

    private fun retry(
        wasAtCompletion: Boolean = true,
        failureReason: PlaybackFailureReason? = PlaybackFailureReason.SERVER_UNAVAILABLE,
        hasNext: Boolean = true,
        autoPlayEnabled: Boolean = true,
        inWatchTogether: Boolean = false,
        autoRetriesUsed: Int = 0,
    ) = playNextRetryPresentation(wasAtCompletion, failureReason, hasNext, autoPlayEnabled, inWatchTogether, autoRetriesUsed)

    @Test
    fun aServerBlipAtTheEndShowsUpNextAgainCountingDown() {
        assertEquals(PlayNextRetry.COUNTDOWN, retry())
    }

    @Test
    fun aNextPressMidEpisodeKeepsThePlainFailure() {
        assertEquals(PlayNextRetry.NONE, retry(wasAtCompletion = false))
    }

    @Test
    fun otherFailuresNeverRetryLoop() {
        for (reason in PlaybackFailureReason.entries - PlaybackFailureReason.SERVER_UNAVAILABLE) {
            assertEquals(PlayNextRetry.NONE, retry(failureReason = reason), "$reason")
        }
        assertEquals(PlayNextRetry.NONE, retry(failureReason = null))
    }

    @Test
    fun noNextEpisodeHasNothingToShow() {
        assertEquals(PlayNextRetry.NONE, retry(hasNext = false))
    }

    @Test
    fun theCountdownBudgetRunsOutIntoAManualPrompt() {
        assertEquals(PlayNextRetry.COUNTDOWN, retry(autoRetriesUsed = MAX_PLAY_NEXT_TRANSIENT_RETRIES - 1))
        assertEquals(PlayNextRetry.MANUAL, retry(autoRetriesUsed = MAX_PLAY_NEXT_TRANSIENT_RETRIES))
    }

    @Test
    fun autoPlayOffOrWatchTogetherShowsThePromptWithoutACountdown() {
        assertEquals(PlayNextRetry.MANUAL, retry(autoPlayEnabled = false))
        assertEquals(PlayNextRetry.MANUAL, retry(inWatchTogether = true))
    }
}
