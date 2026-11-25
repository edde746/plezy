package com.edde746.plezy.profiles

import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.ConnectionSummary
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours

/**
 * The Home users of each signed-in Plex account ([users], by account connection id). Plex owns them, so they're never
 * profile rows: each account's list is cached in the settings (`plex_home_users_<id>`) for cold starts and fetched again
 * from plex.tv ([fetchHomeUsers], with the account token) when an account appears, at [start] and every
 * [refreshInterval].
 *
 * A fetch is kept only while it's the account's newest one, the account still exists and its token hasn't changed;
 * otherwise the cache it wrote is put back. A list equal to the stored one isn't written again. When an account goes,
 * its cache and its bindings go with it, unless the same account came back meanwhile.
 *
 * Confined to [scope]'s thread, like the server manager.
 */
class PlexHomeService(
    private val connections: ConnectionStore,
    private val bindings: ProfileConnectionRegistry,
    private val identity: ProfileIdentity,
    private val fetchHomeUsers: suspend (accountToken: String) -> List<PlexHomeUser>,
    scope: CoroutineScope,
    private val refreshInterval: Duration = 1.hours,
) {
    private val work = scope.childScope()
    private val cache = MutableStateFlow<Map<String, List<PlexHomeUser>>>(emptyMap())

    /** The cached Home users by Plex account connection id. */
    val users: StateFlow<Map<String, List<PlexHomeUser>>> = cache.asStateFlow()

    private val generations = HashMap<String, Int>()
    private val activeRefreshes = HashMap<String, Deferred<Boolean>>()

    // The list last known to be stored for each account.
    private val committed = HashMap<String, List<PlexHomeUser>>()
    private val knownIds = HashSet<String>()

    // One cache write (and its check and undo) at a time; a removal waits for the write in flight.
    private val commits = Mutex()
    private var epoch = 0
    private var hydration: Deferred<Unit>? = null
    private var running = false
    private var clearing = false
    private var closed = false

    /** Loads every Plex account's cached users from the settings; no network, no watching. Runs once. */
    suspend fun hydrate() {
        if (closed) return
        val pass = hydration ?: work.async { loadAll(epoch) }.also { hydration = it }
        try {
            pass.await()
        } catch (e: Exception) {
            if (hydration === pass) hydration = null
            throw e
        }
    }

    /** [hydrate], then watches the accounts and refreshes every one now and every [refreshInterval]. Runs once. */
    fun start() {
        if (closed || running) return
        running = true
        work.launch {
            hydrate()
            launch { connections.observeSummaries().collect(::onConnectionsChanged) }
            launch {
                while (true) {
                    delay(refreshInterval)
                    refreshAll()
                }
            }
            refreshAll()
        }
    }

    /**
     * Fetches [account]'s Home users now and caches them; returns whether that succeeded (a failed fetch is not "no
     * users"). A newer refresh of the same account supersedes this one.
     */
    suspend fun refresh(account: PlexAccountConnection): Boolean = startRefresh(account).await()

    /** Reads the stored caches again: an import may have written them after [hydrate]. */
    suspend fun reloadFromStorage() {
        hydrate()
        val started = epoch
        val plexIds = connections.list().mapNotNull { it.plexAccount()?.id }.toSet()
        if (!isLifecycleCurrent(started)) return
        cache.update { current -> current.filterKeys { it in plexIds } }
        committed.keys.retainAll(plexIds)
        for (id in plexIds) {
            if (!isLifecycleCurrent(started)) return
            loadCached(id)
        }
    }

    /** Forgets every account's users, in memory and stored (signing out of everything). */
    suspend fun clearAll() {
        if (closed || clearing) return
        clearing = true
        epoch++
        activeRefreshes.clear()
        try {
            commits.withLock {
                cache.value = emptyMap()
                committed.clear()
                identity.clearAllPlexHomeUsers()
            }
        } finally {
            clearing = false
        }
    }

    /** Stops watching and refreshing; refreshes in flight are dropped. */
    fun close() {
        closed = true
        epoch++
        activeRefreshes.clear()
        work.cancel()
    }

    private suspend fun loadAll(started: Int) {
        val ids = connections.list().mapNotNull { it.plexAccount()?.id }
        if (!isLifecycleCurrent(started)) return
        knownIds.clear()
        knownIds.addAll(ids)
        for (id in ids) {
            if (!isLifecycleCurrent(started)) return
            loadCached(id)
        }
    }

    private suspend fun loadCached(connectionId: String) {
        val cached = readCache(connectionId)
        if (cached == null) {
            committed.remove(connectionId)
            return
        }
        committed[connectionId] = cached
        cache.update { it + (connectionId to cached) }
    }

    private suspend fun readCache(connectionId: String): List<PlexHomeUser>? = try {
        identity.plexHomeUsers(connectionId)
    } catch (e: IllegalArgumentException) {
        Log.w(TAG, e) { "The Home users cache of $connectionId doesn't read" }
        null
    }

    private suspend fun onConnectionsChanged(current: List<ConnectionSummary>) {
        val started = epoch
        if (!isLifecycleCurrent(started)) return
        val ids = current.filter { it.kind == BackendKind.PLEX }.mapTo(LinkedHashSet()) { it.id }
        val tracked = cache.value.keys
        val removed = knownIds - ids
        knownIds.clear()
        knownIds.addAll(ids)
        for (id in removed) {
            invalidate(id)
            commits.withLock {
                if (!isLifecycleCurrent(started)) return
                // The same account may have been stored again while a write was settling.
                val replacement = connections.get(id)?.plexAccount()
                if (replacement != null) {
                    scheduleRefresh(replacement)
                } else {
                    cache.update { it - id }
                    committed.remove(id)
                    identity.clearPlexHomeUsers(id)
                    bindings.removeAllForConnection(id)
                }
            }
            if (!isLifecycleCurrent(started)) return
        }
        for (id in ids) {
            if (id in tracked) continue
            // A summary carries no token; the refresh needs the stored account.
            val account = connections.get(id)?.plexAccount() ?: continue
            if (!isLifecycleCurrent(started)) return
            scheduleRefresh(account)
        }
    }

    private suspend fun refreshAll() {
        val started = epoch
        val accounts = connections.list().mapNotNull { it.plexAccount() }
        if (!isLifecycleCurrent(started)) return
        accounts.forEach(::scheduleRefresh)
    }

    /** A background refresh joins one in flight for the account. */
    private fun scheduleRefresh(account: PlexAccountConnection) {
        if (activeRefreshes[account.id] == null) startRefresh(account)
    }

    private fun startRefresh(account: PlexAccountConnection): Deferred<Boolean> {
        if (closed || clearing) return CompletableDeferred(false)
        val generation = (generations[account.id] ?: 0) + 1
        generations[account.id] = generation
        val started = epoch
        var owner: Deferred<Boolean>? = null
        val refresh = work.async(start = CoroutineStart.LAZY) {
            try {
                fetchAndCache(account) { isLifecycleCurrent(started) && generations[account.id] == generation && activeRefreshes[account.id] === owner }
            } finally {
                if (activeRefreshes[account.id] === owner) activeRefreshes.remove(account.id)
            }
        }
        owner = refresh
        activeRefreshes[account.id] = refresh
        refresh.start()
        return refresh
    }

    private suspend fun fetchAndCache(account: PlexAccountConnection, isCurrent: () -> Boolean): Boolean {
        val id = account.id
        try {
            if (!isCurrent()) return false
            if (account.accountToken.isEmpty()) {
                Log.w(TAG) { "Not fetching the Home users of ${account.accountLabel} ($id): no token" }
                return false
            }
            val fetched = fetchHomeUsers(account.accountToken)
            if (!isCurrent()) return false
            // A sign-out while plex.tv answered: caching now would bring its profiles back.
            if (connections.get(id) == null) {
                Log.d(TAG) { "Dropping the Home users of removed account ${account.accountLabel}" }
                return false
            }
            return commits.withLock {
                if (!isCurrent()) return@withLock false
                if (committed[id] == fetched && cache.value[id] == fetched) return@withLock true
                val previous = readCache(id)
                identity.savePlexHomeUsers(id, fetched)
                committed[id] = fetched
                val latest = connections.get(id)?.plexAccount()
                if (!isCurrent() || latest?.accountToken != account.accountToken) {
                    if (previous == null) {
                        identity.clearPlexHomeUsers(id)
                        committed.remove(id)
                    } else {
                        identity.savePlexHomeUsers(id, previous)
                        committed[id] = previous
                    }
                    if (latest != null && !closed && !clearing) work.launch { scheduleRefresh(latest) }
                    return@withLock false
                }
                cache.update { it + (id to fetched) }
                Log.d(TAG) { "Cached ${fetched.size} Home users of ${account.accountLabel}" }
                true
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Refreshing the Home users of ${account.accountLabel} failed" }
            return false
        }
    }

    private fun invalidate(connectionId: String) {
        generations[connectionId] = (generations[connectionId] ?: 0) + 1
        activeRefreshes.remove(connectionId)
    }

    private fun isLifecycleCurrent(started: Int): Boolean = !closed && !clearing && epoch == started

    private companion object {
        const val TAG = "PlexHome"
    }
}
