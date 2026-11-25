package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

enum class WatchMarkOutcome {
    /** Queued for the next sync; the offline queue emitted the event. */
    QUEUED_OFFLINE,

    /** Marked on the server; the event emitted and the trackers told. */
    MARKED,

    /** Nothing to do: no server id, or no client bound for it. */
    SKIPPED,
}

/**
 * The user's watched and unwatched marks: offline ones go to the offline queue, online ones to the server, then the
 * single watch-state event and the trackers. Screens call this, never [MediaBackend.markWatched] directly; messages
 * and refreshes stay with the caller.
 */
class WatchActions(
    private val clients: WatchClients,
    private val offlineMode: OfflineModeSource,
    private val offlineWatch: OfflineWatchProvider,
    private val notifier: WatchStateNotifier,
    private val trackers: TrackerWatchMarks,
    private val scope: CoroutineScope,
) {
    /** Marks [item] watched or unwatched. [offline] overrides the app's offline state (downloaded-content screens). */
    suspend fun setWatched(item: MediaItem, watched: Boolean, offline: Boolean? = null): WatchMarkOutcome {
        val serverId = ServerId.tryParse(item.serverId)
        if ((offline ?: offlineMode.isOffline.value) && serverId != null) {
            if (watched) offlineWatch.markAsWatched(serverId, item.id) else offlineWatch.markAsUnwatched(serverId, item.id)
            return WatchMarkOutcome.QUEUED_OFFLINE
        }
        if (serverId == null) return WatchMarkOutcome.SKIPPED
        val client = clients.client(serverId) ?: return WatchMarkOutcome.SKIPPED
        if (watched) client.markWatched(item) else client.markUnwatched(item)
        notifier.notifyWatched(item, isNowWatched = watched, cacheServerId = client.cacheServerId, serverAcknowledged = true)
        scope.launch { trackers.mark(item, client, watched) }
        return WatchMarkOutcome.MARKED
    }

    /** Removes [item] from Continue Watching, watch state untouched. Throws when no client is bound for its server. */
    suspend fun removeFromContinueWatching(item: MediaItem) {
        val client = ServerId.tryParse(item.serverId)?.let(clients::client) ?: throw IllegalStateException(T.errors.noClientAvailable)
        client.removeFromContinueWatching(item)
        notifier.notifyRemovedFromContinueWatching(item)
    }
}

/**
 * Settles a watched crossing the server never saw as one (offline replay, a player app, a same-file sibling): a
 * backend that doesn't mark on a stopped report gets the explicit [MediaBackend.markWatched] and an acknowledged
 * event; one that does gets no call and an unacknowledged event, since a report's success doesn't prove the mark.
 */
suspend fun MediaBackend.markWatchedFromPlaybackStop(item: MediaItem, notifier: WatchStateNotifier) {
    val explicitMark = !marksWatchedOnPlaybackStopped
    if (explicitMark) markWatched(item)
    notifier.notifyWatched(item, isNowWatched = true, cacheServerId = cacheServerId, serverAcknowledged = explicitMark)
}

/**
 * The local watched event for a crossing a live reporting session already gave the server (a report below the
 * threshold, then one past it), with no server call: an explicit mark on top records the watch twice, a second Trakt
 * scrobble on Jellyfin, a second play and inflated view count on Plex. Unacknowledged; keep the
 * returned id to promote it after a later explicit mark.
 */
fun MediaBackend.notifyWatchedFromPlaybackSession(item: MediaItem, notifier: WatchStateNotifier): WatchPatchId? =
    notifier.notifyWatched(item, isNowWatched = true, cacheServerId = cacheServerId, serverAcknowledged = false)
