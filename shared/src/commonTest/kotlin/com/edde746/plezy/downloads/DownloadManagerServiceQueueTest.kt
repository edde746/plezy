package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadSubtitleSpec
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.job
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/** The `srv` movie `item-1` the queue and supplementary suites download, cached as the server returned it. */
internal suspend fun supplementaryFixture(thumbPath: String? = null, safBaseUri: String? = null): Pair<DmsHarness, MediaItem> {
    val harness = DmsHarness.create(safBaseUri)
    val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie", thumbPath = thumbPath)
    harness.putPlexMetadata(
        "srv",
        "item-1",
        JsonObject(
            buildMap {
                put("ratingKey", JsonPrimitive("item-1"))
                put("type", JsonPrimitive("movie"))
                put("title", JsonPrimitive("Movie"))
                if (thumbPath != null) put("thumb", JsonPrimitive(thumbPath))
            },
        ),
    )
    return harness to item
}

/** Records the subtitle requests (`…/subtitle/{id}`); [failuresRemaining] answers 500 that many times per track. */
internal class ScriptedSubtitleServer(
    failuresRemaining: Map<Int, Int> = emptyMap(),
    private val gate: CompletableDeferred<Unit>? = null,
    private val requestStarted: CompletableDeferred<Unit>? = null,
) {
    private val failures = failuresRemaining.toMutableMap()
    private val requests = MutableStateFlow(emptyList<Int>())
    val trackRequests: List<Int> get() = requests.value

    val client = DmsHarness.httpClient { request ->
        val trackId = request.url.segments.last().toInt()
        requests.update { it + trackId }
        requestStarted?.complete(Unit)
        gate?.await()
        val remaining = failures[trackId] ?: 0
        if (remaining > 0) {
            failures[trackId] = remaining - 1
            respond("failed", HttpStatusCode.InternalServerError)
        } else {
            respond("subtitle", HttpStatusCode.OK)
        }
    }
}

class DownloadManagerServiceQueueTest {
    private lateinit var harness: DmsHarness
    private lateinit var item: MediaItem
    private val globalKey = "srv:item-1"

    @AfterTest
    fun close() = harness.close()

    private suspend fun fixture(thumbPath: String? = null) {
        val (h, i) = supplementaryFixture(thumbPath)
        harness = h
        item = i
    }

    private fun backend(resolution: suspend () -> DownloadResolution) = SupplementaryBackend(item, resolution)

    private fun plainVideo() = DownloadResolution("https://example.test/video")

    private suspend fun row(key: String = globalKey) = harness.library.getDownloadedMedia(key)

    private suspend fun queueRows() = harness.library.getQueue()

    private suspend fun seedQueued(key: String, priority: Int = 0, scope: String? = null) {
        harness.data.insertDownload(key.substringBefore(':'), key.substringAfter(':'), globalKey = key, status = QUEUED, clientScopeId = scope)
        harness.library.addToQueue(key, priority)
    }

    /** The download is mid-transfer on `current-task`, its queue row holding the supplementary intent. */
    private suspend fun seedCompleting(downloadSubtitles: Boolean, downloadArtwork: Boolean = false) {
        harness.data.insertDownload("srv", "item-1", status = DOWNLOADING)
        harness.library.updateBgTaskId(globalKey, "current-task")
        harness.library.addToQueue(globalKey, 0, downloadSubtitles, downloadArtwork)
    }

    /** The video is stored; the queue row still asks for supplementary files. */
    private suspend fun seedCompletedPending(downloadSubtitles: Boolean, downloadArtwork: Boolean = false) {
        harness.data.insertDownload("srv", "item-1", status = COMPLETED)
        harness.library.updateVideoFilePath(globalKey, "downloads/srv/item-1/video.mp4")
        harness.library.addToQueue(globalKey, 0, downloadSubtitles, downloadArtwork)
    }

    private fun denied(): Nothing = throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "denied", statusCode = 401)

    /** [manager] starts over [downloader] running [task], which then reports it complete. */
    private suspend fun completeTask(manager: DownloadManagerService, downloader: FakeNativeDownloader, task: DownloadTask = downloadTask("current-task", globalKey)) {
        downloader.holds(task)
        harness.start(manager, downloader)
        real { harness.report(downloader, TaskStatusUpdate(task, TaskStatus.COMPLETE)) }
    }

    // Durability

    @Test
    fun `pin failure occurs after durable queue creation and still starts processing`() = runTest {
        fixture()
        val client = backend(::plainVideo)
        harness.sql("CREATE TRIGGER reject_cache_pin BEFORE UPDATE OF pinned ON api_cache BEGIN SELECT RAISE(ABORT, 'cache pin rejected'); END")
        var attempts = 0
        var observedDurablePair = false
        val started = CompletableDeferred<Unit>()
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), queueProcessorOverride = {
            attempts++
            observedDurablePair = row()?.status == QUEUED.code && queueRows().size == 1
            started.complete(Unit)
        })

        manager.queueDownload(item, client)
        started.await()

        assertEquals(1, attempts)
        assertTrue(observedDurablePair)
        assertNotNull(row())
        assertEquals(1, queueRows().size)
    }

    @Test
    fun `an already queued request refreshes policy and restarts processing`() = runTest {
        fixture()
        seedQueued(globalKey, priority = 1)
        val client = backend(::plainVideo)
        var attempts = 0
        val started = CompletableDeferred<Unit>()
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), queueProcessorOverride = {
            attempts++
            started.complete(Unit)
        })
        val log = manager.progressLog(backgroundScope)

        manager.queueDownload(item, client, priority = 8, downloadSubtitles = false, downloadArtwork = false)
        started.await()

        val queue = queueRows().single()
        assertEquals(8L, queue.priority)
        assertFalse(queue.download_subtitles)
        assertFalse(queue.download_artwork)
        assertEquals(1, attempts)
        assertEquals(1, log.events.size)
    }

    @Test
    fun `an active or completed request emits and starts no duplicate work`() = runTest {
        fixture()
        val client = backend(::plainVideo)
        for (status in listOf(DOWNLOADING, PAUSED, COMPLETED)) {
            harness.data.insertDownload("srv", "item-1", status = status)
            var attempts = 0
            val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), queueProcessorOverride = { attempts++ })
            val log = manager.progressLog(backgroundScope)

            manager.queueDownload(item, client)
            harness.idle()

            assertEquals(status.code, row()?.status)
            assertTrue(queueRows().isEmpty())
            assertEquals(0, attempts)
            assertTrue(log.events.isEmpty())
            manager.dispose()
            harness.library.deleteDownload(globalKey)
        }
    }

    @Test
    fun `transient preparation failure remains queued and starts an automatic retry`() = runTest {
        fixture()
        var attempts = 0
        val retryStarted = CompletableDeferred<Unit>()
        val retryGate = CompletableDeferred<DownloadResolution>()
        val client = backend {
            attempts++
            if (attempts == 1) throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "temporary PlaybackInfo failure", statusCode = 500)
            retryStarted.complete(Unit)
            retryGate.await()
        }
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), autoRetryDelay = Duration.ZERO)

        manager.queueDownload(item, client)
        retryStarted.await()

        assertEquals(2, attempts)
        assertEquals(1L, row()?.retry_count)
        assertEquals(1, queueRows().size)
        harness.library.updateDownloadStatus(globalKey, DownloadedMediaStatus.CANCELLED)
        retryGate.complete(plainVideo())
    }

    @Test
    fun `preparation retries exhaust the configured app retry budget`() = runTest {
        fixture()
        var attempts = 0
        val client = backend {
            attempts++
            throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "temporary PlaybackInfo failure", statusCode = 500)
        }
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), autoRetryDelay = Duration.ZERO)
        val log = manager.progressLog(backgroundScope)

        manager.queueDownload(item, client)
        harness.idle()

        assertEquals(4, attempts)
        assertEquals(FAILED.code, row()?.status)
        // Three retries; the final failure is not one.
        assertEquals(3L, row()?.retry_count)
    }

    @Test
    fun `a refused preparation fails with a localized reason and not the exception text`() = runTest {
        fixture()
        val client = backend {
            throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "PlaybackInfo refused by https://jf.example.test/Items/item-1/PlaybackInfo", statusCode = 403)
        }
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader(), autoRetryDelay = Duration.ZERO)
        val log = manager.progressLog(backgroundScope)

        manager.queueDownload(item, client)
        log.awaitFirst { it.status == FAILED }
        harness.idle()

        assertEquals(FAILED.code, row()?.status)
        assertEquals(T.downloads.errorDownloadFailedWithReason(T.errors.reasonRefused), row()?.error_message)
    }

    @Test
    fun `cold recovery repairs a legacy queue gap once before native recovery`() = runTest {
        fixture()
        harness.data.insertDownload("srv", "item-1", status = QUEUED)
        val client = backend(::plainVideo)
        var nativeRecoveries = 0
        var processing = 0
        val started = CompletableDeferred<Unit>()
        val first = harness.manager({ _, _ -> client }, FakeNativeDownloader(), nativeRecoveryOverride = { nativeRecoveries++ }, queueProcessorOverride = {
            processing++
            harness.library.updateDownloadStatus(globalKey, DOWNLOADING)
            started.complete(Unit)
        })

        first.recoverInterruptedDownloads()
        assertEquals(1, nativeRecoveries)
        assertEquals(1, queueRows().size)
        first.resumeQueuedDownloads(client)
        started.await()
        assertEquals(1, processing)
        first.dispose()

        val second = harness.manager({ _, _ -> client }, FakeNativeDownloader(), nativeRecoveryOverride = { nativeRecoveries++ }, queueProcessorOverride = { processing++ })
        second.recoverInterruptedDownloads()
        second.resumeQueuedDownloads(client)
        harness.idle()

        assertEquals(2, nativeRecoveries)
        assertEquals(1, processing)
        assertEquals(1, queueRows().size)
        assertEquals(DOWNLOADING.code, row()?.status)
    }

    // Supplementary files

    private val twoSubtitles = listOf(
        DownloadSubtitleSpec(1, "https://example.test/subtitle/1", "srt"),
        DownloadSubtitleSpec(2, "https://example.test/subtitle/2", "srt"),
    )

    @Test
    fun `isolates subtitle failures and repairs only missing tracks after restart`() = runTest {
        fixture()
        val server = ScriptedSubtitleServer(failuresRemaining = mapOf(1 to 1))
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitles = twoSubtitles) }
        seedCompleting(downloadSubtitles = true)
        val downloader = FakeNativeDownloader()
        val first = harness.manager({ _, _ -> client }, downloader, http = server.client)

        completeTask(first, downloader)

        // Sidecars sit next to the video as stored, where playback looks for them.
        val stored = row()!!.video_file_path!!
        val subtitles = harness.storage.sidecarSubtitlesDirectoryPath(harness.storage.ensureAbsolutePath(stored))
        val firstPath = LocalPath.join(subtitles, "1.srt")
        val secondPath = LocalPath.join(subtitles, "2.srt")
        assertEquals(listOf(1, 2), server.trackRequests)
        assertFalse(exists(firstPath))
        assertTrue(exists(secondPath))
        assertEquals(COMPLETED.code, row()?.status)
        assertEquals(1, harness.library.getPendingSupplementaryQueueItems().size)
        first.dispose()

        val restarted = harness.manager({ _, _ -> client }, http = server.client)
        real { restarted.repairPendingSupplementaryDownloads() }

        assertEquals(listOf(1, 2, 1), server.trackRequests)
        assertTrue(exists(firstPath))
        assertTrue(exists(secondPath))
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
        assertEquals(COMPLETED.code, row()?.status)
        assertEquals(stored, row()?.video_file_path)
        assertNull(harness.library.getNextQueueItem())
    }

    @Test
    fun `retains unresolved subtitle enrichment and settles a later authoritative empty list`() = runTest {
        fixture()
        var resolved = false
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitlesResolved = resolved) }
        seedCompletedPending(downloadSubtitles = true)
        val manager = harness.manager({ _, _ -> client })

        manager.repairPendingSupplementaryDownloads()
        assertEquals(1, harness.library.getPendingSupplementaryQueueItems().size)

        resolved = true
        manager.repairPendingSupplementaryDownloads()
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
    }

    @Test
    fun `supplementary repair reuses the persisted media source`() = runTest {
        fixture()
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitlesResolved = true) }
        seedCompletedPending(downloadSubtitles = true)
        harness.library.updateDownloadMediaSource(globalKey, "source-2")
        val manager = harness.manager({ _, _ -> client })

        manager.repairPendingSupplementaryDownloads()

        assertEquals("source-2", client.lastMediaSourceId)
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
    }

    @Test
    fun `subtitle disabled completion issues no sidecar request or retry marker`() = runTest {
        fixture()
        val server = ScriptedSubtitleServer()
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitles = twoSubtitles.take(1)) }
        seedCompleting(downloadSubtitles = false)
        val downloader = FakeNativeDownloader()
        val manager = harness.manager({ _, _ -> client }, downloader, http = server.client)

        completeTask(manager, downloader)

        assertTrue(server.trackRequests.isEmpty())
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
        assertTrue(queueRows().isEmpty())
    }

    @Test
    fun `coalesces concurrent persisted supplementary repairs`() = runTest {
        fixture()
        val gate = CompletableDeferred<Unit>()
        val requestStarted = CompletableDeferred<Unit>()
        val server = ScriptedSubtitleServer(gate = gate, requestStarted = requestStarted)
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitles = twoSubtitles.take(1)) }
        seedCompletedPending(downloadSubtitles = true)
        val manager = harness.manager({ _, _ -> client }, http = server.client)

        val firstRepair = async { manager.repairPendingSupplementaryDownloads() }
        requestStarted.await()
        val secondRepair = async { manager.repairPendingSupplementaryDownloads() }
        gate.complete(Unit)
        firstRepair.await()
        secondRepair.await()

        assertEquals(listOf(1), server.trackRequests)
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
    }

    @Test
    fun `recovery completion preserves the base directory of a custom root task path`() = runTest {
        fixture()
        seedCompleting(downloadSubtitles = false)
        val custom = LocalPath.join(harness.root.root, "Media")
        harness.data.deviceSettings.setCustomDownloadPath(custom)
        harness.storage.refreshCustomPath()
        val downloader = FakeNativeDownloader()
        val manager = harness.manager(downloader = downloader)
        // A custom download folder enqueues a root task; only the downloader rebuilds its absolute file path.
        val task = rootTask("current-task", globalKey, LocalPath.join(custom, "Movie (2020)"))

        completeTask(manager, downloader, task)

        val stored = row()!!
        assertEquals(COMPLETED.code, stored.status)
        assertEquals(downloader.filePath(task), stored.video_file_path)
        assertEquals(LocalPath.join(custom, "Movie (2020)", "video.mp4"), stored.video_file_path)
        assertTrue(LocalPath.isAbsolute(stored.video_file_path!!))
    }

    @Test
    fun `queue drain skips an unresolvable head and still reaches the next item`() = runTest {
        fixture()
        // Stale head: highest priority, but its server has no client.
        seedQueued("gone:stale-1", priority = 9)
        seedQueued(globalKey)
        var resolveAttempts = 0
        val client = backend {
            resolveAttempts++
            denied()
        }
        val manager = harness.manager({ serverId, _ -> client.takeIf { serverId.value == "srv" } }, FakeNativeDownloader())
        val log = manager.progressLog(backgroundScope)

        manager.resumeQueuedDownloads(client)
        log.awaitFirst { it.globalKey == globalKey && it.status == FAILED }
        harness.idle()

        assertEquals(1, resolveAttempts)
        // The unresolvable head is skipped, not consumed: it waits for its server.
        assertEquals("gone:stale-1", queueRows().single().media_global_key)
        assertEquals(QUEUED.code, row("gone:stale-1")?.status)
    }

    @Test
    fun `a resume landing mid drain replays the pass for a server that connected during it`() = runTest {
        fixture()
        // The 'late' server is offline when the drain starts and connects mid-drain.
        seedQueued("late:late-1", priority = 9)
        seedQueued(globalKey)
        var lateOnline = false
        lateinit var manager: DownloadManagerService
        var lateAttempts = 0
        val lateClient = SupplementaryBackend(testMediaItem("late-1", MediaKind.MOVIE, "late", title = "Late Movie"), {
            lateAttempts++
            denied()
        }, serverId = "late")
        var srvAttempts = 0
        lateinit var srvClient: SupplementaryBackend
        srvClient = backend {
            srvAttempts++
            // Mid-drain: 'late' connects and its resume arrives while the drain still runs. Without the rerun it is
            // dropped, and late-1, skipped as offline earlier in this pass, stays queued.
            lateOnline = true
            manager.resumeQueuedDownloads(srvClient)
            harness.idle(currentCoroutineContext().job)
            denied()
        }
        manager = harness.manager({ serverId, _ ->
            when (serverId.value) {
                "srv" -> srvClient
                "late" -> lateClient.takeIf { lateOnline }
                else -> null
            }
        }, FakeNativeDownloader())
        val log = manager.progressLog(backgroundScope)

        manager.resumeQueuedDownloads(srvClient)
        log.awaitFirst { it.globalKey == "late:late-1" && it.status == FAILED }
        harness.idle()
        assertTrue(queueRows().isEmpty())

        // One pass handled 'srv', the replayed pass 'late': neither twice.
        assertEquals(1, srvAttempts)
        assertEquals(1, lateAttempts)
        assertEquals(FAILED.code, row("late:late-1")?.status)
    }

    @Test
    fun `a shared row queued under an inactive co owner scope drains through the active owner`() = runTest {
        fixture()
        seedQueued(globalKey, scope = "srv/user-a")
        harness.library.addDownloadOwner("profile-a", globalKey, BackendKind.JELLYFIN.id, "srv/user-a")
        harness.library.addDownloadOwner("profile-b", globalKey, BackendKind.JELLYFIN.id, "srv/user-b")
        var resolveAttempts = 0
        val client = backend {
            resolveAttempts++
            denied()
        }
        // Only profile B's user scope has a client; the row carries profile A's.
        val manager = harness.manager({ _, scope -> client.takeIf { scope == "srv/user-b" } }, FakeNativeDownloader())
        val log = manager.progressLog(backgroundScope)

        manager.resumeQueuedDownloads(client)
        log.awaitFirst { it.globalKey == globalKey && it.status == FAILED }
        harness.idle()
        assertTrue(queueRows().isEmpty())

        assertEquals(1, resolveAttempts)
    }

    @Test
    fun `a manual retry re arms the queue after the circuit breaker trips`() = runTest {
        fixture()
        // Nothing is cached for these ids and the server can't fetch them: every preparation fails for good, and three
        // in a row trip the breaker before the lowest-priority item.
        for (i in 1..4) seedQueued("srv:missing-$i", priority = 10 - i)
        val client = backend(::plainVideo)
        val manager = harness.manager({ _, _ -> client }, FakeNativeDownloader())
        val log = manager.progressLog(backgroundScope)

        manager.resumeQueuedDownloads(client)
        harness.idle()
        assertEquals("srv:missing-4", queueRows().single().media_global_key, "the breaker stopped the first pass")

        manager.retryDownload("srv:missing-1", client)
        log.awaitFirst { it.globalKey == "srv:missing-4" && it.status == FAILED }
        harness.idle()
        assertTrue(queueRows().isEmpty())

        assertEquals(FAILED.code, row("srv:missing-4")?.status)
    }

    // Deferred supplementary repair

    @Test
    fun `completed repair persists artwork without announcing downloading`() = runTest {
        fixture(thumbPath = "/repair-thumb")
        val client = backend(::plainVideo)
        seedCompletedPending(downloadSubtitles = false, downloadArtwork = true)
        val manager = harness.manager({ _, _ -> client }, http = DmsHarness.httpClient { respond("image bytes", HttpStatusCode.OK) })
        val log = manager.progressLog(backgroundScope)

        manager.repairPendingSupplementaryDownloads()
        harness.idle()

        assertTrue(log.events.none { it.status == DOWNLOADING })
        assertTrue(log.events.any { it.status == COMPLETED && it.thumbPath == artworkStorageKey("/repair-thumb") })
        assertEquals(artworkStorageKey("/repair-thumb"), row()?.thumb_path)
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
    }

    @Test
    fun `normal completion still announces artwork and subtitle steps`() = runTest {
        fixture(thumbPath = "/normal-thumb")
        val client = backend { DownloadResolution("https://example.test/video", externalSubtitles = twoSubtitles.take(1)) }
        seedCompleting(downloadSubtitles = true, downloadArtwork = true)
        val downloader = FakeNativeDownloader()
        val manager = harness.manager({ _, _ -> client }, downloader, http = DmsHarness.httpClient { respond("supplementary bytes", HttpStatusCode.OK) })
        val log = manager.progressLog(backgroundScope)

        completeTask(manager, downloader)
        harness.idle()

        val steps = log.events.filter { it.status == DOWNLOADING }.map { it.currentFile }
        assertTrue(steps.containsAll(listOf("artwork", "subtitles")), steps.toString())
        assertTrue(harness.library.getPendingSupplementaryQueueItems().isEmpty())
    }

    @Test
    fun `a track downloads under its artist and title`() = runTest {
        harness = DmsHarness.create()
        val track = testMediaItem(
            "track-1", MediaKind.TRACK, "srv", title = "Song", parentId = "album-1", parentTitle = "Album",
            grandparentId = "artist-1", grandparentTitle = "Artist", index = 3,
        )
        harness.putPlexMetadata(
            "srv",
            "track-1",
            JsonObject(
                mapOf(
                    "ratingKey" to JsonPrimitive("track-1"),
                    "type" to JsonPrimitive("track"),
                    "title" to JsonPrimitive("Song"),
                    "parentRatingKey" to JsonPrimitive("album-1"),
                    "parentTitle" to JsonPrimitive("Album"),
                    "grandparentRatingKey" to JsonPrimitive("artist-1"),
                    "grandparentTitle" to JsonPrimitive("Artist"),
                    "index" to JsonPrimitive(3),
                ),
            ),
        )
        val client = SupplementaryBackend(track, { DownloadResolution("https://example.test/library/parts/9/file.flac") })
        val downloader = FakeNativeDownloader()
        val manager = harness.manager({ _, _ -> client }, downloader)

        manager.queueDownload(track, client, downloadSubtitles = false, downloadArtwork = false)

        assertEquals("Artist - Song", downloader.nextEnqueued().displayName)
    }
}
