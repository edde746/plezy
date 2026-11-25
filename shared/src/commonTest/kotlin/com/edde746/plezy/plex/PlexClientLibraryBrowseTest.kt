package com.edde746.plezy.plex

import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.FilterEditorKind
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.MediaFilterField
import com.edde746.plezy.model.MediaFilterUnit
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.PersonCredit
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private fun MockRequestHandleScope.notFound(): HttpResponseData = respond("not found", HttpStatusCode.NotFound)

private val HttpRequestData.path: String get() = url.encodedPath
private fun HttpRequestData.param(name: String): String? = url.parameters[name]

class PlexLibraryFiltersAndSortsTest {
    @Test
    fun filtersAndSortsUseDedicatedPlexEndpoints() = runTest {
        val requests = mutableListOf<Url>()
        val client = testPlexClient({ request ->
            requests += request.url
            when (request.path) {
                "/library/sections/1/filters" -> jsonResponse(FILTERS_PAYLOAD)
                "/library/sections/1/sorts" -> jsonResponse(SORTS_PAYLOAD)
                else -> notFound()
            }
        })

        val filters = client.getLibraryFilters("1")
        val sorts = client.fetchSortOptions("1", "show")

        assertEquals(listOf("/library/sections/1/filters", "/library/sections/1/sorts"), requests.map { it.encodedPath })
        assertTrue(requests.all { it.parameters.names().none { name -> name != "X-Plex-Token" } })
        assertEquals(listOf("genre", "year", "unwatched"), filters.map { it.filter })
        assertEquals(
            listOf("titleSort", "rating", "audienceRating", "addedAt", "episode.addedAt", "lastViewedAt", "random", "viewCount", "userRating"),
            sorts.map { it.key },
        )
    }

    @Test
    fun filterSchemaParsesFieldsAndPerTypeOperatorsWithoutAskingForItems() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            if (request.path == "/library/sections/1/all") jsonResponse(META_PAYLOAD) else notFound()
        })

        val result = client.fetchLibraryFiltersWithValues("1", MediaKind.MOVIE)
        val byField = result.filters.associateBy { it.filter }

        val request = requests.single()
        assertEquals("1", request.param("includeMeta"))
        // Both bounds: PMS ignores a lone Size=0 and answers with the whole section.
        assertEquals("0", request.param("X-Plex-Container-Start"))
        assertEquals("0", request.param("X-Plex-Container-Size"))
        assertEquals("1", request.param("type"))

        assertEquals(listOf(LibraryFilterOperator.IS, LibraryFilterOperator.IS_NOT), byField.getValue("genre").operators)
        assertEquals("/library/sections/1/genre?type=1", byField.getValue("genre").key)
        assertEquals(FilterEditorKind.VALUE_LIST, byField.getValue("genre").editorKind)

        assertTrue(LibraryFilterOperator.AT_LEAST in byField.getValue("year").operators)
        assertTrue(LibraryFilterOperator.AT_MOST in byField.getValue("year").operators)
        assertEquals("/library/sections/1/year?type=1", byField.getValue("year").key)

        assertEquals("", byField.getValue("mediaSize").key)
        assertEquals(FilterEditorKind.NUMBER, byField.getValue("mediaSize").editorKind)
        assertEquals(MediaFilterUnit.FILE_SIZE, byField.getValue("mediaSize").unit)
        assertEquals(MediaFilterUnit.DURATION, byField.getValue("duration").unit)
        assertEquals(MediaFilterUnit.NONE, byField.getValue("year").unit)

        assertTrue(LibraryFilterOperator.MATCHES in byField.getValue("title").operators)
        assertTrue(LibraryFilterOperator.BEGINS_WITH in byField.getValue("title").operators)
        assertEquals("", byField.getValue("title").key)
        assertEquals(FilterEditorKind.TEXT, byField.getValue("title").editorKind)

        assertEquals(FilterEditorKind.DATE, byField.getValue("addedAt").editorKind)
        assertTrue(byField.getValue("unwatched").isBoolean)
        assertTrue(byField.getValue("unwatched").supportsExclusion)

        assertEquals(FilterEditorKind.TEXT, assertNotNull(byField[MediaFilterField.FILE]).editorKind)
        assertTrue(result.cachedValues.isEmpty())
    }

    @Test
    fun filterSchemaReadsTheActiveTypeAndStripsItsOwnPrefix() = runTest {
        val client = testPlexClient({ request ->
            if (request.path == "/library/sections/2/all") jsonResponse(SHOW_META_PAYLOAD) else notFound()
        })

        val result = client.fetchLibraryFiltersWithValues("2", MediaKind.SHOW)
        val fields = result.filters.map { it.filter }

        assertTrue("genre" in fields)
        assertFalse("show.genre" in fields)
        assertFalse("episode.title" in fields)
        assertEquals("/library/sections/2/genre?type=2", result.filters.first { it.filter == "genre" }.key)
        // A show-type query answers 500 for the file filter.
        assertFalse(MediaFilterField.FILE in fields)
    }

    @Test
    fun filterSchemaFallsBackToTheLegacyListingWhenTheServerPublishesNone() = runTest {
        val paths = mutableListOf<String>()
        val client = testPlexClient({ request ->
            paths += request.path
            when (request.path) {
                "/library/sections/1/all" -> jsonResponse("""{"MediaContainer":{"size":0}}""")
                "/library/sections/1/filters" -> jsonResponse(FILTERS_PAYLOAD)
                else -> notFound()
            }
        })

        val result = client.fetchLibraryFiltersWithValues("1", MediaKind.MOVIE)

        assertEquals(listOf("/library/sections/1/all", "/library/sections/1/filters"), paths)
        assertEquals(listOf("genre", "year", "unwatched"), result.filters.map { it.filter })
        assertTrue(result.filters.first().supportsExclusion)
    }

    @Test
    fun aSharedLibraryHasNoFilterSchemaToRead() = runTest {
        var calls = 0
        val client = testPlexClient({
            calls++
            notFound()
        })

        assertEquals(LibraryFilterResult.EMPTY, client.fetchLibraryFiltersWithValues("shared", null))
        assertEquals(0, calls)
    }

    @Test
    fun genreCategoriesCarryTheGenreFilterIdArtAndTint() = runTest {
        val requests = mutableListOf<String>()
        val client = testPlexClient({ request ->
            requests += request.path
            jsonResponse(
                """
                {"MediaContainer":{"size":3,"Directory":[
                  {"key":"/library/sections/2/all?genre=239","title":"Action","type":"directory",
                   "thumb":"/photo/:/transcode?blendColor=2B717E&width=2560&height=1440&url=%2Flibrary%2Fmetadata%2F9250%2Fart%2F1791086805"},
                  {"key":"/library/sections/2/all?genre=240","title":"Comedy","type":"directory"},
                  {"key":"/library/sections/2/all?label=12","title":"Label","type":"directory"}
                ]}}
                """.trimIndent(),
            )
        })

        val genres = client.fetchLibraryGenres("2", MediaKind.SHOW)

        assertEquals(listOf("/library/sections/2/categories"), requests)
        assertEquals(listOf("Action" to "239", "Comedy" to "240"), genres.map { it.title to it.filterValue })
        assertEquals("/library/metadata/9250/art/1791086805", genres.first().artPath)
        assertEquals(0x2B717E, genres.first().accentRgb)
        assertNull(genres.last().artPath)
        assertNull(genres.last().accentRgb)
    }

    @Test
    fun appendsDateAddedPlaysAndUserRatingSortsOnlyForVideoLibraries() = runTest {
        fun client() = testPlexClient({ request ->
            if (request.path == "/library/sections/1/sorts") {
                jsonResponse("""{"MediaContainer":{"Directory":[{"key":"titleSort","title":"Title","defaultDirection":"asc"}]}}""")
            } else {
                notFound()
            }
        })

        for (type in listOf("movie", "show", "clip")) {
            val sorts = client().fetchSortOptions("1", type)
            assertEquals(listOf("titleSort", "addedAt", "viewCount", "userRating"), sorts.map { it.key }, type)
            val dateAdded = sorts.single { it.key == "addedAt" }
            assertEquals("addedAt:desc", dateAdded.descKey, type)
            assertEquals("desc", dateAdded.defaultDirection, type)
        }

        assertEquals(listOf("titleSort"), client().fetchSortOptions("1", "artist").map { it.key })
    }

    @Test
    fun doesNotDuplicateAdvertisedExtraSorts() = runTest {
        val client = testPlexClient({ request ->
            if (request.path == "/library/sections/1/sorts") {
                jsonResponse(
                    """{"MediaContainer":{"Directory":[
                      {"key":"titleSort","title":"Title","defaultDirection":"asc"},
                      {"key":"addedAt","title":"Date Added","defaultDirection":"desc"},
                      {"key":"viewCount","title":"Plays","defaultDirection":"desc"}]}}""",
                )
            } else {
                notFound()
            }
        })

        assertEquals(listOf("titleSort", "addedAt", "viewCount", "userRating"), client.fetchSortOptions("1", "movie").map { it.key })
    }

    @Test
    fun musicAlbumSortsAskForTheAlbumType() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("""{"MediaContainer":{"Directory":[{"key":"titleSort","title":"Title"}]}}""")
        })

        client.fetchSortOptions("3", "album")

        assertEquals("9", requests.single().param("type"))
    }

    @Test
    fun theSortTheSectionMarksDefaultCarriesItsUnsortedDirection() = runTest {
        val client = testPlexClient({
            jsonResponse(
                """{"MediaContainer":{"Directory":[
                  {"key":"titleSort","title":"Title","default":"asc","defaultDirection":"asc"},
                  {"key":"addedAt","title":"Date Added","defaultDirection":"desc"}]}}""",
            )
        })

        val sorts = client.fetchSortOptions("1", "movie")
        assertEquals(listOf("asc"), sorts.mapNotNull { it.unsortedDirection })
        assertEquals("asc", sorts.first().unsortedDirection)
    }

    @Test
    fun aFailedSortRequestFallsBackToTheBuiltInSorts() = runTest {
        val client = testPlexClient({ respond("boom", HttpStatusCode.InternalServerError) })

        val sorts = client.fetchSortOptions("1", "show")

        assertEquals(
            listOf("titleSort", "addedAt", "episode.originallyAvailableAt", "originallyAvailableAt", "rating", "viewCount", "userRating"),
            sorts.map { it.key },
        )
    }

    @Test
    fun aSharedLibrarySortsByTitleOrDateShared() = runTest {
        var calls = 0
        val client = testPlexClient({
            calls++
            notFound()
        })

        assertEquals(listOf("titleSort", "taggingCreatedAt"), client.fetchSortOptions("shared", null).map { it.key })
        assertEquals(0, calls)
    }

    @Test
    fun firstCharactersReadStringSizes() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("""{"MediaContainer":{"Directory":[{"key":"A","title":"A","size":"12"},{"key":"#","title":"#","size":3}]}}""")
        })

        val characters = client.fetchFirstCharacters("1", type = 2)

        assertEquals("/library/sections/1/firstCharacter", requests.single().path)
        assertEquals("2", requests.single().param("type"))
        assertEquals(listOf(LibraryFirstCharacter("A", "A", 12), LibraryFirstCharacter("#", "#", 3)), characters)
    }

    @Test
    fun sectionPrefsMapSettingIdsToValues() = runTest {
        val client = testPlexClient({ request ->
            if (request.path == "/library/sections/4/prefs") {
                jsonResponse("""{"MediaContainer":{"Setting":[{"id":"enableCinemaTrailers","value":true},{"id":"language","value":"en"}]}}""")
            } else {
                notFound()
            }
        })

        val prefs = client.getLibrarySectionPrefs("4")

        assertEquals(setOf("enableCinemaTrailers", "language"), prefs.keys)
        assertEquals("en", prefs["language"].scalarString())
    }

    @Test
    fun scanAndRefreshUseTheSectionRefreshEndpoint() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            respond("", HttpStatusCode.OK)
        })

        client.scanLibrary("5")
        client.refreshLibraryMetadata("5")

        assertEquals(listOf("/library/sections/5/refresh", "/library/sections/5/refresh"), requests.map { it.path })
        assertNull(requests[0].param("force"))
        assertEquals("1", requests[1].param("force"))
    }
}

class PlexFoldersAndPeopleTest {
    @Test
    fun folderRowsAreClassifiedAndCarryTheirFolderKey() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when (request.path) {
                "/library/sections/3/folder" -> jsonResponse(
                    """{"MediaContainer":{
                      "Directory":[{"key":"/library/sections/3/folder?parent=10","title":"Holidays"}],
                      "Metadata":[{"ratingKey":"7","key":"/library/metadata/7","type":"movie","title":"Clip"}]}}""",
                )
                else -> notFound()
            }
        })

        val rows = client.fetchLibraryFolders("3", null)

        assertEquals("0", requests.single().param("includeCollections"))
        val movie = rows.single { it.id == "7" }
        assertEquals(MediaKind.MOVIE, movie.kind)
        assertEquals("3", movie.libraryId)
        val folder = rows.single { it.title == "Holidays" }
        assertEquals(MediaKind.FOLDER, folder.kind)
        assertEquals("/library/sections/3/folder?parent=10", folder.backendFolderKey)
        assertEquals("3", folder.libraryId)
    }

    @Test
    fun folderChildrenFollowTheFolderKey() = runTest {
        val paths = mutableListOf<String>()
        val client = testPlexClient({ request ->
            paths += request.path
            jsonResponse("""{"MediaContainer":{"Directory":[{"key":"/library/sections/3/folder?parent=11","title":"Sub","type":"folder"}]}}""")
        })
        val parent = testPlexClient({ jsonResponse("""{"MediaContainer":{"Directory":[{"key":"/library/sections/3/folder?parent=10","title":"Top"}]}}""") })
            .fetchLibraryFolders("3", null).single()

        val children = client.fetchFolderChildren(parent, null, null, null)

        assertEquals(listOf("/library/sections/3/folder"), paths)
        assertEquals(MediaKind.FOLDER, children.single().kind)
        assertEquals("/library/sections/3/folder?parent=11", children.single().backendFolderKey)
    }

    @Test
    fun aRowWithoutAFolderKeyHasNoChildren() = runTest {
        var calls = 0
        val client = testPlexClient({
            calls++
            notFound()
        })
        val movie = PlexMappers.mediaItem(kotlinx.serialization.json.buildJsonObject { put("ratingKey", kotlinx.serialization.json.JsonPrimitive("1")); put("type", kotlinx.serialization.json.JsonPrimitive("movie")) })

        assertTrue(client.fetchFolderChildren(movie, null, null, null).isEmpty())
        assertEquals(0, calls)
    }

    @Test
    fun personMediaPagePassesRequestedPagination() = runTest {
        var request: HttpRequestData? = null
        val client = testPlexClient({ r ->
            if (r.path == "/library/people/person-1/media") {
                request = r
                jsonResponse("""{"MediaContainer":{"size":1,"totalSize":30,"Metadata":[{"ratingKey":"99","type":"movie","title":"Movie"}]}}""")
            } else {
                notFound()
            }
        })

        val page = client.fetchPersonMediaPage("person-1", 20, 10)

        assertEquals("99", page.items.single().id)
        assertEquals(30, page.totalCount)
        assertEquals(20, page.offset)
        assertEquals("20", assertNotNull(request).param("X-Plex-Container-Start"))
        assertEquals("10", request!!.param("X-Plex-Container-Size"))
    }

    @Test
    fun personDetailsComeFromDiscoverWithThePlexTvAccountToken() = runTest {
        val requests = mutableListOf<Url>()
        var discoverToken: String? = null
        val client = testPlexClient({ request ->
            requests += request.url
            when {
                request.url.host == "discover.provider.plex.tv" -> {
                    discoverToken = request.headers["X-Plex-Token"]
                    jsonResponse(
                        """{"MediaContainer":{"size":1,"Metadata":[{"title":"Heath Ledger",
                          "summary":"Heath Andrew Ledger was an Australian actor.","bornAt":"1979-04-04","diedAt":"2008-01-22",
                          "birthPlace":" Perth, Western Australia, Australia"}]}}""",
                    )
                }
                request.path == "/library/people/38943" -> jsonResponse(
                    """{"MediaContainer":{"size":1,"Directory":[{"id":38943,"tag":"Heath Ledger","tagType":6,"tagKey":"5d776825eb5d26001f1dd125"}]}}""",
                )
                else -> notFound()
            }
        })
        client.bindAccount("plex.account-1", "account-token")

        val details = client.fetchPersonDetails("38943")

        assertEquals("discover.provider.plex.tv", requests.last().host)
        assertEquals("/library/people/5d776825eb5d26001f1dd125", requests.last().encodedPath)
        // Discover rejects a Home or shared user's server token.
        assertEquals("account-token", discoverToken)
        assertEquals("Heath Andrew Ledger was an Australian actor.", details.biography)
        assertEquals(CalendarDate(1979, 4, 4), details.birthDate)
        assertEquals(CalendarDate(2008, 1, 22), details.deathDate)
        assertEquals("Perth, Western Australia, Australia", details.birthPlace)
    }

    @Test
    fun aTagWithoutAPlexTvIdHasNoDetailsAndNeverReachesDiscover() = runTest {
        val hosts = mutableListOf<String>()
        val client = testPlexClient({ request ->
            hosts += request.url.host
            if (request.path == "/library/people/7") {
                jsonResponse("""{"MediaContainer":{"size":1,"Directory":[{"id":7,"tag":"Local Actor","tagType":6}]}}""")
            } else {
                notFound()
            }
        })
        client.bindAccount("plex.account-1", "account-token")

        assertTrue(client.fetchPersonDetails("7").isEmpty)
        assertFalse("discover.provider.plex.tv" in hosts)
    }

    @Test
    fun aClientWithoutAPlexTvAccountTokenHasNoDetailsAndSendsNothing() = runTest {
        var calls = 0
        val client = testPlexClient({
            calls++
            notFound()
        })

        assertTrue(client.fetchPersonDetails("38943").isEmpty)
        assertEquals(0, calls)
    }

    private fun peopleClient(rows: String, captured: MutableList<HttpRequestData>? = null) = testPlexClient({ request ->
        captured?.add(request)
        if (request.path != "/library/search") {
            respond("unexpected request", HttpStatusCode.InternalServerError)
        } else {
            jsonResponse("""{"MediaContainer":{"SearchResult":[$rows]}}""")
        }
    })

    private fun personRow(id: String, name: String, tagType: String = "6", sectionId: String? = null, thumb: String? = null): String {
        val section = sectionId?.let { "\"librarySectionID\":$it," } ?: ""
        val thumbField = thumb?.let { ",\"thumb\":\"$it\"" } ?: ""
        return """{"score":0.9,"Directory":{$section"type":"tag","id":$id,"tag":"$name","tagType":$tagType$thumbField}}"""
    }

    @Test
    fun searchPeopleMapsActorAndDirectorTagsAndIgnoresEveryOtherRow() = runTest {
        val waltzThumb = "https://metadata-static.plex.tv/3/people/3a908fb6b5c0dbc6d9468729b8e2c543.jpg"
        val captured = mutableListOf<HttpRequestData>()
        val client = peopleClient(
            listOf(
                // A nameless tag must not sink the rows after it.
                personRow("1", "", sectionId = "1"),
                personRow("38797", "Christoph Waltz", sectionId = "1", thumb = waltzThumb),
                // Ids, tag types and section ids may arrive as strings.
                personRow("\"38310\"", "Christopher Nolan", tagType = "\"4\"", sectionId = "\"1\""),
                personRow("555", "Christoph Writer", tagType = "7", sectionId = "1"),
                """{"score":0.5,"Metadata":{"ratingKey":"movie-1","type":"movie","title":"Christoph"}}""",
            ).joinToString(","),
            captured,
        )

        val people = client.searchPeople("Christoph", 20, emptySet())

        assertEquals(listOf("38797", "38310"), people.map { it.id })
        assertEquals(listOf("Christoph Waltz", "Christopher Nolan"), people.map { it.name })
        assertEquals(listOf(waltzThumb, null), people.map { it.thumbPath })
        assertEquals(listOf(PersonCredit.ACTOR, PersonCredit.DIRECTOR), people.map { it.credit })
        for (person in people) {
            assertEquals(BackendKind.PLEX, person.backend)
            assertEquals(ServerId(TEST_SERVER_ID), person.serverId)
            assertEquals("Test Server", person.serverName)
        }
        val request = captured.single()
        assertEquals("/library/search", request.path)
        assertEquals("Christoph", request.param("query"))
        assertEquals("people", request.param("searchTypes"))
    }

    @Test
    fun searchPeopleCollapsesSectionRowsAndHidesAPersonOnlyWhenEverySectionIsHidden() = runTest {
        val client = peopleClient(
            listOf(
                personRow("301", "Kana Hanazawa", sectionId = "1"),
                personRow("400", "Kana Ueda", sectionId = "2"),
                personRow("301", "Kana Hanazawa", sectionId = "\"2\""),
                // Shared media has no local section to hide.
                personRow("500", "Kana Asumi"),
            ).joinToString(","),
        )

        assertEquals(listOf("301", "400", "500"), client.searchPeople("Kana", 20, emptySet()).map { it.id })
        assertEquals(listOf("400", "301", "500"), client.searchPeople("Kana", 20, setOf("1")).map { it.id })
        assertEquals(listOf("500"), client.searchPeople("Kana", 20, setOf("1", "2")).map { it.id })
    }

    @Test
    fun searchPeopleLimitCapsDistinctPeopleNotSectionRows() = runTest {
        val captured = mutableListOf<HttpRequestData>()
        val client = peopleClient(
            listOf(
                personRow("301", "Kana Hanazawa", sectionId = "1"),
                personRow("301", "Kana Hanazawa", sectionId = "2"),
                personRow("400", "Kana Ueda", sectionId = "1"),
                personRow("500", "Kana Asumi", sectionId = "1"),
                personRow("600", "Kana Kita", sectionId = "1"),
            ).joinToString(","),
            captured,
        )

        assertEquals(listOf("301", "400", "500"), client.searchPeople("Kana", 3, emptySet()).map { it.id })
        assertTrue(captured.single().param("limit")!!.toInt() > 3)
    }

    @Test
    fun searchPeopleServerErrorsPropagate() = runTest {
        val client = testPlexClient({ respond("temporary failure", HttpStatusCode.InternalServerError) })

        assertFailsWith<MediaServerHttpException> { client.searchPeople("Kana", 20, emptySet()) }
    }

    @Test
    fun clientSideEpisodeQueueKeepsWatchedRowsAndSpecialsLastByDefault() = runTest {
        val paths = mutableListOf<String>()
        val client = testPlexClient({ request ->
            paths += request.path
            if (request.path == "/library/metadata/show-1/grandchildren") {
                jsonResponse(
                    """{"MediaContainer":{"size":3,"totalSize":3,"Metadata":[
                      {"ratingKey":"special","type":"episode","title":"Special","parentIndex":0,"index":1,"originallyAvailableAt":"2024-01-02","viewCount":1},
                      {"ratingKey":"ep-2","type":"episode","title":"Episode 2","parentIndex":1,"index":2,"originallyAvailableAt":"2024-01-03","viewCount":1},
                      {"ratingKey":"ep-1","type":"episode","title":"Episode 1","parentIndex":1,"index":1,"originallyAvailableAt":"2024-01-01","viewCount":1}]}}""",
                )
            } else {
                notFound()
            }
        })

        val episodes = assertNotNull(client.fetchClientSideEpisodeQueue("show-1"))

        assertTrue("/library/metadata/show-1/grandchildren" in paths)
        assertEquals(listOf("ep-1", "ep-2", "special"), episodes.map { it.id })
        assertTrue(episodes.all { it.isWatched })
    }
}

class PlexExternalIdsFetchTest {
    private fun metadata(guidArray: String? = null, scalarGuid: String? = null): String {
        val fields = listOfNotNull(scalarGuid?.let { "\"guid\":$it" }, guidArray?.let { "\"Guid\":$it" })
        val extra = if (fields.isEmpty()) "" else "," + fields.joinToString(",")
        return """{"MediaContainer":{"Metadata":[{"ratingKey":"show-1","type":"show","title":"Show"$extra}]}}"""
    }

    @Test
    fun readsTheModernGuidArrayAndAsksForIt() = runTest {
        var request: HttpRequestData? = null
        val client = testPlexClient({ r ->
            request = r
            jsonResponse(
                metadata(
                    guidArray = """[{"id":"imdb://tt12345"},{"id":"tmdb://456"},{"id":"tvdb://789"}]""",
                    scalarGuid = "\"plex://show/abc\"",
                ),
            )
        })

        val ids = client.fetchExternalIds("show-1")

        assertEquals("/library/metadata/show-1", request!!.path)
        assertEquals("1", request!!.param("includeGuids"))
        assertEquals(ExternalIds(imdb = "tt12345", tmdb = 456, tvdb = 789), ids)
    }

    @Test
    fun fallsBackToALegacyAgentScalarGuid() = runTest {
        val client = testPlexClient({ jsonResponse(metadata(scalarGuid = "\"com.plexapp.agents.thetvdb://315500?lang=en\"")) })

        assertEquals(315500, client.fetchExternalIds("show-1").tvdb)
    }

    @Test
    fun mapsAHamaAnidbGuidWhichCarriesNoCatalogId() = runTest {
        val client = testPlexClient({ jsonResponse(metadata(scalarGuid = "\"com.plexapp.agents.hama://anidb-11905?lang=en\"")) })

        val ids = client.fetchExternalIds("show-1")

        assertEquals(11905, ids.anidb)
        assertTrue(ids.hasAny)
        assertFalse(ids.hasCatalogIds)
    }

    @Test
    fun theGuidArrayWinsPerFieldAndTheScalarFillsTheRest() = runTest {
        val client = testPlexClient({
            jsonResponse(metadata(guidArray = """[{"id":"tvdb://789"}]""", scalarGuid = "\"com.plexapp.agents.hama://tvdb-315500\""))
        })

        assertEquals(789, client.fetchExternalIds("show-1").tvdb)
    }

    @Test
    fun anUnmatchedItemResolvesToNoIds() = runTest {
        val client = testPlexClient({ jsonResponse(metadata(scalarGuid = "\"com.plexapp.agents.none://315500\"")) })

        assertFalse(client.fetchExternalIds("show-1").hasAny)
    }

    @Test
    fun anItemThatIsGoneResolvesToNoIds() = runTest {
        val client = testPlexClient({ notFound() })

        assertFalse(client.fetchExternalIds("show-1").hasAny)
    }

    @Test
    fun aFailedRequestThrowsInsteadOfReadingAsNoIds() = runTest {
        val client = testPlexClient({ respond("nope", HttpStatusCode.InternalServerError) })

        val error = assertFailsWith<MediaServerHttpException> { client.fetchExternalIds("show-1") }
        assertEquals(500, error.statusCode)
    }
}

class PlexExternalIdLookupTest {
    private fun metadata(rows: String = "") = """{"MediaContainer":{"Metadata":[$rows]}}"""

    /** The hub of [type] plus the episode hub Plex adds to every `tv` search, which must never leak into matches. */
    private fun hubs(rows: String, type: String = "movie") =
        """{"MediaContainer":{"Hub":[
          {"type":"$type","hubIdentifier":"$type","Metadata":[$rows]},
          {"type":"episode","hubIdentifier":"episode","Metadata":[{"ratingKey":"stray-episode","type":"episode","title":"Pilot",
            "Guid":[{"id":"tvdb://123"},{"id":"tmdb://42"},{"id":"imdb://tt12345"}]}]}]}}"""

    private fun HttpRequestData.isTitleSearch() = path == "/hubs/search"
    private fun HttpRequestData.isGuidLookup() = path == "/library/all" && param("guid") != null
    private fun HttpRequestData.isSeasonLookup() = path == "/library/all" && param("type") == "3"

    private fun seasons(request: HttpRequestData, showsWithSeason: Set<String>): String {
        val index = request.param("season.index")!!
        return metadata(
            request.param("show.id")!!.split(',').filter { it in showsWithSeason }.joinToString(",") { show ->
                """{"ratingKey":"$show-season","parentRatingKey":"$show","type":"season","title":"Season","index":$index}"""
            },
        )
    }

    @Test
    fun searchesTheTitleThroughTheHubIndexAndFiltersLegacyGuidsByIdInOneRequest() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            if (request.isGuidLookup()) {
                jsonResponse(metadata())
            } else {
                jsonResponse(
                    hubs(
                        """{"ratingKey":"legacy-movie","type":"movie","title":"Legacy Movie","librarySectionID":5,
                          "librarySectionTitle":"Legacy Movies","guid":"com.plexapp.agents.imdb://tt29768334?lang=en",
                          "Guid":[{"id":"tmdb://999"}]}""",
                    ),
                )
            }
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(imdb = "tt29768334"), MediaKind.MOVIE, listOf("Legacy Movie"), null, null, null))

        assertEquals(listOf("legacy-movie"), matches.map { it.id })
        assertEquals("5", matches.single().libraryId)
        assertEquals("Legacy Movies", matches.single().libraryTitle)
        assertEquals(TEST_SERVER_ID, matches.single().serverId)
        assertEquals("Test Server", matches.single().serverName)
        assertEquals(2, requests.size)
        val guidLookup = requests.single { it.isGuidLookup() }
        assertEquals("1", guidLookup.param("type"))
        assertEquals("1", guidLookup.param("includeGuids"))
        assertEquals(
            listOf("com.plexapp.agents.imdb://tt29768334?", "com.plexapp.agents.hama://imdb-tt29768334?"),
            guidLookup.param("guid")!!.split(','),
        )
        val search = requests.single { it.isTitleSearch() }
        assertEquals("Legacy Movie", search.param("query"))
        assertEquals("movies", search.param("searchTypes"))
        assertEquals("1", search.param("includeGuids"))
        assertEquals("50", search.param("limit"))
        assertNull(search.param("year"))
    }

    @Test
    fun aShowSearchReadsTheShowHubOnly() = runTest {
        var search: HttpRequestData? = null
        val client = testPlexClient({ request ->
            if (request.isGuidLookup()) {
                jsonResponse(metadata())
            } else {
                search = request
                jsonResponse(
                    hubs("""{"ratingKey":"legacy-show","type":"show","title":"Legacy Show","guid":"com.plexapp.agents.hama://tvdb4-315500?lang=en"}""", "show"),
                )
            }
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(tvdb = 315500, tmdb = 42), MediaKind.SHOW, listOf("Legacy Show"), null, null, null))

        assertEquals(listOf("legacy-show"), matches.map { it.id })
        assertEquals("tv", search!!.param("searchTypes"))
    }

    @Test
    fun aLegacyAgentCopyIsReachedByIdWithoutATitleHit() = runTest {
        val client = testPlexClient({ request ->
            if (!request.isGuidLookup()) {
                jsonResponse(hubs("", "show"))
            } else {
                assertTrue("com.plexapp.agents.thetvdb://315500?" in request.param("guid")!!.split(','))
                jsonResponse(
                    metadata(
                        """{"ratingKey":"legacy-only","type":"show","title":"Shirayuki-hime","librarySectionTitle":"Anime (romaji)",
                          "guid":"com.plexapp.agents.thetvdb://315500?lang=en"}""",
                    ),
                )
            }
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(tvdb = 315500), MediaKind.SHOW, listOf("Snow White with the Red Hair"), null, null, null),
        )

        assertEquals(listOf("legacy-only"), matches.map { it.id })
    }

    @Test
    fun aGuidFilterRowThatDoesNotVerifyByIdIsDropped() = runTest {
        val client = testPlexClient({ request ->
            if (!request.isGuidLookup()) {
                jsonResponse(hubs("", "show"))
            } else {
                jsonResponse(metadata("""{"ratingKey":"other-show","type":"show","title":"Other Show","guid":"com.plexapp.agents.thetvdb://3155001?lang=en"}"""))
            }
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(tvdb = 315500), MediaKind.SHOW, listOf("Snow White with the Red Hair"), null, null, null),
        )

        assertTrue(matches.isEmpty())
    }

    @Test
    fun returnsBothAgentVariantsModernGuidMatchFirst() = runTest {
        val client = testPlexClient({ request ->
            if (request.isGuidLookup()) {
                jsonResponse(metadata())
            } else {
                jsonResponse(
                    hubs(
                        """{"ratingKey":"legacy-match","type":"movie","title":"Duplicate","guid":"com.plexapp.agents.imdb://tt12345"},
                           {"ratingKey":"modern-match","type":"movie","title":"Duplicate","guid":"plex://movie/modern","Guid":[{"id":"imdb://tt12345"}]}""",
                    ),
                )
            }
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(imdb = "tt12345"), MediaKind.MOVIE, listOf("Duplicate"), null, null, null))

        assertEquals(listOf("modern-match", "legacy-match"), matches.map { it.id })
    }

    @Test
    fun doesNotMatchUnsupportedOrMalformedScalarGuids() = runTest {
        val client = testPlexClient({ request ->
            if (request.isGuidLookup()) {
                jsonResponse(metadata())
            } else {
                jsonResponse(
                    hubs(
                        """{"ratingKey":"anidb","type":"show","title":"Unsupported","guid":"com.plexapp.agents.hama://anidb-11905"},
                           {"ratingKey":"wrong-shape","type":"show","title":"Unsupported","guid":315500}""",
                        "show",
                    ),
                )
            }
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(tvdb = 315500), MediaKind.SHOW, listOf("Unsupported"), null, null, null))

        assertTrue(matches.isEmpty())
    }

    @Test
    fun searchesEveryTitleCandidateAndUnionsTheirIdVerifiedCopies() = runTest {
        val searches = mutableListOf<String>()
        val client = testPlexClient({ request ->
            if (request.isGuidLookup()) return@testPlexClient jsonResponse(metadata())
            val query = request.param("query")!!
            searches += query
            when (query) {
                "葬送のフリーレン" -> jsonResponse(
                    hubs(
                        """{"ratingKey":"romaji-parent","type":"show","title":"Sousou no Frieren","librarySectionTitle":"Anime (romaji)","Guid":[{"id":"tvdb://123"}]},
                           {"ratingKey":"verified-parent","type":"show","title":"Frieren","Guid":[{"id":"tvdb://123"}]}""",
                        "show",
                    ),
                )
                "Frieren" -> jsonResponse(
                    hubs(
                        """{"ratingKey":"wrong-parent","type":"show","title":"Frieren","Guid":[{"id":"tvdb://999"}]},
                           {"ratingKey":"verified-parent","type":"show","title":"Frieren","Guid":[{"id":"tvdb://123"}]}""",
                        "show",
                    ),
                )
                else -> jsonResponse(hubs("", "show"))
            }
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(tvdb = 123), MediaKind.SHOW, listOf("葬送のフリーレン", "Frieren Season 2", "Frieren"), null, null, null),
        )

        assertEquals(listOf("romaji-parent", "verified-parent"), matches.map { it.id })
        assertEquals(listOf("葬送のフリーレン", "Frieren Season 2", "Frieren"), searches)
    }

    @Test
    fun usesAnExactPlexGuidWithoutExternalIdsOrATitleQuery() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(metadata("""{"ratingKey":"exact-show","type":"show","title":"Exact Show","guid":"plex://show/5e01fc33932ff9001db3b242"}"""))
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(), MediaKind.SHOW, listOf("Never Searched"), null, "plex://show/5e01fc33932ff9001db3b242", null),
        )

        assertEquals(listOf("exact-show"), matches.map { it.id })
        val request = requests.single()
        assertEquals("/library/all", request.path)
        assertEquals("plex://show/5e01fc33932ff9001db3b242", request.param("guid"))
        assertEquals("2", request.param("type"))
        assertEquals("1", request.param("includeGuids"))
        assertNull(request.param("query"))
    }

    @Test
    fun aGuidOnlyLookupStopsAfterTheExactGuidMiss() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(metadata())
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(), MediaKind.MOVIE, listOf("Night on the Galactic Railroad"), null, "plex://movie/5d776b59ad5437001f79c6f8", null),
        )

        assertTrue(matches.isEmpty())
        assertEquals("plex://movie/5d776b59ad5437001f79c6f8", requests.single().param("guid"))
    }

    @Test
    fun nothingToAskAndUnsupportedKindsAreNotLookedUp() = runTest {
        var calls = 0
        val client = testPlexClient({
            calls++
            jsonResponse(metadata())
        })

        assertNull(client.findByExternalIds(ExternalIds(), MediaKind.MOVIE, listOf("Title"), null, null, null))
        assertNull(client.findByExternalIds(ExternalIds(tmdb = 1), MediaKind.EPISODE, listOf("Title"), null, null, null))
        assertEquals(0, calls)
    }

    @Test
    fun anAgreedSeasonRefGatesEveryCandidateWithOneSeasonRequest() = runTest {
        val seasonRequests = mutableListOf<HttpRequestData>()
        val extraRequests = mutableListOf<String>()
        val client = testPlexClient({ request ->
            if (request.param("includePreferences") != null || request.path.endsWith("/prefs") || request.path.endsWith("/children")) {
                extraRequests += request.path
            }
            when {
                request.isSeasonLookup() -> {
                    seasonRequests += request
                    jsonResponse(seasons(request, setOf("complete-show")))
                }
                request.isGuidLookup() -> jsonResponse(metadata())
                else -> jsonResponse(
                    hubs(
                        """{"ratingKey":"incomplete-show","type":"show","title":"Split Show","librarySectionTitle":"Shows","Guid":[{"id":"tvdb://555"}]},
                           {"ratingKey":"complete-show","type":"show","title":"Split Show","librarySectionTitle":"4K Shows","Guid":[{"id":"tvdb://555"}]}""",
                        "show",
                    ),
                )
            }
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(tvdb = 555), MediaKind.SHOW, listOf("Split Show"), null, null, ExternalSeasonRef(tvdb = 2, tmdb = 2)),
        )

        assertEquals(listOf("complete-show"), matches.map { it.id })
        assertEquals("incomplete-show,complete-show", seasonRequests.single().param("show.id"))
        assertEquals("2", seasonRequests.single().param("season.index"))
        assertTrue(extraRequests.isEmpty())
    }

    @Test
    fun aDisagreeingSeasonRefIsLeftUngated() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            if (request.isGuidLookup()) {
                jsonResponse(metadata())
            } else {
                jsonResponse(
                    hubs("""{"ratingKey":"ungated-show","type":"show","title":"Ungated Show","librarySectionID":9,"Guid":[{"id":"tvdb://300"}]}""", "show"),
                )
            }
        })

        val matches = assertNotNull(
            client.findByExternalIds(ExternalIds(tvdb = 300), MediaKind.SHOW, listOf("Ungated Show"), null, null, ExternalSeasonRef(tvdb = 2, tmdb = 1)),
        )

        assertEquals(listOf("ungated-show"), matches.map { it.id })
        assertTrue(requests.none { it.isSeasonLookup() })
        assertEquals(setOf("/library/all", "/hubs/search"), requests.map { it.path }.toSet())
        assertEquals(2, requests.size)
    }

    @Test
    fun returnsEveryLibraryCopySharingOneExactPlexGuid() = runTest {
        val client = testPlexClient({
            jsonResponse(
                metadata(
                    """{"ratingKey":"hd-copy","type":"movie","title":"Dual Library","guid":"plex://movie/dual","librarySectionID":1,
                        "librarySectionTitle":"Movies","Media":[{"id":10,"videoResolution":"1080","videoCodec":"h264","container":"mkv"}]},
                       {"ratingKey":"uhd-copy","type":"movie","title":"Dual Library","guid":"plex://movie/dual","librarySectionID":2,
                        "librarySectionTitle":"4K Movies","Media":[{"id":20,"videoResolution":"4k","videoCodec":"hevc","container":"mkv"}]}""",
                ),
            )
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(), MediaKind.MOVIE, emptyList(), null, "plex://movie/dual", null))

        assertEquals(listOf("hd-copy", "uhd-copy"), matches.map { it.id })
        assertEquals(listOf("1", "2"), matches.map { it.libraryId })
        assertEquals(listOf("Movies", "4K Movies"), matches.map { it.libraryTitle })
        assertEquals(listOf("1080", "4k"), matches.map { it.mediaVersions?.single()?.videoResolution })
    }

    @Test
    fun keepsSearchingByTitleAfterAnExactGuidHit() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val exactCopy =
            """{"ratingKey":"exact-copy","type":"movie","title":"Mixed Agents","guid":"plex://movie/mixed","librarySectionTitle":"4K Movies","Guid":[{"id":"imdb://tt777"}]}"""
        val client = testPlexClient({ request ->
            requests += request
            if (request.isGuidLookup()) {
                assertEquals("plex://movie/mixed", request.param("guid")!!.split(',').first())
                jsonResponse(metadata(exactCopy))
            } else {
                jsonResponse(
                    hubs(
                        """$exactCopy,{"ratingKey":"dupe-copy","type":"movie","title":"Mixed Agents","guid":"plex://movie/mixed-duplicate",
                           "librarySectionTitle":"Movies","Guid":[{"id":"imdb://tt777"}]}""",
                    ),
                )
            }
        })

        val matches = assertNotNull(client.findByExternalIds(ExternalIds(imdb = "tt777"), MediaKind.MOVIE, listOf("Mixed Agents"), null, "plex://movie/mixed", null))

        assertEquals(listOf("exact-copy", "dupe-copy"), matches.map { it.id })
        assertEquals(2, requests.size)
    }

    @Test
    fun aServerThatCannotAnswerFailsTheLookupWithoutChangingEndpoints() = runTest {
        val hosts = mutableSetOf<String>()
        val client = testPlexClient(
            { request ->
                hosts += request.url.host
                respond("busy", HttpStatusCode.ServiceUnavailable)
            },
            baseUrl = "https://primary.example.com",
            prioritizedEndpoints = listOf("https://primary.example.com", "https://secondary.example.com"),
        )

        assertFailsWith<MediaServerHttpException> {
            client.findByExternalIds(ExternalIds(tmdb = 42), MediaKind.MOVIE, listOf("Busy Movie"), null, null, null)
        }
        assertEquals(setOf("primary.example.com"), hosts)
    }
}

private const val FILTERS_PAYLOAD = """{"MediaContainer":{"Directory":[
  {"filter":"genre","filterType":"string","key":"/library/sections/1/genre","title":"Genre","type":"filter"},
  {"filter":"year","filterType":"integer","key":"/library/sections/1/year","title":"Year","type":"filter"},
  {"filter":"unwatched","filterType":"boolean","key":"/library/sections/1/unwatched","title":"Unwatched","type":"filter"}]}}"""

private const val SORTS_PAYLOAD = """{"MediaContainer":{"Directory":[
  {"defaultDirection":"asc","descKey":"titleSort:desc","key":"titleSort","title":"Title"},
  {"defaultDirection":"desc","descKey":"rating:desc","key":"rating","title":"Critic Rating"},
  {"defaultDirection":"desc","descKey":"audienceRating:desc","key":"audienceRating","title":"Audience Rating"},
  {"defaultDirection":"desc","descKey":"addedAt:desc","key":"addedAt","title":"Date Added"},
  {"defaultDirection":"desc","descKey":"episode.addedAt:desc","key":"episode.addedAt","title":"Last Episode Date Added"},
  {"defaultDirection":"desc","descKey":"lastViewedAt:desc","key":"lastViewedAt","title":"Date Viewed"},
  {"defaultDirection":"desc","descKey":"random:desc","key":"random","title":"Randomly"}]}}"""

/** The `Meta` block PMS 1.43 publishes for a movie section, trimmed to the field shapes the editor tells apart. */
private const val META_PAYLOAD = """{"MediaContainer":{"size":0,"totalSize":57,"Meta":{
  "Type":[{"type":"movie","active":true,"Field":[
    {"key":"title","title":"Title","type":"string"},
    {"key":"year","title":"Year","type":"integer"},
    {"key":"mediaSize","title":"File Size","type":"integer","subType":"fileSize"},
    {"key":"duration","title":"Duration","type":"integer","subType":"duration"},
    {"key":"genre","title":"Genre","type":"tag"},
    {"key":"addedAt","title":"Date Added","type":"date"},
    {"key":"unwatched","title":"Unwatched","type":"boolean"}]}],
  "FieldType":[
    {"type":"tag","Operator":[{"key":"=","title":"is"},{"key":"!=","title":"is not"}]},
    {"type":"integer","Operator":[{"key":"=","title":"is"},{"key":"!=","title":"is not"},{"key":">>=","title":"is greater than"},{"key":"<<=","title":"is less than"}]},
    {"type":"string","Operator":[{"key":"=","title":"contains"},{"key":"!=","title":"does not contain"},{"key":"==","title":"is"},{"key":"!==","title":"is not"},{"key":"<=","title":"begins with"},{"key":">=","title":"ends with"}]},
    {"type":"boolean","Operator":[{"key":"=","title":"is"},{"key":"!=","title":"is not"}]},
    {"type":"date","Operator":[{"key":"<<=","title":"is before"},{"key":">>=","title":"is after"}]}]}}}"""

/** A show section: every field qualified with its type, the inactive episode type listed first on purpose. */
private const val SHOW_META_PAYLOAD = """{"MediaContainer":{"size":0,"Meta":{
  "Type":[
    {"type":"episode","active":false,"Field":[{"key":"episode.title","title":"Episode Title","type":"string"},{"key":"episode.genre","title":"Genre","type":"tag"}]},
    {"type":"show","active":true,"Field":[{"key":"show.title","title":"Title","type":"string"},{"key":"show.genre","title":"Genre","type":"tag"}]}],
  "FieldType":[{"type":"tag","Operator":[{"key":"=","title":"is"},{"key":"!=","title":"is not"}]}]}}}"""
