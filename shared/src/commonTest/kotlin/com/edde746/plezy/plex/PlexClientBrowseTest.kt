package com.edde746.plezy.plex

import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.ServerId
import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexClientBrowseTest {
    private fun container(metadata: String, extra: String = "") = """{"MediaContainer":{$extra"Metadata":[$metadata]}}"""

    private fun movie(id: String, extra: String = "") = """{"ratingKey":"$id","type":"movie","title":"Movie $id"$extra}"""

    private fun pathClient(vararg routes: Pair<String, String>, record: MutableList<HttpRequestData>? = null) = testPlexClient({ request ->
        record?.add(request)
        val body = routes.toMap()[request.url.encodedPath]
        if (body == null) jsonResponse("not found", 404) else jsonResponse(body)
    })

    // Libraries.

    @Test
    fun `media providers yield libraries hub keys and EPG providers`() = runTest {
        val client = pathClient(
            "/media/providers" to """{"MediaContainer":{"MediaProvider":[
                {"identifier":"com.plexapp.plugins.library","Feature":[
                  {"type":"promoted","key":"/hubs/promoted"},
                  {"type":"continuewatching","key":"/hubs/continueWatching"},
                  {"type":"content","Directory":[
                    {"hubKey":"/hubs","title":"Home"},
                    {"id":"1","key":"/library/sections/1","type":"movie","title":"Movies"},
                    {"id":"shared","key":"/library/shared","type":"movie","title":"Shared"},
                    {"id":"weird","key":"/somewhere","type":"movie","title":"Skipped"},
                    {"id":"2","key":"/playlists","type":"playlist","title":"Playlists"}
                  ]}
                ]},
                {"identifier":"tv.plex.providers.epg.cloud:4","id":4,"protocols":"livetv","Feature":[{"type":"grid","key":"/tv.plex.providers.epg.cloud:4/grid"}]}
            ]}}""",
        )

        val providers = client.fetchMediaProviders()

        assertEquals(listOf("1", "shared"), providers.libraries.map { it.id })
        assertEquals(listOf(false, true), providers.libraries.map { it.isShared })
        assertEquals("/hubs", providers.homeHubKey)
        assertEquals("/hubs/promoted", providers.promotedHubKey)
        assertEquals("/hubs/continueWatching", providers.continueWatchingHubKey)
        assertEquals(listOf(PlexEpgProvider("tv.plex.providers.epg.cloud:4", "/tv.plex.providers.epg.cloud:4/grid", "4")), providers.epg)
        client.close()
    }

    @Test
    fun `libraries fall back to library sections without provider libraries`() = runTest {
        val client = pathClient("/library/sections" to """{"MediaContainer":{"Directory":[{"key":"3","type":"show","title":"TV"}]}}""")

        val libraries = client.fetchLibraries()

        assertEquals(listOf("3"), libraries.map { it.id })
        assertEquals(TEST_SERVER_ID, libraries.single().serverId)
        client.close()
    }

    @Test
    fun `library content stamps the known section when rows omit it`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = pathClient("/library/sections/7/all" to container(movie("42"), """"size":1,"totalSize":1,"""), record = requests)

        val page = client.fetchLibraryPagedContent("7", LibraryQuery(limit = 1))

        assertEquals("42", page.items.single().id)
        assertEquals("7", page.items.single().libraryId)
        assertEquals(1, page.totalCount)
        val params = requests.single().url.parameters
        assertEquals("1", params["includeCollections"])
        assertEquals("0", params["X-Plex-Container-Start"])
        assertEquals("1", params["X-Plex-Container-Size"])
        client.close()
    }

    @Test
    fun `the shared library reads the individually shared items`() = runTest {
        val client = pathClient("/library/shared/all" to container(movie("9"), """"totalSize":1,"""))

        val page = client.fetchLibraryPagedContent("shared", LibraryQuery())

        assertEquals("9", page.items.single().id)
        assertNull(page.items.single().libraryId)
        client.close()
    }

    @Test
    fun `the total size prefers the header then the body then exposes one possible next item`() = runTest {
        val tenMovies = (0 until 10).joinToString(",") { movie("$it") }
        val noTotal = pathClient("/library/sections/1/all" to container(tenMovies, """"size":10,"""))
        assertEquals(31, noTotal.fetchLibraryPagedContent("1", LibraryQuery(offset = 20, limit = 10)).totalCount)
        assertEquals(30, noTotal.fetchLibraryPagedContent("1", LibraryQuery(offset = 20, limit = 11)).totalCount)
        noTotal.close()

        val header = testPlexClient({ jsonResponse(container(movie("1"), """"size":1,"""), headers = mapOf("X-Plex-Container-Total-Size" to "50")) })
        val page = header.fetchLibraryPagedContent("1", LibraryQuery(offset = 20, limit = 10))
        assertEquals(50, page.totalCount)
        assertEquals(20, page.offset)
        header.close()
    }

    // Children and descendants.

    @Test
    fun `child metadata inherits the hoisted MediaContainer library section`() = runTest {
        val client = pathClient(
            "/library/metadata/show-1/children" to container(
                """{"ratingKey":"season-1","type":"season","title":"Season 1"}""",
                """"librarySectionID":"9","librarySectionTitle":"TV Shows",""",
            ),
        )

        val children = client.fetchChildren("show-1")

        assertEquals("9", children.single().libraryId)
        assertEquals("TV Shows", children.single().libraryTitle)
        client.close()
    }

    @Test
    fun `playable descendants page passes the requested pagination`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = pathClient(
            "/library/metadata/show-1/grandchildren" to container("""{"ratingKey":"ep-1","type":"episode","title":"Episode"}""", """"size":1,"totalSize":30,"""),
            record = requests,
        )

        val page = client.fetchPlayableDescendantsPage("show-1", 20, 10)

        assertEquals("ep-1", page.items.single().id)
        assertEquals(30, page.totalCount)
        assertEquals(20, page.offset)
        val params = requests.single().url.parameters
        assertEquals("20", params["X-Plex-Container-Start"])
        assertEquals("10", params["X-Plex-Container-Size"])
        assertEquals("1", params["includeStreams"])
        client.close()
    }

    @Test
    fun `the playable descendants of an album are its children of a show its grandchildren`() = runTest {
        val requests = mutableListOf<String>()
        val client = testPlexClient({ request ->
            requests += request.url.encodedPath
            when (request.url.encodedPath) {
                "/library/metadata/album-1" -> jsonResponse(container("""{"ratingKey":"album-1","type":"album","title":"Album"}"""))
                "/library/metadata/album-1/children" -> jsonResponse(container("""{"ratingKey":"t1","type":"track","title":"T"}""", """"totalSize":1,"""))
                "/library/metadata/show-1" -> jsonResponse(container("""{"ratingKey":"show-1","type":"show","title":"Show"}"""))
                "/library/metadata/show-1/grandchildren" -> jsonResponse(container("""{"ratingKey":"e1","type":"episode","title":"E"}""", """"totalSize":1,"""))
                else -> jsonResponse("not found", 404)
            }
        })

        assertEquals(listOf("t1"), client.fetchPlayableDescendants("album-1").map { it.id })
        assertEquals(listOf("e1"), client.fetchPlayableDescendants("show-1").map { it.id })
        assertTrue("/library/metadata/album-1/grandchildren" !in requests)
        client.close()
    }

    // Hubs.

    @Test
    fun `hub content infers the library section from a hubs sections key`() = runTest {
        val client = pathClient("/hubs/sections/7/recentlyAdded/items" to container(movie("42"), """"size":1,"""))

        val items = client.fetchMoreHubItems("/hubs/sections/7/recentlyAdded/items")

        assertEquals("42", items.single().id)
        assertEquals("7", items.single().libraryId)
        client.close()
    }

    @Test
    fun `collection hub View All stays under the server page size cap`() = runTest {
        val total = 250
        val sizes = mutableListOf<Int>()
        val client = testPlexClient({ request ->
            if (request.url.encodedPath != "/library/collections/99/children") return@testPlexClient jsonResponse("not found", 404)
            val start = request.url.parameters["X-Plex-Container-Start"]!!.toInt()
            val size = request.url.parameters["X-Plex-Container-Size"]!!.toInt()
            sizes += size
            if (size > 120) return@testPlexClient jsonResponse("X-Plex-Container-Size header exceeds limit 120", 400)
            val end = minOf(start + size, total)
            jsonResponse(container((start until end).joinToString(",") { movie("$it") }, """"offset":$start,"size":${end - start},"totalSize":$total,"""))
        })

        val page = client.fetchMoreHubItemsPage("/library/collections/99/children", 0, 200)
        assertEquals((0 until 200).map { "$it" }, page.items.map { it.id })

        val all = client.fetchMoreHubItems("/library/collections/99/children")
        assertEquals((0 until total).map { "$it" }, all.map { it.id })
        assertTrue(sizes.all { it <= 120 })
        client.close()
    }

    @Test
    fun `hub content pages by filtered video item offset`() = runTest {
        val starts = mutableListOf<String?>()
        val sizes = mutableListOf<String?>()
        val client = testPlexClient({ request ->
            val start = request.url.parameters["X-Plex-Container-Start"]
            starts += start
            sizes += request.url.parameters["X-Plex-Container-Size"]
            val metadata = if (start == "0") {
                """{"ratingKey":"collection-1","type":"collection","title":"Collection"},${movie("movie-1")}"""
            } else {
                """{"ratingKey":"episode-1","type":"episode","title":"Episode"}"""
            }
            jsonResponse(container(metadata, """"totalSize":3,"""))
        })

        val first = client.fetchMoreHubItemsPage("/hubs/sections/7/recent", 0, 1)
        val second = client.fetchMoreHubItemsPage("/hubs/sections/7/recent", 1, 1)

        assertEquals("movie-1", first.items.single().id)
        assertEquals(2, first.totalCount)
        assertEquals(0, first.offset)
        assertEquals("episode-1", second.items.single().id)
        assertEquals(2, second.totalCount)
        assertEquals(1, second.offset)
        assertEquals(listOf<String?>("0", "0", "2"), starts)
        assertTrue(sizes.all { it == "200" })
        client.close()
    }

    @Test
    fun `music hub content keeps the artists albums and tracks its preview row shows`() = runTest {
        val client = pathClient(
            "/hubs/sections/3/recentlyAdded" to container(
                """{"ratingKey":"artist-1","type":"artist","title":"Artist"},{"ratingKey":"album-1","type":"album","title":"Album"},{"ratingKey":"track-1","type":"track","title":"Track"}""",
                """"size":3,"totalSize":3,""",
            ),
        )

        val all = client.fetchMoreHubItems("/hubs/sections/3/recentlyAdded")
        val page = client.fetchMoreHubItemsPage("/hubs/sections/3/recentlyAdded", 0, 50)

        assertEquals(listOf("artist-1", "album-1", "track-1"), all.map { it.id })
        assertEquals(listOf("artist-1", "album-1", "track-1"), page.items.map { it.id })
        assertEquals(3, page.totalCount)
        client.close()
    }

    private val hubsBody = """{"MediaContainer":{"Hub":[
        {"key":"/hubs/a","title":"Movies","type":"movie","Metadata":[${movie("1")},{"ratingKey":"c","type":"collection","title":"C"}]},
        {"key":"/hubs/b","title":"Music","type":"artist","Metadata":[{"ratingKey":"ar","type":"artist","title":"Ar"}]},
        {"key":"/hubs/c","title":"Empty","type":"movie","Metadata":[]}
    ]}}"""

    @Test
    fun `library hubs keep video and music rows and are stamped with the section`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = pathClient("/hubs/sections/5" to hubsBody, record = requests)

        val hubs = client.fetchLibraryHubs("5", "Library", limit = 12)

        assertEquals(listOf("/hubs/a", "/hubs/b"), hubs.map { it.id })
        assertEquals(listOf("1"), hubs[0].items.map { it.id })
        assertEquals("5", hubs[0].items.single().libraryId)
        assertEquals("12", requests.single().url.parameters["count"])
        assertEquals("1", requests.single().url.parameters["includeGuids"])
        client.close()
    }

    @Test
    fun `global hubs keep video rows only`() = runTest {
        val client = pathClient("/hubs" to hubsBody)

        val hubs = client.fetchGlobalHubs()

        assertEquals(listOf("/hubs/a"), hubs.map { it.id })
        client.close()
    }

    @Test
    fun `related hubs keep video and collection rows`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = pathClient("/hubs/metadata/9/related" to hubsBody, record = requests)

        val hubs = client.fetchRelatedHubs("9")

        assertEquals(listOf("1", "c"), hubs.single().items.map { it.id })
        assertEquals("10", requests.single().url.parameters["count"])
        client.close()
    }

    @Test
    fun `a failed hub fetch is recorded and yields no hubs`() = runTest {
        val diagnostics = HubFetchDiagnostics()
        val client = testPlexClient({ jsonResponse("{}", 500) })

        assertTrue(client.fetchGlobalHubs(diagnostics = diagnostics).isEmpty())
        assertTrue(diagnostics.failed)
        assertFalse(diagnostics.cancelled)
        client.close()
    }

    @Test
    fun `continue watching collapses the episodes of a show prefers progress and backfills logos`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when (request.url.encodedPath) {
                "/hubs" -> jsonResponse(
                    """{"MediaContainer":{"Hub":[
                        {"key":"continue","title":"Continue","Metadata":[
                          {"ratingKey":"e1","type":"episode","title":"E1","grandparentRatingKey":"show"},
                          {"ratingKey":"m1","type":"movie","title":"M1","clearLogo":"/m1/logo"}
                        ]},
                        {"key":"ondeck","title":"On Deck","Metadata":[
                          {"ratingKey":"e2","type":"episode","title":"E2","grandparentRatingKey":"show","viewOffset":5000}
                        ]}
                    ]}}""",
                )
                "/library/metadata/show" -> jsonResponse(container("""{"ratingKey":"show","type":"show","Image":[{"type":"clearLogo","url":"/show/logo"}]}"""))
                else -> jsonResponse("not found", 404)
            }
        })

        val items = client.fetchContinueWatching(count = 20)

        assertEquals(listOf("e2", "m1"), items.map { it.id })
        assertEquals("/show/logo", items[0].clearLogoPath)
        val hubParams = requests.first().url.parameters
        assertEquals("home.continue,home.ondeck", hubParams["identifier"])
        assertEquals("20", hubParams["count"])
        assertEquals("1", hubParams["includeGuids"])
        client.close()
    }

    @Test
    fun `continue watching uses the advertised hub retries connection errors and never fails over`() = runTest {
        val primary = "https://plex.example.com"
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient(
            { request ->
                requests += request
                if (requests.size <= 2) throw IOException("connection reset")
                jsonResponse("""{"MediaContainer":{"Hub":[{"key":"c","title":"C","Metadata":[${movie("m1")}]}]}}""")
            },
            baseUrl = primary,
            prioritizedEndpoints = listOf(primary, "https://plex-fallback.example.com"),
        )
        client.providers = PlexMediaProviders(continueWatchingHubKey = "/hubs/continueWatching")

        val items = client.fetchContinueWatching(count = 21)

        assertEquals(listOf("m1"), items.map { it.id })
        assertEquals(listOf("plex.example.com"), requests.map { it.url.host }.distinct())
        assertEquals(List(3) { "/hubs/continueWatching" }, requests.map { it.url.encodedPath })
        val params = requests.last().url.parameters
        assertNull(params["identifier"])
        assertEquals("21", params["count"])
        assertEquals("1", params["includeGuids"])
        client.close()
    }

    @Test
    fun `a failed logo backfill leaves continue watching rows as they are`() = runTest {
        val client = testPlexClient({ request ->
            if (request.url.encodedPath == "/hubs") {
                jsonResponse("""{"MediaContainer":{"Hub":[{"key":"c","title":"C","Metadata":[{"ratingKey":"s1","type":"season","title":"S1","parentRatingKey":"show"}]}]}}""")
            } else {
                jsonResponse("{}", 500)
            }
        })

        val items = client.fetchContinueWatching()

        assertEquals(listOf("s1"), items.map { it.id })
        assertNull(items.single().clearLogoPath)
        client.close()
    }

    // Mutations and prefs.

    @Test
    fun `watch state continue watching and rating mutations hit their endpoints`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("{}")
        })
        val item = PlexMappers.mediaItem(kotlinx.serialization.json.Json.parseToJsonElement(movie("7")) as kotlinx.serialization.json.JsonObject)

        client.markWatched(item)
        client.markUnwatched(item)
        client.removeFromContinueWatching(item)
        client.rate(item, 8.0)

        assertEquals(listOf("PUT /:/scrobble", "PUT /:/unscrobble", "PUT /actions/removeFromContinueWatching", "PUT /:/rate"), requests.map { "${it.method.value} ${it.url.encodedPath}" })
        assertEquals("7", requests[0].url.parameters["key"])
        assertEquals(PLEX_LIBRARY_IDENTIFIER, requests[1].url.parameters["identifier"])
        assertEquals("7", requests[2].url.parameters["ratingKey"])
        assertEquals("7", requests[3].url.parameters["key"])
        assertEquals(PLEX_LIBRARY_IDENTIFIER, requests[3].url.parameters["identifier"])
        assertEquals("8.0", requests[3].url.parameters["rating"])
        client.close()
    }

    @Test
    fun `plex keeps no per user favorites and says so without a request`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("{}")
        })
        val item = PlexMappers.mediaItem(Json.parseToJsonElement(movie("7")).jsonObject)

        assertFailsWith<UnsupportedOperationException> { client.setFavorite(item, true) }
        assertEquals(emptyList(), requests)
        client.close()
    }

    @Test
    fun `server prefs mirror the watched threshold only when it changed`() = runTest {
        val mirrored = mutableListOf<Pair<ServerId, Int>>()
        var threshold = "80"
        val client = testPlexClient(
            { jsonResponse("""{"MediaContainer":{"Setting":[{"id":"LibraryVideoPlayedThreshold","value":"$threshold"},{"id":"FriendlyName","value":"Box"}]}}""") },
            environment = PlexClientEnvironment(onWatchedThresholdChanged = { id, percent -> mirrored += id to percent }),
        )

        client.fetchServerPrefs()
        client.fetchServerPrefs()
        threshold = "95"
        client.fetchServerPrefs()

        assertEquals(95, client.watchedThresholdPercent)
        assertEquals(0.95, client.watchedThreshold)
        assertEquals(listOf(ServerId(TEST_SERVER_ID) to 80, ServerId(TEST_SERVER_ID) to 95), mirrored)
        client.close()
    }

    @Test
    fun `a failed prefs fetch keeps the default threshold`() = runTest {
        val client = testPlexClient({ jsonResponse("{}", 500) })

        client.fetchServerPrefs()

        assertEquals(90, client.watchedThresholdPercent)
        assertEquals(0.9, client.watchedThreshold)
        assertFalse(client.hasServerPrefs)
        client.close()
    }

    // Extras.

    private val extrasEndpoint = "/library/metadata/42/extras"

    private fun trailer(id: String, title: String) = """{"ratingKey":"$id","type":"clip","subtype":"trailer","title":"$title"}"""

    private suspend fun MemoryApiCacheStore.seedExtras(id: String) =
        put(testProfileScope.value, extrasEndpoint, Json.parseToJsonElement(container(trailer(id, "Cached"))).jsonObject)

    private suspend fun PlexClient.cachedExtraIds(store: MemoryApiCacheStore) =
        metadataItemsFromCache(store.get(testProfileScope.value, extrasEndpoint)!!).map { it.id }

    @Test
    fun `extras come from the extras endpoint and are cached under it`() = runTest {
        val store = MemoryApiCacheStore()
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(container(trailer("t1", "Trailer")))
        }, store)

        val extras = client.fetchExtras("42")

        assertEquals(listOf("t1"), extras.map { it.id })
        assertEquals("Trailer", extras.single().title)
        assertEquals(listOf(extrasEndpoint), requests.map { it.url.encodedPath })
        assertEquals(listOf("t1"), client.cachedExtraIds(store))
        client.close()
    }

    @Test
    fun `a failed extras fetch answers from the cache and an uncached failure throws`() = runTest {
        val store = MemoryApiCacheStore()
        store.seedExtras("cached")
        val client = testPlexClient({ jsonResponse(container(trailer("error", "Must Not Replace")), 500) }, store)

        assertEquals(listOf("cached"), client.fetchExtras("42").map { it.id })
        assertEquals(listOf("cached"), client.cachedExtraIds(store))
        assertFailsWith<MediaServerHttpException> { client.fetchExtras("7") }
        client.close()
    }

    @Test
    fun `offline extras read the cache only and a miss is no extras`() = runTest {
        val store = MemoryApiCacheStore()
        store.seedExtras("cached")
        var requests = 0
        val client = testPlexClient({
            requests++
            jsonResponse(container(trailer("network", "Network")))
        }, store)
        client.isOfflineMode = true

        assertEquals(listOf("cached"), client.fetchExtras("42").map { it.id })
        assertEquals(emptyList(), client.fetchExtras("7"))
        assertEquals(0, requests)
        client.close()
    }
}
