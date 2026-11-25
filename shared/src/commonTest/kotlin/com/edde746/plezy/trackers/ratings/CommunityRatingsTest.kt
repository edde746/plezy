package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerIdResolverFactory
import com.edde746.plezy.trackers.TrackerService
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame
import kotlin.time.Duration.Companion.minutes

internal fun r(source: String, value: Double, votes: Int? = null) = MediaRatingSource(source, value, votes)

internal fun scores(ratings: List<MediaRatingSource>) = ratings.map { it.source to it.value }

/** A tracker's community scores as a test scripts them: [ratings], or [error]; [gate] holds the answer back. */
internal class FakeRatingsSource(
    override val service: TrackerService,
    var ratings: List<MediaRatingSource>,
    override val needsAnimeIds: Boolean = false,
) : TrackerRatingsSource {
    var error: Exception? = null
    var gate: CompletableDeferred<Unit>? = null
    val asked = mutableListOf<RatingTitle>()
    val calls: Int get() = asked.size

    override suspend fun ratings(title: RatingTitle): List<MediaRatingSource> {
        asked += title
        gate?.await()
        error?.let { throw it }
        return ratings
    }
}

internal fun TestScope.trackerRatings(
    sources: List<TrackerRatingsSource>,
    resolvers: TrackerIdResolverFactory = TrackerIdResolverFactory { _, _ -> error("no media server in this test") },
) = TrackerRatings({ flowOf(sources) }, resolvers, testScheduler.timeSource)

/** The scores each tracker reports, merged into one per source, and the loader that asks them. */
class CommunityRatingsTest {
    private val ids = TitleIds(imdb = "tt0111161")

    private fun TrackerRatings.movie(sources: List<TrackerRatingsSource>, ids: TitleIds = this@CommunityRatingsTest.ids): Flow<List<MediaRatingSource>> =
        load(sources) { RatingTitle(movie = true, ids) }

    @Test
    fun keepsOneScorePerSourceItsOwnServiceThenMdblistThenSimklThenTheRest() {
        val merged = mergeCommunityRatings(
            listOf(
                RatingsAnswer(TrackerService.MYANIMELIST, listOf(r("mal", 8.6))),
                RatingsAnswer(TrackerService.SIMKL, listOf(r("simkl", 8.4), r("imdb", 9.0), r("mal", 8.5))),
                RatingsAnswer(TrackerService.MDBLIST, listOf(r("imdb", 9.3), r("trakt", 9.1), r("mal", 8.0))),
                RatingsAnswer(TrackerService.TRAKT, listOf(r("trakt", 8.8))),
            ),
        )

        assertEquals(listOf("imdb" to 9.3, "trakt" to 8.8, "simkl" to 8.4, "mal" to 8.6), scores(merged))
    }

    @Test
    fun aLaterAnswerFromALowerPrecedenceTrackerDoesNotReplaceAnEarlierOne() {
        val merged = mergeCommunityRatings(
            listOf(
                RatingsAnswer(TrackerService.MDBLIST, listOf(r("imdb", 9.3))),
                RatingsAnswer(TrackerService.SIMKL, listOf(r("imdb", 9.0))),
            ),
        )

        assertEquals(listOf("imdb" to 9.3), scores(merged))
    }

    @Test
    fun ordersRottenTomatoesImdbTmdbMetacriticLetterboxdBeforeTheTrackers() {
        val merged = mergeCommunityRatings(
            listOf(
                RatingsAnswer(
                    TrackerService.MDBLIST,
                    listOf(
                        r("letterboxd", 9.2),
                        r("trakt", 9.1),
                        r("metacritic", 8.2),
                        r("tmdb", 8.7),
                        r("imdb", 9.3),
                        r("rottenTomatoesAudience", 9.8),
                        r("rottenTomatoesCritic", 8.9),
                    ),
                ),
                RatingsAnswer(TrackerService.ANILIST, listOf(r("anilist", 8.5))),
            ),
        )

        assertEquals(
            listOf("rottenTomatoesCritic", "rottenTomatoesAudience", "imdb", "tmdb", "metacritic", "letterboxd", "trakt", "anilist"),
            merged.map { it.source },
        )
    }

    @Test
    fun communityScoresReplaceTheServersCopyAndKeepSourcesTheTrackersLackInDisplayOrder() {
        val own = listOf(r("critic", 7.0), r("imdb", 8.1), r("rottenTomatoes", 9.0), r("tmdb", 7.5))
        val community = listOf(r("imdb", 8.3), r("rottenTomatoesCritic", 9.1), r("trakt", 8.0))

        assertEquals(
            listOf("rottenTomatoesCritic" to 9.1, "imdb" to 8.3, "tmdb" to 7.5, "trakt" to 8.0, "critic" to 7.0),
            scores(withCommunityRatings(own, community)),
        )
    }

    @Test
    fun theItemsScoresStayUnchangedWhileNoTrackerHasAnswered() {
        val own = listOf(r("audience", 6.0), r("imdb", 8.1))

        assertSame(own, withCommunityRatings(own, emptyList()))
    }

    @Test
    fun growsTheMergedListAsEachTrackerAnswersAndCompletesWhenAllHave() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val mdblist = FakeRatingsSource(TrackerService.MDBLIST, listOf(r("imdb", 9.3), r("trakt", 8.0)))
        val traktGate = CompletableDeferred<Unit>().also { trakt.gate = it }
        val loader = trackerRatings(listOf(trakt, mdblist))

        val emissions = mutableListOf<List<Pair<String, Double>>>()
        val done = launch { loader.movie(listOf(trakt, mdblist)).collect { emissions += scores(it) } }
        runCurrent()
        assertEquals(listOf(listOf("imdb" to 9.3, "trakt" to 8.0)), emissions)

        traktGate.complete(Unit)
        done.join()
        assertEquals(listOf("imdb" to 9.3, "trakt" to 9.1), emissions.last())
    }

    @Test
    fun leavesOutTrackersWithoutScoresTrackersThatFailAndTitlesOutsideATracker() = runTest {
        val failing = FakeRatingsSource(TrackerService.SIMKL, listOf(r("simkl", 8.0))).apply { error = IllegalStateException("down") }
        val outside = FakeRatingsSource(TrackerService.MYANIMELIST, listOf(r("mal", 8.0)))
        val empty = FakeRatingsSource(TrackerService.ANILIST, emptyList())
        val scoring = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val loader = trackerRatings(emptyList())

        val emissions = loader.load(listOf(failing, outside, empty, scoring)) { source ->
            if (source === outside) null else RatingTitle(movie = true, ids)
        }.toList()

        assertEquals(listOf(listOf("trakt" to 9.1)), emissions.map(::scores))
        assertEquals(0, outside.calls)
    }

    @Test
    fun emitsNothingAndCompletesWhenNoTrackerIsConnected() = runTest {
        assertEquals(emptyList(), trackerRatings(emptyList()).movie(emptyList()).toList())
    }

    @Test
    fun asksATrackerAgainOnceItsAnswerIsOlderThanTheTtl() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val loader = trackerRatings(listOf(trakt))

        loader.movie(listOf(trakt)).toList()
        advanceTimeBy(TrackerRatings.TTL - 1.minutes)
        loader.movie(listOf(trakt)).toList()
        assertEquals(1, trakt.calls)

        advanceTimeBy(2.minutes)
        loader.movie(listOf(trakt)).toList()
        assertEquals(2, trakt.calls)
    }

    @Test
    fun keepsATitleATrackerDoesNotKnowButAsksAgainAfterAFailure() = runTest {
        val unknown = FakeRatingsSource(TrackerService.MYANIMELIST, emptyList())
        val failing = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1))).apply { error = IllegalStateException("timeout") }
        val loader = trackerRatings(emptyList())

        loader.movie(listOf(unknown, failing)).toList()
        failing.error = null
        val second = loader.movie(listOf(unknown, failing)).toList()

        assertEquals(1, unknown.calls)
        assertEquals(2, failing.calls)
        assertEquals(listOf("trakt" to 9.1), scores(second.last()))
    }

    @Test
    fun keepsTitlesApartByKindAndIds() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val loader = trackerRatings(emptyList())

        loader.movie(listOf(trakt)).toList()
        loader.load(listOf(trakt)) { RatingTitle(movie = false, ids) }.toList()
        loader.movie(listOf(trakt), TitleIds(imdb = "tt0068646")).toList()

        assertEquals(3, trakt.calls)
    }

    @Test
    fun evictsTheLeastRecentlyUsedTitleBeyondCapacity() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val loader = trackerRatings(emptyList())
        suspend fun visit(n: Int) = loader.movie(listOf(trakt), TitleIds(tmdb = n)).toList()

        for (n in 0 until TrackerRatings.CAPACITY) visit(n)
        visit(0) // most recently used again
        visit(TrackerRatings.CAPACITY) // evicts 1
        val calls = trakt.calls

        visit(0)
        assertEquals(calls, trakt.calls)
        visit(1)
        assertEquals(calls + 1, trakt.calls)
    }

    @Test
    fun concurrentAsksForOneTitleShareOneRequest() = runTest {
        val trakt = FakeRatingsSource(TrackerService.TRAKT, listOf(r("trakt", 9.1)))
        val gate = CompletableDeferred<Unit>().also { trakt.gate = it }
        val loader = trackerRatings(emptyList())

        val first = launch { loader.movie(listOf(trakt)).toList() }
        val second = launch { loader.movie(listOf(trakt)).toList() }
        runCurrent()
        gate.complete(Unit)
        first.join()
        second.join()

        assertEquals(1, trakt.calls)
    }
}
