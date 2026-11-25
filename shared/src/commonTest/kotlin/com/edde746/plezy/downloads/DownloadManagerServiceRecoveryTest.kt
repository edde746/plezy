package com.edde746.plezy.downloads

import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.data.downloads.nextMissingPartIndex
import com.edde746.plezy.data.downloads.storedPartPaths
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readString
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadManagerServiceRulesTest {
    @Test
    fun `uses path extension when present`() {
        assertEquals("mkv", downloadExtensionFromUrl("https://example.com/movie.mkv?Container=mp4"))
    }

    @Test
    fun `uses Jellyfin Container query parameter when path has no extension`() {
        assertEquals("mkv", downloadExtensionFromUrl("https://example.com/Videos/item/stream?Static=true&Container=mkv"))
    }

    @Test
    fun `normalizes and sanitizes container extensions`() {
        assertEquals("mkv", downloadExtensionFromUrl("https://example.com/Videos/item/stream?Container=MKV,MP4"))
        assertNull(downloadExtensionFromUrl("https://example.com/Videos/item/stream?Container=../bad"))
    }

    @Test
    fun `separates the current task id from stale and duplicate tasks`() {
        val tasks = listOf(downloadTask("current", "srv:item-1"), downloadTask("stale", "srv:item-1"), downloadTask("current", "srv:item-1"))
        val partition = partitionNativeTasks(tasks, "current")
        assertEquals(listOf("current", "current"), partition.current.map { it.taskId })
        assertEquals(listOf("stale"), partition.stale.map { it.taskId })
    }

    @Test
    fun `treats every native task as stale when the row has no task id`() {
        val tasks = listOf(downloadTask("first", "srv:item-1"), downloadTask("second", "srv:item-1"))
        val partition = partitionNativeTasks(tasks, null)
        assertTrue(partition.current.isEmpty())
        assertEquals(tasks, partition.stale)
    }

    private val baseAppDir = "/mnt/expand/9f2a/user/0/com.edde746.plezy/app_flutter"

    @Test
    fun `flags an absolute directory left behind by the previous app location`() {
        val task = rootTask("t", "srv:item-1", "/data/user/0/com.edde746.plezy/app_flutter/downloads/srv/item-1")
        assertTrue(isRelocatedRootTaskDirectory(task, "/", baseAppDir))
    }

    @Test
    fun `accepts a directory inside the live app storage`() {
        assertFalse(isRelocatedRootTaskDirectory(rootTask("t", "srv:item-1", "$baseAppDir/downloads/srv/item-1"), "/", baseAppDir))
    }

    @Test
    fun `accepts a directory inside the configured custom download root`() {
        val task = rootTask("t", "srv:item-1", "/Volumes/External/Plezy/Movies/Arrival (2016)")
        assertFalse(isRelocatedRootTaskDirectory(task, "/", baseAppDir, customRootPath = "/Volumes/External/Plezy"))
    }

    @Test
    fun `ignores a SAF task whose root anchored directory is a content tree URI`() {
        val task = documentTask("t", "srv:item-1", "content://com.android.externalstorage.documents/tree/usb%3APlezy")
        assertEquals(BaseDirectory.ROOT, task.baseDirectory)
        assertFalse(isRelocatedRootTaskDirectory(task, "/", baseAppDir))
    }

    @Test
    fun `ignores a task anchored to a base directory the downloader re resolves itself`() {
        val task = downloadTask("t", "srv:item-1")
        assertTrue(task.baseDirectory != BaseDirectory.ROOT)
        assertFalse(isRelocatedRootTaskDirectory(task, "/", baseAppDir))
    }

    @Test
    fun `removes Jellyfin api key from persisted artwork keys`() {
        val url = "https://jf.example/Items/item-1/Images/Primary?tag=abc&api_key=secret-token"
        assertEquals("https://jf.example/Items/item-1/Images/Primary?tag=abc", artworkStorageKey(url))
        val item = testMediaItem("item-1", MediaKind.MOVIE, "jf-machine", BackendKind.JELLYFIN, thumbPath = url)
        assertFalse("api_key" in buildArtworkSpecs(item) { it }.single().localKey)
    }
}

class DownloadManagerServiceRecoveryTest {
    private lateinit var harness: DmsHarness
    private val downloader = FakeNativeDownloader()

    /** Where the app's private storage lived before it moved to another volume. */
    private val previousAppDir = "/data/user/0/com.edde746.plezy/app_flutter"

    @AfterTest
    fun close() = harness.close()

    private suspend fun managerFor(tasks: List<DownloadTask> = emptyList(), records: List<TaskRecord> = emptyList()): DownloadManagerService {
        harness = DmsHarness.create()
        downloader.tasks = { tasks }
        downloader.records = { records }
        return harness.manager(downloader = downloader)
    }

    private suspend fun seedRow(status: com.edde746.plezy.data.downloads.DownloadedMediaStatus, taskId: String? = null, videoFilePath: String? = null) {
        harness.data.insertDownload("srv", "item-1", status = status)
        if (taskId != null) harness.library.updateBgTaskId("srv:item-1", taskId)
        if (videoFilePath != null) harness.library.updateVideoFilePath("srv:item-1", videoFilePath)
    }

    private fun relocatedTask() = rootTask("task-a", "srv:item-1", "$previousAppDir/downloads/srv/item-1")

    @Test
    fun `cancels a still live task targeting the previous app location and requeues it`() = runTest {
        val manager = managerFor(tasks = listOf(relocatedTask()))
        seedRow(DOWNLOADING, taskId = "task-a")

        manager.recoverInterruptedDownloads()

        assertEquals(listOf("task-a"), downloader.cancelledIds)
        val row = harness.library.getDownloadedMedia("srv:item-1")!!
        assertEquals(QUEUED.code, row.status)
        assertNull(row.bg_task_id)
        assertEquals("srv:item-1", harness.library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun `drops a relocated record before rescheduling can re enqueue it`() = runTest {
        val manager = managerFor(records = listOf(TaskRecord(relocatedTask(), TaskStatus.ENQUEUED, 0.4, 1024)))
        seedRow(DOWNLOADING, taskId = "task-a")

        manager.recoverInterruptedDownloads()

        assertEquals(listOf("task-a"), downloader.deletedRecordIds)
        assertEquals(listOf("task-a"), downloader.cancelledIds)
        val row = harness.library.getDownloadedMedia("srv:item-1")!!
        assertEquals(QUEUED.code, row.status)
        assertNull(row.bg_task_id)
        assertEquals("srv:item-1", harness.library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun `keeps a record that still points inside the live app storage`() = runTest {
        harness = DmsHarness.create()
        val task = rootTask("task-a", "srv:item-1", LocalPath.join(harness.storage.baseAppDirectoryPath(), "downloads", "srv", "item-1"))
        downloader.tasks = { listOf(task) }
        downloader.records = { listOf(TaskRecord(task, TaskStatus.ENQUEUED, 0.4, 1024)) }
        val manager = harness.manager(downloader = downloader)
        seedRow(DOWNLOADING, taskId = "task-a")

        manager.recoverInterruptedDownloads()

        assertTrue(downloader.deletedRecordIds.isEmpty())
        assertTrue(downloader.cancelledIds.isEmpty())
        val row = harness.library.getDownloadedMedia("srv:item-1")!!
        assertEquals(DOWNLOADING.code, row.status)
        assertEquals("task-a", row.bg_task_id)
        assertNull(harness.library.getNextQueueItem())
    }

    @Test
    fun `cancels a stale task for a finished download without disturbing the row`() = runTest {
        val manager = managerFor(tasks = listOf(relocatedTask()))
        seedRow(COMPLETED, videoFilePath = "downloads/srv/item-1/video.mkv")

        manager.recoverInterruptedDownloads()

        assertEquals(listOf("task-a"), downloader.cancelledIds)
        val row = harness.library.getDownloadedMedia("srv:item-1")!!
        assertEquals(COMPLETED.code, row.status)
        assertEquals("downloads/srv/item-1/video.mkv", row.video_file_path)
        assertNull(harness.library.getNextQueueItem())
    }

    @Test
    fun `startup drops relocated records before wiring up the downloader`() = runTest {
        val manager = managerFor(records = listOf(TaskRecord(relocatedTask(), TaskStatus.ENQUEUED, 0.4, 1024)))
        seedRow(DOWNLOADING, taskId = "task-a")

        manager.recoverInterruptedDownloads()

        // Configuring delivers the reports gathered while suspended (which can fail the row for good), and rescheduling
        // re-enqueues every record it finds missing: the record has to be gone before either.
        assertEquals(listOf("allRecords", "deleteRecord:task-a", "cancel:task-a", "initialize", "reschedule"), downloader.calls)
        assertEquals("srv:item-1", harness.library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun `startup normalizes stacked paths and completes only fully stored downloads`() = runTest {
        val manager = managerFor()
        val base = harness.root.support
        harness.data.insertDownload("srv", "item-1", status = DOWNLOADING)
        harness.library.resetDownloadParts("srv:item-1", 1)
        harness.library.updateVideoFilePath("srv:item-1", LocalPath.join(base, "downloads", "Movies", "M", "M.mkv"), stampDownloadedAt = false)
        harness.library.updateAdditionalPartPath("srv:item-1", 1, LocalPath.join(base, "downloads", "Movies", "M", "M - part2.mkv"))
        // Its second file never arrived and no native task is left for it.
        harness.data.insertDownload("srv", "item-2", status = DOWNLOADING)
        harness.library.resetDownloadParts("srv:item-2", 1)
        harness.library.updateVideoFilePath("srv:item-2", "downloads/Movies/N/N.mkv", stampDownloadedAt = false)

        manager.recoverInterruptedDownloads()

        val complete = harness.library.getDownloadedMedia("srv:item-1")!!
        assertEquals(COMPLETED.code, complete.status)
        // Stored relative to the base directory, joined as the platform joins paths (`\` on Windows).
        val relative = listOf(LocalPath.join("downloads", "Movies", "M", "M.mkv"), LocalPath.join("downloads", "Movies", "M", "M - part2.mkv"))
        assertEquals(relative, complete.storedPartPaths)
        val incomplete = harness.library.getDownloadedMedia("srv:item-2")!!
        assertEquals(QUEUED.code, incomplete.status, "not completed while a file is missing")
        assertEquals(1, incomplete.nextMissingPartIndex, "the stored first file is kept for the resume")
        assertEquals("srv:item-2", harness.library.getNextQueueItem()?.media_global_key)
    }

    @Test
    fun `startup takes the token out of stored artwork keys and keeps their artwork`() = runTest {
        val manager = managerFor()
        val server = ServerId("srv")
        val bare = "https://jf.example/Items/abc/Images/Primary"
        val tokened = "$bare?api_key=SECRET"
        // Two tracks of an album without an image tag, saved by an earlier release under the key that kept the token.
        for (track in listOf("item-1", "item-2")) {
            harness.data.insertDownload("srv", track, status = COMPLETED)
            harness.library.updateArtworkPaths("srv:$track", tokened)
        }
        val legacy = harness.storage.getArtworkPathFromThumb(server, tokened)
        assertEquals("8b3d2a64fc076ffd457e382138a6d12f.jpg", Path(legacy).name, "the earlier release's file name")
        writeFile(legacy, "album art")

        manager.recoverInterruptedDownloads()

        for (track in listOf("item-1", "item-2")) assertEquals(bare, harness.library.getDownloadedMedia("srv:$track")!!.thumb_path)
        // The tokenless URL the app now has for the image finds the same file.
        val found = assertNotNull(harness.storage.getArtworkPathSync(server, artworkStorageKey(bare)))
        assertEquals("album art", SystemFileSystem.source(Path(found)).buffered().use { it.readString() })
        assertFalse(exists(legacy))
    }
}

class DownloadManagerServiceStartupRecoveryTest {
    @Test
    fun `storage full lazy database open discards native work before retrying`() = runTest {
        val data = testData()
        try {
            data.insertDownload("srv", "active", status = DOWNLOADING)
            data.downloadLibrary.updateBgTaskId("srv:active", "native-task")
            data.downloadLibrary.addToQueue("srv:active")
            data.insertDownload("srv", "complete", status = COMPLETED)
            var openAttempts = 0
            var recoveries = 0

            val opened = openLocalDataWithDownloadRecovery(
                openDatabase = {
                    openAttempts++
                    if (openAttempts == 1) throw IOException("write failed: No space left on device")
                    data
                },
                recoverNativeDownloads = {
                    assertEquals(1, openAttempts, "recovery runs between the failed open and the retry")
                    recoveries++
                },
                storageFullMessage = "Storage full",
            )

            assertEquals(2, openAttempts)
            assertEquals(1, recoveries)
            val active = opened.downloadLibrary.getDownloadedMedia("srv:active")!!
            assertEquals(FAILED.code, active.status)
            assertNull(active.bg_task_id)
            assertEquals("Storage full", active.error_message)
            assertEquals(COMPLETED.code, opened.downloadLibrary.getDownloadedMedia("srv:complete")!!.status)
            assertTrue(opened.downloadLibrary.getQueue().isEmpty())
        } finally {
            data.close()
        }
    }

    @Test
    fun `non storage lazy database open errors bypass download recovery`() = runTest {
        var recoveries = 0
        val error = IllegalStateException("injected database setup failure")
        val thrown = runCatching {
            openLocalDataWithDownloadRecovery({ throw error }, { recoveries++ }, "Storage full")
        }.exceptionOrNull()
        assertTrue(thrown === error)
        assertEquals(0, recoveries)
    }
}
