package com.edde746.plezy.catalog

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class CatalogWatchlistMachineryTest {
    private val matrix = CatalogItemIds(trakt = 1, slug = "the-matrix-1999", imdb = "tt0133093", tmdb = 603)
    private val show = CatalogItemIds(trakt = 2, imdb = "tt11280740", tmdb = 95396)

    private fun snapshotPage() = WatchlistKeyPage(
        groups = listOf(matrix.allKeys.map { "movie/$it" }, show.allKeys.map { "show/$it" }),
        hasMore = false,
    )

    /** Counts [CatalogSource.watchlistChanges] emissions, recording [probe] at each. */
    private fun <T> TestScope.recordChanges(source: CatalogSource, probe: () -> T): MutableList<T> {
        val seen = mutableListOf<T>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { source.watchlistChanges.collect { seen += probe() } }
        return seen
    }

    @Test
    fun membershipMatchesOnAnySharedIdFormAfterSnapshotLoad() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        assertNull(source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        val changes = recordChanges(source) { }

        source.ensureWatchlistLoaded()

        assertEquals(1, changes.size)
        // Queried by tmdb only; the snapshot entry also carries imdb, trakt and slug.
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        // The same tmdb id under the other kind is another title.
        assertEquals(false, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 603)))
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")))
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt9999999")))
    }

    @Test
    fun snapshotPagesUntilExhaustedOrTheMaxPageCount() = runTest {
        val more = WatchlistKeyPage(groups = listOf(listOf("movie/tmdb:1")), hasMore = true)
        val exhausted = FakeWatchlistSource(listOf(more, snapshotPage()))
        exhausted.ensureWatchlistLoaded()
        assertEquals(listOf(1 to 250, 2 to 250), exhausted.pageRequests)
        assertEquals(true, exhausted.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 1)))

        val truncated = FakeWatchlistSource(List(5) { more }, maxPages = 4)
        truncated.ensureWatchlistLoaded()
        assertEquals(listOf(1, 2, 3, 4), truncated.pageRequests.map { it.first })
        assertEquals(true, truncated.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 1)), "a truncated snapshot still loads")
    }

    @Test
    fun concurrentLoadsShareOneSnapshotFetch() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        val gate = CompletableDeferred<Unit>()
        source.snapshotGate = gate

        val first = async { source.ensureWatchlistLoaded() }
        val second = async { source.ensureWatchlistLoaded() }
        runCurrent()
        gate.complete(Unit)
        first.await()
        second.await()

        assertEquals(1, source.pageRequests.size)
        source.ensureWatchlistLoaded()
        assertEquals(1, source.pageRequests.size, "a loaded snapshot is kept for the session")
    }

    @Test
    fun snapshotLoadFailureIsSwallowedMembershipStaysUnknownAndTheNextCallRetries() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.snapshotFailures = 1

        source.ensureWatchlistLoaded() // must not throw
        assertNull(source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))

        source.ensureWatchlistLoaded()
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
    }

    @Test
    fun addToWatchlistIsOptimisticAndNotifiesAgainOnceTheServiceHasIt() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()
        val changes = recordChanges(source) { source.mutations.size }
        val gate = CompletableDeferred<Unit>()
        source.mutationGate = gate
        val added = CatalogItemIds(imdb = "tt0903747", tmdb = 1396)

        val mutation = launch { source.addToWatchlist(MediaKind.SHOW, added) }
        runCurrent()

        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 1396)), "flipped before the service answers")
        assertEquals(listOf(0), changes)
        gate.complete(Unit)
        mutation.join()

        assertEquals(listOf(Mutation(MediaKind.SHOW, added, add = true)), source.mutations)
        assertEquals(listOf(0, 1), changes, "optimistic notify, then once the service has it")
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt0903747")))
    }

    @Test
    fun aSuccessfulMutationNotifiesOnceTheServiceHasItEvenWithoutASnapshot() = runTest {
        // No snapshot loaded, so there is no optimistic flip to announce; the Watchlist row must still hear of it.
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        val changes = recordChanges(source) { source.mutations.isNotEmpty() }

        source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 1396))

        assertEquals(listOf(true), changes)
        assertNull(source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 1396)))
    }

    @Test
    fun removeWithASubsetOfIdFormsDropsTheSiblingKeysToo() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()

        // Media-detail path: ids come from server externals, without trakt or slug.
        source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093", tmdb = 603))

        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(trakt = 1)), "the sibling trakt id goes too")
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")), "the other entry stays")
    }

    @Test
    fun aFailedMutationRevertsTheOptimisticFlipAndRethrows() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()
        val changes = recordChanges(source) { }
        source.mutationFailure = IllegalStateException("HTTP 500")

        assertFailsWith<IllegalStateException> {
            source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093"))
        }

        assertEquals(2, changes.size, "optimistic flip + revert")
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093")))
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(trakt = 1)), "the whole group is restored")
    }

    @Test
    fun aFailedAddRemovesOnlyTheKeysItAdded() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()
        source.mutationFailure = IllegalStateException("HTTP 500")

        assertFailsWith<IllegalStateException> {
            source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt0903747"))
        }

        assertEquals(false, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt0903747")))
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")))
    }

    @Test
    fun aFailedMutationLeavesASnapshotReloadedMeanwhileAlone() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()
        // The service no longer lists the movie: the source reloads, then its mutation fails.
        source.pages = listOf(WatchlistKeyPage(listOf(show.allKeys.map { "show/$it" }), hasMore = false))
        source.reloadBeforeMutating = true
        source.mutationFailure = IllegalStateException("HTTP 500")

        assertFailsWith<IllegalStateException> {
            source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093"))
        }

        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(trakt = 1)), "the reloaded snapshot wins")
    }

    @Test
    fun mutationsCarryTheResolvedIdsAndTheirMembershipKeys() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        source.ensureWatchlistLoaded()
        source.resolve = { it.copy(trakt = 77) }

        source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt1"))

        assertEquals(CatalogItemIds(imdb = "tt1", trakt = 77), source.mutations.single().ids)
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(trakt = 77)))
    }

    @Test
    fun aDisposedSourceNoLongerNotifies() = runTest {
        val source = FakeWatchlistSource(listOf(snapshotPage()))
        val changes = recordChanges(source) { }
        source.dispose()

        source.ensureWatchlistLoaded()
        source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 1))

        assertTrue(changes.isEmpty())
        assertFalse(source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 2))!!)
    }
}

private data class Mutation(val kind: MediaKind, val ids: CatalogItemIds, val add: Boolean)

private class FakeWatchlistSource(var pages: List<WatchlistKeyPage>, maxPages: Int = 4) : CatalogWatchlistMachinery() {
    override val id = CatalogSourceId.TRAKT
    override val supportedRows = listOf(CatalogRowId.WATCHLIST)
    override val watchlistLogLabel = "Fake: watchlist"
    override val watchlistPageLimit = 250
    override val watchlistMaxPages = maxPages

    val pageRequests = mutableListOf<Pair<Int, Int>>()
    var snapshotFailures = 0
    var snapshotGate: CompletableDeferred<Unit>? = null
    val mutations = mutableListOf<Mutation>()
    var mutationGate: CompletableDeferred<Unit>? = null
    var mutationFailure: Exception? = null
    var reloadBeforeMutating = false
    var resolve: (CatalogItemIds) -> CatalogItemIds = { it }

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        pageRequests += page to limit
        snapshotGate?.await()
        if (snapshotFailures > 0) {
            snapshotFailures--
            throw IllegalStateException("HTTP 500")
        }
        return pages[page - 1]
    }

    override suspend fun resolveWatchlistMutationIds(kind: MediaKind, ids: CatalogItemIds): CatalogItemIds = resolve(ids)

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        if (reloadBeforeMutating) reloadWatchlistSnapshot()
        mutationGate?.await()
        mutationFailure?.let { throw it }
        mutations += Mutation(kind, ids, add)
    }

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = throw IllegalArgumentException(row.id)

    override suspend fun search(query: String, limit: Int): List<CatalogItem> = emptyList()

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int) = CatalogDetail(item)

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds) = CatalogItemIds.fromExternal(external)

    override fun dispose() = disposeWatchlistMachinery()
}
