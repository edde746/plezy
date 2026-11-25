package com.edde746.plezy.jellyfin

import com.edde746.plezy.jellyfin.JellyfinLibraryEvents.SocketMessage
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.FakeLibraryEventConnection
import com.edde746.plezy.servers.LibraryEventConnection
import com.edde746.plezy.servers.LibraryEventConnector
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.async
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlinx.serialization.json.Json

class JellyfinLibraryEventsTest {
    private val libraryChanged =
        """{"MessageType":"LibraryChanged","Data":{"FoldersAddedTo":[],"FoldersRemovedFrom":[],"ItemsAdded":["a1"],"ItemsRemoved":[],"ItemsUpdated":[],
           "CollectionFolders":["f137a2dd21bbc1b99aa5c0f6bf02a805","1071671e7bffa0532e930debee501d2e"],"IsEmpty":false}}"""

    @Test
    fun socketUrlUsesDialectPathTokenParamAndKeepsProxyPrefix() {
        assertEquals(
            "wss://proxy.example/jellyfin/socket?ApiKey=access-1&deviceId=device-1",
            JellyfinLibraryEvents.socketUrl("https://proxy.example/jellyfin/", MediaBrowserDialect.JELLYFIN, "access-1", "device-1"),
        )
        assertEquals(
            "ws://emby.local:8096/embywebsocket?api_key=a%2Bb&deviceId=dev+1",
            JellyfinLibraryEvents.socketUrl("http://emby.local:8096", MediaBrowserDialect.EMBY, "a+b", "dev 1"),
        )
    }

    @Test
    fun embyCapabilitiesBodyMatchesTheServerContract() {
        assertEquals(
            Json.parseToJsonElement("""{"PlayableMediaTypes":["Video","Audio"],"SupportedCommands":[],"SupportsMediaControl":false,"SupportsSync":false}"""),
            JellyfinLibraryEvents.SESSION_CAPABILITIES,
        )
        assertEquals("""{"MessageType":"KeepAlive"}""", JellyfinLibraryEvents.KEEP_ALIVE)
    }

    @Test
    fun forceKeepAlivePingsAtHalfTheTimeoutWithinBounds() {
        assertEquals(SocketMessage.ForceKeepAlive(60), JellyfinLibraryEvents.parseFrame("""{"MessageId":"x","Data":60,"MessageType":"ForceKeepAlive"}"""))
        assertEquals(30.seconds, JellyfinLibraryEvents.keepAliveInterval(60))
        assertEquals(30.seconds, JellyfinLibraryEvents.keepAliveInterval(null))
        assertEquals(10.seconds, JellyfinLibraryEvents.keepAliveInterval(1))
        assertEquals(5.minutes, JellyfinLibraryEvents.keepAliveInterval(100_000))
    }

    @Test
    fun libraryChangedMapsFoldersAndFlags() {
        assertEquals(
            SocketMessage.LibraryChanged(setOf("f137a2dd21bbc1b99aa5c0f6bf02a805", "1071671e7bffa0532e930debee501d2e"), emptySet(), added = true),
            JellyfinLibraryEvents.parseFrame(libraryChanged),
        )
        assertEquals(
            SocketMessage.LibraryChanged(setOf("f1"), setOf("b44f", "6f91"), removed = true, updated = true),
            JellyfinLibraryEvents.parseFrame(
                """{"MessageType":"LibraryChanged","Data":{"ItemsRemoved":["b44f","6f91"],"FoldersRemovedFrom":[],"ItemsUpdated":["u"],"CollectionFolders":["f1"]}}""",
            ),
        )
    }

    @Test
    fun otherFramesAreIgnored() {
        assertNull(JellyfinLibraryEvents.parseFrame("""{"MessageType":"KeepAlive"}"""))
        assertNull(JellyfinLibraryEvents.parseFrame("""{"MessageType":"UserDataChanged","Data":{}}"""))
        assertNull(JellyfinLibraryEvents.parseFrame("not json"))
        assertNull(JellyfinLibraryEvents.parseFrame("[1]"))
    }

    /** Records each upgrade's URL and headers. */
    private class RecordingConnector : LibraryEventConnector {
        val upgrades = mutableListOf<Pair<String, Map<String, String>>>()
        val connection = FakeLibraryEventConnection()

        override suspend fun connect(url: String, headers: Map<String, String>): LibraryEventConnection {
            upgrades += url to headers
            return connection
        }
    }

    @Test
    fun embyRegistersCapabilitiesBeforeTheAuthenticatedUpgradeAndEmitsChanges() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        val connector = RecordingConnector()
        val socket = JellyfinLibraryEvents(server.core(MediaBrowserDialect.EMBY), connector, backgroundScope)
        val event = backgroundScope.async { socket.events.first() }
        socket.start()
        runCurrent()
        val registration = server.single("/Sessions/Capabilities/Full")
        assertEquals(JellyfinLibraryEvents.SESSION_CAPABILITIES, Json.parseToJsonElement(registration.body))
        val (url, headers) = connector.upgrades.single()
        assertEquals("ws://jf.local:8096/embywebsocket?api_key=tok-abc&deviceId=dev-1", url)
        assertEquals(server.core().identity.authorization("tok-abc"), headers["Authorization"])
        connector.connection.push(libraryChanged)
        runCurrent()
        assertEquals(
            LibraryChangeEvent(ServerId("machine-1"), setOf("f137a2dd21bbc1b99aa5c0f6bf02a805", "1071671e7bffa0532e930debee501d2e"), itemsAdded = true),
            event.await(),
        )
        socket.dispose()
    }

    @Test
    fun jellyfinConnectsWithoutRegistering() = runTest {
        val server = JellyfinTestServer()
        val connector = RecordingConnector()
        val socket = JellyfinLibraryEvents(server.core(), connector, backgroundScope)
        socket.start()
        runCurrent()
        assertTrue(server.requests.isEmpty())
        assertEquals("ws://jf.local:8096/socket?ApiKey=tok-abc&deviceId=dev-1", connector.upgrades.single().first)
        socket.dispose()
    }
}
