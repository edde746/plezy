package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.SpecialsOrdering
import io.ktor.client.engine.mock.respond
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexLibraryOpsTest {
    private val machineRoot = """{"MediaContainer":{"machineIdentifier":"machine-1"}}"""

    private fun item(id: String, playlistItemId: String? = null) =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, playlistItemId = playlistItemId)

    private fun failing(status: Int) = testPlexClient({ jsonResponse("{}", status) })

    private suspend inline fun assertHttpStatus(status: Int, crossinline block: suspend () -> Unit) {
        val error = assertFailsWith<MediaServerHttpException> { block() }
        assertEquals(status, error.statusCode)
    }

    // Mutation result families.

    @Test
    fun nullableCollectionCreationThrowsRequestFailuresAndReservesNullForUnusableMetadata() = runTest {
        for (status in listOf(400, 500)) {
            assertHttpStatus(status) { failing(status).createCollection("1", "Collection", emptyList(), null) }
        }
        val timeout = testPlexClient({ throw ConnectTimeoutException("timed out") })
        assertFailsWith<MediaServerHttpException> { timeout.createCollection("1", "Collection", emptyList(), null) }

        val unusable = testPlexClient({ jsonResponse("""{"MediaContainer":{"Metadata":[]}}""") })
        assertNull(unusable.createCollection("1", "Collection", emptyList(), null))

        val valid = testPlexClient({ jsonResponse("""{"MediaContainer":{"Metadata":[{"ratingKey":"collection-1"}]}}""") })
        assertEquals("collection-1", valid.createCollection("1", "Collection", emptyList(), null))
    }

    @Test
    fun collectionCreationSendsTheWireFormat() = runTest {
        var captured: HttpRequestData? = null
        val client = testPlexClient({ request ->
            if (request.url.encodedPath == "/") return@testPlexClient jsonResponse(machineRoot)
            captured = request
            jsonResponse("""{"MediaContainer":{"Metadata":[{"ratingKey":" 9 "}]}}""")
        })

        assertEquals("9", client.createCollection("4", "Faves", listOf(item("1"), item("2")), MediaKind.MOVIE))

        val request = captured!!
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("/library/collections", request.url.encodedPath)
        assertEquals("1", request.url.parameters["type"])
        assertEquals("Faves", request.url.parameters["title"])
        assertEquals("0", request.url.parameters["smart"])
        assertEquals("4", request.url.parameters["sectionId"])
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/1,2", request.url.parameters["uri"])
    }

    @Test
    fun nullablePlaylistCreationSharesTheRequestAndAcceptedNullContract() = runTest {
        val valid = testPlexClient({
            jsonResponse(
                """{"MediaContainer":{"Metadata":[{"ratingKey":"playlist-1","type":"playlist","playlistType":"video","title":"Playlist","smart":false}]}}""",
            )
        })
        assertEquals("playlist-1", valid.createPlaylist("Playlist", emptyList())?.id)

        val unusable = testPlexClient({ jsonResponse("""{"MediaContainer":{"Metadata":[]}}""") })
        assertNull(unusable.createPlaylist("Playlist", emptyList()))

        assertFailsWith<MediaServerHttpException> { failing(500).createPlaylist("Playlist", emptyList()) }
    }

    @Test
    fun playlistMoveReturnsFalseOnlyForLocalPreconditionsAndThrowsRequestFailures() = runTest {
        var requests = 0
        val localOnly = testPlexClient({
            requests++
            respond("", HttpStatusCode.OK)
        })
        assertFalse(localOnly.movePlaylistItem("playlist", item("item"), 0, null))
        assertFalse(localOnly.movePlaylistItem("playlist", item("item", "7"), 2, item("other")))
        assertEquals(0, requests)

        var captured: HttpRequestData? = null
        val success = testPlexClient({ request ->
            captured = request
            respond("", HttpStatusCode.OK)
        })
        assertTrue(success.movePlaylistItem("playlist", item("item", "7"), 2, item("other", "5")))
        assertEquals(HttpMethod.Put, captured!!.method)
        assertEquals("/playlists/playlist/items/7/move", captured!!.url.encodedPath)
        assertEquals("5", captured!!.url.parameters["after"])

        assertTrue(success.movePlaylistItem("playlist", item("item", "7"), 0, null))
        assertEquals("0", captured!!.url.parameters["after"])

        assertFailsWith<MediaServerHttpException> { failing(500).movePlaylistItem("playlist", item("item", "7"), 0, null) }
    }

    @Test
    fun aPlaylistDeleteAnsweredWithNoContentSucceeds() = runTest {
        var deleted: String? = null
        val client = testPlexClient({ request ->
            deleted = "${request.method.value} ${request.url.encodedPath}"
            respond("", HttpStatusCode.NoContent)
        })

        assertTrue(client.deletePlaylist(MediaPlaylist(id = "1", backend = BackendKind.PLEX, title = "Mix", playlistType = "video")))
        assertEquals("DELETE /playlists/1", deleted)
    }

    @Test
    fun emptyPlaylistAndCollectionAddsSucceedWithoutARequest() = runTest {
        var requests = 0
        val client = testPlexClient({
            requests++
            respond("", HttpStatusCode.OK)
        })
        assertTrue(client.addToPlaylist("p", emptyList()))
        assertTrue(client.addToCollection("c", emptyList()))
        assertFalse(client.removeFromPlaylist("p", item("item")))
        assertEquals(0, requests)
    }

    @Test
    fun buildFolderUriFallsBackToTheServerRootAndThrowsWhenUnknown() = runTest {
        val client = testPlexClient({ jsonResponse(machineRoot) })
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/sections/1/all", client.buildFolderUri("/library/sections/1/all"))

        val unknown = testPlexClient({ jsonResponse("""{"MediaContainer":{}}""") })
        assertFailsWith<IllegalStateException> { unknown.buildMetadataUri("1") }
    }

    @Test
    fun collectionChildrenAreReadInPagesTheServerAccepts() = runTest {
        val sizes = mutableListOf<String?>()
        val client = testPlexClient({ request ->
            sizes += request.url.parameters["X-Plex-Container-Size"]
            val start = request.url.parameters["X-Plex-Container-Start"]!!.toInt()
            val size = request.url.parameters["X-Plex-Container-Size"]!!.toInt()
            val rows = (start until minOf(start + size, 130)).joinToString(",") { """{"ratingKey":"$it","type":"movie"}""" }
            jsonResponse("""{"MediaContainer":{"totalSize":130,"Metadata":[$rows]}}""")
        })

        val page = client.fetchCollectionPage("c", null, null, null, null)

        assertEquals(130, page.items.size)
        assertEquals(listOf<String?>("120", "120"), sizes)
    }

    // Play queues.

    @Test
    fun playQueueAcceptsNumericStringsFromPlex() = runTest {
        val client = testPlexClient({
            jsonResponse(
                """{"MediaContainer":{"playQueueID":"42","playQueueSelectedItemID":"7","playQueueTotalCount":"3","playQueueVersion":"5","size":"3","Metadata":[]}}""",
            )
        })

        val queue = client.createPlayQueue(uri = "server://items", type = "video")

        assertEquals(42, queue.id)
        assertEquals(7, queue.selectedItemId)
        assertEquals(3, queue.totalCount)
        assertEquals(3, queue.size)
    }

    @Test
    fun createPlayQueuePropagatesHttpFailureInsteadOfReturningNull() = runTest {
        val client = testPlexClient({ respond("boom", HttpStatusCode.InternalServerError) })
        assertHttpStatus(500) { client.createPlayQueue(uri = "server://items", type = "audio") }
    }

    @Test
    fun createPlayQueuePostValidatesAndRetriesAcrossEndpoints() = runTest {
        val primary = "https://plex.example.com"
        val fallback = "https://plex-fallback.example.com"
        val events = mutableListOf<String>()
        val client = testPlexClient(
            { request ->
                events += "${request.method.value}:${request.url.host}${request.url.encodedPath}"
                if (request.url.host == "plex.example.com") throw IOException("primary down")
                if (request.url.encodedPath == "/identity") {
                    jsonResponse("""{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID"}}""")
                } else {
                    jsonResponse("""{"MediaContainer":{"playQueueID":7,"playQueueVersion":1,"Metadata":[]}}""")
                }
            },
            baseUrl = primary,
            prioritizedEndpoints = listOf(primary, fallback),
        )

        val queue = client.createPlayQueue(uri = "server://items", type = "audio")

        assertEquals(7, queue.id)
        assertEquals(
            listOf(
                "POST:plex.example.com/playQueues",
                "GET:plex.example.com/identity",
                "GET:plex-fallback.example.com/identity",
                "POST:plex-fallback.example.com/playQueues",
            ),
            events,
        )
        assertEquals(fallback, client.config.baseUrl)
    }

    private fun selecting(ratingKey: String) =
        """{"MediaContainer":{"playQueueID":42,"playQueueVersion":1,"playQueueSelectedItemID":900,"Metadata":[{"playQueueItemID":900,"ratingKey":"$ratingKey","type":"episode"}]}}"""

    /** A Plex server answering every queue POST with [queue]; each POST's query lands in [posts]. */
    private fun showClient(
        posts: MutableList<Map<String, String?>>,
        ordering: () -> SpecialsOrdering = { SpecialsOrdering.RESPECT_SERVER },
        queue: String,
    ) = testPlexClient(
        { request ->
            when (request.url.encodedPath) {
                "/" -> jsonResponse(machineRoot)
                "/playQueues" -> {
                    posts += request.url.parameters.names().associateWith { request.url.parameters[it] }
                    jsonResponse(queue)
                }
                else -> respond("not found", HttpStatusCode.NotFound)
            }
        },
        environment = PlexClientEnvironment(specialsOrdering = ordering),
    )

    @Test
    fun serverOrderShowQueueIsPlexWebsContinuousQueueSeededAtTheEpisode() = runTest {
        val posts = mutableListOf<Map<String, String?>>()
        val client = showClient(posts, queue = selecting("ep-12"))

        val queue = client.createShowPlayQueue("show-1", startingEpisodeKey = "ep-12")

        assertEquals(42, queue?.id)
        val post = posts.single()
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/ep-12", post["uri"])
        assertEquals("1", post["continuous"])
        assertEquals("video", post["type"])
        assertNull(post["key"])
    }

    @Test
    fun airDateAndShuffledShowQueuesComeFromAllLeaves() = runTest {
        val posts = mutableListOf<Map<String, String?>>()
        var ordering = SpecialsOrdering.AIR_DATE
        val client = showClient(posts, { ordering }, selecting("ep-1"))

        client.createShowPlayQueue("show-1", startingEpisodeKey = "ep-12")
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves", posts.last()["uri"])
        assertEquals("0", posts.last()["continuous"])
        assertEquals("/library/metadata/ep-12", posts.last()["key"])

        ordering = SpecialsOrdering.RESPECT_SERVER
        client.createShowPlayQueue("show-1", shuffle = 1)
        assertEquals("server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves", posts.last()["uri"])
        assertEquals("1", posts.last()["shuffle"])
    }

    // Activities.

    @Test
    fun activitiesTolerateScalarDriftAndSkipOnlyMalformedRows() = runTest {
        val client = testPlexClient({
            jsonResponse(
                """{"MediaContainer":{"Activity":[
                    {"uuid":"activity-1","type":"library.update","title":"Scanning","subtitle":"Movies","progress":25,"cancellable":false},
                    "not-an-activity",
                    {"type":"library.update","title":"Missing identity"},
                    {"uuid":42,"type":7,"title":true,"subtitle":99,"progress":"75","cancellable":"1"}
                ]}}""",
            )
        })

        val activities = client.getActivities()

        assertEquals(2, activities.size)
        assertEquals(PlexActivity("activity-1", "library.update", "Scanning", "Movies", 25, false), activities.first())
        assertEquals(PlexActivity("42", "7", "true", "99", 75, true), activities.last())
    }

    @Test
    fun activityFetchCancellationPropagatesInsteadOfAnEmptyList() = runTest {
        val started = CompletableDeferred<Unit>()
        var requests = 0
        var result: List<PlexActivity>? = null
        val client = testPlexClient(
            {
                requests++
                started.complete(Unit)
                awaitCancellation()
            },
            prioritizedEndpoints = listOf(TEST_BASE_URL, "https://plex-fallback.example.com"),
        )

        val job = launch { result = client.getActivities() }
        started.await()
        job.cancelAndJoin()

        assertTrue(job.isCancelled)
        assertNull(result)
        assertEquals(1, requests)
    }

    @Test
    fun cancelActivityDeletesAndThrowsOnFailure() = runTest {
        var captured: HttpRequestData? = null
        val client = testPlexClient({ request ->
            captured = request
            respond("", HttpStatusCode.OK)
        })
        client.cancelActivity("abc")
        assertEquals(HttpMethod.Delete, captured!!.method)
        assertEquals("/activities/abc", captured!!.url.encodedPath)

        assertHttpStatus(500) { failing(500).cancelActivity("abc") }
    }

    // Metadata edit.

    @Test
    fun metadataEditPreservesLockedFieldsAndRemovedTagWireFormat() = runTest {
        var captured: HttpRequestData? = null
        val client = testPlexClient({ request ->
            captured = request
            respond("", HttpStatusCode.OK)
        })

        val updated = client.updateMetadata(
            sectionId = 1,
            ratingKey = "item-id",
            typeNumber = 1,
            title = "Renamed",
            tagChanges = mapOf("genre" to PlexTagChange(current = listOf("Drama"), original = listOf("Drama", "Science Fiction"))),
        )

        assertTrue(updated)
        val request = captured!!
        assertEquals(HttpMethod.Put, request.method)
        assertEquals("/library/sections/1/all", request.url.encodedPath)
        assertEquals("1", request.url.parameters["type"])
        assertEquals("item-id", request.url.parameters["id"])
        assertEquals("Renamed", request.url.parameters["title.value"])
        assertEquals("1", request.url.parameters["title.locked"])
        assertEquals("Drama", request.url.parameters["genre[0].tag.tag"])
        assertEquals("Science Fiction", request.url.parameters["genre[].tag.tag-"])
        assertEquals("1", request.url.parameters["genre.locked"])
    }

    @Test
    fun metadataEditRemovesCommaTagsOneRequestAtATime() = runTest {
        val removals = mutableListOf<String?>()
        val client = testPlexClient({ request ->
            removals += request.url.parameters["genre[].tag.tag-"]
            respond("", HttpStatusCode.OK)
        })

        assertTrue(
            client.updateMetadata(1, "item-id", 1, tagChanges = mapOf("genre" to PlexTagChange(listOf("Drama"), listOf("Drama", "Action, Adventure", "War")))),
        )

        assertEquals(listOf(null, "Action, Adventure", "War"), removals)
    }

    @Test
    fun findMatchesThrowsOnHttp500InsteadOfReportingNoMatches() = runTest {
        assertHttpStatus(500) { failing(500).findMatches("item-1", title = "Movie") }
    }

    @Test
    fun metadataPrefsReadNestedSettingsAndNormalizeValues() {
        val container = kotlinx.serialization.json.Json.parseToJsonElement(
            """{"Metadata":[{"Preferences":{"Setting":[{"id":"a","value":"x"},{"id":"b","value":3},{"id":"c","value":true},{"id":" ","value":"1"},{"id":"d","value":null}]}}]}""",
        ) as kotlinx.serialization.json.JsonObject

        assertEquals(mapOf("a" to "x", "b" to "3", "c" to "1"), PlexMetadataPreferences.fromMediaContainer(container))
    }

    @Test
    fun metadataPrefsFallBackToTheItemsOwnSettingsTakeALoneSettingAndTrimIds() {
        fun prefs(json: String) = PlexMetadataPreferences.fromMediaContainer(
            kotlinx.serialization.json.Json.parseToJsonElement(json) as kotlinx.serialization.json.JsonObject,
        )
        assertEquals(
            mapOf("a" to "0", "b" to "2.5"),
            prefs("""{"Metadata":[{"Preferences":{"Setting":[]},"Setting":[{"id":" a ","value":false},{"id":"b","value":2.5},{"id":"c","value":{"x":1}}]}]}"""),
        )
        assertEquals(mapOf("lone" to "x"), prefs("""{"Metadata":[{"Preferences":{"Setting":{"id":"lone","value":"x"}}}]}"""))
    }

    @Test
    fun voidMutationTimeoutSurfacesAsConnectionTimeout() = runTest {
        val client = testPlexClient({ throw ConnectTimeoutException("timed out") })
        val error = assertFailsWith<MediaServerHttpException> { client.deleteCollection(item("collection-id")) }
        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
    }
}
