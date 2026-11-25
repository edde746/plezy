package com.edde746.plezy.catalog

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaKind
import kotlin.concurrent.Volatile
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/** One snapshot page of watchlist membership: each group holds every key form of one watchlist entry. */
data class WatchlistKeyPage(val groups: List<List<String>>, val hasMore: Boolean)

/**
 * The watchlist half of [CatalogSource] for sources with a user watchlist: a session-long membership snapshot and
 * optimistic mutations. Subclasses supply key derivation, the snapshot page fetch and the mutation call.
 *
 * The snapshot maps every key form of an entry to the entry's whole key group, so a mutation carrying only some of the
 * entry's id forms (a media-detail remove works from server ids, without Trakt's trakt/slug) still drops the whole
 * entry; with a flat key set the sibling keys survived and membership stayed true for the session.
 */
abstract class CatalogWatchlistMachinery : CatalogSource {
    /** Log prefix naming the source and its list, e.g. `Trakt: watchlist`. */
    protected abstract val watchlistLogLabel: String

    /** Snapshot page size. */
    protected abstract val watchlistPageLimit: Int

    /** Pages read before the snapshot is truncated (and the truncation logged). */
    protected abstract val watchlistMaxPages: Int

    /** One snapshot page as key groups, one group per entry. [page] starts at 1. */
    protected abstract suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage

    /**
     * The API mutation for the resolved [ids]. The snapshot is loaded once per session, so a remove must not trust it:
     * where the service's delete takes more than the watchlist entry with it, re-read the entry first, leave anything
     * no longer on the watchlist alone, and call [reloadWatchlistSnapshot].
     */
    protected abstract suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean)

    /** Every membership key of [ids], namespaced by [kind] (`<kind>/<idform>`); sources with other identity rules override. */
    protected open fun membershipKeysFor(kind: MediaKind, ids: CatalogItemIds): List<String> = ids.allKeys.map { "${kind.id}/$it" }

    /**
     * The concrete ids the mutation needs (MAL maps external ids to a MAL id). Throws when the item cannot exist in
     * this source's domain. Default: [ids] unchanged.
     */
    protected open suspend fun resolveWatchlistMutationIds(kind: MediaKind, ids: CatalogItemIds): CatalogItemIds = ids

    override val supportsWatchlist: Boolean get() = true

    /** A loaded snapshot; [generation] changes only when a load replaces it, never on a mutation. */
    private class Snapshot(val generation: Long, val groups: Map<String, Set<String>>)

    @Volatile
    private var snapshot: Snapshot? = null
    private var generations = 0L
    private val snapshotLock = Mutex()
    private var inFlightLoad: CompletableDeferred<Unit>? = null

    @Volatile
    private var disposed = false
    private val changes = MutableSharedFlow<Unit>(extraBufferCapacity = 64, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    override val watchlistChanges: Flow<Unit> = changes.asSharedFlow()

    private fun notifyChanged() {
        if (!disposed) changes.tryEmit(Unit)
    }

    override suspend fun ensureWatchlistLoaded() {
        if (snapshot != null) return
        var owner = false
        val load = snapshotLock.withLock {
            if (snapshot != null) return
            inFlightLoad ?: CompletableDeferred<Unit>().also {
                inFlightLoad = it
                owner = true
            }
        }
        if (!owner) return load.await()
        try {
            loadSnapshot()
        } finally {
            withContext(NonCancellable) { snapshotLock.withLock { inFlightLoad = null } }
            load.complete(Unit)
        }
    }

    private suspend fun loadSnapshot() {
        val groups = HashMap<String, Set<String>>()
        try {
            var page = 1
            while (true) {
                val result = fetchWatchlistKeyPage(page, watchlistPageLimit)
                for (group in result.groups) {
                    val shared = group.toSet()
                    for (key in shared) groups[key] = shared
                }
                if (!result.hasMore) break
                if (page >= watchlistMaxPages) {
                    Log.w(TAG) { "$watchlistLogLabel snapshot truncated at ${groups.size} keys ($page pages)" }
                    break
                }
                page++
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "$watchlistLogLabel snapshot load failed" }
            return
        }
        snapshotLock.withLock { snapshot = Snapshot(++generations, groups) }
        notifyChanged()
    }

    /** Drops the snapshot and loads it afresh, for a source that found the service disagreeing with it. */
    protected suspend fun reloadWatchlistSnapshot() {
        snapshotLock.withLock { snapshot = null }
        ensureWatchlistLoaded()
    }

    override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? {
        val groups = snapshot?.groups ?: return null
        return membershipKeysFor(kind, ids).any(groups::containsKey)
    }

    override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutateWatchlist(kind, ids, add = true)

    override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) = mutateWatchlist(kind, ids, add = false)

    private suspend fun mutateWatchlist(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        val resolved = resolveWatchlistMutationIds(kind, ids)
        val keys = membershipKeysFor(kind, resolved)

        // Optimistic: flip the snapshot first so the UI toggles at once; revert on failure.
        var generation: Long? = null
        var addedGroup: Set<String>? = null
        var removedGroups: List<Set<String>> = emptyList()
        snapshotLock.withLock {
            val current = snapshot ?: return@withLock
            if (keys.isEmpty()) return@withLock
            val groups = current.groups.toMutableMap()
            if (add) {
                val group = keys.toSet()
                for (key in group) groups[key] = group
                addedGroup = group
            } else {
                removedGroups = takeGroups(groups, keys)
                if (removedGroups.isEmpty()) return@withLock
            }
            snapshot = Snapshot(current.generation, groups)
            generation = current.generation
        }
        if (generation != null) notifyChanged()

        try {
            performWatchlistMutation(kind, resolved, add)
        } catch (e: Throwable) {
            if (generation != null && revert(generation, addedGroup, removedGroups)) notifyChanged()
            throw e
        }
        // The optimistic notify (none without a snapshot, or when the snapshot already agreed) reached listeners
        // before the service had the change; listeners that read the service itself hear it now.
        notifyChanged()
    }

    /** Undoes an optimistic flip unless a load replaced the snapshot meanwhile; whether anything was undone. */
    private suspend fun revert(generation: Long?, addedGroup: Set<String>?, removedGroups: List<Set<String>>): Boolean =
        withContext(NonCancellable) {
            snapshotLock.withLock {
                val current = snapshot?.takeIf { it.generation == generation } ?: return@withLock false
                val groups = current.groups.toMutableMap()
                if (addedGroup != null) for (key in addedGroup) if (groups[key] === addedGroup) groups.remove(key)
                for (group in removedGroups) for (key in group) groups[key] = group
                snapshot = Snapshot(current.generation, groups)
                true
            }
        }

    /** Call from the subclass's [dispose]; later loads and mutations no longer emit [watchlistChanges]. */
    protected fun disposeWatchlistMachinery() {
        disposed = true
    }

    private companion object {
        const val TAG = "CatalogWatchlist"

        /** Removes every entry group any of [keys] hits from [groups], returning them for a revert. */
        fun takeGroups(groups: MutableMap<String, Set<String>>, keys: List<String>): List<Set<String>> {
            val hit = ArrayList<Set<String>>()
            for (key in keys) {
                val group = groups[key] ?: continue
                if (hit.none { it === group }) hit += group
            }
            for (group in hit) for (key in group) groups.remove(key)
            return hit
        }
    }
}
