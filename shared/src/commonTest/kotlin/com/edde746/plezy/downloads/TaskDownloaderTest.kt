package com.edde746.plezy.downloads

import com.edde746.plezy.data.isStorageFullMessage
import com.edde746.plezy.playback.resolve.headers
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import com.edde746.plezy.playback.resolve.lcgBytes
import kotlinx.coroutines.launch
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.write
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** The background downloader's rules over a scripted transport (and the real one over a mock server). */
class TaskDownloaderTest {
    private val bytes = lcgBytes(300_000, seed = 9)
    private val size = bytes.size.toLong()

    @Test
    fun oneTaskRunsAtATimeInTheOrderTheyWereEnqueued() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task("a", host = "one.example"))
        downloader.enqueue(task("b", host = "two.example"))
        downloader.enqueue(task("c", host = "one.example"))
        h.settle()

        assertEquals(listOf("a"), h.fakeTransport.started.map { it.id })
        assertEquals(listOf(TaskStatus.ENQUEUED, TaskStatus.RUNNING), h.callbacks.statusesOf("a"))
        assertEquals(listOf(TaskStatus.ENQUEUED), h.callbacks.statusesOf("b"))

        writePart(h.fakeTransport.started.last(), 10)
        h.fakeTransport.finish("a", TransferResult.Completed(10, null))
        h.settle()
        assertEquals(listOf("a", "b"), h.fakeTransport.started.map { it.id })

        writePart(h.fakeTransport.started.last(), 10)
        h.fakeTransport.finish("b", TransferResult.Completed(10, null))
        h.settle()
        assertEquals(listOf("a", "b", "c"), h.fakeTransport.started.map { it.id })
    }

    @Test
    fun aCompletedTaskLandsAtItsFilePathAndReportsComplete() = downloadsTest(fake = false) { h ->
        h.serveCdn(bytes)
        val downloader = h.start()
        val task = task()

        downloader.enqueue(task)
        h.settle()

        assertEquals(listOf(TaskStatus.ENQUEUED, TaskStatus.RUNNING, TaskStatus.COMPLETE), h.callbacks.statusesOf("film"))
        val file = Path(downloader.filePath(task))
        assertEquals(Path(h.root, "documents", "downloads", "film.mkv").toString(), file.toString())
        assertContentEquals(bytes, read(file))
        assertFalse(SystemFileSystem.exists(h.temp("film")))
        val record = downloader.allRecords().single()
        assertEquals(TaskStatus.COMPLETE, record.status)
        assertEquals(1.0, record.progress)
        assertEquals(size, record.expectedFileSize)
        assertTrue(downloader.allTasks().isEmpty())
        assertEquals("secret", h.transferRequests().single().headers["X-Plex-Token"])
    }

    @Test
    fun aFailedTransferIsRetriedResumingWithRangeUntilItsRetriesRunOut() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task(retries = 2))
        h.settle()
        val first = h.fakeTransport.started.single()
        writePart(first, 50_000)
        h.fakeTransport.listener?.onResponse("film", "\"e1\"")
        h.fakeTransport.progress("film", 50_000, size)
        h.settle()
        h.fakeTransport.finish("film", TransferResult.Network("Reset"))
        h.settle()

        assertEquals(TaskStatus.WAITING_TO_RETRY, h.callbacks.statuses.last().status)
        h.advance(1.seconds)
        assertEquals(1, h.fakeTransport.started.size, "the first retry waits 2 s")
        h.advance(1.seconds)
        val second = h.fakeTransport.started.last()
        assertEquals(2, h.fakeTransport.started.size)
        assertEquals(50_000L, second.offset)
        assertEquals("\"e1\"", second.validator)
        assertEquals(size, second.expectedSize)

        h.fakeTransport.finish("film", TransferResult.Http(503))
        h.advance(4.seconds)
        assertEquals(3, h.fakeTransport.started.size, "the second retry waits 4 s")
        h.fakeTransport.finish("film", TransferResult.Network("Reset"))
        h.advance(60.seconds)

        assertEquals(3, h.fakeTransport.started.size, "no retries left")
        val failed = h.callbacks.statuses.last()
        assertEquals(TaskStatus.FAILED, failed.status)
        assertIs<TaskException.Connection>(failed.exception)
        assertEquals(
            listOf(
                TaskStatus.ENQUEUED, TaskStatus.RUNNING, TaskStatus.WAITING_TO_RETRY, TaskStatus.ENQUEUED, TaskStatus.RUNNING,
                TaskStatus.WAITING_TO_RETRY, TaskStatus.ENQUEUED, TaskStatus.RUNNING, TaskStatus.FAILED,
            ),
            h.callbacks.statusesOf("film"),
        )
    }

    @Test
    fun aTransferThatNeverAnnouncedItsSizeStartsOverOnRetryAndReportsItsBytes() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task(retries = 1))
        h.settle()
        val first = h.fakeTransport.started.single()
        writePart(first, 50_000)
        // A server transcode streams without a length or byte ranges.
        h.fakeTransport.progress("film", 50_000, null)
        h.settle()
        assertEquals(50_000L, h.callbacks.progress.last().downloadedBytes)
        assertEquals(-1L, h.callbacks.progress.last().expectedFileSize)
        h.fakeTransport.finish("film", TransferResult.Network("Reset"))
        h.advance(2.seconds)

        val second = h.fakeTransport.started.last()
        assertEquals(2, h.fakeTransport.started.size)
        assertEquals(0L, second.offset)
    }

    @Test
    fun aRetryOverTheNetworkResumesTheFileWithRangeAndIfRange() = downloadsTest(fake = false) { h ->
        var answered = 0
        h.routes["cdn.example"] = { request ->
            // The first answer breaks off after a third of the file.
            if (answered++ == 0) {
                respond(
                    bytes.copyOf(100_000),
                    HttpStatusCode.PartialContent,
                    headers(HttpHeaders.ContentRange to "bytes 0-${size - 1}/$size", HttpHeaders.ETag to "\"v1\""),
                )
            } else {
                serveVideo(request, bytes)
            }
        }
        val downloader = h.start()
        val task = task()
        downloader.enqueue(task)
        h.settle()
        assertEquals(TaskStatus.WAITING_TO_RETRY, h.callbacks.statuses.last().status)

        h.advance(2.seconds)

        val resumed = h.transferRequests().last()
        assertEquals("bytes=100000-", resumed.headers[HttpHeaders.Range])
        assertEquals("\"v1\"", resumed.headers[HttpHeaders.IfRange])
        assertEquals(TaskStatus.COMPLETE, h.callbacks.statuses.last().status)
        assertContentEquals(bytes, read(Path(downloader.filePath(task))))
    }

    @Test
    fun pauseKeepsTheBytesAndResumeContinuesFromThem() = downloadsTest { h ->
        val downloader = h.start()
        val task = task()
        downloader.enqueue(task)
        h.settle()
        val first = h.fakeTransport.started.single()
        writePart(first, 120_000)
        h.fakeTransport.listener?.onResponse("film", "\"e1\"")
        h.fakeTransport.progress("film", 120_000, size)
        h.settle()

        assertTrue(downloader.pause(task))

        assertEquals(listOf("film"), h.fakeTransport.stopped)
        assertEquals(TaskStatus.PAUSED, h.callbacks.statuses.last().status)
        assertEquals(120_000L, SystemFileSystem.metadataOrNull(h.temp("film"))?.size)
        assertEquals(0.4, downloader.allRecords().single().progress)
        assertFalse(downloader.pause(task), "a paused task isn't running")

        assertTrue(downloader.resume(task))
        h.settle()

        val second = h.fakeTransport.started.last()
        assertEquals(2, h.fakeTransport.started.size)
        assertEquals(120_000L, second.offset)
        assertEquals("\"e1\"", second.validator)
        assertFalse(downloader.resume(task), "a running task isn't paused")
    }

    @Test
    fun aTaskThatDoesNotAllowPausingCantBePaused() = downloadsTest { h ->
        val downloader = h.start()
        val task = task(allowPause = false)
        downloader.enqueue(task)
        h.settle()

        assertFalse(downloader.pause(task))
        assertEquals(TaskStatus.RUNNING, h.callbacks.statuses.last().status)
    }

    @Test
    fun progressCountsTheBytesAlreadyThereOnce() = downloadsTest { h ->
        val downloader = h.start()
        val task = task()
        downloader.enqueue(task)
        h.settle()
        writePart(h.fakeTransport.started.single(), 150_000)
        h.fakeTransport.progress("film", 150_000, size)
        h.settle()
        downloader.pause(task)
        downloader.resume(task)
        h.settle()
        val resumed = h.fakeTransport.started.last()
        assertEquals(150_000L, resumed.offset)

        // A transport reports the bytes in place, the resume's offset included.
        h.fakeTransport.progress("film", 150_000, size)
        h.fakeTransport.progress("film", 225_000, size)
        h.settle()

        assertEquals(listOf(0.5, 0.5, 0.75), h.callbacks.progress.map { it.progress })
        assertTrue(h.callbacks.progress.all { it.expectedFileSize == size })
    }

    @Test
    fun theWifiPolicyOverridesTheTasksOwnFlagInBothDirections() = downloadsTest { h ->
        h.network(online = true, metered = true)
        val downloader = h.start()
        downloader.enqueue(task("cellular", requiresWiFi = false))
        h.settle()
        assertEquals(listOf("cellular"), h.fakeTransport.started.map { it.id })
        assertFalse(h.fakeTransport.started.single().wifiOnly)

        downloader.requireWiFi(RequireWiFi.FOR_ALL_TASKS)
        h.settle()

        assertEquals(listOf("cellular"), h.fakeTransport.stopped, "the running task waits for Wi-Fi")
        assertEquals(TaskStatus.ENQUEUED, h.callbacks.statuses.last().status)
        assertEquals(true to true, h.platform.active.last())
        assertTrue(downloader.waitingForNetwork())

        h.network(online = true, metered = false)
        assertEquals(2, h.fakeTransport.started.size, "an unmetered network (Wi-Fi, Ethernet, a VPN over them) lets it run")
        assertTrue(h.fakeTransport.started.last().wifiOnly)
        writePart(h.fakeTransport.started.last(), 10)
        h.fakeTransport.finish("cellular", TransferResult.Completed(10, null))
        h.settle()

        downloader.enqueue(task("wifi", requiresWiFi = true))
        h.settle()
        h.network(online = true, metered = true)
        assertEquals(listOf("cellular", "wifi"), h.fakeTransport.stopped)

        downloader.requireWiFi(RequireWiFi.FOR_NO_TASKS)
        h.settle()

        val last = h.fakeTransport.started.last()
        assertEquals("wifi", last.id, "a Wi-Fi-only task runs on a metered network once the policy says so")
        assertFalse(last.wifiOnly)
    }

    @Test
    fun theWifiPolicyOutlivesTheProcess() = downloadsTest { h ->
        h.network(online = true, metered = true)
        val first = h.start()
        first.requireWiFi(RequireWiFi.FOR_ALL_TASKS)
        first.enqueue(task(requiresWiFi = false))
        h.settle()
        assertTrue(h.fakeTransport.started.isEmpty())

        h.restart()

        assertTrue(h.fakeTransport.started.isEmpty(), "still waits for Wi-Fi")
    }

    @Test
    fun aTaskWaitsOfflineAndARunningOneGoesBackToTheQueueWhenTheNetworkGoes() = downloadsTest { h ->
        h.network(online = false)
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        assertTrue(h.fakeTransport.started.isEmpty())

        h.network(online = true)
        writePart(h.fakeTransport.started.single(), 1000)
        h.fakeTransport.progress("film", 1000, size)
        h.network(online = false)

        assertEquals(TaskStatus.ENQUEUED, h.callbacks.statuses.last().status)
        assertTrue(SystemFileSystem.exists(h.temp("film")))
        h.network(online = true)
        assertEquals(1000L, h.fakeTransport.started.last().offset)
        assertTrue(TaskStatus.CANCELED !in h.callbacks.statusesOf("film"))
    }

    @Test
    fun aTransferThePlatformStopsResumesInsteadOfReportingCanceled() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        writePart(h.fakeTransport.started.single(), 2000)
        h.fakeTransport.progress("film", 2000, size)
        h.settle()

        // Android's worker ending, or the system stopping it: the transport reports Stopped by itself.
        h.fakeTransport.finish("film", TransferResult.Stopped)
        h.settle()

        assertTrue(TaskStatus.CANCELED !in h.callbacks.statusesOf("film"))
        assertEquals(2, h.fakeTransport.started.size, "it runs again at once")
        assertEquals(2000L, h.fakeTransport.started.last().offset)
    }

    @Test
    fun aCancelFromTheNotificationReportsCanceled() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        writePart(h.fakeTransport.started.single(), 2000)

        // The notification's Cancel cancels the task the app didn't cancel.
        assertTrue(downloader.cancelTasksWithIds(listOf(downloader.runningTask()!!.taskId)))
        h.settle()

        assertEquals(TaskStatus.CANCELED, h.callbacks.statuses.last().status)
        assertFalse(SystemFileSystem.exists(h.temp("film")))
        assertEquals(1, h.fakeTransport.started.size, "not restarted")
        assertTrue(downloader.allTasks().isEmpty())
        assertEquals(TaskNotification.State.GONE, h.platform.notified.last().state)
    }

    @Test
    fun aCancelledQueuedOrPausedTaskReportsCanceled() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task("a", host = "one.example"))
        downloader.enqueue(task("b", host = "two.example"))
        h.settle()

        downloader.cancelTasksWithIds(listOf("b", "missing"))

        assertEquals(listOf(TaskStatus.ENQUEUED, TaskStatus.CANCELED), h.callbacks.statusesOf("b"))
        assertEquals(listOf("a"), downloader.allTasks().map { it.taskId })
    }

    @Test
    fun aTaskTheLastProcessLeftRunningIsRescheduledFromWhatItWrote() = downloadsTest { h ->
        val first = h.start()
        first.enqueue(task("a", host = "one.example"))
        h.settle()
        writePart(h.fakeTransport.started.single(), 40_000)
        h.fakeTransport.listener?.onResponse("a", "\"e\"")
        h.fakeTransport.progress("a", 40_000, size)
        h.settle()

        val next = h.restart()

        assertEquals(TaskStatus.RUNNING, next.allRecords().first { it.task.taskId == "a" }.status)
        assertTrue(h.fakeTransport.started.none { it.id == "a" }, "a killed task waits for its rescheduling")
        val (rescheduled, failed) = next.rescheduleKilledTasks()
        h.settle()

        assertEquals(listOf("a"), rescheduled.map { it.taskId })
        assertTrue(failed.isEmpty())
        val again = h.fakeTransport.started.first()
        assertEquals("a", again.id)
        assertEquals(40_000L, again.offset)
        assertEquals("\"e\"", again.validator)
        assertEquals(listOf(TaskStatus.ENQUEUED, TaskStatus.RUNNING), h.callbacks.statusesOf("a"))
    }

    @Test
    fun recordsSurviveARestart() = downloadsTest { h ->
        val first = h.start()
        first.enqueue(task("done", host = "one.example"))
        first.enqueue(task("paused", host = "two.example"))
        h.settle()
        writePart(h.fakeTransport.started.single(), 10)
        h.fakeTransport.finish("done", TransferResult.Completed(10, null))
        h.settle()
        writePart(h.fakeTransport.started.last(), 1000)
        h.fakeTransport.progress("paused", 1000, 4000)
        h.settle()
        first.pause(task("paused", host = "two.example"))

        val next = h.restart()

        val records = next.allRecords().associateBy { it.task.taskId }
        assertEquals(TaskStatus.COMPLETE, records.getValue("done").status)
        assertEquals(1.0, records.getValue("done").progress)
        assertEquals(task("done", host = "one.example").withoutCredentials(), records.getValue("done").task)
        assertEquals(TaskStatus.PAUSED, records.getValue("paused").status)
        assertEquals(0.25, records.getValue("paused").progress)
        assertEquals(listOf("paused"), next.allTasks().map { it.taskId })
        assertNull(next.taskForId("done"))

        assertTrue(next.resume(task("paused", host = "two.example")))
        h.settle()
        assertEquals(1000L, h.fakeTransport.started.single().offset)

        next.deleteRecord("done")
        assertEquals(listOf("paused"), h.restart().allRecords().map { it.task.taskId })
    }

    @Test
    fun aVolumeTooFullRefusesTheTaskWithAStorageFullMessage() = downloadsTest { h ->
        val downloader = h.start()
        // 300 MiB free of 1 TiB: below the floor of 1 %.
        h.platform.capacity = VolumeCapacity(available = 300L shl 20, total = 1L shl 40)

        downloader.enqueue(task(retries = 5))
        h.settle()

        assertTrue(h.fakeTransport.started.isEmpty())
        val refused = h.callbacks.statuses.last()
        assertEquals(TaskStatus.FAILED, refused.status)
        assertIs<TaskException.FileSystem>(refused.exception)
        assertTrue(isStorageFullMessage(refused.exception?.description))
        assertTrue(TaskStatus.WAITING_TO_RETRY !in h.callbacks.statusesOf("film"), "no retry refills the volume")
    }

    @Test
    fun aTransferTheVolumeFillsUpDuringDeletesItsPartAndIsNotRetried() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task(retries = 5))
        h.settle()
        writePart(h.fakeTransport.started.single(), 5000)

        h.fakeTransport.finish("film", TransferResult.DiskFull)
        h.settle()

        assertEquals(TaskStatus.FAILED, h.callbacks.statuses.last().status)
        assertTrue(isStorageFullMessage(h.callbacks.statuses.last().exception?.description))
        assertFalse(SystemFileSystem.exists(h.temp("film")))
        h.advance(60.seconds)
        assertEquals(1, h.fakeTransport.started.size)
    }

    @Test
    fun aFailedWriteOnAFullVolumeIsAStorageRefusal() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        h.platform.capacity = VolumeCapacity(available = 0, total = 1L shl 40)

        h.fakeTransport.finish("film", TransferResult.WriteFailed)
        h.settle()

        assertTrue(isStorageFullMessage(h.callbacks.statuses.last().exception?.description))
    }

    @Test
    fun aKnownSizeLargerThanTheRoomLeftIsRefusedBeforeItTransfers() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        h.fakeTransport.progress("film", 0, 900L shl 20)
        h.fakeTransport.finish("film", TransferResult.Network("Reset"))
        h.settle()
        // 1 GiB free of 10 GiB: room for the floor (256 MiB) but not for 900 MiB more.
        h.platform.capacity = VolumeCapacity(available = 1L shl 30, total = 10L shl 30)

        h.advance(2.seconds)

        assertEquals(1, h.fakeTransport.started.size)
        assertTrue(isStorageFullMessage(h.callbacks.statuses.last().exception?.description))
    }

    @Test
    fun aMissingFileIsNotFoundWithoutRetries() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task(retries = 5))
        h.settle()

        h.fakeTransport.finish("film", TransferResult.Http(404))
        h.settle()

        val update = h.callbacks.statuses.last()
        assertEquals(TaskStatus.NOT_FOUND, update.status)
        assertEquals(404, update.responseStatusCode)
        h.advance(60.seconds)
        assertEquals(1, h.fakeTransport.started.size)
    }

    @Test
    fun resumeFromBackgroundReattachesTheTransfersThePlatformStillRuns() = downloadsTest { h ->
        val first = h.start()
        first.enqueue(task())
        h.settle()

        h.restart(configure = false)
        h.fakeTransport.stillRunning = setOf("film")
        h.downloader.configure(h.callbacks, NOTIFICATIONS)
        h.downloader.resumeFromBackground()
        h.settle()

        assertTrue(h.fakeTransport.started.isEmpty(), "not started again")
        val (rescheduled, _) = h.downloader.rescheduleKilledTasks()
        assertTrue(rescheduled.isEmpty())
        SystemFileSystem.createDirectories(Path(h.platform.tempDirectory))
        SystemFileSystem.sink(h.temp("film")).buffered().use { it.write(ByteArray(10)) }
        h.fakeTransport.finish("film", TransferResult.Completed(10, null))
        h.settle()

        assertEquals(TaskStatus.COMPLETE, h.callbacks.statuses.last().status)
    }

    @Test
    fun aResetWhileTheTransportIsAskedStopsTheTransferItStillRuns() = downloadsTest { h ->
        h.start().enqueue(task())
        h.settle()

        h.restart(configure = false)
        h.fakeTransport.stillRunning = setOf("film")
        h.fakeTransport.holdReattach = true
        h.downloader.configure(h.callbacks, NOTIFICATIONS)
        val resumed = launch { h.downloader.resumeFromBackground() }
        h.settle()
        assertEquals(1, h.downloader.reset())
        h.fakeTransport.releaseReattach()
        h.settle()
        resumed.join()

        assertEquals(listOf("film"), h.fakeTransport.stopped)
        assertTrue(h.fakeTransport.started.isEmpty())
    }

    @Test
    fun cleaningUpDeletesOnlyTheTemporaryFilesNoTaskOwns() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        writePart(h.fakeTransport.started.single(), 100)
        val orphan = Path(h.platform.tempDirectory, "gone.part")
        SystemFileSystem.sink(orphan).buffered().use { it.write(ByteArray(10)) }

        assertEquals(1, downloader.cleanUpOrphanedTempFiles())

        assertFalse(SystemFileSystem.exists(orphan))
        assertTrue(SystemFileSystem.exists(h.temp("film")))
    }

    @Test
    fun resetCancelsEveryTaskAndDeletesEveryRecord() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task("a", host = "one.example"))
        downloader.enqueue(task("b", host = "two.example"))
        h.settle()
        writePart(h.fakeTransport.started.single(), 100)

        assertEquals(2, downloader.reset())

        assertTrue(downloader.allRecords().isEmpty())
        assertFalse(SystemFileSystem.exists(h.temp("a")))
        assertEquals(TaskStatus.CANCELED, h.callbacks.statusesOf("a").last())
        assertTrue(h.restart().allRecords().isEmpty())
    }

    @Test
    fun aTaskIdUnderWayCantBeEnqueuedTwiceNorANonHttpUrl() = downloadsTest { h ->
        val downloader = h.start()
        assertTrue(downloader.enqueue(task()))
        assertFalse(downloader.enqueue(task()))
        assertFalse(downloader.enqueue(task("file").copy(url = "file:///etc/passwd")))
    }

    @Test
    fun notificationsShowTheRunningTaskWithItsProgressThenItsEnd() = downloadsTest { h ->
        val downloader = h.start()
        downloader.enqueue(task())
        h.settle()
        h.fakeTransport.progress("film", 150_000, size)
        h.settle()

        val running = h.platform.notified.last()
        assertEquals(TaskNotification.State.RUNNING, running.state)
        assertEquals("Film film", running.title)
        assertEquals(0.5, running.progress)

        writePart(h.fakeTransport.started.single(), size)
        h.fakeTransport.finish("film", TransferResult.Completed(size, null))
        h.settle()
        assertEquals(TaskNotification.State.COMPLETE, h.platform.notified.last().state)
        assertEquals("Download complete", h.platform.notified.last().body)
    }

    @Test
    fun aRootTaskKeepsItsAbsoluteDirectory() = downloadsTest { h ->
        val downloader = h.start()
        val task = task().copy(baseDirectory = BaseDirectory.ROOT, directory = "/media/card/Plezy")

        assertEquals(LocalPath.join("/media/card/Plezy", "film.mkv"), downloader.filePath(task))
        assertEquals("/", downloader.baseDirectoryPath(BaseDirectory.ROOT))
    }
}
