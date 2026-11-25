package com.edde746.plezy.desktop

import java.io.File
import java.io.RandomAccessFile
import java.nio.file.Files
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class FileChoosersTest {
    private val file: File = Files.createTempFile("opened", ".json").toFile()

    @AfterTest
    fun delete() {
        file.delete()
    }

    /** A file picked by mistake (a video) is refused as unreadable, before it is read whole. */
    @Test
    fun aFileOverTheLimitIsUnreadable() {
        RandomAccessFile(file, "rw").use { it.setLength(MAX_OPENED_BYTES + 1L) }
        assertNull(readText(file))
    }

    @Test
    fun aFileAtTheLimitIsRead() {
        RandomAccessFile(file, "rw").use { it.setLength(MAX_OPENED_BYTES.toLong()) }
        assertEquals(MAX_OPENED_BYTES, readText(file)?.length)
    }
}
