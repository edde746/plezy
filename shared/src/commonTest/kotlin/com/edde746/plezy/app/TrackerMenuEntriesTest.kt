package com.edde746.plezy.app

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuPrompt
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.libraries.mediaItem
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A watchlist source whose membership is [members] (null: not loaded yet); every mutation lands in [mutations] and
 * signals [watchlistChanges], as [changed] does.
 */
internal class WatchlistSource(override val id: CatalogSourceId, var members: MutableSet<String>? = mutableSetOf()) : CatalogSource {
    val mutations = mutableListOf<String>()
    var loads = 0
    var failMutation: Throwable? = null
    /** The membership a load brings while [members] is null (not loaded yet), once, as a real snapshot loads. */
    var onLoad: MutableSet<String>? = null
    /** The loads that fetched the watchlist ([onLoad]). */
    var fetches = 0
    /** Held until completed: the watchlist is still loading. */
    var loading: CompletableDeferred<Unit>? = null

    override val supportedRows: List<CatalogRowId> = emptyList()
    override val supportsWatchlist: Boolean = true
    private val changes = MutableSharedFlow<Unit>(extraBufferCapacity = 16)
    override val watchlistChanges: Flow<Unit> = changes

    fun changed() {
        changes.tryEmit(Unit)
    }

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = throw IllegalArgumentException("$row")

    override suspend fun search(query: String, limit: Int): List<CatalogItem> = emptyList()

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail = CatalogDetail(item)

    override suspend fun ensureWatchlistLoaded() {
        loads++
        loading?.await()
        onLoad?.let {
            members = it
            fetches++
        }
        onLoad = null
    }

    override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = members?.contains(ids.imdb)

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? = external.imdb?.let { CatalogItemIds(imdb = it) }

    override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutate("add", ids)

    override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutate("remove", ids)

    private fun mutate(op: String, ids: CatalogItemIds) {
        failMutation?.let { throw it }
        mutations += "$op ${ids.imdb}"
        if (op == "add") members?.add(ids.imdb!!) else members?.remove(ids.imdb)
        changed()
    }

    override fun dispose() = Unit
}

class TrackerMenuEntriesTest {
    private val server = FakeMediaBackend("s1").apply { externalIds = { ExternalIds(imdb = "tt1") } }
    private val movie = mediaItem("m1", MediaKind.MOVIE)
    private val trakt = WatchlistSource(CatalogSourceId.TRAKT)
    private var sources: List<CatalogSource> = listOf(trakt)
    private val candidates = LibraryWatchlistCandidates { sources }
    private var online = true
    private var offline = false
    private val asked = mutableListOf<MenuPrompt.Options>()
    private var answer: Int? = 0

    private fun TestScope.watchlist() = WatchlistMenuEntries(
        candidates = { candidates },
        sources = { sources },
        client = { if (it == server.serverId) server else null },
        isOnline = { online },
        isOffline = { offline },
        choose = { asked += it; answer },
        scope = backgroundScope,
    )

    /** The entries a menu shows, then warmed for the next as its item's focus or press warms them. */
    private suspend fun WatchlistMenuEntries.open(item: MediaItem = movie): List<MenuEntry> =
        entries(MenuTarget.Item(item), MenuPlace()).also { warm(MenuTarget.Item(item)) }

    private suspend fun WatchlistMenuEntries.pick(entry: MenuEntry, item: MediaItem = movie): MenuMessage? =
        perform(MenuTarget.Item(item), MenuPlace(), entry.id)

    @Test
    fun aMovieOrShowWithAWatchlistSourceAndItsServerUpGetsAddToWatchlist() = runTest {
        val menu = watchlist()
        assertEquals(listOf(MenuEntry(WatchlistMenuEntries.ADD, T.explore.addToWatchlist, MenuIcon.BOOKMARK_ADD)), menu.open())
        assertEquals(1, menu.open(mediaItem("s", MediaKind.SHOW)).size)
        assertEquals(emptyList(), menu.open(mediaItem("e", MediaKind.EPISODE)))
        assertEquals(emptyList(), menu.open(mediaItem("a", MediaKind.ALBUM)))
        online = false
        assertEquals(emptyList(), menu.open())
        online = true
        offline = true
        assertEquals(emptyList(), menu.open())
        offline = false
        sources = emptyList()
        assertEquals(emptyList(), menu.open())
    }

    @Test
    fun openingWarmsTheCandidatesAndTheWatchlistsSoTheNextOpenKnowsTheMembership() = runTest {
        trakt.members = mutableSetOf("tt1")
        val menu = watchlist()
        assertEquals(WatchlistMenuEntries.ADD, menu.open().single().id, "nothing known yet")
        runCurrent()
        assertEquals(1, trakt.loads)
        assertEquals(WatchlistMenuEntries.REMOVE, menu.open().single().id)
    }

    @Test
    fun theEntriesAloneFetchNothing() = runTest {
        trakt.members = mutableSetOf("tt1")
        val menu = watchlist()
        assertEquals(WatchlistMenuEntries.ADD, menu.entries(MenuTarget.Item(movie), MenuPlace()).single().id)
        runCurrent()
        assertEquals(0, trakt.loads)
    }

    @Test
    fun aStaleAddOnAnItemAlreadyOnTheWatchlistChangesNothing() = runTest {
        trakt.members = mutableSetOf("tt1")
        val menu = watchlist()
        val add = menu.entries(MenuTarget.Item(movie), MenuPlace()).single()
        assertEquals(WatchlistMenuEntries.ADD, add.id)
        assertEquals(MenuMessage(T.explore.addedToWatchlist), menu.pick(add))
        assertEquals(emptyList(), trakt.mutations)
    }

    @Test
    fun anItemKnownToHaveNoCandidateGetsNoEntry() = runTest {
        server.externalIds = { ExternalIds() }
        val menu = watchlist()
        assertEquals(1, menu.open().size)
        runCurrent()
        assertEquals(emptyList(), menu.open())
    }

    @Test
    fun oneCandidateTogglesAsTheMenuSaid() = runTest {
        val menu = watchlist()
        assertEquals(MenuMessage(T.explore.addedToWatchlist), menu.pick(menu.open().single()))
        assertEquals(listOf("add tt1"), trakt.mutations)
        val remove = menu.open().single()
        assertEquals(WatchlistMenuEntries.REMOVE, remove.id)
        assertEquals(MenuMessage(T.explore.removedFromWatchlist), menu.pick(remove))
        assertEquals(listOf("add tt1", "remove tt1"), trakt.mutations)
        assertTrue(asked.isEmpty())
    }

    @Test
    fun severalCandidatesAskForTheSourceAndToggleItByItsOwnMembership() = runTest {
        val mdblist = WatchlistSource(CatalogSourceId.MDBLIST, mutableSetOf("tt1"))
        sources = listOf(trakt, mdblist)
        val menu = watchlist()
        val entry = menu.open().single()
        answer = 1
        assertEquals(MenuMessage(T.explore.removedFromWatchlist), menu.pick(entry))
        val options = asked.single().options
        assertEquals(listOf("Trakt", "MDBList"), options.map { it.label })
        assertEquals(listOf(CatalogSourceId.TRAKT, CatalogSourceId.MDBLIST), options.map { it.logo })
        assertEquals(listOf(T.explore.addToWatchlist, T.explore.removeFromWatchlist), options.map { it.detail })
        assertEquals(listOf("remove tt1"), mdblist.mutations)
        answer = null
        assertNull(menu.pick(entry), "dismissed: nothing runs")
        assertEquals(emptyList(), trakt.mutations)
    }

    @Test
    fun noMatchAndFailuresSaySo() = runTest {
        val menu = watchlist()
        val entry = menu.open().single()
        trakt.failMutation = IllegalStateException("503")
        assertEquals(MenuMessage(T.explore.watchlistUpdateFailed, isError = true), menu.pick(entry))
        server.externalIds = { error("down") }
        val fresh = WatchlistMenuEntries({ LibraryWatchlistCandidates { sources } }, { sources }, { server }, { true }, { false }, { 0 }, backgroundScope)
        assertEquals(MenuMessage(T.explore.watchlistUpdateFailed, isError = true), fresh.pick(entry))
        server.externalIds = { ExternalIds() }
        val none = WatchlistMenuEntries({ LibraryWatchlistCandidates { sources } }, { sources }, { server }, { true }, { false }, { 0 }, backgroundScope)
        assertEquals(MenuMessage(T.explore.watchlistNoMatch), none.pick(entry))
    }

    @Test
    fun rateIsOfferedForVideoItemsAndOpensTheSheetOnTheItemsServerWhileItAnswers() = runTest {
        val opened = mutableListOf<Pair<String, MediaBackend?>>()
        var up = true
        val rate = RateMenuEntries({ if (it == ServerId("s1")) server else null }, { up }) { item, backend -> opened += item.id to backend }
        val entry = rate.entries(MenuTarget.Item(movie), MenuPlace()).single()
        assertEquals(MenuEntry(RateMenuEntries.RATE, T.mediaMenu.rate, MenuIcon.STAR), entry)
        assertEquals(emptyList(), rate.entries(MenuTarget.Item(mediaItem("a", MediaKind.ALBUM)), MenuPlace()))
        assertNull(rate.perform(MenuTarget.Item(movie), MenuPlace(), entry.id))
        up = false
        assertNull(rate.perform(MenuTarget.Item(movie), MenuPlace(), entry.id))
        assertEquals(listOf<Pair<String, MediaBackend?>>("m1" to server, "m1" to null), opened)
        val failing = RateMenuEntries({ server }, { true }) { _, _ -> error("boom") }
        assertTrue(failing.perform(MenuTarget.Item(movie), MenuPlace(), entry.id)!!.isError)
    }
}
