package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.PlaybackSessionTerminatedException
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.playback.report.ReportCall
import com.edde746.plezy.playback.report.ReportKind
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** What the end of a video leads to, and what a play of the video playing now asks for. */
class PlaybackSessionEndTest {
    private fun TestScope.rig(backend: BackendKind = BackendKind.PLEX) = SessionRig(this, SessionBackend(backend = backend))

    private fun SessionRig.end(at: Double) = engine.report { it.copy(positionSeconds = at, eof = true, paused = true) }

    private fun busy() = MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "busy", statusCode = 503)

    @Test
    fun `a movie that ends with nothing after it has ended`() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            idle()
            assertFalse(session.info.value.ended)
            end(600.0)
            idle()
            assertTrue(session.info.value.ended)
            assertNull(session.info.value.notice)
        }
    }

    @Test
    fun `going back from the end plays on with a new server session and trackers`() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            at(590.0)
            end(600.0)
            idle()
            assertEquals("stopped", backend.states.last())
            assertEquals("stopped @600000", trackers.events.last())
            assertTrue(session.info.value.ended)

            // Within the end region the latch holds: nothing is reported again.
            engine.report { it.copy(positionSeconds = 599.0, eof = false, paused = false) }
            idle()
            assertEquals("stopped", backend.states.last())
            assertTrue(session.info.value.ended)

            engine.report { it.copy(positionSeconds = 300.0) }
            idle()
            assertFalse(session.info.value.ended)
            assertEquals("started m1 @300000 playing=true", trackers.events.last())
            elapse(10.seconds)
            assertEquals("playing", backend.states.last(), "the server hears of the video again after its stopped report")
        }
    }

    @Test
    fun `an episode whose series couldnt be read reads it once more at the end`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            play(first)
            open(1200.0)
            idle()
            assertEquals(1, backend.episodeQueueFetches)
            assertNull(session.info.value.nextEpisode)

            backend.episodes = listOf(first, episode("e2", 2))
            end(1200.0)
            idle()
            assertEquals(2, backend.episodeQueueFetches)
            assertEquals("Episode 2", session.info.value.nextEpisode?.title)
            assertFalse(session.info.value.ended)
            assertNull(session.info.value.notice)
        }
    }

    @Test
    fun `a series still unreadable at the end says so and the player stays`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(episode("e1", 1))
            open(1200.0)
            idle()
            end(1200.0)
            idle()
            assertEquals(2, backend.episodeQueueFetches, "read once more, not again and again")
            assertEquals(T.messages.errorLoadingSeries, session.info.value.notice?.text)
            assertFalse(session.info.value.ended)
        }
    }

    @Test
    fun `an episode with a next one ends into up next`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            open(1200.0)
            idle()
            end(1200.0)
            idle()
            assertNotNull(session.info.value.nextEpisode)
            assertFalse(session.info.value.ended)
        }
    }

    /**
     * Maestro Episode 2 (90 s, credits 75-90 s) left for the next one at [leftAt]; what reached the server and the app's
     * watch state for it.
     */
    private fun TestScope.advanceFrom(rig: SessionRig, leftAt: Double, close: Boolean = false): Pair<ReportCall, List<WatchStateEvent>> = with(rig) {
        // As JellyfinClient says for both MediaBrowser dialects; Plex marks from a crossing it sees.
        backend.marksWatchedOnPlaybackStopped = backend.backend != BackendKind.PLEX
        val first = episode("e2", 2, backend.backend, durationMs = 90_000)
        backend.episodes = listOf(first, episode("e3", 3, backend.backend, durationMs = 90_000))
        backend.extras = PlaybackExtras(emptyList(), listOf(MediaMarker(1, MediaMarker.CREDITS, 75_000, 90_000)))
        val events = mutableListOf<WatchStateEvent>()
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { env.notifier.events.collect { events += it } }
        play(first)
        open(90.0)
        at(40.0)
        elapse(10.seconds)
        at(leftAt)
        idle()
        if (close) session.close() else session.playNextEpisode()
        idle()
        if (!close) assertEquals("srv:e3", session.playingKey.value)
        backend.reports.last { it.kind == ReportKind.STOPPED && it.itemId == "e2" } to events.filter { it.itemId == "e2" }
    }

    @Test
    fun `an episode left for the next from its credits ends played on every backend`() {
        for (kind in BackendKind.entries) runTest {
            val (stopped, events) = advanceFrom(rig(kind), leftAt = 80.0)
            // 80 of 90 s is under every server's 90 %: only the end makes Jellyfin, Emby and Plex mark it played.
            assertEquals(90_000, stopped.positionMs, "$kind")
            assertTrue(events.any { it.isNowWatched == true }, "$kind: $events")
        }
    }

    @Test
    fun `an episode left for the next before its credits keeps its resume point`() = runTest {
        val (stopped, events) = advanceFrom(rig(BackendKind.JELLYFIN), leftAt = 60.0)
        assertEquals(60_000, stopped.positionMs)
        assertFalse(events.any { it.isNowWatched == true }, "$events")
    }

    @Test
    fun `an episode closed from its credits ends played on every backend`() {
        for (kind in BackendKind.entries) runTest {
            val (stopped, events) = advanceFrom(rig(kind), leftAt = 80.0, close = true)
            assertEquals(90_000, stopped.positionMs, "$kind")
            assertTrue(events.any { it.isNowWatched == true }, "$kind: $events")
        }
    }

    @Test
    fun `an episode closed before its credits keeps its resume point`() = runTest {
        val (stopped, events) = advanceFrom(rig(BackendKind.JELLYFIN), leftAt = 60.0, close = true)
        assertEquals(60_000, stopped.positionMs)
        assertFalse(events.any { it.isNowWatched == true }, "$events")
    }

    @Test
    fun `a pick of another queue entry plays it`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2), episode("e3", 3))
            play(first)
            open(1200.0)
            at(30.0)
            idle()
            val queue = session.info.value.queue
            val next = queue.getOrNull(queue.indexOfFirst { it.current } + 1)
            assertNotNull(next, "a queue past the playing episode: $queue")
            session.playQueueItem(next.key)
            idle()
            assertEquals("srv:e2", session.playingKey.value)
        }
    }

    @Test
    fun `a pick plays the entry the sheet showed after the queue state moved on`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2), episode("e3", 3))
            play(first)
            open(1200.0)
            at(30.0)
            idle()
            val queue = session.info.value.queue
            val next = queue.getOrNull(queue.indexOfFirst { it.current } + 1)
            assertNotNull(next, "a queue past the playing episode: $queue")
            playbackState.clearShuffle()
            session.playQueueItem(next.key)
            idle()
            assertEquals("srv:e2", session.playingKey.value)
        }
    }

    @Test
    fun `a next episode the end started that fails on a busy server is offered again`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            open(1200.0)
            idle()
            end(1200.0)
            idle()

            backend.initialize = { throw busy() }
            session.playNextEpisode()
            idle()
            assertEquals(1, session.info.value.nextFailures)
            assertEquals("srv:e1", session.playingKey.value, "back on the finished episode")
            assertNotNull(session.info.value.nextEpisode)

            session.playNextEpisode()
            idle()
            assertEquals(2, session.info.value.nextFailures)

            backend.initialize = { SessionBackend.streamOf(it) }
            session.playNextEpisode()
            idle()
            assertEquals("srv:e2", session.playingKey.value)
        }
    }

    @Test
    fun `a next episode the viewer started mid file or that the server refused is not offered again`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            open(1200.0)
            at(300.0)
            idle()

            backend.initialize = { throw busy() }
            session.playNextEpisode()
            idle()
            assertEquals(0, session.info.value.nextFailures, "not started by the end")

            end(1200.0)
            idle()
            backend.initialize = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "forbidden", statusCode = 403) }
            session.playNextEpisode()
            idle()
            assertEquals(0, session.info.value.nextFailures, "not a server that didn't answer")
        }
    }

    @Test
    fun `a session the server ended is stopped by the server until the viewer pauses and plays`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(100.0)
            backend.refuseReports = { kind -> PlaybackSessionTerminatedException(1, "stopped by the admin").takeIf { kind == ReportKind.PROGRESS } }
            elapse(10.seconds)
            at(110.0)
            assertTrue(session.info.value.stoppedByServer)
            assertEquals("stopped", backend.states.last(), "the ended session is closed with one stopped report")

            backend.refuseReports = { null }
            engine.setPaused(true)
            idle()
            assertTrue(session.info.value.stoppedByServer, "paused, not yet played")
            engine.setPaused(false)
            idle()
            assertFalse(session.info.value.stoppedByServer)
        }
    }

    @Test
    fun `while video may not play a file opens paused`() = runTest {
        with(rig()) {
            allowed = false
            play(movie())
            assertEquals(listOf(true), engine.pauses)
            open(600.0)
            assertTrue(engine.state.paused)
        }
    }

    @Test
    fun `a play of the playing video asks for what the in place reloads moved on to`() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            play(first)
            assertEquals("e1", session.launched?.itemId)
            open(1200.0)
            idle()

            session.playNextEpisode()
            idle()
            open(1200.0)
            assertEquals("e2", session.launched?.itemId)
            assertEquals("srv:e2", session.launched?.globalKey)

            session.selectVersion(1)
            idle()
            open(1200.0)
            assertEquals(1, session.launched?.mediaIndex)

            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            open(1200.0)
            assertEquals(TranscodeQualityPreset.P720_2MBPS, session.launched?.qualityPreset)

            // A reload that failed before its file opened leaves it as it was.
            backend.initialize = { throw busy() }
            session.selectVersion(0)
            idle()
            assertEquals(1, session.launched?.mediaIndex)
            assertEquals("e2", session.launched?.itemId)
        }
    }
}
