package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.SpecialsOrdering
import io.ktor.utils.io.errors.IOException
import kotlin.coroutines.cancellation.CancellationException
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject

class JellyfinBrowseTest {
    private val server = JellyfinTestServer()
    private var ordering = SpecialsOrdering.RESPECT_SERVER

    private fun browse(dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): Pair<JellyfinBrowse, JellyfinCore> {
        val core = server.core(dialect)
        return JellyfinBrowse(core) { ordering } to core
    }

    private fun page(rows: List<String>, total: Int? = null) =
        FakeResponse(200, """{"Items":[${rows.joinToString(",")}]${total?.let { ""","TotalRecordCount":$it""" } ?: ""}}""")

    private fun rows(prefix: String, type: String, range: IntRange) = range.map { """{"Id":"$prefix-$it","Type":"$type","Name":"$prefix $it"}""" }

    private val empty = FakeResponse(200, """{"Items":[],"TotalRecordCount":0}""")
    private val notFound = FakeResponse(404, "not found")

    private fun item(id: String, kind: MediaKind) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, serverId = "machine-1")

    private fun fields(req: RecordedRequest) = req.query.getValue("Fields").split(",")

    // Libraries.

    @Test
    fun concurrentFetchLibrariesShareOneViewsRequest() = runTest {
        val (browse, _) = browse()
        val gate = CompletableDeferred<Unit>()
        server.handler = {
            gate.await()
            FakeResponse(200, """{"Items":[{"Id":"lib-1","Name":"Movies","CollectionType":"movies"}]}""")
        }
        val calls = listOf(async { browse.fetchLibraries() }, async { browse.fetchLibraries() })
        runCurrent()
        gate.complete(Unit)
        val results = calls.awaitAll()

        assertEquals(1, server.requests.count { it.path == "/Users/user-1/Views" })
        assertEquals(listOf("lib-1", "lib-1"), results.map { it.single().id })

        // Single-flight, not a cache: a later call sees server-side changes.
        browse.fetchLibraries()
        assertEquals(2, server.requests.count { it.path == "/Users/user-1/Views" })
    }

    @Test
    fun fetchLibrariesDropsBoxsetPlaylistAndLiveTvViewsAndMemoizesTheList() = runTest {
        val (browse, _) = browse()
        server.handler = {
            FakeResponse(
                200,
                """{"Items":[
                {"Id":"lib-movies","Name":"Movies","CollectionType":"movies","Type":"CollectionFolder"},
                {"Id":"lib-shows","Name":"TV Shows","CollectionType":"tvshows","Type":"CollectionFolder"},
                {"Id":"lib-music","Name":"Music","CollectionType":"music","Type":"CollectionFolder"},
                {"Id":"lib-coll","Name":"Collections","CollectionType":"boxsets","Type":"CollectionFolder"},
                {"Id":"lib-pl","Name":"Playlists","CollectionType":"playlists","Type":"ManualPlaylistsFolder"},
                {"Id":"lib-live","Name":"Live TV","CollectionType":"livetv","Type":"UserView"}]}""",
            )
        }
        assertNull(browse.loadedLibraryViews)

        val libraries = browse.fetchLibraries()

        // Live TV is no library anywhere (Home, the sidebar, the Libraries picker): the app has its own Live TV entry.
        assertEquals(listOf("lib-movies", "lib-shows", "lib-music"), libraries.map { it.id })
        assertEquals(libraries, browse.loadedLibraryViews)
    }

    @Test
    fun fetchLibraryPagedContentSendsABoundedPagedItemsRequest() = runTest {
        val (browse, _) = browse()
        server.handler = {
            page(listOf("""{"Id":"movie-1","Type":"Movie","Name":"Movie","BackdropImageTags":["b0","b1","b2"]}"""), total = 123)
        }

        val result = browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.MOVIE, offset = 50, limit = 25))

        assertEquals("movie-1", result.items.single().id)
        assertEquals(123, result.totalCount)
        assertEquals(50, result.offset)
        val req = server.requests.single()
        assertEquals("/Items", req.path)
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "ParentId" to "lib-1",
                "Recursive" to "true",
                "StartIndex" to "50",
                "Limit" to "25",
                "EnableTotalRecordCount" to "true",
                "IncludeItemTypes" to "Movie",
                "Fields" to JellyfinCore.BROWSE_FIELDS,
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            req.query,
        )
    }

    @Test
    fun musicBrowseUsesLeafAppropriateFields() = runTest {
        val (browse, _) = browse()
        server.handler = { empty }

        browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.ALBUM, limit = 20))
        browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.TRACK, limit = 20))

        val (album, track) = server.requests.map { it.query }
        assertEquals("PremiereDate,OriginalTitle,SortName,DateCreated", album["Fields"])
        assertEquals("false", album["EnableUserData"])
        assertEquals("MusicAlbum", album["IncludeItemTypes"])
        assertEquals("UserData,PremiereDate,OriginalTitle,SortName", track["Fields"])
        assertEquals("Audio", track["IncludeItemTypes"])
        assertFalse("EnableUserData" in track)
    }

    @Test
    fun fetchLibraryPagedContentFallsBackToASentinelTotal() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            val start = req.query.getValue("StartIndex").toInt()
            page(rows("movie", "Movie", start until start + req.query.getValue("Limit").toInt()))
        }

        val result = browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.MOVIE, offset = 50, limit = 25))

        assertEquals(25, result.items.size)
        assertEquals(76, result.totalCount)
    }

    @Test
    fun libraryKindIsTheDefaultTypeOnlyWhenTheQueryNamesNone() = runTest {
        val (browse, _) = browse()
        server.handler = { empty }

        browse.fetchLibraryPagedContent("lib-1", LibraryQuery(limit = 20), libraryKind = MediaKind.SHOW)
        browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.EPISODE, limit = 20), libraryKind = MediaKind.SHOW)

        assertEquals(listOf("Series", "Episode"), server.requests.map { it.query["IncludeItemTypes"] })
    }

    @Test
    fun artistBrowseUsesAlbumArtistsAndDistrustsAZeroTotalWithRows() = runTest {
        val (browse, _) = browse()
        server.handler = { page(rows("artist", "MusicArtist", 0 until 20), total = 0) }

        val result = browse.fetchLibraryPagedContent("lib-1", LibraryQuery(kind = MediaKind.ARTIST, limit = 20, nameStartsWith = "B"))

        val req = server.requests.single()
        assertEquals("/Artists/AlbumArtists", req.path)
        assertFalse("IncludeItemTypes" in req.query)
        assertFalse("Recursive" in req.query)
        assertEquals("B", req.query["NameStartsWith"])
        assertEquals(21, result.totalCount)
    }

    @Test
    fun embyBrowseRowsAskForTheWithheldMetadataWithoutDuplicates() = runTest {
        server.handler = { empty }
        browse(MediaBrowserDialect.EMBY).first.fetchLibraryPagedContent("lib-1", LibraryQuery(limit = 5))
        browse(MediaBrowserDialect.JELLYFIN).first.fetchLibraryPagedContent("lib-1", LibraryQuery(limit = 5))

        val (emby, jellyfin) = server.requests.map(::fields)
        assertTrue(emby.containsAll(listOf("ProductionYear", "OfficialRating", "PremiereDate", "DateCreated", "UserDataLastPlayedDate")))
        assertTrue(emby.containsAll(jellyfin))
        assertEquals(emby.size, emby.toSet().size)
        assertFalse("AlternateMediaSources" in emby)
        assertTrue("DateCreated" in jellyfin)
        assertFalse("ProductionYear" in jellyfin)
        assertFalse("OfficialRating" in jellyfin)
    }

    @Test
    fun everyEmbyRowSetAsksForThePlayedDateAndJellyfinStaysFreeOfEmbyTokens() = runTest {
        server.handler = { empty }
        val emby = browse(MediaBrowserDialect.EMBY).first
        emby.fetchLibraryPagedContent("lib-1", LibraryQuery(limit = 5))
        emby.fetchChildren("season-1")
        val withFields = server.requests.filter { "Fields" in it.query }
        assertTrue(withFields.isNotEmpty())
        for (req in withFields) assertTrue("UserDataLastPlayedDate" in fields(req), req.path)

        server.requests.clear()
        val jellyfin = browse().first
        jellyfin.fetchLibraryPagedContent("lib-1", LibraryQuery(limit = 5))
        jellyfin.fetchChildren("season-1")
        for (req in server.requests) {
            assertFalse(req.url.encodedQuery.contains("UserDataLastPlayedDate"))
            assertFalse(req.url.encodedQuery.contains("AlternateMediaSources"))
        }
    }

    // Filters, sorts, genres, admin actions.

    @Test
    fun jellyfinFiltersComeFromTheAggregateRoute() = runTest {
        val (browse, _) = browse()
        server.handler = {
            FakeResponse(200, """{"Genres":["Drama","Action"],"OfficialRatings":["PG-13"],"Tags":["Holiday"],"Years":[1999,2024]}""")
        }

        val result = browse.fetchLibraryFiltersWithValues("lib-1")
        val music = browse.fetchLibraryFiltersWithValues("lib-1", libraryKind = MediaKind.ARTIST)

        val req = server.requests.first()
        assertEquals("/Items/Filters", req.path)
        assertEquals(mapOf("userId" to "user-1", "ParentId" to "lib-1"), req.query)
        assertEquals(listOf("unwatched", "favorite", "genre", "year", "contentRating", "tag"), result.filters.map { it.filter })
        assertEquals(listOf("jellyfin:unwatched", "jellyfin:favorite", "jellyfin:genre", "jellyfin:year", "jellyfin:contentRating", "jellyfin:tag"), result.filters.map { it.key })
        assertEquals(listOf("boolean", "boolean", "tag", "integer", "tag", "tag"), result.filters.map { it.filterType })
        assertEquals("Unwatched", result.filters[0].title)
        assertEquals("Unplayed", music.filters[0].title)
        assertEquals("Favorites", result.filters[1].title)
        assertTrue(result.filters[0].supportsExclusion)
        assertTrue(result.filters.drop(1).none { it.supportsExclusion })
        assertFalse("unwatched" in result.cachedValues)
        assertEquals(listOf("Action", "Drama"), result.cachedValues.getValue("genre").map { it.key })
        assertEquals(listOf("2024", "1999"), result.cachedValues.getValue("year").map { it.key })
    }

    @Test
    fun anEmptyFacetIsLeftOut() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(200, """{"Genres":["Drama"],"OfficialRatings":[],"Tags":[""],"Years":[]}""") }

        val result = browse.fetchLibraryFiltersWithValues("lib-1")

        assertEquals(listOf("unwatched", "favorite", "genre"), result.filters.map { it.filter })
    }

    @Test
    fun jellyfinUnreachableFiltersLeaveOnlyTheSyntheticBooleans() = runTest {
        val (browse, _) = browse()
        server.handler = { throw IOException("connection reset") }

        val result = browse.fetchLibraryFiltersWithValues("lib-1")

        assertEquals(listOf("unwatched", "favorite"), result.filters.map { it.filter })
        assertTrue(result.cachedValues.isEmpty())
    }

    @Test
    fun jellyfinFilterServerErrorThrows() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(500, "{}") }

        val error = assertFailsWith<MediaServerHttpException> { browse.fetchLibraryFiltersWithValues("lib-1") }
        assertEquals(500, error.statusCode)
    }

    @Test
    fun embyReassemblesTheFourFacetsFromItsPerFacetRoutes() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        server.handler = { req ->
            val names = when (req.path) {
                "/Genres" -> listOf("Drama", "Action")
                "/OfficialRatings" -> listOf("R", "PG-13")
                "/Tags" -> listOf("Holiday", "Archive")
                "/Years" -> listOf("1999", "2024", "2010")
                else -> emptyList()
            }
            page(names.map { """{"Name":"$it"}""" }, total = names.size)
        }

        val result = browse.fetchLibraryFiltersWithValues("lib-1", MediaKind.MOVIE)

        assertEquals(setOf("/Genres", "/OfficialRatings", "/Tags", "/Years"), server.requests.map { it.path }.toSet())
        assertEquals(4, server.requests.size)
        for (req in server.requests) {
            assertEquals("GET", req.method)
            assertEquals(mapOf("UserId" to "user-1", "ParentId" to "lib-1", "Recursive" to "true"), req.query)
        }
        assertEquals(listOf("Action", "Drama"), result.cachedValues.getValue("genre").map { it.key })
        assertEquals(listOf("PG-13", "R"), result.cachedValues.getValue("contentRating").map { it.key })
        assertEquals(listOf("Archive", "Holiday"), result.cachedValues.getValue("tag").map { it.key })
        assertEquals(listOf("2024", "2010", "1999"), result.cachedValues.getValue("year").map { it.key })
    }

    @Test
    fun embyKeepsTheFacetsThatAnsweredWhenOneIsUnreachable() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        server.handler = { req ->
            if (req.path == "/Tags") throw IOException("connection reset")
            val name = when (req.path) {
                "/Genres" -> "Action"
                "/OfficialRatings" -> "PG"
                else -> "2024"
            }
            page(listOf("""{"Name":"$name"}"""), total = 1)
        }

        val result = browse.fetchLibraryFiltersWithValues("lib-1", MediaKind.MOVIE)

        assertEquals(listOf("Action"), result.cachedValues.getValue("genre").map { it.key })
        assertEquals(listOf("PG"), result.cachedValues.getValue("contentRating").map { it.key })
        assertEquals(listOf("2024"), result.cachedValues.getValue("year").map { it.key })
        assertNull(result.cachedValues["tag"])
    }

    @Test
    fun embySurfacesAFacetServerError() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        server.handler = { req -> if (req.path == "/Tags") FakeResponse(500, """{"Error":"tags failed"}""") else page(listOf("""{"Name":"Action"}"""), total = 1) }

        val error = assertFailsWith<MediaServerHttpException> { browse.fetchLibraryFiltersWithValues("lib-1", MediaKind.MOVIE) }
        assertEquals(500, error.statusCode)
    }

    @Test
    fun fetchSortOptionsListsTheFixedSetAndShowFieldsOnlyForShows() = runTest {
        val (browse, _) = browse()
        val base = listOf(
            "title", "rating", "criticRating", "addedAt", "lastViewedAt", "viewCount", "productionYear", "runtime",
            "officialRating", "originallyAvailableAt", "studio", "random",
        )

        val sorts = browse.fetchSortOptions("lib-1")
        assertEquals(base, sorts.map { it.key })
        assertEquals("title:desc", sorts.first().descKey)
        assertEquals("asc", sorts.first().defaultDirection)
        assertEquals("desc", sorts[1].defaultDirection)
        assertNull(sorts.last().descKey)
        val show = base.take(4) + "episode.addedAt" + base.drop(4).dropLast(2) + "airTime" + base.takeLast(2)
        assertEquals(show, browse.fetchSortOptions("lib-1", "show").map { it.key })
        for (type in listOf("movie", "homevideos", "music")) assertEquals(base, browse.fetchSortOptions("lib-1", type).map { it.key }, type)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun titleIsTheUnsortedOrderOnlyWhereTheServerListsByName() = runTest {
        val (browse, _) = browse()
        for (type in listOf("movie", "show", "artist", "album", "track", "clip")) {
            val sorts = browse.fetchSortOptions("lib-1", type)
            assertEquals(listOf("title" to "asc"), sorts.filter { it.unsortedDirection != null }.map { it.key to it.unsortedDirection }, type)
        }
        for (type in listOf(null, "unknown", "photo")) {
            assertTrue(browse.fetchSortOptions("lib-1", type).all { it.unsortedDirection == null }, "$type")
        }
    }

    @Test
    fun genresAreScopedToTheBrowseTypeAndSelectByName() = runTest {
        val (browse, _) = browse()
        server.handler = {
            page(listOf("""{"Id":"genre-1","Name":"Action","ImageTags":{"Primary":"tag 1"}}""", """{"Id":"genre-2","Name":"Drama","ImageTags":{}}"""))
        }

        val genres = browse.fetchLibraryGenres("lib-1", MediaKind.SHOW)

        val req = server.requests.single()
        assertEquals("/Genres", req.path)
        assertEquals(
            mapOf(
                "UserId" to "user-1",
                "ParentId" to "lib-1",
                "Recursive" to "true",
                "IncludeItemTypes" to "Series",
                "SortBy" to "SortName",
                "EnableImageTypes" to "Primary",
                "ImageTypeLimit" to "1",
                "EnableTotalRecordCount" to "false",
            ),
            req.query,
        )
        assertEquals(listOf("Action" to "Action", "Drama" to "Drama"), genres.map { it.title to it.filterValue })
        assertEquals("/Items/genre-1/Images/Primary?tag=tag%201", genres.first().artPath)
        assertNull(genres.last().artPath)
    }

    @Test
    fun refreshAndScanPostTheirRefreshModes() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(204, "") }

        browse.refreshLibraryMetadata("lib 1")
        browse.scanLibrary("lib 1")

        val (refresh, scan) = server.requests
        for (req in server.requests) {
            assertEquals("POST", req.method)
            assertEquals("/Items/lib%201/Refresh", req.path)
        }
        assertEquals(
            mapOf("metadataRefreshMode" to "FullRefresh", "imageRefreshMode" to "Default", "replaceAllMetadata" to "false", "replaceAllImages" to "false"),
            refresh.query,
        )
        assertEquals(
            mapOf(
                "Recursive" to "true",
                "metadataRefreshMode" to "Default",
                "imageRefreshMode" to "Default",
                "replaceAllMetadata" to "false",
                "replaceAllImages" to "false",
            ),
            scan.query,
        )
    }

    @Test
    fun aRejectedRefreshThrows() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(403, "") }

        assertEquals(403, assertFailsWith<MediaServerHttpException> { browse.scanLibrary("lib-1") }.statusCode)
    }

    // Folders.

    @Test
    fun fetchLibraryFoldersSplitsFolderAndMediaQueriesAndOrdersFoldersFirst() = runTest {
        val (browse, core) = browse()
        val all = listOf(
            """{"Id":"track-z","Type":"Audio","Name":"Z Track","IsFolder":false}""" to false,
            """{"Id":"series-a","Type":"Series","Name":"A Show","IsFolder":true}""" to false,
            """{"Id":"folder-z","Type":"Folder","Name":"Z Folder","IsFolder":true}""" to true,
            """{"Id":"movie-m","Type":"Movie","Name":"Movie","IsFolder":false}""" to false,
        )
        server.handler = { req ->
            val foldersOnly = req.query["IncludeItemTypes"] == "Folder,CollectionFolder"
            val matching = all.filter { it.second == foldersOnly }.map { it.first }
            page(matching, total = matching.size)
        }

        val items = browse.fetchLibraryFolders("lib-1")

        assertEquals(2, server.requests.size)
        val folderQuery = server.requests.single { "IncludeItemTypes" in it.query }.query
        val mediaQuery = server.requests.single { "ExcludeItemTypes" in it.query }.query
        for (q in listOf(folderQuery, mediaQuery)) {
            assertEquals("lib-1", q["ParentId"])
            assertEquals("false", q["Recursive"])
            assertEquals("true", q["EnableTotalRecordCount"])
            assertEquals("SortName", q["SortBy"])
            assertEquals("Ascending", q["SortOrder"])
            assertEquals("500", q["Limit"])
        }
        assertEquals("SortName", folderQuery["Fields"])
        assertEquals("false", folderQuery["EnableUserData"])
        assertEquals("Folder,CollectionFolder", mediaQuery["ExcludeItemTypes"])
        assertEquals("UserData,PremiereDate,OriginalTitle,SortName,CanDelete", mediaQuery["Fields"])
        assertEquals(listOf("folder-z", "series-a", "movie-m", "track-z"), items.map { it.id })
        assertEquals(MediaKind.FOLDER, items.first().kind)
        assertEquals(MediaKind.SHOW, items[1].kind)

        val cached = assertNotNull(server.store.get(core.cacheServerId, "/Items?ParentId=lib-1&Recursive=false&userId=user-1"))
        assertEquals(4, cached.int("TotalRecordCount"))
        core.offlineMode = true
        server.requests.clear()
        assertEquals(items.map { it.id }, browse.fetchLibraryFolders("lib-1").map { it.id })
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun fetchFolderChildrenPagesDirectContentsAndEmitsIntermediatePages() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            if ("IncludeItemTypes" in req.query) {
                empty
            } else {
                val start = req.query.getValue("StartIndex").toInt()
                page(rows("child", "Movie", start until if (start == 0) 500 else 501), total = 501)
            }
        }
        val pages = mutableListOf<List<MediaItem>>()

        val items = browse.fetchFolderChildren(item("folder-1", MediaKind.FOLDER), onPage = { pages += it })

        assertEquals(listOf("0", "500"), server.requests.filter { "ExcludeItemTypes" in it.query }.map { it.query["StartIndex"] })
        assertEquals(501, items.size)
        assertEquals(1, pages.size)
        assertEquals(500, pages.single().size)
        assertEquals("child-0", pages.single().first().id)
    }

    @Test
    fun fetchFolderChildrenExpandsShowsAndSeasonsThroughChildren() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            if (req.path.startsWith("/Shows/")) {
                notFound
            } else {
                val start = req.query.getValue("StartIndex").toInt()
                page(rows("ep", "Episode", start until if (start == 0) 500 else 501), total = 501)
            }
        }
        val pages = mutableListOf<List<MediaItem>>()

        val items = browse.fetchFolderChildren(item("season-1", MediaKind.SEASON), onPage = { pages += it })

        assertEquals("/Shows/season-1/Seasons", server.requests.first().path)
        assertEquals(listOf("0", "500"), server.requests.filter { it.path == "/Items" }.map { it.query["StartIndex"] })
        assertEquals(501, items.size)
        assertEquals(500, pages.single().size)
        assertEquals("ep-0", pages.single().first().id)
    }

    // Item detail.

    @Test
    fun concurrentFetchItemCallsForOneIdShareOneRequest() = runTest {
        val (browse, _) = browse()
        val gate = CompletableDeferred<Unit>()
        server.handler = { req ->
            gate.await()
            FakeResponse(200, """{"Id":"${req.path.substringAfterLast('/')}","Name":"Item","Type":"Movie"}""")
        }
        val calls = listOf(async { browse.fetchItem("item-1") }, async { browse.fetchItem("item-1") })
        runCurrent()
        gate.complete(Unit)

        assertEquals(listOf("item-1", "item-1"), calls.awaitAll().map { it?.id })
        assertEquals(1, server.requests.size)

        browse.fetchItem("item-2")
        browse.fetchItem("item-1")
        assertEquals(2, server.requests.count { it.path == "/Users/user-1/Items/item-1" })
    }

    @Test
    fun fetchItemRequestsDetailFieldsAndCachesTheRow() = runTest {
        val (browse, core) = browse()
        server.handler = { FakeResponse(200, """{"Id":"item/1","Name":"Item","Type":"Movie"}""") }

        val result = browse.fetchItem("item/1")

        assertEquals("item/1", result?.id)
        val req = server.requests.single()
        assertEquals("/Users/user-1/Items/item%2F1", req.path)
        assertEquals(mapOf("Fields" to JellyfinCore.DETAIL_FIELDS), req.query)
        assertNotNull(server.store.get(core.cacheServerId, "/Users/user-1/Items/item%2F1"))
    }

    @Test
    fun fetchItemFailureModes() = runTest {
        val (browse, _) = browse()
        server.handler = { notFound }
        assertNull(browse.fetchItem("missing"))

        for (status in listOf(401, 403, 500)) {
            server.handler = { FakeResponse(status, "nope") }
            assertEquals(status, assertFailsWith<MediaServerHttpException> { browse.fetchItem("any") }.statusCode)
        }

        server.handler = { FakeResponse(200, "<html>oops</html>") }
        assertNull(browse.fetchItem("any"))
        server.handler = { FakeResponse(200, "") }
        assertNull(browse.fetchItem("any"))
        server.handler = { FakeResponse(200, "[]") }
        assertNull(browse.fetchItem("any"))
    }

    @Test
    fun aTransportFailureAnswersTheCachedRowButAnAnsweredErrorDoesNot() = runTest {
        val (browse, core) = browse()
        server.store.put(core.cacheServerId, "/Users/user-1/Items/item-1", kotlinx.serialization.json.Json.parseToJsonElement("""{"Id":"item-1","Type":"Movie","Name":"Cached"}""") as kotlinx.serialization.json.JsonObject)

        server.handler = { throw IOException("connection reset") }
        assertEquals("Cached", browse.fetchItem("item-1")?.title)

        server.handler = { FakeResponse(500, "boom") }
        assertEquals(500, assertFailsWith<MediaServerHttpException> { browse.fetchItem("item-1") }.statusCode)

        server.handler = { throw IOException("connection reset") }
        val error = assertFailsWith<MediaServerHttpException> { browse.fetchItem("uncached") }
        assertEquals(MediaServerHttpErrorType.CONNECTION_ERROR, error.type)
    }

    @Test
    fun offlineFetchItemReadsTheCacheOnly() = runTest {
        val (browse, core) = browse()
        server.handler = { FakeResponse(200, """{"Id":"item-1","Type":"Movie","Name":"Online"}""") }
        browse.fetchItem("item-1")
        server.requests.clear()
        core.offlineMode = true

        assertEquals("Online", browse.fetchItem("item-1")?.title)
        assertNull(browse.fetchItem("never-fetched"))
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun fetchItemFreshCacheFirstServesAFreshRowAndRefetchesAStaleOne() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(200, """{"Id":"item-1","Type":"Movie","Name":"Item"}""") }
        server.store.now = { 0L }
        browse.fetchItem("item-1")

        server.store.now = { 5 * 60_000L }
        assertEquals("item-1", browse.fetchItemFreshCacheFirst("item-1")?.id)
        assertEquals(1, server.requests.size)

        server.store.now = { 5 * 60_000L + 1 }
        assertEquals("item-1", browse.fetchItemFreshCacheFirst("item-1")?.id)
        assertEquals(2, server.requests.size)
        browse.fetchItemFreshCacheFirst("uncached")
        assertEquals("/Users/user-1/Items/uncached", server.requests.last().path)
    }

    // Item with on-deck.

    private fun detailServer(
        ancestors: FakeResponse? = null,
        nextUp: FakeResponse? = null,
        resume: FakeResponse? = null,
        item: String = """{"Id":"show-1","Type":"Series","Name":"Show 1"}""",
    ) {
        server.handler = { req ->
            when {
                req.path.endsWith("/Resume") -> resume ?: empty
                req.path.startsWith("/Users/user-1/Items/") -> FakeResponse(200, item)
                req.path.endsWith("/Ancestors") -> ancestors ?: notFound
                req.path == "/Shows/NextUp" -> nextUp ?: notFound
                else -> notFound
            }
        }
    }

    private fun episode(id: String, positionSeconds: Int) =
        """{"Id":"$id","Type":"Episode","Name":"$id","UserData":{"PlaybackPositionTicks":${positionSeconds * 10_000_000L}}}"""

    @Test
    fun fetchItemWithOnDeckChainsNextUpForAShow() = runTest {
        val (browse, _) = browse()
        detailServer(
            ancestors = FakeResponse(200, """[{"Id":"lib-shows","Type":"CollectionFolder","Name":"Shows"}]"""),
            nextUp = page(listOf("""{"Id":"ep-9","Type":"Episode","Name":"Next Episode"}""")),
        )

        val result = browse.fetchItemWithOnDeck("show-1")

        assertEquals(
            listOf("/Users/user-1/Items/show-1", "/Items/show-1/Ancestors", "/UserItems/Resume", "/Shows/NextUp"),
            server.requests.map { it.path },
        )
        assertEquals(mapOf("userId" to "user-1"), server.requests[1].query)
        assertEquals("show-1", server.requests[2].query["ParentId"])
        assertEquals("Episode", server.requests[2].query["IncludeItemTypes"])
        assertEquals("true", server.requests[2].query["Recursive"])
        assertEquals(
            mapOf(
                "seriesId" to "show-1",
                "userId" to "user-1",
                "Limit" to "1",
                "Fields" to JellyfinCore.EPISODE_ROW_FIELDS,
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.requests[3].query,
        )
        assertEquals("lib-shows", result.item?.libraryId)
        assertEquals("Shows", result.item?.libraryTitle)
        assertEquals("ep-9", result.onDeckEpisode?.id)
    }

    @Test
    fun theEpisodeInProgressPlayedLastIsOnDeckBeforeNextUp() = runTest {
        // Episode 1 played, Episode 2 left in progress, Episode 3 played: Next Up names the episode after Episode 3.
        val (browse, _) = browse()
        detailServer(
            resume = page(listOf(episode("ep-2", 70), episode("ep-1", 30))),
            nextUp = page(listOf(episode("ep-4", 0))),
        )

        val result = browse.fetchItemWithOnDeck("show-1")

        assertEquals("ep-2", result.onDeckEpisode?.id)
        assertEquals(70_000L, result.onDeckEpisode?.viewOffsetMs)
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
    }

    @Test
    fun embyResumeRowsAtPositionZeroLeaveOnDeckToNextUp() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        detailServer(resume = page(listOf(episode("ep-4", 0))), nextUp = page(listOf(episode("ep-3", 0))))

        val result = browse.fetchItemWithOnDeck("show-1")

        assertEquals("/Users/user-1/Items/Resume", server.requests.single { it.path.endsWith("/Resume") }.path)
        assertEquals("ep-3", result.onDeckEpisode?.id)
    }

    @Test
    fun nextUpAsksForRewatchingWhenTheAccountEnablesIt() = runTest {
        val (browse, core) = browse()
        core.rewatchingInNextUp = true
        detailServer()

        browse.fetchItemWithOnDeck("show-1")

        assertEquals("true", server.requests.single { it.path == "/Shows/NextUp" }.query["EnableRewatching"])
    }

    @Test
    fun aFailedNextUpLeavesNoOnDeckEpisode() = runTest {
        val (browse, _) = browse()
        detailServer(nextUp = FakeResponse(500, "boom"))

        val result = browse.fetchItemWithOnDeck("show-1")

        assertEquals("show-1", result.item?.id)
        assertNull(result.onDeckEpisode)
    }

    @Test
    fun fetchItemWithOnDeckStampsTheFirstCollectionFolderAncestor() = runTest {
        val (browse, _) = browse()
        detailServer(
            item = """{"Id":"movie-1","Type":"Movie","Name":"Movie 1"}""",
            ancestors = FakeResponse(
                200,
                """[{"Id":"folder-1","Type":"Folder","Name":"disk-1"},{"Id":"lib-movies","Type":"CollectionFolder","Name":"Movies"},{"Id":"root","Type":"AggregateFolder","Name":"Media Folders"}]""",
            ),
        )

        val result = browse.fetchItemWithOnDeck("movie-1")

        assertEquals("lib-movies", result.item?.libraryId)
        assertEquals("Movies", result.item?.libraryTitle)
        assertNull(result.onDeckEpisode)
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
    }

    @Test
    fun anAncestorsFailureOrNoCollectionFolderLeavesTheItemUnstamped() = runTest {
        val (browse, _) = browse()
        for (ancestors in listOf(FakeResponse(500, "boom"), FakeResponse(200, """[{"Id":"playlist-root","Type":"Folder","Name":"Playlists"}]"""))) {
            detailServer(item = """{"Id":"movie-1","Type":"Movie","Name":"Movie 1"}""", ancestors = ancestors)
            val result = browse.fetchItemWithOnDeck("movie-1")
            assertEquals("movie-1", result.item?.id)
            assertNull(result.item?.libraryId)
            assertNull(result.item?.libraryTitle)
        }
    }

    @Test
    fun theAncestorsAreAskedForAlongsideTheItemWhichIsHandedOverUnstamped() = runTest {
        val (browse, _) = browse()
        val itemGate = CompletableDeferred<Unit>()
        val ancestorsGate = CompletableDeferred<Unit>()
        server.handler = { req ->
            if (req.path.endsWith("/Ancestors")) {
                ancestorsGate.await()
                FakeResponse(200, """[{"Id":"lib-movies","Type":"CollectionFolder","Name":"Movies"}]""")
            } else {
                itemGate.await()
                FakeResponse(200, """{"Id":"movie-1","Type":"Movie","Name":"Movie 1"}""")
            }
        }
        var early: MediaItem? = null

        val call = async { browse.fetchItemWithOnDeck("movie-1", onItemReady = { early = it }) }
        runCurrent()
        assertEquals(setOf("/Users/user-1/Items/movie-1", "/Items/movie-1/Ancestors"), server.requests.map { it.path }.toSet())
        itemGate.complete(Unit)
        runCurrent()

        assertEquals("movie-1", early?.id)
        assertNull(early?.libraryId)
        assertFalse(call.isCompleted)
        ancestorsGate.complete(Unit)
        assertEquals("lib-movies", call.await().item?.libraryId)
    }

    /** A browse whose cache writes each wait for [beforeWrite] before reaching the server's store. */
    private fun browseWritingAfter(beforeWrite: suspend () -> Unit): Pair<JellyfinBrowse, JellyfinCore> {
        val store = object : ApiCacheStore by server.store {
            override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
                beforeWrite()
                server.store.put(cacheServerId, endpoint, data)
            }
        }
        val core = JellyfinCore(server.connection(), server.http, JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", "dev-1"), store = store)
        return JellyfinBrowse(core) { ordering } to core
    }

    @Test
    fun theItemIsHandedOverBeforeItsCacheRowIsWrittenAndTheCallEndsWithItWritten() = runTest {
        val writeGate = CompletableDeferred<Unit>()
        val (browse, core) = browseWritingAfter { writeGate.await() }
        detailServer(item = """{"Id":"movie-1","Type":"Movie","Name":"Movie 1"}""")
        var early: MediaItem? = null

        val call = async { browse.fetchItemWithOnDeck("movie-1", onItemReady = { early = it }) }
        runCurrent()

        assertEquals("movie-1", early?.id)
        assertFalse(call.isCompleted)
        writeGate.complete(Unit)
        call.await()
        core.offlineMode = true
        assertEquals("Movie 1", browse.fetchItem("movie-1")?.title)
    }

    @Test
    fun anEarlierAnswersCacheRowNeverOverwritesALaterOnes() = runTest {
        val firstWrite = CompletableDeferred<Unit>()
        var writes = 0
        val (browse, core) = browseWritingAfter { if (writes++ == 0) firstWrite.await() }
        var name = "Old"
        server.handler = { req ->
            if (req.path.endsWith("/Ancestors")) notFound else FakeResponse(200, """{"Id":"movie-1","Type":"Movie","Name":"$name"}""")
        }

        val first = async { browse.fetchItemWithOnDeck("movie-1") }
        runCurrent()
        name = "New"
        val second = async { browse.fetchItemWithOnDeck("movie-1") }
        runCurrent()
        firstWrite.complete(Unit)
        awaitAll(first, second)

        core.offlineMode = true
        assertEquals("New", browse.fetchItem("movie-1")?.title)
    }

    @Test
    fun aMissingItemShortCircuitsWithoutItsOnDeckEpisode() = runTest {
        val (browse, _) = browse()
        server.handler = { notFound }
        var ready = false

        val result = browse.fetchItemWithOnDeck("gone-1", onItemReady = { ready = true })

        assertNull(result.item)
        assertNull(result.onDeckEpisode)
        assertFalse(ready)
        assertTrue(server.requests.none { it.path.endsWith("/Resume") || it.path == "/Shows/NextUp" })
    }

    @Test
    fun stampLibraryReadsTheAncestors() = runTest {
        val (browse, _) = browse()
        detailServer(ancestors = FakeResponse(200, """[{"Id":"lib-movies","Type":"CollectionFolder","Name":"Movies"}]"""))

        val stamped = browse.stampLibrary(item("movie 1", MediaKind.MOVIE))

        assertEquals("/Items/movie%201/Ancestors", server.requests.single().path)
        assertEquals("lib-movies", stamped.libraryId)
        assertEquals("Movies", stamped.libraryTitle)
    }

    // Children.

    @Test
    fun fetchChildrenReturnsAndCachesASeriesSeasons() = runTest {
        val (browse, core) = browse()
        server.handler = { req ->
            if (req.path == "/Shows/show-1/Seasons") page(listOf("""{"Id":"season-1","Type":"Season","Name":"Season 1","IndexNumber":1}""")) else notFound
        }

        val seasons = browse.fetchChildren("show-1")

        assertEquals(listOf("season-1"), seasons.map { it.id })
        val req = server.requests.single()
        assertEquals(
            mapOf("userId" to "user-1", "Fields" to JellyfinCore.BROWSE_FIELDS, "EnableImageTypes" to "Primary,Backdrop,Logo", "ImageTypeLimit" to "3"),
            req.query,
        )
        assertNotNull(server.store.get(core.cacheServerId, "/Shows/show-1/Seasons?userId=user-1"))

        core.offlineMode = true
        server.requests.clear()
        assertEquals(listOf("season-1"), browse.fetchChildren("show-1").map { it.id })
        assertEquals(1, browse.fetchChildrenPage("show-1").totalCount)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun fetchChildrenWalksDirectChildrenPagesInEpisodeOrderAndCachesThem() = runTest {
        val (browse, core) = browse()
        server.handler = { req ->
            if (req.path == "/Shows/season-1/Seasons") {
                page(emptyList())
            } else {
                val start = req.query.getValue("StartIndex").toInt()
                page(rows("episode", "Episode", start until start + if (start == 0) 500 else 1), total = 501)
            }
        }

        val items = browse.fetchChildren("season-1")

        assertEquals(501, items.size)
        val itemRequests = server.requests.filter { it.path == "/Items" }
        assertEquals(listOf("0", "500"), itemRequests.map { it.query["StartIndex"] })
        for (req in itemRequests) {
            assertEquals("500", req.query["Limit"])
            assertEquals("season-1", req.query["ParentId"])
            assertTrue("MediaSources" in fields(req))
            assertEquals("ParentIndexNumber,IndexNumber,SortName", req.query["SortBy"])
            assertEquals("Ascending,Ascending,Ascending", req.query["SortOrder"])
        }
        val cached = assertNotNull(server.store.get(core.cacheServerId, "/Items?ParentId=season-1&userId=user-1"))
        assertEquals(501, cached.int("TotalRecordCount"))

        core.offlineMode = true
        val offlinePage = browse.fetchChildrenPage("season-1", start = 500, size = 10)
        assertEquals(listOf("episode-500"), offlinePage.items.map { it.id })
        assertEquals(501, offlinePage.totalCount)
        assertEquals(500, offlinePage.offset)
    }

    @Test
    fun anySeasonsFailureFallsThroughToItemsWhoseFailurePropagates() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(500, "boom") }

        assertFailsWith<MediaServerHttpException> { browse.fetchChildren("parent") }
        assertEquals(listOf("/Shows/parent/Seasons", "/Items"), server.requests.map { it.path })
    }

    @Test
    fun aSeasons404FallsThroughToItems() = runTest {
        val (browse, _) = browse()
        server.handler = { req -> if (req.path.endsWith("/Seasons")) notFound else page(emptyList()) }

        assertTrue(browse.fetchChildren("parent").isEmpty())
        assertEquals("/Items", server.requests.last().path)
    }

    @Test
    fun offlineChildrenWithoutACachedListAreEmpty() = runTest {
        val (browse, core) = browse()
        core.offlineMode = true

        assertTrue(browse.fetchChildren("parent").isEmpty())
        assertEquals(0, browse.fetchChildrenPage("parent").totalCount)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun childAndQueueRoutesPathEncodeReservedIds() = runTest {
        val (browse, _) = browse()
        server.handler = { page(emptyList()) }

        browse.fetchChildren("folder/show #1?x")
        browse.fetchClientSideEpisodeQueue("folder/show #1?x")

        val paths = server.requests.map { it.path }
        assertTrue("/Shows/folder%2Fshow%20%231%3Fx/Seasons" in paths)
        assertTrue("/Shows/folder%2Fshow%20%231%3Fx/Episodes" in paths)
        assertEquals("folder/show #1?x", server.requests.first { it.path == "/Items" }.query["ParentId"])
    }

    @Test
    fun fetchChildrenPageTriesSeasonsThenOrdersDirectEpisodeChildren() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            if (req.path == "/Shows/season-1/Seasons") page(emptyList()) else page(listOf("""{"Id":"episode-1","Name":"Episode","Type":"Episode"}"""), total = 40)
        }

        val result = browse.fetchChildrenPage("season-1", start = 20, size = 10)

        assertEquals("episode-1", result.items.single().id)
        assertEquals(40, result.totalCount)
        assertEquals(20, result.offset)
        val seasons = server.requests.first().query
        assertEquals("20", seasons["StartIndex"])
        assertEquals("10", seasons["Limit"])
        assertEquals("true", seasons["EnableTotalRecordCount"])
        val query = server.requests.single { it.path == "/Items" }.query
        assertEquals("season-1", query["ParentId"])
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertEquals("ParentIndexNumber,IndexNumber,SortName", query["SortBy"])
        assertEquals("Ascending,Ascending,Ascending", query["SortOrder"])
    }

    @Test
    fun fetchSeasonEpisodesPageUsesTheEpisodesRouteScopedToTheSeason() = runTest {
        val (browse, _) = browse()
        server.handler = { page(listOf("""{"Id":"episode-1","Name":"Episode","Type":"Episode"}"""), total = 40) }

        val result = browse.fetchSeasonEpisodesPage("show-1", "season-1", start = 20, size = 10)

        assertEquals("episode-1", result.items.single().id)
        assertEquals(40, result.totalCount)
        assertEquals(20, result.offset)
        val req = server.requests.single()
        assertEquals("/Shows/show-1/Episodes", req.path)
        assertEquals("season-1", req.query["SeasonId"])
        assertEquals("20", req.query["StartIndex"])
        assertEquals("10", req.query["Limit"])
        assertEquals("true", req.query["EnableTotalRecordCount"])
        assertEquals("false", req.query["IsMissing"])
        assertEquals("false", req.query["IsVirtualUnaired"])
        assertTrue("MediaSources" in fields(req))
        assertFalse("SortBy" in req.query)
        assertFalse("SortOrder" in req.query)
    }

    @Test
    fun embyEpisodeRowsCarryEveryMergedVersion() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        server.handler = { req ->
            if (req.path.endsWith("/Seasons")) {
                empty
            } else {
                val alternates = "AlternateMediaSources" in fields(req)
                val sources = listOfNotNull(
                    """{"Id":"mediasource_12","Name":"S01E01 [Teldrive]","MediaStreams":[]}""".takeIf { alternates },
                    """{"Id":"mediasource_9","Name":"S01E01 [DropBox]","MediaStreams":[]}""",
                )
                page(listOf("""{"Id":"9","Name":"S01E01","Type":"Episode","MediaSources":[${sources.joinToString(",")}]}"""), total = 1)
            }
        }

        val seasonPage = browse.fetchSeasonEpisodesPage("series-1", "season-1")
        val parentPage = browse.fetchChildrenPage("season-1")

        for (row in listOf(seasonPage.items.single(), parentPage.items.single())) {
            assertEquals(listOf("mediasource_12", "mediasource_9"), row.mediaVersions?.map { it.id })
        }
    }

    // Descendants.

    @Test
    fun fetchPlayableDescendantsPageUsesPageBoundsEpisodeRowFieldsAndHidesPlaceholders() = runTest {
        val (browse, _) = browse()
        server.handler = { page(listOf("""{"Id":"episode-1","Name":"Episode","Type":"Episode"}"""), total = 40) }

        val result = browse.fetchPlayableDescendantsPage("show-1", start = 20, size = 10)

        assertEquals("episode-1", result.items.single().id)
        assertEquals(40, result.totalCount)
        assertEquals(20, result.offset)
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "ParentId" to "show-1",
                "Recursive" to "true",
                "IncludeItemTypes" to "Movie,Episode,Audio",
                "StartIndex" to "20",
                "Limit" to "10",
                "Fields" to JellyfinCore.EPISODE_ROW_FIELDS,
                "ExcludeLocationTypes" to "Virtual",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.requests.single().query,
        )
    }

    @Test
    fun fetchPlayableDescendantsRetriesByAlbumArtistWhenTheFolderTreeIsEmpty() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            if ("AlbumArtistIds" in req.query) page(listOf("""{"Id":"track-1","Type":"Audio","Name":"Track"}"""), total = 1) else empty
        }

        val items = browse.fetchPlayableDescendants("artist-1")

        assertEquals(listOf("track-1"), items.map { it.id })
        val (first, retry) = server.requests.map { it.query }
        assertEquals("artist-1", first["ParentId"])
        assertEquals("Movie,Episode,Audio", first["IncludeItemTypes"])
        assertEquals("200", first["Limit"])
        assertEquals("artist-1", retry["AlbumArtistIds"])
        assertFalse("ParentId" in retry)
        assertEquals("Audio", retry["IncludeItemTypes"])
    }

    @Test
    fun fetchPlayableFolderDescendantsIncludesGenericVideoButNeverAudio() = runTest {
        val (browse, _) = browse()
        server.handler = { page(listOf("""{"Id":"video-1","Name":"Home Video","Type":"Video"}"""), total = 1) }

        val items = browse.fetchPlayableFolderDescendants("folder-1")

        assertEquals(MediaKind.CLIP, items.single().kind)
        val query = server.requests.single().query
        assertEquals("folder-1", query["ParentId"])
        assertEquals("true", query["Recursive"])
        assertEquals("Movie,Episode,Video,MusicVideo", query["IncludeItemTypes"])
    }

    @Test
    fun fetchRandomLibraryVideosIsOneRandomlySortedRequest() = runTest {
        val (browse, _) = browse()
        server.handler = { page(rows("video", "Video", 0 until 50), total = 900) }

        val items = browse.fetchRandomLibraryVideos("lib-1", limit = 50)

        assertEquals(50, items.size)
        val query = server.requests.single().query
        assertEquals("Random", query["SortBy"])
        assertEquals("0", query["StartIndex"])
        assertEquals("50", query["Limit"])
        assertEquals("Movie,Episode,Video,MusicVideo", query["IncludeItemTypes"])
    }

    @Test
    fun cancellingFetchPlayableDescendantsStopsBeforeASecondPage() = runTest {
        val (browse, _) = browse()
        lateinit var call: Deferred<List<MediaItem>>
        server.handler = {
            call.cancel()
            page(rows("movie", "Movie", 0 until 200), total = 201)
        }

        call = async { browse.fetchPlayableDescendants("collection-1") }

        assertFailsWith<CancellationException> { call.await() }
        assertEquals(listOf("0"), server.requests.map { it.query["StartIndex"] })
    }

    // Episode queue.

    @Test
    fun fetchClientSideEpisodeQueuePagesPastTheFirst200() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            val start = req.query.getValue("StartIndex").toInt()
            page(rows("ep", "Episode", start until minOf(start + 200, 250)), total = 250)
        }

        val result = browse.fetchClientSideEpisodeQueue("show-1")

        assertEquals(250, result?.size)
        assertEquals(listOf("0", "200"), server.requests.map { it.query["StartIndex"] })
        for (req in server.requests) {
            assertEquals("/Shows/show-1/Episodes", req.path)
            assertEquals("UserData,PremiereDate", req.query["Fields"])
            assertEquals("false", req.query["IsMissing"])
            assertEquals("false", req.query["IsVirtualUnaired"])
            // The server's own order, as its web client asks: Emby honours a SortBy over it.
            assertFalse("SortBy" in req.query)
            assertFalse("SortOrder" in req.query)
        }
    }

    @Test
    fun fetchClientSideEpisodeQueueOrdersPerTheSpecialsPreference() = runTest {
        val (browse, _) = browse()
        server.handler = {
            page(
                listOf(
                    """{"Id":"special","Type":"Episode","ParentIndexNumber":0,"IndexNumber":1,"PremiereDate":"2022-10-27T00:00:00Z","SeriesId":"show-1"}""",
                    """{"Id":"ep-1","Type":"Episode","ParentIndexNumber":1,"IndexNumber":1,"PremiereDate":"2022-10-05T00:00:00Z","SeriesId":"show-1"}""",
                    """{"Id":"ep-2","Type":"Episode","ParentIndexNumber":1,"IndexNumber":2,"PremiereDate":"2022-11-02T00:00:00Z","SeriesId":"show-1"}""",
                ),
                total = 3,
            )
        }

        ordering = SpecialsOrdering.RESPECT_SERVER
        assertEquals(listOf("special", "ep-1", "ep-2"), browse.fetchClientSideEpisodeQueue("show-1")?.map { it.id })
        ordering = SpecialsOrdering.AIR_DATE
        assertEquals(listOf("ep-1", "special", "ep-2"), browse.fetchClientSideEpisodeQueue("show-1")?.map { it.id })
        ordering = SpecialsOrdering.SPECIALS_LAST
        assertEquals(listOf("ep-1", "ep-2", "special"), browse.fetchClientSideEpisodeQueue("show-1")?.map { it.id })
    }

    @Test
    fun embyQueueFieldsDoNotDuplicatePremiereDate() = runTest {
        val (browse, _) = browse(MediaBrowserDialect.EMBY)
        server.handler = { empty }

        browse.fetchClientSideEpisodeQueue("series-1")

        val fields = fields(server.requests.last())
        assertEquals(1, fields.count { it == "PremiereDate" })
        assertTrue(fields.containsAll(listOf("UserData", "PremiereDate", "ProductionYear", "OfficialRating", "DateCreated")))
    }

    // Related items and people.

    @Test
    fun fetchRelatedHubsReadsSimilarIntoOneHub() = runTest {
        val (browse, _) = browse()
        server.handler = { page(listOf("""{"Id":"movie-2","Type":"Movie","Name":"Other"}""")) }

        val hubs = browse.fetchRelatedHubs("movie-1")

        val req = server.requests.single()
        assertEquals("/Items/movie-1/Similar", req.path)
        assertEquals(
            mapOf("userId" to "user-1", "Limit" to "10", "Fields" to JellyfinCore.BROWSE_FIELDS, "EnableImageTypes" to "Primary,Backdrop,Logo", "ImageTypeLimit" to "3"),
            req.query,
        )
        val hub = hubs.single()
        assertEquals("item.movie-1.similar", hub.id)
        assertEquals(T.discover.moreLikeThis, hub.title)
        assertEquals(listOf("movie-2"), hub.items.map { it.id })

        server.handler = { page(emptyList()) }
        assertTrue(browse.fetchRelatedHubs("movie-1", count = 5).isEmpty())
        assertEquals("5", server.requests.last().query["Limit"])
    }

    @Test
    fun fetchExtrasCombinesLocalTrailersAndSpecialFeaturesAsPlayableVideos() = runTest {
        val (browse, _) = browse()
        server.handler = { req ->
            when (req.path) {
                "/Items/movie%2Fid%20%231%3Fx/LocalTrailers" -> FakeResponse(
                    200,
                    """[{"Id":"trailer-1","Name":"Trailer","Type":"Trailer","ExtraType":"Trailer","RunTimeTicks":900000000,"ImageTags":{"Primary":"trailer-tag"}},
                       {"Id":"theme-song","Name":"Theme Song","Type":"Audio","ExtraType":"ThemeSong"}]""",
                )
                "/Items/movie%2Fid%20%231%3Fx/SpecialFeatures" -> FakeResponse(
                    200,
                    """[{"Id":"trailer-1","Name":"Trailer Duplicate","Type":"Trailer","ExtraType":"Trailer"},
                       {"Id":"featurette-1","Name":"Making Of","Type":"Video","ExtraType":"Featurette","RunTimeTicks":1800000000,"BackdropImageTags":["featurette-backdrop"]}]""",
                )
                else -> FakeResponse(500, "unexpected")
            }
        }

        val extras = browse.fetchExtras("movie/id #1?x")

        assertEquals(2, server.requests.size)
        for (req in server.requests) {
            assertEquals(mapOf("userId" to "user-1", "EnableImageTypes" to "Primary,Backdrop,Logo", "ImageTypeLimit" to "3"), req.query)
        }
        assertEquals(listOf("trailer-1", "featurette-1"), extras.map { it.id })
        assertTrue(extras.all { it.kind == MediaKind.CLIP && it.serverId == "machine-1" && it.serverName == "Home" })
        assertEquals("Trailer", extras[0].raw?.str("ExtraType"))
        assertEquals("Featurette", extras[1].raw?.str("ExtraType"))
    }

    @Test
    fun embyScopesTrailersAndSpecialFeaturesAndAFailedLegIsEmpty() = runTest {
        server.handler = { req -> if (req.path.endsWith("/LocalTrailers")) FakeResponse(500, "boom") else page(emptyList()) }

        assertTrue(browse(MediaBrowserDialect.EMBY).first.fetchExtras("item-1").isEmpty())
        assertTrue(browse().first.fetchExtras("item-1").isEmpty())

        assertEquals(
            setOf(
                "/Users/user-1/Items/item-1/LocalTrailers",
                "/Users/user-1/Items/item-1/SpecialFeatures",
                "/Items/item-1/LocalTrailers",
                "/Items/item-1/SpecialFeatures",
            ),
            server.requests.map { it.path }.toSet(),
        )
        assertTrue(server.requests.all { it.method == "GET" && it.body.isEmpty() })
    }

    @Test
    fun offlineExtrasAreEmptyWithoutARequest() = runTest {
        val (browse, core) = browse()
        core.offlineMode = true

        assertTrue(browse.fetchExtras("item-1").isEmpty())
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun fetchPersonMediaPageQueriesItemsByPerson() = runTest {
        val (browse, _) = browse()
        server.handler = { page(listOf("""{"Id":"movie-1","Name":"Movie","Type":"Movie"}"""), total = 40) }

        val result = browse.fetchPersonMediaPage("person-1", start = 20, size = 10)

        assertEquals("movie-1", result.items.single().id)
        assertEquals(40, result.totalCount)
        assertEquals(20, result.offset)
        val req = server.requests.single()
        assertEquals("/Items", req.path)
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "PersonIds" to "person-1",
                "IncludeItemTypes" to "Movie,Series",
                "Recursive" to "true",
                "StartIndex" to "20",
                "Limit" to "10",
                "Fields" to JellyfinCore.BROWSE_FIELDS,
                "SortBy" to "PremiereDate,ProductionYear,SortName",
                "SortOrder" to "Descending,Descending,Ascending",
                "CollapseBoxSetItems" to "false",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            req.query,
        )
        browse.fetchPersonMediaPage("person-1")
        assertEquals("200", server.requests.last().query["Limit"])
    }

    @Test
    fun fetchPersonDetailsMapsThePersonPageFields() = runTest {
        val (browse, _) = browse()
        server.handler = {
            FakeResponse(
                200,
                """{"Id":"person-1","Name":"Jeanette Nolan","Type":"Person","Overview":"Jeanette Nolan was an American actress.",
                   "PremiereDate":"1911-12-30T00:00:00.0000000Z","EndDate":"1998-06-05T00:00:00.0000000Z","ProductionLocations":["Los Angeles, California, USA"]}""",
            )
        }

        val details = browse.fetchPersonDetails("person-1")

        val req = server.requests.single()
        assertEquals("/Users/user-1/Items/person-1", req.path)
        assertEquals(mapOf("Fields" to "Overview,ProductionLocations"), req.query)
        assertEquals("Jeanette Nolan was an American actress.", details.biography)
        assertEquals(CalendarDate(1911, 12, 30), details.birthDate)
        assertEquals(CalendarDate(1998, 6, 5), details.deathDate)
        assertEquals("Los Angeles, California, USA", details.birthPlace)
        assertTrue(server.store.rows.isEmpty())
    }

    @Test
    fun fetchPersonDetailsLeavesOutWhatThePersonDoesNotFillIn() = runTest {
        val (browse, core) = browse()
        server.handler = { FakeResponse(200, """{"Id":"person-1","Name":"Tom Hanks","Type":"Person","Overview":"","ProductionLocations":[]}""") }

        assertTrue(browse.fetchPersonDetails("person-1").isEmpty)

        core.offlineMode = true
        assertTrue(browse.fetchPersonDetails("person-1").isEmpty)
        assertEquals(1, server.requests.size)
    }

    @Test
    fun deleteMediaItemDeletesTheItem() = runTest {
        val (browse, _) = browse()
        server.handler = { FakeResponse(204, "") }

        assertTrue(browse.deleteMediaItem(item("movie 1", MediaKind.MOVIE)))
        val req = server.requests.single()
        assertEquals("DELETE", req.method)
        assertEquals("/Items/movie%201", req.path)

        server.handler = { FakeResponse(500, "") }
        assertEquals(500, assertFailsWith<MediaServerHttpException> { browse.deleteMediaItem(item("movie-1", MediaKind.MOVIE)) }.statusCode)
    }
}
