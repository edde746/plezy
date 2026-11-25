package com.edde746.plezy.servers

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.parseGlobalKey
import kotlin.time.Clock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * A patch rebuilt from the persisted offline queue: [globalKey] already resolved through the queued client scope,
 * [updatedAt] (epoch ms) and [order] the row's, so freshness survives a restart. [patchId] is the row's durable id.
 */
data class HydratedWatchStatePatch(
    val globalKey: String,
    val patch: WatchStateSnapshot,
    val updatedAt: Long,
    val order: Long,
    val patchId: WatchPatchId? = null,
)

/** An item an authoritative response returned, with the cache scope of the client that fetched it. */
data class ObservedRow(val item: MediaItem, val clientScope: String?)

/**
 * The session's watch-state overlay. Server fetches stay the source of truth and items are never mutated to show a
 * watch event: every [WatchStateEvent] with a non-empty patch lands here, and consumers resolve items at the point of
 * use ([apply], [applyAll], [patchForItem], [freshWatchState]).
 *
 * Resolution follows the hierarchy: an item's effective patch is the newest among its own and its
 * [MediaItem.parentChain] ancestors' (newer: later `updatedAt`, then a session event over a hydrated one, then the
 * later sequence), so a show mark reaches every episode while a later per-item event still overrides it.
 *
 * User-scoped backends ([setActiveClientScopesByServer]) key patches by `"{scope}:{itemId}"`; lookups try the active
 * scope, then the public key.
 *
 * An acknowledged patch yields once an authoritative read that started after it returns the item
 * ([observationWatermark], [recordObservations]); a patch still owed to the server never does.
 */
class WatchStateStore(notifier: WatchStateNotifier, scope: CoroutineScope, private val clock: Clock = Clock.System) {
    private val state = MutableStateFlow(State())

    /**
     * This store's identity: watermarks mean nothing to another store, and requests outlive a profile session, so
     * [recordObservations] rejects another epoch.
     */
    val observationEpoch: Any = Any()

    /** Capture right before an authoritative request; pass it back to [recordObservations] when it succeeds. */
    val observationWatermark: Long get() = state.value.sequence

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { notifier.events.collect(::onEvent) }
        scope.launch(start = CoroutineStart.UNDISPATCHED) { notifier.promotions.collect { onPromotion(it.patchId) } }
    }

    fun patchForItem(item: MediaItem): WatchStateSnapshot? = state.value.patchForItem(item)

    /** The patch stored under [globalKey] itself, ancestors ignored. */
    internal fun patchForGlobalKey(globalKey: String): WatchStateSnapshot? = state.value.patchForGlobalKey(globalKey)

    fun apply(item: MediaItem): MediaItem = applyPatch(item, patchForItem(item))

    fun applyAll(items: List<MediaItem>): List<MediaItem> {
        val current = state.value
        if (current.isEmpty) return items
        return items.map { applyPatch(it, current.patchForItem(it)) }
    }

    /** Emits after every change of the overlay: a screen resolving its items as it renders renders again. */
    val changes: Flow<Unit> get() = state.drop(1).map { }

    /** [item] resolved now and again whenever its effective patch changes. */
    fun freshWatchState(item: MediaItem): Flow<MediaItem> =
        state.map { it.patchForItem(item) }.distinctUntilChanged().map { applyPatch(item, it) }

    fun freshWatchState(items: List<MediaItem>): Flow<List<MediaItem>> =
        state.map { current -> items.map { current.patchForItem(it) } }
            .distinctUntilChanged()
            .map { patches -> items.mapIndexed { i, item -> applyPatch(item, patches[i]) } }

    /**
     * Records that a successful authoritative response returned [rows]. [watermark] is the [observationWatermark]
     * captured before the request, [epoch] the [observationEpoch] of the store that captured it. Patches recorded
     * during the request keep a higher sequence and survive. An observation is kept only for an item some acknowledged
     * patch could still apply to, and only ever raised.
     */
    fun recordObservations(rows: Iterable<ObservedRow>, watermark: Long, epoch: Any) {
        if (epoch !== observationEpoch) return
        val observed = rows.toList()
        state.update { s ->
            if (s.patches.isEmpty()) return@update s
            var observedAt = s.observedAt
            for (row in observed) {
                val item = row.item
                if (!s.hasSuppressibleEntry(item)) continue
                val scope = row.clientScope
                val key = if (!scope.isNullOrEmpty() && scope != item.serverId) "$scope:${item.id}" else item.globalKey
                val existing = observedAt[key]
                if (existing != null && existing >= watermark) continue
                observedAt = observedAt + (key to watermark)
            }
            s.copy(observedAt = observedAt)
        }
    }

    /** A different profile clears every patch and observation. */
    fun setActiveProfileId(profileId: String?) {
        state.update { s ->
            if (s.activeProfileId == profileId) s else State(activeProfileId = profileId, scopes = s.scopes, sequence = s.sequence)
        }
    }

    /** Each server's active client scope; null, empty and the server's own id mean unscoped. */
    fun setActiveClientScopesByServer(scopes: Map<ServerId, String?>) {
        val normalized = buildMap {
            for ((serverId, scope) in scopes) if (!scope.isNullOrEmpty() && scope != serverId.value) put(serverId, scope)
        }
        state.update { it.copy(scopes = normalized) }
    }

    /** Replaces the persisted-queue layer wholesale; session events stay. */
    fun setHydratedPatches(patches: Iterable<HydratedWatchStatePatch>) {
        val next = mutableMapOf<String, PatchEntry>()
        for (hydrated in patches) {
            val candidate = PatchEntry(hydrated.patch, hydrated.updatedAt, hydrated.order, isSessionEvent = false, patchId = hydrated.patchId)
            val existing = next[hydrated.globalKey]
            if (existing == null || candidate.isNewerThan(existing)) next[hydrated.globalKey] = candidate
        }
        state.update { it.copy(hydrated = next) }
    }

    private fun onEvent(event: WatchStateEvent) {
        val snapshot = WatchStateSnapshot.fromEvent(event)
        if (snapshot.isEmpty) return
        val now = clock.now().toEpochMilliseconds()
        state.update { s ->
            val serverId = event.serverId.value
            val activeScope = s.scopes[event.serverId]
            val eventScope = event.cacheServerId?.takeIf { it.isNotEmpty() }
            if (activeScope != null && eventScope != null && eventScope != serverId && eventScope != activeScope) return@update s
            val resolvedScope = activeScope ?: eventScope
            val key = if (resolvedScope != null && resolvedScope != serverId) "$resolvedScope:${event.itemId}" else event.globalKey
            val sequence = s.sequence + 1
            val entry = PatchEntry(snapshot, now, sequence, isSessionEvent = true, serverAcknowledged = event.serverAcknowledged, patchId = event.patchId)
            s.copy(patches = s.patches + (key to entry), sequence = sequence)
        }
    }

    /**
     * The write behind [patchId] settled, so its entry may now yield to a later read. Matched by identity only: an
     * unknown id (replaced by a newer action, or from before a restart) is a no-op. The fresh sequence keeps an
     * observation captured before the write landed from suppressing it. A hydrated entry moves to the session layer,
     * never over a different session entry on its key.
     */
    private fun onPromotion(patchId: WatchPatchId) {
        state.update { s ->
            val sequence = s.sequence + 1
            val sessionKey = s.patches.keyOf(patchId)
            if (sessionKey != null) {
                return@update s.copy(patches = s.patches + (sessionKey to s.patches.getValue(sessionKey).acknowledgedAt(sequence)), sequence = sequence)
            }
            val hydratedKey = s.hydrated.keyOf(patchId) ?: return@update s
            val promoted = s.hydrated.getValue(hydratedKey)
            val existing = s.patches[hydratedKey]
            if (existing == null || existing.patchId == patchId) {
                s.copy(hydrated = s.hydrated - hydratedKey, patches = s.patches + (hydratedKey to promoted.acknowledgedAt(sequence)), sequence = sequence)
            } else {
                s.copy(hydrated = s.hydrated - hydratedKey)
            }
        }
    }

    private data class PatchEntry(
        val patch: WatchStateSnapshot,
        val updatedAt: Long,
        val sequence: Long,
        val isSessionEvent: Boolean,
        val serverAcknowledged: Boolean = false,
        val patchId: WatchPatchId? = null,
    ) {
        fun acknowledgedAt(sequence: Long) = copy(sequence = sequence, isSessionEvent = true, serverAcknowledged = true)

        fun isNewerThan(other: PatchEntry): Boolean = when {
            updatedAt != other.updatedAt -> updatedAt > other.updatedAt
            isSessionEvent != other.isSessionEvent -> isSessionEvent
            else -> sequence > other.sequence
        }
    }

    private data class State(
        val patches: Map<String, PatchEntry> = emptyMap(),
        val hydrated: Map<String, PatchEntry> = emptyMap(),
        val activeProfileId: String? = null,
        val scopes: Map<ServerId, String> = emptyMap(),
        val sequence: Long = 0,
        /** The highest watermark at which an authoritative read returned each scope-resolved key. */
        val observedAt: Map<String, Long> = emptyMap(),
    ) {
        val isEmpty: Boolean get() = patches.isEmpty() && hydrated.isEmpty()

        /** The active client scope's key first, then the public one. */
        fun candidateKeys(globalKey: String): List<String> {
            val (serverId, id) = parseGlobalKey(globalKey) ?: return listOf(globalKey)
            val scoped = scopes[serverId] ?: return listOf(globalKey)
            return listOf("$scoped:$id", globalKey)
        }

        /**
         * The newer of the key's session and hydrated entries. An acknowledged session entry the server re-observed
         * since drops out first, so an older hydrated one (an owed write) still shows.
         */
        fun exactEntry(key: String, observedAt: Long?): PatchEntry? {
            val session = patches[key]?.takeUnless { it.serverAcknowledged && observedAt != null && observedAt >= it.sequence }
            val hydratedEntry = hydrated[key]
            if (session == null) return hydratedEntry
            if (hydratedEntry == null) return session
            return if (session.isNewerThan(hydratedEntry)) session else hydratedEntry
        }

        fun entryFor(globalKey: String, observedAt: Long?): PatchEntry? = candidateKeys(globalKey).firstNotNullOfOrNull { exactEntry(it, observedAt) }

        /**
         * Observation through the primary candidate only: on a user-scoped backend the public id is shared, so a
         * public observation must not suppress one user's scoped patch.
         */
        fun observationFor(globalKey: String): Long? = observedAt[candidateKeys(globalKey).first()]

        fun patchForGlobalKey(globalKey: String): WatchStateSnapshot? = entryFor(globalKey, observationFor(globalKey))?.patch

        /**
         * The item's own observation is one barrier for its ancestors too: a read of the item already includes any
         * container mark before it, so suppressing only the item's entry must not let an older season patch win.
         */
        fun patchForItem(item: MediaItem): WatchStateSnapshot? {
            if (isEmpty) return null
            val observed = observationFor(item.globalKey)
            var best = entryFor(item.globalKey, observed)
            val serverId = ServerId.tryParse(item.serverId)
            for (parentId in item.parentChain) {
                val entry = entryFor(serverId?.let { buildGlobalKey(it, parentId) } ?: parentId, observed) ?: continue
                if (best == null || entry.isNewerThan(best)) best = entry
            }
            return best?.patch
        }

        fun hasSuppressibleEntry(item: MediaItem): Boolean {
            if (candidateKeys(item.globalKey).any { patches[it]?.serverAcknowledged == true }) return true
            val serverId = ServerId.tryParse(item.serverId)
            return item.parentChain.any { parentId ->
                candidateKeys(serverId?.let { buildGlobalKey(it, parentId) } ?: parentId).any { patches[it]?.serverAcknowledged == true }
            }
        }
    }

    companion object {
        fun applyPatch(item: MediaItem, patch: WatchStateSnapshot?): MediaItem = patch?.apply(item) ?: item

        private fun Map<String, PatchEntry>.keyOf(patchId: WatchPatchId): String? = entries.firstOrNull { it.value.patchId == patchId }?.key
    }
}
