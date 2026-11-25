package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerPinExpiredException
import com.edde746.plezy.playback.resolve.FakeHttp
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

internal fun MockRequestHandleScope.jsonResponse(body: String, status: Int = 200): HttpResponseData =
    respond(body, HttpStatusCode.fromValue(status), headersOf(HttpHeaders.ContentType, "application/json"))

internal fun TestScope.authWith(
    deviceName: String? = null,
    handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
): Pair<PlexAuthService, FakeHttp> {
    val http = FakeHttp(this, handler = handler)
    val auth = PlexAuthService(
        http.client,
        clientIdentifier = "test-client",
        appVersion = "1.2.3",
        platformVersion = "15.1",
        platform = "macOS",
        deviceName = deviceName,
    )
    return auth to http
}

private fun serverJson(
    owned: String = "true",
    product: String? = null,
    lastSeenAt: String? = null,
    port: String = "32400",
    local: String = "true",
    relay: String = "false",
    ipv6: String = "false",
) = """{"name":"Home Server","clientIdentifier":"srv-1","accessToken":"server-token","owned":$owned,"provides":"server",
    ${product?.let { "\"product\":$it," }.orEmpty()}${lastSeenAt?.let { "\"lastSeenAt\":$it," }.orEmpty()}
    "connections":[{"protocol":"https","address":"192.168.1.3","port":$port,"uri":"https://192-168-1-3.machine.plex.direct:32400",
    "local":$local,"relay":$relay,"IPv6":$ipv6}]}"""

class PlexAuthServiceTest {
    @Test
    fun `fetchServers retries resources through plex tv after clients host transport failure`() = runTest {
        val (auth, http) = authWith { request ->
            if (request.url.host == "clients.plex.tv") throw IOException("DNS failed")
            jsonResponse("[${serverJson()}]")
        }

        val servers = auth.fetchServers("token")

        assertEquals(listOf("clients.plex.tv", "plex.tv"), http.requests.map { it.url.host })
        assertEquals("/api/v2/resources", http.requests.last().url.encodedPath)
        assertEquals("srv-1", servers.single().clientIdentifier)
    }

    @Test
    fun `fetchServers does not retry canonical host for HTTP auth failures`() = runTest {
        val (auth, http) = authWith { jsonResponse("""{"errors":[]}""", status = 401) }

        val error = assertFailsWith<MediaServerHttpException> { auth.fetchServers("bad-token") }

        assertEquals(401, error.statusCode)
        assertEquals(listOf("clients.plex.tv"), http.requests.map { it.url.host })
    }

    @Test
    fun `fetchServers lists only servers and fails when every server is malformed`() = runTest {
        var body = """[{"provides":"client","name":"Phone"},${serverJson()},{"provides":"server","name":"Broken"}]"""
        val (auth, _) = authWith { jsonResponse(body) }

        assertEquals(listOf("srv-1"), auth.fetchServers("token").map { it.clientIdentifier })

        body = """[{"provides":"server","name":"Broken"}]"""
        val error = assertFailsWith<PlexServerParsingException> { auth.fetchServers("token") }
        assertEquals(1, error.invalidServers.size)

        body = "[]"
        assertEquals(emptyList(), auth.fetchServers("token"))
    }

    @Test
    fun `pollPinUntilClaimed retries a transient transport failure while sign in completes`() = runTest {
        var pollCount = 0
        val (auth, _) = authWith { request ->
            pollCount++
            if (pollCount == 1) throw IOException("The Internet connection appears to be offline.")
            jsonResponse("""{"authToken":"claimed-token"}""")
        }

        val token = auth.pollPinUntilClaimed(1, timeout = 1.seconds, initialBackoff = Duration.ZERO, maxBackoff = Duration.ZERO)

        assertEquals("claimed-token", token)
        assertEquals(2, pollCount)
    }

    @Test
    fun `pollPinUntilClaimed backs off 1 2 4 5 seconds and gives up at the timeout`() = runTest {
        val polledAt = mutableListOf<Long>()
        val (auth, _) = authWith {
            polledAt += testScheduler.currentTime
            jsonResponse("""{"authToken":null}""")
        }

        assertNull(auth.pollPinUntilClaimed(1, timeout = 20.seconds))
        assertEquals(listOf(0L, 1_000, 3_000, 7_000, 12_000, 17_000), polledAt)
    }

    @Test
    fun `pollPinUntilClaimed stops on an expired PIN`() = runTest {
        val (auth, _) = authWith { jsonResponse("{}", status = 410) }

        assertFailsWith<MediaServerPinExpiredException> { auth.pollPinUntilClaimed(1) }
    }

    @Test
    fun `checkPin maps expired and rejected PINs`() = runTest {
        var status = 404
        val (auth, http) = authWith { jsonResponse("{}", status = status) }

        assertFailsWith<MediaServerPinExpiredException> { auth.checkPin(7) }
        status = 403
        val rejected = assertFailsWith<MediaServerAuthException> { auth.checkPin(7) }
        assertEquals(403, rejected.statusCode)
        status = 500
        assertFailsWith<MediaServerHttpException> { auth.checkPin(7) }
        assertEquals("https://plex.tv/api/v2/pins/7", http.requests.first().url.toString())
    }

    @Test
    fun `createPin posts a strong or a short PIN request with the common headers`() = runTest {
        val (auth, http) = authWith(deviceName = "Living Room") { jsonResponse("""{"id":42,"code":"abcd"}""", status = 201) }

        assertEquals(PlexPin(42, "abcd"), auth.createPin(strong = true))
        auth.createPin(strong = false)

        assertEquals(
            listOf("https://plex.tv/api/v2/pins?strong=true", "https://plex.tv/api/v2/pins?strong=false"),
            http.requests.map { it.url.toString() },
        )
        val request = http.requests.first()
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("application/json", request.headers["Accept"])
        assertEquals("Plezy", request.headers["X-Plex-Product"])
        assertEquals("test-client", request.headers["X-Plex-Client-Identifier"])
        assertEquals("macOS", request.headers["X-Plex-Platform"])
        assertEquals("Living Room", request.headers["X-Plex-Device-Name"])
        assertNull(request.headers["X-Plex-Token"])
        assertNull(request.headers["X-Plex-Version"])
    }

    @Test
    fun `auth url carries the PIN in the fragment`() = runTest {
        val (auth, _) = authWith { jsonResponse("{}") }

        assertEquals(
            "https://app.plex.tv/auth#?clientID=test-client&code=abcd&context%5Bdevice%5D%5Bproduct%5D=Plezy",
            auth.authUrl("abcd"),
        )
    }

    @Test
    fun `link url opens plex tv link with the PIN filled in`() = runTest {
        val (auth, _) = authWith { jsonResponse("{}") }

        assertEquals("https://www.plex.tv/link/?pin=6TWW", auth.linkUrl("6TWW"))
    }

    @Test
    fun `switchToUser tolerates drifted field shapes on the 201 body 1488`() = runTest {
        val (auth, http) = authWith {
            jsonResponse(
                """{"id":312174832,"uuid":"uuid-1","title":"hi_phi","authToken":"minted-user-token",
                "profile":{"defaultAudioLanguages":"en,sv","defaultSubtitleLanguages":"en,sv","mediaPostsVisibility":true}}""",
                status = 201,
            )
        }

        val token = auth.switchToUser("uuid-1", "account-token")

        assertEquals("minted-user-token", token)
        val request = http.requests.single()
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("clients.plex.tv", request.url.host)
        assertEquals("/api/v2/home/users/uuid-1/switch", request.url.encodedPath)
    }

    @Test
    fun `switchToUser sends all identity in the query and only Accept as a header`() = runTest {
        val (auth, http) = authWith(deviceName = "Living Room") { jsonResponse("""{"authToken":"t"}""", status = 201) }

        auth.switchToUser("uuid-1", "account-token", pin = "1234")
        auth.switchToUser("uuid-1", "account-token")

        val query = http.requests.first().url.parameters
        assertEquals(
            mapOf(
                "includeSubscriptions" to "1",
                "includeProviders" to "1",
                "includeSettings" to "1",
                "includeSharedSettings" to "1",
                "X-Plex-Product" to "Plezy",
                "X-Plex-Version" to "1.2.3",
                "X-Plex-Client-Identifier" to "test-client",
                "X-Plex-Platform" to "macOS",
                "X-Plex-Platform-Version" to "15.1",
                "X-Plex-Token" to "account-token",
                "X-Plex-Language" to "en",
                "pin" to "1234",
            ),
            query.names().associateWith { query[it] },
        )
        assertNull(http.requests.last().url.parameters["pin"])
        assertNull(http.requests.first().headers["X-Plex-Token"])
        assertNull(http.requests.first().headers["X-Plex-Device-Name"])
        assertEquals("application/json", http.requests.first().headers["Accept"])
    }

    @Test
    fun `home users come from the clients API`() = runTest {
        val (auth, http) = authWith { jsonResponse("""{"id":"3","users":[{"id":1,"uuid":"u1","title":"Owner","admin":true}]}""") }

        val home = auth.getHomeUsers("tok")

        assertEquals(3, home.id)
        assertEquals("u1", home.users.single { it.admin }.uuid)
        assertEquals("https://clients.plex.tv/api/v2/home/users", http.requests.single().url.toString())
    }

    @Test
    fun `fetchServers tolerates scalar drift in server and connection fields`() = runTest {
        val (auth, _) = authWith {
            jsonResponse(
                "[" + serverJson(
                    owned = "\"1\"",
                    product = "42",
                    lastSeenAt = "123",
                    port = "\"32400\"",
                    local = "\"1\"",
                    relay = "0",
                    ipv6 = "\"false\"",
                ) + "]",
            )
        }

        val server = auth.fetchServers("token").single()

        assertTrue(server.owned)
        assertEquals("42", server.product)
        assertNull(server.lastSeenAt)
        assertEquals(32400, server.connections.first().port)
        assertTrue(server.connections.first().local)
        assertFalse(server.connections.first().relay)
        assertFalse(server.connections.first().ipv6)
    }
}
