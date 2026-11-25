package com.edde746.plezy.plex

import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.FakeLibraryEventConnector
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

@OptIn(ExperimentalCoroutinesApi::class)
class PlexLibraryEventSocketTest {
    private val connector = FakeLibraryEventConnector()

    private fun TestScope.socket(baseUrl: String = "http://plex.test:32400", token: String? = "token-1") = PlexLibraryEventSocket(
        ServerId("plex_1"),
        baseUrl = { baseUrl },
        token = { token },
        connector = connector,
        scope = backgroundScope,
        timeSource = testScheduler.timeSource,
        debounce = 100.milliseconds,
    )

    private fun TestScope.collect(socket: PlexLibraryEventSocket): List<LibraryChangeEvent> {
        val events = mutableListOf<LibraryChangeEvent>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { socket.events.collect { events += it } }
        return events
    }

    private fun entry(state: Int, sectionId: String? = "1", type: Int = 1) =
        """{"identifier":"com.plexapp.plugins.library",${sectionId?.let { "\"sectionID\":\"$it\"," } ?: ""}"itemID":"10141","type":$type,"state":$state}"""

    private fun timeline(vararg entries: String) = """{"NotificationContainer":{"type":"timeline","TimelineEntry":[${entries.joinToString(",")}]}}"""

    private val playing = """{"NotificationContainer":{"type":"playing","PlaySessionStateNotification":[{"sessionKey":"1","state":"playing"}]}}"""

    @Test
    fun `websocket URLs keep a reverse proxy path prefix and carry the token`() = runTest {
        assertEquals("wss://proxy.example/plex/:/websockets/notifications?X-Plex-Token=token-1", socket("https://proxy.example/plex").buildUrl())
        assertEquals("ws://192.168.1.5:32400/:/websockets/notifications?X-Plex-Token=token-1", socket("http://192.168.1.5:32400/").buildUrl())
        assertEquals("ws://plex.test:32400/:/websockets/notifications", socket(token = null).buildUrl())
    }

    @Test
    fun `the first settled entry emits immediately and the rest of the flood coalesces`() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push(playing)
        for (state in 0..4) connection.push(timeline(entry(state)))
        connection.push(timeline(entry(5)))
        connection.push(timeline(entry(5)))
        connection.push(timeline(entry(5, sectionId = "2")))
        connection.push("""{"NotificationContainer":{"type":"timeline","TimelineEntry":[{"identifier":"com.plexapp.plugins.playlists","state":5}]}}""")
        runCurrent()

        val first = events.single()
        assertEquals(setOf("1"), first.libraryIds)
        assertTrue(first.itemsAdded)
        assertTrue(first.itemsUpdated)
        assertFalse(first.itemsRemoved)

        advanceTimeBy(300.milliseconds)
        runCurrent()
        assertEquals(2, events.size)
        assertEquals(setOf("1", "2"), events[1].libraryIds)
        channel.dispose()
    }

    @Test
    fun `an entry without a section widens its window to the whole server`() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push(timeline(entry(5, sectionId = "9")))
        connection.push(timeline(entry(5, sectionId = null)))
        connection.push(timeline(entry(5, sectionId = "1")))
        runCurrent()
        advanceTimeBy(300.milliseconds)
        runCurrent()

        assertEquals(2, events.size)
        assertTrue(events[1].targetsWholeServer)
        assertTrue(events[1].libraryIds.isEmpty())
        channel.dispose()
    }

    @Test
    fun `a settled deletion reports the removed item`() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()

        connector.connections.single().push(timeline(entry(5, type = -1)))
        runCurrent()

        val event = events.single()
        assertTrue(event.itemsRemoved)
        assertFalse(event.itemsAdded)
        assertEquals(setOf("10141"), event.removedItemIds)
        channel.dispose()
    }

    @Test
    fun `a malformed frame does not kill the channel`() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push("this is not json")
        connection.push("[1,2,3]")
        connection.push(timeline(entry(5)))
        runCurrent()

        assertTrue(events.single().itemsAdded)
        channel.dispose()
    }
}
