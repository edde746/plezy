package com.edde746.plezy.downloads

import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.additionalPartPathList
import com.edde746.plezy.data.downloads.storedPartPaths
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.parseGlobalKey
import kotlinx.coroutines.CancellationException

/**
 * Deletes a download's files: its video (and the later files of a stacked version), the `.part` and subtitle
 * sidecars, episode thumbnails, chapter thumbnails no other download uses, and the folders that leaves empty, on the
 * file system or through the storage access framework alike. A folder is never deleted with files in it: it is named
 * by title, so it can hold another copy of the title or the user's own files.
 */
internal class DownloadFileDeleter(
    private val database: DownloadLibraryRepository,
    private val storage: DownloadStorageService,
    private val safStorage: SafStorageOperations,
    private val metadata: DownloadMetadataScopes,
    private val ledger: SafGrantLedger,
    private val files: LocalFiles,
    private val emitDeletionProgress: (DeletionProgress) -> Unit,
) {
    /** The downloaded leaves of a container (season, show, album, artist), loaded once; null for a leaf. */
    suspend fun containerChildren(item: MediaItem, serverId: ServerId): List<Downloaded_media>? = when (item.kind) {
        MediaKind.SEASON -> database.getEpisodesBySeason(item.id, serverId.value)
        MediaKind.SHOW -> database.getEpisodesByShow(item.id, serverId.value)
        MediaKind.ALBUM -> database.getTracksByAlbum(item.id, serverId.value)
        MediaKind.ARTIST -> database.getTracksByArtist(item.id, serverId.value)
        else -> null
    }

    /** Deletes the files of [ratingKey] from the loaded [record], [item] and container [children]. */
    suspend fun deleteMediaFiles(
        serverId: ServerId,
        ratingKey: String,
        record: Downloaded_media?,
        item: MediaItem?,
        children: List<Downloaded_media>? = null,
    ) {
        guarded("Error deleting files") {
            val scopeId = record?.client_scope_id
            if (item == null) {
                if (record != null && record.storedPartPaths.isNotEmpty()) {
                    deleteByFilePath(record)
                } else {
                    Log.w(TAG) { "Cannot delete: no metadata for ${buildGlobalKey(serverId, ratingKey)}" }
                }
                return@guarded
            }
            when (item.kind) {
                MediaKind.EPISODE -> deleteEpisodeFiles(item, serverId, scopeId)
                MediaKind.SEASON, MediaKind.SHOW -> deleteEpisodeContainerFiles(item, serverId, children.orEmpty(), scopeId)
                MediaKind.MOVIE -> deleteMovieFiles(item, serverId, scopeId)
                // A track deletes from its row: the stored path covers every layout, and the album and artist folders
                // go once empty.
                MediaKind.TRACK -> if (record != null) deleteTrackByRecord(record)
                MediaKind.ALBUM, MediaKind.ARTIST -> deleteLeavesInContainer(
                    leaves = children.orEmpty(),
                    serverId = serverId,
                    clientScopeId = scopeId,
                    containerKey = item.id,
                    containerTitle = item.displayTitle,
                    leafNoun = "track",
                ) { track, _ -> deleteTrackByRecord(track) }
                else -> Log.w(TAG) { "Unknown type for deletion: ${item.kind}" }
            }
        }
    }

    /**
     * Deletes the files of every stored part before the attempt that replaces them; another download's file stays.
     * Throws on a failed part so the caller can log which one.
     */
    suspend fun deleteStoredPartFile(record: Downloaded_media, partIndex: Int, storedPath: String) {
        if (isVideoPathSharedWithOtherDownload(record, storedPath)) return
        if (storage.isSafUri(storedPath)) {
            tryDeleteSaf(storedPath, isDir = false, description = "SAF video file ${partIndex + 1}")
        } else {
            deleteFilesystemVideoAssets(storage.ensureAbsolutePath(storedPath))
        }
        if (partIndex == 0) return
        // A later file's subtitles live in an app-managed folder of their own.
        val subsDir = storage.getPartSubtitlesDirectory(ServerId(record.server_id), record.rating_key, partIndex)
        if (files.deleteRecursively(subsDir)) {
            Log.i(TAG) { "Deleted subtitles: $subsDir" }
            cleanupEmptyParentDirectories(LocalPath.dirname(subsDir))
        }
    }

    // Chapter thumbnails

    /**
     * The chapter thumbnail paths of [ratingKey] from the cache only (deletion never goes to the network), or null when
     * the cache can't answer: unknown references, not "none".
     */
    private suspend fun chapterThumbPaths(serverId: ServerId, ratingKey: String, clientScopeId: String?): List<String>? = try {
        val client = metadata.client(serverId, clientScopeId)
        client?.fetchPlaybackExtrasFromCacheOnly(ratingKey)?.chapters?.mapNotNull { it.thumb?.takeIf(String::isNotEmpty) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Error getting chapter thumb paths for $ratingKey" }
        null
    }

    /**
     * Deletes [ratingKey]'s chapter thumbnails no other download on the server uses. [batchRatingKeys] are rows deleted
     * in the same operation: they neither keep thumbnails nor, missing from the cache, hold all of them back. Any other
     * row whose references are unknown keeps every candidate.
     */
    private suspend fun deleteChapterThumbnails(
        serverId: ServerId,
        ratingKey: String,
        clientScopeId: String?,
        batchRatingKeys: Set<String> = emptySet(),
    ) {
        guarded("Error deleting chapter thumbnails for $ratingKey", warn = true) {
            val record = database.getDownloadedMedia(buildGlobalKey(serverId, ratingKey))
            val thumbPaths = chapterThumbPaths(serverId, ratingKey, clientScopeId ?: record?.client_scope_id)
            if (thumbPaths.isNullOrEmpty()) {
                Log.d(TAG) { "No chapter thumbnails to delete for $ratingKey" }
                return@guarded
            }
            val inUse = mutableSetOf<String>()
            for (item in database.getDownloadsByServerId(serverId.value)) {
                if (item.rating_key == ratingKey || item.rating_key in batchRatingKeys) continue
                val paths = chapterThumbPaths(serverId, item.rating_key, item.client_scope_id)
                if (paths == null) {
                    Log.d(TAG) { "Retaining chapter thumbnails for $ratingKey: references of ${item.rating_key} unknown (not cached)" }
                    return@guarded
                }
                inUse += paths
            }
            var deleted = 0
            var preserved = 0
            for (thumb in thumbPaths) {
                if (thumb in inUse) {
                    preserved++
                    continue
                }
                if (files.deleteIfExists(storage.getArtworkPathFromThumb(serverId, thumb), "chapter thumbnail")) deleted++
            }
            if (deleted > 0 || preserved > 0) {
                Log.i(TAG) { "Deleted $deleted of ${thumbPaths.size} chapter thumbnails ($preserved preserved)" }
            }
        }
    }

    // Episodes, seasons, shows

    private suspend fun deleteEpisodeFiles(
        episode: MediaItem,
        serverId: ServerId,
        clientScopeId: String?,
        skipStorageVideoAndParents: Boolean = false,
        batchRatingKeys: Set<String> = emptySet(),
    ) {
        guarded("Error deleting ${storageLabel()}episode files") {
            val showYear = episode.grandparentId?.let { metadata.lookup(serverId, it, clientScopeId) }?.year
            val storageDeletion = deleteEpisodeStorageVideo(episode, showYear, skipStorageVideoAndParents)
            files.deleteIfExists(storage.getEpisodeThumbnailPath(episode, showYear), "episode thumbnail")
            val subsDir = storage.getEpisodeSubtitlesDirectory(episode, showYear)
            if (files.deleteRecursively(subsDir)) Log.i(TAG) { "Deleted episode subtitles: $subsDir" }
            deleteChapterThumbnails(serverId, episode.id, clientScopeId, batchRatingKeys)
            if (!skipStorageVideoAndParents) {
                cleanupEpisodeStorageParents(episode, showYear, storageDeletion)
                ensureDbFileDeleted(serverId, episode.id)
            }
        }
    }

    private suspend fun deleteEpisodeContainerFiles(container: MediaItem, serverId: ServerId, episodes: List<Downloaded_media>, clientScopeId: String?) {
        val isSeason = container.kind == MediaKind.SEASON
        val label = if (isSeason) "season" else "show"
        guarded("Error deleting ${storageLabel()}$label files") {
            // The season folder sits under the show's year-qualified folder: resolve it before any episode row goes.
            val showYear = if (isSeason) container.parentId?.let { metadata.lookup(serverId, it, clientScopeId) }?.year else null
            Log.d(TAG) { "Deleting ${episodes.size} episodes in $label ${container.id}" }
            deleteEpisodesInCollection(episodes, serverId, clientScopeId, container.id, container.displayTitle)
            if (isSeason) deleteSeasonStorageDirectory(container, showYear) else pruneStorageDirectory(storage.getShowSafPathComponents(container, null))
        }
    }

    private suspend fun deleteEpisodesInCollection(
        episodes: List<Downloaded_media>,
        serverId: ServerId,
        clientScopeId: String?,
        parentKey: String,
        parentTitle: String,
    ) {
        val isSaf = storage.isUsingSaf
        // Every row of this batch, the container's included, is about to go: none of them retains chapter thumbnails.
        val batchRatingKeys = buildSet {
            add(parentKey)
            episodes.forEach { add(it.rating_key) }
        }
        deleteLeavesInContainer(episodes, serverId, clientScopeId, parentKey, parentTitle, "episode") { episode, scopeId ->
            if (isSaf) {
                val episodeMetadata = metadata.lookup(serverId, episode.rating_key, scopeId)
                if (episodeMetadata != null) {
                    deleteEpisodeFiles(episodeMetadata, serverId, scopeId, skipStorageVideoAndParents = true, batchRatingKeys = batchRatingKeys)
                    deleteByFilePath(episode)
                    return@deleteLeavesInContainer
                }
            }
            deleteChapterThumbnails(serverId, episode.rating_key, scopeId, batchRatingKeys)
            deleteByFilePath(episode)
        }
    }

    /** Deletes each leaf of a container: progress under the container's key, its files, its cached rows, its row. */
    private suspend fun deleteLeavesInContainer(
        leaves: List<Downloaded_media>,
        serverId: ServerId,
        clientScopeId: String?,
        containerKey: String,
        containerTitle: String,
        leafNoun: String,
        deleteFiles: suspend (Downloaded_media, String?) -> Unit,
    ) {
        val containerGlobalKey = buildGlobalKey(serverId, containerKey)
        leaves.forEachIndexed { i, leaf ->
            val scopeId = leaf.client_scope_id ?: clientScopeId
            emitDeletionProgress(
                DeletionProgress(containerGlobalKey, containerTitle, i + 1, leaves.size, "Deleting $leafNoun ${i + 1} of ${leaves.size}"),
            )
            deleteFiles(leaf, scopeId)
            metadata.deleteForItemByServer(serverId, leaf.rating_key, scopeId)
            ledger.deleteDownloadRowAndRelease(buildGlobalKey(serverId, leaf.rating_key))
        }
    }

    /** A track's files from its row; the album cover blob stays while another track of the server uses it. */
    private suspend fun deleteTrackByRecord(record: Downloaded_media) {
        val parsed = parseGlobalKey(record.global_key)
        val thumb = record.thumb_path
        val keepThumb = parsed != null && thumb != null &&
            database.getDownloadsByServerId(parsed.first.value).any { it.global_key != record.global_key && it.thumb_path == thumb }
        deleteByFilePath(record, deleteThumb = !keepThumb)
    }

    // Movies

    private suspend fun deleteMovieFiles(movie: MediaItem, serverId: ServerId, clientScopeId: String?) {
        guarded("Error deleting ${storageLabel()}movie files") {
            deleteMovieStorageVideo(movie)
            deleteChapterThumbnails(serverId, movie.id, clientScopeId)
            ensureDbFileDeleted(serverId, movie.id)
            pruneStorageDirectory(storage.getMovieSafPathComponents(movie))
        }
    }

    /**
     * Removes the media folder at [components] once it holds no files: its empty subfolders, then itself (and, on the
     * file system, its emptied parents up to the downloads root).
     */
    private suspend fun pruneStorageDirectory(components: List<String>) {
        if (storage.isUsingSaf) {
            val base = storage.safBaseUri ?: return
            safStorage.getChild(base, components)?.let { pruneEmptySafDirTree(it.uri) }
            return
        }
        val dir = LocalPath.join(storage.getDownloadsDirectory(), *components.toTypedArray())
        if (pruneEmptySubdirectories(dir)) cleanupEmptyParentDirectories(dir)
    }

    /**
     * The movie's video at its current path, with its sidecars and the later files of a stacked version named after
     * it. A download recorded under an older, title-only name goes in [ensureDbFileDeleted] instead.
     */
    private suspend fun deleteMovieStorageVideo(movie: MediaItem) {
        if (storage.isUsingSaf) {
            val base = storage.safBaseUri ?: return
            val movieDir = safStorage.getChild(base, storage.getMovieSafPathComponents(movie)) ?: return
            val baseName = storage.getMovieSafBaseName(movie)
            findSafFileByBaseName(movieDir.uri, baseName)?.let { tryDeleteSaf(it.uri, isDir = false, description = "SAF movie video") }
            deleteSafPartFiles(movieDir.uri, baseName)
            return
        }
        val template = storage.getMovieVideoPath(movie, "tmp")
        val withoutExt = template.substring(0, template.lastIndexOf('.'))
        deleteFilesystemPartFiles(withoutExt)
        val actual = findFileWithAnyExtension(withoutExt)
        if (actual != null) {
            deleteFilesystemVideoAssets(actual)
            return
        }
        files.deleteRecursively(storage.sidecarSubtitlesDirectoryPath(template))
    }

    private data class EpisodeStorageDeletion(val seasonDirUri: String?, val showDirUri: String?)

    private suspend fun deleteEpisodeStorageVideo(episode: MediaItem, showYear: Int?, skipVideo: Boolean): EpisodeStorageDeletion {
        if (storage.isUsingSaf) {
            if (skipVideo) return EpisodeStorageDeletion(null, null)
            val base = storage.safBaseUri ?: return EpisodeStorageDeletion(null, null)
            val seasonDirUri = safStorage.getChild(base, storage.getEpisodeSafPathComponents(episode, showYear))?.uri
            val showDirUri = safStorage.getChild(base, storage.getShowSafPathComponents(episode, showYear))?.uri
            if (seasonDirUri != null) {
                val baseName = storage.getEpisodeSafBaseName(episode)
                findSafFileByBaseName(seasonDirUri, baseName)?.let { tryDeleteSaf(it.uri, isDir = false, description = "SAF episode video") }
                deleteSafPartFiles(seasonDirUri, baseName)
            }
            return EpisodeStorageDeletion(seasonDirUri, showDirUri)
        }
        if (!skipVideo) {
            val template = storage.getEpisodeVideoPath(episode, "tmp", showYear)
            val withoutExt = template.substring(0, template.lastIndexOf('.'))
            deleteFilesystemPartFiles(withoutExt)
            findFileWithAnyExtension(withoutExt)?.let { actual ->
                files.deleteIfExists(actual, "episode video")
                files.deleteIfExists("$actual.part", "partial download")
            }
        }
        return EpisodeStorageDeletion(null, null)
    }

    private suspend fun cleanupEpisodeStorageParents(episode: MediaItem, showYear: Int?, deletion: EpisodeStorageDeletion) {
        if (storage.isUsingSaf) {
            deleteEmptySafDirsInOrder(listOf(deletion.seasonDirUri, deletion.showDirUri))
            return
        }
        val seasonKey = episode.parentId
        val deleted = deleteDirectoryIfUnused(
            storage.getSeasonDirectory(episode, showYear),
            "season",
            { if (seasonKey == null) emptyList() else database.getEpisodesBySeason(seasonKey) },
            episode.globalKey,
        )
        if (deleted) cleanupShowDirectory(episode, showYear)
    }

    private suspend fun deleteSeasonStorageDirectory(season: MediaItem, showYear: Int?) {
        pruneStorageDirectory(storage.getSeasonSafPathComponents(season, showYear))
        // The show folder goes too once the season leaves it empty.
        if (storage.isUsingSaf) {
            val base = storage.safBaseUri ?: return
            deleteEmptySafDirsInOrder(listOf(safStorage.getChild(base, storage.getShowSafPathComponents(season, showYear))?.uri))
            return
        }
        cleanupShowDirectory(season, showYear)
    }

    private suspend fun cleanupShowDirectory(item: MediaItem, showYear: Int?) {
        val showKey = item.grandparentId ?: item.parentId ?: item.id
        deleteDirectoryIfUnused(storage.getShowDirectory(item, showYear), "show", { database.getEpisodesByShow(showKey) }, item.globalKey)
    }

    /** Deletes [dir] once empty and no row but [excludingGlobalKey] of [remainingRows] still writes into it. */
    private suspend fun deleteDirectoryIfUnused(
        dir: String,
        label: String,
        remainingRows: suspend () -> List<Downloaded_media>,
        excludingGlobalKey: String,
    ): Boolean {
        if (!files.isDirectory(dir) || files.list(dir).isNotEmpty()) return false
        if (remainingRows().any { it.global_key != excludingGlobalKey }) return false
        files.deleteIfExists(dir, "empty $label directory")
        return true
    }

    /** After the deletion by metadata, makes sure the files the row records are gone too. */
    private suspend fun ensureDbFileDeleted(serverId: ServerId, ratingKey: String) {
        guarded("Safety net deletion failed", warn = true) {
            val record = database.getDownloadedMedia(buildGlobalKey(serverId, ratingKey)) ?: return@guarded
            deleteAdditionalPartFiles(record)
            val storedPath = record.video_file_path ?: return@guarded
            if (isVideoPathSharedWithOtherDownload(record, storedPath)) return@guarded
            if (storage.isSafUri(storedPath)) {
                if (safStorage.exists(storedPath, isDir = false)) {
                    Log.w(TAG) { "Safety net: SAF video still exists after metadata deletion, deleting: $storedPath" }
                    safStorage.delete(storedPath, isDir = false)
                }
                return@guarded
            }
            val videoPath = storage.ensureAbsolutePath(storedPath)
            if (files.exists(videoPath)) Log.w(TAG) { "Safety net: video still exists after metadata deletion, deleting: $videoPath" }
            deleteFilesystemVideoAssets(videoPath, withThumbnail = record.type == MediaKind.EPISODE.id)
        }
    }

    // Shared helpers

    /** Deletes the files [record] stores (another download's file stays), and its thumbnail when [deleteThumb]. */
    suspend fun deleteByFilePath(record: Downloaded_media, deleteThumb: Boolean = true) {
        guarded("Error in fallback deletion") {
            val storedPath = record.video_file_path
            if (storedPath != null && !isVideoPathSharedWithOtherDownload(record, storedPath)) {
                if (storage.isSafUri(storedPath)) {
                    tryDeleteSaf(storedPath, isDir = false, description = "SAF video file")
                } else {
                    deleteFilesystemVideoAssets(storage.ensureAbsolutePath(storedPath), withThumbnail = record.type == MediaKind.EPISODE.id)
                }
            }
            deleteAdditionalPartFiles(record)
            // thumb_path is the server's artwork path; the stored blob is named after it.
            val thumb = record.thumb_path
            if (deleteThumb && thumb != null) {
                parseGlobalKey(record.global_key)?.let { (serverId, _) ->
                    files.deleteIfExists(storage.getArtworkPathFromThumb(serverId, thumb), "thumbnail")
                }
            }
        }
    }

    private suspend fun deleteAdditionalPartFiles(record: Downloaded_media) {
        record.additionalPartPathList?.forEachIndexed { index, stored ->
            if (stored != null) deleteStoredPartFile(record, index + 1, stored)
        }
    }

    /** Whether another download records [storedPath] too (title-only paths of older releases could collide). */
    private suspend fun isVideoPathSharedWithOtherDownload(record: Downloaded_media, storedPath: String): Boolean {
        val shared = database.isVideoFilePathRecordedByOtherDownload(storedPath, record.global_key)
        if (shared) Log.i(TAG) { "Keeping $storedPath: another download still records it" }
        return shared
    }

    /** Deletes a file and the sidecars derived from its path, then the folders that leaves empty. */
    private suspend fun deleteFilesystemVideoAssets(videoPath: String, withThumbnail: Boolean = false) {
        files.deleteIfExists(videoPath, "video file")
        files.deleteIfExists("$videoPath.part", "partial download")
        if (withThumbnail) files.deleteIfExists(LocalPath.withoutExtension(videoPath) + ".jpg", "episode thumbnail")
        val subsPath = storage.sidecarSubtitlesDirectoryPath(videoPath)
        if (files.deleteRecursively(subsPath)) Log.i(TAG) { "Deleted subtitles: $subsPath" }
        cleanupEmptyParentDirectories(LocalPath.dirname(videoPath))
    }

    /** Deletes the later files of a stacked download named after [firstWithoutExt], with their sidecars. */
    private suspend fun deleteFilesystemPartFiles(firstWithoutExt: String) {
        val dir = LocalPath.dirname(firstWithoutExt)
        val firstBaseName = LocalPath.basename(firstWithoutExt)
        for (path in files.list(dir)) {
            val name = LocalPath.basename(path)
            if (!files.isFile(path) || extensionOf(name) !in VIDEO_EXTENSIONS) continue
            if (!storage.isPartFileBaseName(firstBaseName, LocalPath.withoutExtension(name))) continue
            files.deleteIfExists(path, "stacked video file")
            files.deleteIfExists("$path.part", "partial download")
            val subs = storage.sidecarSubtitlesDirectoryPath(path)
            if (files.deleteRecursively(subs)) Log.i(TAG) { "Deleted subtitles: $subs" }
        }
    }

    private suspend fun findFileWithAnyExtension(withoutExt: String): String? {
        val baseName = LocalPath.basename(withoutExt)
        return files.list(LocalPath.dirname(withoutExt)).firstOrNull { path ->
            val name = LocalPath.basename(path)
            LocalPath.withoutExtension(name) == baseName && extensionOf(name) in VIDEO_EXTENSIONS && files.isFile(path)
        }
    }

    /** Walks up from [dir] toward the downloads root, deleting each empty folder. */
    private suspend fun cleanupEmptyParentDirectories(dir: String) {
        guarded("Error cleaning up parent directories", warn = true) {
            val root = storage.getDownloadsDirectory()
            var current = dir
            while (current != root && LocalPath.isWithin(root, current)) {
                if (files.exists(current)) {
                    if (files.list(current).isNotEmpty()) break
                    files.deleteIfExists(current, "empty directory")
                }
                current = LocalPath.dirname(current)
            }
        }
    }

    /** Deletes the empty folders below [dir], deepest first; files stay. True when [dir] is left empty. */
    private suspend fun pruneEmptySubdirectories(dir: String): Boolean {
        if (!files.isDirectory(dir)) return false
        var empty = true
        for (entry in files.list(dir)) {
            if (files.isDirectory(entry) && pruneEmptySubdirectories(entry)) {
                files.deleteIfExists(entry, "empty directory")
            } else {
                empty = false
            }
        }
        return empty
    }

    private suspend fun tryDeleteSaf(uri: String, isDir: Boolean, description: String) {
        if (safStorage.delete(uri, isDir)) Log.i(TAG) { "Deleted $description: $uri" }
    }

    /** Deletes [dirUri] and the document folders below it that hold no files, deepest first. True when it is gone. */
    private suspend fun pruneEmptySafDirTree(dirUri: String): Boolean {
        val children = safStorage.list(dirUri) ?: return false
        var remaining = 0
        for (child in children) {
            if (!child.isDir || !pruneEmptySafDirTree(child.uri)) remaining++
        }
        if (remaining > 0 || !safStorage.delete(dirUri, isDir = true)) return false
        Log.i(TAG) { "Cleaned up empty SAF directory: $dirUri" }
        return true
    }

    /** Deletes each of [dirUris] (deepest first) while it is empty; stops at the first that isn't. */
    private suspend fun deleteEmptySafDirsInOrder(dirUris: List<String?>) {
        for (uri in dirUris) {
            if (uri == null) break
            if (!safStorage.exists(uri, isDir = true)) continue
            val children = safStorage.list(uri)
            if (children == null || children.isNotEmpty()) break
            if (!safStorage.delete(uri, isDir = true)) break
            Log.i(TAG) { "Cleaned up empty SAF directory: $uri" }
        }
    }

    private suspend fun findSafFileByBaseName(dirUri: String, baseName: String): SafDocumentFile? =
        safStorage.list(dirUri)?.firstOrNull { !it.isDir && LocalPath.withoutExtension(it.name) == baseName }

    private suspend fun deleteSafPartFiles(dirUri: String, firstBaseName: String) {
        for (child in safStorage.list(dirUri).orEmpty()) {
            if (!child.isDir && storage.isPartFileBaseName(firstBaseName, LocalPath.withoutExtension(child.name))) {
                tryDeleteSaf(child.uri, isDir = false, description = "SAF stacked video file")
            }
        }
    }

    private fun storageLabel(): String = if (storage.isUsingSaf) "SAF " else ""

    /** Runs a best-effort deletion step: a failure is logged, the deletion goes on. */
    private suspend fun guarded(message: String, warn: Boolean = false, block: suspend () -> Unit) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (warn) Log.w(TAG, e) { message } else Log.e(TAG, e) { message }
        }
    }

    companion object {
        private const val TAG = "DownloadDeletion"
        private val VIDEO_EXTENSIONS = setOf(".mp4", ".ogv", ".mkv", ".m4v", ".avi")

        /** The extension of file [name] with its dot, lowercased; empty when it has none. */
        fun extensionOf(name: String): String = name.removePrefix(LocalPath.withoutExtension(name)).lowercase()
    }
}
