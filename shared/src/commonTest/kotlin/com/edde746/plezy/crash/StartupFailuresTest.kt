package com.edde746.plezy.crash

import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.writeString
import kotlinx.serialization.SerializationException
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

class StartupFailuresTest {
    private val directory = Path(SystemTemporaryDirectory, "startup-failures-${Random.nextLong().toULong()}").toString()
    private val store = StartupFailures(directory)
    private val file = Path(directory, StartupFailures.FILE_NAME)

    private fun record(message: String = "boom", at: String = "2026-11-07T10:00:00Z") = StartupFailureRecord.of(
        StartupPhaseException(StartupPhase.DATABASE, IllegalStateException(message)),
        appVersion = "2.26.0+160 (abc1234)",
        platform = "macos 15.1",
        at = Instant.parse(at),
    )

    @Test
    fun `a record keeps the real error and the wrappers phase`() {
        val failure = record()
        assertEquals(StartupPhase.DATABASE, failure.phase)
        assertEquals("IllegalStateException", failure.errorType)
        assertEquals("boom", failure.message)
        assertEquals("[database] IllegalStateException: boom", failure.headline)
        assertFalse(failure.reported)
    }

    @Test
    fun `a JSON decoding error loses the document it quotes but keeps its message`() {
        val error = SerializationException("Unexpected JSON token at offset 12: Expected quotation mark\nJSON input: {\"plex_token\":\"tok-secret-value\"}")
        val failure = StartupFailureRecord.of(error, "v", "p")
        assertEquals("Unexpected JSON token at offset 12: Expected quotation mark", failure.message)
        assertFalse("tok-secret-value" in failure.message + failure.stackTrace)
    }

    @Test
    fun `message and stack trace are redacted`() {
        val failure = record("open failed for http://192.168.1.20:32400/library?X-Plex-Token=abcdef")
        assertFalse("abcdef" in failure.message + failure.stackTrace)
        assertFalse("192.168.1.20" in failure.message + failure.stackTrace)
    }

    @Test
    fun `describe lists every allowlisted field`() {
        val text = record().describe()
        val expected = listOf(
            "Plezy startup failure", "Version: 2.26.0+160 (abc1234)", "Platform: macos 15.1", "When: 2026-11-07T10:00:00Z",
            "Phase: database", "Error: IllegalStateException", "Message: boom", "Stack trace:",
        )
        assertEquals(expected, text.lines().take(expected.size))
    }

    @Test
    fun `a record survives its JSON and an unreadable one is none`() {
        val failure = record().copy(reported = true)
        assertEquals(failure, StartupFailureRecord.fromJson(failure.toJson()))
        assertNull(StartupFailureRecord.fromJson("""{"errorType":"X"}"""))
        assertNull(StartupFailureRecord.fromJson("not json"))
    }

    @Test
    fun `an unreported record is sent once and kept until the next start reads it`() = runTest {
        val failure = record()
        store.record(failure)
        val sent = mutableListOf<CrashReport>()
        store.flush(optedIn = true, canEverReport = true) { sent += it.report(); true }
        store.flush(optedIn = true, canEverReport = true) { sent += it.report(); true }
        assertEquals(1, sent.size)
        assertEquals("Startup failed: [database] IllegalStateException: boom", sent.single().message)
        assertEquals(CrashReport.Level.FATAL, sent.single().level)
        assertEquals("database", sent.single().tags["startup.phase"])
        assertEquals(true, StartupFailures(directory).peek()?.reported)
    }

    @Test
    fun `a report the reporter did not take stays unreported for the next start`() = runTest {
        store.record(record())
        store.flush(optedIn = true, canEverReport = true) { false }
        assertEquals(false, store.peek()?.reported)
        store.flush(optedIn = true, canEverReport = true, send = null)
        assertEquals(false, store.peek()?.reported)
    }

    @Test
    fun `reports off or a build without them mark the record reported unsent`() = runTest {
        for ((optedIn, canReport) in listOf(false to true, true to false)) {
            store.record(record())
            var sent = false
            store.flush(optedIn, canReport) { sent = true; true }
            assertFalse(sent)
            assertEquals(true, store.peek()?.reported)
        }
    }

    @Test
    fun `marking reported never overwrites a newer failure`() = runTest {
        val first = record("first")
        store.record(first)
        val peeked = store.peek()!!
        val second = record("second", at = "2026-11-07T10:00:05Z")
        store.record(second)
        store.markReported(peeked)
        val onDisk = store.peek()!!
        assertEquals(second.id, onDisk.id)
        assertFalse(onDisk.reported)
    }

    @Test
    fun `consuming a reported record deletes it and shows it`() = runTest {
        store.record(record())
        store.markReported(store.peek()!!)
        val reader = StartupFailures(directory)
        val consumed = reader.consumePrevious()
        assertEquals(true, consumed?.reported)
        assertEquals(consumed, reader.pending)
        assertFalse(SystemFileSystem.exists(file))
    }

    @Test
    fun `consuming an unreported record keeps it on disk`() = runTest {
        store.record(record())
        val reader = StartupFailures(directory)
        assertEquals(false, reader.consumePrevious()?.reported)
        assertTrue(SystemFileSystem.exists(file))
    }

    @Test
    fun `an unreadable record is deleted`() = runTest {
        SystemFileSystem.createDirectories(Path(directory))
        SystemFileSystem.sink(file).buffered().use { it.writeString("{broken") }
        assertNull(store.consumePrevious())
        assertFalse(SystemFileSystem.exists(file))
    }

    @Test
    fun `clearing forgets the record in memory and on disk`() = runTest {
        store.record(record())
        store.clear()
        assertNull(store.pending)
        assertNull(store.peek())
    }
}
