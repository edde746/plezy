package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaChapter
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Cache-only playback extras per rating key; a network fetch is counted and refused. */
internal class ChapterExtrasBackend(private val cachedExtras: Map<String, PlaybackExtras>) : FakeMediaBackend("srv", BackendKind.PLEX) {
    var networkFetchCount = 0

    override suspend fun fetchPlaybackExtras(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean, forceRefresh: Boolean): PlaybackExtras {
        networkFetchCount++
        throw IllegalStateException("deletion reference scan must stay cache-only")
    }

    override suspend fun fetchPlaybackExtrasFromCacheOnly(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean): PlaybackExtras? =
        cachedExtras[itemId]
}

class DownloadManagerServiceDeletionTest {
    private var harness: DmsHarness? = null

    @AfterTest
    fun close() {
        harness?.close()
    }

    private suspend fun newHarness(saf: Boolean = false): DmsHarness {
        harness?.close()
        return DmsHarness.create(if (saf) DocumentTreeFake.ROOT_URI else null).also { harness = it }
    }

    @Test
    fun `missing video still removes partial and subtitle sidecars`() = runTest {
        val h = newHarness()
        val videoPath = LocalPath.join(h.root.support, "downloads", "srv", "item-1", "video.mkv")
        writeFile("$videoPath.part", "partial")
        val subtitles = h.storage.sidecarSubtitlesDirectoryPath(videoPath)
        writeFile(LocalPath.join(subtitles, "1.srt"), "subtitle")
        h.data.insertDownload("srv", "item-1", status = COMPLETED)
        h.library.updateVideoFilePath("srv:item-1", videoPath)
        val manager = h.manager()

        manager.deleteDownload("srv:item-1")

        assertFalse(exists("$videoPath.part"))
        assertFalse(exists(subtitles))
        assertNull(h.library.getDownloadedMedia("srv:item-1"))
    }

    @Test
    fun `deleting one track keeps the shared album folder and the last track clears it`() = runTest {
        val h = newHarness()
        suspend fun seedTrack(id: String, title: String, index: Int): String {
            val track = testMediaItem(id, MediaKind.TRACK, "srv", title = title, grandparentTitle = "Artist", parentTitle = "Album", index = index)
            val audioPath = h.storage.getTrackAudioPath(track, "mp3")
            writeFile(audioPath, "audio")
            h.putPlexMetadata("srv", id, plexFields("ratingKey" to id, "type" to "track", "title" to title, "grandparentTitle" to "Artist", "parentTitle" to "Album", "index" to index))
            h.data.insertDownload("srv", id, type = "track", status = COMPLETED)
            h.library.updateVideoFilePath("srv:$id", h.storage.toRelativePath(audioPath))
            return audioPath
        }
        val first = seedTrack("track-1", "One", 1)
        val second = seedTrack("track-2", "Two", 2)
        val albumDir = LocalPath.dirname(first)
        assertEquals(albumDir, LocalPath.dirname(second), "both tracks share one album folder")
        val manager = h.manager()

        manager.deleteDownload("srv:track-1")

        assertFalse(exists(first))
        assertTrue(exists(second), "the sibling track survives")
        assertTrue(exists(albumDir), "the shared album folder survives")

        manager.deleteDownload("srv:track-2")

        assertFalse(exists(second))
        assertFalse(exists(albumDir), "the empty album folder goes")
        assertFalse(exists(LocalPath.dirname(albumDir)), "the empty artist folder goes")
        assertTrue(exists(h.storage.getDownloadsDirectory()), "the downloads root stays")
    }

    private data class DeletionResult(
        val rowDeleted: Boolean,
        val cacheDeleted: Boolean,
        val videoDeleted: Boolean,
        val thumbnailDeleted: Boolean,
        val subtitlesDeleted: Boolean,
        val progressItems: List<Int>,
    )

    private suspend fun runEpisodeDeletion(saf: Boolean, failVideoDeletion: Boolean = false): DeletionResult {
        val h = newHarness(saf)
        val globalKey = "srv:episode-1"
        val episode = testMediaItem(
            "episode-1", MediaKind.EPISODE, "srv", title = "Pilot", parentId = "season-1", parentIndex = 1, grandparentId = "show-1",
            grandparentTitle = "Show", index = 1,
        )
        h.putPlexMetadata(
            "srv",
            "episode-1",
            plexFields(
                "ratingKey" to "episode-1", "type" to "episode", "title" to "Pilot", "parentRatingKey" to "season-1", "parentIndex" to 1,
                "grandparentRatingKey" to "show-1", "grandparentTitle" to "Show", "index" to 1,
            ),
        )
        h.putPlexMetadata("srv", "show-1", plexFields("ratingKey" to "show-1", "type" to "show", "title" to "Show", "year" to 2000))
        h.data.insertDownload("srv", "episode-1", type = "episode", status = COMPLETED, parentRatingKey = "season-1", grandparentRatingKey = "show-1")
        val safVideoUri = "content://episode-1.mkv"
        val filesystemVideoPath = h.storage.getEpisodeVideoPath(episode, "mkv", 2000)
        if (!saf) writeFile(filesystemVideoPath, "video")
        h.library.updateVideoFilePath(globalKey, if (saf) safVideoUri else filesystemVideoPath)
        val thumbnail = h.storage.getEpisodeThumbnailPath(episode, 2000)
        writeFile(thumbnail, "thumbnail")
        val subtitles = h.storage.getEpisodeSubtitlesDirectory(episode, 2000)
        writeFile(LocalPath.join(subtitles, "1.srt"), "subtitle")
        val fake = DocumentTreeFake(failDeletes = if (failVideoDeletion) setOf(safVideoUri) else emptySet())
        if (saf) fake.addEpisode(h.storage, episode, safVideoUri, 2000)
        val manager = h.manager(safStorage = fake)
        val progress = EventLog(h.scope, manager.deletionProgressStream)

        manager.deleteDownload(globalKey)
        h.idle()

        return DeletionResult(
            rowDeleted = h.library.getDownloadedMedia(globalKey) == null,
            cacheDeleted = h.plexCache.getMetadata("srv", "episode-1") == null,
            videoDeleted = if (saf) !fake.existsNow(safVideoUri) else !exists(filesystemVideoPath),
            thumbnailDeleted = !exists(thumbnail),
            subtitlesDeleted = !exists(subtitles),
            progressItems = progress.events.map { it.currentItem },
        )
    }

    @Test
    fun `filesystem and SAF episode deletion apply the same cleanup policy`() = runTest {
        val filesystem = runEpisodeDeletion(saf = false)
        val saf = runEpisodeDeletion(saf = true)

        assertEquals(filesystem, saf)
        assertEquals(DeletionResult(true, true, true, true, true, listOf(0, 1)), filesystem)
    }

    @Test
    fun `SAF deletion failure still cleans sidecars and cache and database state`() = runTest {
        assertEquals(DeletionResult(true, true, false, true, true, listOf(0, 1)), runEpisodeDeletion(saf = true, failVideoDeletion = true))
    }

    private data class ContainerDeletionResult(
        val rowDeleted: Boolean,
        val cacheDeleted: Boolean,
        val directoryDeleted: Boolean,
        val ownVideoDeleted: Boolean,
        val foreignFileKept: Boolean,
    )

    /**
     * Deletes a movie, season or show whose folder holds only what the download owns (a movie: its own video), or with
     * [withForeignFile] also a file it doesn't own.
     */
    private suspend fun runContainerDeletion(kind: MediaKind, saf: Boolean, withForeignFile: Boolean = false): ContainerDeletionResult {
        val h = newHarness(saf)
        val id = "${kind.id}-1"
        val globalKey = "srv:$id"
        val title = when (kind) {
            MediaKind.MOVIE -> "Movie"
            MediaKind.SHOW -> "Show"
            else -> "Season 1"
        }
        val isSeason = kind == MediaKind.SEASON
        val item = testMediaItem(
            id, kind, "srv", title = title, year = 2000, parentId = if (isSeason) "show-1" else null,
            grandparentTitle = if (isSeason) "Show" else null, index = if (isSeason) 1 else null,
        )
        h.putPlexMetadata(
            "srv",
            id,
            if (isSeason) {
                plexFields("ratingKey" to id, "type" to kind.id, "title" to title, "year" to 2000, "parentRatingKey" to "show-1", "grandparentTitle" to "Show", "index" to 1)
            } else {
                plexFields("ratingKey" to id, "type" to kind.id, "title" to title, "year" to 2000)
            },
        )
        h.data.insertDownload("srv", id, type = kind.id, status = COMPLETED)
        val components = when (kind) {
            MediaKind.MOVIE -> h.storage.getMovieSafPathComponents(item)
            MediaKind.SEASON -> h.storage.getSeasonSafPathComponents(item)
            else -> h.storage.getShowSafPathComponents(item)
        }
        val ownsVideo = kind == MediaKind.MOVIE
        val fake = DocumentTreeFake()
        var directory: String? = null
        var ownVideo: String? = null
        var foreignFile: String? = null
        if (saf) {
            fake.addContainer(h.storage, item, withForeignFile)
            if (ownsVideo) h.library.updateVideoFilePath(globalKey, DocumentTreeFake.CONTAINER_VIDEO_URI)
        } else {
            directory = LocalPath.join(h.storage.getDownloadsDirectory(), *components.toTypedArray())
            kotlinx.io.files.SystemFileSystem.createDirectories(kotlinx.io.files.Path(directory))
            if (ownsVideo) {
                ownVideo = h.storage.getMovieVideoPath(item, "mkv")
                writeFile(ownVideo, "video")
                h.library.updateVideoFilePath(globalKey, h.storage.toRelativePath(ownVideo))
            }
            if (withForeignFile) foreignFile = LocalPath.join(directory, "asset.bin").also { writeFile(it, "asset") }
        }
        val manager = h.manager(safStorage = fake)

        manager.deleteDownload(globalKey)

        return ContainerDeletionResult(
            rowDeleted = h.library.getDownloadedMedia(globalKey) == null,
            cacheDeleted = h.plexCache.getMetadata("srv", id) == null,
            directoryDeleted = if (saf) !fake.existsNow(DocumentTreeFake.TARGET_URI) else !exists(directory!!),
            ownVideoDeleted = if (saf) !fake.existsNow(DocumentTreeFake.CONTAINER_VIDEO_URI) else ownVideo == null || !exists(ownVideo),
            foreignFileKept = if (saf) !withForeignFile || fake.existsNow(DocumentTreeFake.ASSET_URI) else foreignFile == null || exists(foreignFile),
        )
    }

    @Test
    fun `movie and season and show deletion agree across filesystem and SAF`() = runTest {
        for (kind in listOf(MediaKind.MOVIE, MediaKind.SEASON, MediaKind.SHOW)) {
            val filesystem = runContainerDeletion(kind, saf = false)
            val saf = runContainerDeletion(kind, saf = true)
            assertEquals(filesystem, saf, "${kind.id} deletion differs by storage backend")
            assertEquals(ContainerDeletionResult(true, true, true, true, true), filesystem, kind.id)
        }
    }

    @Test
    fun `a folder holding files the download does not own is kept with those files`() = runTest {
        for (kind in listOf(MediaKind.MOVIE, MediaKind.SEASON, MediaKind.SHOW)) {
            for (saf in listOf(false, true)) {
                assertEquals(
                    ContainerDeletionResult(true, true, false, true, true),
                    runContainerDeletion(kind, saf, withForeignFile = true),
                    "${kind.id} deletion (saf: $saf) removed what it does not own",
                )
            }
        }
    }

    /**
     * Two same-titled movies from different servers share a folder: deletes the first and reports whether the second's
     * file survived (and the first's went). [legacySharedPath]: both rows record the same title-only file.
     */
    private suspend fun runSameTitleMovieDeletion(saf: Boolean, legacySharedPath: Boolean): Boolean {
        val h = newHarness(saf)
        val copies = listOf("srv-a", "srv-b").map { testMediaItem("movie-1", MediaKind.MOVIE, it, title = "Movie", year = 2000) }
        val fake = DocumentTreeFake()
        val stored = mutableMapOf<String, String>()
        for (copy in copies) {
            h.putPlexMetadata(copy.serverId!!, "movie-1", plexFields("ratingKey" to "movie-1", "type" to "movie", "title" to "Movie", "year" to 2000))
            h.data.insertDownload(copy.serverId!!, "movie-1", status = COMPLETED)
            val fileName = if (legacySharedPath) "Movie (2000).mkv" else h.storage.getMovieSafFileName(copy, "mkv")
            stored[copy.globalKey] = if (saf) {
                fake.addMovieFile(h.storage, copy, fileName)
            } else {
                val file = LocalPath.join(h.storage.getMovieDirectory(copy), fileName)
                writeFile(file, "video")
                h.storage.toRelativePath(file)
            }
            h.library.updateVideoFilePath(copy.globalKey, stored.getValue(copy.globalKey))
        }
        val manager = h.manager(safStorage = fake)

        manager.deleteDownload(copies[0].globalKey)

        fun present(path: String) = if (saf) fake.existsNow(path) else exists(h.storage.ensureAbsolutePath(path))
        val firstGone = h.library.getDownloadedMedia(copies[0].globalKey) == null
        val secondKept = present(stored.getValue(copies[1].globalKey))
        val firstFileGone = legacySharedPath || !present(stored.getValue(copies[0].globalKey))
        return firstGone && secondKept && firstFileGone
    }

    @Test
    fun `deleting one of two same titled movies keeps the other copy`() = runTest {
        for (saf in listOf(false, true)) assertTrue(runSameTitleMovieDeletion(saf, legacySharedPath = false), "saf: $saf")
    }

    @Test
    fun `a title only path recorded by two downloads survives deleting one of them`() = runTest {
        for (saf in listOf(false, true)) assertTrue(runSameTitleMovieDeletion(saf, legacySharedPath = true), "saf: $saf")
    }

    private val sharedThumb = "/library/parts/1/indexes/sd/1000"

    /** Deletes movie item-1 beside an optional item-2, the chapter extras scripted per item; reports whether the thumb survived. */
    private suspend fun runChapterThumbnailDeletion(withSibling: Boolean, siblingCached: Boolean, siblingReferencesThumb: Boolean = true): Pair<Boolean, Int> {
        val h = newHarness()
        val serverId = ServerId("srv")
        h.putPlexMetadata("srv", "item-1", plexFields("ratingKey" to "item-1", "type" to "movie", "title" to "Movie"))
        h.data.insertDownload("srv", "item-1", status = COMPLETED)
        if (withSibling) h.data.insertDownload("srv", "item-2", status = COMPLETED)
        val artworkFile = h.storage.getArtworkPathFromThumb(serverId, sharedThumb)
        writeFile(artworkFile, "chapter thumb")
        val client = ChapterExtrasBackend(
            buildMap {
                put("item-1", PlaybackExtras(listOf(MediaChapter(id = 1, thumb = sharedThumb)), emptyList()))
                if (withSibling && siblingCached) {
                    val thumb = if (siblingReferencesThumb) sharedThumb else "/library/parts/2/indexes/sd/2000"
                    put("item-2", PlaybackExtras(listOf(MediaChapter(id = 2, thumb = thumb)), emptyList()))
                }
            },
        )
        val manager = h.manager({ _, _ -> client })

        manager.deleteDownload("srv:item-1")

        return exists(artworkFile) to client.networkFetchCount
    }

    @Test
    fun `chapter thumbnails referenced by a cache resolvable sibling are retained`() = runTest {
        assertEquals(true to 0, runChapterThumbnailDeletion(withSibling = true, siblingCached = true))
    }

    @Test
    fun `chapter thumbnails are retained when a sibling cannot be resolved from cache`() = runTest {
        assertEquals(true to 0, runChapterThumbnailDeletion(withSibling = true, siblingCached = false))
    }

    @Test
    fun `unreferenced chapter thumbnails are deleted without any network fetch`() = runTest {
        assertEquals(false to 0, runChapterThumbnailDeletion(withSibling = false, siblingCached = false))
    }

    @Test
    fun `a cache resolvable sibling with different chapters does not block deletion`() = runTest {
        assertEquals(false to 0, runChapterThumbnailDeletion(withSibling = true, siblingCached = true, siblingReferencesThumb = false))
    }

    /**
     * Deletes season-1 with its episodes ep-1 and ep-2 (ep-2's extras not cached) and reports whether ep-1's unshared
     * chapter thumbnail survived; [withCacheMissSurvivor] adds a row outside the batch whose extras aren't cached.
     */
    private suspend fun runSeasonBatchChapterThumbnailDeletion(withCacheMissSurvivor: Boolean): Pair<Boolean, Int> {
        val h = newHarness()
        val thumb = "/library/parts/1/indexes/sd/1000"
        h.putPlexMetadata("srv", "season-1", plexFields("ratingKey" to "season-1", "type" to "season", "title" to "Season 1", "parentRatingKey" to "show-1", "index" to 1))
        h.data.insertDownload("srv", "season-1", type = "season", status = COMPLETED, parentRatingKey = "show-1")
        for (episode in listOf("ep-1", "ep-2")) {
            h.data.insertDownload("srv", episode, type = "episode", status = COMPLETED, parentRatingKey = "season-1", grandparentRatingKey = "show-1")
        }
        if (withCacheMissSurvivor) h.data.insertDownload("srv", "movie-1", status = COMPLETED)
        val artworkFile = h.storage.getArtworkPathFromThumb(ServerId("srv"), thumb)
        writeFile(artworkFile, "chapter thumb")
        val client = ChapterExtrasBackend(mapOf("ep-1" to PlaybackExtras(listOf(MediaChapter(id = 1, thumb = thumb)), emptyList())))
        val manager = h.manager({ _, _ -> client })

        manager.deleteDownload("srv:season-1")

        return exists(artworkFile) to client.networkFetchCount
    }

    @Test
    fun `batch deletion ignores same batch siblings with missing caches when reference counting`() = runTest {
        assertEquals(false to 0, runSeasonBatchChapterThumbnailDeletion(withCacheMissSurvivor = false), "a sibling deleted in the same batch must not retain")
    }

    @Test
    fun `batch deletion still retains chapter thumbnails for a surviving cache miss row`() = runTest {
        assertEquals(true to 0, runSeasonBatchChapterThumbnailDeletion(withCacheMissSurvivor = true), "a surviving row with unknown references must retain")
    }
}
