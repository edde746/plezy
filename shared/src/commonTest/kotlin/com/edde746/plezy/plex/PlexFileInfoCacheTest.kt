package com.edde746.plezy.plex

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * `/library/metadata/{id}` is a shared cache row that lighter readers fill without streams or file checks. File info
 * must not serve such a lean row: it would show no stream table and no file-presence flags.
 */
class PlexFileInfoCacheTest {
    private val endpoint = "/library/metadata/movie-1"
    private val store = MemoryApiCacheStore()
    private val scopeA = PlexProfileScopeId.of(ServerId(TEST_SERVER_ID), "profile-a")
    private val scopeB = PlexProfileScopeId.of(ServerId(TEST_SERVER_ID), "profile-b")
    private val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Movie", serverId = TEST_SERVER_ID)

    private fun metadata(parts: String): String =
        """{"MediaContainer":{"Metadata":[{"ratingKey":"movie-1","title":"Movie","type":"movie","Media":[{"id":1,"container":"mkv","videoCodec":"h264","Part":[$parts]}]}]}}"""

    private val lean = metadata("""{"id":10,"file":"/media/movie.mkv","size":100}""")
    private val full = metadata(
        """{"id":10,"file":"/media/movie.mkv","size":100,"exists":true,"accessible":true,"Stream":[{"id":1,"streamType":1,"codec":"h264"}]}""",
    )
    private val probedEmpty = metadata("""{"id":10,"file":"/media/movie.mkv","size":100,"exists":true,"accessible":true,"Stream":[]}""")
    private val mixedParts = metadata(
        """{"id":10,"file":"/media/movie-cd1.mkv","exists":true,"accessible":true,"Stream":[{"id":1,"streamType":1,"codec":"h264"}]},{"id":11,"file":"/media/movie-cd2.mkv"}""",
    )

    private fun json(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    private fun recordingClient(requests: MutableList<HttpRequestData>, status: Int = 200) = testPlexClient(
        { request ->
            requests += request
            if (status == 200) jsonResponse(full) else jsonResponse("boom", status)
        },
        store,
        profileScopeId = scopeA,
    )

    @Test
    fun `a lean cached row is refetched with the full file info shape`() = runTest {
        store.put(scopeA.value, endpoint, json(lean))
        val requests = mutableListOf<HttpRequestData>()

        val info = recordingClient(requests).getFileInfo(movie)

        assertEquals(1, requests.size)
        assertEquals("1", requests.single().url.parameters["includeStreams"])
        assertEquals("1", requests.single().url.parameters["checkFiles"])
        val part = info!!.versions.single().parts.single()
        assertEquals(1, part.streams.size)
        assertEquals(true, part.exists)
        assertEquals(true, part.accessible)
        assertEquals(json(full), store.get(scopeA.value, endpoint))
    }

    @Test
    fun `a complete cached row is served without the network`() = runTest {
        store.put(scopeA.value, endpoint, json(full))
        val requests = mutableListOf<HttpRequestData>()

        val info = recordingClient(requests).getFileInfo(movie)

        assertTrue(requests.isEmpty())
        assertEquals(1, info!!.versions.single().parts.single().streams.size)
    }

    @Test
    fun `a part probed as empty still counts as complete`() = runTest {
        store.put(scopeA.value, endpoint, json(probedEmpty))
        val requests = mutableListOf<HttpRequestData>()

        val info = recordingClient(requests).getFileInfo(movie)

        assertTrue(requests.isEmpty())
        assertTrue(info!!.versions.single().parts.single().streams.isEmpty())
    }

    @Test
    fun `one complete part does not excuse a lean sibling`() = runTest {
        store.put(scopeA.value, endpoint, json(mixedParts))
        val requests = mutableListOf<HttpRequestData>()

        recordingClient(requests).getFileInfo(movie)

        assertEquals(1, requests.size)
    }

    @Test
    fun `offline keeps the lean row rather than failing`() = runTest {
        store.put(scopeA.value, endpoint, json(lean))
        val requests = mutableListOf<HttpRequestData>()
        val client = recordingClient(requests)
        client.isOfflineMode = true

        val part = client.getFileInfo(movie)!!.versions.single().parts.single()

        assertTrue(requests.isEmpty())
        assertEquals("/media/movie.mkv", part.filePath)
        assertTrue(part.streams.isEmpty())
    }

    @Test
    fun `a failed refetch falls back to the lean row`() = runTest {
        store.put(scopeA.value, endpoint, json(lean))
        val requests = mutableListOf<HttpRequestData>()

        val info = recordingClient(requests, status = 500).getFileInfo(movie)

        assertTrue(requests.isNotEmpty())
        assertEquals("/media/movie.mkv", info!!.versions.single().parts.single().filePath)
    }

    @Test
    fun `an uncached item is fetched in full and cached`() = runTest {
        val requests = mutableListOf<HttpRequestData>()

        val info = recordingClient(requests).getFileInfo(movie)

        assertEquals(1, requests.size)
        assertNotNull(info)
        assertEquals(json(full), store.get(scopeA.value, endpoint))
    }

    @Test
    fun `the refetch keeps the profile identity captured before the cache read`() = runTest {
        store.put(scopeA.value, endpoint, json(lean))
        val tokens = mutableListOf<String?>()
        val client = testPlexClient(
            { request ->
                when (request.url.encodedPath) {
                    "/" -> jsonResponse("""{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID"}}""")
                    "/media/providers" -> jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""")
                    else -> {
                        tokens += request.headers["X-Plex-Token"]
                        jsonResponse(full)
                    }
                }
            },
            store,
            token = "token-a",
            profileScopeId = scopeA,
        )
        // Hold the first cache read open so the profile switch lands between the cache lookup and the refetch.
        val reached = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        store.beforeGet = {
            store.beforeGet = null
            reached.complete(Unit)
            release.await()
        }

        val info = async { client.getFileInfo(movie) }
        reached.await()
        try {
            client.applyProfileUpdate("token-b", scopeB)
        } finally {
            release.complete(Unit)
        }

        assertEquals(true, info.await()!!.versions.single().parts.single().exists)
        assertEquals(listOf<String?>("token-a"), tokens)
        assertEquals(json(full), store.get(scopeA.value, endpoint))
        assertNull(store.get(scopeB.value, endpoint))
    }
}
