package com.edde746.plezy.trackers.mal

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RelayResult
import com.edde746.plezy.trackers.SeriesProgress
import com.edde746.plezy.trackers.Tracker
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.isTransientTrackerFailure
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

/**
 * MyAnimeList against its documented answers:
 * - tokens: https://myanimelist.net/apiconfig/references/authorization ("Refresh an access token")
 * - API v2: https://myanimelist.net/apiconfig/references/api/v2 (`GET /users/@me`, `GET /anime/{id}`,
 *   `PUT /anime/{id}/my_list_status`)
 */
class MalTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = MalProvider(service.http(TrackerService.MYANIMELIST), "client-id") { now }

    private fun ScriptedService.tracker(credentials: FakeCredentials = FakeCredentials(TrackerService.MYANIMELIST)): Tracker =
        provider(this).tracker(credentials)

    private fun episode(episode: Int = 12, animeProgress: Int? = 12, mal: Int = 21) = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(tvdb = 1),
        anime = AnimeIds(mal = mal),
        season = 1,
        episode = episode,
        animeProgress = animeProgress,
    )

    /** MyAnimeList answering the snapshot `GET` with [anime] and every `PUT` with an entry; requests kept. */
    private fun TestScope.mal(anime: String) = ScriptedService(this) { request ->
        when (request.method) {
            "GET" -> json(anime)
            "PUT" -> json("""{"status":"watching","num_episodes_watched":5}""")
            else -> error("unexpected $request")
        }
    }

    private val ScriptedService.puts get() = requests.filter { it.method == "PUT" }.map { it.form() }

    @Test
    fun aRelaySessionKeepsTheRefreshTokenAndLooksUpTheName() = runTest {
        val service = ScriptedService(this) { json("""{"id":1,"name":"Xinil","joined_at":"2004-11-05T00:00:00+00:00"}""") }
        val session = provider(service).signIn.session(RelayResult("access-1", "refresh-1", 2_678_400))
        assertEquals(TrackerSession("access-1", "refresh-1", now + 2_678_400, "Xinil", now), session)
        val lookup = service.requests.single()
        assertEquals("https://api.myanimelist.net/v2/users/@me", lookup.url.toString())
        assertEquals("Bearer access-1", lookup.headers["Authorization"])
        assertEquals("application/json", lookup.headers["Accept"])

        assertFailsWith<TrackerException.SignIn> { provider(service).signIn.session(RelayResult("access-1", null, 2_678_400)) }
    }

    @Test
    fun refreshingGoesStraightToMyAnimeListAsAForm() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.form()["refresh_token"]) {
                "refresh-1" -> json("""{"token_type":"Bearer","expires_in":2678400,"access_token":"access-2","refresh_token":"refresh-2"}""")
                "refresh-down" -> Answer(503)
                else -> json("""{"error":"invalid_grant","message":"The refresh token is invalid."}""", 400)
            }
        }
        val old = TrackerSession("access-1", "refresh-1", now, "Xinil", now - 100)
        // The username carries over.
        assertEquals(TrackerSession("access-2", "refresh-2", now + 2_678_400, "Xinil", now), provider(service).refresher.refresh(old))
        val request = service.requests.single()
        assertEquals("https://myanimelist.net/v1/oauth2/token", request.url.toString())
        assertTrue(request.contentType.orEmpty().startsWith("application/x-www-form-urlencoded"))
        assertEquals(mapOf("client_id" to "client-id", "grant_type" to "refresh_token", "refresh_token" to "refresh-1"), request.form())
        // 400/401/403: the grant is dead. Anything else may pass.
        assertTrue(assertFailsWith<TrackerException.Auth> { provider(service).refresher.refresh(old.copy(refreshToken = "refresh-x")) }.permanent)
        assertFalse(assertFailsWith<TrackerException.Auth> { provider(service).refresher.refresh(old.copy(refreshToken = "refresh-down")) }.permanent)
    }

    /** A connected MyAnimeList account whose API refuses every token and whose token endpoint answers [refresh]. */
    private suspend fun TestScope.refusedAccount(refresh: () -> Answer): Pair<TrackerFixture, Rating> {
        val service = ScriptedService(this) { request -> if (request.url.host == "myanimelist.net") refresh() else Answer(401) }
        val fixture = TrackerFixture(this, services = emptyList(), realProviders = listOf(provider(service)))
        // A MyAnimeList session always expires; this one a day from the fixture's clock, so no refresh comes first.
        fixture.connect(TrackerService.MYANIMELIST, TrackerSession("access-old", "refresh-old", now + 86_400, "Xinil", 1))
        val tracker = fixture.hub.accounts.bound(fixture.profileId).first().single().tracker as Rating
        return fixture to tracker
    }

    private val show = RatingTarget(RatingKind.SHOW, anime = AnimeIds(mal = 21))

    @Test
    fun aTransientRefreshFailureKeepsTheSessionAndStaysTransientForTheQueue() = runTest {
        val (fixture, tracker) = refusedAccount { Answer(500, "temporary outage") }

        val error = assertFailsWith<TrackerException.Auth> { tracker.rating(show) }

        assertTrue(isTransientTrackerFailure(error), "the queue defers the write instead of spending an attempt")
        assertEquals("refresh-old", fixture.stored(TrackerService.MYANIMELIST)?.refreshToken)
        fixture.close()
    }

    @Test
    fun aPermanentRefreshFailureSignsTheAccountOut() = runTest {
        val (fixture, tracker) = refusedAccount { json("""{"error":"invalid_grant"}""", 400) }

        assertFailsWith<TrackerException.Auth> { tracker.rating(show) }

        assertNull(fixture.stored(TrackerService.MYANIMELIST))
        fixture.close()
    }

    @Test
    fun aRejectedTokenRefreshesOnceAndRetriesOnce() = runTest {
        val service = ScriptedService(this) { request ->
            when {
                request.headers["Authorization"] == "Bearer access-1" -> Answer(401)
                request.method == "GET" -> json("""{"id":21,"num_episodes":12}""")
                else -> json("{}")
            }
        }
        val credentials = FakeCredentials(TrackerService.MYANIMELIST)
        service.tracker(credentials).markWatched(episode(animeProgress = 1))
        assertEquals(1, credentials.refreshes)
        assertEquals(listOf("GET", "GET", "PUT"), service.requests.map { it.method })

        // A second 401 after the refresh is the request's own answer.
        val refused = ScriptedService(this) { Answer(401) }
        val again = FakeCredentials(TrackerService.MYANIMELIST)
        assertEquals(401, assertFailsWith<TrackerException.Api> { (refused.tracker(again) as Rating).rating(show) }.status)
        assertEquals(1, again.refreshes)
    }

    @Test
    fun aRateLimitIsAPlainApiFailure() = runTest {
        val limited = ScriptedService(this) { request ->
            if (request.method == "GET") json("""{"num_episodes":12}""") else Answer(429, headers = mapOf("Retry-After" to "5"))
        }
        val error = assertFailsWith<TrackerException.Api> { limited.tracker().markWatched(episode()) }
        assertEquals(429, error.status)
        assertTrue(error.transient)
    }

    @Test
    fun theListEntryIsWrittenAsAFormToItsListStatus() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.method == "GET") {
                assertEquals("/v2/anime/21", request.path)
                assertEquals("num_episodes,my_list_status", request.url.parameters["fields"])
                json("""{"num_episodes":12}""")
            } else {
                json("{}")
            }
        }
        service.tracker().markWatched(episode(animeProgress = 13))

        val put = service.requests.single { it.method == "PUT" }
        assertEquals("/v2/anime/21/my_list_status", put.path)
        assertTrue(put.contentType.orEmpty().startsWith("application/x-www-form-urlencoded"))
        // Scoped progress past the total: capped, and the entry completes.
        assertEquals(mapOf("status" to "completed", "num_watched_episodes" to "12"), put.form())
    }

    @Test
    fun fallbackLocalProgressStaysWatchingWithoutUsingTheAnimeTotal() = runTest {
        // A local episode number isn't in the mapped entry's numbering: the total (10) neither caps nor completes it.
        val service = mal("""{"num_episodes":10}""")
        service.tracker().markWatched(episode(animeProgress = null))
        assertEquals(listOf(mapOf("status" to "watching", "num_watched_episodes" to "12")), service.puts)
    }

    @Test
    fun progressStaysWatchingWhileTheTotalIsUnknown() = runTest {
        val service = mal("""{"num_episodes":0}""")
        service.tracker().markWatched(episode())
        assertEquals(listOf(mapOf("status" to "watching", "num_watched_episodes" to "12")), service.puts)
    }

    @Test
    fun aMovieIsOneCompletedUnitAndItsWatchDateIsDropped() = runTest {
        val service = mal("""{"num_episodes":1}""")
        val movie = TrackerContext(TrackerMediaKind.MOVIE, anime = AnimeIds(mal = 21))
        service.tracker().markWatched(movie, watchedAt = kotlin.time.Instant.fromEpochSeconds(now))
        assertEquals(listOf(mapOf("status" to "completed", "num_watched_episodes" to "1")), service.puts)
    }

    @Test
    fun anItemWithoutAMyAnimeListIdIsSkipped() = runTest {
        val service = mal("""{"num_episodes":12}""")
        val tracker = service.tracker()
        tracker.markWatched(episode().copy(anime = AnimeIds(anilist = 5)))
        tracker.markUnwatched(episode().copy(anime = null))
        tracker.markWatched(episode(episode = 0, animeProgress = null))
        assertEquals(emptyList(), service.requests)
        assertNull((tracker as SeriesProgress).seriesEntryId(episode().copy(anime = null)))
        assertEquals("21", tracker.seriesEntryId(episode()))
        assertEquals(7, tracker.seriesProgress(episode(episode = 3, animeProgress = 7)))
        assertEquals(3, tracker.seriesProgress(episode(episode = 3, animeProgress = null)))
    }

    @Test
    fun unwatchResetsAnInProgressEntryToZeroWithoutDeletingIt() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"watching","num_episodes_watched":5}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf("GET", "PUT"), service.requests.map { it.method })
        assertEquals(listOf(mapOf("status" to "watching", "num_watched_episodes" to "0")), service.puts)
    }

    @Test
    fun unwatchKeepsARewatchInProgressAtZero() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"completed","is_rewatching":true,"num_episodes_watched":5}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf(mapOf("is_rewatching" to "true", "num_watched_episodes" to "0")), service.puts)
    }

    @Test
    fun unwatchLeavesACompletedEntryUntouched() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"completed","num_episodes_watched":12,"num_times_rewatched":1}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf("GET"), service.requests.map { it.method })
    }

    @Test
    fun unwatchDoesNotCreateAnEntryForAnUnlistedAnime() = runTest {
        val service = mal("""{"num_episodes":12}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf("GET"), service.requests.map { it.method })
    }

    @Test
    fun unwatchWritesNothingWhenTheEntryCanNotBeRead() = runTest {
        for (answer in listOf(Answer(404), Answer(503))) {
            val service = ScriptedService(this) { answer }
            service.tracker().markUnwatched(episode(animeProgress = null))
            assertEquals(listOf("GET"), service.requests.map { it.method })
        }
    }

    @Test
    fun theSnapshotStaysCachedWhenTheWriteFails() = runTest {
        var puts = 0
        val service = ScriptedService(this) { request ->
            if (request.method == "GET") json("""{"num_episodes":12}""") else if (++puts == 1) Answer(500, "boom") else json("{}")
        }
        val tracker = service.tracker()

        assertFailsWith<TrackerException.Api> { tracker.markWatched(episode()) }
        tracker.markWatched(episode())

        assertEquals(1, service.requests.count { it.method == "GET" }, "a failed write keeps the snapshot its retry needs")
        assertEquals(2, puts)
    }

    @Test
    fun aFailedLookupIsReadAgainByTheNextWrite() = runTest {
        var gets = 0
        val service = ScriptedService(this) { request ->
            if (request.method == "GET") (if (++gets == 1) Answer(500, "boom") else json("""{"num_episodes":12}""")) else json("{}")
        }
        val tracker = service.tracker()

        // The first write goes on without a snapshot.
        tracker.markWatched(episode())
        tracker.markWatched(episode())

        assertEquals(2, gets)
        assertEquals(listOf(mapOf("status" to "watching", "num_watched_episodes" to "12"), mapOf("status" to "completed", "num_watched_episodes" to "12")), service.puts)
    }

    @Test
    fun aNewSignInReadsTheEntryAgain() = runTest {
        val service = mal("""{"num_episodes":12}""")
        service.tracker().markWatched(episode(animeProgress = 3))
        service.tracker().markWatched(episode(animeProgress = 3))
        assertEquals(2, service.requests.count { it.method == "GET" })
    }

    @Test
    fun aRewatchingEntryStaysRewatchingMidSeriesWithoutTouchingItsStatus() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"completed","is_rewatching":true,"num_times_rewatched":2}}""")
        service.tracker().markWatched(episode(episode = 5, animeProgress = 5))
        assertEquals(listOf(mapOf("num_watched_episodes" to "5", "is_rewatching" to "true")), service.puts)
    }

    @Test
    fun aCompletedRewatchBumpsTheRewatchCount() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"completed","is_rewatching":true,"num_times_rewatched":2}}""")
        service.tracker().markWatched(episode(animeProgress = 12))
        assertEquals(
            listOf(mapOf("status" to "completed", "num_watched_episodes" to "12", "is_rewatching" to "false", "num_times_rewatched" to "3")),
            service.puts,
        )
    }

    @Test
    fun newProgressOnACompletedEntryStartsARewatch() = runTest {
        val service = mal("""{"num_episodes":12,"my_list_status":{"status":"completed","is_rewatching":false,"num_times_rewatched":0}}""")
        service.tracker().markWatched(episode(episode = 1, animeProgress = 1))
        assertEquals(listOf(mapOf("num_watched_episodes" to "1", "is_rewatching" to "true")), service.puts)
    }

    @Test
    fun sequentialRewatchWritesReadTheEntryAsTheLastWriteLeftIt() = runTest {
        var gets = 0
        val service = ScriptedService(this) { request ->
            if (request.method == "GET") {
                // The second read is the entry after the first write; the stale first one would bump the count again.
                val status = if (++gets == 1) {
                    """{"status":"completed","is_rewatching":true,"num_times_rewatched":2}"""
                } else {
                    """{"status":"completed","is_rewatching":false,"num_times_rewatched":3}"""
                }
                json("""{"num_episodes":12,"my_list_status":$status}""")
            } else {
                json("{}")
            }
        }
        val tracker = service.tracker()

        tracker.markWatched(episode(animeProgress = 12))
        tracker.markWatched(episode(animeProgress = 12))

        assertEquals(2, gets, "a successful write drops the snapshot")
        assertEquals(
            listOf(
                mapOf("status" to "completed", "num_watched_episodes" to "12", "is_rewatching" to "false", "num_times_rewatched" to "3"),
                mapOf("status" to "completed", "num_watched_episodes" to "12"),
            ),
            service.puts,
        )
    }

    @Test
    fun theCurrentListScoreIsRead() = runTest {
        val service = ScriptedService(this) { request ->
            assertEquals("GET", request.method)
            assertEquals("/v2/anime/21", request.path)
            assertEquals("my_list_status", request.url.parameters["fields"])
            json("""{"my_list_status":{"score":9}}""")
        }
        assertEquals(9, (service.tracker() as Rating).rating(show))
        // An unscored entry (0), an anime off the list, one MyAnimeList doesn't know: no score.
        assertNull((mal("""{"my_list_status":{"score":0}}""").tracker() as Rating).rating(show))
        assertNull((mal("""{"id":21}""").tracker() as Rating).rating(show))
        assertNull((ScriptedService(this) { Answer(404) }.tracker() as Rating).rating(show))
    }

    @Test
    fun ratingsWriteTheEntrysScoreClampedAndZeroClears() = runTest {
        val service = mal("""{"id":21}""")
        val tracker = service.tracker() as Rating
        tracker.rate(show, 11)
        tracker.rate(RatingTarget(RatingKind.EPISODE, anime = AnimeIds(mal = 21), season = 1, episode = 3), 0)
        tracker.clearRating(show)
        assertEquals(listOf(mapOf("score" to "10"), mapOf("score" to "1"), mapOf("score" to "0")), service.puts)
        assertNotNull(assertFailsWith<TrackerException.Unsupported> { tracker.rate(show.copy(anime = AnimeIds(anilist = 5)), 5) })
        assertFailsWith<TrackerException.Unsupported> { tracker.rating(show.copy(anime = null)) }
    }
}
