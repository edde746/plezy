package com.edde746.plezy.catalog.matching

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

private data class Mutation(val kind: MediaKind, val ids: CatalogItemIds, val add: Boolean)

/** A watchlist source resolving any item to [resolveTo] (null: not in its domain), or failing with [resolveError]. */
private class FakeWatchlistSource(
    override val id: CatalogSourceId,
    var resolveTo: CatalogItemIds? = CatalogItemIds(imdb = "tt1"),
    var resolveError: Throwable? = null,
    var mutationGate: CompletableDeferred<Unit>? = null,
    var mutationError: Throwable? = null,
    override val supportsWatchlist: Boolean = true,
) : CatalogSource {
    var resolveCalls = 0
    val mutations = mutableListOf<Mutation>()

    override val supportedRows: List<CatalogRowId> = emptyList()
    override val watchlistChanges: Flow<Unit> = emptyFlow()

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage = throw IllegalArgumentException("No row $row")

    override suspend fun search(query: String, limit: Int): List<CatalogItem> = emptyList()

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail = CatalogDetail(item)

    override suspend fun ensureWatchlistLoaded() = Unit

    override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = null

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? {
        resolveCalls++
        resolveError?.let { throw it }
        return resolveTo
    }

    override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutate(kind, ids, add = true)

    override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutate(kind, ids, add = false)

    private suspend fun mutate(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        mutationGate?.await()
        mutationError?.let { throw it }
        mutations += Mutation(kind, ids, add)
    }

    override fun dispose() = Unit
}

/** The item's server: answers [ids] for its external ids (after [gate], when set), or throws [error]. */
private class ExternalIdsServer(var ids: ExternalIds, var error: Throwable? = null) : FakeMediaBackend(SERVER) {
    var gate: CompletableDeferred<Unit>? = null
    val fetches get() = calls.count { it.startsWith("fetchExternalIds") }

    init {
        externalIds = {
            gate?.await()
            error?.let { throw it }
            ids
        }
    }
}

private const val SERVER = "server-1"
private const val ITEM = "movie-1"
private val serverId = ServerId(SERVER)

@OptIn(ExperimentalCoroutinesApi::class)
class LibraryWatchlistCandidatesTest {
    // Resolution.

    @Test
    fun pairsEachSourceWithItsResolvedIdsSkippingOutOfDomainAndFailingSources() = runTest {
        val trakt = FakeWatchlistSource(CatalogSourceId.TRAKT)
        val mal = FakeWatchlistSource(CatalogSourceId.MAL, resolveTo = null)
        val simkl = FakeWatchlistSource(CatalogSourceId.SIMKL, resolveError = IllegalStateException("down"))
        val failed = mutableListOf<CatalogSource>()

        val candidates = resolveWatchlistCandidates(
            ExternalIdsServer(ExternalIds(imdb = "tt1")),
            ITEM,
            MediaKind.MOVIE,
            listOf(trakt, mal, simkl),
        ) { failed += it }

        assertEquals(listOf(CatalogSourceId.TRAKT), candidates.map { it.source.id })
        assertEquals(listOf<CatalogSource>(simkl), failed, "out of domain is an answer; only the failure is reported")
        assertEquals("tt1", candidates.single().ids.imdb)
        assertEquals(1, mal.resolveCalls)
        assertEquals(1, simkl.resolveCalls)
    }

    @Test
    fun anItemWithoutExternalIdsResolvesToNothingWithoutAskingAnySource() = runTest {
        val trakt = FakeWatchlistSource(CatalogSourceId.TRAKT)

        val candidates = resolveWatchlistCandidates(ExternalIdsServer(ExternalIds()), ITEM, MediaKind.MOVIE, listOf(trakt))

        assertTrue(candidates.isEmpty())
        assertEquals(0, trakt.resolveCalls)
    }

    @Test
    fun aNullClientResolvesToNothing() = runTest {
        assertTrue(resolveWatchlistCandidates(null, ITEM, MediaKind.MOVIE, listOf(FakeWatchlistSource(CatalogSourceId.TRAKT))).isEmpty())
    }

    @Test
    fun aFailedExternalIdFetchPropagatesToTheCaller() = runTest {
        assertFailsWith<IllegalStateException> {
            resolveWatchlistCandidates(
                ExternalIdsServer(ExternalIds(), error = IllegalStateException("unreachable")),
                ITEM,
                MediaKind.MOVIE,
                listOf(FakeWatchlistSource(CatalogSourceId.TRAKT)),
            )
        }
    }

    // The session cache.

    @Test
    fun resolvesAnItemOncePerSessionAndHandsMenusTheCachedResult() = runTest {
        val source = FakeWatchlistSource(CatalogSourceId.TRAKT)
        val candidates = LibraryWatchlistCandidates { listOf(source) }
        val client = ExternalIdsServer(ExternalIds(imdb = "tt1"))

        assertNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))
        val first = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client)
        val second = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client)

        assertEquals(1, client.fetches)
        assertSame(source, first.single().source)
        assertSame(first, second)
        assertSame(first, candidates.cachedWatchlistCandidatesFor(serverId, ITEM))
    }

    @Test
    fun onlyWatchlistCapableSourcesAreAsked() = runTest {
        val trakt = FakeWatchlistSource(CatalogSourceId.TRAKT)
        val seerr = FakeWatchlistSource(CatalogSourceId.SEERR, supportsWatchlist = false)
        val candidates = LibraryWatchlistCandidates { listOf(trakt, seerr) }

        val resolved = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, ExternalIdsServer(ExternalIds(imdb = "tt1")))

        assertEquals(listOf(CatalogSourceId.TRAKT), resolved.map { it.source.id })
        assertEquals(0, seerr.resolveCalls)
    }

    @Test
    fun concurrentLoadsForTheSameItemCoalesceIntoOneResolution() = runTest {
        val candidates = LibraryWatchlistCandidates { listOf(FakeWatchlistSource(CatalogSourceId.TRAKT)) }
        val client = ExternalIdsServer(ExternalIds(imdb = "tt1")).apply { gate = CompletableDeferred() }

        val first = async { candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client) }
        val second = async { candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client) }
        runCurrent()
        client.gate!!.complete(Unit)

        assertSame(first.await(), second.await())
        assertEquals(1, client.fetches)
    }

    @Test
    fun aFailedResolutionIsRetriedInsteadOfCached() = runTest {
        val candidates = LibraryWatchlistCandidates { listOf(FakeWatchlistSource(CatalogSourceId.TRAKT)) }
        val client = ExternalIdsServer(ExternalIds(imdb = "tt1"), error = IllegalStateException("unreachable"))

        assertFailsWith<IllegalStateException> { candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client) }
        assertNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))

        client.error = null
        assertEquals(1, candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client).size)
        assertEquals(2, client.fetches)
    }

    @Test
    fun anAnswerMissingASourceThatFailedToResolveIsRetriedInsteadOfCached() = runTest {
        val trakt = FakeWatchlistSource(CatalogSourceId.TRAKT)
        val mal = FakeWatchlistSource(CatalogSourceId.MAL, resolveError = IllegalStateException("mapping unavailable"))
        val candidates = LibraryWatchlistCandidates { listOf(trakt, mal) }
        val client = ExternalIdsServer(ExternalIds(imdb = "tt1"))

        val partial = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client)
        assertEquals(listOf(CatalogSourceId.TRAKT), partial.map { it.source.id })
        assertNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))

        mal.resolveError = null
        val complete = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client)
        assertEquals(listOf(CatalogSourceId.TRAKT, CatalogSourceId.MAL), complete.map { it.source.id })
        assertSame(complete, candidates.cachedWatchlistCandidatesFor(serverId, ITEM))
    }

    @Test
    fun aNullClientResolvesToNothingWithoutCachingTheMiss() = runTest {
        val candidates = LibraryWatchlistCandidates { listOf(FakeWatchlistSource(CatalogSourceId.TRAKT)) }

        assertTrue(candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, null).isEmpty())
        assertNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))

        val resolved = candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, ExternalIdsServer(ExternalIds(imdb = "tt1")))
        assertEquals(1, resolved.size)
    }

    @Test
    fun aSourceRebindInvalidatesCachedCandidates() = runTest {
        val candidates = LibraryWatchlistCandidates { listOf(FakeWatchlistSource(CatalogSourceId.TRAKT)) }

        candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, ExternalIdsServer(ExternalIds(imdb = "tt1")))
        assertNotNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))

        candidates.invalidate()

        assertNull(candidates.cachedWatchlistCandidatesFor(serverId, ITEM))
    }

    @Test
    fun aLoadThatOutlivesARebindDoesNotRepopulateTheCache() = runTest {
        var sources = listOf(FakeWatchlistSource(CatalogSourceId.TRAKT))
        val candidates = LibraryWatchlistCandidates { sources }
        val client = ExternalIdsServer(ExternalIds(imdb = "tt1")).apply { gate = CompletableDeferred() }

        val stale = async { candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client) }
        runCurrent()
        candidates.invalidate()
        val simkl = FakeWatchlistSource(CatalogSourceId.SIMKL)
        sources = listOf(simkl)
        val fresh = async { candidates.watchlistCandidatesFor(serverId, ITEM, MediaKind.MOVIE, client) }
        runCurrent()
        client.gate!!.complete(Unit)

        assertEquals(listOf(CatalogSourceId.TRAKT), stale.await().map { it.source.id })
        assertEquals(listOf(CatalogSourceId.SIMKL), fresh.await().map { it.source.id })
        assertEquals(2, client.fetches, "a load started after the rebind doesn't join the one started before it")
        assertSame(simkl, candidates.cachedWatchlistCandidatesFor(serverId, ITEM)?.single()?.source)
    }

    // Mutations.

    @Test
    fun dispatchesAddAndRemoveToTheCandidateSource() = runTest {
        val source = FakeWatchlistSource(CatalogSourceId.TRAKT)
        val candidates = LibraryWatchlistCandidates { emptyList() }
        val candidate = WatchlistCandidate(source, CatalogItemIds(imdb = "tt1"))

        assertTrue(candidates.mutateWatchlistMembership(MediaKind.MOVIE, candidate, add = true))
        assertTrue(candidates.mutateWatchlistMembership(MediaKind.MOVIE, candidate, add = false))

        assertEquals(listOf(true, false), source.mutations.map { it.add })
        assertEquals("tt1", source.mutations.first().ids.imdb)
    }

    @Test
    fun anIdenticalMutationAlreadyInFlightIsRefusedInsteadOfDoubleFiring() = runTest {
        val gate = CompletableDeferred<Unit>()
        val source = FakeWatchlistSource(CatalogSourceId.TRAKT, mutationGate = gate)
        val candidates = LibraryWatchlistCandidates { emptyList() }
        val candidate = WatchlistCandidate(source, CatalogItemIds(imdb = "tt1"))

        val first = async { candidates.mutateWatchlistMembership(MediaKind.MOVIE, candidate, add = true) }
        runCurrent()
        assertFalse(candidates.mutateWatchlistMembership(MediaKind.MOVIE, candidate, add = true))
        assertTrue(source.mutations.isEmpty())

        gate.complete(Unit)
        assertTrue(first.await())
        assertEquals(1, source.mutations.size)

        // The guard releases with the mutation.
        assertTrue(candidates.mutateWatchlistMembership(MediaKind.MOVIE, candidate, add = false))
        assertEquals(2, source.mutations.size)
    }

    @Test
    fun aFailedMutationRethrowsAndReleasesTheGuard() = runTest {
        val candidates = LibraryWatchlistCandidates { emptyList() }
        val failing = FakeWatchlistSource(CatalogSourceId.TRAKT, mutationError = IllegalStateException("api down"))

        assertFailsWith<IllegalStateException> {
            candidates.mutateWatchlistMembership(MediaKind.MOVIE, WatchlistCandidate(failing, CatalogItemIds(imdb = "tt1")), add = true)
        }

        val working = FakeWatchlistSource(CatalogSourceId.TRAKT)
        assertTrue(candidates.mutateWatchlistMembership(MediaKind.MOVIE, WatchlistCandidate(working, CatalogItemIds(imdb = "tt1")), add = true))
        assertEquals(1, working.mutations.size)
    }
}
