package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

private fun ids(vararg values: String) = values.mapTo(mutableSetOf()) { ServerId(it) }

private fun searchItem(serverId: String? = null, libraryId: String? = null, libraryTitle: String? = null) = MediaItem(
    id = "item",
    backend = BackendKind.PLEX,
    kind = MediaKind.MOVIE,
    serverId = serverId,
    libraryId = libraryId,
    libraryTitle = libraryTitle,
)

private fun server(id: String, vararg libraries: Pair<String, String>) =
    FakeLibraryServer(ServerId(id), libraries.map { (libId, title) -> serverLib(id, libId, title) })

@OptIn(ExperimentalCoroutinesApi::class)
class LibrariesStoreTest {
    private val events = MutableSharedFlow<LibraryChangeEvent>(extraBufferCapacity = 16)
    private val prefs = FakeLibraryPreferences()

    private fun TestScope.store(
        servers: FakeLibraryServers? = null,
        isProfileBinding: () -> Boolean = { false },
    ): LibrariesStore {
        val store = LibrariesStore(prefs, backgroundScope, events, isProfileBinding = isProfileBinding)
        servers?.let(store::initialize)
        runCurrent()
        return store
    }

    /** Counts state publications from now on. */
    private fun TestScope.updates(store: LibrariesStore): () -> Int {
        var count = -1
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.state.collect { count++ } }
        return { count }
    }

    private fun LibrariesStore.titles() = libraries.map { it.title }

    @Test
    fun `starts with initial empty state`() = runTest {
        val p = store()
        assertTrue(p.libraries.isEmpty())
        assertFalse(p.hasLibraries)
        assertFalse(p.isLoading)
        assertFalse(p.hasLoaded)
        assertEquals(LibrariesLoadState.INITIAL, p.loadState)
        assertNull(p.errorMessage)
    }

    @Test
    fun `loadLibraries before initialize is a no op`() = runTest {
        val p = store()
        val notified = updates(p)
        p.loadLibraries()
        assertEquals(LibrariesLoadState.INITIAL, p.loadState)
        assertTrue(p.libraries.isEmpty())
        assertEquals(0, notified())
    }

    @Test
    fun `refresh before initialize is a no op`() = runTest {
        val p = store()
        val notified = updates(p)
        p.refresh()
        assertEquals(LibrariesLoadState.INITIAL, p.loadState)
        assertEquals(0, notified())
    }

    @Test
    fun `updateLibraryOrder updates the list and notifies and persists the order`() = runTest {
        val p = store()
        val notified = updates(p)
        val libs = listOf(serverLib("srv", "1", "A"), serverLib("srv", "2", "B"), serverLib("srv", "3", "C"))

        p.updateLibraryOrder(libs)
        assertEquals(listOf("A", "B", "C"), p.titles())
        assertEquals(1, notified())
        assertEquals(libs.map { it.globalKey }, prefs.libraryOrder())
    }

    @Test
    fun `saved order puts known keys first and appends the rest in fetch order`() {
        val libs = listOf(serverLib("s", "1", "A"), serverLib("s", "2", "B"), serverLib("s", "3", "C"))
        assertEquals(listOf("C", "A", "B"), applyLibraryOrder(libs, listOf("s:3", "gone:9", "s:1")).map { it.title })
        assertEquals(libs, applyLibraryOrder(libs, emptyList()))
        assertEquals(libs, applyLibraryOrder(libs, null))
    }

    @Test
    fun `without a saved order the libraries follow the server order whichever server answers first`() = runTest {
        val order = listOf(ServerId("jellyfin"), ServerId("emby"))
        for ((first, second) in listOf("emby" to "jellyfin", "jellyfin" to "emby")) {
            val servers = FakeLibraryServers()
            val p = LibrariesStore(prefs, backgroundScope, events, serverOrder = { order })
            p.initialize(servers)
            servers.add(server(first, "1" to "Movies $first", "2" to "Shows $first"))
            p.syncToOnlineServers(ids(first))
            servers.add(server(second, "1" to "Movies $second", "2" to "Shows $second"))
            p.syncToOnlineServers(ids(first, second))

            assertEquals(listOf("Movies jellyfin", "Shows jellyfin", "Movies emby", "Shows emby"), p.titles(), "$first answered first")
            assertEquals(order, p.librariesServerOrder)
        }
    }

    @Test
    fun `a saved order places the servers where their first library is`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("jellyfin", "1" to "Movies jellyfin", "2" to "Shows jellyfin"))
        servers.add(server("emby", "1" to "Movies emby"))
        val p = LibrariesStore(prefs, backgroundScope, events, serverOrder = { listOf(ServerId("jellyfin"), ServerId("emby")) })
        p.initialize(servers)
        p.syncToOnlineServers(ids("jellyfin", "emby"))

        p.updateLibraryOrder(listOf(serverLib("emby", "1", "Movies emby"), serverLib("jellyfin", "2", "Shows jellyfin")))
        p.loadLibraries()

        assertEquals(listOf("Movies emby", "Shows jellyfin", "Movies jellyfin"), p.titles())
        assertEquals(listOf(ServerId("emby"), ServerId("jellyfin")), p.librariesServerOrder)
    }

    @Test
    fun `clear resets state to initial and notifies`() = runTest {
        val p = store()
        p.updateLibraryOrder(listOf(serverLib("srv", "1", "L"), serverLib("srv", "2", "L")))
        assertEquals(2, p.libraries.size)
        val notified = updates(p)

        p.clear()
        assertTrue(p.libraries.isEmpty())
        assertFalse(p.hasLibraries)
        assertEquals(LibrariesLoadState.INITIAL, p.loadState)
        assertNull(p.errorMessage)
        assertEquals(1, notified())
    }

    @Test
    fun `mutating methods after dispose are no ops`() = runTest {
        val p = store()
        p.dispose()
        p.clear()
        p.updateLibraryOrder(listOf(serverLib("srv", "1", "L")))
        assertTrue(p.libraries.isEmpty())
        assertNull(prefs.libraryOrder())
    }

    @Test
    fun `libraryByGlobalKey resolves loaded libraries and misses return null`() = runTest {
        val p = store()
        assertNull(p.libraryByGlobalKey("A:1"))
        p.updateLibraryOrder(listOf(serverLib("A", "1", "Movies"), serverLib("A", "2", "Anime")))
        assertEquals("Anime", p.libraryByGlobalKey("A:2")?.title)
        assertNull(p.libraryByGlobalKey("A:999"))
        assertNull(p.libraryByGlobalKey("2"), "bare library ids are not global keys")
    }

    @Test
    fun `libraryCountForServer counts per server and is 0 while unloaded`() = runTest {
        val p = store()
        assertEquals(0, p.libraryCountForServer("A"))
        p.updateLibraryOrder(listOf(serverLib("A", "1", "Movies"), serverLib("A", "2", "Anime"), serverLib("B", "1", "Shows")))
        assertEquals(2, p.libraryCountForServer("A"))
        assertEquals(1, p.libraryCountForServer("B"))
        assertEquals(0, p.libraryCountForServer("C"))
    }

    @Test
    fun `lookups stay current across a delta load and clear`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A", "1" to "Movies A", "2" to "Shows A"))
        val p = store(servers)

        p.syncToOnlineServers(ids("A"))
        assertEquals(2, p.libraryCountForServer("A"))
        assertEquals("Movies A", p.libraryByGlobalKey("A:1")?.title)

        servers.add(server("B", "1" to "Movies B"))
        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(1, p.libraryCountForServer("B"))
        assertEquals("Movies B", p.libraryByGlobalKey("B:1")?.title)
        assertEquals(2, p.libraryCountForServer("A"))

        p.clear()
        assertEquals(0, p.libraryCountForServer("A"))
        assertNull(p.libraryByGlobalKey("A:1"))
    }

    @Test
    fun `libraryLabelFor labels only items on a multi library server`() = runTest {
        val p = store()
        p.updateLibraryOrder(listOf(serverLib("A", "1", "Movies"), serverLib("A", "2", "Anime"), serverLib("B", "1", "Shows")))
        assertEquals("Anime", p.libraryLabelFor(searchItem("A", "2", "Anime")))
        assertNull(p.libraryLabelFor(searchItem("B", "1", "Shows")), "attribution on a single-library server is noise")
    }

    @Test
    fun `libraryLabelFor is null for serverless items and while unloaded`() = runTest {
        val p = store()
        assertNull(p.libraryLabelFor(searchItem("A", "1", "Movies")))
        p.updateLibraryOrder(listOf(serverLib("A", "1", "Movies"), serverLib("A", "2", "Anime")))
        assertNull(p.libraryLabelFor(searchItem(libraryId = "1", libraryTitle = "Movies")))
    }

    @Test
    fun `libraryLabelFor resolves a missing title through the loaded library`() = runTest {
        val p = store()
        p.updateLibraryOrder(listOf(serverLib("A", "1", "Movies"), serverLib("A", "2", "Anime")))
        assertEquals("Anime", p.libraryLabelFor(searchItem("A", "2")))
        assertNull(p.libraryLabelFor(searchItem("A", "9")))
        assertNull(p.libraryLabelFor(searchItem("A")))
    }

    @Test
    fun `loads when a server first comes online`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)

        p.syncToOnlineServers(ids("A"))

        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
        assertEquals(1, a.calls)
    }

    @Test
    fun `does not reload when the online set is unchanged`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A"))
        p.syncToOnlineServers(ids("A"))
        assertEquals(1, a.calls)
    }

    @Test
    fun `delta loads only a server that connects after the first load`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A"))
        assertEquals(listOf("Movies A"), p.titles())

        val b = servers.add(server("B", "1" to "Shows B"))
        p.syncToOnlineServers(ids("A", "B"))

        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
        assertEquals(1, a.calls, "an already-loaded server is not refetched")
        assertEquals(1, b.calls)
    }

    @Test
    fun `a background reload over existing data never surfaces a loading state`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A"))
        assertTrue(p.hasLoaded)
        val sawLoading = mutableListOf<Boolean>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { p.state.collect { sawLoading += it.isLoading } }

        servers.add(server("B", "1" to "Shows B"))
        p.syncToOnlineServers(ids("A", "B"))
        p.loadLibraries()

        assertFalse(true in sawLoading)
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
    }

    @Test
    fun `a server whose fetch fails is retried on the next sync and not cached as loaded`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A", "1" to "Movies A"))
        val b = servers.add(server("B", "1" to "Shows B")).apply { error = IllegalStateException("transient") }
        val p = store(servers)

        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(listOf("Movies A"), p.titles())

        b.error = null
        p.syncToOnlineServers(ids("A", "B"))
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
    }

    @Test
    fun `servers that answered with libraries or failing are told apart from those still asked`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A", "1" to "Movies A"))
        servers.add(server("B", "1" to "Shows B")).apply { error = IllegalStateException("transient") }
        val p = store(servers)

        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(ids("A", "B"), p.state.value.answeredServerIds)

        servers.add(server("C", "1" to "Movies C"))
        p.syncToOnlineServers(ids("A", "B", "C"))
        assertEquals(ids("A", "B", "C"), p.state.value.answeredServerIds)

        p.clear()
        assertEquals(emptySet(), p.state.value.answeredServerIds)
    }

    @Test
    fun `does not reload when the online set shrinks`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val b = servers.add(server("B", "1" to "Shows B"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A", "B"))
        p.syncToOnlineServers(ids("B"))
        assertEquals(1, a.calls)
        assertEquals(1, b.calls)
    }

    @Test
    fun `a zero library server is marked loaded and does not retrigger`() = runTest {
        val servers = FakeLibraryServers()
        val c = servers.add(server("C"))
        val p = store(servers)

        p.syncToOnlineServers(ids("C"))
        assertTrue(p.hasLoaded)
        assertTrue(p.libraries.isEmpty())
        p.syncToOnlineServers(ids("C"))
        assertEquals(1, c.calls)
    }

    @Test
    fun `a server appearing mid load is still picked up`() = runTest {
        val servers = FakeLibraryServers()
        val gate = CompletableDeferred<Unit>()
        val a = servers.add(server("A", "1" to "Movies A").apply { this.gate = gate })
        val p = store(servers)

        val inFlight = async(start = CoroutineStart.UNDISPATCHED) { p.syncToOnlineServers(ids("A")) }
        servers.add(server("B", "1" to "Shows B"))
        val queued = async(start = CoroutineStart.UNDISPATCHED) { p.syncToOnlineServers(ids("A", "B")) }

        gate.complete(Unit)
        inFlight.await()
        queued.await()

        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
        assertEquals(2, a.calls, "a second pass runs for the larger set")
    }

    @Test
    fun `online server deltas arriving mid pass are unioned into one trailing pass`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A"))

        val gate = CompletableDeferred<Unit>()
        val b = servers.add(server("B", "1" to "Shows B").apply { this.gate = gate })
        val firstDelta = async(start = CoroutineStart.UNDISPATCHED) { p.syncToOnlineServers(ids("A", "B")) }
        assertEquals(1, b.calls)

        val c = servers.add(server("C", "1" to "Movies C"))
        val trailingDelta = async(start = CoroutineStart.UNDISPATCHED) { p.syncToOnlineServers(ids("A", "B", "C")) }

        gate.complete(Unit)
        firstDelta.await()
        trailingDelta.await()

        assertEquals(1, a.calls)
        assertEquals(1, b.calls, "the trailing delta drops ids committed by the active pass")
        assertEquals(1, c.calls)
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B", "Movies C")))
    }

    @Test
    fun `a coalesced call gets its trailing pass after the in flight pass fails`() = runTest {
        val servers = FakeLibraryServers()
        val gate = CompletableDeferred<Unit>()
        val a = servers.add(
            server("A", "1" to "Movies A").apply {
                this.gate = gate
                errorForCall = { call ->
                    if (call == 1) MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "first pass cancelled") else null
                }
            },
        )
        val p = store(servers)

        val first = async(start = CoroutineStart.UNDISPATCHED) { p.loadLibraries() }
        val coalesced = async(start = CoroutineStart.UNDISPATCHED) { p.loadLibraries() }
        assertEquals(1, a.calls)

        gate.complete(Unit)
        first.await()
        coalesced.await()

        assertEquals(2, a.calls)
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `dispose during an in flight coalesced load prevents trailing work and commits`() = runTest {
        val servers = FakeLibraryServers()
        val gate = CompletableDeferred<Unit>()
        val a = servers.add(server("A", "1" to "Movies A").apply { this.gate = gate })
        val p = store(servers)
        val notified = updates(p)

        val first = async(start = CoroutineStart.UNDISPATCHED) { p.loadLibraries() }
        val coalesced = async(start = CoroutineStart.UNDISPATCHED) { p.loadLibraries() }
        assertEquals(1, a.calls)
        assertEquals(1, notified(), "the loading state was published before disposal")

        p.dispose()
        gate.complete(Unit)
        first.await()
        coalesced.await()

        assertEquals(1, a.calls, "the queued trailing pass was discarded")
        assertTrue(p.libraries.isEmpty(), "the completed fetch was not committed after disposal")
        assertEquals(1, notified())

        p.loadLibraries()
        p.syncToOnlineServers(ids("A"))
        assertEquals(1, a.calls, "entry points after dispose are no-ops")
    }

    @Test
    fun `clear resets tracking so the next sync reloads`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A"))
        p.clear()
        assertFalse(p.hasLoaded)
        p.syncToOnlineServers(ids("A"))
        assertEquals(2, a.calls)
    }

    @Test
    fun `a first load disrupted by cancellations stays loading instead of flashing empty`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A")).apply {
            error = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "HTTP client is closing")
        }
        val p = store(servers)

        p.loadLibraries()
        assertTrue(p.isLoading)
        assertFalse(p.hasLoaded)
        assertNull(p.errorMessage)

        a.error = null
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `a zero success first load during profile binding stays loading`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A")).apply { error = IllegalStateException("probe timed out") }
        var binding = true
        val p = store(servers, isProfileBinding = { binding })

        p.loadLibraries()
        assertTrue(p.isLoading)
        assertFalse(p.hasLoaded)

        binding = false
        a.error = null
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `a settled zero success first load still commits loaded empty`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A")).apply { error = IllegalStateException("connection refused") }
        val p = store(servers)

        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertTrue(p.libraries.isEmpty())
        assertNull(p.errorMessage)
    }

    @Test
    fun `a failed first load shows an error and an in place one keeps the list`() = runTest {
        var fail = true
        val p = store()
        p.initialize { _ ->
            if (fail) throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "down")
            LibraryAggregationResult(listOf(serverLib("A", "1", "Movies A")), ids("A"), emptySet(), emptySet())
        }

        p.loadLibraries()
        assertEquals(LibrariesLoadState.ERROR, p.loadState)
        assertTrue(!p.errorMessage.isNullOrEmpty())

        fail = false
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertNull(p.errorMessage)

        fail = true
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `a totally failed silent refresh keeps the last good list`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val p = store(servers)
        p.loadLibraries()
        assertEquals(listOf("Movies A"), p.titles())

        a.error = IllegalStateException("offline")
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())

        // The kept list does not cover the failed server: the next sync refetches it.
        a.error = null
        val before = a.calls
        p.syncToOnlineServers(ids("A"))
        assertEquals(before + 1, a.calls)
    }

    @Test
    fun `a partially failed silent refresh retains the failed servers previous libraries`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val b = servers.add(server("B", "1" to "Shows B"))
        val p = store(servers)
        p.loadLibraries()
        assertEquals(setOf("Movies A", "Shows B"), p.titles().toSet())

        a.libraries = listOf(serverLib("A", "2", "Movies A v2"))
        b.error = IllegalStateException("timed out")
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(setOf("Movies A v2", "Shows B"), p.titles().toSet())

        b.error = null
        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(2, a.calls, "A was committed as loaded by the partial refresh")
        assertEquals(3, b.calls)
        assertEquals(setOf("Movies A v2", "Shows B"), p.titles().toSet())
    }

    @Test
    fun `a refresh drops the entries of a server absent from the pass entirely`() = runTest {
        val servers = FakeLibraryServers()
        servers.add(server("A", "1" to "Movies A"))
        servers.add(server("B", "1" to "Shows B"))
        val p = store(servers)
        p.loadLibraries()
        assertEquals(setOf("Movies A", "Shows B"), p.titles().toSet())

        servers.remove(ServerId("B"))
        p.loadLibraries()
        assertTrue(p.hasLoaded)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `a subsequent all failed delta keeps the retained libraries`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val b = servers.add(server("B", "1" to "Shows B"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A", "B"))

        a.error = IllegalStateException("offline")
        b.error = IllegalStateException("offline")
        p.loadLibraries()
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
        val notified = updates(p)

        p.syncToOnlineServers(ids("A", "B"))
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
        assertEquals(0, notified(), "a pass where no server succeeded is never authoritative")

        a.error = null
        b.error = null
        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(4, a.calls)
        assertEquals(4, b.calls)
        assertTrue(p.titles().containsAll(listOf("Movies A", "Shows B")))
    }

    @Test
    fun `a partially failed delta replaces only the succeeded servers entries`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val b = servers.add(server("B", "1" to "Shows B"))
        val p = store(servers)
        p.syncToOnlineServers(ids("A", "B"))

        a.error = IllegalStateException("offline")
        b.error = IllegalStateException("offline")
        p.loadLibraries()

        a.error = null
        a.libraries = listOf(serverLib("A", "2", "Movies A v2"))
        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(setOf("Movies A v2", "Shows B"), p.titles().toSet())

        b.error = null
        p.syncToOnlineServers(ids("A", "B"))
        assertEquals(3, a.calls, "A was loaded by the partial delta")
        assertEquals(4, b.calls)
        assertEquals(setOf("Movies A v2", "Shows B"), p.titles().toSet())
    }

    @Test
    fun `online servers listener is removed on dispose`() = runTest {
        val online = MutableSharedFlow<Set<ServerId>>()
        val p = LibrariesStore(prefs, backgroundScope, events, online)
        runCurrent()
        assertEquals(1, online.subscriptionCount.value)

        p.dispose()
        runCurrent()
        assertEquals(0, online.subscriptionCount.value)
    }

    @Test
    fun `online servers emissions drive the sync`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))
        val online = MutableSharedFlow<Set<ServerId>>()
        val p = LibrariesStore(prefs, backgroundScope, events, online)
        p.initialize(servers)
        runCurrent()

        online.emit(ids("A"))
        runCurrent()
        assertEquals(1, a.calls)
        assertEquals(listOf("Movies A"), p.titles())
    }

    @Test
    fun `is a no op for an empty set or before initialize`() = runTest {
        val servers = FakeLibraryServers()
        val a = servers.add(server("A", "1" to "Movies A"))

        val p = store(servers)
        p.syncToOnlineServers(emptySet())
        assertEquals(LibrariesLoadState.INITIAL, p.loadState)
        assertEquals(0, a.calls)

        val p2 = store()
        val notified = updates(p2)
        p2.syncToOnlineServers(ids("A"))
        assertEquals(LibrariesLoadState.INITIAL, p2.loadState)
        assertEquals(0, notified())
    }

    private suspend fun TestScope.seeded(): LibrariesStore = store().apply {
        updateLibraryOrder(listOf(serverLib("s1", "1", "Movies"), serverLib("s1", "2", "Shows"), serverLib("s2", "1", "Other")))
    }

    private fun TestScope.push(event: LibraryChangeEvent) {
        events.tryEmit(event)
        runCurrent()
    }

    @Test
    fun `a push event bumps only the named libraries without notifying`() = runTest {
        val p = seeded()
        val notified = updates(p)

        push(LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("1"), itemsAdded = true))

        assertEquals(1, p.libraryContentEpoch("s1:1"))
        assertEquals(0, p.libraryContentEpoch("s1:2"))
        assertEquals(0, p.libraryContentEpoch("s2:1"), "other servers untouched")
        assertEquals(0, notified(), "epoch bumps are bookkeeping, not a UI change")
    }

    @Test
    fun `unnamed or unknown library ids mark the whole server`() = runTest {
        val p = seeded()

        push(LibraryChangeEvent(ServerId("s1"), itemsAdded = true))
        assertEquals(1, p.libraryContentEpoch("s1:1"))
        assertEquals(1, p.libraryContentEpoch("s1:2"))

        // A new library matches nothing loaded: mark the server rather than nothing.
        push(LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("brand-new"), itemsAdded = true))
        assertEquals(2, p.libraryContentEpoch("s1:1"))
        assertEquals(2, p.libraryContentEpoch("s1:2"))
        assertEquals(0, p.libraryContentEpoch("s2:1"))
    }

    @Test
    fun `a partly resolved id set widens to the whole server while a fully resolved one stays precise`() = runTest {
        val p = seeded()

        // Jellyfin names collection folders; a grouped view's folders never appear as a loaded library.
        push(LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("1", "folder-b", "folder-c"), itemsAdded = true))
        assertEquals(1, p.libraryContentEpoch("s1:1"))
        assertEquals(1, p.libraryContentEpoch("s1:2"), "unresolved ids widen to every library on the server")
        assertEquals(0, p.libraryContentEpoch("s2:1"))

        push(LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("1", "2"), itemsAdded = true))
        push(LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("2"), itemsUpdated = true))
        assertEquals(2, p.libraryContentEpoch("s1:1"))
        assertEquals(3, p.libraryContentEpoch("s1:2"))
        assertEquals(0, p.libraryContentEpoch("s2:1"))

        val mixed = LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("1", "folder-b"), itemsAdded = true)
        assertTrue(p.eventTargetsLibrary(mixed, serverLib("s1", "2", "Shows")))
        assertFalse(p.eventTargetsLibrary(mixed, serverLib("s2", "1", "Other")))
        val precise = LibraryChangeEvent(ServerId("s1"), libraryIds = setOf("1"), itemsAdded = true)
        assertFalse(p.eventTargetsLibrary(precise, serverLib("s1", "2", "Shows")))
    }

    @Test
    fun `events with no changes or for unknown servers are ignored`() = runTest {
        val p = seeded()

        push(LibraryChangeEvent(ServerId("s1")))
        push(LibraryChangeEvent(ServerId("ghost"), itemsAdded = true))

        assertEquals(0, p.libraryContentEpoch("s1:1"))
        assertEquals(0, p.libraryContentEpoch("s1:2"))
        assertEquals(0, p.libraryContentEpoch("s2:1"))
    }
}
