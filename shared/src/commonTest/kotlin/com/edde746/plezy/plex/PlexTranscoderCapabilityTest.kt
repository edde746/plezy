package com.edde746.plezy.plex

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import kotlinx.coroutines.Dispatchers
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class PlexTranscoderCapabilityTest {
    private fun clientWithRoot(root: String) = testPlexClient({ request ->
        assertEquals("/", request.url.encodedPath)
        jsonResponse("""{"MediaContainer":$root}""")
    })

    // Like a real PMS: XML unless the request asks for JSON.
    private fun rootServer(root: String) = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = Dispatchers.Unconfined
                addHandler { request ->
                    if (request.url.encodedPath != "/") return@addHandler respond("", HttpStatusCode.NotFound)
                    if (request.headers["Accept"]?.contains("application/json") != true) {
                        return@addHandler respond("<MediaContainer/>", HttpStatusCode.OK, headersOf("Content-Type", "text/xml"))
                    }
                    respond("""{"MediaContainer":$root}""", HttpStatusCode.OK, headersOf("Content-Type", "application/json"))
                }
            },
        ),
    ) { install(HttpTimeout) }

    @Test
    fun `the client probe fails open when transcoderVideo is absent`() = runTest {
        val client = clientWithRoot("""{"friendlyName":"Plex"}""")

        assertTrue(client.serverSupportsVideoTranscoding())
        assertTrue(client.capabilities.videoTranscoding)
        client.close()
    }

    @Test
    fun `the client probe preserves an explicit transcoderVideo false`() = runTest {
        val client = clientWithRoot("""{"transcoderVideo":false}""")

        assertFalse(client.serverSupportsVideoTranscoding())
        assertFalse(client.capabilities.videoTranscoding)
        client.close()
    }

    @Test
    fun `the connection probe keeps an absent transcoderVideo unknown`() = runTest {
        val result = PlexClient.testConnectionWithLatency(rootServer("""{"friendlyName":"Plex"}"""), "http://127.0.0.1:32400", "token", 2.seconds, "client-id")

        assertTrue(result.success)
        assertNull(result.transcoderVideo)
    }

    @Test
    fun `the connection probe preserves an explicit transcoderVideo false`() = runTest {
        val result = PlexClient.testConnectionWithLatency(rootServer("""{"transcoderVideo":false}"""), "http://127.0.0.1:32400", "token", 2.seconds, "client-id")

        assertTrue(result.success)
        assertEquals(false, result.transcoderVideo)
    }
}
