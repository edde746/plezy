package com.edde746.plezy.presentation.home

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.metadata.EditedItem
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

private fun item(index: Int, backend: BackendKind, libraryId: String? = null) = MediaItem(
    id = "item_$index",
    backend = backend,
    kind = MediaKind.MOVIE,
    title = "Item $index",
    libraryId = libraryId,
    serverId = "server_1",
)

/** A server holding [items] for every hub, recording each page asked for. */
private class HubServer(private val all: List<MediaItem>, backend: BackendKind) : FakeMediaBackend("server_1", backend) {
    val starts = mutableListOf<Int?>()
    val sizes = mutableListOf<Int?>()
    var fullHubRequests = 0
    var sortOptions: List<MediaSort> = emptyList()
    var sortRequests = 0

    override suspend fun fetchMoreHubItemsPage(hubId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
        starts += start
        sizes += size
        val from = start ?: 0
        return LibraryPage(all.drop(from).take(size ?: all.size), all.size, from)
    }

    override suspend fun fetchMoreHubItems(hubId: String, limit: Int?): List<MediaItem> {
        fullHubRequests++
        return all
    }

    override suspend fun fetchSortOptions(libraryId: String, libraryType: String?): List<MediaSort> {
        sortRequests++
        return sortOptions
    }
}

private fun TestScope.storeScope() = CoroutineScope(backgroundScope.coroutineContext + UnconfinedTestDispatcher(testScheduler))

private fun TestScope.store(hub: MediaHub, server: HubServer?, loadItems: (suspend () -> List<MediaItem>)? = null) =
    HubDetailStore(hub, server, loadItems, { it.toCardUi(server) }, storeScope())

class HubDetailStoreTest {
    @Test
    fun aJellyfinHubAdvancesByTheRawPageAfterDroppingOtherLibraries() = runTest {
        val items = List(205) { item(it, BackendKind.JELLYFIN, libraryId = if (it % 2 == 0) "7" else "8") }
        val server = HubServer(items, BackendKind.JELLYFIN)

        val store = store(MediaHub("home.continue", "Recent", "movie", items.take(5), size = items.size, more = true, libraryId = "7", serverId = "server_1"), server)

        assertEquals(listOf<Int?>(0, 200), server.starts)
        assertEquals(0, server.fullHubRequests)
        val titles = store.state.value.items.map { it.title }
        assertTrue("Item 204" in titles)
        assertFalse("Item 203" in titles)
        assertFalse(store.state.value.loading)
        assertFalse(store.state.value.pageFailed)
    }

    @Test
    fun jellyfinRecentlyAddedFetchesEachPageOnlyAsTheUserReachesTheEnd() = runTest {
        val items = List(450) { item(it, BackendKind.JELLYFIN) }
        val server = HubServer(items, BackendKind.JELLYFIN)
        val store = store(MediaHub("home.recent", "Recently Added", "mixed", items.take(20), size = items.size, more = true, serverId = "server_1"), server)
        assertEquals(listOf<Int?>(0), server.starts)
        assertEquals(listOf<Int?>(200), server.sizes)

        store.nearEnd()
        assertEquals(listOf<Int?>(0, 200), server.starts)
        store.nearEnd()
        store.nearEnd()

        assertEquals(listOf<Int?>(0, 200, 400), server.starts)
        assertEquals(listOf<Int?>(200, 200, 50), server.sizes)
        assertEquals("Item 449", store.state.value.items.last().title)
    }

    @Test
    fun aPlexHubReplacesItsPreviewWithTheFullHub() = runTest {
        val items = List(205) { item(it, BackendKind.PLEX) }
        val server = HubServer(items, BackendKind.PLEX)

        val store = store(MediaHub("/hubs/home/recentlyAdded", "Recently Added", "movie", items.take(5), size = items.size, more = true, serverId = "server_1"), server)

        assertEquals(listOf<Int?>(0), server.starts)
        assertEquals(1, server.fullHubRequests)
        assertEquals(205, store.state.value.items.size)
        assertEquals(205, store.state.value.cards.size)
    }

    @Test
    fun aPlexSectionHubSortsByItsOwnFieldsAndHidesTheOnesItCannotHonour() = runTest {
        fun played(id: String, title: String, plays: Int) =
            MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = title, viewCount = plays, serverId = "server_1")
        val items = listOf(played("a", "Alpha", 1), played("b", "Bravo", 3), played("c", "Charlie", 2))
        val server = HubServer(items, BackendKind.PLEX)
        server.sortOptions = listOf(
            MediaSort("titleSort", "Title", "titleSort:desc", "asc"),
            MediaSort("viewCount", "Plays", "viewCount:desc", "desc"),
            MediaSort("mediaHeight", "Resolution", "mediaHeight:desc", "desc"),
        )
        val store = store(MediaHub("/hubs/sections/1/recentlyAdded", "Hub", "movie", items, size = items.size, serverId = "server_1"), server)

        assertEquals(listOf("Title", "Plays"), store.state.value.sortOptions.map { it.title })
        store.setSort(store.state.value.sortOptions[1], descending = true)
        assertEquals(listOf("Bravo", "Charlie", "Alpha"), store.state.value.items.map { it.title })
        assertEquals(listOf("Bravo", "Charlie", "Alpha"), store.state.value.cards.map { it.title })

        store.setSort(null, descending = false)
        assertEquals(listOf("Alpha", "Bravo", "Charlie"), store.state.value.items.map { it.title })
    }

    @Test
    fun everySupportedSortKeyOrdersByItsOwnFieldAndAnyOtherByTitle() = runTest {
        val base = listOf("Zulu", "Yankee", "Xray").mapIndexed { i, title ->
            MediaItem(id = "x$i", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = title, serverId = "server_1")
        }
        // Each key ranks x0 < x1 < x2 by its own field, against the titles' order.
        val rank: Map<String, (MediaItem, Int) -> MediaItem> = mapOf(
            "titleSort" to { item, n -> item.copy(titleSort = "a$n") },
            "title" to { item, n -> item.copy(title = "abc"[n].toString()) },
            "addedAt" to { item, n -> item.copy(addedAt = n.toLong()) },
            "year" to { item, n -> item.copy(year = 2000 + n) },
            "originallyAvailableAt" to { item, n -> if (n == 0) item.copy(year = 1999) else item.copy(originallyAvailableAt = "200$n-01-01") },
            "rating" to { item, n -> item.copy(rating = n.toDouble()) },
            "userRating" to { item, n -> item.copy(userRating = n.toDouble()) },
            "contentRating" to { item, n -> item.copy(contentRating = listOf("G", "PG", "R")[n]) },
            "duration" to { item, n -> item.copy(durationMs = n * 60_000L) },
            "viewOffset" to { item, n -> item.copy(viewOffsetMs = n * 1_000L) },
            "viewCount" to { item, n -> item.copy(viewCount = n) },
            "lastViewedAt" to { item, n -> item.copy(lastViewedAt = n.toLong()) },
            "unviewedLeafCount" to { item, n -> item.copy(kind = MediaKind.SHOW, leafCount = 10, viewedLeafCount = 10 - n) },
        )
        for ((key, apply) in rank) {
            val ranked = base.mapIndexed { n, item -> apply(item, n) }
            val store = store(MediaHub("home.recent", "Recent", "movie", listOf(ranked[2], ranked[0], ranked[1]), size = 3, serverId = "server_1"), null)
            store.setSort(MediaSort(key, key), descending = false)
            assertEquals(listOf("x0", "x1", "x2"), store.state.value.items.map { it.id }, key)
            store.setSort(MediaSort(key, key), descending = true)
            assertEquals(listOf("x2", "x1", "x0"), store.state.value.items.map { it.id }, "$key descending")
        }
        val store = store(MediaHub("home.recent", "Recent", "movie", base, size = 3, serverId = "server_1"), null)
        store.setSort(MediaSort("mediaHeight", "Resolution"), descending = false)
        assertEquals(listOf("Xray", "Yankee", "Zulu"), store.state.value.items.map { it.title })
    }

    @Test
    fun continueWatchingLoadsItsWholeListOnceWithTheDefaultSorts() = runTest {
        val preview = List(20) { item(it, BackendKind.PLEX) }
        var loads = 0
        val store = store(HomeStore.continueWatchingHub(preview, more = true), null) {
            loads++
            List(30) { item(it, BackendKind.PLEX) }
        }

        assertEquals(1, loads)
        assertEquals(30, store.state.value.items.size)
        assertEquals(listOf("titleSort", "year", "addedAt", "rating"), store.state.value.sortOptions.map { it.key })
    }

    @Test
    fun aHubWithoutMoreShowsItsPreviewAndFetchesNothing() = runTest {
        val items = List(3) { item(it, BackendKind.JELLYFIN) }
        val server = HubServer(items, BackendKind.JELLYFIN)

        val store = store(MediaHub("home.recent", "Recent", "movie", items, size = 3, serverId = "server_1"), server)

        assertTrue(server.starts.isEmpty())
        assertEquals(0, server.sortRequests)
        assertEquals(3, store.state.value.items.size)
        assertFalse(store.state.value.loading)
    }

    @Test
    fun continueWatchingDropsARemovedItemAndLoadsItsListAgain() = runTest {
        val items = List(3) { item(it, BackendKind.PLEX) }
        var loads = 0
        var remaining = items
        val events = MutableSharedFlow<WatchStateEvent>(extraBufferCapacity = 4)
        val store = HubDetailStore(
            MediaHub("continueWatching", "Continue Watching", "mixed", items, size = 3),
            client = null,
            loadItems = { loads++; remaining },
            toCard = { it.toCardUi(null) },
            parentScope = storeScope(),
            watchStates = events,
        )
        remaining = items.drop(1)
        events.emit(WatchStateEvent("item_0", ServerId("server_1"), WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        assertEquals(1, loads)
        assertEquals(listOf("Item 1", "Item 2"), store.state.value.items.map { it.title })

        events.emit(WatchStateEvent("item_9", ServerId("server_1"), WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        assertEquals(1, loads, "an item the list doesn't hold changes nothing")
    }

    @Test
    fun theHubSettlesOnceItsFirstLoadEndsAndStaysSettledThroughALaterLoad() = runTest {
        val items = List(3) { item(it, BackendKind.PLEX) }
        var gate = CompletableDeferred<Unit>()
        val events = MutableSharedFlow<WatchStateEvent>(extraBufferCapacity = 4)
        val store = HubDetailStore(
            MediaHub("continueWatching", "Continue Watching", "mixed", items, size = 3, more = true),
            client = null,
            loadItems = { gate.await(); items.drop(1) },
            toCard = { it.toCardUi(null) },
            parentScope = storeScope(),
            watchStates = events,
        )
        assertFalse(store.state.value.settled, "the preview while the hub loads")
        gate.complete(Unit)
        assertTrue(store.state.value.settled)

        gate = CompletableDeferred()
        events.emit(WatchStateEvent("item_1", ServerId("server_1"), WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        assertTrue(store.state.value.loading)
        assertTrue(store.state.value.settled, "a later load keeps the page")
        gate.complete(Unit)
    }

    @Test
    fun aFailedFirstLoadSettlesTheHub() = runTest {
        val items = List(3) { item(it, BackendKind.PLEX) }
        val store = store(HomeStore.continueWatchingHub(items, more = true), null) { error("offline") }

        assertTrue(store.state.value.settled)
        assertNotNull(store.state.value.error)
    }

    @Test
    fun anEditedItemIsFetchedAgainAndSwappedIn() = runTest {
        val items = List(2) { item(it, BackendKind.PLEX) }
        val server = HubServer(items, BackendKind.PLEX)
        server.items = { id -> items.first { it.id == id }.copy(title = "Edited") }
        val edits = MutableSharedFlow<EditedItem>(extraBufferCapacity = 4)
        val store = HubDetailStore(MediaHub("home.recent", "Recent", "movie", items, size = 2, serverId = "server_1"), server, null, { it.toCardUi(server) }, storeScope(), edited = edits)

        edits.emit(EditedItem(ServerId("server_1"), "item_1"))

        assertEquals(listOf("Item 0", "Edited"), store.state.value.items.map { it.title })
    }

    @Test
    fun anItemMarkedWatchedOrUnwatchedIsFetchedAgainAndSwappedIn() = runTest {
        val items = List(2) { item(it, BackendKind.PLEX) }
        val server = HubServer(items, BackendKind.PLEX)
        server.items = { id -> items.first { it.id == id }.copy(title = "Fetched") }
        val events = MutableSharedFlow<WatchStateEvent>(extraBufferCapacity = 4)
        val store = HubDetailStore(MediaHub("home.recent", "Recent", "movie", items, size = 2, serverId = "server_1"), server, null, { it.toCardUi(server) }, storeScope(), watchStates = events)

        events.emit(WatchStateEvent("item_1", ServerId("server_1"), WatchStateChangeType.WATCHED, emptyList()))

        assertEquals(listOf("Item 0", "Fetched"), store.state.value.items.map { it.title })
    }
}
