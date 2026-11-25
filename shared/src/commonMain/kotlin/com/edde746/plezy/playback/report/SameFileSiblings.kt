package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.markWatchedFromPlaybackStop

/**
 * Marks watched the other episodes of a multi-episode file once the played one is (Plex: they share its part, so
 * watching the file watched them): each not yet watched gets [markWatchedFromPlaybackStop] (no explicit mark on a
 * backend that marks from the stop) and the [trackers]' mark, as no playback session ever opened for it. The tracker's
 * `onScrobbled` runs it with [siblings] from [com.edde746.plezy.servers.PlaybackStateStore.sameFileSiblings]. A
 * failure throws and leaves the rest unmarked.
 */
suspend fun markSameFileSiblingsWatched(siblings: List<MediaItem>, backend: MediaBackend, notifier: WatchStateNotifier, trackers: TrackerWatchMarks) {
    for (sibling in siblings) {
        if (sibling.isWatched) continue
        backend.markWatchedFromPlaybackStop(sibling, notifier)
        trackers.mark(sibling, backend, true)
    }
}
