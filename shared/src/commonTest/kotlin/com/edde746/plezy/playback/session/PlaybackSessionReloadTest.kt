package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.TrackKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** How a play starts and how an in-place reload runs: one at a time, the newest play winning. */
class PlaybackSessionReloadTest {
    private fun TestScope.rig(backend: BackendKind = BackendKind.PLEX) = SessionRig(this, SessionBackend(backend = backend))

    @Test
    fun aPlayOnAServerWithoutAClientFailsAsUnavailableAndLoadsNothing() = runTest {
        with(rig()) {
            session.start(PlayRequest.Item(ServerId("gone"), "m1", item = movie()))
            runCurrent()
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, failure.reason)
            assertEquals(emptyList(), backend.initializations)
            assertEquals(emptyList(), engine.loads)
        }
    }

    @Test
    fun aNewerPlayWinsOverOneStillResolving() = runTest {
        with(rig()) {
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.start(PlayRequest.Item(ServerId("srv"), "m1", item = movie("m1")))
            runCurrent()
            session.start(PlayRequest.Item(ServerId("srv"), "m2", item = movie("m2")))
            runCurrent()
            gate.complete(Unit)
            idle()
            assertEquals(listOf("https://srv/m2/v1080"), engine.loads.map { it.url }, "the first play's late resolve opens nothing")
            assertEquals("srv:m2", session.playingKey.value)
        }
    }

    @Test
    fun aSwitchWhileAReloadRunsIsRefused() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(60.0)
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            runCurrent()
            session.selectVersion(1)
            session.selectSourceTrack(TrackKind.AUDIO, 5)
            session.selectSourceTrack(TrackKind.SUBTITLE, 9)
            runCurrent()
            gate.complete(Unit)
            idle()
            assertEquals(2, backend.initializations.size, "the first open and the quality switch alone")
            assertEquals(TranscodeQualityPreset.P720_2MBPS, backend.initializations.last().qualityPreset)
            assertEquals(0, backend.initializations.last().selectedMediaIndex)
            assertEquals(listOf("https://srv/m1/v1080", "https://srv/m1/transcode/P720_2MBPS"), engine.loads.map { it.url })
        }
    }

    @Test
    fun aNextEpisodeShowsItsTitleAtOnceAndEndsTheOldSessionBeforeItResolves() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            open(1200.0)
            at(600.0)
            idle()
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.playNextEpisode()
            runCurrent()
            with(session.info.value) {
                assertEquals("S1E2 · Episode 2", subtitle, "the new episode shows before it resolves")
                assertNull(nextEpisode, "up next goes with the episode it stood for")
                assertTrue(resolving)
            }
            assertEquals("srv:e2", session.playingKey.value)
            assertEquals(true, engine.pauses.last(), "the old file pauses")
            assertEquals("stopped", backend.states.last(), "the old server session ends before the new one resolves")
            assertEquals(1, backend.initializations.size)

            gate.complete(Unit)
            idle()
            assertEquals("https://srv/e2/v1080", engine.loads.last().url)
        }
    }

    @Test
    fun aReloadPlaysOnOnlyWhenTheFileWasPlaying() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(60.0)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            assertEquals(false, engine.pauses.last(), "playing before, playing after")

            open(600.0)
            session.engine.setPaused(true)
            idle()
            session.selectQuality(TranscodeQualityPreset.P480_1_5MBPS)
            idle()
            assertEquals("https://srv/m1/transcode/P480_1_5MBPS", engine.loads.last().url)
            val ids = backend.initializations.map { it.sessionIdentifier to it.transcodeSessionId }.distinct()
            assertEquals(1, ids.size, "every in-place switch keeps the session's ids: $ids")
            assertTrue(ids.single().first != null && ids.single().second != null)
            assertEquals(true, engine.pauses.last(), "paused before, paused after")
        }
    }

    @Test
    fun aPauseOrPlayWhileAReloadRunsIsHowTheNewFileOpens() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            open(1200.0)
            at(600.0)
            idle()
            val next = CompletableDeferred<Unit>()
            backend.initializationGate = next
            session.playNextEpisode()
            runCurrent()
            session.engine.setPaused(true)
            next.complete(Unit)
            idle()
            assertEquals("https://srv/e2/v1080", engine.loads.last().url)
            assertEquals(true, engine.pauses.last(), "paused before its first frame, the next episode opens paused")

            open(1200.0)
            idle()
            val switch = CompletableDeferred<Unit>()
            backend.initializationGate = switch
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            runCurrent()
            session.engine.setPaused(false)
            switch.complete(Unit)
            idle()
            assertEquals("https://srv/e2/transcode/P720_2MBPS", engine.loads.last().url)
            assertEquals(false, engine.pauses.last(), "played while it reloaded, the paused file opens playing")
        }
    }
}
