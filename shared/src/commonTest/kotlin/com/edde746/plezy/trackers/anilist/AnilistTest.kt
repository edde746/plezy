package com.edde746.plezy.trackers.anilist

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.ApiFailureCategory
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RelayResult
import com.edde746.plezy.trackers.Tracker
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonElement

/**
 * AniList against its documented answers (docs.anilist.co):
 * - errors in a 200 body: https://docs.anilist.co/guide/graphql/errors
 * - rate limits (429, `Retry-After`): https://docs.anilist.co/guide/rate-limiting
 * - authenticated requests and token lifetime: https://docs.anilist.co/guide/auth/authenticated-requests
 * - `SaveMediaListEntry` and score formats: https://docs.anilist.co/guide/graphql/mutations,
 *   https://docs.anilist.co/reference/enum/scoreformat
 */
class AnilistTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = AnilistProvider(service.http(TrackerService.ANILIST)) { now }

    private fun ScriptedService.tracker(credentials: FakeCredentials = FakeCredentials(TrackerService.ANILIST)): Tracker =
        provider(this).tracker(credentials)

    private fun episode(episode: Int = 12, animeProgress: Int? = 12) = TrackerContext(
        kind = TrackerMediaKind.EPISODE,
        ids = ExternalIds(tvdb = 1),
        anime = AnimeIds(anilist = 21),
        season = 1,
        episode = episode,
        animeProgress = animeProgress,
    )

    private val movie = TrackerContext(TrackerMediaKind.MOVIE, ids = ExternalIds(tmdb = 1), anime = AnimeIds(anilist = 21))

    private val show = RatingTarget(RatingKind.SHOW, anime = AnimeIds(anilist = 21))

    private val Recorded.query: String get() = field("query").orEmpty()

    private val Recorded.variables: JsonElement? get() = json()["variables"]

    private val saved = """{"data":{"SaveMediaListEntry":{"id":1}}}"""

    /** AniList answering the snapshot query with [media] (the `Media` object) and every save. */
    private fun TestScope.anilist(media: String) = ScriptedService(this) { request ->
        if ("SaveMediaListEntry" in request.query) json(saved) else json("""{"data":{"Media":$media}}""")
    }

    private val ScriptedService.saves get() = requests.filter { "SaveMediaListEntry" in it.query }.map { it.variables }

    @Test
    fun aRelaySessionLastsAYearAndLooksUpTheViewer() = runTest {
        val service = ScriptedService(this) { json("""{"data":{"Viewer":{"name":"Josh"}}}""") }
        val session = provider(service).signIn.session(RelayResult("access-1", refreshToken = null, expiresInSeconds = null))
        assertEquals(TrackerSession("access-1", null, now + 365L * 24 * 60 * 60, "Josh", now), session)
        assertEquals("Bearer access-1", service.requests.single().headers["Authorization"])
        assertNull(provider(service).refresher)
    }

    @Test
    fun everyCallIsAGraphqlPostWithItsVariables() = runTest {
        val service = anilist("""{"episodes":12}""")
        service.tracker().markWatched(episode())
        for (request in service.requests) {
            assertEquals("POST", request.method)
            assertEquals("https://graphql.anilist.co", request.url.toString())
            assertTrue(request.contentType.orEmpty().startsWith("application/json"))
            assertEquals("application/json", request.headers["Accept"])
            assertEquals("Bearer access-1", request.headers["Authorization"])
        }
        assertEquals(parse("""{"mediaId":21}"""), service.requests.first().variables)
    }

    @Test
    fun aRefusedTokenSignsTheAccountOutAndErrorsMapToTheirKinds() = runTest {
        val credentials = FakeCredentials(TrackerService.ANILIST)
        val refused = ScriptedService(this) { json("""{"data":null,"errors":[{"message":"Invalid token","status":401}]}""", 401) }
        val auth = assertFailsWith<TrackerException.Auth> { (refused.tracker(credentials) as Rating).rating(show) }
        assertTrue(auth.permanent)
        assertTrue(credentials.invalidated)
        assertEquals(0, credentials.refreshes)

        val limited = ScriptedService(this) {
            Answer(429, """{"data":null,"errors":[{"message":"Too Many Requests.","status":429}]}""", mapOf("Retry-After" to "30"))
        }
        assertEquals(30, assertFailsWith<TrackerException.RateLimited> { (limited.tracker() as Rating).rating(show) }.retryAfterSeconds)

        val down = ScriptedService(this) { Answer(502) }
        assertEquals(502, assertFailsWith<TrackerException.Api> { (down.tracker() as Rating).rating(show) }.status)

        // A 200 may still carry errors.
        val invalid = ScriptedService(this) {
            json("""{"data":null,"errors":[{"message":"validation","status":400,"validation":{"score":["The score may not be greater than 100."]}}]}""")
        }
        val api = assertFailsWith<TrackerException.Api> { (invalid.tracker() as Rating).rate(show, 8) }
        assertEquals(ApiFailureCategory.GRAPHQL_ERRORS, api.category)
        assertEquals(false, api.transient)
    }

    @Test
    fun scopedProgressReachingTheTotalCompletesTheEntry() = runTest {
        val service = anilist("""{"episodes":12}""")
        service.tracker().markWatched(episode(animeProgress = 13))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":12,"status":"COMPLETED"}""")), service.saves)
    }

    @Test
    fun fallbackLocalProgressStaysCurrentWithoutUsingTheAnimeTotal() = runTest {
        val service = anilist("""{"episodes":10}""")
        service.tracker().markWatched(episode(animeProgress = null))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":12,"status":"CURRENT"}""")), service.saves)
    }

    @Test
    fun progressStaysCurrentWhileTheTotalIsUnknown() = runTest {
        val service = anilist("""{"episodes":null}""")
        service.tracker().markWatched(episode())
        assertEquals(listOf(parse("""{"mediaId":21,"progress":12,"status":"CURRENT"}""")), service.saves)
        assertTrue("repeat" !in service.requests.last().query, "repeat is in the document only when written")
    }

    @Test
    fun unwatchResetsAnInProgressEntryToZeroWithoutDeletingIt() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"CURRENT","repeat":0,"progress":5}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":0,"status":"CURRENT"}""")), service.saves)
        assertTrue(service.requests.none { "Delete" in it.query })
    }

    @Test
    fun unwatchKeepsARewatchInProgressAtZero() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"REPEATING","repeat":1,"progress":5}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":0,"status":"REPEATING"}""")), service.saves)
    }

    @Test
    fun unwatchLeavesACompletedEntryUntouched() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"COMPLETED","repeat":0,"progress":12}}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(emptyList(), service.saves)
    }

    @Test
    fun unwatchDoesNotCreateAnEntryForAnUnlistedAnime() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":null}""")
        service.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(emptyList(), service.saves)

        // An id AniList doesn't know answers 404 "Not Found.": no entry, nothing written.
        val unknown = ScriptedService(this) { json("""{"data":{"Media":null},"errors":[{"message":"Not Found.","status":404}]}""", 404) }
        unknown.tracker().markUnwatched(episode(animeProgress = null))
        assertEquals(1, unknown.requests.size)
    }

    @Test
    fun theSnapshotStaysCachedWhenTheWriteFails() = runTest {
        var reads = 0
        var saves = 0
        val service = ScriptedService(this) { request ->
            if ("SaveMediaListEntry" in request.query) {
                if (++saves == 1) Answer(500, "boom") else json(saved)
            } else {
                reads++
                json("""{"data":{"Media":{"episodes":12}}}""")
            }
        }
        val tracker = service.tracker()

        assertFailsWith<TrackerException.Api> { tracker.markWatched(episode()) }
        tracker.markWatched(episode())

        assertEquals(1, reads, "a failed write keeps the snapshot its retry needs")
        assertEquals(2, saves)
    }

    @Test
    fun aFailedLookupIsReadAgainByTheNextWrite() = runTest {
        var reads = 0
        val service = ScriptedService(this) { request ->
            if ("SaveMediaListEntry" in request.query) json(saved) else if (++reads == 1) Answer(500, "boom") else json("""{"data":{"Media":{"episodes":12}}}""")
        }
        val tracker = service.tracker()

        tracker.markWatched(episode())
        tracker.markWatched(episode())

        assertEquals(2, reads)
    }

    @Test
    fun aRepeatingEntryStaysRepeatingMidSeries() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"REPEATING","repeat":2}}""")
        service.tracker().markWatched(episode(episode = 5, animeProgress = 5))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":5,"status":"REPEATING"}""")), service.saves)
    }

    @Test
    fun aCompletedRewatchBumpsTheRepeatCount() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"REPEATING","repeat":2}}""")
        service.tracker().markWatched(episode(animeProgress = 12))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":12,"status":"COMPLETED","repeat":3}""")), service.saves)
        assertTrue("\$repeat: Int" in service.requests.last().query)
    }

    @Test
    fun newProgressOnACompletedEntryStartsARewatch() = runTest {
        val service = anilist("""{"episodes":12,"mediaListEntry":{"status":"COMPLETED","repeat":1}}""")
        service.tracker().markWatched(episode(episode = 1, animeProgress = 1))
        assertEquals(listOf(parse("""{"mediaId":21,"progress":1,"status":"REPEATING"}""")), service.saves)
    }

    @Test
    fun aMovieRewatchCompletesWithABumpedRepeatCount() = runTest {
        val service = anilist("""{"episodes":1,"mediaListEntry":{"status":"REPEATING","repeat":0}}""")
        service.tracker().markWatched(movie)
        assertEquals(listOf(parse("""{"mediaId":21,"progress":1,"status":"COMPLETED","repeat":1}""")), service.saves)
    }

    @Test
    fun sequentialRewatchWritesReadTheEntryAsTheLastWriteLeftIt() = runTest {
        var reads = 0
        val service = ScriptedService(this) { request ->
            if ("SaveMediaListEntry" in request.query) {
                json(saved)
            } else {
                // The second read is the entry after the first write; the stale first one would write repeat 3 again.
                val entry = if (++reads == 1) """{"status":"REPEATING","repeat":2}""" else """{"status":"COMPLETED","repeat":3}"""
                json("""{"data":{"Media":{"episodes":12,"mediaListEntry":$entry}}}""")
            }
        }
        val tracker = service.tracker()

        tracker.markWatched(episode(animeProgress = 12))
        tracker.markWatched(episode(animeProgress = 12))

        assertEquals(2, reads, "a successful write drops the snapshot")
        assertEquals(
            listOf(parse("""{"mediaId":21,"progress":12,"status":"COMPLETED","repeat":3}"""), parse("""{"mediaId":21,"progress":12,"status":"COMPLETED"}""")),
            service.saves,
        )
    }

    @Test
    fun aPoint100ScoreIsReadAsOneToTen() = runTest {
        var scoreRaw = "80"
        val service = ScriptedService(this) { request ->
            assertEquals(parse("""{"mediaId":21}"""), request.variables)
            assertTrue("mediaListEntry" in request.query)
            assertTrue("scoreRaw: score(format: POINT_100)" in request.query)
            json("""{"data":{"Media":{"mediaListEntry":{"scoreRaw":$scoreRaw}}}}""")
        }
        val tracker = service.tracker() as Rating
        assertEquals(8, tracker.rating(show))
        scoreRaw = "85"
        assertEquals(9, tracker.rating(show))
        scoreRaw = "4"
        assertEquals(1, tracker.rating(show))
        scoreRaw = "0"
        assertNull(tracker.rating(show))
        scoreRaw = "null"
        assertNull(tracker.rating(show))
    }

    @Test
    fun scoresAreWrittenAsPoint100AndZeroClears() = runTest {
        val service = anilist("{}")
        val tracker = service.tracker() as Rating
        tracker.rate(show, 7)
        tracker.rate(RatingTarget(RatingKind.EPISODE, anime = AnimeIds(anilist = 21), season = 1, episode = 2), 12)
        tracker.clearRating(show)
        assertEquals(
            listOf(parse("""{"mediaId":21,"scoreRaw":70}"""), parse("""{"mediaId":21,"scoreRaw":100}"""), parse("""{"mediaId":21,"scoreRaw":0}""")),
            service.saves,
        )
        assertFailsWith<TrackerException.Unsupported> { tracker.rate(show.copy(anime = AnimeIds(mal = 21)), 7) }
    }

    @Test
    fun anItemWithoutAnAnilistIdIsSkipped() = runTest {
        val service = anilist("""{"episodes":12}""")
        service.tracker().markWatched(episode().copy(anime = AnimeIds(mal = 21)))
        service.tracker().markUnwatched(episode().copy(anime = null))
        assertEquals(emptyList(), service.requests)
    }
}
