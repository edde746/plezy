package com.edde746.plezy.trackers

import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.mdblist.MdblistProvider
import com.edde746.plezy.trackers.simkl.SimklProvider
import com.edde746.plezy.trackers.trakt.TraktProvider
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Playback through the services' own clients against their scripted APIs: which endpoints one playback reaches, so
 * that a watch is recorded once, by the service's own rule or by a history write when the server's threshold is lower.
 */
class TrackerServicesPlaybackTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private val now = 1_790_000_000L
    private val session = TrackerSession("a0", "r0", expiresAt = 4_000_000_000, username = "alex", createdAt = now)

    /** One service's real client against [service], connected; the media server's threshold is [threshold]. */
    private suspend fun TestScope.connected(name: TrackerService, service: ScriptedService, threshold: Double): TrackerFixture {
        val http = service.http(name)
        val provider = when (name) {
            TrackerService.TRAKT -> TraktProvider(http, "client-id", "client-secret") { now }
            TrackerService.SIMKL -> SimklProvider(http, "client-id", "legacy-client-id", "2.26.0") { now }
            else -> MdblistProvider(http, "client-id") { now }
        }
        val f = TrackerFixture(this, services = emptyList(), realProviders = listOf(provider)).also { fixtures += it }
        f.backend.watchedThreshold = threshold
        f.connect(name, session)
        return f
    }

    private fun answering(statuses: Map<String, Int> = emptyMap()): (Recorded) -> Answer =
        { request -> json("{}", statuses[request.path] ?: 201) }

    private val episode = episodeItem("tt0903747", 1, 3)

    /** Plays [episode] from 0 to [to] % in 5 % steps, then leaves it there. */
    private fun TrackerFixture.play(to: Int) {
        observer.start(episode, backend, at(0, 100))
        for (position in 5..to step 5) observer.onPosition(at(position, 100))
        observer.onPosition(at(to, 100))
        observer.onVideoStopped(at(to, 100))
        drain()
    }

    private fun ScriptedService.paths() = requests.map { it.path }

    @Test
    fun traktFilesAWatchBelowItsOwnRuleInHistory() = runTest {
        val answer = answering()
        val trakt = ScriptedService(this) { answer(it) }
        val f = connected(TrackerService.TRAKT, trakt, threshold = 0.5)
        f.play(60)
        assertEquals(listOf("/scrobble/start", "/scrobble/stop", "/sync/history"), trakt.paths())
        assertEquals(60.0, trakt.to("/scrobble/stop").single().field("progress")!!.toDouble())
        assertEquals(
            parse("""{"shows":[{"ids":{"imdb":"tt0903747"},"seasons":[{"number":1,"episodes":[{"number":3}]}]}]}"""),
            parse(trakt.to("/sync/history").single().body),
        )
    }

    @Test
    fun traktLeavesAWatchAtItsOwnRuleToTheStopUnlessTheStopFailed() = runTest {
        val answer = answering()
        val trakt = ScriptedService(this) { answer(it) }
        connected(TrackerService.TRAKT, trakt, threshold = 0.7).play(85)
        assertEquals(listOf("/scrobble/start", "/scrobble/stop"), trakt.paths())

        val failing = answering(mapOf("/scrobble/stop" to 500))
        val unconfirmed = ScriptedService(this) { failing(it) }
        connected(TrackerService.TRAKT, unconfirmed, threshold = 0.7).play(85)
        assertEquals(listOf("/scrobble/start", "/scrobble/stop", "/sync/history"), unconfirmed.paths())
    }

    @Test
    fun traktCheckpointsASeekAsPauseThenStart() = runTest {
        val answer = answering()
        val trakt = ScriptedService(this) { answer(it) }
        val f = connected(TrackerService.TRAKT, trakt, threshold = 0.9)
        f.observer.start(episode, f.backend, at(0, 100))
        f.observer.onPosition(at(40, 100))
        f.drain()
        assertEquals(listOf("/scrobble/start", "/scrobble/pause", "/scrobble/start"), trakt.paths())
        assertEquals(listOf("0.0", "40.0", "40.0"), trakt.requests.map { it.field("progress") })
    }

    @Test
    fun simklRecordsAWatchItself() = runTest {
        val answer = answering()
        val simkl = ScriptedService(this) { answer(it) }
        connected(TrackerService.SIMKL, simkl, threshold = 0.9).play(95)
        assertEquals(listOf("/scrobble/start", "/scrobble/stop"), simkl.paths())

        val low = ScriptedService(this) { answer(it) }
        connected(TrackerService.SIMKL, low, threshold = 0.75).play(76)
        assertEquals(listOf("/scrobble/start", "/scrobble/stop", "/sync/history"), low.paths())
    }

    @Test
    fun mdblistCheckpointsASeekThroughStartAndStaysSilentWhenOff() = runTest {
        val answer = answering()
        val mdblist = ScriptedService(this) { answer(it) }
        val f = connected(TrackerService.MDBLIST, mdblist, threshold = 0.9)
        f.observer.start(episode, f.backend, at(0, 100))
        f.observer.onPosition(at(40, 100))
        f.drain()
        assertEquals(listOf("/scrobble/start", "/scrobble/start"), mdblist.paths())

        f.set(AppSettings.scrobble(TrackerService.MDBLIST), false)
        f.observer.onVideoStopped(at(95, 100))
        f.coordinator.watchMarks.mark(movieItem(), f.backend, true)
        f.drain()
        assertEquals(2, mdblist.requests.size)
    }
}
