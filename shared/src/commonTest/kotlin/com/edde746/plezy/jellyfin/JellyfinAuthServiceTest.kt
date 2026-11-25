package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.utils.io.errors.IOException
import kotlinx.coroutines.awaitCancellation
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class JellyfinAuthServiceTest {
    private val time = VirtualTime()
    private val serverInfo = JellyfinServerInfo(serverName = "Home", machineId = "srv-1", version = "10.9.0")
    private val header = "MediaBrowser Client=\"Plezy\", Device=\"TestDevice\", DeviceId=\"dev-xyz\", Version=\"test\""

    private fun service(
        dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
        deviceId: String = "dev-xyz",
        timeoutMs: Long = 8_000,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) = JellyfinAuthService(
        fakeHttp(time, handler),
        JellyfinDeviceIdentity(clientName = "Plezy", deviceName = "TestDevice", clientVersion = "test", deviceId = deviceId),
        dialect,
        requestTimeout = timeoutMs.milliseconds,
        now = { 1_000L },
        timeSource = time.timeSource,
    )

    private fun MockRequestHandleScope.status(code: Int, body: String = "") = json(body, code)

    private val HttpRequestData.path get() = url.encodedPath
    private val HttpRequestData.text get() = (body as? TextContent)?.text.orEmpty()

    private suspend fun authenticateWithUser(user: String): JellyfinConnection = service { req ->
        when (req.path) {
            "/System/Info/Public" -> json("""{"Id":"srv-1","ServerName":"Home"}""")
            "/Users/AuthenticateByName" -> json("""{"AccessToken":"tok-new","User":$user}""")
            else -> status(404)
        }
    }.authenticateByName("https://jf.example.com", "edde", "pw")

    // probe

    @Test
    fun probeReturnsServerInfo() = time.test {
        val svc = service { req ->
            assertEquals("/System/Info/Public", req.path)
            assertEquals("GET", req.method.value)
            json("""{"Id":"srv-1","ServerName":"Home","Version":"10.9.0"}""")
        }
        val info = svc.probe("https://jf.example.com/")
        assertEquals("Home", info.serverName)
        assertEquals("srv-1", info.machineId)
        assertEquals("10.9.0", info.version)
    }

    @Test
    fun probeFallsBackToLocalAddress() = time.test {
        val svc = service { json("""{"Id":"srv-1","LocalAddress":"http://192.168.1.10:8096"}""") }
        assertEquals("http://192.168.1.10:8096", svc.probe("https://jf.example.com").serverName)
    }

    @Test
    fun probeRejectsNonJson() = time.test {
        val svc = service { respond("plain text", HttpStatusCode.OK) }
        val error = assertFailsWith<MediaServerUrlException> { svc.probe("https://jf.example.com") }
        assertEquals("Server response was not JSON", error.message)
    }

    @Test
    fun probeRejectsMissingIdentity() = time.test {
        val svc = service { json("""{"Version":"10.9.0"}""") }
        val error = assertFailsWith<MediaServerUrlException> { svc.probe("https://jf.example.com") }
        assertEquals("Server response missing Id/ServerName — not a Jellyfin server?", error.message)
    }

    @Test
    fun probeWrapsHttpErrors() = time.test {
        val svc = service { status(500, """{"error":"oops"}""") }
        val error = assertFailsWith<MediaServerUrlException> { svc.probe("https://jf.example.com") }
        assertEquals("Server probe failed: HTTP 500", error.message)
    }

    @Test
    fun probeWrapsTransportErrors() = time.test {
        val svc = service { throw IOException("network down") }
        assertFailsWith<MediaServerUrlException> { svc.probe("https://jf.example.com") }
    }

    @Test
    fun probeAppliesTheRequestTimeout() = time.test {
        val svc = service(timeoutMs = 50) { awaitCancellation() }
        val error = assertFailsWith<MediaServerUrlException> { svc.probe("https://jf.example.com") }
        assertEquals("Server did not respond in time", error.message)
    }

    // authenticateByName

    @Test
    fun passwordSignInReturnsAConnection() = time.test {
        val svc = service { req ->
            when (req.path) {
                "/System/Info/Public" -> json("""{"Id":"srv-1","ServerName":"Home","Version":"10.9.0"}""")
                "/Users/AuthenticateByName" -> {
                    assertEquals("POST", req.method.value)
                    json("""{"AccessToken":"tok-new","User":{"Id":"user-7","Name":"edde","Policy":{"IsAdministrator":true}}}""")
                }
                else -> status(404)
            }
        }

        val conn = svc.authenticateByName(
            "https://jf.example.com",
            "edde",
            "pw",
            baseUrls = listOf("https://jf.example.com", "https://jf.lan:8096"),
        )

        assertEquals("tok-new", conn.accessToken)
        assertEquals("https://jf.example.com", conn.baseUrl)
        assertEquals(listOf("https://jf.example.com", "https://jf.lan:8096"), conn.baseUrls)
        assertEquals("user-7", conn.userId)
        assertEquals("edde", conn.userName)
        assertEquals("srv-1", conn.serverMachineId)
        assertEquals("Home", conn.serverName)
        assertEquals("srv-1/user-7", conn.id)
        assertEquals("dev-xyz", conn.deviceId)
        assertTrue(conn.isAdministrator)
        assertEquals(1_000L, conn.createdAt)
        assertEquals(1_000L, conn.lastAuthenticatedAt)
    }

    @Test
    fun capturesThePrimaryImageTag() = time.test {
        assertEquals("avatar-tag", authenticateWithUser("""{"Id":"user-7","Name":"edde","PrimaryImageTag":"avatar-tag"}""").primaryImageTag)
    }

    @Test
    fun missingOrNullPrimaryImageTagIsNull() = time.test {
        assertNull(authenticateWithUser("""{"Id":"user-7","Name":"edde"}""").primaryImageTag)
        assertNull(authenticateWithUser("""{"Id":"user-7","Name":"edde","PrimaryImageTag":null}""").primaryImageTag)
    }

    @Test
    fun blankPrimaryImageTagsAreNull() = time.test {
        for (tag in listOf("\"\"", "\"   \\t \"")) {
            assertNull(authenticateWithUser("""{"Id":"user-7","Name":"edde","PrimaryImageTag":$tag}""").primaryImageTag, tag)
        }
    }

    @Test
    fun malformedPrimaryImageTagDoesNotFailSignIn() = time.test {
        assertEquals("12345", authenticateWithUser("""{"Id":"user-7","Name":"edde","PrimaryImageTag":12345}""").primaryImageTag)
        for (tag in listOf("""["unexpected"]""", """{"unexpected":"tag"}""")) {
            assertEquals("user-7", authenticateWithUser("""{"Id":"user-7","Name":"edde","PrimaryImageTag":$tag}""").userId, tag)
        }
    }

    @Test
    fun passwordSignInRejects401() = time.test {
        val svc = service { req -> if (req.path == "/System/Info/Public") json("""{"Id":"srv-1","ServerName":"Home"}""") else status(401) }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "wrong") }
        assertEquals("Invalid username or password", error.message)
        assertEquals(401, error.statusCode)
    }

    @Test
    fun passwordSignInRejectsMalformedJson401() = time.test {
        val svc = service { req -> if (req.path == "/System/Info/Public") json("""{"Id":"srv-1","ServerName":"Home"}""") else status(401, "{bad json") }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "wrong") }
        assertEquals(401, error.statusCode)
    }

    @Test
    fun passwordSignInRejects403() = time.test {
        val svc = service { status(403) }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) }
        assertEquals(403, error.statusCode)
    }

    @Test
    fun passwordSignInRequiresAccessToken() = time.test {
        val svc = service { req ->
            if (req.path == "/System/Info/Public") json("""{"Id":"srv-1","ServerName":"Home"}""") else json("""{"User":{"Id":"user-7","Name":"edde"}}""")
        }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "pw") }
        assertEquals("Authentication response missing AccessToken or User", error.message)
    }

    @Test
    fun passwordSignInRequiresUserIdAndName() = time.test {
        val svc = service { json("""{"AccessToken":"tok","User":{"Id":"user-7"}}""") }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) }
        assertEquals("Authentication response missing User.Id or User.Name", error.message)
    }

    @Test
    fun passwordSignInRejectsNonJson() = time.test {
        val svc = service { respond("<html>", HttpStatusCode.OK) }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) }
        assertEquals("Authentication response was not JSON", error.message)
    }

    // isQuickConnectEnabled

    @Test
    fun quickConnectEnabledReadsABareTrue() = time.test {
        val svc = service { req ->
            assertEquals("/QuickConnect/Enabled", req.path)
            json("true")
        }
        assertTrue(svc.isQuickConnectEnabled("https://jf.example.com"))
    }

    @Test
    fun quickConnectEnabledReadsABareFalse() = time.test {
        assertFalse(service { json("false") }.isQuickConnectEnabled("https://jf.example.com"))
    }

    @Test
    fun quickConnectEnabledIsFalseOn404() = time.test {
        assertFalse(service { status(404) }.isQuickConnectEnabled("https://jf.example.com"))
    }

    @Test
    fun quickConnectEnabledIsFalseOnTransportError() = time.test {
        assertFalse(service { throw IOException("network down") }.isQuickConnectEnabled("https://jf.example.com"))
    }

    // initiateQuickConnect

    @Test
    fun initiateReturnsCodeAndSecretFromGet() = time.test {
        val svc = service { req ->
            assertEquals("/QuickConnect/Initiate", req.path)
            assertEquals("GET", req.method.value)
            json("""{"Code":"ABCDE","Secret":"sec-xyz"}""")
        }
        assertEquals(JellyfinQuickConnectInitiation("ABCDE", "sec-xyz"), svc.initiateQuickConnect("https://jf.example.com"))
    }

    @Test
    fun theQuickConnectSecretIsRedactedOnceLearnedAndBeforeItIsSent() = time.test {
        try {
            service { json("""{"Code":"ABCDE","Secret":"initiated-secret-1"}""") }.initiateQuickConnect("https://jf.example.com")
            assertFalse("initiated-secret-1" in LogRedaction.redactLiterals("poll secret=initiated-secret-1"))

            var sentBeforeRegistered = false
            val svc = service { req ->
                if (req.path == "/QuickConnect/Connect") sentBeforeRegistered = "custom-secret-2" in LogRedaction.redactLiterals("custom-secret-2")
                status(404)
            }
            assertNull(svc.authenticateByQuickConnect("https://jf.example.com", "custom-secret-2", serverInfo = serverInfo, timeout = 5.seconds))
            assertFalse(sentBeforeRegistered)
        } finally {
            LogRedaction.clear()
        }
    }

    @Test
    fun initiateFallsBackToPostOn405() = time.test {
        val methods = mutableListOf<String>()
        val svc = service { req ->
            assertEquals("/QuickConnect/Initiate", req.path)
            methods += req.method.value
            if (req.method.value == "GET") status(405) else json("""{"Code":"ABCDE","Secret":"sec-xyz"}""")
        }
        assertEquals("ABCDE", svc.initiateQuickConnect("https://jf.example.com").code)
        assertEquals(listOf("GET", "POST"), methods)
    }

    @Test
    fun initiateRejects403() = time.test {
        val error = assertFailsWith<MediaServerAuthException> { service { status(403) }.initiateQuickConnect("https://jf.example.com") }
        assertEquals("Quick Connect rejected by server", error.message)
        assertEquals(403, error.statusCode)
    }

    @Test
    fun initiateRejectsMalformedJson401() = time.test {
        val error = assertFailsWith<MediaServerAuthException> { service { status(401, "{bad json") }.initiateQuickConnect("https://jf.example.com") }
        assertEquals(401, error.statusCode)
    }

    @Test
    fun initiateRequiresCodeAndSecret() = time.test {
        val error = assertFailsWith<MediaServerAuthException> { service { json("""{"Code":"ABCDE"}""") }.initiateQuickConnect("https://jf.example.com") }
        assertEquals("Quick Connect response missing Code or Secret", error.message)
    }

    @Test
    fun initiatePreservesOtherHttpErrors() = time.test {
        val error = assertFailsWith<MediaServerHttpException> { service { status(500) }.initiateQuickConnect("https://jf.example.com") }
        assertEquals(500, error.statusCode)
    }

    // authenticateByQuickConnect

    @Test
    fun quickConnectReturnsAConnectionAfterApproval() = time.test {
        var polls = 0
        val svc = service { req ->
            when (req.path) {
                "/System/Info/Public" -> json("""{"Id":"srv-1","ServerName":"Home"}""")
                "/QuickConnect/Connect" -> {
                    assertEquals("sec", req.url.parameters["secret"])
                    polls++
                    json("""{"Authenticated":${polls >= 2}}""")
                }
                "/Users/AuthenticateWithQuickConnect" -> {
                    assertEquals("""{"Secret":"sec"}""", req.text)
                    json("""{"AccessToken":"tok-qc","User":{"Id":"user-9","Name":"edde","PrimaryImageTag":"quick-connect-avatar"}}""")
                }
                else -> status(404)
            }
        }

        val conn = assertNotNull(svc.authenticateByQuickConnect("https://jf.example.com", "sec", timeout = 30.seconds))

        assertEquals("tok-qc", conn.accessToken)
        assertEquals("user-9", conn.userId)
        assertEquals("srv-1/user-9", conn.id)
        assertEquals("quick-connect-avatar", conn.primaryImageTag)
        assertEquals(2, polls)
    }

    @Test
    fun quickConnectReturnsNullWhenTheSecretExpires() = time.test {
        for (body in listOf("", "{bad json")) {
            val svc = service { req ->
                when (req.path) {
                    "/System/Info/Public" -> json("""{"Id":"srv-1","ServerName":"Home"}""")
                    "/QuickConnect/Connect" -> status(404, body)
                    else -> status(500)
                }
            }
            assertNull(svc.authenticateByQuickConnect("https://jf.example.com", "sec", timeout = 5.seconds), body)
        }
    }

    @Test
    fun quickConnectReturnsNullWhenCancelled() = time.test {
        val svc = service { req -> if (req.path == "/System/Info/Public") json("""{"Id":"srv-1","ServerName":"Home"}""") else json("""{"Authenticated":false}""") }
        assertNull(svc.authenticateByQuickConnect("https://jf.example.com", "sec", timeout = 30.seconds, shouldCancel = { true }))
    }

    @Test
    fun quickConnectReturnsNullAtTheTimeout() = time.test {
        val svc = service { json("""{"Authenticated":false}""") }
        assertNull(svc.authenticateByQuickConnect("https://jf.example.com", "sec", serverInfo = serverInfo, timeout = 100.milliseconds))
    }

    @Test
    fun quickConnectPollRejects401() = time.test {
        for (body in listOf("", "{bad json")) {
            val svc = service { req -> if (req.path == "/System/Info/Public") json("""{"Id":"srv-1","ServerName":"Home"}""") else status(401, body) }
            val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByQuickConnect("https://jf.example.com", "sec", timeout = 5.seconds) }
            assertEquals("Quick Connect poll rejected by server", error.message)
            assertEquals(401, error.statusCode)
        }
    }

    @Test
    fun quickConnectExchangeRejects400() = time.test {
        for (body in listOf("", "{bad json")) {
            val svc = service { req ->
                when (req.path) {
                    "/QuickConnect/Connect" -> json("""{"Authenticated":true}""")
                    "/Users/AuthenticateWithQuickConnect" -> status(400, body)
                    else -> status(500)
                }
            }
            val error = assertFailsWith<MediaServerAuthException> {
                svc.authenticateByQuickConnect("https://jf.example.com", "sec", serverInfo = serverInfo, timeout = 5.seconds)
            }
            assertEquals("Quick Connect exchange rejected by server", error.message)
            assertEquals(400, error.statusCode)
        }
    }

    // Password and Quick Connect share behaviour

    @Test
    fun passwordAndQuickConnectExchangeShareTheTimeout() = time.test {
        val password = service(timeoutMs = 50) { awaitCancellation() }
        val quickConnect = service(timeoutMs = 50) { req ->
            if (req.path == "/QuickConnect/Connect") json("""{"Authenticated":true}""") else awaitCancellation()
        }
        val errors = listOf(
            assertFailsWith<MediaServerHttpException> { password.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) },
            assertFailsWith<MediaServerHttpException> { quickConnect.authenticateByQuickConnect("https://jf.example.com", "sec", serverInfo = serverInfo) },
        )
        for (error in errors) assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
    }

    @Test
    fun passwordAndQuickConnectExchangePreserveNonAuthHttpErrors() = time.test {
        val password = service { status(500) }
        val quickConnect = service { req -> if (req.path == "/QuickConnect/Connect") json("""{"Authenticated":true}""") else status(500) }
        val errors = listOf(
            assertFailsWith<MediaServerHttpException> { password.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) },
            assertFailsWith<MediaServerHttpException> { quickConnect.authenticateByQuickConnect("https://jf.example.com", "sec", serverInfo = serverInfo) },
        )
        for (error in errors) assertEquals(500, error.statusCode)
    }

    // Emby

    @Test
    fun embyQuickConnectSupportCheckSendsNoRequest() = time.test {
        val svc = service(MediaBrowserDialect.EMBY) { error("no request expected: ${it.url}") }
        assertFalse(svc.isQuickConnectEnabled("https://emby.example.com"))
    }

    @Test
    fun embyQuickConnectInitiationIsRejectedLocally() = time.test {
        val svc = service(MediaBrowserDialect.EMBY) { error("no request expected: ${it.url}") }
        val error = assertFailsWith<MediaServerAuthException> { svc.initiateQuickConnect("https://emby.example.com") }
        assertEquals("Quick Connect rejected by server", error.message)
        assertNull(error.statusCode)
    }

    @Test
    fun embyQuickConnectSignInIsRejectedLocally() = time.test {
        val svc = service(MediaBrowserDialect.EMBY) { error("no request expected: ${it.url}") }
        val error = assertFailsWith<MediaServerAuthException> { svc.authenticateByQuickConnect("https://emby.example.com", "quick-secret") }
        assertEquals("Quick Connect rejected by server", error.message)
        assertNull(error.statusCode)
    }

    @Test
    fun embyPasswordSignInBuildsAnEmbyConnection() = time.test {
        val svc = service(MediaBrowserDialect.EMBY) { req ->
            assertEquals("/Users/AuthenticateByName", req.path)
            json("""{"AccessToken":"tok-new","User":{"Id":"user-7","Name":"edde"}}""")
        }
        val connection = svc.authenticateByName("https://emby.example.com", "edde", "pw", serverInfo = serverInfo)
        assertEquals(MediaBrowserDialect.EMBY, connection.dialect)
        assertEquals(BackendKind.EMBY, connection.kind)
    }

    @Test
    fun detectedDialectOverridesThePickedOneAndUnknownKeepsIt() = time.test {
        suspend fun authenticate(publicInfo: String) = service { req ->
            when (req.path) {
                "/System/Info/Public" -> json(publicInfo)
                "/Users/AuthenticateByName" -> json("""{"AccessToken":"tok-new","User":{"Id":"user-7","Name":"edde"}}""")
                else -> status(404)
            }
        }.authenticateByName("https://server.example.com", "edde", "pw")

        val detected = authenticate("""{"LocalAddresses":[],"RemoteAddresses":[],"ServerName":"Emby Home","Version":"4.9.5.0","Id":"emby-server"}""")
        val unknown = authenticate("""{"ServerName":"Unknown Home","Id":"unknown-server","Version":"4.9.5.0"}""")

        assertEquals(MediaBrowserDialect.EMBY, detected.dialect)
        assertEquals(BackendKind.EMBY, detected.kind)
        assertEquals(MediaBrowserDialect.JELLYFIN, unknown.dialect)
        assertEquals(BackendKind.JELLYFIN, unknown.kind)
    }

    @Test
    fun passwordSignInIsWireIdenticalAcrossDialects() = time.test {
        suspend fun capture(dialect: MediaBrowserDialect): List<Triple<String, String, String>> {
            val seen = mutableListOf<Triple<String, String, String>>()
            service(dialect) { req ->
                seen += Triple(req.method.value, req.path, req.text)
                json("""{"AccessToken":"tok-new","User":{"Id":"user-7","Name":"edde"}}""")
            }.authenticateByName("https://server.example.com", "edde", "pw", serverInfo = serverInfo)
            return seen
        }
        val expected = listOf(Triple("POST", "/Users/AuthenticateByName", """{"Username":"edde","Pw":"pw"}"""))
        assertEquals(expected, capture(MediaBrowserDialect.JELLYFIN))
        assertEquals(expected, capture(MediaBrowserDialect.EMBY))
    }

    // request identity

    @Test
    fun passwordSignInSendsTheCompleteMediaBrowserHeader() = time.test {
        var request: HttpRequestData? = null
        service { req ->
            request = req
            json("""{"AccessToken":"tok-new","User":{"Id":"user-7","Name":"edde"}}""")
        }.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo)

        val req = assertNotNull(request)
        assertEquals("POST", req.method.value)
        assertEquals(header, req.headers[HttpHeaders.Authorization])
        assertEquals("application/json", req.body.contentType?.withoutParameters()?.toString())
    }

    @Test
    fun quickConnectSendsTheSameHeader() = time.test {
        var request: HttpRequestData? = null
        service { req ->
            request = req
            json("""{"Code":"ABCDE","Secret":"sec-xyz"}""")
        }.initiateQuickConnect("https://jf.example.com")

        val req = assertNotNull(request)
        assertEquals("GET", req.method.value)
        assertEquals(header, req.headers[HttpHeaders.Authorization])
    }

    @Test
    fun rejectsAnEmptyDeviceIdBeforeSendingARequest() = time.test {
        var requests = 0
        val svc = service(deviceId = "") {
            requests++
            status(500)
        }
        assertFailsWith<IllegalArgumentException> { svc.authenticateByName("https://jf.example.com", "edde", "pw", serverInfo = serverInfo) }
        assertFailsWith<IllegalArgumentException> { svc.initiateQuickConnect("https://jf.example.com") }
        assertFailsWith<IllegalArgumentException> { svc.authenticateByQuickConnect("https://jf.example.com", "sec", serverInfo = serverInfo) }
        assertEquals(0, requests)
    }
}
