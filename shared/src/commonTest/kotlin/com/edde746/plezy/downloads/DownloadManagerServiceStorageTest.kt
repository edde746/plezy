package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadPartResolution
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadSubtitleSpec
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.data.downloads.additionalPartPathList
import com.edde746.plezy.data.downloads.nextMissingPartIndex
import com.edde746.plezy.data.downloads.partCount
import com.edde746.plezy.data.downloads.storedPartPaths
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadManagerServiceSafGrantTest {
    private lateinit var harness: DmsHarness

    @AfterTest
    fun close() = harness.close()

    private suspend fun seedRow(key: String, videoFilePath: String? = null, taskId: String? = null, status: DownloadedMediaStatus = QUEUED) {
        harness.data.insertDownload(key.substringBefore(':'), key.substringAfter(':'), globalKey = key, status = status)
        if (videoFilePath != null) harness.library.updateVideoFilePath(key, videoFilePath)
        if (taskId != null) harness.library.updateBgTaskId(key, taskId)
    }

    /** The download location's grant ledger as the manager builds it. */
    private fun ledger(safStorage: SafStorageOperations, location: DownloadLocationStore) =
        SafGrantLedger(harness.library, safStorage, location) { harness.storage.isDirectoryWritable(it) }

    private fun saf(path: String) = DownloadLocationSnapshot(path, "saf")

    @Test
    fun `root switches retain references and release only the final owner`() = runTest {
        harness = DmsHarness.create()
        seedRow("srv:first")
        seedRow("srv:second")
        val location = MemoryLocationStore(saf("content://picked-a"))
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-a" to "content://root-a",
                "content://picked-b" to "content://root-b",
                "content://picked-b-alias" to "content://root-b",
                "content://root-a" to "content://root-a",
                "content://root-b" to "content://root-b",
            ),
            persistedRoots = setOf("content://root-a", "content://root-b"),
        )
        val ledger = ledger(fake, location)

        ledger.claimDownloadSafRoot("srv:first", "content://picked-a")
        ledger.claimDownloadSafRoot("srv:second", "content://picked-a")
        ledger.setDownloadLocation("content://picked-b", "saf", null)
        assertTrue(fake.releaseCalls.isEmpty())

        ledger.deleteDownloadRowAndRelease("srv:first")
        assertTrue(fake.releaseCalls.isEmpty())
        ledger.deleteDownloadRowAndRelease("srv:second")
        assertEquals(listOf("content://root-a"), fake.releaseCalls)

        ledger.setDownloadLocation("content://picked-b-alias", "saf", null)
        assertEquals(listOf("content://root-a"), fake.releaseCalls)
        ledger.resetDownloadLocation(null)
        assertEquals(listOf("content://root-a", "content://root-b"), fake.releaseCalls)
    }

    @Test
    fun `a paused claim serializes ahead of a root switch and retry move`() = runTest {
        harness = DmsHarness.create()
        seedRow("srv:item")
        val location = MemoryLocationStore(saf("content://picked-a"))
        val claimEntered = CompletableDeferred<Unit>()
        val allowClaim = CompletableDeferred<Unit>()
        val fake = DocumentTreeFake(
            persistedRoots = setOf("content://root-a", "content://root-b"),
            resolveOverride = { uri ->
                if (uri == "content://task-a") {
                    claimEntered.complete(Unit)
                    allowClaim.await()
                    "content://root-a"
                } else {
                    when (uri) {
                        "content://picked-a", "content://root-a" -> "content://root-a"
                        "content://picked-b", "content://root-b" -> "content://root-b"
                        else -> null
                    }
                }
            },
        )
        val ledger = ledger(fake, location)

        val claim = async { ledger.claimDownloadSafRoot("srv:item", "content://task-a") }
        claimEntered.await()
        val rootSwitch = async { ledger.setDownloadLocation("content://picked-b", "saf", null) }
        runCurrent()
        assertFalse(rootSwitch.isCompleted)
        assertTrue(fake.releaseCalls.isEmpty())

        allowClaim.complete(Unit)
        claim.await()
        rootSwitch.await()
        assertEquals("content://root-a", harness.library.getDownloadedMedia("srv:item")?.saf_root_uri)
        assertTrue(fake.releaseCalls.isEmpty())

        ledger.claimDownloadSafRoot("srv:item", "content://picked-b")
        assertEquals("content://root-b", harness.library.getDownloadedMedia("srv:item")?.saf_root_uri)
        assertEquals(listOf("content://root-a"), fake.releaseCalls)
    }

    @Test
    fun `startup backfills legacy row and task roots then releases only orphans`() = runTest {
        harness = DmsHarness.create()
        seedRow("srv:legacy", videoFilePath = "content://child-a", status = COMPLETED)
        seedRow("srv:task", taskId = "task-d", status = DOWNLOADING)
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-b" to "content://root-b",
                "content://child-a" to "content://root-a",
                "content://dir-d" to "content://root-d",
                "content://root-a" to "content://root-a",
                "content://root-b" to "content://root-b",
                "content://root-c" to "content://root-c",
                "content://root-d" to "content://root-d",
            ),
            persistedRoots = setOf("content://root-a", "content://root-b", "content://root-c", "content://root-d"),
        )
        val ledger = ledger(fake, MemoryLocationStore(saf("content://picked-b")))
        val task = documentTask("task-d", "srv:task", "content://dir-d")

        ledger.reconcile(listOf(task))
        assertEquals("content://root-a", harness.library.getDownloadedMedia("srv:legacy")?.saf_root_uri)
        assertEquals("content://root-d", harness.library.getDownloadedMedia("srv:task")?.saf_root_uri)
        assertEquals(setOf("content://root-a", "content://root-b", "content://root-d"), fake.persistedRoots)
        assertEquals(listOf("content://root-c"), fake.releaseCalls)

        ledger.reconcile(listOf(task))
        assertEquals(listOf("content://root-c"), fake.releaseCalls)
    }

    @Test
    fun `a failed legacy root resolution defers every orphan release`() = runTest {
        harness = DmsHarness.create()
        seedRow("srv:legacy", videoFilePath = "content://unresolved-child", status = COMPLETED)
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-b" to "content://root-b",
                "content://root-b" to "content://root-b",
                "content://root-c" to "content://root-c",
            ),
            persistedRoots = setOf("content://root-b", "content://root-c"),
        )
        val ledger = ledger(fake, MemoryLocationStore(saf("content://picked-b")))

        ledger.reconcile(emptyList())

        assertTrue(fake.releaseCalls.isEmpty())
        assertEquals(setOf("content://root-b", "content://root-c"), fake.persistedRoots)
    }

    private fun switchFailure(failurePoint: String) = runTest {
        harness = DmsHarness.create()
        val location = MemoryLocationStore(saf("content://picked-a"))
        if (failurePoint == "preference write") location.onWrite = { if (it == 1) throw IllegalStateException("injected preference write failure") }
        if (failurePoint == "storage refresh") location.onRefresh = { if (it == 1) throw IllegalStateException("injected refresh failure") }
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-a" to "content://root-a",
                "content://picked-b" to "content://root-b",
                "content://root-a" to "content://root-a",
                "content://root-b" to "content://root-b",
            ),
            persistedRoots = setOf("content://root-a", "content://root-b"),
        )
        val manager = harness.manager(safStorage = fake, locationStore = location)

        assertFailsWith<IllegalStateException> { manager.setDownloadLocation("content://picked-b", "saf") }

        assertEquals(saf("content://picked-a"), location.location)
        if (failurePoint == "preference write") {
            assertEquals(listOf("content://root-b"), fake.releaseCalls)
        } else {
            assertTrue(fake.releaseCalls.isEmpty())
            assertTrue("content://root-b" in fake.persistedRoots)
        }
    }

    @Test
    fun `preference write restores the old location without discarding a usable grant`() = switchFailure("preference write")

    @Test
    fun `storage refresh restores the old location without discarding a usable grant`() = switchFailure("storage refresh")

    @Test
    fun `rollback retains a newly selected root already claimed by a row`() = runTest {
        harness = DmsHarness.create()
        seedRow("srv:item")
        harness.library.updateDownloadSafRoot("srv:item", "content://root-b")
        val location = MemoryLocationStore(saf("content://picked-a")).apply { onRefresh = { if (it == 1) throw IllegalStateException("injected refresh failure") } }
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-a" to "content://root-a",
                "content://picked-b" to "content://root-b",
                "content://root-a" to "content://root-a",
                "content://root-b" to "content://root-b",
            ),
            persistedRoots = setOf("content://root-a", "content://root-b"),
        )
        val manager = harness.manager(safStorage = fake, locationStore = location)

        assertFailsWith<IllegalStateException> { manager.setDownloadLocation("content://picked-b", "saf") }

        assertEquals(saf("content://picked-a"), location.location)
        assertTrue(fake.releaseCalls.isEmpty())
        assertTrue("content://root-b" in fake.persistedRoots)
    }

    /**
     * The caller is cancelled while the switch is held at [heldAt]: the switch still ends whole, as one that was never
     * cancelled (the settings screen leaving mid-switch must not split the location).
     */
    private fun cancelledSwitch(heldAt: String, from: DownloadLocationSnapshot, released: List<String>) = runTest {
        harness = DmsHarness.create()
        val location = MemoryLocationStore(from)
        val entered = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val hold: suspend (Int) -> Unit = {
            entered.complete(Unit)
            release.await()
        }
        if (heldAt == "preference write") location.onWrite = hold else location.onRefresh = hold
        val fake = DocumentTreeFake(
            canonicalRoots = mapOf(
                "content://picked-a" to "content://root-a",
                "content://picked-b" to "content://root-b",
                "content://root-a" to "content://root-a",
                "content://root-b" to "content://root-b",
            ),
            persistedRoots = setOf("content://root-a", "content://root-b"),
        )
        val manager = harness.manager(safStorage = fake, locationStore = location)

        val switch = launch { manager.setDownloadLocation("content://picked-b", "saf") }
        entered.await()
        switch.cancel()
        release.complete(Unit)
        switch.join()

        assertEquals(saf("content://picked-b"), location.location)
        assertEquals(location.location, location.live, "the storage runs on the stored location")
        assertEquals(released, fake.releaseCalls)
        assertTrue("content://root-b" in fake.persistedRoots)
    }

    @Test
    fun `a switch cancelled during its preference write stores and loads the whole new location`() =
        cancelledSwitch("preference write", from = DownloadLocationSnapshot(null, null), released = emptyList())

    @Test
    fun `a switch cancelled during its storage refresh loads the new location and releases the old grant`() =
        cancelledSwitch("storage refresh", from = saf("content://picked-a"), released = listOf("content://root-a"))
}

class DownloadManagerServiceStackedTest {
    private lateinit var harness: DmsHarness
    private lateinit var item: MediaItem
    private val globalKey = "srv:item-1"
    private val subtitleBase = "https://example.test/subtitle"

    @AfterTest
    fun close() = harness.close()

    private suspend fun fixture(saf: Boolean = false) {
        val (h, i) = supplementaryFixture(safBaseUri = if (saf) DocumentTreeFake.ROOT_URI else null)
        harness = h
        item = i
    }

    private fun stackedResolution() = DownloadResolution(
        videoUrl = "https://example.test/library/parts/1/file.mkv",
        externalSubtitles = listOf(DownloadSubtitleSpec(1, "$subtitleBase/1", "srt")),
        additionalParts = listOf(
            DownloadPartResolution("https://example.test/library/parts/2/file.mkv", listOf(DownloadSubtitleSpec(2, "$subtitleBase/2", "srt"))),
            DownloadPartResolution("https://example.test/library/parts/3/file.mp4", listOf(DownloadSubtitleSpec(3, "$subtitleBase/3", "srt"))),
        ),
    )

    /** A manager whose native enqueues land in the returned downloader. */
    private fun startManager(
        client: SupplementaryBackend,
        server: ScriptedSubtitleServer? = null,
        safStorage: SafStorageOperations = UnsupportedSafStorage,
    ): Pair<DownloadManagerService, FakeNativeDownloader> {
        val downloader = FakeNativeDownloader()
        val manager = if (server != null) {
            harness.manager({ _, _ -> client }, downloader, safStorage = safStorage, http = server.client)
        } else {
            harness.manager({ _, _ -> client }, downloader, safStorage = safStorage)
        }
        return manager to downloader
    }

    /** Lands [content] at [task]'s file and reports [reported] (default: the task) complete; returns the file's path. */
    private suspend fun complete(downloader: FakeNativeDownloader, task: DownloadTask, content: String, reported: DownloadTask = task): String {
        val path = downloader.filePath(task)
        writeFile(path, content)
        real { harness.report(downloader, TaskStatusUpdate(reported, TaskStatus.COMPLETE)) }
        return path
    }

    private suspend fun row() = harness.library.getDownloadedMedia(globalKey)!!

    @Test
    fun `fetches every file in order then stores and deletes them all`() = runTest {
        fixture()
        val server = ScriptedSubtitleServer()
        val client = SupplementaryBackend(item, { stackedResolution() })
        val (manager, downloader) = startManager(client, server)
        val log = manager.progressLog(backgroundScope)

        manager.queueDownload(item, client)

        val first = downloader.nextEnqueued()
        assertTrue(first.url.endsWith("/parts/1/file.mkv"))
        log.clear()
        val firstPath = complete(downloader, first, "first")
        assertEquals(DOWNLOADING.code, row().status, "the item is not downloaded until every file is")

        val second = downloader.nextEnqueued()
        val firstBaseName = LocalPath.withoutExtension(LocalPath.basename(firstPath))
        assertTrue(second.url.endsWith("/parts/2/file.mkv"))
        assertEquals("$firstBaseName - part2.mkv", second.filename)
        assertEquals(LocalPath.dirname(firstPath), LocalPath.dirname(downloader.filePath(second)))
        harness.idle()
        assertTrue(log.events.none { it.progress < 33 }, "no fall back to 0% between files")

        // Progress covers the whole item: the stored first file plus half of the second.
        harness.report(downloader, TaskProgressUpdate(second, 0.5, 1000))
        assertEquals(50, log.events.last().progress)
        assertEquals("first".length + 500L, log.events.last().downloadedBytes)
        assertEquals("first".length + 1000L, log.events.last().totalBytes)
        val secondPath = complete(downloader, second, "second")

        val third = downloader.nextEnqueued()
        assertTrue(third.url.endsWith("/parts/3/file.mp4"))
        assertEquals("$firstBaseName - part3.mp4", third.filename)
        val thirdPath = complete(downloader, third, "third")
        val files = listOf(firstPath, secondPath, thirdPath)

        val stored = row()
        assertEquals(COMPLETED.code, stored.status)
        assertEquals(3, stored.partCount)
        assertNotNull(stored.downloaded_at)
        assertEquals(files, stored.storedPartPaths.map { harness.storage.ensureAbsolutePath(it) })
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())

        // Each file's subtitles sit next to that file, where playback looks.
        assertEquals(listOf(1, 2, 3), server.trackRequests.sorted())
        files.forEachIndexed { index, file ->
            val sidecar = LocalPath.join(harness.storage.sidecarSubtitlesDirectoryPath(file), "${index + 1}.srt")
            assertTrue(exists(sidecar), sidecar)
        }

        val deleter = harness.manager({ _, _ -> client })
        real { deleter.deleteDownload(globalKey) }

        assertNull(harness.library.getDownloadedMedia(globalKey))
        for (file in files) {
            assertFalse(exists(file), file)
            assertFalse(exists(harness.storage.sidecarSubtitlesDirectoryPath(file)), file)
        }
    }

    @Test
    fun `a restart between files resumes at the next file instead of starting over`() = runTest {
        fixture()
        val client = SupplementaryBackend(item, { stackedResolution() })
        val (before, beforeDownloader) = startManager(client)
        before.queueDownload(item, client)
        val first = beforeDownloader.nextEnqueued()
        // The app is killed while the first file downloads; its context is gone.
        before.dispose()

        val (after, downloader) = startManager(client)
        downloader.holds(first)
        harness.start(after, downloader)
        val log = after.progressLog(backgroundScope)
        // The downloader reports the finished task after the restart.
        val firstPath = complete(downloader, first, "first")

        val second = downloader.nextEnqueued()
        assertEquals("${LocalPath.withoutExtension(LocalPath.basename(firstPath))} - part2.mkv", second.filename)
        assertTrue(exists(firstPath), "the stored file is kept")
        val stored = row()
        assertEquals(DOWNLOADING.code, stored.status)
        assertEquals(second.taskId, stored.bg_task_id)
        assertFalse(LocalPath.isAbsolute(stored.video_file_path!!), "stored like any app-storage path")
        assertEquals(firstPath, harness.storage.ensureAbsolutePath(stored.video_file_path!!))
        assertEquals(1, stored.nextMissingPartIndex)
        harness.idle()
        assertTrue(log.events.isNotEmpty())
        assertTrue(log.events.all { it.progress == 33 }, "resumes at a third, not 0%: ${log.events}")
    }

    @Test
    fun `a file that cannot be fetched fails the whole download`() = runTest {
        fixture()
        val client = SupplementaryBackend(item, { stackedResolution() })
        val (manager, downloader) = startManager(client)
        manager.queueDownload(item, client)
        complete(downloader, downloader.nextEnqueued(), "first")

        val second = downloader.nextEnqueued()
        harness.report(downloader, TaskStatusUpdate(second, TaskStatus.NOT_FOUND))

        assertEquals(FAILED.code, row().status)
        assertEquals(1, row().nextMissingPartIndex)
    }

    @Test
    fun `a replayed completion of a finished file records nothing`() = runTest {
        fixture(saf = true)
        // Holds the download between files (the first recorded, the next not enqueued) at its next root lookup.
        var holdArmed = false
        val held = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val fake = DocumentTreeFake(
            resolveOverride = {
                if (holdArmed) {
                    holdArmed = false
                    held.complete(Unit)
                    release.await()
                }
                DocumentTreeFake.ROOT_URI
            },
        )
        fake.addMovieDir(harness.storage, item)
        val client = SupplementaryBackend(item, { stackedResolution() })
        val (manager, downloader) = startManager(client, safStorage = fake)
        manager.queueDownload(item, client)
        val first = downloader.nextEnqueued()
        val firstUri = fake.addMovieFile(harness.storage, item, first.filename)

        holdArmed = true
        downloader.callbacks.onStatus(TaskStatusUpdate(first, TaskStatus.COMPLETE))
        held.await()
        val completion = harness.work()
        // The downloader replays the same completion while the next file waits.
        downloader.callbacks.onStatus(TaskStatusUpdate(first, TaskStatus.COMPLETE))
        harness.idle(*completion.toTypedArray())

        var stored = row()
        assertEquals(DOWNLOADING.code, stored.status)
        assertEquals(listOf(firstUri), stored.storedPartPaths, "the replay must not record the file as the next part")
        assertNull(stored.bg_task_id)

        release.complete(Unit)
        harness.idle()
        val second = downloader.nextEnqueued()
        assertEquals(harness.storage.partFilePath(first.filename, 1, "mkv"), second.filename)
        stored = row()
        assertEquals(DOWNLOADING.code, stored.status)
        assertEquals(listOf(firstUri), stored.storedPartPaths)
        assertEquals(second.taskId, stored.bg_task_id)
    }

    @Test
    fun `requesting a failed stacked download again deletes what it stored and starts over`() = runTest {
        fixture()
        val client = SupplementaryBackend(item, { stackedResolution() })
        val (manager, downloader) = startManager(client)
        manager.queueDownload(item, client)
        val firstPath = complete(downloader, downloader.nextEnqueued(), "first")
        val secondPath = complete(downloader, downloader.nextEnqueued(), "second")
        harness.report(downloader, TaskStatusUpdate(downloader.nextEnqueued(), TaskStatus.NOT_FOUND))
        assertEquals(FAILED.code, row().status)

        // A new request may pick another version: nothing stored earlier is reused.
        manager.queueDownload(item, client)

        val restarted = downloader.nextEnqueued()
        assertTrue(restarted.url.endsWith("/parts/1/file.mkv"))
        assertFalse(exists(secondPath), "an earlier file must not be orphaned")
        assertFalse(exists(firstPath))
        val stored = row()
        assertEquals(DOWNLOADING.code, stored.status)
        assertNull(stored.video_file_path)
        assertEquals(listOf<String?>(null, null), stored.additionalPartPathList)
    }

    @Test
    fun `SAF deletion removes every stored document and the subtitle folder of each later file`() = runTest {
        harness = DmsHarness.create(DocumentTreeFake.ROOT_URI)
        val movie = testMediaItem("movie-1", MediaKind.MOVIE, "srv", title = "Movie", year = 2000)
        harness.putPlexMetadata("srv", "movie-1", plexFields("ratingKey" to "movie-1", "type" to "movie", "title" to "Movie", "year" to 2000))
        harness.data.insertDownload("srv", "movie-1", status = COMPLETED)
        val fake = DocumentTreeFake()
        val firstName = harness.storage.getMovieSafFileName(movie, "mkv")
        val uris = listOf(
            fake.addMovieFile(harness.storage, movie, firstName),
            fake.addMovieFile(harness.storage, movie, harness.storage.partFilePath(firstName, 1, "mkv")),
            fake.addMovieFile(harness.storage, movie, harness.storage.partFilePath(firstName, 2, "mp4")),
        )
        harness.library.updateVideoFilePath(movie.globalKey, uris.first())
        harness.library.updateAdditionalPartPaths(movie.globalKey, uris.drop(1))
        val partSubtitles = listOf(1, 2).map { harness.storage.getPartSubtitlesDirectory(ServerId("srv"), "movie-1", it) }
        partSubtitles.forEach { writeFile(LocalPath.join(it, "9.srt"), "subtitle") }
        val manager = harness.manager(safStorage = fake)

        manager.deleteDownload(movie.globalKey)

        assertNull(harness.library.getDownloadedMedia(movie.globalKey))
        uris.forEach { assertFalse(fake.existsNow(it), it) }
        partSubtitles.forEach { assertFalse(exists(it), it) }
    }

    @Test
    fun `a new attempt sweeps every numbered copy of its file and enqueues a pausable task`() = runTest {
        fixture(saf = true)
        val client = SupplementaryBackend(item, { DownloadResolution("https://example.test/library/parts/1/file.mkv") })
        val fake = DocumentTreeFake()
        val fileName = harness.storage.getMovieSafFileName(item, "mkv")
        val base = LocalPath.withoutExtension(fileName)
        // What interrupted attempts leave, numbered by either provider scheme, at any depth.
        val leftovers = listOf(fileName, "$base (1).mkv", "$base (1) (1).mkv", "$base (2) (1) (1).mkv", "$fileName (1)", "$fileName (1) (1)")
            .map { fake.addMovieFile(harness.storage, item, it) }
        val unrelated = listOf("$base (1).srt", "$base (copy).mkv", "Other (1).mkv").map { fake.addMovieFile(harness.storage, item, it) }
        val (manager, downloader) = startManager(client, safStorage = fake)

        manager.queueDownload(item, client)
        val task = downloader.nextEnqueued()

        leftovers.forEach { assertFalse(fake.existsNow(it), it) }
        unrelated.forEach { assertTrue(fake.existsNow(it), it) }
        assertTrue(task.isDocumentTask)
        assertEquals(fileName, task.filename)
        assertTrue(task.allowPause, "an unpausable task fails at the end of every run window instead of continuing")
    }
}
