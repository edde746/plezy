package com.edde746.plezy.data.downloads

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.db.Download_owners
import com.edde746.plezy.data.db.Download_queue
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.testData
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.CANCELLED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PARTIAL
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadLibraryRepositoryTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val library = data.downloadLibrary

    @AfterTest
    fun close() = data.close()

    private var nextId = 1L

    /** Stores a row at any [status], as no production path does: admission only ever queues. */
    private suspend fun insertDownload(
        globalKey: String,
        status: DownloadedMediaStatus,
        type: String = "movie",
        clientScopeId: String? = null,
        parentRatingKey: String? = null,
        grandparentRatingKey: String? = null,
        mediaIndex: Long = 0,
        mediaSourceId: String? = null,
    ) {
        val (serverId, ratingKey) = globalKey.split(':', limit = 2)
        val row = Downloaded_media(
            id = nextId++, server_id = serverId, client_scope_id = clientScopeId, rating_key = ratingKey,
            global_key = globalKey, type = type, parent_rating_key = parentRatingKey,
            grandparent_rating_key = grandparentRatingKey, status = status.code, progress = 0, total_bytes = null,
            downloaded_bytes = 0, video_file_path = null, additional_part_paths = null, saf_root_uri = null,
            thumb_path = null, downloaded_at = null, error_message = null, retry_count = 0, bg_task_id = null,
            media_index = mediaIndex, media_source_id = mediaSourceId, library_id = null, library_title = null, transcode_quality = null,
        )
        data.db.write { q.downloadedMediaQueries.insertRow(row) }
    }

    private suspend fun queueRow(key: String, priority: Long, addedAt: Long, subtitles: Boolean = true, artwork: Boolean = true) {
        data.db.write { q.downloadedMediaQueries.insertQueueRow(Download_queue(nextId++, key, priority, addedAt, subtitles, artwork)) }
    }

    private fun sql(statement: String) {
        data.driver.execute(null, statement, 0)
    }

    private fun insertProfile(id: String) = sql("INSERT INTO profiles VALUES ('$id', 'local', '$id', NULL, '{}', 0, 0, NULL)")

    private fun insertConnection(id: String, kind: String, config: String = "{}") =
        sql("INSERT INTO connections VALUES ('$id', '$kind', '$config', 0, NULL, NULL)")

    private fun insertBinding(profileId: String, connectionId: String, user: String) =
        sql("INSERT INTO profile_connections VALUES ('$profileId', '$connectionId', '$user', 0, NULL, NULL, NULL)")

    private suspend fun media(key: String) = assertNotNull(library.getDownloadedMedia(key))

    private suspend fun queue() = library.getQueue()

    private suspend fun all() = library.getAllDownloads()

    // insertQueuedDownload

    @Test
    fun admissionStoresMediaIdentityScopePolicyAndQueueRowTogether() = runTest {
        val outcome = library.insertQueuedDownload(
            serverId = "srv", clientScopeId = "srv/user-a", ratingKey = "episode-1", globalKey = "srv:episode-1",
            type = "episode", parentRatingKey = "season-1", grandparentRatingKey = "show-1", mediaIndex = 3,
            mediaSourceId = "source-3", priority = 7, downloadSubtitles = false, downloadArtwork = true,
        )

        assertEquals(QueueDownloadOutcome.ADMITTED, outcome)
        val media = all().single()
        val queued = queue().single()
        assertEquals("srv", media.server_id)
        assertEquals("srv/user-a", media.client_scope_id)
        assertEquals("episode-1", media.rating_key)
        assertEquals("season-1", media.parent_rating_key)
        assertEquals("show-1", media.grandparent_rating_key)
        assertEquals(QUEUED, media.downloadStatus)
        assertEquals(3L, media.media_index)
        assertEquals("source-3", media.media_source_id)
        assertEquals(media.global_key, queued.media_global_key)
        assertEquals(7L, queued.priority)
        assertFalse(queued.download_subtitles)
        assertTrue(queued.download_artwork)
    }

    @Test
    fun aRequeueRefreshesRequestAndAttemptStateButKeepsIdentityAndFiles() = runTest {
        insertDownload(
            "srv:existing", FAILED, clientScopeId = "scope-original", parentRatingKey = "season-original",
            grandparentRatingKey = "show-original", mediaIndex = 2, mediaSourceId = "source-original",
        )
        val original = media("srv:existing")
        sql(
            "UPDATE downloaded_media SET progress = 41, downloaded_bytes = 410, total_bytes = 1000, " +
                "video_file_path = 'downloads/video.mkv', saf_root_uri = 'content://downloads', " +
                "thumb_path = 'downloads/thumb.jpg', downloaded_at = 1234, error_message = 'network error', " +
                "retry_count = 3, bg_task_id = 'stale-task' WHERE global_key = 'srv:existing'",
        )

        val outcome = library.insertQueuedDownload(
            serverId = "different-server", clientScopeId = "scope-new", ratingKey = "different-rating-key",
            globalKey = "srv:existing", type = "episode", parentRatingKey = "season-new", grandparentRatingKey = "show-new",
            mediaIndex = 9, mediaSourceId = "source-new", priority = 4, downloadSubtitles = false, downloadArtwork = false,
        )

        assertEquals(QueueDownloadOutcome.ADMITTED, outcome)
        val requeued = media("srv:existing")
        assertEquals(original.id, requeued.id)
        assertEquals("different-server", requeued.server_id)
        assertEquals("scope-new", requeued.client_scope_id)
        assertEquals("different-rating-key", requeued.rating_key)
        assertEquals("episode", requeued.type)
        assertEquals("season-new", requeued.parent_rating_key)
        assertEquals("show-new", requeued.grandparent_rating_key)
        assertEquals(9L, requeued.media_index)
        assertEquals("source-new", requeued.media_source_id)
        assertEquals(QUEUED, requeued.downloadStatus)
        assertEquals(0L, requeued.progress)
        assertEquals(0L, requeued.downloaded_bytes)
        assertNull(requeued.total_bytes)
        assertNull(requeued.error_message)
        assertEquals(0L, requeued.retry_count)
        assertNull(requeued.bg_task_id)
        assertEquals("downloads/video.mkv", requeued.video_file_path)
        assertEquals("content://downloads", requeued.saf_root_uri)
        assertEquals("downloads/thumb.jpg", requeued.thumb_path)
        assertEquals(1234L, requeued.downloaded_at)
        val queued = queue().single()
        assertEquals(4L, queued.priority)
        assertFalse(queued.download_subtitles)
        assertFalse(queued.download_artwork)
    }

    @Test
    fun aRequeueWithoutLibraryIdentityKeepsTheEarlierStamp() = runTest {
        library.insertQueuedDownload(serverId = "srv", ratingKey = "existing", globalKey = "srv:existing", type = "movie", libraryId = "lib-7", libraryTitle = "Movies")
        library.updateDownloadStatus("srv:existing", FAILED)

        val outcome = library.insertQueuedDownload(serverId = "srv", ratingKey = "existing", globalKey = "srv:existing", type = "movie")

        assertEquals(QueueDownloadOutcome.ADMITTED, outcome)
        assertEquals("lib-7", media("srv:existing").library_id)
        assertEquals("Movies", media("srv:existing").library_title)
    }

    @Test
    fun aRequeueWithFreshLibraryIdentityOverwritesTheStamp() = runTest {
        library.insertQueuedDownload(serverId = "srv", ratingKey = "existing", globalKey = "srv:existing", type = "movie", libraryId = "lib-7", libraryTitle = "Movies")
        library.updateDownloadStatus("srv:existing", FAILED)

        library.insertQueuedDownload(serverId = "srv", ratingKey = "existing", globalKey = "srv:existing", type = "movie", libraryId = "lib-9", libraryTitle = "Moved")

        assertEquals("lib-9", media("srv:existing").library_id)
        assertEquals("Moved", media("srv:existing").library_title)
    }

    @Test
    fun cancelledAndPartialRowsAreAdmittedForAFreshAttempt() = runTest {
        for (status in listOf(CANCELLED, PARTIAL)) {
            val key = "srv:${status.name}"
            insertDownload(key, status)
            library.updateDownloadProgress(key, 75, 750, 1000)
            library.updateDownloadError(key, "old failure")

            assertEquals(QueueDownloadOutcome.ADMITTED, library.insertQueuedDownload(serverId = "srv", ratingKey = status.name, globalKey = key, type = "movie"))
            val row = media(key)
            assertEquals(QUEUED, row.downloadStatus)
            assertEquals(0L, row.progress)
            assertEquals(0L, row.downloaded_bytes)
            assertNull(row.total_bytes)
            assertNull(row.error_message)
            assertEquals(0L, row.retry_count)
        }
        assertEquals(2, queue().size)
    }

    @Test
    fun activePausedAndCompletedRowsAreLeftAloneWithoutQueueWork() = runTest {
        for (status in listOf(DOWNLOADING, PAUSED, COMPLETED)) {
            val key = "srv:${status.name}"
            insertDownload(key, status)
            library.updateDownloadProgress(key, 63, 630, 1000)
            val before = media(key)

            val outcome = library.insertQueuedDownload(serverId = "other", ratingKey = "replacement", globalKey = key, type = "episode", priority = 9)

            assertEquals(QueueDownloadOutcome.UNCHANGED, outcome)
            assertEquals(before, media(key))
        }
        assertTrue(queue().isEmpty())
    }

    @Test
    fun anAlreadyQueuedRowGetsTheNewPolicyWithoutItsMediaRewritten() = runTest {
        insertDownload("srv:queued", QUEUED)
        library.updateDownloadProgress("srv:queued", 12, 120, 1000)
        library.addToQueue("srv:queued", priority = 1)
        val before = media("srv:queued")

        val outcome = library.insertQueuedDownload(
            serverId = "other", ratingKey = "replacement", globalKey = "srv:queued", type = "episode", priority = 8,
            downloadSubtitles = false, downloadArtwork = false,
        )

        assertEquals(QueueDownloadOutcome.ALREADY_QUEUED, outcome)
        assertEquals(before, media("srv:queued"))
        val queued = queue().single()
        assertEquals(8L, queued.priority)
        assertFalse(queued.download_subtitles)
        assertFalse(queued.download_artwork)
    }

    @Test
    fun aStateAdvanceDuringRetryAdmissionWinsOverTheStaleRequeue() = runTest {
        insertDownload("srv:race", FAILED)
        // Stands in for the download engine moving the row on between the read and the requeue.
        sql(
            """
            CREATE TRIGGER advance_retry_state
            BEFORE UPDATE OF status ON downloaded_media
            WHEN OLD.global_key = 'srv:race' AND OLD.status = ${FAILED.code} AND NEW.status = ${QUEUED.code}
            BEGIN
                UPDATE downloaded_media SET status = ${DOWNLOADING.code} WHERE id = OLD.id;
                SELECT RAISE(IGNORE);
            END
            """.trimIndent(),
        )

        val outcome = library.insertQueuedDownload(serverId = "srv", ratingKey = "race", globalKey = "srv:race", type = "movie")

        assertEquals(QueueDownloadOutcome.UNCHANGED, outcome)
        assertEquals(DOWNLOADING, media("srv:race").downloadStatus)
        assertTrue(queue().isEmpty())
    }

    @Test
    fun aFailedQueueInsertRollsBackBothNewAndRequeuedMediaRows() = runTest {
        insertDownload("srv:existing", FAILED)
        library.updateDownloadProgress("srv:existing", 41, 410, 1000)
        sql("CREATE TRIGGER reject_download_queue_insert BEFORE INSERT ON download_queue BEGIN SELECT RAISE(ABORT, 'queue insert rejected'); END")

        assertFailsWith<Exception> { library.insertQueuedDownload(serverId = "srv", ratingKey = "new", globalKey = "srv:new", type = "movie") }
        assertFailsWith<Exception> { library.insertQueuedDownload(serverId = "srv", ratingKey = "existing", globalKey = "srv:existing", type = "movie") }

        assertNull(library.getDownloadedMedia("srv:new"))
        val preserved = media("srv:existing")
        assertEquals(FAILED, preserved.downloadStatus)
        assertEquals(41L, preserved.progress)
        assertEquals(410L, preserved.downloaded_bytes)
        assertTrue(queue().isEmpty())
    }

    @Test
    fun aNewEnqueueStampsLibraryIdentity() = runTest {
        library.insertQueuedDownload(serverId = "srv", ratingKey = "movie-2", globalKey = "srv:movie-2", type = "movie", libraryId = "lib-7", libraryTitle = "Movies")

        assertEquals("lib-7", media("srv:movie-2").library_id)
        assertEquals("Movies", media("srv:movie-2").library_title)
    }

    // Queue

    @Test
    fun addToQueueStoresDefaultsOrTheGivenPolicyAndReplacesTheKeysRow() = runTest {
        library.addToQueue("srv:100")
        queue().single().let {
            assertEquals("srv:100", it.media_global_key)
            assertEquals(0L, it.priority)
            assertTrue(it.download_subtitles)
            assertTrue(it.download_artwork)
        }

        library.addToQueue("srv:100", priority = 5, downloadSubtitles = false, downloadArtwork = false)

        queue().single().let {
            assertEquals(5L, it.priority)
            assertFalse(it.download_subtitles)
            assertFalse(it.download_artwork)
        }
    }

    @Test
    fun removeFromQueueDeletesOnlyThatKey() = runTest {
        library.addToQueue("srv:1")
        library.addToQueue("srv:2")

        library.removeFromQueue("srv:1")

        assertEquals(listOf("srv:2"), queue().map { it.media_global_key })
    }

    @Test
    fun theNextItemIsAQueuedDownloadByPriorityThenAge() = runTest {
        assertNull(library.getNextQueueItem())
        insertDownload("srv:1", QUEUED)
        insertDownload("srv:2", DOWNLOADING)
        insertDownload("srv:3", QUEUED)
        insertDownload("srv:4", QUEUED)
        queueRow("srv:1", priority = 1, addedAt = 1_000)
        queueRow("srv:2", priority = 10, addedAt = 1_000)
        queueRow("srv:3", priority = 5, addedAt = 1_100)
        queueRow("srv:4", priority = 5, addedAt = 1_050)

        assertEquals("srv:4", library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun theNextItemSkipsExcludedKeys() = runTest {
        insertDownload("srv:1", QUEUED)
        insertDownload("srv:2", QUEUED)
        queueRow("srv:1", priority = 5, addedAt = 1_000)
        queueRow("srv:2", priority = 1, addedAt = 1_000)

        assertEquals("srv:1", library.getNextQueueItem()?.media_global_key)
        assertEquals("srv:2", library.getNextQueueItem(setOf("srv:1"))?.media_global_key)
        assertNull(library.getNextQueueItem(setOf("srv:1", "srv:2")))
    }

    @Test
    fun repairAddsOnlyMissingQueueRowsAndKeepsExistingPolicy() = runTest {
        insertDownload("srv:missing", QUEUED)
        insertDownload("srv:custom", QUEUED)
        insertDownload("srv:downloading", DOWNLOADING)
        queueRow("srv:custom", priority = -1, addedAt = 123_456, subtitles = false, artwork = false)
        library.addToQueue("srv:orphan", priority = 9)

        assertEquals(1, library.repairMissingQueuedDownloadEntries())
        assertEquals(0, library.repairMissingQueuedDownloadEntries())

        val rows = queue().associateBy { it.media_global_key }
        assertEquals(setOf("srv:missing", "srv:custom", "srv:orphan"), rows.keys)
        rows.getValue("srv:missing").let {
            assertEquals(0L, it.priority)
            assertTrue(it.download_subtitles)
            assertTrue(it.download_artwork)
        }
        rows.getValue("srv:custom").let {
            assertEquals(-1L, it.priority)
            assertEquals(123_456L, it.added_at)
            assertFalse(it.download_subtitles)
            assertFalse(it.download_artwork)
        }
        assertEquals(9L, rows.getValue("srv:orphan").priority)
        assertEquals("srv:missing", library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun supplementaryWorkIsCompletedVideosOnlyAndNeverPrimaryWork() = runTest {
        suspend fun seed(key: String, status: DownloadedMediaStatus, video: Boolean = false) {
            insertDownload(key, status)
            if (video) library.updateVideoFilePath(key, "downloads/${key.substring(4)}/video.mkv")
            library.addToQueue(key, priority = if (key == "srv:queued") 5 else 0, downloadSubtitles = key == "srv:completed-video", downloadArtwork = false)
        }
        seed("srv:queued", QUEUED)
        seed("srv:downloading", DOWNLOADING)
        seed("srv:completed-video", COMPLETED, video = true)
        seed("srv:completed-no-video", COMPLETED)

        val pending = library.getPendingSupplementaryQueueItems().single()
        assertEquals("srv:completed-video", pending.media_global_key)
        assertTrue(pending.download_subtitles)
        assertFalse(pending.download_artwork)
        assertEquals("srv:queued", library.getNextQueueItem()?.media_global_key)

        library.removeFromQueue("srv:completed-video")
        assertTrue(library.getPendingSupplementaryQueueItems().isEmpty())
        library.addToQueue("srv:completed-video")
        library.deleteDownload("srv:completed-video")
        assertTrue(queue().none { it.media_global_key == "srv:completed-video" })
    }

    @Test
    fun storageFullFailsQueuedAndDownloadingRowsAndDropsTheirQueueRows() = runTest {
        insertDownload("srv:queued", QUEUED)
        insertDownload("srv:downloading", DOWNLOADING)
        insertDownload("srv:paused", PAUSED)
        library.addToQueue("srv:queued")
        library.addToQueue("srv:paused")
        library.updateBgTaskId("srv:downloading", "task")

        val failed = library.failActiveDownloadsForStorageFull("Storage full")

        assertEquals(setOf("srv:queued", "srv:downloading"), failed.toSet())
        for (key in failed) {
            assertEquals(FAILED, media(key).downloadStatus)
            assertEquals("Storage full", media(key).error_message)
            assertNull(media(key).bg_task_id)
        }
        assertEquals(PAUSED, media("srv:paused").downloadStatus)
        assertEquals(listOf("srv:paused"), queue().map { it.media_global_key })
        assertTrue(library.failActiveDownloadsForStorageFull("Storage full").isEmpty())
    }

    // Update helpers

    @Test
    fun statusAndProgressUpdatesWriteOnlyTheirFields() = runTest {
        insertDownload("srv:100", QUEUED)

        library.updateDownloadStatus("srv:100", DOWNLOADING)
        assertEquals(DOWNLOADING, media("srv:100").downloadStatus)
        assertEquals(0L, media("srv:100").progress)

        library.updateDownloadProgress("srv:100", 42, 4242, 9999)
        media("srv:100").let {
            assertEquals(42L, it.progress)
            assertEquals(4242L, it.downloaded_bytes)
            assertEquals(9999L, it.total_bytes)
        }
    }

    @Test
    fun aVideoPathStampsCompletionUnlessItIsARepair() = runTest {
        insertDownload("srv:100", QUEUED)

        library.updateVideoFilePath("srv:100", "/tmp/file.mkv")
        assertEquals("/tmp/file.mkv", media("srv:100").video_file_path)
        assertEquals(clock.now, media("srv:100").downloaded_at)

        val stamped = clock.now
        clock.now += 60_000
        library.updateVideoFilePath("srv:100", "downloads/normalized/file.mkv", stampDownloadedAt = false)
        assertEquals("downloads/normalized/file.mkv", media("srv:100").video_file_path)
        assertEquals(stamped, media("srv:100").downloaded_at)
    }

    @Test
    fun safRootReferencesFollowTheRows() = runTest {
        insertDownload("srv:100", QUEUED)
        insertDownload("srv:200", QUEUED)

        library.updateDownloadSafRoot("srv:100", "content://root-a")
        library.updateDownloadSafRoot("srv:200", "content://root-a")
        assertEquals(2, library.countDownloadsReferencingSafRoot("content://root-a"))

        library.updateDownloadSafRoot("srv:200", "content://root-b")
        assertEquals(1, library.countDownloadsReferencingSafRoot("content://root-a"))
        assertEquals(1, library.countDownloadsReferencingSafRoot("content://root-b"))

        library.updateDownloadSafRoot("srv:100", null)
        assertEquals(0, library.countDownloadsReferencingSafRoot("content://root-a"))
    }

    @Test
    fun artworkPathIsSetAndCleared() = runTest {
        insertDownload("srv:100", QUEUED)

        library.updateArtworkPaths("srv:100", "/tmp/thumb.jpg")
        assertEquals("/tmp/thumb.jpg", media("srv:100").thumb_path)

        library.updateArtworkPaths("srv:100", null)
        assertNull(media("srv:100").thumb_path)
    }

    @Test
    fun errorsAndRetriesAreRecordedUntilCleared() = runTest {
        insertDownload("srv:100", QUEUED)

        library.updateDownloadError("srv:100", "first")
        assertEquals("first", media("srv:100").error_message)
        assertEquals(0L, media("srv:100").retry_count)
        library.countDownloadRetry("srv:100")
        library.updateDownloadError("srv:100", "second")
        assertEquals("second", media("srv:100").error_message)
        assertEquals(1L, media("srv:100").retry_count)

        library.clearDownloadError("srv:100")
        assertNull(media("srv:100").error_message)
        assertEquals(0L, media("srv:100").retry_count)
    }

    @Test
    fun backgroundTaskIdRoundTrips() = runTest {
        assertNull(library.getBgTaskId("does:not-exist"))
        insertDownload("srv:100", QUEUED)
        assertNull(library.getBgTaskId("srv:100"))

        library.updateBgTaskId("srv:100", "task-abc")
        assertEquals("task-abc", library.getBgTaskId("srv:100"))

        library.updateBgTaskId("srv:100", null)
        assertNull(library.getBgTaskId("srv:100"))
    }

    // Lookups

    private suspend fun seedTree() {
        insertDownload("srvA:ep1", COMPLETED, type = "episode", parentRatingKey = "season1", grandparentRatingKey = "show1")
        insertDownload("srvA:ep2", COMPLETED, type = "episode", parentRatingKey = "season1", grandparentRatingKey = "show1")
        insertDownload("srvA:ep3", COMPLETED, type = "episode", parentRatingKey = "season2", grandparentRatingKey = "show1")
        insertDownload("srvB:movie1", QUEUED)
    }

    @Test
    fun getDownloadedMediaFindsTheKeysRow() = runTest {
        seedTree()

        assertEquals("ep1", library.getDownloadedMedia("srvA:ep1")?.rating_key)
        assertNull(library.getDownloadedMedia("nope:nope"))
    }

    @Test
    fun episodesAreFoundBySeasonAndShow() = runTest {
        seedTree()

        assertEquals(setOf("ep1", "ep2"), library.getEpisodesBySeason("season1").map { it.rating_key }.toSet())
        assertEquals(setOf("ep3"), library.getEpisodesBySeason("season2").map { it.rating_key }.toSet())
        assertTrue(library.getEpisodesBySeason("seasonZ").isEmpty())
        assertEquals(setOf("ep1", "ep2", "ep3"), library.getEpisodesByShow("show1").map { it.rating_key }.toSet())
        assertTrue(library.getEpisodesByShow("show-missing").isEmpty())
    }

    @Test
    fun episodeLookupsFilterByServerAndClientScope() = runTest {
        insertDownload("jf:ep-a", COMPLETED, type = "episode", clientScopeId = "jf/user-a", parentRatingKey = "season1", grandparentRatingKey = "show1")
        insertDownload("jf:ep-b", COMPLETED, type = "episode", clientScopeId = "jf/user-b", parentRatingKey = "season1", grandparentRatingKey = "show1")
        insertDownload("other:ep-other", COMPLETED, type = "episode", parentRatingKey = "season1", grandparentRatingKey = "show1")
        insertDownload("other:ep-other-scoped", COMPLETED, type = "episode", clientScopeId = "other/user-a", parentRatingKey = "season1", grandparentRatingKey = "show1")

        assertEquals(listOf("ep-a"), library.getEpisodesBySeason("season1", serverId = "jf", clientScopeId = "jf/user-a").map { it.rating_key })
        assertEquals(listOf("ep-other"), library.getEpisodesBySeason("season1", serverId = "other", filterClientScope = true).map { it.rating_key })
        assertEquals(listOf("ep-b"), library.getEpisodesByShow("show1", serverId = "jf", clientScopeId = "jf/user-b").map { it.rating_key })
    }

    private suspend fun seedMusic() {
        insertDownload("srvA:track1", COMPLETED, type = "track", parentRatingKey = "album1", grandparentRatingKey = "artist1")
        insertDownload("srvA:track2", COMPLETED, type = "track", parentRatingKey = "album1", grandparentRatingKey = "artist1")
        insertDownload("srvA:track3", COMPLETED, type = "track", parentRatingKey = "album2", grandparentRatingKey = "artist1")
        // An episode sharing the album's key stays out of track lookups.
        insertDownload("srvA:ep-collide", COMPLETED, type = "episode", parentRatingKey = "album1", grandparentRatingKey = "artist1")
        insertDownload("srvB:track-b", COMPLETED, type = "track", parentRatingKey = "album1", grandparentRatingKey = "artist1")
    }

    @Test
    fun tracksAreFoundByAlbumAndArtistOnly() = runTest {
        seedMusic()

        assertEquals(setOf("srvA:track1", "srvA:track2", "srvB:track-b"), library.getTracksByAlbum("album1").map { it.global_key }.toSet())
        assertEquals(setOf("track1", "track2"), library.getTracksByAlbum("album1", serverId = "srvA").map { it.rating_key }.toSet())
        assertTrue(library.getTracksByAlbum("albumZ").isEmpty())
        assertEquals(setOf("track1", "track2", "track3"), library.getTracksByArtist("artist1", serverId = "srvA").map { it.rating_key }.toSet())
        assertTrue(library.getTracksByArtist("artist-missing").isEmpty())
    }

    @Test
    fun downloadsAreFoundByServer() = runTest {
        seedTree()

        assertEquals(setOf("ep1", "ep2", "ep3"), library.getDownloadsByServerId("srvA").map { it.rating_key }.toSet())
        assertEquals(setOf("movie1"), library.getDownloadsByServerId("srvB").map { it.rating_key }.toSet())
        assertTrue(library.getDownloadsByServerId("srvZ").isEmpty())
    }

    // Owners

    @Test
    fun repeatedClaimsKeepTheirCreationTimeAndOmittedMetadata() = runTest {
        data.db.write { q.downloadedMediaQueries.insertOwnerRow(Download_owners("profile-a", "srv:100", "plex", "scope-a", 1234)) }

        library.addDownloadOwner("profile-a", "srv:100")
        library.addDownloadOwner("profile-a", "srv:100")

        val owner = assertNotNull(library.getDownloadOwner("profile-a", "srv:100"))
        assertEquals(1234L, owner.created_at)
        assertEquals("plex", owner.backend)
        assertEquals("scope-a", owner.client_scope_id)
    }

    @Test
    fun repeatedClaimsFillInEachMetadataFieldTheyBring() = runTest {
        library.addDownloadOwner("profile-a", "srv:100")
        val createdAt = assertNotNull(library.getDownloadOwner("profile-a", "srv:100")).created_at
        clock.now += 1_000

        library.addDownloadOwner("profile-a", "srv:100", backendId = "jellyfin")
        library.addDownloadOwner("profile-a", "srv:100", clientScopeId = "srv/user-a")

        val owner = assertNotNull(library.getDownloadOwner("profile-a", "srv:100"))
        assertEquals(createdAt, owner.created_at)
        assertEquals("jellyfin", owner.backend)
        assertEquals("srv/user-a", owner.client_scope_id)
    }

    @Test
    fun ownersOfDeletedLocalProfilesDontCount() = runTest {
        insertProfile("profile-a")
        library.addDownloadOwner("profile-a", "srv:100")
        library.addDownloadOwner("profile-deleted", "srv:100")

        assertEquals(listOf("profile-a"), library.getValidDownloadOwnersForKey("srv:100").map { it.profile_id })
    }

    @Test
    fun plexHomeOwnersCountWhileTheirAccountConnectionExists() = runTest {
        insertConnection("account-1", "plex")
        library.addDownloadOwner("plex-home-account-1-00000000-0000-0000-0000-000000000001", "srv:100")
        library.addDownloadOwner("plex-home-missing-account-00000000-0000-0000-0000-000000000001", "srv:200")

        assertEquals(1, library.getValidDownloadOwnersForKey("srv:100").size)
        assertTrue(library.getValidDownloadOwnersForKey("srv:200").isEmpty())
    }

    @Test
    fun ownersKeepProfileVisibilitySeparateForOnePhysicalRow() = runTest {
        insertDownload("srv1:1", COMPLETED)

        library.addDownloadOwner("profile-a", "srv1:1")
        library.addDownloadOwner("profile-b", "srv1:1")

        assertEquals(setOf("srv1:1"), library.getDownloadOwnerKeysForProfile("profile-a"))
        assertEquals(setOf("srv1:1"), library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals(2, library.getValidDownloadOwnersForKey("srv1:1").size)

        library.removeDownloadOwner("profile-a", "srv1:1")
        assertTrue(library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(listOf("profile-b"), library.getValidDownloadOwnersForKey("srv1:1").map { it.profile_id })
    }

    @Test
    fun aSharedReleaseRebindsOnlyIncompleteMediaAndKeepsTheFinalOwner() = runTest {
        insertProfile("profile-a")
        insertProfile("profile-b")
        suspend fun seedOwners(key: String) {
            library.addDownloadOwner("profile-a", key, "plex", "srv1/plex-profile/profile-a")
            library.addDownloadOwner("profile-b", key, "plex", "srv1/plex-profile/profile-b")
        }
        insertDownload("srv1:queued-shared", QUEUED, clientScopeId = "srv1/plex-profile/profile-a")
        seedOwners("srv1:queued-shared")

        val queued = library.removeSharedDownloadOwnerAndRebindIncompleteMedia("profile-a", "srv1:queued-shared")

        assertTrue(queued.hasRemainingOwner)
        assertEquals("profile-a", queued.removedOwner?.profile_id)
        assertEquals("srv1/plex-profile/profile-b", media("srv1:queued-shared").client_scope_id)
        assertNull(library.getDownloadOwner("profile-a", "srv1:queued-shared"))
        assertNotNull(library.getDownloadOwner("profile-b", "srv1:queued-shared"))

        val last = library.removeSharedDownloadOwnerAndRebindIncompleteMedia("profile-b", "srv1:queued-shared")
        assertFalse(last.hasRemainingOwner)
        assertNotNull(library.getDownloadOwner("profile-b", "srv1:queued-shared"))

        insertDownload("srv1:completed-shared", COMPLETED, clientScopeId = "srv1/plex-profile/profile-a")
        seedOwners("srv1:completed-shared")

        val completed = library.removeSharedDownloadOwnerAndRebindIncompleteMedia("profile-a", "srv1:completed-shared")

        assertTrue(completed.hasRemainingOwner)
        assertEquals("srv1/plex-profile/profile-a", media("srv1:completed-shared").client_scope_id)
    }

    // Adoption

    @Test
    fun adoptionClaimsOnlyOwnerlessRows() = runTest {
        insertDownload("srv1:1", COMPLETED)
        insertDownload("srv1:2", COMPLETED)
        library.addDownloadOwner("profile-existing", "srv1:2")

        library.adoptLegacyDownloadsForProfile("profile-a")

        assertEquals(setOf("srv1:1"), library.getDownloadOwnerKeysForProfile("profile-a"))
        assertEquals(setOf("srv1:2"), library.getDownloadOwnerKeysForProfile("profile-existing"))
    }

    @Test
    fun anOwnerlessJellyfinDownloadTakesTheProfilesOnlyUserScope() = runTest {
        insertProfile("profile-b")
        insertConnection("jf-machine/user-b", "jellyfin", """{"serverMachineId":"jf-machine","userId":"user-b"}""")
        insertBinding("profile-b", "jf-machine/user-b", "user-b")
        insertDownload("jf-machine:ownerless", COMPLETED, clientScopeId = "jf-machine/user-a")

        library.adoptLegacyDownloadsForProfile("profile-b")

        val owner = assertNotNull(library.getDownloadOwner("profile-b", "jf-machine:ownerless"))
        assertEquals("jf-machine/user-b", media("jf-machine:ownerless").client_scope_id)
        assertEquals("jellyfin", owner.backend)
        assertEquals("jf-machine/user-b", owner.client_scope_id)
    }

    @Test
    fun anOwnerlessJellyfinDownloadWaitsWhenTheProfileHasSeveralUserScopes() = runTest {
        for (user in listOf("user-b", "user-c")) {
            insertConnection("jf-machine/$user", "jellyfin")
            insertBinding("profile-b", "jf-machine/$user", user)
        }
        insertDownload("jf-machine:ambiguous", COMPLETED, clientScopeId = "jf-machine/user-a")

        library.adoptLegacyDownloadsForProfile("profile-b")

        assertTrue(library.getDownloadOwnerKeysForProfile("profile-b").isEmpty())
        assertEquals("jf-machine/user-a", media("jf-machine:ambiguous").client_scope_id)
    }

    @Test
    fun aPlexDownloadIsAdoptedOnlyByTheProfileItsScopeNames() = runTest {
        insertDownload("srv1:profile-a-item", COMPLETED, clientScopeId = PlexProfileScopeId.of(ServerId("srv1"), "profile-a").value)

        library.adoptLegacyDownloadsForProfile("profile-b")
        assertTrue(library.getDownloadOwnerKeysForProfile("profile-b").isEmpty())

        library.adoptLegacyDownloadsForProfile("profile-a")
        assertEquals(setOf("srv1:profile-a-item"), library.getDownloadOwnerKeysForProfile("profile-a"))
        assertEquals("plex", library.getDownloadOwner("profile-a", "srv1:profile-a-item")?.backend)
    }

    private fun pinMetadata(scope: String, ratingKey: String, json: String, suffix: String = "") =
        sql("INSERT INTO api_cache VALUES ('$scope:/library/metadata/$ratingKey$suffix', '$json', 0, 1)")

    private suspend fun cached(scope: String, ratingKey: String, suffix: String = "") =
        data.db.read { apiCacheQueries.selectByKey("$scope:/library/metadata/$ratingKey$suffix").executeAsOneOrNull() }

    /** Plex metadata of [ratingKey], with [profileState] fields at the top and nested levels. */
    private fun metadata(ratingKey: String, profileState: String) =
        """{"MediaContainer":{"Metadata":[{"ratingKey":"$ratingKey","title":"T $ratingKey"$profileState,"Media":[{"Part":[{"id":1$profileState}]}]}]}}"""

    @Test
    fun aLogoutDetachesOwnersAndMovesPlexDownloadsWithTheirMetadataToTheNextProfile() = runTest {
        insertProfile("profile-a")
        val scopeA = PlexProfileScopeId.of(ServerId("srv1"), "profile-a").value
        insertDownload("srv1:ep", COMPLETED, type = "episode", clientScopeId = scopeA, parentRatingKey = "season", grandparentRatingKey = "show")
        insertDownload("jf:movie", COMPLETED, clientScopeId = "jf/user-a")
        library.addDownloadOwner("profile-a", "srv1:ep", "plex", scopeA)
        library.addDownloadOwner("profile-a", "jf:movie", "jellyfin", "jf/user-a")
        val profileState = ""","viewOffset":5,"viewCount":1,"lastViewedAt":7,"userRating":8.0,"lastRatedAt":3,"skipCount":1,"viewedLeafCount":2"""
        for (id in listOf("ep", "season", "show")) pinMetadata(scopeA, id, metadata(id, profileState))
        pinMetadata(scopeA, "show", """{"MediaContainer":{}}""", suffix = "/children")

        library.detachDownloadsForLogout()

        val transfer = "srv1/~plex-transfer"
        assertTrue(library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(transfer, media("srv1:ep").client_scope_id)
        assertEquals("jf/user-a", media("jf:movie").client_scope_id)
        assertEquals(2, all().size)
        for (id in listOf("ep", "season", "show")) {
            val row = assertNotNull(cached(transfer, id), id)
            assertTrue(row.pinned)
            assertEquals(Json.parseToJsonElement(metadata(id, "")), Json.parseToJsonElement(row.data_), "no watch state crosses a logout")
            assertNull(cached(scopeA, id), id)
        }
        assertNull(cached(scopeA, "show", suffix = "/children"))

        library.adoptLegacyDownloadsForProfile("profile-new")

        val scopeNew = PlexProfileScopeId.of(ServerId("srv1"), "profile-new").value
        assertEquals(scopeNew, media("srv1:ep").client_scope_id)
        val owner = assertNotNull(library.getDownloadOwner("profile-new", "srv1:ep"))
        assertEquals("plex", owner.backend)
        assertEquals(scopeNew, owner.client_scope_id)
        for (id in listOf("ep", "season", "show")) {
            val row = assertNotNull(cached(scopeNew, id), id)
            assertTrue(row.pinned)
            assertEquals(Json.parseToJsonElement(metadata(id, "")), Json.parseToJsonElement(row.data_))
            assertNull(cached(transfer, id), id)
        }
    }

    @Test
    fun aMalformedCachedPayloadStaysOutOfTheTransferScope() {
        assertNull(sanitizePlexMetadataForOwnerlessTransfer("not json"))
        assertNull(sanitizePlexMetadataForOwnerlessTransfer("[1]"))
    }

    // Delete

    @Test
    fun deletingADownloadRemovesItsRowQueueRowAndOwnersAndReturnsItsRoot() = runTest {
        insertDownload("srv:100", QUEUED)
        insertDownload("srv:200", QUEUED)
        library.addToQueue("srv:100")
        library.addToQueue("srv:200")
        library.addDownloadOwner("profile-a", "srv:100")
        library.updateDownloadSafRoot("srv:100", "content://root-a")

        assertEquals("content://root-a", library.deleteDownload("srv:100"))

        assertEquals(listOf("srv:200"), all().map { it.global_key })
        assertEquals(listOf("srv:200"), queue().map { it.media_global_key })
        assertNull(library.getDownloadOwner("profile-a", "srv:100"))
        assertNull(library.deleteDownload("nope:nope"))
    }

    // Stacked files

    @Test
    fun aRowWithoutLaterFilesIsSingleFile() = runTest {
        insertDownload("srv:100", DOWNLOADING)
        media("srv:100").let {
            assertNull(it.additionalPartPathList)
            assertEquals(1, it.partCount)
            assertEquals(0, it.nextMissingPartIndex)
            assertNull(it.storedPartPath(1))
        }

        library.updateVideoFilePath("srv:100", "downloads/a.mkv")

        assertNull(media("srv:100").nextMissingPartIndex)
        assertEquals(listOf("downloads/a.mkv"), media("srv:100").storedPartPaths)
    }

    @Test
    fun filesAreRecordedInOrderAndTheLastStampsCompletion() = runTest {
        insertDownload("srv:100", DOWNLOADING)
        library.updateVideoFilePath("srv:100", "downloads/stale.mkv", stampDownloadedAt = false)
        library.resetDownloadParts("srv:100", additionalPartCount = 2)

        media("srv:100").let {
            assertNull(it.video_file_path)
            assertEquals(listOf(null, null), it.additionalPartPathList)
            assertEquals(3, it.partCount)
            assertEquals(0, it.nextMissingPartIndex)
        }

        library.updateVideoFilePath("srv:100", "downloads/a.mkv", stampDownloadedAt = false)
        library.updateAdditionalPartPath("srv:100", 1, "downloads/a - part2.mkv", stampDownloadedAt = false)
        assertEquals(2, media("srv:100").nextMissingPartIndex)
        assertNull(media("srv:100").downloaded_at)

        library.updateAdditionalPartPath("srv:100", 2, "content://doc/a - part3.mp4")
        media("srv:100").let {
            assertNull(it.nextMissingPartIndex)
            assertNotNull(it.downloaded_at)
            assertEquals(listOf("downloads/a.mkv", "downloads/a - part2.mkv", "content://doc/a - part3.mp4"), it.storedPartPaths)
            assertEquals("content://doc/a - part3.mp4", it.storedPartPath(2))
            assertNull(it.storedPartPath(3))
        }
        assertFailsWith<IllegalStateException> { library.updateAdditionalPartPath("srv:100", 3, "downloads/x.mkv") }

        library.resetDownloadParts("srv:100", additionalPartCount = 0)
        assertNull(media("srv:100").additional_part_paths)
        assertNull(media("srv:100").video_file_path)
    }

    @Test
    fun aMalformedPartListReadsAsSingleFile() {
        assertNull(decodeAdditionalPartPaths("not json"))
        assertNull(decodeAdditionalPartPaths("""{"a":1}"""))
        assertNull(decodeAdditionalPartPaths("[]"))
        assertEquals(listOf("a", null, null), decodeAdditionalPartPaths("""["a", null, 3]"""))
    }

    @Test
    fun aFileAnotherDownloadRecordsStaysShared() = runTest {
        insertDownload("srv:100", COMPLETED)
        insertDownload("srv:200", COMPLETED)
        library.updateVideoFilePath("srv:200", "downloads/b.mkv")
        library.updateAdditionalPartPaths("srv:200", listOf("downloads/shared.mkv"))

        assertTrue(library.isVideoFilePathRecordedByOtherDownload("downloads/shared.mkv", excludingGlobalKey = "srv:100"))
        assertTrue(library.isVideoFilePathRecordedByOtherDownload("downloads/b.mkv", excludingGlobalKey = "srv:100"))
        assertFalse(library.isVideoFilePathRecordedByOtherDownload("downloads/shared.mkv", excludingGlobalKey = "srv:200"))
        assertFalse(library.isVideoFilePathRecordedByOtherDownload("downloads/other.mkv", excludingGlobalKey = "srv:100"))
    }

    @Test
    fun readmittingAFailedStackedDownloadKeepsItsRecordedFiles() = runTest {
        insertDownload("srv:100", FAILED)
        library.updateVideoFilePath("srv:100", "downloads/a.mkv")
        library.updateAdditionalPartPaths("srv:100", listOf("downloads/a - part2.mkv", null))

        val outcome = library.insertQueuedDownload(serverId = "srv", ratingKey = "100", globalKey = "srv:100", type = "movie", mediaIndex = 1)

        assertEquals(QueueDownloadOutcome.ADMITTED, outcome)
        assertEquals(listOf("downloads/a.mkv", "downloads/a - part2.mkv"), media("srv:100").storedPartPaths)
        assertEquals(listOf("downloads/a - part2.mkv", null), media("srv:100").additionalPartPathList)
    }
}
