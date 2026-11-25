package com.edde746.plezy.servers

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.ServerId
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
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

private fun change(serverId: String = "server_1", removed: Set<String> = emptySet()) = LibraryChangeEvent(
    serverId = ServerId(serverId),
    removedItemIds = removed,
    itemsAdded = removed.isEmpty(),
    itemsRemoved = removed.isNotEmpty(),
)

/** A client whose every channel request hands out a fresh [FakeLibraryEventChannel], kept in [channels]. */
private class EventClient(id: String = "server_1", supportsEvents: Boolean = true) :
    FakeMediaBackend(id, capabilities = if (supportsEvents) ServerCapabilities.PLEX else ServerCapabilities(libraryChangeEvents = false)) {
    val channels = mutableListOf<FakeLibraryEventChannel>()

    init {
        libraryEventChannel = { FakeLibraryEventChannel().also { channels += it } }
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class LibraryEventServiceTest {
    private val servers = FakeOnlineServers()
    private val notifier = LibraryContentNotifier()
    private val deletions = DeletionNotifier()

    private fun TestScope.service() = LibraryEventService(servers, notifier, deletions, backgroundScope)

    private fun TestScope.received(): List<LibraryChangeEvent> {
        val events = mutableListOf<LibraryChangeEvent>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { notifier.events.collect { events += it } }
        return events
    }

    private fun TestScope.deleted(): List<DeletionEvent> {
        val events = mutableListOf<DeletionEvent>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { deletions.events.collect { events += it } }
        return events
    }

    private fun TestScope.emitStatus() {
        servers.emit()
        runCurrent()
    }

    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun startsOneChannelPerOnlineServerAndForwardsItsEvents() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()

        assertEquals(1, client.channels.size)
        assertEquals(1, client.channels.single().starts)

        val received = received()
        client.channels.single().emit(change())
        runCurrent()

        assertEquals("server_1", received.single().serverId.value)
        service.dispose()
    }

    @Test
    fun removedItemIdsFanOutAsInPlaceDeletionEvents() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        val deletions = deleted()
        val forwarded = received()

        client.channels.single().emit(change(removed = setOf("m1", "m2")))
        runCurrent()

        assertEquals(setOf("m1", "m2"), deletions.map { it.itemId }.toSet())
        assertTrue(deletions.all { it.serverId == ServerId("server_1") })
        assertTrue(deletions.none { it.isDownloadOnly }, "a server removal is not a download deletion")
        assertTrue(deletions.all { it.origin == DeletionOrigin.SERVER_PUSH })
        assertEquals(1, forwarded.size, "the coarse event still reaches the notifier")
        service.dispose()
    }

    @Test
    fun bulkRemovalsSkipPerItemDeletionEventsAndRelyOnTheRefetch() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        val deletions = deleted()
        val forwarded = received()

        client.channels.single().emit(change(removed = (0 until 30).mapTo(LinkedHashSet()) { "bulk-$it" }))
        runCurrent()

        assertTrue(deletions.isEmpty(), "past the cap the coarse refetch owns the update")
        assertEquals(1, forwarded.size)
        service.dispose()
    }

    @Test
    fun skipsServersWithoutTheCapabilityOrWithoutAChannel() = runTest {
        val incapable = EventClient("server_nocap", supportsEvents = false).also(servers::register)
        FakeMediaBackend("server_nochannel").also(servers::register)
        val service = service()
        emitStatus()

        assertTrue(incapable.channels.isEmpty())
        service.dispose()
    }

    @Test
    fun anOfflineTransitionDisposesTheChannelAndBackOnlineRecreatesIt() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        assertEquals(1, client.channels.size)

        servers.setOnline(client.serverId, false)
        emitStatus()
        assertTrue(client.channels.single().disposed)

        servers.setOnline(client.serverId, true)
        emitStatus()
        assertEquals(2, client.channels.size)
        assertEquals(1, client.channels.last().starts)
        service.dispose()
    }

    @Test
    fun onlyServersVisibleToTheActiveProfileGetAChannel() = runTest {
        val visible = EventClient("server_1").also(servers::register)
        val hidden = EventClient("server_2").also(servers::register)
        servers.visible = setOf(ServerId("server_1"))
        val service = service()
        emitStatus()

        assertEquals(1, visible.channels.single().starts)
        assertTrue(hidden.channels.isEmpty())

        // A visibility change alone reconciles.
        servers.visible = setOf(ServerId("server_2"))
        emitStatus()
        assertTrue(visible.channels.single().disposed)
        assertEquals(1, hidden.channels.single().starts)
        service.dispose()
    }

    @Test
    fun aReplacedClientTearsDownTheOldChannelAndStartsAFreshOne() = runTest {
        val original = EventClient().also(servers::register)
        val service = service()
        emitStatus()

        val replacement = EventClient().also(servers::register)
        emitStatus()

        assertTrue(original.channels.single().disposed)
        assertEquals(1, replacement.channels.size)
        assertEquals(1, replacement.channels.single().starts)
        service.dispose()
    }

    @Test
    fun suspendStopsChannelsAndResumeRebuildsThem() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()

        service.suspend()
        assertTrue(client.channels.single().disposed)

        // Status emissions while suspended must not resurrect channels.
        emitStatus()
        assertEquals(1, client.channels.size)

        service.resume()
        assertEquals(2, client.channels.size)
        assertEquals(1, client.channels.last().starts)
        service.dispose()
    }

    @Test
    fun disposeTearsEverythingDownAndIgnoresLaterStatusEmissions() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()

        service.dispose()
        assertTrue(client.channels.single().disposed)

        emitStatus()
        service.resume()
        runCurrent()
        assertEquals(1, client.channels.size)
    }

    @Test
    fun aRetainedChannelIsReArmedOnEverySync() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()

        service.resume()
        emitStatus()

        val channel = client.channels.single()
        assertEquals(3, channel.starts, "start() re-arms a channel that ran out of retries; a no-op otherwise")
        assertFalse(channel.disposed)
        service.dispose()
    }

    // Authentication sessions.

    @Test
    fun aReauthenticatedClientGetsAFreshChannelOnTheNextSync() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        val first = client.channels.single()

        client.authenticationSessionId = Any()
        emitStatus()

        assertTrue(first.disposed)
        assertEquals(2, client.channels.size)
        assertEquals(1, client.channels.last().starts)
        service.dispose()
    }

    @Test
    fun anUnchangedSessionKeepsTheHealthyChannel() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        val received = received()

        emitStatus()
        client.channels.single().emit(change())
        runCurrent()

        assertEquals(1, client.channels.size)
        assertFalse(client.channels.single().disposed)
        assertEquals(1, received.size)
        service.dispose()
    }

    @Test
    fun oldFramesCannotCrossTheCommitToStatusInterval() = runTest {
        val client = EventClient().also(servers::register)
        val service = service()
        emitStatus()
        val received = received()
        val deletions = deleted()
        val old = client.channels.single()

        // The commit lands before the manager's batched status emission.
        client.authenticationSessionId = Any()
        old.emit(change(removed = setOf("a-after-b-commit")))
        runCurrent()

        assertTrue(received.isEmpty())
        assertTrue(deletions.isEmpty())
        assertTrue(old.disposed, "the old session's channel is retired at once")

        emitStatus()
        client.channels.last().emit(change(removed = setOf("b-current")))
        runCurrent()
        assertEquals(listOf("b-current"), deletions.map { it.itemId })
        service.dispose()
    }

    @Test
    fun aPendingCoalescedEventIsStaleEvenAfterReturningToTheSameCredentials() = runTest {
        val connector = FakeLibraryEventConnector()
        val socket = TestLibraryEventSocket(connector, backgroundScope, testScheduler.timeSource, debounce = 10.seconds)
        val client = FakeMediaBackend("plex_1").apply {
            libraryEventChannel = { socket }
            servers.register(this)
        }
        val service = service()
        val received = received()
        val deletions = deleted()
        service.sync()
        runCurrent()

        // One burst: the leading event and a trailing removal pending in the window.
        connector.connections.single().push("remove:movies:a-leading")
        connector.connections.single().push("remove:movies:a-pending")
        runCurrent()
        assertEquals(listOf("a-leading"), deletions.map { it.itemId })

        // A → B → A installs a new session object even though the credentials end where they started.
        client.authenticationSessionId = Any()

        elapse(10.seconds)
        assertEquals(listOf("a-leading"), deletions.map { it.itemId })
        assertEquals(1, received.size)
        assertTrue(connector.connections.single().closed)
        service.dispose()
    }

    // Push recovery through the service.

    @Test
    fun aStatusEmissionRecoversExhaustedPush() = runTest {
        recoversExhaustedPush(foregroundResume = false)
    }

    @Test
    fun foregroundResumeWithoutSuspensionRecoversExhaustedPush() = runTest {
        recoversExhaustedPush(foregroundResume = true)
    }

    private fun TestScope.recoversExhaustedPush(foregroundResume: Boolean) {
        val connector = FakeLibraryEventConnector()
        var available = false
        connector.connect = { if (available) FakeLibraryEventConnection() else connector.refuse() }
        val socket = TestLibraryEventSocket(
            connector,
            backgroundScope,
            testScheduler.timeSource,
            debounce = Duration.ZERO,
            retryBaseDelay = 5.seconds,
            maxConnectAttempts = 2,
        )
        FakeMediaBackend("plex_1").apply {
            libraryEventChannel = { socket }
            servers.register(this)
        }
        val service = service()
        val received = received()
        service.sync()
        runCurrent()
        elapse(15.seconds)
        assertFalse(socket.isRunning)
        assertEquals(3, connector.attempts)
        elapse(5.minutes)
        assertEquals(3, connector.attempts, "the retry budget really is exhausted")

        available = true
        // Desktop foreground needs neither a suspension nor a status transition.
        if (foregroundResume) service.resume() else servers.emit()
        runCurrent()
        connector.connections.single().push("add:recovered")
        runCurrent()
        assertEquals(setOf("recovered"), received.single().libraryIds)

        service.resume()
        service.resume()
        runCurrent()
        connector.connections.single().push("add:still-live")
        runCurrent()
        assertEquals(setOf("still-live"), received.last().libraryIds)
        assertEquals(4, connector.attempts, "foreground must not restart an active transport")
        service.dispose()
    }

    @Test
    fun foregroundResumePreservesAnInProgressReconnectBackoff() = runTest {
        val connector = FakeLibraryEventConnector()
        connector.connect = { if (connector.attempts == 1) connector.refuse() else FakeLibraryEventConnection() }
        val socket = TestLibraryEventSocket(connector, backgroundScope, testScheduler.timeSource, debounce = Duration.ZERO)
        val client = FakeMediaBackend("plex_1").apply {
            libraryEventChannel = { socket }
            servers.register(this)
        }
        val service = service()
        val received = received()
        service.sync()
        runCurrent()
        elapse(2.seconds)

        service.resume()
        runCurrent()
        assertEquals(1, connector.attempts, "resume must not bypass the existing backoff")
        elapse(3.seconds)
        connector.connections.single().push("add:retry")
        runCurrent()

        assertEquals(setOf("retry"), received.single().libraryIds)
        assertEquals(2, connector.attempts, "resume must not postpone the existing retry either")
        service.dispose()
    }
}
