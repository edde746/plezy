package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.playback.session.PlaybackFailureAction.FATAL
import com.edde746.plezy.playback.session.PlaybackFailureAction.IGNORE
import com.edde746.plezy.playback.session.PlaybackFailureAction.LIVE_INTERRUPTED
import com.edde746.plezy.playback.session.PlaybackFailureAction.LIVE_RETRY
import com.edde746.plezy.playback.session.PlaybackFailureAction.MEDIA_UNREADABLE
import com.edde746.plezy.playback.session.PlaybackFailureAction.PLAYBACK_NOT_ALLOWED
import com.edde746.plezy.playback.session.PlaybackFailureAction.SERVER_BUSY
import com.edde746.plezy.playback.session.PlaybackFailureAction.SERVER_LIMIT
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlaybackFailurePolicyTest {
    private fun resolve(
        cause: FailureCause? = null,
        statuses: Set<Int> = emptySet(),
        live: Boolean = false,
        liveRetrying: Boolean = false,
        liveFallbackLevel: Int = 0,
        liveRetryFailed: Boolean = false,
    ) = resolvePlaybackFailureAction(cause, statuses, live, liveRetrying, liveFallbackLevel, liveRetryFailed)

    @Test
    fun http403OnDemandIsTerminalAndOutranksOtherStatuses() {
        assertEquals(PLAYBACK_NOT_ALLOWED, resolve(statuses = setOf(403)))
        assertEquals(PLAYBACK_NOT_ALLOWED, resolve(statuses = setOf(403, 404)))
        assertEquals(PLAYBACK_NOT_ALLOWED, resolve(statuses = setOf(403, 500)))
        assertEquals(PLAYBACK_NOT_ALLOWED, resolve(FailureCause.SERVER_HTTP_503, setOf(403)))
    }

    @Test
    fun http403OnLiveKeepsTheLadder() {
        assertEquals(LIVE_RETRY, resolve(statuses = setOf(403), live = true))
    }

    @Test
    fun http404OnDemandIsTerminal() {
        assertEquals(MEDIA_UNREADABLE, resolve(statuses = setOf(404)))
        assertEquals(MEDIA_UNREADABLE, resolve(FailureCause.SERVER_HTTP_404))
    }

    @Test
    fun http404OnLiveRidesTheLadderUntilItIsSpent() {
        assertEquals(LIVE_RETRY, resolve(statuses = setOf(404), live = true))
        assertEquals(LIVE_RETRY, resolve(FailureCause.SERVER_HTTP_404, live = true))
        assertEquals(
            LIVE_INTERRUPTED,
            resolve(statuses = setOf(404), live = true, liveFallbackLevel = MAX_LIVE_FALLBACK_LEVEL, liveRetryFailed = true),
        )
    }

    @Test
    fun http500IsTerminalOnDemandAndLiveAndOutranks404() {
        assertEquals(SERVER_LIMIT, resolve(statuses = setOf(500)))
        assertEquals(SERVER_LIMIT, resolve(statuses = setOf(500), live = true))
        assertEquals(SERVER_LIMIT, resolve(FailureCause.SERVER_HTTP_500, live = true))
        assertEquals(SERVER_LIMIT, resolve(statuses = setOf(404, 500)))
    }

    @Test
    fun theWatchdogs503IsTerminalOnDemandOnlyAndALatchedStatusOutranksIt() {
        assertEquals(SERVER_BUSY, resolve(FailureCause.SERVER_HTTP_503))
        assertEquals(LIVE_RETRY, resolve(FailureCause.SERVER_HTTP_503, live = true))
        assertEquals(SERVER_LIMIT, resolve(FailureCause.SERVER_HTTP_503, setOf(500)))
        assertEquals(MEDIA_UNREADABLE, resolve(FailureCause.SERVER_HTTP_503, setOf(404)))
    }

    @Test
    fun anAudioOutputFailureIsTerminalWhateverElseApplies() {
        assertEquals(FATAL, resolve(FailureCause.AUDIO_OUTPUT))
        assertEquals(FATAL, resolve(FailureCause.AUDIO_OUTPUT, live = true))
        assertEquals(FATAL, resolve(FailureCause.AUDIO_OUTPUT, live = true, liveRetrying = true))
        assertEquals(FATAL, resolve(FailureCause.AUDIO_OUTPUT, setOf(404)))
    }

    @Test
    fun theLiveLadderClimbsEveryRungBelowTheBound() {
        for (level in 0 until MAX_LIVE_FALLBACK_LEVEL) assertEquals(LIVE_RETRY, resolve(live = true, liveFallbackLevel = level))
    }

    @Test
    fun aRunningLiveRetryOwnsTheError() {
        assertEquals(IGNORE, resolve(live = true, liveRetrying = true))
        assertEquals(IGNORE, resolve(statuses = setOf(404), live = true, liveRetrying = true))
    }

    @Test
    fun aSpentLadderReportsAnInterruptionOnlyAfterItsLastRetryFailed() {
        assertEquals(LIVE_INTERRUPTED, resolve(live = true, liveFallbackLevel = MAX_LIVE_FALLBACK_LEVEL, liveRetryFailed = true))
        assertEquals(FATAL, resolve(live = true, liveFallbackLevel = MAX_LIVE_FALLBACK_LEVEL))
    }

    @Test
    fun aStreamMpvGaveUpOnFailsOnDemandAndClimbsTheLiveLadder() {
        assertEquals(FATAL, resolve(FailureCause.STREAM_INIT))
        assertEquals(LIVE_RETRY, resolve(FailureCause.STREAM_INIT, live = true))
    }

    @Test
    fun anErrorWithNoServerStatusIsFatalOnDemand() {
        assertEquals(FATAL, resolve())
        assertEquals(FATAL, resolve(statuses = setOf(503)))
        assertEquals(FATAL, resolve(FailureCause.OPEN_TIMED_OUT))
    }

    private fun offers(
        live: Boolean = false,
        plexBacked: Boolean = true,
        serverSupportsTranscoding: Boolean = true,
        requestedPreset: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
        fallbackAlreadyUsed: Boolean = false,
    ) = offersServerLimitTranscode(live, plexBacked, serverSupportsTranscoding, requestedPreset, fallbackAlreadyUsed)

    @Test
    fun anOnDemandPlexOpenAtOriginalOffersATranscode() {
        assertTrue(offers())
    }

    @Test
    fun liveNonPlexAndServersThatCantTranscodeGetNoOffer() {
        assertFalse(offers(live = true))
        assertFalse(offers(plexBacked = false))
        assertFalse(offers(serverSupportsTranscoding = false))
    }

    @Test
    fun aCappedPresetGetsNoOffer() {
        for (preset in TranscodeQualityPreset.entries.filter { !it.isOriginal }) assertFalse(offers(requestedPreset = preset), preset.name)
    }

    @Test
    fun anItemThatAlreadyTriedTheTranscodeGetsNoSecondOffer() {
        assertFalse(offers(fallbackAlreadyUsed = true))
    }
}
