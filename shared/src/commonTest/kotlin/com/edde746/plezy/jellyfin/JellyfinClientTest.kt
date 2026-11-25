package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.data.testData
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.image.PixelSize
import com.edde746.plezy.image.sizedImageUrl
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.servers.MediaBrowserClientEvents
import com.edde746.plezy.servers.MediaBrowserConnection
import io.ktor.http.Url
import io.ktor.utils.io.errors.IOException
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class JellyfinClientTest {
    private val data = testData()

    @AfterTest
    fun closeData() = data.close()

    private fun TestScope.client(
        server: JellyfinTestServer,
        connection: JellyfinConnection = server.connection(),
        updates: MutableList<JellyfinConnection> = mutableListOf(),
        onExhausted: () -> Unit = {},
    ) = JellyfinClient(
        connection = connection,
        http = server.http,
        identity = JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", connection.deviceId),
        cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { listOf(connection) }, { emptyList() })),
        scope = CoroutineScope(coroutineContext),
        favorites = data.liveTvFavorites,
        onConnectionUpdated = { updates += it },
        onAllEndpointsExhausted = onExhausted,
    )

    private fun publicInfo(id: String = "machine-1") = FakeResponse(body = """{"Id":"$id","ServerName":"Home","Version":"10.10.7"}""")

    // Both auth headers on every request, Content-Type exactly application/json.
    @Test fun everyRequestCarriesBothAuthHeaders() = runTest {
        val server = JellyfinTestServer { publicInfo() }
        client(server).getMachineIdentifier()
        val headers = server.single("/System/Info/Public").headers
        assertEquals("MediaBrowser Client=\"Plezy%20Linux\", Device=\"Test%20Box\", DeviceId=\"dev-1\", Version=\"1.2.3\", Token=\"tok-abc\"", headers["Authorization"])
        assertEquals("tok-abc", headers["X-Emby-Token"])
        assertEquals("application/json", headers["Accept"])
        val post = JellyfinTestServer()
        client(post).reportPlaybackStarted("item-1", kotlin.time.Duration.ZERO)
        assertEquals("application/json", post.single("/Sessions/Playing").headers["Content-Type"])
    }

    // Identity and watched policy.
    @Test fun identityAndWatchedPolicyFollowTheConnection() = runTest {
        val server = JellyfinTestServer()
        val jellyfin = client(server)
        assertEquals("machine-1", jellyfin.serverId.value)
        assertEquals("machine-1/user-1", jellyfin.cacheServerId)
        assertEquals("Home", jellyfin.serverName)
        assertEquals(BackendKind.JELLYFIN, jellyfin.backend)
        assertEquals(ServerCapabilities.JELLYFIN, jellyfin.capabilities)
        assertFalse(jellyfin.capabilities.continueWatchingRemoval)
        assertEquals(0.9, jellyfin.watchedThreshold)
        assertTrue(jellyfin.marksWatchedOnPlaybackStopped)
        assertTrue(jellyfin.streamHeaders.isEmpty())
        val emby = client(server, server.connection(MediaBrowserDialect.EMBY))
        assertEquals(BackendKind.EMBY, emby.backend)
        assertTrue(emby.capabilities.continueWatchingRemoval)
    }

    // Machine identifier.
    @Test fun machineIdentifierFallsBackToTheStoredId() = runTest {
        assertEquals("srv-live", client(JellyfinTestServer { publicInfo("srv-live") }).getMachineIdentifier())
        assertEquals("machine-1", client(JellyfinTestServer { FakeResponse(500) }).getMachineIdentifier())
        assertEquals("machine-1", client(JellyfinTestServer { throw IOException("down") }).getMachineIdentifier())
    }

    @Test fun theTokenAndEveryUrlAreRedactedBeforeTheFirstRequest() = runTest {
        val line = "token tok-redact-1 at https://primary.jf-redact.example/Items and https://lan.jf-redact.example:8096/Items"
        val secrets = listOf("tok-redact-1", "primary.jf-redact.example", "lan.jf-redact.example")
        var seen: String? = null
        val server = JellyfinTestServer {
            if (seen == null) seen = LogRedaction.redactLiterals(line)
            publicInfo()
        }
        val connection = server.connection(baseUrls = listOf("https://primary.jf-redact.example", "https://lan.jf-redact.example:8096"))
            .copy(baseUrl = "https://primary.jf-redact.example", accessToken = "tok-redact-1")
        LogRedaction.clear()
        try {
            assertTrue(secrets.all { it in LogRedaction.redactLiterals(line) }, "nothing is redacted before the client exists")
            client(server, connection).getMachineIdentifier()
        } finally {
            LogRedaction.clear()
        }
        val redacted = assertNotNull(seen)
        for (secret in secrets) assertFalse(secret in redacted, redacted)
    }

    // Health probe.
    @Test fun healthProbesTheCurrentUserRoute() = runTest {
        val jellyfin = JellyfinTestServer { FakeResponse(body = "{}") }
        assertEquals(HealthStatus.ONLINE, client(jellyfin).checkHealth())
        assertEquals("/Users/Me", jellyfin.requests.single().path)
        val emby = JellyfinTestServer { FakeResponse(body = "{}") }
        client(emby, emby.connection(MediaBrowserDialect.EMBY)).checkHealth()
        assertEquals("/Users/user-1", emby.requests.single().path)
    }

    @Test fun healthTellsRevokedTokensAndRefusedAccountsFromOutages() = runTest {
        assertEquals(HealthStatus.AUTH_ERROR, client(JellyfinTestServer { FakeResponse(401) }).checkHealth())
        assertEquals(HealthStatus.ACCESS_DENIED, client(JellyfinTestServer { FakeResponse(403) }).checkHealth())
        assertEquals(HealthStatus.OFFLINE, client(JellyfinTestServer { FakeResponse(500) }).checkHealth())
        assertEquals(HealthStatus.OFFLINE, client(JellyfinTestServer { throw IOException("down") }).checkHealth())
    }

    @Test fun healthRefreshesAdminStatusAndAvatarTagOnlyWhenChanged() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Policy":{"IsAdministrator":true},"PrimaryImageTag":" tag-2 "}""") }
        val updates = mutableListOf<JellyfinConnection>()
        val c = client(server, updates = updates)
        c.checkHealth()
        assertTrue(c.connection.isAdministrator)
        assertEquals("tag-2", c.connection.primaryImageTag)
        assertEquals(1, updates.size)
        c.checkHealth()
        assertEquals(1, updates.size)
        // A user DTO without Policy leaves the admin flag alone.
        server.handler = { FakeResponse(body = """{"PrimaryImageTag":"tag-2"}""") }
        c.checkHealth()
        assertTrue(c.connection.isAdministrator)
        assertEquals(1, updates.size)
        server.handler = { FakeResponse(body = """{"Policy":{"IsAdministrator":true}}""") }
        c.checkHealth()
        assertEquals(null, c.connection.primaryImageTag)
        assertEquals(2, updates.size)
    }

    // Fallback endpoints.
    @Test fun failsOverToAFallbackOfTheSameServerAndPersistsIt() = runTest {
        val primary = "https://primary.example.com"
        val fallback = "https://fallback.example.com"
        val server = JellyfinTestServer { req ->
            when {
                req.url.host == "primary.example.com" -> throw IOException("primary down")
                req.path == "/System/Info/Public" -> publicInfo()
                else -> FakeResponse(body = """{"Items":[]}""")
            }
        }
        val updates = mutableListOf<JellyfinConnection>()
        val c = client(server, server.connection().copy(baseUrl = primary, baseUrls = listOf(primary, fallback)), updates)
        c.fetchLibraries()
        assertEquals(fallback, c.connection.baseUrl)
        assertEquals(listOf(fallback, primary), c.connection.baseUrls)
        assertEquals(fallback, updates.last().baseUrl)
        val probes = server.requests.filter { it.path == "/System/Info/Public" }
        assertTrue(probes.isNotEmpty())
        // The public probe is unauthenticated.
        probes.forEach { assertFalse("X-Emby-Token" in it.headers || "Authorization" in it.headers) }
        assertEquals("fallback.example.com", server.requests.last().url.host)
    }

    @Test fun neverFailsOverToAnotherServerAndReportsExhaustion() = runTest {
        val server = JellyfinTestServer { req ->
            when {
                req.url.host == "primary.example.com" -> throw IOException("primary down")
                req.path == "/System/Info/Public" -> publicInfo("srv-other")
                else -> FakeResponse(body = """{"Items":[]}""")
            }
        }
        var exhausted = 0
        val c = client(
            server,
            server.connection().copy(baseUrl = "https://primary.example.com", baseUrls = listOf("https://primary.example.com", "https://other.example.com")),
            onExhausted = { exhausted++ },
        )
        kotlin.test.assertFails { c.fetchLibraries() }
        assertEquals("https://primary.example.com", c.connection.baseUrl)
        assertTrue(server.requests.none { it.url.host == "other.example.com" && it.path != "/System/Info/Public" })
        assertEquals(1, exhausted)
    }

    // Emby ignores a ParentId naming its Live TV view and answers with every library's items.
    @Test fun searchSkipsTheLiveTvViewSoAHitNamesItsOwnLibrary() = runTest {
        val server = JellyfinTestServer { request ->
            when (request.path) {
                "/Users/user-1/Views" -> FakeResponse(
                    body = """{"Items":[{"Id":"tv","Name":"Live TV","Type":"UserView","CollectionType":"livetv"},""" +
                        """{"Id":"movies","Name":"Movies","Type":"CollectionFolder","CollectionType":"movies"}]}""",
                )
                "/Items" -> FakeResponse(body = """{"Items":[{"Id":"movie-1","Name":"Film","Type":"Movie"}]}""")
                else -> FakeResponse()
            }
        }
        val emby = client(server, server.connection(MediaBrowserDialect.EMBY))
        val results = emby.searchItems("film", 100, emptySet())
        assertEquals(listOf("Movies"), results.map { it.libraryTitle })
        assertTrue(server.requests.none { it.query["ParentId"] == "tv" })
    }

    // Item images load without a token on both dialects: neither an item's image paths nor the URLs drawn from them
    // carry one, so none reaches a download row, a saved queue or an image cache key.
    @Test fun posterUrlsAreSizedAndCarryNoToken() = runTest {
        val server = JellyfinTestServer { request ->
            if (request.path.endsWith("/Items/movie-1")) FakeResponse(body = """{"Id":"movie-1","Type":"Movie","ImageTags":{"Primary":"abc"}}""") else FakeResponse()
        }
        for (dialect in MediaBrowserDialect.entries) {
            val client = client(server, server.connection(dialect))
            val movie = assertNotNull(client.fetchItem("movie-1"), "$dialect")
            assertEquals("http://jf.local:8096/Items/movie-1/Images/Primary?tag=abc", movie.thumbPath, "$dialect")
            val url = Url(sizedImageUrl(client, movie.thumbPath, ImageKind.POSTER, PixelSize(240, 360)))
            assertEquals(mapOf("tag" to "abc", "maxWidth" to "240", "maxHeight" to "360"), url.parameters.names().associateWith { url.parameters[it] }, "$dialect")
        }
    }

    @Test fun `a fresh client sends the account rewatching switch on its first Next Up request`() = runTest {
        val server = JellyfinTestServer { request ->
            if (request.path == "/DisplayPreferences/usersettings") {
                FakeResponse(body = """{"CustomPrefs":{"enableRewatchingInNextUp":"true"}}""")
            } else {
                FakeResponse(body = """{"Items":[]}""")
            }
        }
        client(server).fetchContinueWatching(5, emptySet())
        assertEquals("true", server.single("/Shows/NextUp").query["EnableRewatching"])
    }
}

class JellyfinConnectorTest {
    private val data = testData()
    private val base = JellyfinTestServer().connection().copy(baseUrls = listOf("http://jf.local:8096", "https://jf.example.com"))

    @AfterTest
    fun closeData() = data.close()

    private fun connector(server: JellyfinTestServer, scope: CoroutineScope) = JellyfinConnector(
        http = server.http,
        identity = { JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", it.deviceId) },
        cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { emptyList() }, { emptyList() })),
        scope = scope,
        favorites = data.liveTvFavorites,
        persist = {},
    )

    private class Events : MediaBrowserClientEvents {
        val updates = mutableListOf<MediaBrowserConnection>()
        override fun onAllEndpointsExhausted() = Unit
        override suspend fun onConnectionUpdated(updated: MediaBrowserConnection) {
            updates += updated
        }
    }

    @Test fun reusesALiveClientOnlyWhileItsBakedInFieldsMatch() = runTest {
        val c = connector(JellyfinTestServer(), this)
        assertTrue(c.canReuse(base, base.copy(baseUrls = base.baseUrls.reversed(), baseUrl = "https://jf.example.com", isAdministrator = true, serverName = "Renamed")))
        assertFalse(c.canReuse(base, base.copy(accessToken = "other")))
        assertFalse(c.canReuse(base, base.copy(deviceId = "other")))
        assertFalse(c.canReuse(base, base.copy(dialect = MediaBrowserDialect.EMBY)))
        assertFalse(c.canReuse(base, base.copy(baseUrls = base.baseUrls + "https://third.example.com")))
    }

    @Test fun racesStoredUrlsAndPersistsThePromotion() = runTest {
        val server = JellyfinTestServer { req ->
            if (req.url.host == "jf.local") throw IOException("lan unreachable")
            FakeResponse(body = """{"Id":"machine-1","ServerName":"Home 2","Version":"10.10.7"}""")
        }
        val events = Events()
        val client = connector(server, this).createClient(base, events)
        assertEquals("https://jf.example.com", client.connection.baseUrl)
        assertEquals(listOf("https://jf.example.com", "http://jf.local:8096"), client.connection.baseUrls)
        assertEquals("Home 2", client.connection.serverName)
        assertEquals(listOf<MediaBrowserConnection>(client.connection), events.updates)
    }

    @Test fun aHistoricWrongMachineAlternateIsDroppedAndAnUnreachableOneKept() = runTest {
        val stored = base.copy(baseUrls = listOf("http://jf.local:8096", "https://jf.example.com", "https://reused-host.example.com", "https://offline.example.com"))
        val server = JellyfinTestServer { req ->
            when (req.url.host) {
                "offline.example.com" -> throw IOException("unreachable")
                "reused-host.example.com" -> FakeResponse(body = """{"Id":"srv-other","ServerName":"Other"}""")
                else -> FakeResponse(body = """{"Id":"machine-1","ServerName":"Home"}""")
            }
        }
        val client = connector(server, this).createClient(stored, Events())
        assertFalse("https://reused-host.example.com" in client.connection.baseUrls)
        assertTrue("https://offline.example.com" in client.connection.baseUrls)
    }

    @Test fun aFailedPersistKeepsTheReconciledClient() = runTest {
        val server = JellyfinTestServer { req ->
            if (req.url.host == "jf.local") FakeResponse(body = """{"Id":"srv-other","ServerName":"Other"}""")
            else FakeResponse(body = """{"Id":"machine-1","ServerName":"Home"}""")
        }
        val failing = object : MediaBrowserClientEvents {
            override fun onAllEndpointsExhausted() = Unit
            override suspend fun onConnectionUpdated(updated: MediaBrowserConnection) = throw IllegalStateException("disk full")
        }
        val client = connector(server, this).createClient(base, failing)
        assertEquals(listOf("https://jf.example.com"), client.connection.baseUrls)
    }

    @Test fun aFailedRaceRunsOnTheStoredActiveUrlAndKeepsTheAlternatesStored() = runTest {
        val server = JellyfinTestServer { throw IOException("everything down") }
        val events = Events()
        val client = connector(server, this).createClient(base, events)
        assertEquals("http://jf.local:8096", client.connection.baseUrl)
        assertEquals(listOf("http://jf.local:8096"), client.connection.baseUrls)
        assertTrue(events.updates.isEmpty())
    }
}
