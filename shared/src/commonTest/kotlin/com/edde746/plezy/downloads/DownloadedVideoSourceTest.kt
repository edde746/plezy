package com.edde746.plezy.downloads

import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A downloaded row backs playback only while its stored copy is reachable: null lets the caller stream from the server
 * instead of handing the player a dead path (a removable volume can be unmounted while the row still reads completed).
 */
class DownloadedVideoSourceTest {
    private val data = testData()
    private val library = data.downloadLibrary
    private val root = StorageRoot()
    private val storage = DownloadStorageService(root.platform(), data.deviceSettings)
    private val server = ServerId("srv-1")

    @AfterTest
    fun tearDown() {
        data.close()
        root.delete()
    }

    private fun source(saf: SafStorageOperations = UnsupportedSafStorage) = LibraryDownloadedVideoSource(library, storage, saf)

    private suspend fun completedRow(storedPath: String) {
        library.insertQueuedDownload(
            serverId = server.value,
            ratingKey = "movie-1",
            globalKey = GLOBAL_KEY,
            type = "movie",
            mediaIndex = 0,
            mediaSourceId = "source-a",
        )
        library.updateDownloadStatus(GLOBAL_KEY, DownloadedMediaStatus.COMPLETED)
        library.updateVideoFilePath(GLOBAL_KEY, storedPath)
    }

    private suspend fun DownloadedVideoSource.resolve(mediaIndex: Int?, partIndex: Int = 0, allowAnyVersion: Boolean = false) =
        resolve(server, "movie-1", mediaIndex, null, allowAnyVersion, partIndex)

    private fun file(vararg components: String) = root.path(*components).also { writeFile(it) }

    // Storage-access-framework copies

    @Test
    fun anUnmountedVolumeYieldsNoSourceSoTheCallerCanStream() = runTest {
        completedRow(SAF_URI)
        val saf = FakeSafStorage(reachable = false)

        assertNull(source(saf).resolve(0))
        assertEquals(listOf(SAF_URI), saf.existsCalls, "the stored document URI is what must be probed")
    }

    @Test
    fun aReachableDocumentPlaysFromTheStoredUri() = runTest {
        completedRow(SAF_URI)

        val video = assertNotNull(source(FakeSafStorage(existing = setOf(SAF_URI))).resolve(0))
        assertEquals(SAF_URI, video.path)
        assertEquals(0, video.mediaIndex)
        assertEquals("source-a", video.mediaSourceId)
    }

    @Test
    fun reachabilityIsNotConsultedForAVersionThatWouldBeSkippedAnyway() = runTest {
        completedRow(SAF_URI)
        val saf = FakeSafStorage()

        assertNull(source(saf).resolve(1))
        assertEquals(emptyList(), saf.existsCalls)
    }

    // File copies

    @Test
    fun aDeletedFileYieldsNoSource() = runTest {
        completedRow(root.path("gone.mkv"))
        assertNull(source().resolve(0))
    }

    @Test
    fun aPresentFileResolvesToItsAbsolutePath() = runTest {
        val video = file("movie-1.mkv")
        completedRow(video)
        assertEquals(video, source().resolve(0)?.path)
    }

    @Test
    fun aFileStoredRelativeToTheBaseDirectoryResolvesUnderIt() = runTest {
        val video = LocalPath.join(root.support, "downloads", "srv-1", "movie-1", "video.mkv").also { writeFile(it) }
        completedRow(LocalPath.join("downloads", "srv-1", "movie-1", "video.mkv"))
        assertEquals(video, source().resolve(0)?.path)
    }

    @Test
    fun anUnfinishedDownloadYieldsNoSource() = runTest {
        completedRow(file("movie-1.mkv"))
        library.updateDownloadStatus(GLOBAL_KEY, DownloadedMediaStatus.PAUSED)
        assertNull(source().resolve(0))
    }

    @Test
    fun anotherVersionPlaysOnlyWhenAnyVersionIsAllowed() = runTest {
        completedRow(file("movie-1.mkv"))

        assertNull(source().resolve(1))
        val video = assertNotNull(source().resolve(1, allowAnyVersion = true))
        assertEquals(0, video.mediaIndex, "the version on disk")
    }

    // Stacked files

    @Test
    fun eachFileOfAStackedDownloadResolvesByItsPartIndex() = runTest {
        val files = listOf(file("movie-1.mkv"), file("movie-1 - part2.mkv"), file("movie-1 - part3.mp4"))
        completedRow(files[0])
        library.updateAdditionalPartPaths(GLOBAL_KEY, files.drop(1))

        for (partIndex in files.indices) {
            val video = assertNotNull(source().resolve(0, partIndex), "part $partIndex")
            assertEquals(files[partIndex], video.path)
            assertEquals("source-a", video.mediaSourceId)
            assertEquals(3, video.partCount)
        }
        assertNull(source().resolve(0, partIndex = 3))
    }

    @Test
    fun aDownloadFromBeforeStackedFilesWereFetchedHasNoLaterFile() = runTest {
        val first = file("movie-1.mkv")
        completedRow(first)

        assertEquals(first, source().resolve(0)?.path)
        assertNull(source().resolve(0, partIndex = 1))
    }

    @Test
    fun anUnreachableLaterFileYieldsNoSourceRatherThanAnotherFile() = runTest {
        completedRow(file("movie-1.mkv"))
        library.updateAdditionalPartPaths(GLOBAL_KEY, listOf(root.path("movie-1 - part2.mkv")))

        assertNull(source().resolve(0, partIndex = 1))
    }

    // Sidecar subtitles

    @Test
    fun aFileVideoSSubtitlesAreItsSubsDirectory() = runTest {
        val video = file("Movie [tag].mkv")
        val subtitles = listOf(file("Movie [tag]_subs", "3.srt"), file("Movie [tag]_subs", "7.ass"))
        file("subtitles", "9.srt")
        completedRow(video)

        val resolved = assertNotNull(source().resolve(0))
        assertEquals(subtitles, source().sidecarSubtitles(resolved, null))
    }

    @Test
    fun aFileVideoWithoutSubsDirectoryFallsBackToTheSubtitlesFolderBesideIt() = runTest {
        val video = file("video.mkv")
        val legacy = file("subtitles", "9.srt")
        completedRow(video)

        val resolved = assertNotNull(source().resolve(0))
        assertEquals(listOf(legacy), source().sidecarSubtitles(resolved, null))
    }

    @Test
    fun aDocumentVideoSSubtitlesAreInAppStorage() = runTest {
        completedRow(SAF_URI)
        val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, serverId = server.value, title = "Movie", year = 2020)
        val downloads = storage.getDownloadsDirectory()
        val own = LocalPath.join(downloads, "Movies", "Movie (2020)", "${storage.getMovieSafBaseName(movie)}_subs", "1.srt").also { writeFile(it) }
        val item = LocalPath.join(downloads, "srv-1", "movie-1", "subtitles", "2.srt").also { writeFile(it) }
        val laterPart = LocalPath.join(downloads, "srv-1", "movie-1", "subtitles", "part2", "4.srt").also { writeFile(it) }
        library.updateAdditionalPartPaths(GLOBAL_KEY, listOf("$SAF_URI-2"))
        val saf = FakeSafStorage()

        val first = assertNotNull(source(saf).resolve(0))
        assertEquals(listOf(own, item), source(saf).sidecarSubtitles(first, movie))
        val second = assertNotNull(source(saf).resolve(0, partIndex = 1))
        assertEquals(listOf(laterPart), source(saf).sidecarSubtitles(second, movie))
    }

    // Artwork

    @Test
    fun savedArtworkIsAFileUrlFoundWithoutTheTokenAndMissingArtworkIsNone() = runTest {
        val saved = storage.getArtworkPathFromThumb(server, "/Items/e2/Images/Primary?tag=7").also { writeFile(it) }

        assertEquals("file://$saved", source().artworkUrl(server, "/Items/e2/Images/Primary?tag=7&api_key=secret"))
        assertNull(source().artworkUrl(server, "/Items/e3/Images/Primary"))
        assertNull(source().artworkUrl(ServerId("srv-2"), "/Items/e2/Images/Primary?tag=7"), "another server's")
    }

    // Version matching

    private fun row(mediaIndex: Long = 0, mediaSourceId: String? = null) = Downloaded_media(
        id = 1, server_id = "srv", client_scope_id = null, rating_key = "movie-1", global_key = "srv:movie-1", type = "movie",
        parent_rating_key = null, grandparent_rating_key = null, status = DownloadedMediaStatus.COMPLETED.code, progress = 100,
        total_bytes = null, downloaded_bytes = 0, video_file_path = null, additional_part_paths = null, saf_root_uri = null,
        thumb_path = null, downloaded_at = null, error_message = null, retry_count = 0, bg_task_id = null,
        media_index = mediaIndex, media_source_id = mediaSourceId, library_id = null, library_title = null, transcode_quality = null,
    )

    @Test
    fun sourceIdWinsWhenBothSidesHaveOne() {
        // Equal ids match even when the index disagrees (Jellyfin's merged versions reorder between fetches).
        assertTrue(downloadedVersionMatches(row(mediaIndex = 1, mediaSourceId = "src-a"), requestedMediaIndex = 0, requestedMediaSourceId = "src-a"))
        assertFalse(downloadedVersionMatches(row(mediaIndex = 0, mediaSourceId = "src-a"), requestedMediaIndex = 0, requestedMediaSourceId = "src-b"))
    }

    @Test
    fun fallsBackToTheIndexWhenEitherSideLacksASourceId() {
        assertTrue(downloadedVersionMatches(row(mediaIndex = 0), requestedMediaIndex = 0, requestedMediaSourceId = "src-a"))
        assertFalse(downloadedVersionMatches(row(mediaIndex = 1), requestedMediaIndex = 0, requestedMediaSourceId = "src-a"))
        assertTrue(downloadedVersionMatches(row(mediaIndex = 1, mediaSourceId = "src-a"), requestedMediaIndex = 1))
        assertFalse(downloadedVersionMatches(row(mediaIndex = 1, mediaSourceId = "src-a"), requestedMediaIndex = 0))
    }

    @Test
    fun aBlankRequestedSourceIdIsTreatedAsAbsent() {
        assertTrue(downloadedVersionMatches(row(mediaIndex = 0, mediaSourceId = "src-a"), requestedMediaIndex = 0, requestedMediaSourceId = "  "))
    }

    @Test
    fun aNullRequestedIndexMeansAnyVersion() {
        assertTrue(downloadedVersionMatches(row(mediaIndex = 1, mediaSourceId = "src-a")))
        assertTrue(downloadedVersionMatches(row(mediaIndex = 1)))
        // A source id mismatch still rejects.
        assertFalse(downloadedVersionMatches(row(mediaIndex = 1, mediaSourceId = "src-a"), requestedMediaSourceId = "src-b"))
    }

    private companion object {
        const val GLOBAL_KEY = "srv-1:movie-1"
        const val SAF_URI = "content://com.android.externalstorage.documents/tree/79F7-B648%3A/document/movie-1.mkv"
    }
}
