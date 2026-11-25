package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.jellyfin.ItemRows.items
import com.edde746.plezy.jellyfin.ItemRows.testServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

class JellyfinExternalIdLookupTest {
    private fun series(id: String = "series-1", tmdb: Int = 42) =
        """{"Id":"$id","Type":"Series","Name":"Parent Series","ProviderIds":{"Tmdb":"$tmdb"}}"""

    private fun movie(id: String, tmdb: Int) = """{"Id":"$id","Type":"Movie","Name":"The Matrix","ProviderIds":{"Tmdb":"$tmdb"}}"""

    /** Stamps from [libraries] (item id → id and title), as the ancestors lookup would. */
    private fun lookup(
        core: JellyfinCore,
        libraries: Map<String, Pair<String, String>> = emptyMap(),
        children: suspend (String) -> List<MediaItem> = { error("Season hierarchy must not be requested: $it") },
        fetchItem: suspend (String) -> MediaItem? = { error("unused") },
        stampLibrary: suspend (MediaItem) -> MediaItem = { item ->
            libraries[item.id]?.let { (id, title) -> item.copy(libraryId = id, libraryTitle = title) } ?: item
        },
    ) = JellyfinSearch(core, fetchLibraries = { error("unused") }, fetchItem = fetchItem, fetchChildren = children, stampLibrary = stampLibrary)

    @Test
    fun searchesEveryTitleAndUnionsTheIdVerifiedCopiesEachOneReaches() = runTest {
        // A copy filed under another language's title is only reachable through that title.
        val server = testServer { request ->
            when (request.query["SearchTerm"]) {
                "Parent Series" -> items(series())
                "Oya Series" -> items(series(), series(id = "series-romaji"))
                else -> items()
            }
        }

        val matches = lookup(server.core(), mapOf("series-1" to ("library-1" to "Shows")))
            .findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series Season 2", "Parent Series", "Oya Series"))!!

        assertEquals(setOf("Parent Series Season 2", "Parent Series", "Oya Series"), server.requests.map { it.query["SearchTerm"] }.toSet())
        assertEquals(3, server.requests.size)
        assertEquals(listOf("series-1", "series-romaji"), matches.map { it.id }, "the shared copy appears once")
        assertEquals("library-1", matches.first().libraryId)
        assertEquals("Shows", matches.first().libraryTitle)
        val query = server.requests.first().query
        assertEquals("/Items", server.requests.first().path)
        assertEquals("user-1", query["userId"])
        assertEquals("true", query["Recursive"])
        assertEquals("50", query["Limit"])
        assertEquals("Series", query["IncludeItemTypes"])
        assertEquals("ProviderIds,RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete", query["Fields"])
        assertFalse("anyProviderIdEquals" in query)
    }

    @Test
    fun rejectsATitleHitWhoseProviderIdsDoNotIntersect() = runTest {
        val server = testServer { items(series(tmdb = 99)) }

        val matches = lookup(server.core()).findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series"))

        assertEquals(emptyList(), matches)
    }

    @Test
    fun appliesTheYearWindowToTheFirstTitleOnly() = runTest {
        val server = testServer { request -> if (request.query["SearchTerm"] == "Parent Series") items(series()) else items() }

        val matches = lookup(server.core())
            .findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series Season 2", "Parent Series"), year = 2024)!!

        assertEquals(listOf("series-1"), matches.map { it.id })
        val bySearch = server.requests.associate { it.query["SearchTerm"] to it.query }
        assertEquals("2023,2024,2025", bySearch.getValue("Parent Series Season 2")["years"])
        assertFalse("years" in bySearch.getValue("Parent Series"))
    }

    @Test
    fun aSequelSeasonSkipsTheYearWindow() = runTest {
        val server = testServer { items(series()) }

        lookup(server.core(), children = { emptyList() })
            .findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series"), year = 2024, season = ExternalSeasonRef(tvdb = 2, tmdb = 1))

        assertFalse("years" in server.requests.single().query)
    }

    @Test
    fun requiresAnAgreedSequelSeasonToExistInTheMatchedSeries() = runTest {
        suspend fun lookupWithSeasons(seasons: List<Int>): List<String> {
            val server = testServer { items(series()) }
            val core = server.core()
            val children: suspend (String) -> List<MediaItem> = { id ->
                assertEquals("series-1", id)
                seasons.map { MediaItem(id = "season-$it", backend = BackendKind.JELLYFIN, kind = MediaKind.SEASON, index = it) }
            }
            return lookup(core, children = children)
                .findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series"), year = 2024, season = ExternalSeasonRef(tvdb = 2, tmdb = 2))!!
                .map { it.id }
        }

        assertEquals(emptyList(), lookupWithSeasons(listOf(1)))
        assertEquals(listOf("series-1"), lookupWithSeasons(listOf(1, 2)))
    }

    @Test
    fun doesNotGateWhenTvdbAndTmdbSeasonsDisagree() = runTest {
        val server = testServer { items(series()) }

        val matches = lookup(server.core())
            .findByExternalIds(ExternalIds(tmdb = 42), MediaKind.SHOW, titles = listOf("Parent Series"), season = ExternalSeasonRef(tvdb = 2, tmdb = 1))!!

        assertEquals(listOf("series-1"), matches.map { it.id })
    }

    @Test
    fun returnsEveryLibraryCopyOfATitleEachStampedWithItsOwnLibrary() = runTest {
        val server = testServer { items(movie("movie-4k", 603), movie("movie-hd", 603)) }

        val matches = lookup(server.core(), mapOf("movie-4k" to ("library-4k" to "Movies 4K"), "movie-hd" to ("library-hd" to "Movies")))
            .findByExternalIds(ExternalIds(tmdb = 603), MediaKind.MOVIE, titles = listOf("The Matrix"))!!

        assertEquals(
            listOf(Triple("movie-4k", "library-4k", "Movies 4K"), Triple("movie-hd", "library-hd", "Movies")),
            matches.map { Triple(it.id, it.libraryId, it.libraryTitle) },
        )
        assertEquals("Movie", server.requests.single().query["IncludeItemTypes"])
    }

    @Test
    fun aFailedLibraryStampLeavesTheMatchUnstamped() = runTest {
        val server = testServer { items(movie("movie-1", 603)) }

        val matches = lookup(server.core(), stampLibrary = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP 500", statusCode = 500) })
            .findByExternalIds(ExternalIds(tmdb = 603), MediaKind.MOVIE, titles = listOf("The Matrix"))!!

        assertEquals("movie-1", matches.single().id)
        assertNull(matches.single().libraryId)
    }

    @Test
    fun cannotRunWithoutIdsTitlesOrAMovieOrShowKind() = runTest {
        val server = testServer()
        val lookup = lookup(server.core())

        assertNull(lookup.findByExternalIds(ExternalIds(), MediaKind.MOVIE, titles = listOf("The Matrix")))
        assertNull(lookup.findByExternalIds(ExternalIds(tmdb = 603), MediaKind.MOVIE, titles = emptyList()))
        assertNull(lookup.findByExternalIds(ExternalIds(tmdb = 603), MediaKind.EPISODE, titles = listOf("The Matrix")))
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun aFailedTitleSearchFailsTheLookup() = runTest {
        val server = testServer { FakeResponse(500, "boom") }

        assertFailsWith<MediaServerHttpException> {
            lookup(server.core()).findByExternalIds(ExternalIds(tmdb = 603), MediaKind.MOVIE, titles = listOf("The Matrix"))
        }
    }

    // fetchExternalIds.

    private fun detail(core: JellyfinCore, json: String) = core.mapItem(Json.parseToJsonElement(json).jsonObject)

    @Test
    fun externalIdsComeFromTheDetailProviderIds() = runTest {
        val core = testServer().core()
        val item = detail(core, """{"Id":"item-1","Type":"Movie","Name":"M","ProviderIds":{"Tmdb":"603","Imdb":"tt0133093","Tvdb":"169"}}""")
        val requested = mutableListOf<String>()

        val ids = lookup(core, fetchItem = { requested += it; item }).fetchExternalIds("item-1")

        assertEquals(ExternalIds(imdb = "tt0133093", tmdb = 603, tvdb = 169), ids)
        assertEquals(listOf("item-1"), requested)
    }

    @Test
    fun anItemWithoutProviderIdsOrAMissingItemHasNoExternalIds() = runTest {
        val core = testServer().core()
        val bare = detail(core, """{"Id":"item-1","Type":"Movie","Name":"M"}""")

        assertFalse(lookup(core, fetchItem = { bare }).fetchExternalIds("item-1").hasAny)
        assertFalse(lookup(core, fetchItem = { null }).fetchExternalIds("item-1").hasAny)
    }

    @Test
    fun aFailedDetailFetchFailsTheExternalIds() = runTest {
        val core = testServer().core()
        val failing = lookup(core, fetchItem = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP 500", statusCode = 500) })

        val error = assertFailsWith<MediaServerHttpException> { failing.fetchExternalIds("item-1") }

        assertTrue(error.statusCode == 500)
    }
}
