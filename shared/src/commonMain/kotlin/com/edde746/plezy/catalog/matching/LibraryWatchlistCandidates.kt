package com.edde746.plezy.catalog.matching

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlin.concurrent.atomics.AtomicReference
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.coroutines.cancellation.CancellationException

private const val TAG = "WatchlistCandidates"

/** A watchlist-capable catalog source paired with a library item's ids in that source's terms. */
data class WatchlistCandidate(val source: CatalogSource, val ids: CatalogItemIds)

/**
 * Which of [sources] can hold library item [itemId] on their watchlist, with the ids each needs for membership and
 * mutation. The item's external ids come from its own server ([client]); each source maps them to its own id forms
 * (MyAnimeList and AniList through the anime mappings, Plex Discover server-side). A source that can't hold the item
 * (non-anime on MyAnimeList, no usable ids) is absent from the answer. A source whose resolution fails is logged,
 * skipped and reported to [onSourceFailed], so one flaky provider doesn't hide the rest and the caller can tell the
 * partial answer from a complete one. A failed external-id fetch throws.
 */
internal suspend fun resolveWatchlistCandidates(
    client: MediaBackend?,
    itemId: String,
    kind: MediaKind,
    sources: List<CatalogSource>,
    onSourceFailed: (CatalogSource) -> Unit = {},
): List<WatchlistCandidate> {
    if (client == null || sources.isEmpty()) return emptyList()
    val ids = client.fetchExternalIds(itemId)
    if (!ids.hasAny) return emptyList()
    val candidates = ArrayList<WatchlistCandidate>()
    for (source in sources) {
        try {
            source.resolveItemIds(kind, ids)?.let { candidates += WatchlistCandidate(source, it) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Watchlist external-id resolution failed for ${source.id.id}" }
            onSourceFailed(source)
        }
    }
    return candidates
}

/**
 * The watchlist candidates of library items for one session, shared by the media detail screen and the item menus so an
 * item fetches its external ids at most once per session; and the watchlist mutations those surfaces start.
 *
 * [sources] are the connected catalog sources, read when a load starts; only those with a watchlist are asked. The
 * owner calls [invalidate] whenever the sources rebind.
 */
@OptIn(ExperimentalAtomicApi::class)
class LibraryWatchlistCandidates(private val sources: () -> List<CatalogSource>) {
    /** Complete answers by item key; [generation] advances on [invalidate]. */
    private class Cache(val generation: Int, val results: Map<String, List<WatchlistCandidate>>)

    /** A load in flight, started under cache [generation]. */
    private class Load(val generation: Int, val result: CompletableDeferred<List<WatchlistCandidate>>)

    /** Completes a load whose owner was cancelled: its waiters start a load of their own. */
    private class OwnerCancelled : Exception()

    private val cache = AtomicReference(Cache(0, emptyMap()))
    private val lock = Mutex()
    private val loads = HashMap<String, Load>()
    private val mutationsInFlight = HashSet<String>()

    /**
     * Every watchlist-capable source item [itemId] on [serverId] exists in, with its ids there. A complete answer is
     * kept for the session; one missing a source that failed to resolve is not (it would hide that source's action for
     * the session), nor is a failure, which throws. A null [client] (the server is offline) answers empty without
     * caching. Concurrent calls for one item share one load.
     */
    suspend fun watchlistCandidatesFor(serverId: ServerId, itemId: String, kind: MediaKind, client: MediaBackend?): List<WatchlistCandidate> {
        val key = itemKey(serverId, itemId)
        while (true) {
            val known = cache.load()
            known.results[key]?.let { return it }
            if (client == null) return emptyList()
            var owner = false
            val load = lock.withLock {
                loads[key]?.takeIf { it.generation == known.generation }
                    ?: Load(known.generation, CompletableDeferred()).also {
                        loads[key] = it
                        owner = true
                    }
            }
            if (!owner) {
                try {
                    return load.result.await()
                } catch (_: OwnerCancelled) {
                    continue
                }
            }
            val candidates = try {
                var complete = true
                resolveWatchlistCandidates(client, itemId, kind, sources().filter { it.supportsWatchlist }) { complete = false }
                    .also { if (complete) store(load.generation, key, it) }
            } catch (e: Throwable) {
                settle(key, load) { load.result.completeExceptionally(if (e is CancellationException) OwnerCancelled() else e) }
                throw e
            }
            settle(key, load) { load.result.complete(candidates) }
            return candidates
        }
    }

    /**
     * The candidates already resolved for item [itemId] on [serverId], or null when not resolved this session. Menus
     * label from this without waiting; empty means no connected source can hold the item.
     */
    fun cachedWatchlistCandidatesFor(serverId: ServerId, itemId: String): List<WatchlistCandidate>? =
        cache.load().results[itemKey(serverId, itemId)]

    /** Drops every resolved answer; loads in flight finish without caching, and later calls start afresh. */
    fun invalidate() {
        while (true) {
            val known = cache.load()
            if (cache.compareAndSet(known, Cache(known.generation + 1, emptyMap()))) return
        }
    }

    /**
     * Adds [candidate]'s item to its source's watchlist, or removes it. False when the identical mutation (same
     * source, [kind] and canonical id) is already in flight and nothing ran: surfaces that outlive their tap (menus)
     * can't double-fire. API failures propagate to the caller, which owns the user feedback.
     */
    suspend fun mutateWatchlistMembership(kind: MediaKind, candidate: WatchlistCandidate, add: Boolean): Boolean {
        val key = "${candidate.source.id.id}/${kind.id}/${candidate.ids.canonicalKey.orEmpty()}"
        if (!lock.withLock { mutationsInFlight.add(key) }) return false
        try {
            if (add) {
                candidate.source.addToWatchlist(kind, candidate.ids)
            } else {
                candidate.source.removeFromWatchlist(kind, candidate.ids)
            }
            return true
        } finally {
            withContext(NonCancellable) { lock.withLock { mutationsInFlight.remove(key) } }
        }
    }

    /** Keeps [candidates] for [key] unless an [invalidate] came after the load started. */
    private fun store(generation: Int, key: String, candidates: List<WatchlistCandidate>) {
        while (true) {
            val known = cache.load()
            if (known.generation != generation) return
            if (cache.compareAndSet(known, Cache(generation, known.results + (key to candidates)))) return
        }
    }

    private suspend fun settle(key: String, load: Load, complete: () -> Unit) = withContext(NonCancellable) {
        lock.withLock { if (loads[key] === load) loads.remove(key) }
        complete()
    }

    private fun itemKey(serverId: ServerId, itemId: String): String = "$serverId/$itemId"
}
