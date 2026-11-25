@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.model.MediaSubtitleTrack
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration

/** Replacement failure deferral, the subtitle re-map across tunes, and the live clock's calibration and anchoring. */
class LiveSessionStateTest {
    private fun track(id: Int, index: Int? = null, languageCode: String? = null) =
        MediaSubtitleTrack(id = id, index = index, languageCode = languageCode, selected = false, forced = false)

    // Replacement failure deferral

    @Test
    fun aFailureOfTheStreamBeingReplacedIsNotDeferred() {
        val state = LiveSessionState()
        val token = state.beginReplacement()
        assertFalse(state.deferReplacementFailure(), "the zap still tunes: the old stream is the one failing")
        state.streamGeneration++
        assertFalse(state.endReplacement(token, committed = true))
    }

    @Test
    fun aReplacementStreamsFailureRunsOnceTheReplacementCommits() {
        val state = LiveSessionState()
        val token = state.beginReplacement()
        state.streamGeneration++
        assertTrue(state.deferReplacementFailure())
        assertTrue(state.endReplacement(token, committed = true))
        assertFalse(state.endReplacement(token, committed = true), "consumed: a second end doesn't replay it")
    }

    @Test
    fun anUncommittedReplacementDropsItsParkedFailure() {
        val state = LiveSessionState()
        val token = state.beginReplacement()
        state.streamGeneration++
        assertTrue(state.deferReplacementFailure())
        assertFalse(state.endReplacement(token, committed = false))
    }

    @Test
    fun aFailureIsDroppedWhenANewerStreamReplacedTheFailedOne() {
        val state = LiveSessionState()
        val token = state.beginReplacement()
        state.streamGeneration++
        assertTrue(state.deferReplacementFailure())
        state.streamGeneration++
        assertFalse(state.endReplacement(token, committed = true))
    }

    @Test
    fun aSupersededReplacementCannotEndTheNewerOne() {
        val state = LiveSessionState()
        val stale = state.beginReplacement()
        val current = state.beginReplacement()
        state.streamGeneration++
        assertTrue(state.deferReplacementFailure())
        assertFalse(state.endReplacement(stale, committed = true))
        assertTrue(state.endReplacement(current, committed = true))
    }

    @Test
    fun nothingIsDeferredOutsideAReplacement() {
        val state = LiveSessionState()
        state.streamGeneration++
        assertFalse(state.deferReplacementFailure())
    }

    // Subtitle re-map

    @Test
    fun noPreviousSelectionStaysOff() {
        assertNull(LiveSessionState.remapSubtitleSelection(listOf(track(1)), null))
    }

    @Test
    fun theSameStreamIdWins() {
        val tracks = listOf(track(1, languageCode = "fin"), track(2, languageCode = "fin"))
        assertEquals(2, LiveSessionState.remapSubtitleSelection(tracks, track(2, languageCode = "fin"))?.id)
    }

    @Test
    fun aRetuneFallsBackToLanguageAndStreamIndex() {
        val tracks = listOf(track(101, 3, "fin"), track(102, 4, "fin"), track(103, 5, "swe"))
        assertEquals(102, LiveSessionState.remapSubtitleSelection(tracks, track(92, 4, "fin"))?.id)
    }

    @Test
    fun languageAloneMatchesWhenTheIndexMoved() {
        val tracks = listOf(track(101, 3, "swe"), track(102, 4, "fin"))
        assertEquals(102, LiveSessionState.remapSubtitleSelection(tracks, track(92, 9, "fin"))?.id)
    }

    @Test
    fun noEquivalentTrackDropsTheSelection() {
        assertNull(LiveSessionState.remapSubtitleSelection(listOf(track(101, 3, "swe")), track(92, 4, "fin")))
    }

    @Test
    fun adoptingASessionClearsTheSubtitleChoice() {
        val state = LiveSessionState()
        state.selectedSubtitle = track(92, languageCode = "fin")
        state.adoptSession(FakeLivePlaybackSession())
        assertNull(state.selectedSubtitle)
    }

    // Source clock

    @Test
    fun aNonZeroSourceBaselineIsSubtractedFromLaterPositions() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        assertEquals(1093L, state.epochForPosition(52.0))
        assertTrue(state.bindClockOpen(generation, 7))
        assertTrue(state.calibrateClockSource(7, 47.0))
        assertTrue(result.await())
        assertEquals(1046.0, state.streamStartEpoch)
        assertEquals(1098L, state.epochForPosition(52.0))
    }

    @Test
    fun aSupersededSourceCannotCalibrateTheLatestOpen() = runTest {
        val state = LiveSessionState()
        val first = state.beginClockOpen(1085)
        val firstResult = state.clockOpenResult(first)
        val second = state.beginClockOpen(1070)
        val secondResult = state.clockOpenResult(second)
        assertFalse(state.bindClockOpen(first, 11))
        assertTrue(state.bindClockOpen(second, 12))
        assertFalse(state.calibrateClockSource(11, 52.0))
        assertTrue(state.calibrateClockSource(12, 40.0))
        assertFalse(firstResult.await())
        assertTrue(secondResult.await())
        assertEquals(1075L, state.epochForPosition(45.0))
    }

    @Test
    fun readinessThatBeatsTheLoadReplyCalibratesOnBind() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        assertFalse(state.calibrateClockSource(7, 47.0))
        assertEquals(1093L, state.epochForPosition(52.0))
        assertTrue(state.bindClockOpen(generation, 7))
        assertTrue(result.await())
        assertEquals(1046.0, state.streamStartEpoch)
        assertEquals(1098L, state.epochForPosition(52.0))
    }

    @Test
    fun aFailureThatBeatsTheLoadReplyFailsTheOpenOnBind() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        state.failClockSource(7)
        assertFalse(state.bindClockOpen(generation, 7))
        assertFalse(result.await())
        assertNull(state.pendingStreamEpoch)
        assertFalse(state.calibrateClockSource(7, 47.0))
    }

    @Test
    fun aRejectedFirstLoadCannotClaimTheSecondSeeksSource() = runTest {
        val state = LiveSessionState().apply { streamStartEpoch = 1000.0 }
        val first = state.beginClockOpen(1085)
        val firstResult = state.clockOpenResult(first)
        val second = state.beginClockOpen(1075)
        val secondResult = state.clockOpenResult(second)
        state.calibrateClockSource(12, 40.0)
        state.failClockOpen(first)
        assertFalse(firstResult.await())
        assertEquals(1075L, state.epochForPosition(40.0))
        assertTrue(state.bindClockOpen(second, 12))
        assertTrue(secondResult.await())
        assertEquals(1035.0, state.streamStartEpoch)
        assertEquals(1080L, state.epochForPosition(45.0))
    }

    @Test
    fun anUnregisteredOpenIsInvisibleToClockBinding() = runTest {
        val state = LiveSessionState()
        val first = state.beginClockOpen(1085)
        assertTrue(state.bindClockOpen(first, 11))
        state.calibrateClockSource(11, 10.0)
        assertEquals(1075.0, state.streamStartEpoch)
        // An open at the edge registers no clock generation: its source reports and is never claimed.
        state.calibrateClockSource(12, 3.0)
        assertEquals(1075.0, state.streamStartEpoch)

        val second = state.beginClockOpen(1070)
        val secondResult = state.clockOpenResult(second)
        assertTrue(state.bindClockOpen(second, 13))
        assertEquals(1070L, state.epochForPosition(5.0))
        assertTrue(state.calibrateClockSource(13, 40.0))
        assertTrue(secondResult.await())
        assertEquals(1030.0, state.streamStartEpoch)
    }

    @Test
    fun unclaimedSourceReportsAreBoundedToTheMostRecent() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        state.calibrateClockSource(1, 47.0)
        for (source in 2L..9L) state.calibrateClockSource(source, 0.0)
        assertTrue(state.bindClockOpen(generation, 1))
        assertEquals(1093L, state.epochForPosition(52.0))
        assertTrue(state.calibrateClockSource(1, 47.0))
        assertTrue(result.await())
    }

    @Test
    fun aCalibrationTimeoutKeepsTheTargetUntilLateReadiness() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        state.bindClockOpen(generation, 7)
        state.timeoutClockOpen(generation)
        assertFalse(result.await())
        assertEquals(1093L, state.epochForPosition(52.0))
        assertTrue(state.calibrateClockSource(7, 47.0))
        assertEquals(1098L, state.epochForPosition(52.0))
    }

    @Test
    fun aTimedOutOpenStillBindsWhenItsLoadReplyComesLate() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        state.timeoutClockOpen(generation)
        assertFalse(result.await())
        state.calibrateClockSource(7, 47.0)
        assertEquals(1093L, state.epochForPosition(52.0))
        assertTrue(state.bindClockOpen(generation, 7))
        assertEquals(1098L, state.epochForPosition(52.0))
    }

    @Test
    fun aZeroBasedSourceKeepsTheEpochMapping() = runTest {
        val state = LiveSessionState()
        val generation = state.beginClockOpen(1093)
        val result = state.clockOpenResult(generation)
        state.bindClockOpen(generation, 7)
        state.calibrateClockSource(7, 0.0)
        assertTrue(result.await())
        assertEquals(1098L, state.epochForPosition(5.0))
    }

    @Test
    fun twoBackwardSkipsCompoundFromTheCalibratedSourceClock() = runTest {
        val state = LiveSessionState().apply { streamStartEpoch = 1000.0 }
        var position = 100.0
        var sourceId = 0L
        val requested = mutableListOf<Long>()
        val accumulator = LiveSeekAccumulator(
            scope = backgroundScope,
            seek = { target ->
                requested += target
                val generation = state.beginClockOpen(target)
                val result = state.clockOpenResult(generation)
                val source = ++sourceId
                state.bindClockOpen(generation, source)
                if (requested.size == 1) {
                    state.calibrateClockSource(source, 52.0)
                    position = 57.0
                } else {
                    state.calibrateClockSource(source, 40.0)
                    position = 45.0
                }
                result.await()
            },
            currentEpoch = { state.epochForPosition(position) },
            bounds = { LiveSeekBounds(0, 2000) },
            debounce = Duration.ZERO,
        )
        accumulator.seekBy(-15)
        runCurrent()
        assertEquals(listOf(1085L), requested)
        assertEquals(1090L, state.epochForPosition(position))
        accumulator.seekBy(-15)
        runCurrent()
        assertEquals(listOf(1085L, 1075L), requested)
        assertEquals(1080L, state.epochForPosition(position))
    }

    // Stream anchor

    private val capture = CaptureBuffer(1000.0, 0.0, 40.0)

    @Test
    fun anOpenAtTheEdgeAnchorsOnTheCaptureEdgeNotTheWallClock() {
        val state = LiveSessionState()
        state.markStreamRestartedAtLiveEdge(capture)
        assertEquals(1040.0, state.streamStartEpoch)
        assertTrue(state.atLiveEdge)
        assertEquals(1050L, state.epochForPosition(10.0))
    }

    @Test
    fun aHeartbeatReanchorsTheClockOnThePlaybackTranscodeOrigin() {
        val state = LiveSessionState().apply { markStreamRestartedAtLiveEdge(capture) }
        val playback = CaptureBuffer(1027.5, 0.033, 12.0)
        assertTrue(state.adoptPlaybackStreamOrigin(playback, state.streamGeneration))
        assertEquals(1048L, state.epochForPosition(20.0))
        assertFalse(state.adoptPlaybackStreamOrigin(playback, state.streamGeneration))
    }

    @Test
    fun aHeartbeatSentBeforeAReopenCannotAnchorTheReplacementStream() = runTest {
        val state = LiveSessionState().apply { streamStartEpoch = 1040.0 }
        val stale = state.streamGeneration
        state.streamGeneration++
        val generation = state.beginClockOpen(990)
        val result = state.clockOpenResult(generation)
        state.bindClockOpen(generation, 3)
        state.calibrateClockSource(3, 0.0)
        assertTrue(result.await())
        assertFalse(state.adoptPlaybackStreamOrigin(CaptureBuffer(1027.5, 0.0, 60.0), stale))
        assertEquals(990L, state.epochForPosition(0.0))
    }

    @Test
    fun aHeartbeatCannotReanchorWhileAnOpenCalibrates() {
        val state = LiveSessionState().apply { streamStartEpoch = 1040.0 }
        state.beginClockOpen(990)
        assertFalse(state.adoptPlaybackStreamOrigin(CaptureBuffer(1027.5, 0.0, 60.0), state.streamGeneration))
        assertEquals(990L, state.epochForPosition(5.0))
    }
}
