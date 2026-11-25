package com.edde746.plezy.downloads

import com.edde746.plezy.data.downloads.DownloadedMediaStatus

/**
 * A download's live state as the manager reports it: every status change, every progress tick of the file being
 * fetched, and each supplementary step ([currentFile] `video`, `artwork`, `subtitles`).
 *
 * @param progress whole percent of the item, 0–100.
 * @param speed bytes per second, 0 while unknown.
 * @param thumbPath the artwork storage key once the item's artwork is stored.
 * @param downloadedAt epoch milliseconds the last file landed.
 */
data class DownloadProgress(
    val globalKey: String,
    val status: DownloadedMediaStatus,
    val progress: Int = 0,
    val downloadedBytes: Long = 0,
    val totalBytes: Long = 0,
    val speed: Double = 0.0,
    val errorMessage: String? = null,
    val currentFile: String? = null,
    val thumbPath: String? = null,
    val downloadedAt: Long? = null,
) {
    /** [progress] as a fraction, 0–1. */
    val progressPercent: Double get() = progress / 100.0
    val hasArtworkPaths: Boolean get() = thumbPath != null
    val hasError: Boolean get() = errorMessage != null

    /** [speed] as "512 B/s", "1.5 KB/s", "2.3 MB/s". */
    val speedFormatted: String
        get() = when {
            speed < 1024 -> "${kotlin.math.round(speed).toLong()} B/s"
            speed < 1024 * 1024 -> "${oneDecimal(speed / 1024)} KB/s"
            else -> "${oneDecimal(speed / (1024 * 1024))} MB/s"
        }

    private fun oneDecimal(value: Double): String {
        val tenths = kotlin.math.round(value * 10).toLong()
        return "${tenths / 10}.${tenths % 10}"
    }
}

/**
 * How far deleting [globalKey] (a single item, or a season, show, album or artist with its downloaded leaves) has got:
 * [currentItem] of [totalItems] leaves.
 */
data class DeletionProgress(
    val globalKey: String,
    val itemTitle: String,
    val currentItem: Int,
    val totalItems: Int,
    val currentOperation: String? = null,
) {
    val progressPercent: Double get() = if (totalItems > 0) currentItem.toDouble() / totalItems else 0.0

    val progressPercentInt: Int get() = kotlin.math.round(progressPercent * 100).toInt()
    val isComplete: Boolean get() = currentItem >= totalItems
}
