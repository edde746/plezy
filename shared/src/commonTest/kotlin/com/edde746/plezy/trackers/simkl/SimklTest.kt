package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.ServiceChannel
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
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.days
import kotlin.time.Instant
import kotlinx.coroutines.test.runTest

/**
 * Simkl against its documented answers (api.simkl.org):
 * - AUTH V2 device flow: https://api.simkl.org/api-reference/oauth2-device
 * - tokens and refresh: https://api.simkl.org/api-reference/oauth2-tokens, scopes: …/oauth2-scopes
 * - headers, and which calls carry the user's token: https://api.simkl.org/conventions/headers, …/api-reference/auth-v2
 * - scrobble: https://api.simkl.org/guides/scrobble
 * - history: https://api.simkl.org/api-reference/simkl/add-to-history; anime numbering: https://api.simkl.org/guides/anime
 * - ratings: https://api.simkl.org/api-reference/simkl/get-user-ratings, …/add-ratings
 * - plan to watch: https://api.simkl.org/api-reference/simkl/get-all-items
 * - ids: https://api.simkl.org/conventions/standard-media-objects
 * - title scores: https://api.simkl.org/api-reference/simkl/redirect, …/get-anime
 */
class SimklTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = SimklProvider(service.http(TrackerService.SIMKL), "client-id", "legacy-client-id", "1.0") { now }

    /** An AUTH V2 account: its token refreshes on a 401. */
    private fun credentials() = FakeCredentials(TrackerService.SIMKL, token = "simkl_at_1", refreshed = "simkl_at_2")


    private val episode = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(imdb = "tt0944947", tmdb = 1399),
        season = 1,
        episode = 2,
    )

    /** Attack on Titan S3E13 (TVDB), which Simkl files as episode 1 of its own "Season 3 part 2" entry (guides/anime). */
    private val animeEpisode = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(tmdb = 1429, tvdb = 267440),
        anime = AnimeIds(simkl = 931899),
        season = 3,
        episode = 13,
    )

    private val movie = TrackerContext(
        kind = TrackerMediaKind.MOVIE,
        ids = ExternalIds(imdb = "tt1375666"),
    )

    @Test
    fun scrobblesCarryTwoDecimalsASeekSendsNothingAndAStopConflictIsDone() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.path == "/scrobble/stop") json("""{"watched_at":"2026-09-29T18:42:10Z","expires_at":"2026-09-29T19:42:10Z"}""", 409) else json("""{"id":1,"action":"start"}""", 201)
        }
        val tracker = provider(service).tracker(credentials()) as RealtimeScrobble
        tracker.scrobble(episode, ScrobbleState.START, 42.4567)
        tracker.scrobble(episode, ScrobbleState.SEEK, 60.0)
        tracker.scrobble(episode, ScrobbleState.STOP, 95.0)

        assertEquals(listOf("/scrobble/start", "/scrobble/stop"), service.requests.map { it.path })
        assertEquals(
            parse("""{"progress":42.46,"show":{"ids":{"tmdb":1399,"imdb":"tt0944947"}},"episode":{"season":1,"number":2}}"""),
            parse(service.requests[0].body),
        )
        val start = service.requests[0]
        assertEquals("client-id", start.url.parameters["client_id"])
        assertEquals("plezy", start.url.parameters["app-name"])
        assertEquals("1.0", start.url.parameters["app-version"])
        assertEquals("client-id", start.headers["simkl-api-key"])
        assertEquals("Bearer simkl_at_1", start.headers["Authorization"])
        // A conflict on start, pause or a history write is not documented as success.
        val conflicted = ScriptedService(this) { json("{}", 409) }
        val conflictedTracker = provider(conflicted).tracker(credentials()) as RealtimeScrobble
        assertIs<TrackerException.Api>(assertFailsWith<TrackerException> { conflictedTracker.scrobble(movie, ScrobbleState.START, 1.0) })
        assertIs<TrackerException.Api>(assertFailsWith<TrackerException> { conflictedTracker.scrobble(movie, ScrobbleState.PAUSE, 1.0) })
        assertIs<TrackerException.Api>(assertFailsWith<TrackerException> { conflictedTracker.markWatched(movie) })
    }

    @Test
    fun historyWritesTheEpisodeUnderItsShow() = runTest {
        val service = ScriptedService(this) { json("""{"added":{"movies":0,"shows":1,"episodes":1}}""", 201) }
        val tracker = provider(service).tracker(credentials()) as RealtimeScrobble
        tracker.markWatched(episode)
        tracker.reconcileWatchedAfterStop(movie, 80.0)
        tracker.markUnwatched(movie)

        assertEquals(listOf("/sync/history", "/sync/history/remove"), service.requests.map { it.path })
        assertEquals(
            parse("""{"shows":[{"ids":{"tmdb":1399,"imdb":"tt0944947"},"use_tvdb_anime_seasons":true,"seasons":[{"number":1,"episodes":[{"number":2}]}]}]}"""),
            parse(service.requests[0].body),
        )
        assertEquals(parse("""{"movies":[{"ids":{"imdb":"tt1375666"}}]}"""), parse(service.requests[1].body))
    }

    @Test
    fun `a watch replayed a day late keeps its watched at and an unknown title comes back`() = runTest {
        val yesterday = Instant.fromEpochSeconds(now) - 1.days
        val service = ScriptedService(this) {
            json("""{"added":{"movies":0,"shows":1,"episodes":1},"not_found":{"movies":[{"ids":{"imdb":"tt1375666"}}],"shows":[]}}""", 201)
        }
        val tracker = provider(service).tracker(credentials()) as EpisodeHistory
        val items = listOf(HistoryItem(episode, yesterday), HistoryItem(movie, yesterday))

        val rejected = tracker.writeHistory(items, watched = true)

        assertEquals(
            parse(
                """{"movies":[{"ids":{"imdb":"tt1375666"},"watched_at":"$yesterday"}],"shows":[{"ids":{"tmdb":1399,"imdb":"tt0944947"},""" +
                    """"use_tvdb_anime_seasons":true,"seasons":[{"number":1,"episodes":[{"number":2,"watched_at":"$yesterday"}]}]}]}""",
            ),
            parse(service.requests.single().body),
        )
        assertEquals(listOf(HistoryItem(movie, yesterday)), rejected)
    }

    /**
     * An anime episode goes by its show's external ids in their own (TVDB) numbering, which Simkl maps onto its anime
     * entries; the mapping's Simkl id would pick one entry the numbers don't count in. An anime movie keeps it.
     */
    @Test
    fun anAnimeEpisodeGoesByItsShowsIdsAndAnAnimeMovieByItsSimklId() = runTest {
        val service = ScriptedService(this) { json("""{"id":1,"action":"start"}""", 201) }
        val tracker = provider(service).tracker(credentials()) as RealtimeScrobble
        tracker.scrobble(animeEpisode, ScrobbleState.START, 0.0)
        tracker.markWatched(animeEpisode)
        val animeMovie = movie.copy(ids = ExternalIds(imdb = "tt0245429"), anime = AnimeIds(simkl = 37207))
        tracker.markWatched(animeMovie)

        assertEquals(
            parse("""{"progress":0.0,"show":{"ids":{"tvdb":267440,"tmdb":1429}},"episode":{"season":3,"number":13}}"""),
            parse(service.to("/scrobble/start").single().body),
        )
        val (episodeMark, movieMark) = service.to("/sync/history")
        assertEquals(
            parse("""{"shows":[{"ids":{"tvdb":267440,"tmdb":1429},"use_tvdb_anime_seasons":true,"seasons":[{"number":3,"episodes":[{"number":13}]}]}]}"""),
            parse(episodeMark.body),
        )
        assertEquals(parse("""{"movies":[{"ids":{"simkl":37207,"imdb":"tt0245429"}}]}"""), parse(movieMark.body))
    }

    @Test
    fun aRejectedTokenRefreshesAndEachLimitSignalSaysWhenToComeBack() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.headers["Authorization"] == "Bearer simkl_at_1") Answer(401) else json("{}", 201)
        }
        val credentials = credentials()
        provider(service).tracker(credentials).markWatched(movie)
        assertEquals(1, credentials.refreshes)
        assertEquals(2, service.requests.size)

        // api.simkl.org/resources/rate-limits, "Limit signals": the body tells them apart, and each wants its own wait.
        suspend fun refusal(answer: Answer): TrackerException =
            assertFailsWith<TrackerException> { provider(ScriptedService(this) { answer }).tracker(credentials()).markWatched(movie) }
        suspend fun waitFor(answer: Answer): Long? = assertIs<TrackerException.RateLimited>(refusal(answer)).retryAfterSeconds
        // The daily quota waits its Retry-After; the per-second rate about a second, whatever Retry-After (the daily reset's) says.
        assertEquals(45_000, waitFor(Answer(429, """{"error":"user_limit_exceeded"}""", mapOf("Retry-After" to "45000"))))
        assertEquals(2, waitFor(Answer(429, """{"error":"rate_limit"}""", mapOf("Retry-After" to "45000"))))
        // A throttling block from POST overages, and the per-user write lock.
        assertEquals(300, waitFor(Answer(412, """{"error":"client_id_failed"}""")))
        assertEquals(5, waitFor(Answer(400, """{"error":"RATE_LIMIT"}""")))
        // Any other 400 is an answer about the write.
        assertIs<TrackerException.Api>(refusal(Answer(400, """{"error":"bad_request"}""")))
    }

    /** A stop between the profile's threshold and Simkl's 80 % is two writes, which the service's channel spaces. */
    @Test
    fun writesGoASecondApartAsSimklsLimitAsks() = runTest {
        val sentAt = mutableListOf<Long>()
        val service = ScriptedService(this) {
            sentAt += testScheduler.currentTime
            json("{}", 201)
        }
        val tracker = provider(service).tracker(credentials()) as RealtimeScrobble
        val channel = ServiceChannel(backgroundScope, TrackerService.SIMKL)
        channel.submit(ScrobbleState.STOP, tracker.writeSpacing) {
            tracker.scrobble(movie, ScrobbleState.STOP, 75.0)
            true
        }
        channel.submit(null, tracker.writeSpacing) {
            tracker.reconcileWatchedAfterStop(movie, 75.0)
            true
        }.await()
        assertEquals(listOf("/scrobble/stop", "/sync/history"), service.requests.map { it.path })
        assertTrue(sentAt[1] - sentAt[0] >= 1_000, "${sentAt[1] - sentAt[0]} ms apart")
    }

    @Test
    fun ratingsMatchStringIdsAndOnlyWholeTitlesAreRated() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/sync/ratings/shows" -> json(
                    """{"shows":[{"user_rated_at":"2026-01-01T00:00:00Z","user_rating":8,"status":"watching","show":{"title":"Game of Thrones","year":2011,"ids":{"simkl":17465,"imdb":"tt0944947","tvdb":"121361"}}}]}""",
                )
                "/sync/ratings/anime" -> json("{}")
                else -> json("""{"added":{"shows":1}}""", 201)
            }
        }
        val tracker = provider(service).tracker(credentials()) as Rating
        // tvdb comes back as a string; the local id is a number.
        assertEquals(8, tracker.rating(RatingTarget(RatingKind.SHOW, ExternalIds(tvdb = 121361))))
        tracker.rate(RatingTarget(RatingKind.SHOW, ExternalIds(imdb = "tt0944947")), 9)
        assertEquals(parse("""{"shows":[{"ids":{"imdb":"tt0944947"},"rating":9}]}"""), parse(service.to("/sync/ratings").single().body))
        tracker.clearRating(RatingTarget(RatingKind.MOVIE, ExternalIds(tmdb = 603)))
        assertEquals(parse("""{"movies":[{"ids":{"tmdb":603}}]}"""), parse(service.to("/sync/ratings/remove").single().body))
        assertFailsWith<TrackerException.Unsupported> { tracker.rate(RatingTarget(RatingKind.EPISODE, ExternalIds(imdb = "tt0944947"), season = 1, episode = 1), 9) }
        assertFailsWith<TrackerException.Unsupported> { tracker.rating(RatingTarget(RatingKind.SHOW, ExternalIds())) }
    }

    /** A show that isn't in `shows` may be filed under `anime`, matched by the mapping's Simkl id. */
    @Test
    fun aShowRatingIsLookedForInTheAnimeBucketToo() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/sync/ratings/shows" -> json("""{"shows":[]}""")
                "/sync/ratings/anime" -> json("""{"anime":[{"user_rating":9,"show":{"ids":{"simkl":987}}}]}""")
                else -> error("unexpected $request")
            }
        }
        val tracker = provider(service).tracker(FakeCredentials(TrackerService.SIMKL)) as Rating
        val target = RatingTarget(RatingKind.SHOW, ExternalIds(tvdb = 123, tmdb = 456, imdb = "tt789"), AnimeIds(simkl = 987))
        assertEquals(9, tracker.rating(target))
        assertEquals(listOf("/sync/ratings/shows", "/sync/ratings/anime"), service.requests.map { it.path })
    }

    /**
     * Title scores: `/redirect` carries the account's token (a V2 client gets 401 `user_token_required` without one;
     * a rejected token refreshes once) and isn't followed; the detail record goes without the token, so Simkl's edge
     * cache answers it.
     */
    @Test
    fun titleScoresResolveWithTheTokenAndReadTheCachedRecordWithout() = runTest {
        val service = ScriptedService(this) { request ->
            when {
                request.path == "/redirect" && request.headers["Authorization"] == "Bearer simkl_at_1" ->
                    json("""{"error":"user_token_failed","code":401}""", 401)
                request.path == "/redirect" -> Answer(301, headers = mapOf("Location" to "https://simkl.com/movies/53536/the-shawshank-redemption"))
                request.path == "/movies/53536" -> json("""{"title":"The Shawshank Redemption","ids":{"simkl":53536},"ratings":{"simkl":{"rating":8.9,"votes":13542},"imdb":{"rating":9.3,"votes":3207270}}}""")
                else -> error("unexpected $request")
            }
        }
        val credentials = credentials()
        val scores = provider(service).ratings(credentials).ratings(RatingTitle(movie = true, ids = TitleIds(imdb = "tt0111161", tmdb = 278)))

        assertEquals(listOf(MediaRatingSource("simkl", 8.9, 13542), MediaRatingSource("imdb", 9.3, 3207270)), scores)
        assertEquals(listOf("/redirect", "/redirect", "/movies/53536"), service.requests.map { it.path })
        assertEquals(1, credentials.refreshes)
        val redirect = service.requests[1]
        assertEquals("Bearer simkl_at_2", redirect.headers["Authorization"])
        assertEquals(listOf("simkl", "tt0111161", "278", "movie"), listOf("to", "imdb", "tmdb", "type").map { redirect.url.parameters[it] })
        val record = service.requests[2]
        assertEquals(null, record.headers["Authorization"])
        assertEquals("client-id", record.url.parameters["client_id"])
        assertEquals("plezy", record.url.parameters["app-name"])
    }
}
