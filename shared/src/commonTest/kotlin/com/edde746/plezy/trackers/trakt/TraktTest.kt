package com.edde746.plezy.trackers.trakt

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.ApiFailureCategory
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.ratings.RatingTitle
import com.edde746.plezy.trackers.ratings.TitleIds
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException

/**
 * Trakt against its documented answers (docs.trakt.tv):
 * - device codes: https://docs.trakt.tv/reference/postoauthdevicecode, https://docs.trakt.tv/reference/postoauthdevicetoken
 * - tokens: https://docs.trakt.tv/reference/postoauthtoken, https://docs.trakt.tv/docs/authentication-oauth
 * - scrobble: https://docs.trakt.tv/reference/postscrobblestart, …/postscrobblestop
 * - history and ratings: https://docs.trakt.tv/reference/postsynchistory, …/getsyncratings, …/postsyncratings
 */
class TraktTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = TraktProvider(service.http(TrackerService.TRAKT), "client-id", "") { now }

    private val movie = TrackerContext(
        kind = TrackerMediaKind.MOVIE,
        ids = ExternalIds(imdb = "tt0111161", tmdb = 278),
    )

    private val episode = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(imdb = "tt0903747", tvdb = 81189),
        season = 1,
        episode = 2,
    )

    @Test
    fun scrobblesSendTheItemAndProgressAndASeekIsPauseThenStart() = runTest {
        val service = ScriptedService(this) { request ->
            // A duplicate within Trakt's window is a 409 that counts as done.
            if (request.path == "/scrobble/stop") json("""{"watched_at":"2026-09-29T18:42:10.000Z","expires_at":"2026-09-30T18:42:10.000Z"}""", 409) else json("{}", 201)
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as RealtimeScrobble
        tracker.scrobble(episode, ScrobbleState.START, 1.5)
        tracker.scrobble(episode, ScrobbleState.SEEK, 42.0)
        tracker.scrobble(movie, ScrobbleState.STOP, 91.25)

        assertEquals(listOf("/scrobble/start", "/scrobble/pause", "/scrobble/start", "/scrobble/stop"), service.requests.map { it.path })
        assertEquals(
            parse("""{"show":{"ids":{"imdb":"tt0903747","tvdb":81189}},"episode":{"season":1,"number":2},"progress":1.5}"""),
            parse(service.requests[0].body),
        )
        assertEquals(parse("""{"movie":{"ids":{"imdb":"tt0111161","tmdb":278}},"progress":91.25}"""), parse(service.requests[3].body))
        assertEquals("Bearer access-1", service.requests[0].headers["Authorization"])
    }

    @Test
    fun aSeeksPauseAndStartGoASecondApartAsTraktsWriteLimitAsks() = runTest {
        val sentAt = mutableListOf<Long>()
        val service = ScriptedService(this) {
            sentAt += testScheduler.currentTime
            json("{}", 201)
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as RealtimeScrobble
        tracker.scrobble(episode, ScrobbleState.SEEK, 42.0)
        assertEquals(listOf("/scrobble/pause", "/scrobble/start"), service.requests.map { it.path })
        assertTrue(sentAt[1] - sentAt[0] >= 1_000, "${sentAt[1] - sentAt[0]} ms apart")
    }

    @Test
    fun historyWritesCarryTheWatchDateAndAStopBelowTraktsRuleIsRecorded() = runTest {
        val service = ScriptedService(this) { json("""{"added":{"movies":1,"episodes":0}}""", 201) }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as RealtimeScrobble
        tracker.markWatched(episode, Instant.parse("2026-09-28T20:00:00Z"))
        tracker.markUnwatched(movie)
        // 85% already recorded a play at Trakt; 75% did not, and the profile's lower threshold still counts it.
        tracker.reconcileWatchedAfterStop(movie, 85.0)
        tracker.reconcileWatchedAfterStop(movie, 75.0)

        assertEquals(listOf("/sync/history", "/sync/history/remove", "/sync/history"), service.requests.map { it.path })
        assertEquals(
            parse(
                """{"shows":[{"ids":{"imdb":"tt0903747","tvdb":81189},"seasons":[{"number":1,"episodes":[{"watched_at":"2026-09-28T20:00:00Z","number":2}]}]}]}""",
            ),
            parse(service.requests[0].body),
        )
        assertEquals(parse("""{"movies":[{"ids":{"imdb":"tt0111161","tmdb":278}}]}"""), parse(service.requests[1].body))
    }

    @Test
    fun aBatchIsOneRequestWithEachShowsEpisodesUnderIt() = runTest {
        val service = ScriptedService(this) { json("""{"added":{"movies":1,"episodes":3}}""", 201) }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as EpisodeHistory
        val at = Instant.parse("2026-09-28T20:00:00Z")
        val items = listOf(
            HistoryItem(episode, at),
            HistoryItem(movie, at),
            HistoryItem(episode.copy(season = 2, episode = 1), at),
            HistoryItem(episode.copy(episode = 3), at),
            // Named twice: sent once.
            HistoryItem(episode, at),
            // Nothing to name it by: left out.
            HistoryItem(episode.copy(season = null), at),
        )
        tracker.writeHistory(items, watched = true)
        tracker.writeHistory(items, watched = false)

        assertEquals(listOf("/sync/history", "/sync/history/remove"), service.requests.map { it.path })
        val date = "\"watched_at\":\"2026-09-28T20:00:00Z\""
        assertEquals(
            parse(
                """{"movies":[{"ids":{"imdb":"tt0111161","tmdb":278},$date}],"shows":[{"ids":{"imdb":"tt0903747","tvdb":81189},"seasons":[""" +
                    """{"number":1,"episodes":[{"number":2,$date},{"number":3,$date}]},{"number":2,"episodes":[{"number":1,$date}]}]}]}""",
            ),
            parse(service.requests[0].body),
        )
        assertEquals(
            parse(
                """{"movies":[{"ids":{"imdb":"tt0111161","tmdb":278}}],"shows":[{"ids":{"imdb":"tt0903747","tvdb":81189},"seasons":[""" +
                    """{"number":1,"episodes":[{"number":2},{"number":3}]},{"number":2,"episodes":[{"number":1}]}]}]}""",
            ),
            parse(service.requests[1].body),
        )
    }

    @Test
    fun anEpisodeWithoutExternalNumbersIsNotWritten() = runTest {
        val service = ScriptedService(this) { error("no request expected") }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as RealtimeScrobble
        tracker.markWatched(episode.copy(season = null, episode = null))
        tracker.scrobble(movie.copy(ids = ExternalIds()), ScrobbleState.START, 0.0)
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun aRejectedTokenIsRefreshedOnceAndTheRequestRetried() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.headers["Authorization"] == "Bearer access-1") Answer(401) else json("{}", 201)
        }
        val credentials = FakeCredentials(TrackerService.TRAKT)
        provider(service).tracker(credentials).markWatched(movie)
        assertEquals(1, credentials.refreshes)
        assertEquals(listOf("Bearer access-1", "Bearer access-2"), service.requests.map { it.headers["Authorization"] })
    }

    @Test
    fun failuresMapToTheirKinds() = runTest {
        suspend fun failure(answer: () -> Answer, credentials: FakeCredentials = FakeCredentials(TrackerService.TRAKT)): Throwable =
            assertFailsWith<TrackerException> { provider(ScriptedService(this) { answer() }).tracker(credentials).markWatched(movie) }

        val limited = assertIs<TrackerException.RateLimited>(failure({ Answer(429, headers = mapOf("Retry-After" to "30")) }))
        assertEquals(30, limited.retryAfterSeconds)
        assertTrue(limited.transient)
        // A timestamp (or milliseconds) sent as Retry-After isn't a wait of years: the service's own hold applies.
        val stamped = assertIs<TrackerException.RateLimited>(failure({ Answer(429, headers = mapOf("Retry-After" to "1767225600")) }))
        assertNull(stamped.retryAfterSeconds)

        val outage = assertIs<TrackerException.Api>(failure({ Answer(503) }))
        assertEquals(503, outage.status)
        assertTrue(outage.transient)

        val refused = assertIs<TrackerException.Api>(failure({ Answer(422) }))
        assertEquals(false, refused.transient)

        val dead = FakeCredentials(TrackerService.TRAKT).apply {
            refreshFailure = TrackerException.Auth(TrackerService.TRAKT, "refresh failed", 400, permanent = true)
        }
        val expired = assertIs<TrackerException.Auth>(failure({ Answer(401) }, dead))
        assertTrue(expired.permanent)

        val offline = assertFailsWith<TrackerException.Network> {
            provider(ScriptedService(this) { throw IOException("offline") }).tracker(FakeCredentials(TrackerService.TRAKT)).markWatched(movie)
        }
        assertTrue(offline.transient)
    }

    @Test
    fun anAnswerThatCantBeReadFailsRatherThanReadingAsNothing() = runTest {
        val rated = RatingTarget(RatingKind.MOVIE, ExternalIds(imdb = "tt0111161"))
        // A captive portal's page, an empty body, and an object where Trakt documents a list.
        for (body in listOf("<html>Sign in to the Wi-Fi</html>", "", """{"status":"ok"}""")) {
            val provider = provider(ScriptedService(this) { json(body) })
            val credentials = FakeCredentials(TrackerService.TRAKT)
            val reads: List<suspend () -> Any?> = listOf(
                { (provider.tracker(credentials) as Rating).rating(rated) },
            )
            for (read in reads) {
                assertEquals(ApiFailureCategory.UNREADABLE, assertFailsWith<TrackerException.Api>(body) { read() }.category)
            }
        }
        val portal = provider(ScriptedService(this) { json("<html>Sign in to the Wi-Fi</html>") })
        val ratings = portal.ratings(FakeCredentials(TrackerService.TRAKT))
        val failure = assertFailsWith<TrackerException.Api> { ratings.ratings(RatingTitle(true, TitleIds(imdb = "tt0111161"))) }
        assertEquals(ApiFailureCategory.UNREADABLE, failure.category)
    }

    @Test
    fun ratingsReadTheMatchingEntryAndWriteTheScore() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/sync/ratings/episodes" -> json(
                    """[
                      {"rated_at":"2026-01-01T00:00:00.000Z","rating":7,"type":"episode","episode":{"season":1,"number":1,"ids":{"trakt":1}},"show":{"title":"Breaking Bad","ids":{"trakt":1388,"imdb":"tt0903747","tvdb":81189}}},
                      {"rated_at":"2026-01-02T00:00:00.000Z","rating":9,"type":"episode","episode":{"season":1,"number":2,"ids":{"trakt":2}},"show":{"title":"Breaking Bad","ids":{"trakt":1388,"imdb":"tt0903747","tvdb":81189}}}
                    ]""",
                )
                else -> json("""{"added":{"episodes":1}}""", 201)
            }
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as Rating
        val target = RatingTarget(RatingKind.EPISODE, ExternalIds(imdb = "tt0903747"), season = 1, episode = 2)
        assertEquals(9, tracker.rating(target))
        assertNull(tracker.rating(target.copy(episode = 3)))

        tracker.rate(target, 12)
        assertEquals(
            parse("""{"shows":[{"ids":{"imdb":"tt0903747"},"seasons":[{"number":1,"episodes":[{"number":2,"rating":10}]}]}]}"""),
            parse(service.to("/sync/ratings").single().body),
        )
        tracker.clearRating(RatingTarget(RatingKind.MOVIE, ExternalIds(tmdb = 278)))
        assertEquals(parse("""{"movies":[{"ids":{"tmdb":278}}]}"""), parse(service.to("/sync/ratings/remove").single().body))
    }

    @Test
    fun aConflictIsDoneForAScrobbleButNotForAHistoryWrite() = runTest {
        val service = ScriptedService(this) { json("""{"watched_at":"2026-09-29T18:42:10.000Z"}""", 409) }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as RealtimeScrobble
        tracker.scrobble(movie, ScrobbleState.START, 0.0)
        tracker.scrobble(movie, ScrobbleState.STOP, 90.0)
        assertEquals(409, assertFailsWith<TrackerException.Api> { tracker.markWatched(movie) }.status)
    }

    @Test
    fun aSeasonRatesNestedUnderItsShowAndATitleWithoutIdsIsNotAvailable() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                // The inline `season.show` wins over a sibling `show`.
                "/sync/ratings/seasons" -> json(
                    """[{"rating":6,"season":{"number":2,"show":{"ids":{"tvdb":81189}}},"show":{"ids":{"tvdb":1}}}]""",
                )
                else -> json("""{"added":{"seasons":1}}""", 201)
            }
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.TRAKT)) as Rating
        val season = RatingTarget(RatingKind.SEASON, ExternalIds(tvdb = 81189), season = 2)
        assertEquals(6, tracker.rating(season))
        assertNull(tracker.rating(season.copy(season = 3)))
        tracker.rate(season, 0)
        assertEquals(
            parse("""{"shows":[{"ids":{"tvdb":81189},"seasons":[{"number":2,"rating":1}]}]}"""),
            parse(service.to("/sync/ratings").single().body),
        )
        val requests = service.requests.size
        assertFailsWith<TrackerException.Unsupported> { tracker.rate(RatingTarget(RatingKind.MOVIE), 7) }
        assertFailsWith<TrackerException.Unsupported> { tracker.rating(RatingTarget(RatingKind.SHOW)) }
        assertEquals(requests, service.requests.size, "nothing sent")
    }
}
