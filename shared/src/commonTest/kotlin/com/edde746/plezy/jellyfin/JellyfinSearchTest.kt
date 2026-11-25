package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.jellyfin.ItemRows.items
import com.edde746.plezy.jellyfin.ItemRows.row
import com.edde746.plezy.jellyfin.ItemRows.testServer
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaLibrary
import io.ktor.http.Url
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

class JellyfinSearchTest {
    private fun view(id: String, name: String, collectionType: String?) =
        """{"Id":"$id","Name":"$name","Type":"CollectionFolder"${collectionType?.let { ""","CollectionType":"$it"""" } ?: ""}}"""

    private val defaultViews = listOf(view("lib-movies", "Movies", "movies"), view("lib-shows", "Shows", "tvshows"), view("lib-music", "Music", "music"))

    /** Views mapped the way the library list maps them; [fetches] counts the loads. */
    private class Views(private val core: JellyfinCore, private val views: List<String>) {
        var fetches = 0

        suspend fun load(): List<MediaLibrary> {
            fetches++
            return views.mapNotNull { JellyfinMappers.library(Json.parseToJsonElement(it).jsonObject, core.serverId, core.connection.serverName, core.dialect) }
        }
    }

    private fun search(core: JellyfinCore, views: Views) =
        JellyfinSearch(core, views::load, fetchItem = { error("unused") }, fetchChildren = { error("unused") }, stampLibrary = { it })

    /**
     * A server that answers `/Items` from [itemsByParent] filtered by the requested types, and `/Artists` from
     * `artists:{parent}`. An unscoped search fails the test: it could neither attribute hits nor honour a hidden
     * library.
     */
    private fun itemsServer(itemsByParent: Map<String, List<Pair<String, String>>>): suspend (RecordedRequest) -> FakeResponse = { request ->
        when (request.path) {
            "/Items" -> {
                val parent = request.query["ParentId"] ?: error("Unscoped /Items search: ${request.url}")
                val types = request.query["IncludeItemTypes"]?.split(',')?.toSet()
                items(*itemsByParent[parent].orEmpty().filter { types == null || it.second in types }.map { row(it.first, it.second) }.toTypedArray())
            }
            "/Artists" -> {
                val parent = request.query["parentId"] ?: error("Unscoped /Artists search: ${request.url}")
                items(*itemsByParent["artists:$parent"].orEmpty().map { row(it.first, it.second) }.toTypedArray())
            }
            else -> error("Unexpected request: ${request.url}")
        }
    }

    private fun itemParents(server: JellyfinTestServer) = server.requests.filter { it.path == "/Items" }.map { it.query["ParentId"] }

    private val threeLibraries = mapOf(
        "lib-movies" to listOf("movie-1" to "Movie"),
        "lib-shows" to listOf("show-1" to "Series"),
        "lib-music" to listOf("album-1" to "MusicAlbum"),
    )

    @Test
    fun everySearchFansOutOneScopedQueryPerVisibleLibrary() = runTest {
        val server = testServer(itemsServer(threeLibraries))
        val core = server.core()
        val views = Views(core, defaultViews)

        val results = search(core, views).searchItems("the")

        assertEquals(listOf("movie-1", "show-1", "album-1"), results.map { it.id })
        assertEquals(1, views.fetches, "a cold search loads the views once")
        assertEquals(listOf("lib-movies", "lib-shows", "lib-music", "lib-music"), itemParents(server))
        val movies = server.requests.first { it.query["ParentId"] == "lib-movies" }.query
        assertEquals("user-1", movies["userId"])
        assertEquals("the", movies["SearchTerm"])
        assertEquals("true", movies["Recursive"])
        assertEquals("100", movies["Limit"])
        assertEquals("Primary,Backdrop,Logo", movies["EnableImageTypes"])
    }

    @Test
    fun aHiddenLibraryIsExcludedByScopingOneRequestPerVisibleLibrary() = runTest {
        val server = testServer(itemsServer(threeLibraries))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the", excludedLibraryIds = setOf("lib-shows"))

        assertEquals(listOf("movie-1", "album-1"), results.map { it.id })
        assertTrue(server.requests.none { it.query["ParentId"] == "lib-shows" || it.query["parentId"] == "lib-shows" })
        assertEquals(listOf("lib-movies", "lib-music", "lib-music"), itemParents(server))
    }

    @Test
    fun everyHitCarriesTheLibraryItCameFrom() = runTest {
        val server = testServer(itemsServer(mapOf("lib-movies" to listOf("movie-1" to "Movie"), "lib-music" to listOf("album-1" to "MusicAlbum"))))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the")

        assertEquals(listOf("lib-movies", "lib-music"), results.map { it.libraryId })
        assertEquals(listOf("Movies", "Music"), results.map { it.libraryTitle })
    }

    @Test
    fun onlyAMusicLibraryScopesTheArtistsLeg() = runTest {
        val server = testServer(itemsServer(mapOf("artists:lib-music" to listOf("artist-1" to "MusicArtist"))))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the")

        assertEquals(listOf("artist-1"), results.map { it.id })
        val artists = server.requests.filter { it.path == "/Artists" }
        assertEquals(listOf("lib-music"), artists.map { it.query["parentId"] })
        assertEquals("the", artists.single().query["searchTerm"])
        assertEquals("user-1", artists.single().query["userId"])
    }

    @Test
    fun aFailingArtistsLegDoesNotSinkTheOtherLegs() = runTest {
        val music = itemsServer(mapOf("lib-music" to listOf("album-1" to "MusicAlbum")))
        val server = testServer { request -> if (request.path == "/Artists") FakeResponse(500, "boom") else music(request) }
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the")

        assertEquals(listOf("album-1"), results.map { it.id })
    }

    @Test
    fun aFailingItemsLegFailsTheSearch() = runTest {
        val server = testServer { request -> if (request.path == "/Items") FakeResponse(500, "boom") else items() }
        val core = server.core()

        assertFailsWith<MediaServerHttpException> { search(core, Views(core, defaultViews)).searchItems("the") }
    }

    @Test
    fun anArtistSpanningTwoMusicLibrariesIsReturnedOnce() = runTest {
        val server = testServer(
            itemsServer(
                mapOf(
                    "artists:lib-music" to listOf("artist-1" to "MusicArtist"),
                    "artists:lib-scores" to listOf("artist-1" to "MusicArtist"),
                    "lib-scores" to listOf("album-1" to "MusicAlbum"),
                ),
            ),
        )
        val core = server.core()
        val views = Views(core, listOf(view("lib-shows", "Shows", "tvshows"), view("lib-music", "Music", "music"), view("lib-scores", "Soundtracks", "music")))

        val results = search(core, views).searchItems("the", excludedLibraryIds = setOf("lib-shows"))

        assertEquals(listOf("artist-1", "album-1"), results.map { it.id })
        assertEquals("lib-music", results.first().libraryId, "first leg wins")
        assertEquals(listOf("lib-music", "lib-scores"), server.requests.filter { it.path == "/Artists" }.map { it.query["parentId"] })
    }

    @Test
    fun oneLibraryHoldingEveryMatchStillFillsTheWholeBudget() = runTest {
        val server = testServer(itemsServer(mapOf("lib-movies" to (0 until 100).map { "movie-$it" to "Movie" })))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the", limit = 100, excludedLibraryIds = setOf("lib-shows"))

        assertEquals(100, results.size)
        assertEquals(listOf("100", "100", "100"), server.requests.filter { it.path == "/Items" }.map { it.query["Limit"] })
    }

    @Test
    fun searchNeverPaysForATotalItDoesNotRead() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val core = server.core()

        search(core, Views(core, defaultViews)).searchItems("the")

        assertTrue(server.requests.all { it.query["EnableTotalRecordCount"] == "false" })
    }

    @Test
    fun musicAlbumAndAudioLegsUseSafeFieldSetsWithoutLosingEitherKind() = runTest {
        val server = testServer(itemsServer(mapOf("lib-music" to listOf("album-1" to "MusicAlbum", "track-1" to "Audio"))))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the", excludedLibraryIds = setOf("lib-shows"))

        assertEquals(listOf("album-1", "track-1"), results.map { it.id })
        val music = server.requests.filter { it.path == "/Items" && it.query["ParentId"] == "lib-music" }.map { it.query }
        val album = music.single { it["IncludeItemTypes"] == "MusicAlbum" }
        val audio = music.single { it["IncludeItemTypes"] == "Audio" }
        assertEquals("false", album["EnableUserData"])
        assertEquals("PremiereDate,OriginalTitle,SortName,DateCreated", album["Fields"])
        assertEquals("UserData,PremiereDate,OriginalTitle,SortName", audio["Fields"])
        val movies = server.requests.single { it.path == "/Items" && it.query["ParentId"] == "lib-movies" }.query
        assertEquals("RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete", movies["Fields"])
    }

    @Test
    fun eachLibraryIsSearchedOnlyForTheTypesItsKindCanHold() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val core = server.core()
        val views = Views(
            core,
            listOf(
                view("lib-movies", "Movies", "movies"),
                view("lib-shows", "Shows", "tvshows"),
                view("lib-home", "Home Videos", "homevideos"),
                view("lib-mvids", "Music Videos", "musicvideos"),
                view("lib-mixed", "Mixed", null),
            ),
        )

        search(core, views).searchItems("the")

        val typesByLibrary = server.requests.filter { it.path == "/Items" }.associate { it.query["ParentId"] to it.query["IncludeItemTypes"] }
        assertEquals<Map<String?, String?>>(
            mapOf(
                "lib-movies" to "Movie",
                "lib-shows" to "Series,Episode",
                "lib-home" to "Video,MusicVideo",
                "lib-mvids" to "Video,MusicVideo",
                "lib-mixed" to "Movie,Series,Episode,MusicAlbum,Audio",
            ),
            typesByLibrary,
        )
    }

    @Test
    fun embySearchesAMovieLibraryByMediaTypeAndKeepsOnlyItsMovies() = runTest {
        val server = testServer(
            itemsServer(
                mapOf(
                    "lib-movies" to listOf("movie-1" to "Movie", "trailer-1" to "Trailer"),
                    "lib-shows" to listOf("show-1" to "Series"),
                ),
            ),
        )
        val core = server.core(MediaBrowserDialect.EMBY)

        val results = search(core, Views(core, defaultViews)).searchItems("the")

        assertEquals(listOf("movie-1", "show-1"), results.map { it.id })
        val movies = server.requests.single { it.path == "/Items" && it.query["ParentId"] == "lib-movies" }.query
        assertEquals("Video", movies["MediaTypes"])
        assertFalse("IncludeItemTypes" in movies)
        assertEquals("Series,Episode", server.requests.single { it.query["ParentId"] == "lib-shows" }.query["IncludeItemTypes"])
    }

    @Test
    fun jellyfinKeepsTheTypedMovieLibrarySearch() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val core = server.core()

        search(core, Views(core, defaultViews)).searchItems("the")

        val movies = server.requests.single { it.path == "/Items" && it.query["ParentId"] == "lib-movies" }.query
        assertEquals("Movie", movies["IncludeItemTypes"])
        assertFalse("MediaTypes" in movies)
    }

    @Test
    fun homeAndMusicVideoLibrariesSurfaceTheirVideos() = runTest {
        val server = testServer(itemsServer(mapOf("lib-home" to listOf("video-1" to "Video"), "lib-mvids" to listOf("mv-1" to "MusicVideo"))))
        val core = server.core()

        val results = search(core, Views(core, listOf(view("lib-home", "Home Videos", "homevideos"), view("lib-mvids", "Music Videos", "musicvideos"))))
            .searchItems("the")

        assertEquals(listOf("video-1", "mv-1"), results.map { it.id })
        assertEquals(listOf("lib-home", "lib-mvids"), results.map { it.libraryId })
    }

    @Test
    fun aPhotoLibraryIsNotSearched() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val core = server.core()

        search(core, Views(core, listOf(view("lib-movies", "Movies", "movies"), view("lib-photos", "Photos", "photos")))).searchItems("the")

        assertEquals(listOf("lib-movies"), itemParents(server))
    }

    @Test
    fun excludedIdsOwnedByAnotherServerDoNotShrinkTheFanOut() = runTest {
        val server = testServer(itemsServer(mapOf("lib-movies" to listOf("movie-1" to "Movie"))))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the", excludedLibraryIds = setOf("some-other-servers-library"))

        assertEquals(listOf("movie-1"), results.map { it.id })
        assertEquals(listOf("lib-movies", "lib-shows", "lib-music", "lib-music"), itemParents(server))
    }

    @Test
    fun hidingEveryLibraryReturnsNothingInsteadOfEverything() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val core = server.core()

        val results = search(core, Views(core, defaultViews)).searchItems("the", excludedLibraryIds = setOf("lib-movies", "lib-shows", "lib-music"))

        assertEquals(emptyList(), results)
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun aFailedViewFetchFailsTheSearchInsteadOfFallingBackToAnUnscopedOne() = runTest {
        val server = testServer(itemsServer(emptyMap()))
        val failing = JellyfinSearch(
            server.core(),
            fetchLibraries = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP 500", statusCode = 500) },
            fetchItem = { null },
            fetchChildren = { emptyList() },
            stampLibrary = { it },
        )

        assertFailsWith<MediaServerHttpException> { failing.searchItems("the", excludedLibraryIds = setOf("lib-shows")) }
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun librariesAreSearchedThreeAtATime() = runTest {
        var inFlight = 0
        var peak = 0
        val server = testServer {
            inFlight++
            peak = maxOf(peak, inFlight)
            kotlinx.coroutines.delay(10)
            inFlight--
            items()
        }
        val core = server.core()
        val views = Views(core, (1..5).map { view("lib-$it", "Movies $it", "movies") })

        search(core, views).searchItems("the")

        assertEquals(5, server.requests.size)
        assertEquals(3, peak)
    }

    // People search.

    private val peopleViews = defaultViews + view("lib-anime", "Anime", "tvshows")

    private fun personRow(id: String, name: String, primaryTag: String? = null) =
        """{"Id":"$id","Name":"$name","Type":"Person"${primaryTag?.let { ""","ImageTags":{"Primary":"$it"}""" } ?: ""}}"""

    /**
     * Serves the candidate search in the given (name) order and answers each `/Items?PersonIds=` check from
     * [titlesByPerson]: person id → (library id → title type).
     */
    private fun peopleServer(persons: List<String>, titlesByPerson: Map<String, Map<String, String>>): suspend (RecordedRequest) -> FakeResponse = { request ->
        val query = request.query
        when {
            request.path == "/Persons" || (request.path == "/Items" && query["IncludeItemTypes"] == "Person") ->
                items(*persons.take(query["Limit"]?.toInt() ?: persons.size).toTypedArray())
            request.path == "/Items" -> {
                val personId = query["PersonIds"] ?: error("Unexpected /Items request: ${request.url}")
                val parent = query["ParentId"]
                val types = query["IncludeItemTypes"]?.split(',')?.toSet()
                val matches = titlesByPerson[personId].orEmpty()
                    .filter { (library, type) -> (parent == null || parent == library) && (types == null || type in types) }
                    .map { (library, type) -> row("$personId-$library", type) }
                items(*matches.take(query["Limit"]?.toInt() ?: matches.size).toTypedArray())
            }
            else -> error("Unexpected request: ${request.url}")
        }
    }

    private fun titleChecks(server: JellyfinTestServer) = server.requests.filter { it.path == "/Items" && "PersonIds" in it.query }

    private fun candidateSearches(server: JellyfinTestServer) =
        server.requests.filter { it.path == "/Persons" || (it.path == "/Items" && it.query["IncludeItemTypes"] == "Person") }

    @Test
    fun ranksTheNameOrderedCandidatesBeforeCuttingThemToTheLimit() = runTest {
        val server = testServer(
            peopleServer(
                listOf(personRow("p-andrew", "Andrew Jackson"), personRow("p-emily", "Emily Jackson"), personRow("p-samuel", "Samuel L. Jackson")),
                mapOf("p-andrew" to mapOf("lib-movies" to "Movie"), "p-emily" to mapOf("lib-movies" to "Movie"), "p-samuel" to mapOf("lib-movies" to "Movie")),
            ),
        )
        val core = server.core()

        val results = search(core, Views(core, peopleViews)).searchPeople("Samuel L. Jackson", limit = 2)

        assertEquals(2, results.size)
        assertEquals("p-samuel", results.first().id)
        assertEquals(2, titleChecks(server).size, "only the ranked top limit is worth a check")
    }

    @Test
    fun candidatesWithoutAFilmographyTitleAreDroppedInRankedOrderOnBothDialects() = runTest {
        for (dialect in listOf(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.EMBY)) {
            val server = testServer(
                peopleServer(
                    listOf(
                        personRow("p-christopher", "Christopher Nolan"),
                        personRow("p-jonathan", "Jonathan Nolan"),
                        personRow("p-gould", "Nolan Gould"),
                        personRow("p-north", "Nolan North"),
                    ),
                    mapOf(
                        "p-christopher" to mapOf("lib-movies" to "Movie"),
                        // Credited on an episode only: the filmography lists movies and series.
                        "p-jonathan" to mapOf("lib-shows" to "Episode"),
                        "p-north" to mapOf("lib-shows" to "Series"),
                    ),
                ),
            )
            val core = server.core(dialect)
            val views = Views(core, peopleViews)

            val results = search(core, views).searchPeople("Nolan")

            assertEquals(listOf("p-north", "p-christopher"), results.map { it.id }, "$dialect")
            val checks = titleChecks(server)
            assertEquals(4, checks.size)
            assertEquals(0, views.fetches, "nothing is hidden, so no view fetch")
            assertTrue(checks.all { "ParentId" !in it.query })
            val check = checks.first().query
            assertEquals("Movie,Series", check["IncludeItemTypes"])
            assertEquals("true", check["Recursive"])
            assertEquals("1", check["Limit"])
            assertEquals("false", check["CollapseBoxSetItems"])
            assertEquals("false", check["EnableTotalRecordCount"])
            assertEquals("false", check["EnableImages"])
            assertEquals("false", check["EnableUserData"])
        }
    }

    @Test
    fun embySearchesPeopleThroughItemsJellyfinThroughPersons() = runTest {
        for ((dialect, expectedPath) in listOf(MediaBrowserDialect.JELLYFIN to "/Persons", MediaBrowserDialect.EMBY to "/Items")) {
            val server = testServer(peopleServer(listOf(personRow("p-christopher", "Christopher Nolan")), mapOf("p-christopher" to mapOf("lib-movies" to "Movie"))))
            val core = server.core(dialect)

            val results = search(core, Views(core, peopleViews)).searchPeople("Nolan")

            assertEquals(listOf("p-christopher"), results.map { it.id })
            val candidates = candidateSearches(server).single()
            assertEquals(expectedPath, candidates.path)
            val query = candidates.query
            assertEquals("Nolan", query["SearchTerm"])
            assertEquals("user-1", query["userId"])
            assertEquals("Actor,Director", query["PersonTypes"])
            assertEquals("100", query["Limit"])
            assertEquals("Primary", query["EnableImageTypes"])
            assertEquals("1", query["ImageTypeLimit"])
            assertEquals("false", query["EnableUserData"])
            assertEquals("false", query["EnableTotalRecordCount"])
            if (dialect == MediaBrowserDialect.EMBY) {
                assertEquals("true", query["Recursive"])
                assertTrue(server.requests.none { it.path == "/Persons" })
            } else {
                assertFalse("IncludeItemTypes" in query)
            }
        }
    }

    @Test
    fun aPersonWhoseOnlyTitlesSitInAHiddenLibraryIsLeftOut() = runTest {
        val server = testServer(
            peopleServer(
                listOf(personRow("p-bryan", "Bryan Cranston"), personRow("p-waltz", "Christoph Waltz"), personRow("p-kana", "Kana Hanazawa")),
                mapOf(
                    "p-bryan" to mapOf("lib-shows" to "Series"),
                    // A title in any visible library keeps a person also in the hidden one.
                    "p-waltz" to mapOf("lib-movies" to "Movie", "lib-anime" to "Series"),
                    "p-kana" to mapOf("lib-anime" to "Series"),
                ),
            ),
        )
        val core = server.core()

        val results = search(core, Views(core, peopleViews)).searchPeople("a", excludedLibraryIds = setOf("lib-anime"))

        assertEquals(setOf("p-bryan", "p-waltz"), results.map { it.id }.toSet())
        assertTrue(titleChecks(server).all { it.query["ParentId"] in setOf("lib-movies", "lib-shows") }, "music never holds a title")
    }

    @Test
    fun hidingEveryLibraryThatCanHoldATitleReturnsNobodyWithoutSearching() = runTest {
        val server = testServer(peopleServer(listOf(personRow("p-waltz", "Christoph Waltz")), mapOf("p-waltz" to mapOf("lib-movies" to "Movie"))))
        val core = server.core()

        val results = search(core, Views(core, peopleViews)).searchPeople("Waltz", excludedLibraryIds = setOf("lib-movies", "lib-shows", "lib-anime"))

        assertEquals(emptyList(), results)
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun aThumbExistsOnlyForAPersonWithAPrimaryImageTag() = runTest {
        val server = testServer(
            peopleServer(
                listOf(personRow("p-tagged", "Tagged Actor", primaryTag = "tag-1"), personRow("p-untagged", "Untagged Actor")),
                mapOf("p-tagged" to mapOf("lib-movies" to "Movie"), "p-untagged" to mapOf("lib-movies" to "Movie")),
            ),
        )
        val core = server.core()

        val byId = search(core, Views(core, peopleViews)).searchPeople("Actor").associateBy { it.id }

        val thumb = Url(byId.getValue("p-tagged").thumbPath!!)
        assertEquals("jf.local", thumb.host)
        assertEquals(8096, thumb.port)
        assertEquals("/Items/p-tagged/Images/Primary", thumb.encodedPath)
        assertEquals("tag-1", thumb.parameters["tag"])
        assertNull(byId.getValue("p-untagged").thumbPath, "a tagless image URL 404s")
    }

    @Test
    fun cancellingDuringTheTitleChecksStartsNoFurtherBatch() = runTest {
        val checks = mutableListOf<String>()
        val server = testServer { request ->
            if (request.path == "/Persons") {
                items(*(0 until 4).map { personRow("p-$it", "Actor $it") }.toTypedArray())
            } else {
                checks += request.query.getValue("PersonIds")
                awaitCancellation()
            }
        }
        val core = server.core()

        val people = async { search(core, Views(core, peopleViews)).searchPeople("Actor") }
        runCurrent()
        assertEquals(3, checks.size)
        people.cancel()
        runCurrent()

        assertTrue(people.isCancelled)
        assertEquals(3, checks.size, "the fourth candidate's batch never starts")
    }
}
