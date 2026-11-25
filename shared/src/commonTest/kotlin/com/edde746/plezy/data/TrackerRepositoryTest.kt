package com.edde746.plezy.data

import com.edde746.plezy.data.tracker.TrackerWriteRequest
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class TrackerRepositoryTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val queue = data.trackerWriteQueue
    private val p = "p1"
    private val trakt = TrackerService.TRAKT
    private val anilist = TrackerService.ANILIST

    @AfterTest
    fun close() = data.close()

    private suspend fun keys(profile: String = p) = queue.pending(profile).map { "${it.service.id}/${it.coalesceKey}/${it.watched}" }

    /** Sign-in times, one later than the other. */
    private var signIns = 0L

    /** Connects [service] for [profile] and returns the binding its queued writes carry. */
    private suspend fun connected(service: TrackerService, profile: String = p): Long =
        data.trackerAccounts.connect(profile, service, "alex", ++signIns).connectedAt

    private fun write(key: String, watched: Boolean = true, claim: Long? = null) =
        TrackerWriteRequest(key, TrackerContext(TrackerMediaKind.MOVIE, ExternalIds("tt1")), watched, claim)

    private suspend fun enqueue(service: TrackerService, key: String, watched: Boolean, claim: Long? = null, at: Long = 1, profile: String = p): Int {
        val binding = data.trackerAccounts.account(profile, service)?.connectedAt ?: connected(service, profile)
        return queue.enqueue(profile, service, binding, listOf(write(key, watched, claim)), at)
    }

    @Test
    fun reconnectUpdatesTheSignInAndDisconnectDropsQueuedWrites() = runTest {
        data.trackerAccounts.connect(p, trakt, "alex", 1)
        data.trackerAccounts.connect(p, trakt, "alex2", 2)
        val account = data.trackerAccounts.account(p, trakt)!!
        assertEquals("alex2", account.username)
        assertEquals(2, account.connectedAt)

        enqueue(trakt, "movie:tt1", true)
        enqueue(anilist, "anime:1", true, claim = 3)
        assertTrue(data.trackerAccounts.disconnect(p, trakt))
        assertEquals(listOf(anilist), data.trackerAccounts.accounts(p).map { it.service })
        assertEquals(listOf("anilist/anime:1/true"), keys())
    }

    @Test
    fun aQueuedWriteBelongsToTheSignInItWasMadeUnder() = runTest {
        val first = connected(trakt)
        assertEquals(1, queue.enqueue(p, trakt, first, listOf(write("movie:tt1")), 1))
        // Signing in again (maybe as someone else) is a new binding: the old sign-in's writes go.
        val second = connected(trakt)
        assertNotEquals(first, second)
        assertEquals(emptyList(), keys())
        // A write that fails after the reconnect can't be queued under the old sign-in either.
        assertEquals(0, queue.enqueue(p, trakt, first, listOf(write("movie:tt1")), 2))
        assertEquals(1, queue.enqueue(p, trakt, second, listOf(write("movie:tt1")), 2))
        // A dead session found under the old sign-in doesn't sign out the new one.
        assertFalse(data.trackerAccounts.disconnect(p, trakt, connectedAt = first))
        assertEquals(1, queue.pending(p).size)
        assertTrue(data.trackerAccounts.disconnect(p, trakt, connectedAt = second))
        assertEquals(0, queue.enqueue(p, trakt, second, listOf(write("movie:tt1")), 3))
        assertEquals(emptyList(), keys())
    }

    @Test
    fun aNewerIntentReplacesTheQueuedOneAndMovesToTheBack() = runTest {
        enqueue(trakt, "movie:tt1", true, at = 1)
        enqueue(trakt, "movie:tt2", true, at = 2)
        enqueue(trakt, "movie:tt1", false, at = 3)
        assertEquals(listOf("trakt/movie:tt2/true", "trakt/movie:tt1/false"), keys())
        // The same key on another service or profile is another remote row.
        enqueue(TrackerService.SIMKL, "movie:tt1", true, at = 4)
        enqueue(trakt, "movie:tt1", true, at = 4, profile = "p2")
        assertEquals(listOf("trakt/movie:tt2/true", "trakt/movie:tt1/false", "simkl/movie:tt1/true"), keys())
        assertEquals(listOf("trakt/movie:tt1/true"), keys("p2"))
    }

    @Test
    fun progressClaimsNeverMoveBackwards() = runTest {
        assertEquals(1, enqueue(anilist, "anime:21", true, claim = 6, at = 1))
        assertEquals(0, enqueue(anilist, "anime:21", true, claim = 5, at = 2))
        assertEquals(6, queue.pending(p).single().progressClaim)
        assertEquals(1, enqueue(anilist, "anime:21", true, claim = 7, at = 3))
        assertEquals(7, queue.pending(p).single().progressClaim)
        // A removal is not a claim and replaces any claim.
        assertEquals(1, enqueue(anilist, "anime:21", false, at = 4))
        assertEquals(null, queue.pending(p).single().progressClaim)
    }

    @Test
    fun aRowThatNoLongerReadsIsDropped() = runTest {
        enqueue(trakt, "movie:tt1", true)
        // A row written in a shape this build can't read (a kind it no longer has), and one of a service it doesn't know.
        data.db.database.trackerQueries.insertQueued(p, trakt.id, "movie:tt2", true, """{"kind":"FILM","ids":{"imdb":"tt2"}}""", null, 2, 0)
        data.db.database.trackerQueries.insertQueued(p, "letterboxd", "movie:tt3", true, """{"kind":"MOVIE"}""", null, 2, 0)
        assertEquals(listOf("trakt/movie:tt1/true"), keys())
        assertEquals(1, data.db.database.trackerQueries.selectQueued(p).executeAsList().size, "both are gone for good")
    }

    @Test
    fun aFailedAttemptIsCountedOnTheRowAndCompletingAStaleIdKeepsTheNewerIntent() = runTest {
        enqueue(trakt, "movie:tt1", true, at = 1)
        val stale = queue.pending(p).single().id
        queue.recordFailure(listOf(stale))
        assertEquals(1, queue.pending(p).single().attempts)
        enqueue(trakt, "movie:tt1", false, at = 2)
        assertFalse(queue.isQueued(stale))
        queue.complete(listOf(stale))
        queue.recordFailure(listOf(stale))
        assertEquals(listOf("trakt/movie:tt1/false"), keys())
        assertEquals(0, queue.pending(p).single().attempts, "a newer intent starts with no attempts")
    }

    @Test
    fun invalidateDropsOnlyCoveredWrites() = runTest {
        enqueue(anilist, "anime:1", true, claim = 8)
        queue.invalidate(p, anilist, mapOf("anime:1" to 7L))
        assertEquals(1, queue.pending(p).size)
        queue.invalidate(p, anilist, mapOf("anime:1" to 8L))
        assertEquals(emptyList(), queue.pending(p))

        enqueue(trakt, "movie:tt1", true)
        queue.invalidate(p, trakt, mapOf("movie:tt1" to null))
        assertEquals(emptyList(), queue.pending(p))
    }
}
