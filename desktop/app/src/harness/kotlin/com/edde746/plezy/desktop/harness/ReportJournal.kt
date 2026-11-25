package com.edde746.plezy.desktop.harness

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import java.io.OutputStream
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption.CREATE
import java.nio.file.StandardOpenOption.TRUNCATE_EXISTING
import java.nio.file.StandardOpenOption.WRITE

/**
 * The test report's journal ([TestReport], `report.jsonl`): one JSON record per line, in the order they were appended,
 * each handed to the OS as it is appended, so every record written is there however the process ends. A record is
 * compact JSON, which escapes the line breaks inside its strings, so a line is one whole record, and a last line
 * without its line break is one the process was cut off writing: the desktop test harness's readers ignore it.
 * Opening it replaces the file at [path].
 */
internal class ReportJournal(path: Path) : AutoCloseable {
    private val out: OutputStream = run {
        Files.createDirectories(path.toAbsolutePath().parent)
        Files.newOutputStream(path, CREATE, TRUNCATE_EXISTING, WRITE)
    }

    /** Writes [record] and its line break in one write, unbuffered. */
    @Synchronized fun append(record: JsonElement) {
        out.write((Json.encodeToString(JsonElement.serializer(), record) + "\n").encodeToByteArray())
    }

    @Synchronized override fun close() = out.close()
}
