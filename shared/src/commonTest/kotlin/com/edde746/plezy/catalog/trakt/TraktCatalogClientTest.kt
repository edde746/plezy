package com.edde746.plezy.catalog.trakt

import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.trakt.TraktApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

class TraktCatalogClientTest {
    private val recommenders = """
        "favorited_by":[{"username":"alice","name":"Alice","notes":"A forever favorite."}],
        "recommended_by":[{"username":"bob","name":null,"notes":"The lobby scene."}],
    """.trimIndent()

    private fun movieJson(withRecommenders: Boolean = false): String = """
        {"title":"The Matrix","year":1999,"ids":{"trakt":1,"slug":"the-matrix-1999","imdb":"tt0133093","tmdb":603},
         "overview":"A hacker learns the truth.","tagline":"Welcome to the Real World.","original_title":"The Matrix",
         "released":"1999-03-31T00:00:00.000Z","runtime":136,"rating":8.7,"votes":42000,"genres":["action","sci-fi"],
         "certification":"R","trailer":"https://youtube.com/watch?v=m8e-FF8MsqU","comment_count":1234,"language":"en",
         "languages":["en"],"available_translations":["es","fr"],"country":"us",
         ${if (withRecommenders) recommenders else ""}
         "images":{"poster":["walter-r2.trakt.tv/images/movies/p.webp"],"fanart":["walter-r2.trakt.tv/images/movies/f.webp"],
           "logo":["walter-r2.trakt.tv/images/movies/logo.webp"]}}
    """.trimIndent()

    private val showJson = """
        {"title":"Severance","year":2022,"ids":{"trakt":2,"slug":"severance","imdb":"tt11280740","tmdb":95396,"tvdb":371980},
         "overview":"Work-life balance, surgically.","runtime":50,"rating":8.9,"first_aired":"2022-02-18T00:00:00.000Z",
         "airs":{"day":"Friday","time":"09:30","timezone":"America/New_York"},"images":{}}
    """.trimIndent()

    private fun TestScope.client(answer: (Recorded) -> Answer): Pair<TraktCatalogClient, ScriptedService> {
        val service = ScriptedService(this, answer)
        val api = TraktApi(service.http(TrackerService.TRAKT), FakeCredentials(TrackerService.TRAKT), mapOf("trakt-api-version" to "2"))
        return TraktCatalogClient(api) to service
    }

    private fun obj(text: String): JsonObject = parse(text).jsonObject

    @Test
    fun imagesPrefixProtocolLessCdnUrlsWithHttps() {
        val images = TraktImages.fromJson(obj("""{"poster":["walter-r2.trakt.tv/images/movies/p.webp"]}"""))
        assertEquals("https://walter-r2.trakt.tv/images/movies/p.webp", images.primaryPoster)
        assertNull(images.primaryLogo)
    }

    @Test
    fun imagesKeepAbsoluteUrlsAndFallBackFromFanartToThumbForTheBackdrop() {
        val images = TraktImages.fromJson(obj("""{"poster":["https://example.com/p.webp"],"thumb":["walter-r2.trakt.tv/t.webp"]}"""))
        assertEquals("https://example.com/p.webp", images.primaryPoster)
        assertEquals("https://walter-r2.trakt.tv/t.webp", images.primaryBackdrop)
        assertNull(images.primaryLogo)
    }

    @Test
    fun imagesAreNullForMissingOrEmptyArrays() {
        val images = TraktImages.fromJson(obj("""{"poster":[]}"""))
        assertNull(images.primaryPoster)
        assertNull(images.primaryBackdrop)
    }

    @Test
    fun idsLeaveNullsOutOfTheBodyAndCountASlugAsAnId() {
        assertEquals(obj("""{"imdb":"tt0133093","tmdb":603}"""), TraktIds(imdb = "tt0133093", tmdb = 603).toJson())
        assertTrue(TraktIds(slug = "the-matrix-1999").hasAny)
        assertFalse(TraktIds().hasAny)
    }

    @Test
    fun theWatchlistParsesWrappedEntriesAndItsPagination() = runTest {
        val (client, service) = client {
            json(
                """[{"rank":1,"listed_at":"2026-01-01T00:00:00.000Z","type":"movie","movie":${movieJson()}},
                    {"rank":2,"listed_at":"2026-01-02T00:00:00.000Z","type":"show","show":$showJson}]""",
                headers = mapOf("x-pagination-page" to "1", "x-pagination-page-count" to "3", "x-pagination-item-count" to "250"),
            )
        }

        val page = client.getWatchlist()

        val request = service.requests.single()
        assertEquals("/sync/watchlist", request.path)
        assertEquals("full,images", request.url.parameters["extended"])
        assertEquals("Bearer access-1", request.headers["Authorization"])
        assertEquals(2, page.items.size)
        assertFalse(page.items[0].isShow)
        assertEquals("The Matrix", page.items[0].media?.title)
        assertEquals("tt0133093", page.items[0].media?.ids?.imdb)
        assertEquals("https://walter-r2.trakt.tv/images/movies/p.webp", page.items[0].media?.images?.primaryPoster)
        assertTrue(page.items[1].isShow)
        assertEquals(371980, page.items[1].media?.ids?.tvdb)
        assertNull(page.items[1].media?.images?.primaryPoster)
        assertEquals(TraktPage(page.items, page = 1, pageCount = 3, itemCount = 250), page)
        assertTrue(page.hasMore)
    }

    @Test
    fun aListWithoutPaginationHeadersIsASinglePage() = runTest {
        val (client, _) = client { json("[]") }

        val page = client.getWatchlist()

        assertTrue(page.items.isEmpty())
        assertEquals(1, page.page)
        assertEquals(1, page.pageCount)
        assertFalse(page.hasMore)
        assertNull(page.itemCount)
    }

    @Test
    fun trendingParsesWatcherWrappedEntries() = runTest {
        val (client, service) = client { json("""[{"watchers":120,"movie":${movieJson()}}]""") }

        val page = client.getTrending(TraktCatalogType.MOVIES, page = 2, limit = 10)

        val request = service.requests.single()
        assertEquals("/movies/trending", request.path)
        assertEquals("2", request.url.parameters["page"])
        assertEquals("10", request.url.parameters["limit"])
        assertEquals(120, page.items.single().watchers)
        assertEquals("The Matrix", page.items.single().media?.title)
        assertNull(page.itemCount)
    }

    @Test
    fun popularParsesBareMediaObjects() = runTest {
        val (client, service) = client { json("[$showJson]") }

        val show = client.getPopular(TraktCatalogType.SHOWS).items.single()

        assertEquals("/shows/popular", service.requests.single().path)
        assertEquals("Severance", show.title)
        assertEquals("2022-02-18T00:00:00.000Z", show.firstAired)
        assertEquals(TraktAirs("Friday", "09:30", "America/New_York"), show.airs)
        assertNull(show.commentCount)
    }

    @Test
    fun recommendationsPassTheIgnoreFlagsAndKeepProvenance() = runTest {
        val (client, service) = client { json("[${movieJson(withRecommenders = true)}]") }

        val item = client.getRecommended(TraktCatalogType.MOVIES, limit = 15).single()

        val request = service.requests.single()
        assertEquals("/recommendations/movies", request.path)
        assertEquals("15", request.url.parameters["limit"])
        assertEquals("false", request.url.parameters["ignore_collected"])
        assertEquals("true", request.url.parameters["ignore_watchlisted"])
        assertEquals("The Matrix", item.title)
        assertEquals(listOf(TraktRecommendationUser("alice", "Alice", "A forever favorite.")), item.favoritedBy)
        assertEquals(listOf(TraktRecommendationUser("bob", null, "The lobby scene.")), item.recommendedBy)
    }

    @Test
    fun showPeopleWidenForGuestStarsAndParseCastAndCrew() = runTest {
        val (client, service) = client {
            json(
                """{"cast":[{"characters":["Mark Scout","Mark S."],"episode_count":19,"person":{"name":"Adam Scott"}}],
                    "guest_stars":[{"characters":["June"],"episode_count":1,"person":{"name":"Guest Actor"}}],
                    "crew":{"directing":[{"jobs":["Director"],"person":{"name":"Ben Stiller"}}],
                            "production":[{"job":"Executive Producer","person":{"name":"Jackie Cohn"}}]}}""",
            )
        }

        val people = client.getPeople(TraktCatalogType.SHOWS, "severance")

        val request = service.requests.single()
        assertEquals("/shows/severance/people", request.path)
        assertEquals("full,images,guest_stars", request.url.parameters["extended"])
        assertEquals(listOf("Mark Scout", "Mark S."), people.cast.single().characters)
        assertEquals(19, people.cast.single().episodeCount)
        assertEquals("Guest Actor", people.guestStars.single().person?.name)
        assertEquals(2, people.crew.size)
        assertEquals(listOf("Director"), people.crew.first().jobs)
        assertEquals("Executive Producer", people.crew.last().job)
    }

    @Test
    fun addToWatchlistAccepts201AndPostsTheIdsBodyUntouched() = runTest {
        val (client, service) = client { json("""{"added":{"movies":1}}""", 201) }
        val body = obj("""{"movies":[{"ids":{"imdb":"tt0133093"}}]}""")

        client.addToWatchlist(body)

        assertEquals("/sync/watchlist", service.requests.single().path)
        assertEquals(body, parse(service.requests.single().body))
    }

    @Test
    fun removeFromWatchlistPostsToTheRemoveEndpoint() = runTest {
        val (client, service) = client { json("""{"deleted":{"shows":1}}""") }

        client.removeFromWatchlist(obj("""{"shows":[]}"""))

        assertEquals("/sync/watchlist/remove", service.requests.single().path)
    }

    @Test
    fun malformedEntriesAreSkippedInsteadOfThrowing() = runTest {
        val (client, _) = client { json("""["not-a-map",42]""") }

        assertTrue(client.getTrending(TraktCatalogType.SHOWS).items.isEmpty())
    }

    @Test
    fun anEntryWithoutAMovieOrShowHasNoMedia() {
        assertNull(TraktCatalogEntry.fromJson(obj("""{"rank":1,"type":"movie"}""")).media)
    }

    @Test
    fun anEntryPrefersItsMovieAndIsAShowWheneverItCarriesOne() {
        val show = TraktCatalogEntry.fromJson(obj("""{"show":{"title":"Severance","ids":{"trakt":2}}}"""))
        assertEquals("Severance", show.media?.title)
        assertTrue(show.isShow)
        val movie = TraktCatalogEntry.fromJson(obj("""{"movie":{"title":"The Matrix","ids":{"trakt":1}}}"""))
        assertFalse(movie.isShow)
        val both = TraktCatalogEntry.fromJson(obj("""{"movie":{"title":"The Matrix","ids":{"trakt":1}},"show":{"title":"Severance","ids":{"trakt":2}}}"""))
        assertEquals("The Matrix", both.media?.title)
        assertTrue(both.isShow)
    }

    @Test
    fun catalogIdsTakeTheImdbTmdbAndTvdbIdsOfAnItem() {
        assertEquals(
            CatalogItemIds(imdb = "tt0133093", tmdb = 603, tvdb = 81189),
            CatalogItemIds.fromExternal(ExternalIds(imdb = "tt0133093", tmdb = 603, tvdb = 81189, anidb = 69)),
        )
    }
}
