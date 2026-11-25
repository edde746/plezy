package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.sortEpisodesByWatchOrder
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** Offline "On Deck" and the manual marks made while offline. */
class OfflineWatchProvider(
    private val syncService: OfflineWatchSyncService,
    private val downloads: OfflineWatchDownloads,
    private val notifier: WatchStateNotifier,
    private val scope: CoroutineScope,
    /** The user's Specials placement, read per call. */
    private val specialsOrdering: () -> SpecialsOrdering,
    /** The "remove watched downloads" setting, read per mark. */
    private val autoRemoveWatchedDownloads: () -> Boolean,
) {
    /**
     * The show's next downloaded episode in watch order (Specials per [specialsOrdering]): the first not watched, by
     * its queued local action, else its downloaded metadata; every one watched → the first, to rewatch. Null without
     * downloads.
     */
    suspend fun getNextUnwatchedEpisode(showGlobalKey: String): MediaItem? {
        val episodes = sortEpisodesByWatchOrder(downloads.downloadedEpisodesForShow(showGlobalKey), specialsOrdering())
        if (episodes.isEmpty()) return null
        val local = syncService.getLocalWatchStatusesBatched(episodes.mapTo(mutableSetOf()) { it.globalKey })
        return episodes.firstOrNull { episode ->
            !(local[episode.globalKey] ?: downloads.metadata(episode.globalKey)?.isWatched ?: false)
        } ?: episodes.first()
    }

    /** Queues a watched mark and emits its event; removes the download when the setting says so. */
    suspend fun markAsWatched(serverId: ServerId, itemId: String) {
        val queued = syncService.queueMarkWatched(serverId, itemId)
        emit(serverId, itemId, watched = true, queued)
        if (autoRemoveWatchedDownloads()) scope.launch { autoRemove(buildGlobalKey(serverId, itemId)) }
    }

    suspend fun markAsUnwatched(serverId: ServerId, itemId: String) {
        val queued = syncService.queueMarkUnwatched(serverId, itemId)
        emit(serverId, itemId, watched = false, queued)
    }

    /** Through the downloaded metadata when there is one (with its parents), else a minimal event with none. */
    private suspend fun emit(serverId: ServerId, itemId: String, watched: Boolean, queued: QueuedOfflineWatchAction) {
        val patchId = WatchPatchId.offlineAction(queued.profileId, queued.rowId, queued.revision)
        val metadata = downloads.metadata(buildGlobalKey(serverId, itemId))
        if (metadata != null) {
            notifier.notifyWatched(metadata, isNowWatched = watched, cacheServerId = queued.clientScopeId, patchId = patchId)
            return
        }
        notifier.notify(
            WatchStateEvent(
                itemId = itemId,
                serverId = serverId,
                changeType = if (watched) WatchStateChangeType.WATCHED else WatchStateChangeType.UNWATCHED,
                parentChain = emptyList(),
                cacheServerId = queued.clientScopeId,
                isNowWatched = watched,
                patchId = patchId,
            ),
        )
    }

    private suspend fun autoRemove(globalKey: String) {
        try {
            downloads.deleteWatchedDownload(globalKey)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "failed to auto-delete locally watched download $globalKey" }
        }
    }

    private companion object {
        const val TAG = "OfflineWatchProvider"
    }
}
