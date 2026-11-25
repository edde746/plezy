package com.edde746.plezy.downloads

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.downloadStatus
import com.edde746.plezy.data.downloads.partCount
import com.edde746.plezy.data.downloads.storedPartPath
import com.edde746.plezy.data.downloads.transcodeQuality
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.playback.source.fileUrl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlin.coroutines.CoroutineContext

/**
 * One file of a downloaded copy, resolved for playback.
 *
 * @param path an absolute file path, or a `content://` URI (a download in an Android storage-access folder).
 * @param mediaIndex the version on disk, which differs from the one asked for after an any-version fallback.
 * @param partIndex which file of a version stacked across [partCount] files (0 is the first).
 * @param clientScopeId the scoped client the download's cached metadata belongs to (null: the server's own).
 * @param transcodeQuality the quality the server transcoded the copy to, or [TranscodeQualityPreset.ORIGINAL].
 */
data class DownloadedVideo(
    val serverId: ServerId,
    val itemId: String,
    val path: String,
    val mediaIndex: Int,
    val mediaSourceId: String?,
    val partIndex: Int,
    val partCount: Int,
    val clientScopeId: String?,
    val transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
)

/** Where the playable copy of a downloaded item is. */
interface DownloadedVideoSource {
    /**
     * File [partIndex] of the completed download of [itemId] on [serverId], or null when it can't back playback: not
     * completed, another version than asked for (unless [allowAnyVersion]), no such file, or the file is not reachable
     * (deleted, an unmounted volume, a revoked folder grant), so the caller streams from the server instead.
     *
     * Version: by source id when both the request and the download have one, else by [mediaIndex]; a null
     * [mediaIndex] takes any version. [allowAnyVersion] (offline, where the alternative is failing) returns the
     * downloaded version on a mismatch. A later file that isn't stored returns null, never another file.
     * Whether the active profile owns the download is the caller's check.
     */
    suspend fun resolve(
        serverId: ServerId,
        itemId: String,
        mediaIndex: Int?,
        mediaSourceId: String?,
        allowAnyVersion: Boolean,
        partIndex: Int = 0,
    ): DownloadedVideo?

    /**
     * The sidecar subtitle files downloaded with [video], as absolute paths; a numeric file name (without extension)
     * is the subtitle's source stream id. A file video's are in `<video without extension>_subs/` (else, from earlier
     * layouts, `subtitles/` beside it). A `content://` video's are in app storage: a later file's in its own
     * `part<N>` directory; the first file's in the movie's or episode's `_subs` directory ([metadata] names it) and
     * the item's `<serverId>/<itemId>/subtitles`.
     */
    suspend fun sidecarSubtitles(video: DownloadedVideo, metadata: MediaItem?): List<String>

    /** The saved artwork of [path] (an image path or URL of [serverId]'s) as a `file://` URL; null when it isn't saved. */
    suspend fun artworkUrl(serverId: ServerId, path: String): String?
}

/**
 * Whether [row] holds the version asked for: by source id when both sides have one (Jellyfin's merged versions can
 * reorder between fetches), else by media index; a null [requestedMediaIndex] takes any version. A blank requested
 * source id counts as none.
 */
internal fun downloadedVersionMatches(row: Downloaded_media, requestedMediaIndex: Int? = null, requestedMediaSourceId: String? = null): Boolean {
    val downloadedSourceId = row.media_source_id
    val requestedSourceId = requestedMediaSourceId?.trim()
    if (!requestedSourceId.isNullOrEmpty() && !downloadedSourceId.isNullOrEmpty()) return downloadedSourceId == requestedSourceId
    if (requestedMediaIndex == null) return true
    return row.media_index == requestedMediaIndex.toLong()
}

/** [DownloadedVideoSource] over the `downloaded_media` rows. */
class LibraryDownloadedVideoSource internal constructor(
    private val library: DownloadLibraryRepository,
    private val storage: DownloadStorageService,
    private val saf: SafStorageOperations,
    private val fileSystem: FileSystem = SystemFileSystem,
    private val io: CoroutineContext = Dispatchers.IO,
) : DownloadedVideoSource {
    override suspend fun resolve(
        serverId: ServerId,
        itemId: String,
        mediaIndex: Int?,
        mediaSourceId: String?,
        allowAnyVersion: Boolean,
        partIndex: Int,
    ): DownloadedVideo? {
        val globalKey = buildGlobalKey(serverId, itemId)
        val row = library.getDownloadedMedia(globalKey) ?: return null
        if (row.downloadStatus != DownloadedMediaStatus.COMPLETED) {
            Log.d(TAG) { "Download of $globalKey is not complete (${row.downloadStatus})" }
            return null
        }
        if (!downloadedVersionMatches(row, mediaIndex, mediaSourceId)) {
            if (!allowAnyVersion) {
                Log.d(TAG) { "$globalKey is downloaded as version ${row.media_index} (source ${row.media_source_id}), not $mediaIndex (source $mediaSourceId)" }
                return null
            }
            Log.d(TAG) { "Version $mediaIndex (source $mediaSourceId) of $globalKey isn't downloaded; using version ${row.media_index}" }
        }
        val storedPath = row.storedPartPath(partIndex)
        if (storedPath == null) {
            Log.d(TAG) { "No stored file ${partIndex + 1} of ${row.partCount} for $globalKey" }
            return null
        }
        // Reachability, not just the row: a removable volume can be unmounted, or a folder grant revoked, while the row
        // still reads completed, and the player can't tell a stale path from a live one until it fails to open it.
        val reachable: Boolean
        val path: String
        if (storage.isSafUri(storedPath)) {
            path = storedPath
            reachable = saf.exists(storedPath, isDir = false)
        } else {
            path = withContext(io) { storage.getReadablePath(storedPath) }
            reachable = withContext(io) { fileSystem.metadataOrNull(Path(path))?.isRegularFile == true }
        }
        if (!reachable) {
            Log.w(TAG) { "Downloaded file of $globalKey is not reachable: $path (stored as $storedPath)" }
            return null
        }
        return DownloadedVideo(
            serverId = serverId,
            itemId = itemId,
            path = path,
            mediaIndex = row.media_index.toInt(),
            mediaSourceId = row.media_source_id,
            partIndex = partIndex,
            partCount = row.partCount,
            clientScopeId = row.client_scope_id,
            transcodeQuality = row.transcodeQuality,
        )
    }

    override suspend fun artworkUrl(serverId: ServerId, path: String): String? = withContext(io) {
        storage.getArtworkPathFromThumb(serverId, artworkStorageKey(path)).takeIf { fileSystem.exists(Path(it)) }?.let(::fileUrl)
    }

    override suspend fun sidecarSubtitles(video: DownloadedVideo, metadata: MediaItem?): List<String> = withContext(io) {
        val directories = if (storage.isSafUri(video.path)) safSidecarDirectories(video, metadata) else fileSidecarDirectories(video.path)
        directories.flatMap { directory ->
            val dir = Path(directory)
            if (fileSystem.metadataOrNull(dir)?.isDirectory != true) return@flatMap emptyList()
            fileSystem.list(dir).filter { fileSystem.metadataOrNull(it)?.isRegularFile == true }.map { it.toString() }.sorted()
        }
    }

    private fun fileSidecarDirectories(videoPath: String): List<String> {
        val primary = storage.sidecarSubtitlesDirectoryPath(videoPath)
        if (fileSystem.exists(Path(primary))) return listOf(primary)
        return listOf(LocalPath.join(LocalPath.dirname(videoPath), "subtitles"))
    }

    private fun safSidecarDirectories(video: DownloadedVideo, metadata: MediaItem?): List<String> {
        val downloads = storage.getDownloadsDirectory()
        val item = LocalPath.join(downloads, video.serverId.value, video.itemId, "subtitles")
        if (video.partIndex > 0) return listOf(LocalPath.join(item, "part${video.partIndex + 1}"))
        val own = when {
            metadata == null || metadata.title == null -> null
            metadata.isEpisode -> LocalPath.join(downloads, *storage.getEpisodeSafPathComponents(metadata).toTypedArray(), "${storage.getEpisodeSafBaseName(metadata)}_subs")
            metadata.isMovie -> LocalPath.join(downloads, *storage.getMovieSafPathComponents(metadata).toTypedArray(), "${storage.getMovieSafBaseName(metadata)}_subs")
            else -> null
        }
        return listOfNotNull(own, item)
    }

    private companion object {
        const val TAG = "DownloadedVideo"
    }
}
