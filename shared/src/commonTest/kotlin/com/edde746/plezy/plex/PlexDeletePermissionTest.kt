package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaDeletionRefusedException
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpMethod
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Plex's Allow media deletion switch: read from the server root, and read again before every delete, which it gates. */
class PlexDeletePermissionTest {
    private val item = MediaItem(id = "42", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, serverId = TEST_SERVER_ID)
    private val requests = mutableListOf<HttpRequestData>()

    private fun root(allowMediaDeletion: String?) =
        """{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID"${allowMediaDeletion?.let { ""","allowMediaDeletion":$it""" } ?: ""}}}"""

    private fun server(rootBody: String) = testPlexClient({ request ->
        requests += request
        if (request.url.encodedPath == "/") jsonResponse(rootBody) else jsonResponse("{}")
    })

    private val deletes get() = requests.filter { it.method == HttpMethod.Delete }

    @Test
    fun theSwitchIsReadFromTheRootAndAMissingOneIsOff() = runTest {
        for ((value, expected) in listOf("true" to true, "1" to true, "\"1\"" to true, "false" to false, "0" to false, null to false)) {
            val client = server(root(value))
            assertEquals(expected, client.fetchDeletePermission(item), "allowMediaDeletion $value")
            assertEquals(expected, client.carriedDeletePermission(item), "kept as last read")
        }
        assertNull(server("""{"error":"nope"}""").fetchDeletePermission(item))
        assertTrue(requests.all { it.url.encodedPath == "/" && it.method == HttpMethod.Get })
    }

    @Test
    fun theConnectionProbeReadsTheSwitchAndAMissingOneIsOff() = runTest {
        for ((body, expected) in listOf(root("1") to true, root(null) to false, "{}" to null)) {
            assertEquals(expected, PlexClient.testConnectionWithLatency(server(body).httpClient, TEST_BASE_URL, TEST_TOKEN).allowMediaDeletion, body)
        }
    }

    @Test
    fun aDeleteGoesOutOnlyWhileTheSwitchIsOn() = runTest {
        assertTrue(server(root("1")).deleteMediaItem(item))
        assertEquals(listOf("/library/metadata/42"), deletes.map { it.url.encodedPath })

        requests.clear()
        for (value in listOf("0", null)) {
            assertFailsWith<MediaDeletionRefusedException> { server(root(value)).deleteMediaItem(item) }
        }
        assertFailsWith<MediaDeletionRefusedException> { server("{}").deleteMediaItem(item) }
        assertEquals(emptyList(), deletes)
    }

    @Test
    fun anUnreadableSwitchSendsNoDelete() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("{}", 500)
        })
        assertEquals(500, assertFailsWith<MediaServerHttpException> { client.deleteMediaItem(item) }.statusCode)
        assertEquals(emptyList(), deletes)
    }

    @Test
    fun aServerThatNeverAnswersTimesOutAtTheProbeDeadlineAndGetsNoDelete() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            awaitCancellation()
        })

        val error = assertFailsWith<MediaServerHttpException> { client.deleteMediaItem(item) }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertTrue(currentTime <= MediaServerTimeouts.DELETE_PERMISSION_PROBE.inWholeMilliseconds)
        assertEquals(emptyList(), deletes)
    }

    @Test
    fun theReadNeverFailsOverToAnotherEndpoint() = runTest {
        val primary = "https://plex.example.com"
        val client = testPlexClient(
            { request ->
                requests += request
                throw IOException("connection reset")
            },
            baseUrl = primary,
            prioritizedEndpoints = listOf(primary, "https://plex-fallback.example.com"),
        )

        assertFailsWith<MediaServerHttpException> { client.fetchDeletePermission(item) }

        assertEquals(listOf("plex.example.com"), requests.map { it.url.host }.distinct())
    }

    @Test
    fun anAnswerReadBeforeAPlexHomeSwitchAllowsNoDelete() = runTest {
        lateinit var client: PlexClient
        var switched = false
        client = testPlexClient({ request ->
            requests += request
            when {
                request.url.encodedPath != "/" -> jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""")
                request.headers["X-Plex-Token"] == TEST_TOKEN && !switched -> {
                    // Another Home user signs in while the switch is read.
                    switched = true
                    assertTrue(client.applyProfileUpdate("token-b", PlexProfileScopeId.of(ServerId(TEST_SERVER_ID), "profile-b")))
                    jsonResponse(root("1"))
                }
                else -> jsonResponse(root("1"))
            }
        })

        assertFalse(client.deleteMediaItem(item))
        assertTrue(switched)
        assertEquals(emptyList(), deletes)
    }
}
