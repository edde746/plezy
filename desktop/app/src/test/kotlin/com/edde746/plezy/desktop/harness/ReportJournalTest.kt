package com.edde746.plezy.desktop.harness

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createTempDirectory
import kotlin.io.path.writeBytes
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

class ReportJournalTest {
    private val dir = createTempDirectory("journal")
    private val path: Path = dir.resolve("report.jsonl")

    @AfterTest
    fun cleanUp() {
        dir.toFile().deleteRecursively()
    }

    /** A record whose strings hold what a log line or a title may: line breaks, quotes, a character beyond ASCII. */
    private fun record(n: Int): JsonElement = buildJsonObject {
        put("event", buildJsonObject {
            put("n", n)
            put("message", "line one\nline \"two\"\r\nüber 🎬\u2028")
        })
    }

    /**
     * The journal as the desktop test harness's readers read it: the bytes up to the last
     * line break, one JSON record per line; what follows the last line break is a record cut short, left out.
     */
    private fun readLines(): List<JsonElement> {
        val bytes = Files.readAllBytes(path)
        val whole = bytes.decodeToString(0, bytes.lastIndexOf('\n'.code.toByte()) + 1)
        return whole.split('\n').dropLast(1).map { Json.parseToJsonElement(it) }
    }

    @Test
    fun eachRecordIsOneLineInTheOrderAppendedWhileTheJournalIsOpen() {
        val journal = ReportJournal(path)
        val written = (1..3).map(::record)
        written.forEach(journal::append)
        // Each record is in the file as soon as it is appended: a reader polling the running app sees it.
        assertEquals(written, readLines())
        journal.append(record(4))
        assertEquals(written + record(4), readLines())
        journal.close()
    }

    @Test
    fun aCutRecordIsLeftOutAndEveryOneBeforeItParses() {
        ReportJournal(path).use { journal -> (1..3).forEach { journal.append(record(it)) } }
        val bytes = Files.readAllBytes(path)
        val thirdStart = bytes.indices.filter { bytes[it] == '\n'.code.toByte() }[1] + 1
        // The process ended while writing the third: every cut inside it, the ones inside "ü" and "🎬" included, and
        // the one before its line break.
        for (cut in thirdStart until bytes.size) {
            path.writeBytes(bytes.copyOf(cut))
            assertEquals(listOf(record(1), record(2)), readLines(), "cut at byte $cut of ${bytes.size}")
        }
        path.writeBytes(bytes)
        assertEquals((1..3).map(::record), readLines())
    }

    @Test
    fun anEarlierRunsJournalIsReplaced() {
        ReportJournal(path).use { it.append(record(1)) }
        ReportJournal(path).use { it.append(JsonPrimitive("second run")) }
        assertEquals(listOf<JsonElement>(JsonPrimitive("second run")), readLines())
    }
}
