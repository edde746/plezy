package com.edde746.plezy.trackers

import com.edde746.plezy.data.tracker.QueuedTrackerWrite
import com.edde746.plezy.data.tracker.TrackerWriteQueue
import com.edde746.plezy.data.tracker.TrackerWriteRequest
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.trackers.TrackerService.MYANIMELIST
import com.edde746.plezy.trackers.TrackerService.SIMKL
import com.edde746.plezy.trackers.TrackerService.TRAKT
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * Failed watched writes: kept per remote row as the newest intent, replayed in batches through the account they were
 * made under, a transient failure costing no attempt, and dropped after five refusals. The earlier releases' queues
 * move into it once.
 */
class TrackerWriteQueueTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private suspend fun TestScope.fixture(vararg services: TrackerService): TrackerFixture {
        val f = TrackerFixture(this, services = services.toList()).also { fixtures += it }
        f.settle()
        for (service in services) f.connect(service)
        return f
    }

    private val show = "tt0903747"

    private fun episodeWrite(service: TrackerService, episode: Int, watched: Boolean = true, library: String? = null) = TrackerWriteRequest(
        "${service.id}|s1e$episode|imdb=$show",
        TrackerContext(TrackerMediaKind.EPISODE, ExternalIds(show), season = 1, episode = episode, libraryGlobalKey = library),
        watched,
        null,
    )

    private fun claim(progress: Int, entry: Int = 21) = TrackerWriteRequest(
        "mal|series|$entry",
        TrackerContext(TrackerMediaKind.EPISODE, anime = AnimeIds(mal = entry), season = 1, episode = progress, animeProgress = progress),
        true,
        progress.toLong(),
    )

    /** Queues [writes] under the profile's current [service] sign-in, as a write that failed at [at] would. */
    private suspend fun TrackerFixture.queue(service: TrackerService, vararg writes: TrackerWriteRequest, at: Long = 1_000, profile: String = profileId) {
        val binding = data.trackerAccounts.account(profile, service)!!.connectedAt
        data.trackerWriteQueue.enqueue(profile, service, binding, writes.toList(), at)
    }

    private suspend fun TrackerFixture.replay() {
        coordinator.replayQueuedWrites()
        drain()
    }

    private suspend fun TrackerFixture.mark(item: MediaItem, watched: Boolean = true) {
        coordinator.watchMarks.mark(item, backend, watched)
        drain()
    }

    private suspend fun TrackerFixture.attempts() = data.trackerWriteQueue.pending(profileId).map { it.attempts }

    // The drain

    @Test
    fun aReplaySendsTheWriteWithItsDateAndRemovesIt() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1), at = 1_234)
        f.replay()
        assertEquals(listOf("watched $show:1:1 at=1234"), f.calls(TRAKT))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aDrainSpacesTraktWritesByItsOneWriteASecondLimit() = runTest {
        val f = fixture(TRAKT, SIMKL)
        f.queue(TRAKT, episodeWrite(TRAKT, 1), episodeWrite(TRAKT, 2, watched = false))
        f.queue(SIMKL, episodeWrite(SIMKL, 1), episodeWrite(SIMKL, 2, watched = false))
        f.replay()
        val trakt = f.log.filter { it.service == TRAKT }.map { it.atMillis }
        val simkl = f.log.filter { it.service == SIMKL }.map { it.atMillis }
        assertEquals(1_000, trakt[1] - trakt[0])
        assertEquals(Tracker.DEFAULT_WRITE_SPACING.inWholeMilliseconds, simkl[1] - simkl[0])
    }

    @Test
    fun aRefusedReplaySpendsAnAttemptAndAnExhaustedWriteIsDroppedUnsent() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1))
        val id = f.data.trackerWriteQueue.pending(f.profileId).single().id
        f.data.trackerWriteQueue.recordFailure(List(TrackerWriteQueue.MAX_ATTEMPTS - 2) { id })
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 422))
        f.replay()
        assertEquals(listOf(TrackerWriteQueue.MAX_ATTEMPTS - 1), f.attempts())
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 422))
        f.replay()
        assertEquals(listOf(TrackerWriteQueue.MAX_ATTEMPTS), f.attempts())
        f.replay()
        assertEquals(2, f.calls(TRAKT).size, "the exhausted write isn't sent again")
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun `a row the service does not know is gone after one replay while the rest are sent`() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1), episodeWrite(TRAKT, 2))
        (f.tracker(TRAKT) as FakeRealtimeTracker).notFound += episodeWrite(TRAKT, 2).context
        f.replay()
        assertEquals(emptyList(), f.queued())
        f.replay()
        assertEquals(1, f.calls(TRAKT).size, "the unknown row isn't sent again")
    }

    @Test
    fun aServiceThatMayNotWriteNowKeepsItsRowsWithoutSpendingAnAttempt() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1))
        // A row of a service with no connection (an earlier release's, imported).
        f.data.db.database.trackerQueries.insertQueued(
            f.profileId, SIMKL.id, "simkl|movie|imdb=tt1", true, """{"kind":"MOVIE","ids":{"imdb":"tt1"}}""", null, 1, 2,
        )
        f.set(AppSettings.enableTraktWatchedSync, false)
        f.replay()
        assertEquals(emptyList(), f.log)
        assertEquals(
            listOf("trakt trakt|s1e1|imdb=$show watched=true attempts=0", "simkl simkl|movie|imdb=tt1 watched=true attempts=2"),
            f.queued(),
        )
    }

    @Test
    fun aRowOfAFilteredOutLibraryIsDroppedAndEachRowKeepsItsOwnOutcome() = runTest {
        val f = fixture(TRAKT)
        f.set(AppSettings.trackerFilterIds(TRAKT), listOf("s1:anime"))
        f.queue(TRAKT, episodeWrite(TRAKT, 1, library = "s1:anime"), episodeWrite(TRAKT, 2, library = "s1:tv"), episodeWrite(TRAKT, 3, library = "s1:tv"))
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 422))
        f.replay()
        assertEquals(listOf("watched $show:1:2 at=1000, $show:1:3 at=1000"), f.calls(TRAKT))
        assertEquals(
            listOf("trakt trakt|s1e2|imdb=$show watched=true attempts=1", "trakt trakt|s1e3|imdb=$show watched=true attempts=1"),
            f.queued(),
        )
    }

    @Test
    fun historyRowsBatchByServiceAndDirectionUpToTheCapAndOtherRowsGoAlone() {
        var id = 0L
        fun row(service: TrackerService, key: String, watched: Boolean = true) =
            QueuedTrackerWrite(++id, service, key, TrackerContext(TrackerMediaKind.MOVIE), watched, null, 0, 0)
        val half = TrackerCoordinator.HISTORY_BATCH / 2
        val rows = (1..half).map { row(SIMKL, "simkl-$it") } +
            row(SIMKL, "simkl-removed", watched = false) +
            (half + 1..TrackerCoordinator.HISTORY_BATCH + 1).map { row(SIMKL, "simkl-$it") } +
            listOf(row(MYANIMELIST, "mal-42"), row(MYANIMELIST, "mal-43"))
        val units = TrackerCoordinator.replayUnits(rows) { it == SIMKL }.map { unit -> unit.map { it.coalesceKey } }
        assertEquals(
            listOf(
                (1..TrackerCoordinator.HISTORY_BATCH).map { "simkl-$it" },
                listOf("simkl-removed"),
                listOf("simkl-${TrackerCoordinator.HISTORY_BATCH + 1}"),
                listOf("mal-42"),
                listOf("mal-43"),
            ),
            units,
        )
    }

    @Test
    fun aDeferredBatchLeavesTheRestOfThatServiceForALaterDrain() = runTest {
        val f = fixture(SIMKL)
        f.queue(SIMKL, *(1..TrackerCoordinator.HISTORY_BATCH + 1).map { episodeWrite(SIMKL, it) }.toTypedArray())
        f.tracker(SIMKL).failNext("watched", TrackerException.Api(SIMKL, 503))
        f.replay()
        assertEquals(1, f.calls(SIMKL).size, "a service that asked for quiet gets no second request in the same drain")
        assertEquals(List(TrackerCoordinator.HISTORY_BATCH + 1) { 0 }, f.attempts())
        f.replay()
        assertEquals(3, f.calls(SIMKL).size, "the next drain asks again")
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun theWritesOfEachFailureKindSpendAnAttemptOnlyWhenTheyAreAnAnswerAboutTheWrite() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1))
        val notVerdicts = listOf(
            TrackerException.RateLimited(TRAKT, retryAfterSeconds = 1),
            TrackerException.Api(TRAKT, 502),
            TrackerException.Network(TRAKT, IOException("offline")),
            TrackerException.Auth(TRAKT, "refresh failed", status = 503, permanent = false),
        )
        for (error in notVerdicts) {
            f.tracker(TRAKT).failNext("watched", error)
            f.replay()
            assertEquals(listOf(0), f.attempts(), "$error")
        }
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 404))
        f.replay()
        assertEquals(listOf(1), f.attempts())
        assertEquals(5, f.calls(TRAKT).size)
    }

    @Test
    fun transientFailuresAreTheOnesThatSayNothingAboutTheWrite() {
        assertTrue(isTransientTrackerFailure(TrackerException.RateLimited(TRAKT)))
        assertTrue(isTransientTrackerFailure(TrackerException.Api(TRAKT, 429)))
        assertTrue(isTransientTrackerFailure(TrackerException.Api(TRAKT, 500)))
        assertTrue(isTransientTrackerFailure(TrackerException.Network(TRAKT, IOException("reset"))))
        assertTrue(isTransientTrackerFailure(IOException("socket closed")))
        assertTrue(isTransientTrackerFailure(TrackerException.Auth(TRAKT, "refresh 503", permanent = false)))
        assertFalse(isTransientTrackerFailure(TrackerException.Auth(TRAKT, "refresh refused", permanent = true)))
        assertFalse(isTransientTrackerFailure(TrackerException.Api(TRAKT, 404)))
        assertFalse(isTransientTrackerFailure(IllegalStateException("bug")))
    }

    @Test
    fun aRateLimitedReplayAsksOnceAndKeepsEveryEpisode() = runTest {
        val f = fixture(SIMKL)
        f.queue(SIMKL, episodeWrite(SIMKL, 1), episodeWrite(SIMKL, 2), episodeWrite(SIMKL, 3))
        f.tracker(SIMKL).failNext("watched", TrackerException.RateLimited(SIMKL, retryAfterSeconds = 60))
        f.replay()
        // Asked again while the wait it asked for runs: not sent.
        f.replay()
        assertEquals(1, f.calls(SIMKL).size)
        assertEquals(listOf(0, 0, 0), f.attempts())
        f.advance(60.seconds)
        f.replay()
        assertEquals(2, f.calls(SIMKL).size)
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aCoalescedSecondReplayDoesNotAskADeferredServiceAgain() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, episodeWrite(TRAKT, 1), episodeWrite(TRAKT, 2, watched = false))
        f.tracker(TRAKT).latency = 5.seconds
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 503))
        f.coordinator.replayQueuedWrites()
        f.advance(1.seconds)
        f.coordinator.replayQueuedWrites()
        f.advance(30.seconds)
        assertEquals(listOf("watched $show:1:1 at=1000"), f.calls(TRAKT))
        assertEquals(listOf(0, 0), f.attempts())
    }

    @Test
    fun profileQueuesAreIsolated() = runTest {
        val f = fixture(TRAKT)
        f.hub.accounts.connect("p2", TRAKT, TrackerSession("b0", "r0", FAR_FUTURE, "kai", 1))
        f.settle()
        f.queue(TRAKT, episodeWrite(TRAKT, 1))
        f.queue(TRAKT, episodeWrite(TRAKT, 2), profile = "p2")
        f.replay()
        f.hub.onForeground()
        f.drain()
        assertEquals(listOf("watched $show:1:1 at=1000"), f.calls(TRAKT))
        assertEquals(1, f.data.trackerWriteQueue.pending("p2").size)

        f.hub.onActiveProfileChanged("p2")
        f.drain()
        assertEquals("watched $show:1:2 at=1000", f.calls(TRAKT).last())
        assertEquals(emptyList(), f.data.trackerWriteQueue.pending("p2"))
    }

    @Test
    fun aPurgeDropsOneServicesRowsSoNothingReplaysAndLeavesTheOthers() = runTest {
        val f = fixture(TRAKT, SIMKL)
        f.queue(TRAKT, episodeWrite(TRAKT, 1))
        f.queue(SIMKL, episodeWrite(SIMKL, 1))
        f.hub.purgeWriteQueue(f.profileId, TRAKT)
        assertEquals(listOf("simkl simkl|s1e1|imdb=$show watched=true attempts=0"), f.queued())
        f.replay()
        assertEquals(emptyList(), f.calls(TRAKT))
    }

    // Direct writes and the queue

    @Test
    fun aFailedSeriesWriteIsReplayedOnTheNextDrain() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 21
        f.tracker(MYANIMELIST).failNext("watched", TrackerException.Api(MYANIMELIST, 500))
        f.mark(episodeItem(show, 1, 4))
        assertEquals(listOf("mal mal|series|21 watched=true attempts=0"), f.queued())
        f.replay()
        assertEquals(listOf("watched 21@4", "watched 21@4"), f.calls(MYANIMELIST))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aFailedWriteTheQueueCannotPersistIsKeptInMemoryAndQueuedOnTheNextDrain() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 21
        f.tracker(MYANIMELIST).failNext("watched", TrackerException.Api(MYANIMELIST, 500))
        // A queue that can't write (a full disk): its table is out of reach for the failed write.
        f.data.driver.execute(null, "ALTER TABLE tracker_write_queue RENAME TO tracker_write_queue_away", 0)
        f.mark(episodeItem(show, 1, 4))
        f.data.driver.execute(null, "ALTER TABLE tracker_write_queue_away RENAME TO tracker_write_queue", 0)
        assertEquals(emptyList(), f.queued())
        f.replay()
        assertEquals(listOf("watched 21@4", "watched 21@4"), f.calls(MYANIMELIST))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aFailedContainerQueuesEveryEpisodeAndReplaysThemAsOneRequest() = runTest {
        val f = fixture(SIMKL)
        f.backend.playableDescendants = { episodeItems(show, 3) }
        f.tracker(SIMKL).failNext("watched", TrackerException.Api(SIMKL, 500))
        f.mark(showItem(show))
        assertEquals(3, f.queued().size)
        f.replay()
        assertEquals(2, f.calls(SIMKL).size)
        assertEquals(3, f.calls(SIMKL).last().split(", ").size)
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aWriteThatWentThroughDropsTheQueuedRowsItCovers() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, TrackerWriteRequest("trakt|movie|imdb=tt1", TrackerContext(TrackerMediaKind.MOVIE, ExternalIds("tt1")), true, null))
        f.mark(movieItem("tt1"))
        f.replay()
        assertEquals(listOf("watched tt1"), f.calls(TRAKT), "the replay isn't sent twice")
    }

    @Test
    fun aCompletedClaimDropsOnlyTheQueuedClaimsItCovers() = runTest {
        val f = fixture(MYANIMELIST)
        f.resolver.animeTt[show] = 21
        f.queue(MYANIMELIST, claim(3))
        f.mark(episodeItem(show, 1, 5))
        assertEquals(emptyList(), f.queued(), "episode 5 covers a claim of 3")

        f.queue(MYANIMELIST, claim(7))
        f.mark(episodeItem(show, 1, 5))
        assertEquals(listOf(7L), f.data.trackerWriteQueue.pending(f.profileId).map { it.progressClaim }, "still ahead of 5")

        // A lower claim failing doesn't replace a higher one queued.
        f.tracker(MYANIMELIST).failNext("watched", TrackerException.Api(MYANIMELIST, 500))
        f.mark(episodeItem(show, 1, 6))
        assertEquals(listOf(7L), f.data.trackerWriteQueue.pending(f.profileId).map { it.progressClaim })
    }

    @Test
    fun anOlderHistoryFailureNeverReplacesANewerWrite() = runTest {
        val f = fixture(TRAKT)
        f.tracker(TRAKT).latency = 5.seconds
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 500))
        f.coordinator.watchMarks.mark(movieItem("tt1"), f.backend, true)
        f.coordinator.watchMarks.mark(movieItem("tt1"), f.backend, false)
        f.advance(30.seconds)
        assertEquals(listOf("watched tt1", "unwatched tt1"), f.calls(TRAKT))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aReplayInFlightCannotLandAfterANewerDirectWrite() = runTest {
        val f = fixture(TRAKT)
        f.queue(TRAKT, TrackerWriteRequest("trakt|movie|imdb=tt1", TrackerContext(TrackerMediaKind.MOVIE, ExternalIds("tt1")), true, null))
        f.tracker(TRAKT).latency = 5.seconds
        f.coordinator.replayQueuedWrites()
        f.advance(1.seconds)
        f.coordinator.watchMarks.mark(movieItem("tt1"), f.backend, false)
        f.advance(30.seconds)
        assertEquals(listOf("watched tt1 at=1000", "unwatched tt1"), f.calls(TRAKT))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aFailureCompletingAfterADisconnectIsNotQueued() = runTest {
        val f = fixture(TRAKT)
        f.tracker(TRAKT).latency = 5.seconds
        f.tracker(TRAKT).failNext("watched", TrackerException.Api(TRAKT, 500))
        f.coordinator.watchMarks.mark(movieItem("tt1"), f.backend, true)
        f.advance(1.seconds)
        f.hub.accounts.disconnect(f.profileId, TRAKT)
        f.connect(TRAKT)
        f.advance(30.seconds)
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aReconcileFailureCompletingAfterADisconnectIsNotQueued() = runTest {
        val f = fixture(TRAKT)
        f.backend.watchedThreshold = 0.5
        f.observer.start(episodeItem(show, 1, 1), f.backend, at(0, 100))
        f.settle()
        for (position in 5..60 step 5) f.observer.onPosition(at(position, 100))
        f.drain()
        f.tracker(TRAKT).latency = 5.seconds
        f.tracker(TRAKT).failNext("reconcile", TrackerException.Api(TRAKT, 500))
        f.observer.onVideoStopped(at(60, 100))
        // The stop lands after 5 s, the reconciliation goes out a second later and fails 5 s after that.
        f.advance(7.seconds)
        f.hub.accounts.disconnect(f.profileId, TRAKT)
        f.advance(30.seconds)
        assertEquals(listOf("scrobble START 0", "scrobble STOP 60", "reconcile 60"), f.calls(TRAKT))
        assertEquals(emptyList(), f.queued())
    }

    @Test
    fun aFailedReconciliationIsQueuedAsAWatchedWrite() = runTest {
        val f = fixture(TRAKT)
        f.backend.watchedThreshold = 0.5
        f.observer.start(episodeItem(show, 1, 1), f.backend, at(0, 100))
        for (position in 5..60 step 5) f.observer.onPosition(at(position, 100))
        f.drain()
        f.tracker(TRAKT).failNext("reconcile", TrackerException.Api(TRAKT, 500))
        f.observer.onVideoStopped(at(60, 100))
        f.drain()
        assertEquals(listOf("trakt trakt|s1e1|imdb=$show watched=true attempts=0"), f.queued())
    }

    // The earlier releases' queues

    private val json = Json

    private suspend fun TrackerFixture.storeEarlier(profile: String, queue: String?, legacy: String?) {
        val scope = profileUserScope(profile)
        queue?.let { data.profileSettings.set(scope, ProfileSettings.trackerWriteQueue, json.parseToJsonElement(it)) }
        legacy?.let { data.profileSettings.set(scope, ProfileSettings.traktSyncQueue, json.parseToJsonElement(it)) }
    }

    @Test
    fun anEarlierReleasesQueuesMoveInOnceWithTheirIntentAndEpisodeIntact() = runTest {
        val f = fixture()
        val profile = "p3"
        f.storeEarlier(
            profile,
            queue = """[
              {"service":"mal","watched":true,"ctx":{"external":{"tvdb":9},"anime":{"mal":21},"isMovie":false,"ratingKey":"r3",
               "season":1,"episodeNumber":4,"animeProgress":4},"coalesceKey":"mal|series|21","progressClaim":4,
               "watchedAtIso":"2026-05-02T00:00:00.000Z","attempts":1},
              {"service":"trakt","watched":false,"ctx":{"external":{"imdb":"tt1","tvdb":5},"isMovie":false,"ratingKey":"r1",
               "season":2,"episodeNumber":3},"coalesceKey":"trakt|s2e3|imdb=tt1","watchedAtIso":"2026-05-03T00:00:00.000Z","attempts":0}
            ]""",
            // Left behind by an interrupted migration: its row replaces the shared one for the same remote row.
            legacy = """[
              {"ids":{"imdb":"tt1","tvdb":5},"ratingKey":"r1","libraryGlobalKey":"s1:lib","kind":"episode","season":2,"number":3,
               "op":"add","watchedAtIso":"2026-05-01T10:00:00.000Z","attempts":2},
              {"ids":{},"ratingKey":"r2","kind":"movie","op":"remove","watchedAtIso":"2026-05-01T10:00:00.000Z","attempts":0}
            ]""",
        )
        f.hub.onActiveProfileChanged(profile)
        f.drain()

        val rows = f.data.trackerWriteQueue.pending(profile)
        assertEquals(listOf("mal|series|21", "trakt|s2e3|imdb=tt1"), rows.map { it.coalesceKey })
        val (mal, trakt) = rows
        assertEquals(
            TrackerContext(TrackerMediaKind.EPISODE, ExternalIds(tvdb = 9), AnimeIds(mal = 21), season = 1, episode = 4, animeProgress = 4, ratingKey = "r3"),
            mal.context,
        )
        assertEquals(4L, mal.progressClaim)
        assertEquals(1, mal.attempts)
        assertEquals(TRAKT, trakt.service)
        assertTrue(trakt.watched)
        assertEquals(
            TrackerContext(TrackerMediaKind.EPISODE, ExternalIds(imdb = "tt1", tvdb = 5), season = 2, episode = 3, ratingKey = "r1", libraryGlobalKey = "s1:lib"),
            trakt.context,
        )
        assertEquals(Instant.parse("2026-05-01T10:00:00Z").toEpochMilliseconds(), trakt.watchedAt)
        assertEquals(2, trakt.attempts)
        val scope = profileUserScope(profile)
        assertNull(f.data.profileSettings.value(scope, ProfileSettings.trackerWriteQueue))
        assertNull(f.data.profileSettings.value(scope, ProfileSettings.traktSyncQueue))

        // Once: nothing is left to move the next time.
        f.relaunch(profile)
        assertEquals(2, f.data.trackerWriteQueue.pending(profile).size)
    }

    @Test
    fun aQueueThatDoesNotReadIsKeptAsideAndNothingThrows() = runTest {
        val f = fixture()
        val profile = "p3"
        val scope = profileUserScope(profile)
        val corrupt: JsonElement = JsonPrimitive("[{\"service\":")
        f.data.profileSettings.set(scope, ProfileSettings.trackerWriteQueue, corrupt)
        f.storeEarlier(profile, queue = null, legacy = """{"not":"a list"}""")
        f.hub.onActiveProfileChanged(profile)
        f.drain()
        assertEquals(emptyList(), f.data.trackerWriteQueue.pending(profile))
        assertEquals(corrupt, f.data.profileSettings.value(scope, ProfileSettings.trackerWriteQueueCorrupt))
        assertNull(f.data.profileSettings.value(scope, ProfileSettings.trackerWriteQueue))
        assertNull(f.data.profileSettings.value(scope, ProfileSettings.traktSyncQueue))

        // A queue of an unknown service doesn't read either.
        f.storeEarlier("p4", queue = """[{"service":"letterboxd","watched":true,"ctx":{},"coalesceKey":"k","watchedAtIso":"x"}]""", legacy = null)
        f.hub.onActiveProfileChanged("p4")
        f.drain()
        assertEquals(emptyList(), f.data.trackerWriteQueue.pending("p4"))
        assertTrue(f.data.profileSettings.value(profileUserScope("p4"), ProfileSettings.trackerWriteQueueCorrupt) != null)
    }

    /** The app's next launch, with [profile] active. */
    private fun TrackerFixture.relaunch(profile: String) {
        newHub().onActiveProfileChanged(profile)
        drain()
    }
}
