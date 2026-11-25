package com.edde746.plezy.downloads

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchMarkOutcome
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException

/**
 * Marks every downloaded title of the collection folder [folder] watched or unwatched (only the titles that change);
 * offline, the marks queue for the next sync. The feedback to show: an error when a server was unreachable.
 */
suspend fun setDownloadsFolderWatched(
    controller: DownloadsController,
    watchActions: WatchActions,
    folder: MediaItem,
    watched: Boolean,
    offline: Boolean,
): DownloadFeedback = try {
    val titles = controller.downloadedCollectionItems(folder.globalKey).filter { title ->
        if (watched) !title.isWatched else title.isWatched || title.isPartiallyWatched || title.hasActiveProgress
    }
    var reachedServer = true
    for (title in titles) {
        if (watchActions.setWatched(title, watched, offline) == WatchMarkOutcome.SKIPPED) reachedServer = false
    }
    when {
        !reachedServer -> DownloadFeedback(T.messages.errorLoading(error = T.errors.reasonUnreachable), isError = true)
        offline -> DownloadFeedback(if (watched) T.messages.markedAsWatchedOffline else T.messages.markedAsUnwatchedOffline, isError = false)
        else -> DownloadFeedback(if (watched) T.messages.markedAsWatched else T.messages.markedAsUnwatched, isError = false)
    }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e("Downloads", e) { "Failed to mark downloads folder ${folder.globalKey}" }
    DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
}

/** Deletes every downloaded title of [folder] (after the caller's confirmation); the feedback to show. */
suspend fun deleteDownloadsFolder(controller: DownloadsController, folder: MediaItem): DownloadFeedback = try {
    controller.deleteCollectionDownloads(folder.globalKey)
    DownloadFeedback(T.downloads.collectionDownloadsDeleted, isError = false)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e("Downloads", e) { "Failed to delete downloads folder ${folder.globalKey}" }
    DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
}
