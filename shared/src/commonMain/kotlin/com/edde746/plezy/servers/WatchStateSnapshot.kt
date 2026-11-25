package com.edde746.plezy.servers

import com.edde746.plezy.model.MediaItem

/**
 * A watch-state overlay patch: a watched flag to force ([isWatched] null: leave it) and a resume offset to set
 * ([hasViewOffsetMs]; the offset itself may be null).
 */
data class WatchStateSnapshot(val isWatched: Boolean? = null, val hasViewOffsetMs: Boolean = false, val viewOffsetMs: Long? = null) {
    val isEmpty: Boolean get() = isWatched == null && !hasViewOffsetMs

    /** [item] with this patch applied; a container's leaf counts follow the watched flag. */
    fun apply(item: MediaItem): MediaItem {
        var updated = item
        if (isWatched != null) updated = updated.withWatchedFlag(isWatched)
        if (hasViewOffsetMs) updated = updated.copy(viewOffsetMs = viewOffsetMs)
        return updated
    }

    companion object {
        private val WATCHED = WatchStateSnapshot(isWatched = true, hasViewOffsetMs = true, viewOffsetMs = 0)
        private val UNWATCHED = WatchStateSnapshot(isWatched = false, hasViewOffsetMs = true, viewOffsetMs = 0)
        private val NONE = WatchStateSnapshot()

        /**
         * The patch an event makes. Marks clear the resume offset; progress past the threshold is a watched mark, below
         * it only moves the offset. A Continue Watching removal patches nothing.
         */
        fun fromEvent(event: WatchStateEvent): WatchStateSnapshot = when (event.changeType) {
            WatchStateChangeType.WATCHED -> WATCHED
            WatchStateChangeType.UNWATCHED -> UNWATCHED
            WatchStateChangeType.PROGRESS_UPDATE ->
                if (event.isNowWatched == true) WATCHED else WatchStateSnapshot(hasViewOffsetMs = event.viewOffset != null, viewOffsetMs = event.viewOffset)
            WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING -> NONE
        }

        /** The patch an item's queued offline actions make: the newest action decides, as [fromEvent] reads events. */
        fun fromActions(actions: Iterable<OfflineWatchAction>): WatchStateSnapshot {
            val latest = actions.maxByOrNull { it.updatedAt } ?: return NONE
            return when (latest.type) {
                OfflineWatchActionType.WATCHED -> WATCHED
                OfflineWatchActionType.UNWATCHED -> UNWATCHED
                OfflineWatchActionType.PROGRESS ->
                    if (latest.shouldMarkWatched) WATCHED else WatchStateSnapshot(hasViewOffsetMs = latest.viewOffsetMs != null, viewOffsetMs = latest.viewOffsetMs)
            }
        }
    }
}
