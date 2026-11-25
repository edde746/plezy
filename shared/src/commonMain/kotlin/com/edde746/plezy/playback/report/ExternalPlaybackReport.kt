package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.isWatchedProgress
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.markWatchedFromPlaybackStop
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

private const val TAG = "ExternalPlaybackReport"

/**
 * Tells [backend] where a playback in another player app stopped, or queues it offline when there is no backend or
 * the stop fails.
 *
 * Nothing is reported for an error or an unknown position that isn't a completion. With [partTimeline] (an item
 * stacked across files) the file's position is placed on the item (its start plus the position; a completion is the
 * file's end) against the item's duration; else the duration is the player's, else the item's. The position is
 * clamped to the duration. Then a started report (DirectPlay; a failure is logged and the stop goes on) and a stopped
 * one; with a known duration a progress event, and past [MediaBackend.watchedThreshold] the watched mark
 * ([markWatchedFromPlaybackStop]) and the [trackers]' (in [scope]). [isLaunchCurrent] false (a newer launch replaced
 * this one) stops it between steps.
 */
suspend fun reportExternalPlayback(
    result: ExternalPlaybackResult,
    item: MediaItem,
    backend: MediaBackend?,
    notifier: WatchStateNotifier,
    trackers: TrackerWatchMarks,
    scope: CoroutineScope,
    offlineQueue: OfflineProgressQueue? = null,
    mediaSourceId: String? = null,
    partTimeline: MediaPartTimeline? = null,
    isLaunchCurrent: () -> Boolean = { true },
) {
    if (!isLaunchCurrent()) return
    if (result.error) {
        Log.d(TAG) { "the player app returned an error for ${item.id}; nothing to report" }
        return
    }

    val durationMs: Long?
    val reportedPositionMs: Long?
    if (partTimeline != null) {
        val part = partTimeline.current
        durationMs = partTimeline.duration.inWholeMilliseconds
        val filePositionMs = positive(result.positionMs)
        reportedPositionMs = when {
            filePositionMs != null -> part.start.inWholeMilliseconds + filePositionMs
            result.completed -> part.end.inWholeMilliseconds
            else -> null
        }
    } else {
        durationMs = positive(result.durationMs) ?: positive(item.durationMs)
        reportedPositionMs = positive(result.positionMs) ?: if (result.completed) durationMs else null
    }
    if (reportedPositionMs == null) return

    val position = (if (durationMs == null) reportedPositionMs else reportedPositionMs.coerceIn(0L, durationMs)).milliseconds
    val duration = durationMs?.milliseconds
    if (backend == null) {
        queueExternalProgress(item, offlineQueue, position, duration)
        return
    }

    var started = false
    try {
        backend.reportPlaybackStarted(
            itemId = item.id,
            position = position,
            duration = duration,
            playMethod = PlayMethod.DIRECT_PLAY,
            mediaSourceId = mediaSourceId,
        )
        started = true
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "started report for ${item.id} failed; sending the stop anyway" }
    }

    if (!isLaunchCurrent()) return
    try {
        backend.reportPlaybackStopped(itemId = item.id, position = position, duration = duration, mediaSourceId = mediaSourceId)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "failed to report the player app's progress for ${item.id}; queueing it" }
        if (!isLaunchCurrent()) return
        queueExternalProgress(item, offlineQueue, position, duration)
        return
    }

    if (!isLaunchCurrent()) return
    if (duration == null) return

    notifier.notifyProgress(
        item = item,
        viewOffset = position.inWholeMilliseconds,
        duration = duration.inWholeMilliseconds,
        cacheServerId = backend.cacheServerId,
        watchedThreshold = backend.watchedThreshold,
        // MediaBrowser keeps a stopped position only for a session its start opened; Plex keeps every report's.
        serverAcknowledged = !item.backend.usesMediaBrowserApi || started,
    )

    if (!isWatchedProgress(position.inWholeMilliseconds, duration.inWholeMilliseconds, backend.watchedThreshold)) return
    try {
        // A backend that marks on the stopped report gets only the local event: an explicit mark double-scrobbles.
        backend.markWatchedFromPlaybackStop(item, notifier)
        if (!isLaunchCurrent()) return
        scope.launch { trackers.mark(item, backend, true) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "failed to mark the player app's playback of ${item.id} watched" }
    }
}

private suspend fun queueExternalProgress(item: MediaItem, offlineQueue: OfflineProgressQueue?, position: Duration, duration: Duration?) {
    val serverId = ServerId.tryParse(item.serverId)
    if (offlineQueue == null || serverId == null) return
    val positionMs = position.inWholeMilliseconds
    val viewOffsetMs = if (duration == null) positionMs else positionMs.coerceIn(0L, duration.inWholeMilliseconds)
    offlineQueue.queueProgress(serverId, item.id, viewOffsetMs, duration?.inWholeMilliseconds)
}

private fun positive(value: Long?): Long? = value?.takeIf { it > 0 }
