package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.isWatchedProgress
import kotlin.concurrent.atomics.AtomicLong
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.jvm.JvmInline
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * The identity of the watch-state overlay entry an event creates, so the write behind it can settle that exact entry
 * later ([WatchStateNotifier.promote]); promotion never matches by item, since a same-item rewatch may have replaced
 * the entry.
 *
 * Two forms: [session] is minted per event and dies with the process (a live playback crossing); [offlineAction] is
 * derived from the persisted queue row, so emission, hydration after a restart and promotion still join.
 */
@JvmInline
value class WatchPatchId private constructor(val value: String) {
    /** The queued row's revision of an [offlineAction] id; null for a session id. */
    val offlineRevision: Long?
        get() {
            if (!value.startsWith("o:")) return null
            val separator = value.lastIndexOf(':')
            return if (separator < 2) null else value.substring(separator + 1).toLongOrNull()
        }

    override fun toString(): String = value

    companion object {
        fun session(sequence: Long): WatchPatchId = WatchPatchId("s:$sequence")

        fun offlineAction(profileId: String?, rowId: Long, revision: Long): WatchPatchId =
            WatchPatchId("o:${profileId.orEmpty()}:$rowId:$revision")
    }
}

enum class WatchStateChangeType { WATCHED, UNWATCHED, PROGRESS_UPDATE, REMOVED_FROM_CONTINUE_WATCHING }

/**
 * A watch-state change of one item.
 *
 * [cacheServerId] is the user-scoped cache namespace of the client the change went through (a Jellyfin user, a Plex
 * profile); screens still match by [serverId]. [librarySectionId] is the item's library, null when emitted without
 * metadata. [serverAcknowledged]: the server had already accepted this exact state, so a later authoritative read may
 * supersede the overlay entry; false means a write is still owed and no read may retire it. [patchId] identifies the
 * overlay entry for promotion; null for events nothing will settle.
 */
data class WatchStateEvent(
    override val itemId: String,
    override val serverId: ServerId,
    val changeType: WatchStateChangeType,
    override val parentChain: List<String>,
    val cacheServerId: String? = null,
    /** The new resume position for [WatchStateChangeType.PROGRESS_UPDATE]. */
    val viewOffset: Long? = null,
    val isNowWatched: Boolean? = null,
    val librarySectionId: String? = null,
    val serverAcknowledged: Boolean = false,
    val patchId: WatchPatchId? = null,
) : HierarchicalEvent

/** A queued write the server has now accepted. Its own stream: subscribers of watch-state changes never see it. */
data class WatchPatchPromotion(val patchId: WatchPatchId)

/** The app's watch-state changes and patch promotions. */
@OptIn(ExperimentalAtomicApi::class)
class WatchStateNotifier {
    private val _events = eventFlow<WatchStateEvent>()
    val events: SharedFlow<WatchStateEvent> = _events.asSharedFlow()

    private val _promotions = eventFlow<WatchPatchPromotion>()

    /**
     * Writes that settled. Deliberately apart from [events]: the offline sync purges queued progress on a watched or
     * unwatched event, and replaying one here would delete a newer rewatch.
     */
    val promotions: SharedFlow<WatchPatchPromotion> = _promotions.asSharedFlow()

    private val sequence = AtomicLong(0L)

    fun notify(event: WatchStateEvent) {
        Log.d(TAG) { "${event.changeType} ${event.globalKey}, parents ${event.parentChain}" }
        _events.tryEmit(event)
    }

    /**
     * A watched (or, [isNowWatched] false, unwatched) event for [item]. Returns the patch id used ([patchId] or a
     * minted session id); null, with a warning, when the item has no server.
     */
    fun notifyWatched(
        item: MediaItem,
        isNowWatched: Boolean = true,
        cacheServerId: String? = null,
        serverAcknowledged: Boolean = false,
        patchId: WatchPatchId? = null,
    ): WatchPatchId? {
        val serverId = serverIdForEvent(item, TAG, "watched") ?: return null
        val id = patchId ?: WatchPatchId.session(sequence.addAndFetch(1L))
        notify(
            WatchStateEvent(
                itemId = item.id,
                serverId = serverId,
                changeType = if (isNowWatched) WatchStateChangeType.WATCHED else WatchStateChangeType.UNWATCHED,
                parentChain = item.parentChain,
                cacheServerId = cacheServerId,
                isNowWatched = isNowWatched,
                librarySectionId = item.libraryId,
                serverAcknowledged = serverAcknowledged,
                patchId = id,
            ),
        )
        return id
    }

    /**
     * A progress event; it counts as watched past [watchedThreshold] (pass the server's
     * [com.edde746.plezy.backend.MediaBackend.watchedThreshold]). Returns the patch id as [notifyWatched] does.
     */
    fun notifyProgress(
        item: MediaItem,
        viewOffset: Long,
        duration: Long,
        cacheServerId: String? = null,
        watchedThreshold: Double = 0.9,
        serverAcknowledged: Boolean = false,
        patchId: WatchPatchId? = null,
    ): WatchPatchId? {
        val serverId = serverIdForEvent(item, TAG, "progress") ?: return null
        val id = patchId ?: WatchPatchId.session(sequence.addAndFetch(1L))
        notify(
            WatchStateEvent(
                itemId = item.id,
                serverId = serverId,
                changeType = WatchStateChangeType.PROGRESS_UPDATE,
                parentChain = item.parentChain,
                cacheServerId = cacheServerId,
                viewOffset = viewOffset,
                isNowWatched = isWatchedProgress(viewOffset, duration, watchedThreshold),
                librarySectionId = item.libraryId,
                serverAcknowledged = serverAcknowledged,
                patchId = id,
            ),
        )
        return id
    }

    fun notifyRemovedFromContinueWatching(item: MediaItem) {
        val serverId = serverIdForEvent(item, TAG, "continue-watching removal") ?: return
        notify(
            WatchStateEvent(
                itemId = item.id,
                serverId = serverId,
                changeType = WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING,
                parentChain = item.parentChain,
                librarySectionId = item.libraryId,
            ),
        )
    }

    /** The write behind [patchId] settled. */
    fun promote(patchId: WatchPatchId) {
        Log.d(TAG) { "promoting $patchId" }
        _promotions.tryEmit(WatchPatchPromotion(patchId))
    }

    private companion object {
        const val TAG = "WatchStateNotifier"
    }
}
