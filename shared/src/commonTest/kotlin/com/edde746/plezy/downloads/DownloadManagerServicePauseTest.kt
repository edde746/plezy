package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A pause the app didn't issue (the notification's Pause) ends where the app's own pause does. */
class DownloadManagerServicePauseTest {
    private lateinit var harness: DmsHarness
    private val key = "srv:item-1"
    private val task = downloadTask("task-a", key)

    @AfterTest
    fun close() = harness.close()

    /** A transfer under way: the row downloading with its task and its queue row, the task in the downloader. */
    private suspend fun downloading() {
        harness = DmsHarness.create()
        harness.data.insertDownload("srv", "item-1", status = DOWNLOADING)
        harness.library.updateBgTaskId(key, task.taskId)
        harness.library.addToQueue(key)
    }

    /** The downloader of the next process, which kept the task paused. */
    private fun pausedDownloader() = FakeNativeDownloader().apply {
        tasks = { listOf(task) }
        records = { listOf(TaskRecord(task, TaskStatus.PAUSED, 0.4, 1024)) }
    }

    private suspend fun assertPausedWithTask(downloader: FakeNativeDownloader) {
        val row = harness.library.getDownloadedMedia(key)!!
        assertEquals(PAUSED.code, row.status)
        assertEquals(task.taskId, row.bg_task_id, "the task keeps its resume data")
        assertTrue(harness.library.getQueue().isEmpty())
        assertTrue(downloader.cancelledIds.isEmpty())
    }

    @Test
    fun `a pause the downloader reports pauses the download and resumes its task after a restart`() = runTest {
        downloading()
        val first = FakeNativeDownloader().apply { holds(task) }
        val manager = harness.manager(downloader = first)
        harness.start(manager, first)

        harness.report(first, TaskStatusUpdate(task, TaskStatus.PAUSED))
        assertPausedWithTask(first)

        manager.dispose()
        val next = pausedDownloader()
        val resumed = mutableListOf<String>()
        next.resumeHandler = { resumed += it.taskId; true }
        val reopened = harness.manager(downloader = next)
        reopened.recoverInterruptedDownloads()
        assertPausedWithTask(next)

        reopened.resumeDownload(key, FakeMediaBackend("srv"))
        assertEquals(listOf(task.taskId), resumed)
        assertEquals(DOWNLOADING.code, harness.library.getDownloadedMedia(key)!!.status)
    }

    @Test
    fun `startup pauses a download whose task the downloader holds paused`() = runTest {
        downloading()
        val downloader = pausedDownloader()
        val manager = harness.manager(downloader = downloader)

        manager.recoverInterruptedDownloads()

        assertPausedWithTask(downloader)
    }

    @Test
    fun `the apps pause pauses the task in the downloader and cancels a duplicate`() = runTest {
        downloading()
        val duplicate = downloadTask("task-b", key)
        val paused = mutableListOf<String>()
        val downloader = FakeNativeDownloader().apply {
            tasks = { listOf(task, duplicate) }
            pauseHandler = { paused += it.taskId; true }
        }
        val manager = harness.manager(downloader = downloader)
        // A running app: the downloader was set up at startup.
        manager.recoverInterruptedDownloads()
        downloader.cancelledIds.clear()

        manager.pauseDownload(key)

        assertEquals(listOf(task.taskId), paused)
        assertEquals(listOf(duplicate.taskId), downloader.cancelledIds)
        val row = harness.library.getDownloadedMedia(key)!!
        assertEquals(PAUSED.code, row.status)
        assertEquals(task.taskId, row.bg_task_id)
        assertTrue(harness.library.getQueue().isEmpty())
    }

    @Test
    fun `a task the downloader cannot pause or no longer holds is cancelled and the download still pauses`() = runTest {
        for (holdsTask in listOf(true, false)) {
            downloading()
            val downloader = FakeNativeDownloader().apply {
                tasks = { if (holdsTask) listOf(task) else emptyList() }
                pauseHandler = { false }
            }
            val manager = harness.manager(downloader = downloader)

            manager.pauseDownload(key)

            assertEquals(listOf(task.taskId), downloader.cancelledIds, "holds task: $holdsTask")
            assertEquals(PAUSED.code, harness.library.getDownloadedMedia(key)!!.status)
            assertTrue(harness.library.getQueue().isEmpty())
            manager.dispose()
            if (holdsTask) harness.close()
        }
    }

    @Test
    fun `a task the downloader promotes while the pause runs is cancelled`() = runTest {
        downloading()
        val downloader = FakeNativeDownloader().apply {
            tasks = { listOf(task) }
            records = { listOf(TaskRecord(task, TaskStatus.RUNNING, 0.4, 1024)) }
        }
        val manager = harness.manager(downloader = downloader)
        manager.recoverInterruptedDownloads()
        downloader.cancelledIds.clear()
        downloader.pauseHandler = {
            harness.report(downloader, TaskStatusUpdate(task, TaskStatus.RUNNING))
            true
        }

        manager.pauseDownload(key)

        assertEquals(listOf(task.taskId), downloader.cancelledIds)
        assertEquals(PAUSED.code, harness.library.getDownloadedMedia(key)!!.status)
    }
}
