package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.anilist.AnilistProvider
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.mal.MalProvider
import com.edde746.plezy.trackers.mdblist.MdblistProvider
import com.edde746.plezy.trackers.simkl.SimklProvider
import com.edde746.plezy.trackers.trakt.TraktProvider
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/**
 * Each tracker's community scores against its documented answers (trimmed to the fields read):
 * - Trakt: docs.trakt.tv's examples for "Get movie ratings" and "ID Lookup";
 * - MyAnimeList: the API v2 reference's `GET /anime/{id}` example (30230);
 * - AniList: graphql.anilist.co's answer for Death Note (`idMal: 1535`), 2026-10-04;
 * - Simkl: api.simkl.org's examples for `/anime/{id}` (Death Note) and `/redirect`'s `Location`;
 * - MDBList: `GET /imdb/movie/tt0111161` as recorded in lzblack/douban-rankings' test fixtures (MIT).
 */
class TrackerScoresTest {
    private val now = 1_790_000_000L

    private fun movie(ids: TitleIds) = RatingTitle(movie = true, ids)

    private fun show(ids: TitleIds) = RatingTitle(movie = false, ids)

    private fun TestScope.scripted(vararg answers: Answer) = ArrayDeque(answers.toList()).let { queue -> ScriptedService(this) { queue.removeFirst() } }

    private fun trakt(service: ScriptedService) = TraktProvider(service.http(TrackerService.TRAKT), "client-id", "client-secret") { now }.ratings(FakeCredentials(TrackerService.TRAKT))

    private fun mal(service: ScriptedService) = MalProvider(service.http(TrackerService.MYANIMELIST), "client-id") { now }.ratings(FakeCredentials(TrackerService.MYANIMELIST))

    private fun anilist(service: ScriptedService) = AnilistProvider(service.http(TrackerService.ANILIST)) { now }.ratings(FakeCredentials(TrackerService.ANILIST))

    private fun simkl(service: ScriptedService) = SimklProvider(service.http(TrackerService.SIMKL), "client-id", "legacy-client-id", "2.26.0") { now }.ratings(FakeCredentials(TrackerService.SIMKL))

    private fun mdblist(service: ScriptedService) = MdblistProvider(service.http(TrackerService.MDBLIST), "client-id") { now }.ratings(FakeCredentials(TrackerService.MDBLIST))

    private fun assertScores(expected: List<MediaRatingSource>, actual: List<MediaRatingSource>) {
        assertEquals(expected.map { it.source to it.votes }, actual.map { it.source to it.votes })
        expected.zip(actual).forEach { (e, a) -> assertEquals(e.value, a.value, 1e-9, e.source) }
    }

    private val traktRatings = """{"rating":7.33778,"votes":7866,"distribution":{"1":298,"2":46,"3":87,"4":178,"5":446,"6":1167,"7":1855,"8":1543,"9":662,"10":1583}}"""
    private val traktLookup =
        """[{"type":"movie","score":null,"movie":{"title":"TRON: Legacy","year":2010,"ids":{"trakt":12601,"slug":"tron-legacy-2010","imdb":"tt1104001","tmdb":20526}}}]"""

    @Test
    fun traktLooksATmdbOnlyMovieUpByIdLookupThenReadsItsRatings() = runTest {
        val service = scripted(json(traktLookup), json(traktRatings))

        val ratings = trakt(service).ratings(movie(TitleIds(tmdb = 20526)))

        assertEquals(listOf("/search/tmdb/20526", "/movies/12601/ratings"), service.requests.map { it.path })
        assertEquals("movie", service.requests.first().url.parameters["type"])
        assertScores(listOf(r("trakt", 7.33778, 7866)), ratings)
    }

    @Test
    fun traktUsesAKnownTraktIdWithoutALookupAndDropsAScoreWithoutVotes() = runTest {
        val service = scripted(json("""{"rating":0,"votes":0,"distribution":{}}"""))

        val ratings = trakt(service).ratings(show(TitleIds(trakt = 1388, tmdb = 1396)))

        assertEquals("/shows/1388/ratings", service.requests.single().path)
        assertTrue(ratings.isEmpty())
    }

    @Test
    fun traktTakesASlugOrImdbIdBeforeLookingUp() = runTest {
        val service = scripted(json(traktRatings), json(traktRatings))

        trakt(service).ratings(movie(TitleIds(slug = "tron-legacy-2010", imdb = "tt1104001", tmdb = 20526)))
        trakt(service).ratings(movie(TitleIds(imdb = "tt1104001", tmdb = 20526)))

        assertEquals(listOf("/movies/tron-legacy-2010/ratings", "/movies/tt1104001/ratings"), service.requests.map { it.path })
    }

    @Test
    fun traktLooksATvdbOnlyShowUpByTvdbAndSkipsResultsOfTheOtherKind() = runTest {
        val service = scripted(json(traktLookup))

        val ratings = trakt(service).ratings(show(TitleIds(tvdb = 81189)))

        assertEquals("/search/tvdb/81189", service.requests.single().path)
        assertEquals("show", service.requests.single().url.parameters["type"])
        assertTrue(ratings.isEmpty())
    }

    @Test
    fun traktHasNoScoresForATitleItDoesNotKnow() = runTest {
        val service = scripted(json("""{"error":"not found"}""", 404))

        assertTrue(trakt(service).ratings(movie(TitleIds(imdb = "tt0111161"))).isEmpty())
        assertEquals("/movies/tt0111161/ratings", service.requests.single().path)
    }

    @Test
    fun traktNeedsAnIdItCanLookUp() = runTest {
        val service = scripted()

        assertTrue(trakt(service).ratings(movie(TitleIds(tvdb = 81189))).isEmpty())
        assertTrue(trakt(service).ratings(show(TitleIds(mal = 1535))).isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun traktPropagatesAFailureOtherThan404() = runTest {
        val service = scripted(json("oops", 500))

        assertEquals(500, assertFailsWith<TrackerException.Api> { trakt(service).ratings(movie(TitleIds(trakt = 1))) }.status)
    }

    @Test
    fun myAnimeListReadsTheMeanScoreAndItsScorers() = runTest {
        val service = scripted(
            json(
                """{"id":30230,"title":"Diamond no Ace: Second Season","main_picture":{"medium":"https://myanimelist.cdn-dena.com/images/anime/9/74398.jpg"},
                "mean":8.42,"num_scoring_users":29027}""",
            ),
        )

        val ratings = mal(service).ratings(show(TitleIds(mal = 30230, tvdb = 1)))

        assertEquals("/v2/anime/30230", service.requests.single().path)
        assertEquals("mean,num_scoring_users", service.requests.single().url.parameters["fields"])
        assertScores(listOf(r("mal", 8.42, 29027)), ratings)
    }

    @Test
    fun myAnimeListHasNoScoresForAnAnimeNobodyScoredOrItDoesNotKnow() = runTest {
        val service = scripted(json("""{"id":1,"title":"Not yet aired"}"""), json("""{"error":"not_found"}""", 404))

        assertTrue(mal(service).ratings(show(TitleIds(mal = 1))).isEmpty())
        assertTrue(mal(service).ratings(movie(TitleIds(mal = 999999))).isEmpty())
        assertEquals(2, service.requests.size)
    }

    @Test
    fun myAnimeListNeedsAMyAnimeListId() = runTest {
        val service = scripted()

        assertTrue(mal(service).ratings(show(TitleIds(tvdb = 267440, anilist = 1))).isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun myAnimeListPropagatesAFailureOtherThan404() = runTest {
        val service = scripted(json("oops", 500))

        assertEquals(500, assertFailsWith<TrackerException.Api> { mal(service).ratings(show(TitleIds(mal = 16498))) }.status)
    }

    @Test
    fun aniListAsksByAniListIdElseByMyAnimeListIdForA0To100Average() = runTest {
        val death = json("""{"data":{"Media":{"id":1535,"idMal":1535,"averageScore":84}}}""")
        val service = scripted(death, death)

        val byAnilist = anilist(service).ratings(show(TitleIds(anilist = 1535, mal = 1535)))
        val byMal = anilist(service).ratings(movie(TitleIds(mal = 1535)))

        assertEquals(listOf("""{"id":1535}""", """{"idMal":1535}"""), service.requests.map { it.json()["variables"].toString() })
        assertTrue(service.requests.first().json()["query"].toString().contains("averageScore"))
        assertScores(listOf(r("anilist", 8.4)), byAnilist)
        assertScores(listOf(r("anilist", 8.4)), byMal)
    }

    @Test
    fun aniListHasNoScoresWithoutAnAverageOrForAnAnimeItDoesNotKnow() = runTest {
        val service = scripted(
            json("""{"data":{"Media":null}}"""),
            json("""{"data":{"Media":{"id":1,"averageScore":null}}}"""),
            json("""{"errors":[{"message":"Not Found.","status":404}],"data":{"Media":null}}""", 404),
        )

        repeat(3) { assertTrue(anilist(service).ratings(show(TitleIds(anilist = 1))).isEmpty()) }
        assertEquals(3, service.requests.size)
    }

    @Test
    fun aniListNeedsAnAniListOrMyAnimeListId() = runTest {
        val service = scripted()

        assertTrue(anilist(service).ratings(show(TitleIds(tvdb = 267440))).isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun aniListPropagatesAFailureOtherThan404() = runTest {
        val service = scripted(json("oops", 500))

        assertEquals(500, assertFailsWith<TrackerException.Api> { anilist(service).ratings(show(TitleIds(anilist = 16498))) }.status)
    }

    @Test
    fun simklResolvesItsPageByAnUnfollowedRedirectThenReadsItsThreeScores() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/redirect" -> Answer(301, headers = mapOf("Location" to "https://simkl.com/anime/40190/death-note"))
                "/anime/40190" -> json(
                    """{"title":"Death Note","year":2006,"type":"anime","ids":{"simkl":40190,"slug":"death-note","imdb":"tt0877057","mal":"1535"},
                    "ratings":{"simkl":{"rating":9.0,"votes":4200},"mal":{"rating":8.6,"votes":3700000},"imdb":{"rating":9.0,"votes":410000}}}""",
                )
                else -> error("unexpected $request")
            }
        }

        val ratings = simkl(service).ratings(show(TitleIds(imdb = "tt0877057", tmdb = 13916, mal = 1535, anilist = 1535)))

        assertEquals(listOf("/redirect", "/anime/40190"), service.requests.map { it.path })
        val redirect = service.requests.first()
        assertEquals("api.simkl.com", redirect.url.host)
        assertEquals("Bearer access-1", redirect.headers["Authorization"])
        assertEquals(
            listOf("simkl", "tt0877057", "13916", "tv", "1535", "1535"),
            listOf("to", "imdb", "tmdb", "type", "mal", "anilist").map { redirect.url.parameters[it] },
        )
        assertScores(listOf(r("simkl", 9.0, 4200), r("imdb", 9.0, 410000), r("mal", 8.6, 3700000)), ratings)
    }

    @Test
    fun simklSendsAMoviesTmdbIdTypedAndTreatsADetail404AsNoScore() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.path == "/redirect") {
                Answer(301, headers = mapOf("Location" to "https://simkl.com/movies/53536/terminator-3-rise-of-the-machines"))
            } else {
                json("""{"error":"not_found"}""", 404)
            }
        }

        val ratings = simkl(service).ratings(movie(TitleIds(tmdb = 296, tvdb = 7)))

        assertEquals(listOf("/redirect", "/movies/53536"), service.requests.map { it.path })
        assertEquals("movie", service.requests.first().url.parameters["type"])
        assertEquals("7", service.requests.first().url.parameters["tvdb"])
        assertTrue(ratings.isEmpty())
    }

    @Test
    fun simklStopsAtARedirectThatNamesNoTitlePage() = runTest {
        val service = scripted(Answer(302, headers = mapOf("Location" to "https://simkl.com/search/?q=nothing")))

        assertTrue(simkl(service).ratings(movie(TitleIds(imdb = "tt0000001"))).isEmpty())
        assertEquals("/redirect", service.requests.single().path)
    }

    @Test
    fun simklNeedsAnIdItCanRedirectBy() = runTest {
        val service = scripted()

        assertTrue(simkl(service).ratings(show(TitleIds(simkl = 40190, trakt = 1))).isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun simklPropagatesAFailureOtherThan404() = runTest {
        val service = scripted(json("failed", 500))

        assertEquals(500, assertFailsWith<TrackerException.Api> { simkl(service).ratings(movie(TitleIds(imdb = "tt1375666"))) }.status)
    }

    @Test
    fun mdblistReadsEveryMappedSourceOffItsOwnScaleAndDropsTheRest() = runTest {
        val service = scripted(
            json(
                """{"title":"The Shawshank Redemption","year":1994,"score":89,"ratings":[
                {"source":"imdb","value":9.3,"score":93,"votes":3207270,"url":43},
                {"source":"metacritic","value":82,"score":82,"votes":22,"url":"/the-shawshank-redemption"},
                {"source":"metacriticuser","value":9.3,"score":93,"votes":2198,"url":null},
                {"source":"trakt","value":91,"score":91,"votes":43118,"url":null},
                {"source":"tomatoes","value":89,"score":89,"votes":147,"url":"/m/shawshank_redemption","fresh":1},
                {"source":"popcorn","value":98,"score":98,"votes":53439,"url":"/m/shawshank_redemption"},
                {"source":"tmdb","value":87,"score":87,"votes":30786,"url":null},
                {"source":"letterboxd","value":4.6,"score":92,"votes":2908116,"url":"/film/the-shawshank-redemption/"},
                {"source":"rogerebert","value":3.5,"score":null,"votes":null,"url":"the-shawshank-redemption-1994"},
                {"source":"myanimelist","value":null,"score":null,"votes":null,"url":null}]}""",
            ),
        )

        val ratings = mdblist(service).ratings(movie(TitleIds(imdb = "tt0111161", tmdb = 278)))

        assertEquals("/imdb/movie/tt0111161", service.requests.single().path)
        assertScores(
            listOf(
                r("imdb", 9.3, 3207270),
                r("metacritic", 8.2, 22),
                r("trakt", 9.1, 43118),
                r("rottenTomatoesCritic", 8.9, 147),
                r("rottenTomatoesAudience", 9.8, 53439),
                r("tmdb", 8.7, 30786),
                r("letterboxd", 9.2, 2908116),
            ),
            ratings,
        )
    }

    @Test
    fun mdblistLooksUpByTmdbThenAShowsTvdbThenMyAnimeListIdAndAcceptsNumericStrings() = runTest {
        fun body(source: String, value: String, votes: String) = json("""{"ratings":[{"source":"$source","value":$value,"votes":$votes}]}""")
        val service = scripted(body("tmdb", "\"84\"", "\"21000\""), body("tomatoesaudience", "96", "250000"), body("myanimelist", "\"8.62\"", "3700000"))

        val byTmdb = mdblist(service).ratings(show(TitleIds(tmdb = 1396, tvdb = 81189)))
        val byTvdb = mdblist(service).ratings(show(TitleIds(tvdb = 81189, mal = 21)))
        val byMal = mdblist(service).ratings(movie(TitleIds(tvdb = 81189, mal = 21)))

        assertEquals(listOf("/tmdb/show/1396", "/tvdb/show/81189", "/mal/any/21"), service.requests.map { it.path })
        assertScores(listOf(r("tmdb", 8.4, 21000)), byTmdb)
        assertScores(listOf(r("rottenTomatoesAudience", 9.6, 250000)), byTvdb)
        assertScores(listOf(r("mal", 8.62, 3700000)), byMal)
    }

    @Test
    fun mdblistHasNoScoresForATitleItDoesNotKnow() = runTest {
        val service = scripted(json("""{"error":"Not found"}""", 404))

        assertTrue(mdblist(service).ratings(movie(TitleIds(tmdb = 1))).isEmpty())
        assertEquals("/tmdb/movie/1", service.requests.single().path)
    }

    @Test
    fun mdblistNeedsAnIdItCanLookUp() = runTest {
        val service = scripted()

        assertTrue(mdblist(service).ratings(movie(TitleIds(trakt = 1, simkl = 2))).isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun mdblistPropagatesAFailureOtherThan404() = runTest {
        val service = scripted(json("oops", 503))

        assertEquals(503, assertFailsWith<TrackerException.Api> { mdblist(service).ratings(movie(TitleIds(imdb = "tt0111161"))) }.status)
    }
}
