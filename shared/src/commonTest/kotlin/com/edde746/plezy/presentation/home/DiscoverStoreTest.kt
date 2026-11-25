@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.presentation.home

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaActions
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.DeletionOrigin
import com.edde746.plezy.servers.FakeLibraryPreferences
import com.edde746.plezy.servers.FakeOfflineWatchDownloads
import com.edde746.plezy.servers.FakeOnlineServers
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.HiddenLibrariesStore
import com.edde746.plezy.servers.InMemoryOfflineWatchQueue
import com.edde746.plezy.servers.LibraryContentNotifier
import com.edde746.plezy.servers.LibraryRefreshNotifier
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.ToggleOfflineMode
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchPatchId
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.servers.WatchedThresholdSource
import com.edde746.plezy.settings.ContinueWatchingAction
import com.edde746.plezy.settings.EpisodeAction
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

private fun item(
    id: String,
    serverId: String = "server_1",
    kind: MediaKind = MediaKind.EPISODE,
    parentId: String? = null,
    grandparentId: String? = null,
    title: String = id,
    libraryId: String? = null,
    guid: String? = null,
    viewOffsetMs: Long? = null,
    durationMs: Long? = null,
) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = kind,
    title = title,
    guid = guid,
    parentId = parentId,
    grandparentId = grandparentId,
    viewOffsetMs = viewOffsetMs,
    durationMs = durationMs,
    libraryId = libraryId,
    serverId = serverId,
    serverName = "Server $serverId",
)

private fun hub(id: String, serverId: String = "server_1", identifier: String? = null, libraryId: String? = null, items: List<MediaItem>? = null) = MediaHub(
    id = id,
    title = id,
    type = "movie",
    items = items ?: listOf(item("$id-item", serverId)),
    identifier = identifier,
    size = 1,
    libraryId = libraryId,
    serverId = serverId,
)

private val cancelled = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "client closed")

/** A Plex server with global hubs: on-deck answers [onDeck], hubs [hubs]; each can be held at a gate. */
private class Server(id: String) {
    val backend = FakeMediaBackend(id)
    var onDeck: () -> List<MediaItem> = { emptyList() }
    var hubs: () -> List<MediaHub> = { emptyList() }
    var onDeckGate: CompletableDeferred<Unit>? = null
    var hubGate: CompletableDeferred<Unit>? = null
    val onDeckStarted = CompletableDeferred<Unit>()
    val hubStarted = CompletableDeferred<Unit>()
    var item: MediaItem? = null

    /** The count each on-deck request asked for (null: no limit), in order. */
    val onDeckCounts = mutableListOf<Int?>()

    init {
        backend.libraries = { emptyList() }
        backend.continueWatching = { count, _ ->
            onDeckCounts += count
            onDeckStarted.complete(Unit)
            onDeckGate?.await()
            onDeck().let { if (count != null) it.take(count) else it }
        }
        backend.globalHubs = { _, _, _ ->
            hubStarted.complete(Unit)
            hubGate?.await()
            hubs()
        }
        backend.items = { item }
        backend.externalIds = { ExternalIds() }
    }

    val onDeckCalls get() = backend.calls.count { it == "fetchContinueWatching" }
    val hubCalls get() = backend.calls.count { it == "fetchGlobalHubs" }
}

private class Fixture(val test: TestScope, profileId: String? = "profile-a", withServer: Boolean = true) {
    val scope = CoroutineScope(test.backgroundScope.coroutineContext + UnconfinedTestDispatcher(test.testScheduler))
    val online = FakeOnlineServers()
    val server = Server("server_1")
    val prefs = FakeLibraryPreferences()
    val hidden = HiddenLibrariesStore(prefs, scope = scope)
    val libraries = MutableStateFlow<List<MediaLibrary>>(emptyList())
    val onlineChanges = MutableSharedFlow<Set<ServerId>>()
    val watchStates = WatchStateNotifier()
    val deletions = DeletionNotifier()
    val libraryContent = LibraryContentNotifier()
    var binding = false
    var playing = false
    val store: DiscoverStore

    init {
        if (withServer) online.register(server.backend)
        store = DiscoverStore(
            servers = online,
            aggregation = DataAggregationService(online) { emptyMap() },
            hiddenLibraries = hidden,
            libraries = libraries,
            onlineServerChanges = onlineChanges,
            watchStates = watchStates,
            deletions = deletions,
            libraryContent = libraryContent,
            profileId = profileId,
            isProfileBinding = { binding },
            useGlobalHubs = { true },
            isRefreshBlocked = { playing },
            parentScope = scope,
            timeSource = test.testScheduler.timeSource,
            pacing = DiscoverPacing(debounce = 40.milliseconds, blockedRetry = 40.milliseconds, cooldown = 0.milliseconds),
        )
    }

    fun add(id: String): Server = Server(id).also { online.register(it.backend) }

    val state get() = store.state.value
    val onDeckIds get() = state.onDeck.map { it.id }
    val hubIds get() = state.hubs.map { it.id }
}

class DiscoverStoreTest {
    @Test
    fun loadPublishesOnDeckAndHubsAndConcurrentCallsCoalesce() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        val gate = CompletableDeferred<Unit>()
        f.server.onDeckGate = gate

        // One pass in flight plus at most one trailing pass: a request arriving mid-load sees its own fetch.
        val loads = listOf(f.store.load(), f.store.load(), f.store.load())
        gate.complete(Unit)
        loads.forEach { it.await() }

        assertEquals(listOf("a"), f.onDeckIds)
        assertEquals(listOf("hub-1"), f.hubIds)
        assertFalse(f.state.isLoading)
        assertFalse(f.state.areHubsLoading)
        assertNull(f.state.error)
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(2, f.server.hubCalls)
    }

    @Test
    fun closingDuringALoadDropsItsTrailingWorkAndCommits() = runTest {
        val f = Fixture(this)
        val gate = CompletableDeferred<Unit>()
        f.server.onDeckGate = gate
        f.server.hubGate = gate
        f.server.onDeck = { listOf(item("late")) }
        f.server.hubs = { listOf(hub("late-hub")) }

        f.store.load()
        f.store.load()
        f.store.close()
        gate.complete(Unit)
        runCurrent()

        assertEquals(1, f.server.onDeckCalls)
        assertTrue(f.state.onDeck.isEmpty())
        assertTrue(f.state.hubs.isEmpty())
        f.store.load().await()
        f.store.syncToOnlineServers(setOf(ServerId("server_1")))
        assertEquals(1, f.server.onDeckCalls)
    }

    @Test
    fun theRowShowsTwentyAndProbesForMore() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { List(30) { item("item-$it") } }

        f.store.load().await()

        assertEquals(DiscoverStore.CONTINUE_WATCHING_PREVIEW_LIMIT, f.state.onDeck.size)
        assertTrue(f.state.hasMoreContinueWatching)
        // One row past the preview is asked for, which tells whether there are more.
        assertEquals(listOf<Int?>(21), f.server.onDeckCounts)

        f.server.onDeck = { List(20) { item("item-$it") } }
        f.store.load().await()
        assertEquals(20, f.state.onDeck.size)
        assertFalse(f.state.hasMoreContinueWatching)
    }

    @Test
    fun viewAllAsksForEveryRowLeavesHiddenLibrariesOutAndKeepsTheCopiesPastThePreview() = runTest {
        val f = Fixture(this)
        val hd = item("film-hd", kind = MediaKind.MOVIE, title = "Film", libraryId = "1", guid = "plex://movie/film")
        val uhd = item("film-uhd", kind = MediaKind.MOVIE, title = "Film", libraryId = "3", guid = "plex://movie/film")
        f.server.onDeck = { List(25) { item("item-$it", libraryId = "1") } + item("hidden", libraryId = "2") + hd + uhd }
        f.hidden.hideLibrary("server_1:2")
        runCurrent()

        val all = f.store.loadAllContinueWatching()

        assertEquals(null, f.server.onDeckCounts.last())
        assertEquals(List(25) { "item-$it" } + "film-hd", all.map { it.id })
        // The merged film sits past the preview: its copies still open the picker.
        assertEquals(setOf("film-hd", "film-uhd"), f.store.continueWatchingCopiesOf(all.last()).map { it.id }.toSet())
    }

    @Test
    fun hubsOfPlaybackProgressAreLeftToContinueWatching() = runTest {
        val f = Fixture(this)
        f.server.hubs = {
            listOf(hub("keep"), hub("cw", identifier = "home.continue"), hub("od", identifier = "home.ondeck"), hub("nu", identifier = "home.nextup"))
        }

        f.store.load().await()

        assertEquals(listOf("keep"), f.hubIds)

        // Neutral identifiers: the title alone gives them away, whatever its case.
        f.server.hubs = {
            listOf(hub("Continue Watching in Movies"), hub("ON DECK"), hub("Next Up"), hub("Recently Added"))
        }
        f.store.load().await()

        assertEquals(listOf("Recently Added"), f.hubIds)
    }

    @Test
    fun watchedAndUnwatchedEventsRefreshContinueWatchingOnly() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("ep-1", parentId = "season-1")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        f.watchStates.notifyWatched(item("ep-1", parentId = "season-1"))
        runCurrent()
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)

        f.watchStates.notifyWatched(item("ep-1", parentId = "season-1"), isNowWatched = false)
        runCurrent()
        assertEquals(3, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)
    }

    @Test
    fun progressMovesTheRowToTheFrontAtItsOffsetAndReachesTheShelf() = runTest {
        val f = Fixture(this)
        val playing = item("ep-3", viewOffsetMs = 10_000, durationMs = 100_000)
        f.server.onDeck = { listOf(item("ep-1"), item("ep-2"), playing) + (4..21).map { item("ep-$it") } }
        f.store.load().await()

        f.watchStates.notifyProgress(playing, viewOffset = 30_000, duration = 100_000)
        runCurrent()

        // The item played last leads the row before any fetch, as the next fetch lists it: back on Home nothing moves.
        assertEquals(listOf("ep-3", "ep-1", "ep-2"), f.onDeckIds.take(3))
        assertEquals(30_000, f.state.onDeck.first().viewOffsetMs)
        assertEquals(DiscoverStore.CONTINUE_WATCHING_PREVIEW_LIMIT, f.state.onDeck.size)
        assertTrue(f.state.hasMoreContinueWatching)
        assertEquals(1, f.server.onDeckCalls)
        assertEquals(listOf("ep-3", "ep-1", "ep-2"), f.store.shelf.value?.take(3)?.map { it.id })
        assertEquals(30_000, f.store.shelf.value?.first()?.viewOffsetMs)
    }

    @Test
    fun aStoreWithoutAProfileNeverFillsTheShelf() = runTest {
        val f = Fixture(this, profileId = null)
        f.server.onDeck = { listOf(item("private")) }

        f.store.load().await()

        assertEquals(listOf("private"), f.onDeckIds)
        assertNull(f.store.shelf.value)
    }

    @Test
    fun copiesBehindAMergedRowFollowProgressAndDeletion() = runTest {
        val f = Fixture(this)
        // The same film in an HD and a 4K library: one row, the other copy one pick away.
        val hd = item("movie-hd", kind = MediaKind.MOVIE, title = "Film", libraryId = "1", guid = "plex://movie/film", viewOffsetMs = 10_000, durationMs = 100_000)
        val uhd = item("movie-uhd", kind = MediaKind.MOVIE, title = "Film", libraryId = "2", guid = "plex://movie/film", viewOffsetMs = 20_000, durationMs = 100_000)
        f.server.onDeck = { listOf(hd, uhd, item("other")) }
        f.store.load().await()
        assertEquals(listOf("movie-hd", "other"), f.onDeckIds)
        assertEquals(setOf("movie-hd", "movie-uhd"), f.store.continueWatchingCopiesOf(f.state.onDeck.first()).map { it.id }.toSet())

        f.watchStates.notifyProgress(uhd, viewOffset = 40_000, duration = 100_000)
        runCurrent()

        // The row shows the copy last played, as the next fetch would; the one it replaced stays a pick away.
        assertEquals(listOf("movie-uhd", "other"), f.onDeckIds)
        assertEquals(40_000, f.state.onDeck.first().viewOffsetMs)
        assertEquals(setOf("movie-hd", "movie-uhd"), f.store.continueWatchingCopiesOf(f.state.onDeck.first()).map { it.id }.toSet())
        assertEquals(1, f.server.onDeckCalls)

        f.server.onDeckGate = CompletableDeferred()
        f.deletions.notifyDeletedItem(hd)
        runCurrent()
        assertTrue(f.store.continueWatchingCopiesOf(f.state.onDeck.first()).isEmpty())
    }

    @Test
    fun aWatchedOrRemovedRowLeavesAtOnceAndAWatchedShowTakesItsEpisode() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("ep-1", parentId = "season-1", grandparentId = "show-1"), item("ep-2"), item("ep-3")) }
        f.store.load().await()
        f.server.onDeckGate = CompletableDeferred()

        f.watchStates.notifyWatched(item("show-1", kind = MediaKind.SHOW))
        runCurrent()
        assertEquals(listOf("ep-2", "ep-3"), f.onDeckIds)

        f.watchStates.notifyRemovedFromContinueWatching(item("ep-2"))
        runCurrent()
        assertEquals(listOf("ep-3"), f.onDeckIds)

        f.watchStates.notifyProgress(item("ep-3"), viewOffset = 95_000, duration = 100_000)
        runCurrent()
        assertEquals(emptyList(), f.onDeckIds)
    }

    @Test
    fun anUnwatchedEventEvictsNothing() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("ep-1"), item("ep-2")) }
        f.store.load().await()
        f.server.onDeckGate = CompletableDeferred()

        f.watchStates.notifyWatched(item("ep-1"), isNowWatched = false)
        runCurrent()

        assertEquals(listOf("ep-1", "ep-2"), f.onDeckIds)
    }

    @Test
    fun aDeletionDropsTheItemEverywhereAndRefreshesContinueWatchingOnly() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("ep-1"), item("ep-2")) }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(item("ep-1"), item("other")))) }
        f.store.load().await()
        f.server.onDeck = { listOf(item("ep-2")) }

        f.deletions.notifyDeletedItem(item("ep-1"))
        runCurrent()

        assertEquals(listOf("ep-2"), f.onDeckIds)
        assertEquals(listOf("other"), f.state.hubs.single().items.map { it.id })
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)
    }

    @Test
    fun aDownloadOnlyDeletionChangesNothing() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("ep-1")) }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(item("ep-1")))) }
        f.store.load().await()

        f.deletions.notifyDeletedItem(item("ep-1"), isDownloadOnly = true)
        runCurrent()

        assertEquals(listOf("ep-1"), f.onDeckIds)
        assertEquals(listOf("ep-1"), f.state.hubs.single().items.map { it.id })
        assertEquals(1, f.server.onDeckCalls)
    }

    @Test
    fun eventsEvictOnlyTheEmittingServersCopyOfACollidingId() = runTest {
        val f = Fixture(this)
        val second = f.add("server_2")
        f.server.onDeck = { listOf(item("42")) }
        second.onDeck = { listOf(item("42", "server_2", title = "42 two")) }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(item("42")))) }
        second.hubs = { listOf(hub("hub-2", "server_2", items = listOf(item("42", "server_2")))) }
        f.store.load().await()
        f.server.onDeckGate = CompletableDeferred()

        f.deletions.notifyDeletedItem(item("42", "server_2"))
        runCurrent()
        assertEquals(listOf("server_1"), f.state.onDeck.map { it.serverId })
        assertEquals(listOf("hub-1"), f.state.hubs.filter { it.items.isNotEmpty() }.map { it.id })

        f.watchStates.notifyWatched(item("42"))
        runCurrent()
        assertEquals(emptyList(), f.onDeckIds)
    }

    @Test
    fun aLibraryOrderChangeReSortsTheHubsWithoutAFetch() = runTest {
        val f = Fixture(this)
        f.server.hubs = { listOf(hub("hub-lib2", libraryId = "lib-2"), hub("hub-lib1", libraryId = "lib-1")) }
        f.store.load().await()
        assertEquals(listOf("hub-lib2", "hub-lib1"), f.hubIds)

        fun lib(id: String) = MediaLibrary(id = id, backend = BackendKind.PLEX, title = id, kind = MediaKind.MOVIE, serverId = "server_1")
        f.libraries.value = listOf(lib("lib-1"), lib("lib-2"))
        runCurrent()

        assertEquals(listOf("hub-lib1", "hub-lib2"), f.hubIds)
        assertEquals(1, f.server.hubCalls)
    }

    @Test
    fun aHiddenLibraryChangeReloadsEverythingOnce() = runTest {
        val f = Fixture(this)
        f.store.load().await()

        f.hidden.hideLibrary("server_1:lib-1")
        runCurrent()

        assertEquals(2, f.server.onDeckCalls)
        assertEquals(2, f.server.hubCalls)
    }

    @Test
    fun aBackgroundContinueWatchingRefreshNeverChangesStatesOrShowsErrors() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.store.load().await()

        f.server.onDeck = { error("server down") }
        f.store.refreshContinueWatching().await()

        assertEquals(listOf("a"), f.onDeckIds)
        assertNull(f.state.error)
        assertFalse(f.state.isLoading)
    }

    @Test
    fun noServersIsAnErrorUnlessTheBinderRuns() = runTest {
        val f = Fixture(this, withServer = false)

        f.binding = true
        f.store.load().await()
        assertTrue(f.state.isLoading)
        assertNull(f.state.error)

        f.binding = false
        f.store.load().await()
        assertFalse(f.state.isLoading)
        assertEquals(DiscoverLoad.ERROR, f.state.onDeckLoad)
        assertNotNull(f.state.error)
    }

    @Test
    fun nothingIsFetchedWhileTheProfileBinderRuns() = runTest {
        val f = Fixture(this)
        f.binding = true
        f.store.load().await()
        f.store.refreshContinueWatching().await()

        assertEquals(0, f.server.onDeckCalls)
        assertEquals(0, f.server.hubCalls)
        assertTrue(f.state.isLoading)
        assertTrue(f.state.areHubsLoading)
        assertFalse(f.store.isLoadInFlight)
        assertNull(f.store.shelf.value)

        f.binding = false
        f.server.onDeck = { listOf(item("rebound")) }
        f.server.hubs = { listOf(hub("rebound-hub")) }
        f.store.load().await()
        assertEquals(listOf("rebound"), f.onDeckIds)
        assertEquals(listOf("rebound-hub"), f.hubIds)
    }

    @Test
    fun aCancelledPassWithNothingShownStaysLoading() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { throw cancelled }
        f.server.hubs = { throw cancelled }

        f.store.load().await()

        assertTrue(f.state.isLoading)
        assertTrue(f.state.areHubsLoading)
        assertNull(f.state.error)

        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        assertEquals(listOf("a"), f.onDeckIds)
        assertFalse(f.state.areHubsLoading)
    }

    @Test
    fun aSettledFailureWithNothingShownIsEmptyAndWithContentKeepsIt() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { error("dead") }
        f.server.hubs = { error("dead") }
        f.store.load().await()
        assertFalse(f.state.isLoading)
        assertFalse(f.state.areHubsLoading)
        assertTrue(f.state.onDeck.isEmpty() && f.state.hubs.isEmpty())
        assertNull(f.state.error)

        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        f.server.onDeck = { error("dead") }
        f.server.hubs = { error("dead") }
        f.store.load().await()

        assertEquals(listOf("a"), f.onDeckIds)
        assertEquals(listOf("hub-1"), f.hubIds)
        assertFalse(f.state.isLoading)

        // The kept rows don't count as covering the failed server: its next emission fetches again.
        f.server.onDeck = { listOf(item("b")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1")))
        assertEquals(4, f.server.onDeckCalls)
    }

    @Test
    fun aManualRefreshTellsWhatHappened() = runTest {
        val f = Fixture(this)
        val second = f.add("server_2")
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        assertEquals(DiscoverRefreshOutcome.REFRESHED, f.store.refreshNow())

        second.hubs = { error("down") }
        assertEquals(DiscoverRefreshOutcome.DEGRADED, f.store.refreshNow())

        f.server.onDeck = { error("down") }
        f.server.hubs = { error("down") }
        second.onDeck = { error("down") }
        assertEquals(DiscoverRefreshOutcome.FAILED, f.store.refreshNow())
        // The rows stay; the failure is the caller's message, never a blank screen.
        assertEquals(listOf("a"), f.onDeckIds)
        assertNull(f.state.error)

        listOf(f.server, second).forEach {
            it.onDeck = { throw cancelled }
            it.hubs = { throw cancelled }
        }
        assertEquals(DiscoverRefreshOutcome.CANCELLED, f.store.refreshNow())
    }

    @Test
    fun onDeckCommitsWhileDisruptedHubsStayLoading() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { throw cancelled }

        f.store.load().await()

        assertFalse(f.state.isLoading)
        assertEquals(listOf("a"), f.onDeckIds)
        assertTrue(f.state.areHubsLoading)
        assertTrue(f.state.hubs.isEmpty())
    }

    @Test
    fun theHeroShowsWhileHubsAreStillLoading() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubGate = CompletableDeferred()
        f.server.hubs = { listOf(hub("hub-1")) }

        f.store.load()
        runCurrent()

        assertEquals(listOf("a"), f.onDeckIds)
        assertTrue(f.state.areHubsLoading)
        f.server.hubGate?.complete(Unit)
        runCurrent()
        assertEquals(listOf("hub-1"), f.hubIds)
    }

    @Test
    fun anEditedHubItemIsRefetchedOnlyFromItsOwnServer() = runTest {
        val f = Fixture(this)
        val second = f.add("server_2")
        val one = item("shared-id", title = "One")
        val two = item("shared-id", "server_2", title = "Two")
        f.server.hubs = { listOf(hub("hub-1", items = listOf(one))) }
        second.hubs = { listOf(hub("hub-2", "server_2", items = listOf(two))) }
        f.store.load().await()
        val updated = two.copy(title = "Two refreshed")
        second.item = updated

        f.store.refreshEdited(ServerId("server_2"), "shared-id")
        runCurrent()

        assertFalse(f.server.backend.calls.any { it.startsWith("fetchItem") })
        assertEquals(listOf("fetchItem:shared-id"), second.backend.calls.filter { it.startsWith("fetchItem") })
        assertEquals(setOf("One", "Two refreshed"), f.state.hubs.flatMap { it.items }.map { it.title }.toSet())
        assertEquals(1, f.server.onDeckCalls)
    }

    @Test
    fun anEditedContinueWatchingRowReconcilesThroughTheOnDeckFetchNotItsMetadata() = runTest {
        val f = Fixture(this)
        // The full metadata carries the season poster the server's Continue Watching row lacks.
        val row = item("ep-1", title = "Before")
        f.server.onDeck = { listOf(row) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        f.server.item = row.copy(title = "Metadata", parentThumbPath = "/library/metadata/season-1/thumb/1")
        f.server.onDeck = { listOf(row.copy(title = "Edited")) }

        f.store.refreshEdited(ServerId("server_1"), "ep-1")
        runCurrent()

        assertTrue(f.server.backend.calls.none { it.startsWith("fetchItem") })
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)
        assertEquals("Edited", f.state.onDeck.single().title)
        assertEquals(null, f.state.onDeck.single().parentThumbPath)
    }

    @Test
    fun anEditedItemInContinueWatchingAndAHubIsSwappedInTheHubOnly() = runTest {
        val f = Fixture(this)
        val row = item("ep-1", title = "Before")
        val metadata = row.copy(title = "Metadata", parentThumbPath = "/library/metadata/season-1/thumb/1")
        f.server.onDeck = { listOf(row) }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(row))) }
        f.store.load().await()
        f.server.item = metadata

        f.store.refreshEdited(ServerId("server_1"), "ep-1")
        runCurrent()

        assertEquals(listOf("fetchItem:ep-1"), f.server.backend.calls.filter { it.startsWith("fetchItem") })
        assertEquals(null, f.state.onDeck.single().parentThumbPath)
        assertEquals(metadata, f.state.hubs.single().items.single())
    }

    @Test
    fun aServerOnlineMidSessionIsFetchedAloneAndMerged() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        f.store.syncToOnlineServers(setOf(ServerId("server_1")))
        assertEquals(1, f.server.onDeckCalls)

        val second = f.add("server_2")
        second.onDeck = { listOf(item("b", "server_2")) }
        second.hubs = { listOf(hub("hub-2", "server_2")) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))

        assertEquals(1, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)
        assertEquals(setOf("a", "b"), f.onDeckIds.toSet())
        assertEquals(setOf("hub-1", "hub-2"), f.hubIds.toSet())

        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(1, second.onDeckCalls)

        // The binder's waves are its own: it primes one load when it settles.
        val third = f.add("server_3")
        f.binding = true
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2"), ServerId("server_3")))
        assertEquals(0, third.onDeckCalls)
    }

    @Test
    fun aFailedMergeKeepsWhatShowsAndRetriesOnTheNextEmission() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        val second = f.add("server_2")
        second.onDeck = { error("flaky connect") }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(listOf("a"), f.onDeckIds)
        assertNull(f.state.error)

        second.onDeck = { listOf(item("b", "server_2")) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(2, second.onDeckCalls)
        assertEquals(setOf("a", "b"), f.onDeckIds.toSet())
    }

    /**
     * Rows a later answer brings follow the ones shown, even played more recently, and so does a reload while Home
     * shows: nothing swaps places. Home shown again orders the row as the servers do.
     */
    @Test
    fun laterRowsFollowTheShownOnesUntilHomeShowsAgain() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a").copy(lastViewedAt = 300), item("c").copy(lastViewedAt = 100)) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        assertEquals(listOf("a", "c"), f.onDeckIds)

        val second = f.add("server_2")
        second.onDeck = { listOf(item("b", "server_2").copy(lastViewedAt = 200), item("d", "server_2").copy(lastViewedAt = 400)) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(listOf("a", "c", "d", "b"), f.onDeckIds)
        f.store.load().await()
        assertEquals(listOf("a", "c", "d", "b"), f.onDeckIds)

        f.store.onShown()
        runCurrent()
        assertEquals(listOf("d", "a", "b", "c"), f.onDeckIds)
    }

    /** Returning to the app shows Home anew: Continue Watching takes the servers' order. */
    @Test
    fun returningToTheAppOrdersContinueWatchingAnew() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a").copy(lastViewedAt = 300), item("c").copy(lastViewedAt = 100)) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        assertEquals(listOf("a", "c"), f.onDeckIds)

        f.server.onDeck = { listOf(item("c").copy(lastViewedAt = 500), item("a").copy(lastViewedAt = 300)) }
        f.store.load().await()
        assertEquals(listOf("a", "c"), f.onDeckIds)

        f.store.onAppResumed(refreshContinueWatching = true)
        runCurrent()
        assertEquals(listOf("c", "a"), f.onDeckIds)
    }

    @Test
    fun staleHubsReloadOnceAndFreshOrNeverLoadedOnesDoNot() = runTest {
        val f = Fixture(this)
        testScheduler.advanceTimeBy(1.minutes)
        assertFalse(f.store.refreshIfStale())

        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        testScheduler.advanceTimeBy(DiscoverStore.STALE_AFTER)
        assertFalse(f.store.refreshIfStale())
        assertEquals(1, f.server.hubCalls)

        testScheduler.advanceTimeBy(1.seconds)
        assertTrue(f.store.refreshIfStale())
        runCurrent()
        assertEquals(2, f.server.hubCalls)

        // A pass that kept the previous hubs didn't refresh them: they stay stale.
        testScheduler.advanceTimeBy(16.minutes)
        f.server.hubs = { error("down") }
        assertTrue(f.store.refreshIfStale())
        runCurrent()
        assertEquals(listOf("hub-1"), f.hubIds)
        f.server.hubs = { listOf(hub("hub-1")) }
        assertTrue(f.store.refreshIfStale())
        runCurrent()
        assertEquals(4, f.server.hubCalls)
    }

    @Test
    fun aResumeRefreshesContinueWatchingAloneUnlessAFullPassCoversItOrOnTheDesktop() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        f.store.onAppResumed(refreshContinueWatching = true)
        runCurrent()
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)

        f.store.onAppResumed(refreshContinueWatching = false)
        runCurrent()
        assertEquals(2, f.server.onDeckCalls)

        // Stale hubs: the full pass fetches Continue Watching once, with no refresh of its own beside it.
        testScheduler.advanceTimeBy(DiscoverStore.STALE_AFTER + 1.seconds)
        f.store.onAppResumed(refreshContinueWatching = true)
        runCurrent()
        assertEquals(3, f.server.onDeckCalls)
        assertEquals(2, f.server.hubCalls)
    }

    @Test
    fun anItemPlayedFromElsewhereJoinsContinueWatchingWhenHomeShowsAgain() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        // Played from a hub or a link: its progress isn't the row's, so nothing fetches while it plays.
        val played = item("b", viewOffsetMs = 0, durationMs = 100_000)
        f.server.onDeck = { listOf(item("b", viewOffsetMs = 30_000, durationMs = 100_000), item("a")) }
        f.watchStates.notifyProgress(played, viewOffset = 30_000, duration = 100_000)
        runCurrent()
        assertEquals(listOf("a"), f.onDeckIds)
        assertEquals(1, f.server.onDeckCalls)

        // Home shows again with fresh hubs: Continue Watching alone refetches and takes it in.
        f.store.onShown()
        runCurrent()
        assertEquals(listOf("b", "a"), f.onDeckIds)
        assertEquals(2, f.server.onDeckCalls)
        assertEquals(1, f.server.hubCalls)

        // Stale hubs: one full pass, no Continue Watching refresh beside it.
        testScheduler.advanceTimeBy(DiscoverStore.STALE_AFTER + 1.seconds)
        f.store.onShown()
        runCurrent()
        assertEquals(3, f.server.onDeckCalls)
        assertEquals(2, f.server.hubCalls)

        // While the profile binder runs nothing is fetched.
        f.binding = true
        f.store.onShown()
        runCurrent()
        assertEquals(3, f.server.onDeckCalls)
    }

    @Test
    fun aServerPushReloadsOnceDebouncedAndWaitsForPlaybackToEnd() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()

        repeat(3) { f.libraryContent.notifyChanged(LibraryChangeEvent(ServerId("server_$it"), itemsAdded = true)) }
        testScheduler.advanceTimeBy(120.milliseconds)
        runCurrent()
        assertEquals(2, f.server.hubCalls)

        f.libraryContent.notifyChanged(LibraryChangeEvent(ServerId("server_1")))
        testScheduler.advanceTimeBy(120.milliseconds)
        runCurrent()
        assertEquals(2, f.server.hubCalls)

        f.playing = true
        f.libraryContent.notifyChanged(LibraryChangeEvent(ServerId("server_1"), itemsAdded = true))
        testScheduler.advanceTimeBy(120.milliseconds)
        runCurrent()
        assertEquals(2, f.server.hubCalls)
        f.playing = false
        testScheduler.advanceTimeBy(120.milliseconds)
        runCurrent()
        assertEquals(3, f.server.hubCalls)

        f.libraryContent.notifyChanged(LibraryChangeEvent(ServerId("server_1"), itemsAdded = true))
        f.store.close()
        testScheduler.advanceTimeBy(120.milliseconds)
        runCurrent()
        assertEquals(3, f.server.hubCalls)
    }

    @Test
    fun aServerOnlineBeforeAnythingLoadedRunsTheFullLoad() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }

        f.store.syncToOnlineServers(setOf(ServerId("server_1")))

        assertEquals(listOf("a"), f.onDeckIds)
        assertEquals(listOf("hub-1"), f.hubIds)
        assertEquals(DiscoverLoad.LOADED, f.state.onDeckLoad)
        assertEquals(DiscoverLoad.LOADED, f.state.hubsLoad)
    }

    @Test
    fun aDeletedShowOrSeasonTakesItsEpisodesFromEveryListAndOnlyALocalDeletionRefetches() = runTest {
        val f = Fixture(this)
        f.server.onDeck = {
            listOf(item("ep-1", parentId = "season-1", grandparentId = "show-1"), item("ep-2", parentId = "season-2", grandparentId = "show-2"), item("ep-3"))
        }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(item("ep-4", parentId = "season-1", grandparentId = "show-1"), item("other")))) }
        f.store.load().await()

        f.deletions.notify(DeletionEvent("show-1", ServerId("server_1"), emptyList(), MediaKind.SHOW, origin = DeletionOrigin.SERVER_PUSH))
        runCurrent()
        assertEquals(listOf("ep-2", "ep-3"), f.onDeckIds)
        assertEquals(listOf("other"), f.state.hubs.single().items.map { it.id })
        // A pushed deletion leaves the refetch to the library change that comes with it.
        assertEquals(1, f.server.onDeckCalls)

        f.server.onDeckGate = CompletableDeferred()
        f.deletions.notify(DeletionEvent("season-2", ServerId("server_1"), listOf("show-2"), MediaKind.SEASON))
        runCurrent()
        assertEquals(listOf("ep-3"), f.onDeckIds)
        assertEquals(2, f.server.onDeckCalls)
    }

    @Test
    fun continueWatchingRefreshesCoalesceIntoTheRunningOneAndOneMore() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.store.load().await()
        val gate = CompletableDeferred<Unit>()
        f.server.onDeckGate = gate

        val refreshes = List(3) { f.store.refreshContinueWatching() }
        assertEquals(2, f.server.onDeckCalls)
        gate.complete(Unit)
        refreshes.forEach { it.await() }

        assertEquals(3, f.server.onDeckCalls)
    }

    @Test
    fun aContinueWatchingRefreshOvertakenByAChangeIsDroppedAndFetchedAgain() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        val gate = CompletableDeferred<Unit>()
        f.server.onDeckGate = gate
        val refresh = f.store.refreshContinueWatching()

        // A server comes online and merges in while the refresh, which never asked it, is still out.
        val second = f.add("server_2")
        second.onDeck = { listOf(item("b", "server_2")) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(setOf("a", "b"), f.onDeckIds.toSet())
        gate.complete(Unit)
        refresh.await()

        assertEquals(3, f.server.onDeckCalls)
        assertEquals(setOf("a", "b"), f.onDeckIds.toSet())
    }

    @Test
    fun aFailedRefetchOfAnEditedItemLeavesEveryListAsItWas() = runTest {
        val f = Fixture(this)
        val edited = item("ep-1", title = "Before")
        f.server.onDeck = { listOf(edited) }
        f.server.hubs = { listOf(hub("hub-1", items = listOf(edited))) }
        f.store.load().await()
        val before = f.state
        f.server.backend.items = { error("server down") }

        f.store.refreshEdited(ServerId("server_1"), "ep-1")
        runCurrent()

        assertEquals(listOf("fetchItem:ep-1"), f.server.backend.calls.filter { it.startsWith("fetchItem") })
        assertEquals(before, f.state)
    }

    @Test
    fun everyContinueWatchingChangeReachesTheShelf() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a"), item("b")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        fun shelfIds() = f.store.shelf.value?.map { it.id }
        assertEquals(listOf("a", "b"), shelfIds())

        // Home shown again: the row takes the servers' order.
        f.server.onDeck = { listOf(item("c"), item("a")) }
        f.store.onShown()
        runCurrent()
        assertEquals(listOf("c", "a"), shelfIds())

        f.server.onDeckGate = CompletableDeferred()
        f.watchStates.notifyRemovedFromContinueWatching(item("c"))
        runCurrent()
        assertEquals(listOf("a"), shelfIds())

        f.server.onDeckGate = null
        f.server.onDeck = { listOf(item("a")) }
        val second = f.add("server_2")
        second.onDeck = { listOf(item("d", "server_2")) }
        f.store.syncToOnlineServers(setOf(ServerId("server_1"), ServerId("server_2")))
        assertEquals(setOf("a", "d"), shelfIds()?.toSet())
    }
}

class HomeStoreTest {
    @Test
    fun refreshingHoldsWithTheRowsShownUntilTheRefreshLandsOrFails() = runTest {
        val f = Fixture(this)
        f.server.onDeck = { listOf(item("a")) }
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        val home = home(f)
        runCurrent()
        val rows = home.state.value.rows
        assertEquals(2, rows.size)
        assertFalse(home.refreshing.value)

        val gate = CompletableDeferred<Unit>()
        f.server.onDeckGate = gate
        home.refresh()
        assertTrue(home.refreshing.value)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertTrue(home.refreshing.value)
        assertEquals(rows, home.state.value.rows)

        gate.complete(Unit)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertFalse(home.refreshing.value)
        assertNull(home.state.value.message)

        val failing = CompletableDeferred<Unit>()
        f.server.onDeckGate = failing
        f.server.onDeck = { error("down") }
        f.server.hubs = { error("down") }
        home.refresh()
        advanceTimeBy(1.seconds)
        runCurrent()
        assertTrue(home.refreshing.value)

        failing.complete(Unit)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertFalse(home.refreshing.value)
        assertEquals(T.errors.unableToLoad(T.discover.title), home.state.value.message)
        assertEquals(rows, home.state.value.rows)
    }

    @Test
    fun libraryShortcutsFollowTheLibrariesAndOpenTheOneShown() = runTest {
        val f = Fixture(this)
        val libraries = MutableStateFlow(listOf(LibraryShortcutUi("server_1:movies", "Movies", null, MediaKind.MOVIE)))
        val opened = mutableListOf<String>()
        val home = home(f, libraries, opened::add)
        runCurrent()
        assertEquals(listOf("Movies"), home.state.value.libraries.map { it.title })

        libraries.value = libraries.value + LibraryShortcutUi("server_1:shows", "Shows", null, MediaKind.MOVIE)
        runCurrent()
        assertEquals(listOf("Movies", "Shows"), home.state.value.libraries.map { it.title })

        home.openLibrary("server_1:shows")
        home.openLibrary("server_1:gone")
        assertEquals(listOf("server_1:shows"), opened)
    }

    @Test
    fun aHubCardShowsItsItemWatchedOnceMarkedWithoutAReload() = runTest {
        val f = Fixture(this)
        f.server.hubs = { listOf(hub("hub-1")) }
        f.store.load().await()
        val home = home(f, watchState = WatchStateStore(f.watchStates, backgroundScope))
        runCurrent()
        assertFalse(home.state.value.hubs.single().items.single().watched)

        f.watchStates.notify(
            WatchStateEvent(
                itemId = "hub-1-item",
                serverId = ServerId("server_1"),
                changeType = WatchStateChangeType.WATCHED,
                parentChain = emptyList(),
                isNowWatched = true,
                patchId = WatchPatchId.session(1),
            ),
        )
        runCurrent()

        assertTrue(home.state.value.hubs.single().items.single().watched)
        assertEquals(1, f.server.hubCalls)
    }

    /**
     * Home over [f]'s Discover with [libraries]' shortcuts, a shortcut's tap to [selectLibrary], the cards under
     * [watchState]'s overlay; its cards' actions go unused here.
     */
    private fun TestScope.home(
        f: Fixture,
        libraries: Flow<List<LibraryShortcutUi>> = flowOf(emptyList()),
        selectLibrary: (String) -> Unit = {},
        watchState: WatchStateStore? = null,
    ): HomeStore {
        val navigator = PlezyNavigator(Route.Home)
        val clients = FakeWatchClients()
        val offlineMode = ToggleOfflineMode()
        val notifier = WatchStateNotifier()
        val trackers = RecordingTrackers()
        val sync = OfflineWatchSyncService(
            InMemoryOfflineWatchQueue(), FakeOfflineWatchDownloads(), clients, notifier, trackers,
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: com.edde746.plezy.backend.MediaBackend): Boolean = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = offlineMode,
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val offlineWatch = OfflineWatchProvider(sync, FakeOfflineWatchDownloads(), notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        val menu = MediaMenu(
            navigator = navigator,
            client = { null },
            isOnline = { false },
            isOwnerOrAdmin = { false },
            activeProfile = { null },
            hasMultipleProfiles = { false },
            isOffline = { false },
            fresh = { it },
            watchStateChanges = emptyFlow(),
            watchActions = WatchActions(clients, offlineMode, offlineWatch, notifier, trackers, backgroundScope),
            deletions = DeletionNotifier(),
            libraryRefresh = LibraryRefreshNotifier(),
            addedToList = { _, _ -> },
            play = {},
            launchQueue = { throw AssertionError("no queue launch expected") },
            scope = backgroundScope,
        )
        val actions = MediaActions(
            navigator,
            MutableStateFlow(ContinueWatchingAction.PLAY),
            MutableStateFlow(EpisodeAction.PLAY),
            copiesOf = { emptyList() },
            play = {},
            playTrack = {},
            openLibrary = {},
            notify = {},
            menu = menu,
        )
        return HomeStore(
            MutableStateFlow(f.store), { null }, MutableStateFlow(CardOptions()), MutableStateFlow(false), watchState, actions, navigator,
            libraries, flowOf(true), selectLibrary, f.scope,
        )
    }
}
