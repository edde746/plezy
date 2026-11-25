package com.edde746.plezy.trackers.mdblist

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.time.Instant
import kotlinx.coroutines.test.runTest

/**
 * MDBList against its documented answers:
 * - device code, refresh and revoke: https://api.mdblist.com/docs/authentication/
 * - scrobble, `/sync/watched`, `/sync/ratings`, `/user`, `/lists/user`, list items: the OpenAPI schema behind
 *   https://api.mdblist.com/docs/ (`/schema/`), including its 429 + `Retry-After` rate-limit rule
 */
class MdblistTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = MdblistProvider(service.http(TrackerService.MDBLIST), "client-id") { now }


    private val movie = TrackerContext(
        kind = TrackerMediaKind.MOVIE,
        ids = ExternalIds(imdb = "tt0111161", tmdb = 278, tvdb = 1),
    )

    private val episode = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(tmdb = 1396),
        season = 1,
        episode = 2,
    )

    @Test
    fun scrobblesNestTheEpisodeInTheShowAndClampTheProgress() = runTest {
        val service = ScriptedService(this) { json("""{"id":1,"action":"start","progress":10}""", 201) }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as RealtimeScrobble
        tracker.scrobble(episode, ScrobbleState.START, 10.123)
        tracker.scrobble(movie, ScrobbleState.SEEK, 50.0)
        tracker.scrobble(movie, ScrobbleState.STOP, 100.4)

        assertEquals(listOf("/scrobble/start", "/scrobble/start", "/scrobble/stop"), service.requests.map { it.path })
        assertEquals(parse("""{"show":{"ids":{"tmdb":1396},"season":{"number":1,"episode":{"number":2}}},"progress":10.12}"""), parse(service.requests[0].body))
        // No TVDB id in MDBList's id block.
        assertEquals(parse("""{"movie":{"ids":{"imdb":"tt0111161","tmdb":278}},"progress":100.0}"""), parse(service.requests[2].body))
    }

    @Test
    fun watchedMarksCarryTheDateAndATvdbOnlyItemIsSkipped() = runTest {
        val service = ScriptedService(this) { json("""{"updated":{"movies":1},"not_found":{},"errors":[]}""") }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as RealtimeScrobble
        tracker.markWatched(episode, Instant.parse("2025-10-21T12:00:00Z"))
        tracker.reconcileWatchedAfterStop(movie, 80.0)
        tracker.markUnwatched(movie)
        val tvdbOnly = episode.copy(ids = ExternalIds(tvdb = 81189))
        tracker.markWatched(tvdbOnly)

        assertEquals(listOf("/sync/watched", "/sync/watched/remove"), service.requests.map { it.path })
        assertEquals(
            parse("""{"shows":[{"ids":{"tmdb":1396},"seasons":[{"number":1,"episodes":[{"number":2,"watched_at":"2025-10-21T12:00:00Z"}]}]}]}"""),
            parse(service.requests[0].body),
        )
        assertNull((tracker as EpisodeHistory).historyRowIdentity(tvdbOnly))
        assertEquals("tmdb=1396", tracker.historyRowIdentity(episode))
    }

    @Test
    fun aRejectedTokenRefreshesAndLimitsAreRateLimited() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.headers["Authorization"] == "Bearer access-1") json("""{"detail":"Invalid token"}""", 401) else json("{}")
        }
        val credentials = FakeCredentials(TrackerService.MDBLIST)
        provider(service).tracker(credentials).markWatched(movie)
        assertEquals(1, credentials.refreshes)

        val limited = ScriptedService(this) { json("""{"error":"API rate limit exceeded!"}""", 429, mapOf("Retry-After" to "120")) }
        val error = assertFailsWith<TrackerException.RateLimited> { provider(limited).tracker(FakeCredentials(TrackerService.MDBLIST)).markWatched(movie) }
        assertEquals(120, error.retryAfterSeconds)
    }

    @Test
    fun ratingsAreFoundInTheirKindsList() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.method) {
                "GET" -> json(
                    """{"movies":[{"rating":8,"rated_at":"2025-10-21T14:00:00Z","movie":{"title":"The Shawshank Redemption","ids":{"imdb":"tt0111161","tmdb":278}}}],"shows":[],"seasons":[],"episodes":[],"pagination":{"total":1,"limit":100,"offset":0}}""",
                )
                else -> json("""{"updated":{"movies":1},"not_found":{},"errors":[]}""")
            }
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as Rating
        assertEquals(8, tracker.rating(RatingTarget(RatingKind.MOVIE, ExternalIds(tmdb = 278))))
        tracker.clearRating(RatingTarget(RatingKind.MOVIE, ExternalIds(imdb = "tt0111161")))
        assertEquals(parse("""{"movies":[{"ids":{"imdb":"tt0111161"}}]}"""), parse(service.to("/sync/ratings/remove").single().body))
        assertFailsWith<TrackerException.Unsupported> { tracker.rate(RatingTarget(RatingKind.SHOW, ExternalIds(tvdb = 81189)), 7) }
    }

    @Test
    fun aRatingTargetWithoutAnImdbOrTmdbIdIsUnsupportedAndSendsNothing() = runTest {
        val service = ScriptedService(this) { json("{}") }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as Rating
        val target = RatingTarget(RatingKind.SHOW, ExternalIds(tvdb = 81189, anidb = 69))

        assertFailsWith<TrackerException.Unsupported> { tracker.rating(target) }
        assertFailsWith<TrackerException.Unsupported> { tracker.rate(target, 7) }
        assertFailsWith<TrackerException.Unsupported> { tracker.clearRating(target) }
        assertEquals(emptyList(), service.requests)
    }

    @Test
    fun theWatchIsLeftToMdblistFromItsOwnRuleAndRecordedBelowIt() = runTest {
        val service = ScriptedService(this) { json("""{"updated":{"movies":1},"not_found":{},"errors":[]}""") }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as RealtimeScrobble
        tracker.reconcileWatchedAfterStop(movie, 80.0)
        assertEquals(emptyList(), service.requests)
        tracker.reconcileWatchedAfterStop(movie, 79.9)
        // A live mark carries no date.
        assertEquals(parse("""{"movies":[{"ids":{"imdb":"tt0111161","tmdb":278}}]}"""), parse(service.to("/sync/watched").single().body))
    }

    @Test
    fun aSeasonRatesThroughTheNestedShowShape() = runTest {
        val service = ScriptedService(this) { json("""{"updated":{"seasons":1},"not_found":{},"errors":[]}""") }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.MDBLIST)) as Rating
        tracker.rate(RatingTarget(RatingKind.SEASON, ExternalIds(imdb = "tt0903747"), season = 2), 9)
        assertEquals(
            parse("""{"shows":[{"ids":{"imdb":"tt0903747"},"seasons":[{"number":2,"rating":9}]}]}"""),
            parse(service.to("/sync/ratings").single().body),
        )
    }
}
