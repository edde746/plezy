@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.app

import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupFailures
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.StoredTask
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.testData as dataOnDefaultDispatcher
import com.edde746.plezy.downloads.TaskStatus
import com.edde746.plezy.downloads.insertDownload
import com.edde746.plezy.downloads.task
import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class AppBootstrapTest {
    private val originalSink = Log.sink

    @AfterTest
    fun restore() {
        Log.sink = originalSink
        Log.minLevel = Log.Level.INFO
        Dispatchers.resetMain()
    }

    /** A development session (a process of its own) logs at the level the Debug logging setting asks for, as the product does. */
    @Test
    fun aDevelopmentSessionFollowsTheDebugLoggingSetting() = runTest {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        AppBootstrap.local(inMemoryDatabase(), BuildFlavor.SIDELOADED, "test").use { boot ->
            suspend fun levelBecomes(level: Log.Level) =
                withContext(Dispatchers.Default) { withTimeout(10.seconds) { while (Log.minLevel != level) delay(5) } }
            Log.minLevel = Log.Level.WARN
            levelBecomes(Log.Level.INFO)
            boot.graph.data.deviceSettings.set(AppSettings.enableDebugLogging, true)
            levelBecomes(Log.Level.DEBUG)
            boot.graph.data.deviceSettings.set(AppSettings.enableDebugLogging, false)
            levelBecomes(Log.Level.INFO)
        }
    }

    @Test
    fun aStoresCoroutineThatThrowsIsLoggedAndTheProductRunsOn() = runTest {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        // The system's settings, as a platform reports them before it builds a core.
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        val errors = mutableListOf<String>()
        Log.sink = Log.Sink { level, _, _, error -> if (level == Log.Level.ERROR && error != null) errors += error }
        AppBootstrap.product(inMemoryDatabase(), MemorySecretStore(), BuildFlavor.SIDELOADED, "test", Startup()).use { boot ->
            val app = boot.graph.scope
            // A store's scope, as every store builds it from the graph's.
            val store = app.childScope()
            store.launch { throw IllegalStateException("a store's work failed") }
            runCurrent()

            var ranAfter = false
            store.launch { ranAfter = true }
            runCurrent()

            assertTrue(errors.any { "a store's work failed" in it }, errors.joinToString("\n"))
            assertTrue(ranAfter, "the store's next coroutine runs")
            assertTrue(app.isActive, "the app's scope goes on")
        }
    }

    @Test
    fun aDatabaseThatCantOpenOnAFullDiskOpensAfterThePartialDownloadsAreDiscarded() = runTest {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        val temp = Path(SystemTemporaryDirectory, "plezy-download-tasks-${Random.nextLong().toULong()}")
        SystemFileSystem.createDirectories(temp)
        val partial = Path(temp, "film.part")
        SystemFileSystem.sink(partial).buffered().use { it.write(ByteArray(1024)) }
        // Its I/O on the default dispatcher: the product's open blocks the test's thread, which runs the test dispatcher.
        val data = dataOnDefaultDispatcher()
        data.insertDownload("srv", "running", status = DownloadedMediaStatus.DOWNLOADING)
        data.insertDownload("srv", "done", status = DownloadedMediaStatus.COMPLETED)
        data.downloadTasks.save(StoredTask(task(), TaskStatus.RUNNING, 0.4, 2048, null, 5, null, null, 1))
        val events = mutableListOf<String>()

        val boot = AppBootstrap.product(
            SystemTemporaryDirectory.toString(), MemorySecretStore(), BuildFlavor.SIDELOADED, "test", development = false,
            earlierRelease = null, downloadTempDirectory = temp.toString(),
        ) {
            events += if (SystemFileSystem.exists(partial)) "open with the partial file" else "open after discarding it"
            if (events.size == 1) throw IOException("disk I/O error: database or disk is full (code 13 SQLITE_FULL)")
            data
        }

        boot.use {
            assertEquals(listOf("open with the partial file", "open after discarding it"), events)
            assertTrue(SystemFileSystem.list(temp).isEmpty(), "the downloader's partial files are gone")
            assertTrue(data.downloadTasks.all().isEmpty(), "the downloader's tasks are forgotten")
            val running = data.downloadLibrary.getDownloadedMedia("srv:running")!!
            assertEquals(DownloadedMediaStatus.FAILED.code, running.status)
            assertEquals(T.downloads.storageFull, running.error_message)
            assertEquals(DownloadedMediaStatus.COMPLETED.code, data.downloadLibrary.getDownloadedMedia("srv:done")!!.status)
        }
        SystemFileSystem.delete(temp)
    }

    @Test
    fun aDatabaseThatCantOpenFailsTheStartNamingItsPhaseAndKeepsTheRecordForTheNextStart() = runTest {
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        val directory = Path(SystemTemporaryDirectory, "plezy-start-${Random.nextLong().toULong()}").toString()
        val failure = assertFailsWith<StartupFailedException> {
            AppBootstrap.product(
                directory, MemorySecretStore(), BuildFlavor.SIDELOADED, "test", development = false,
                earlierRelease = null, downloadTempDirectory = null,
            ) { throw IllegalStateException("file is not a database") }
        }
        assertEquals(StartupPhase.DATABASE, failure.record.phase)
        assertEquals("[database] IllegalStateException: file is not a database", failure.record.headline)
        assertEquals(failure.record.id, StartupFailures(directory).peek()?.id)
    }
}
