package com.edde746.plezy.plex

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.plugins.HttpTimeout
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.respondError
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals

class PlexServerDiscoveryTest {
    private fun server(vararg connections: PlexConnection) = PlexServer.fromJson(
        buildJsonObject {
            put("name", "Home Server")
            put("clientIdentifier", "srv-1")
            put("accessToken", "token-1")
            put("connections", JsonArray(connections.map { it.toJson() }))
        },
    )

    private fun http(port: Int, local: Boolean = true, ipv6: Boolean = false, address: String = "127.0.0.1") =
        PlexConnection("http", address, port, "http://127.0.0.1:$port", local = local, relay = false, ipv6 = ipv6)

    /** Answers `/` per port: a delay in ms (virtual time), or null for a refused connection. */
    private fun TestScope.client(delays: Map<Int, Long?>) = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = StandardTestDispatcher(testScheduler)
                addHandler { request ->
                    val d = delays[request.url.port]
                    if (d == null) {
                        respondError(HttpStatusCode.ServiceUnavailable)
                    } else {
                        delay(d)
                        respond("""{"MediaContainer":{"machineIdentifier":"srv-1"}}""", headers = headersOf(HttpHeaders.ContentType, "application/json"))
                    }
                }
            },
        ),
    ) { install(HttpTimeout) }

    @Test
    fun `keeps a slower IPv4 endpoint over a faster IPv6 sibling in both race phases`() = runTest {
        val s = server(http(2, ipv6 = true, address = "::1"), http(1))
        val emitted = s.findBestWorkingConnection(client(mapOf(1 to 100L, 2 to 0L))).toList().map { it.uri }
        assertEquals(listOf("http://127.0.0.1:1"), emitted)
    }

    @Test
    fun `accepts an IPv6 endpoint once every IPv4 sibling has failed`() = runTest {
        val s = server(http(2, ipv6 = true, address = "::1"), http(1))
        val emitted = s.findBestWorkingConnection(client(mapOf(1 to null, 2 to 0L))).toList().map { it.uri }
        assertEquals(listOf("http://127.0.0.1:2"), emitted)
    }

    @Test
    fun `emits nothing when every candidate fails`() = runTest {
        val s = server(http(1))
        assertEquals(emptyList(), s.findBestWorkingConnection(client(emptyMap())).toList())
    }
}
