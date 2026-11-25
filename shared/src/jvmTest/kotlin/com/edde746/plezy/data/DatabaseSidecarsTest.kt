package com.edde746.plezy.data

import kotlinx.coroutines.runBlocking
import kotlinx.io.files.Path
import java.nio.file.Files
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DatabaseSidecarsTest {
    private val dir = Files.createTempDirectory("plezy-sidecars")
    private val file = dir.resolve(DATABASE_FILE_NAME)
    private val wal = dir.resolve("$DATABASE_FILE_NAME-wal")
    private val shm = dir.resolve("$DATABASE_FILE_NAME-shm")

    @Test
    fun openRemovesOrphanedSidecarsWhenTheMainDatabaseIsAbsent() {
        // What a crashed first open or a restore without the database leaves: SQLite would read it into the new one.
        Files.write(wal, ByteArray(4096) { 0x5A })
        Files.write(shm, ByteArray(32768) { 0x5A })

        LocalData(DatabaseFactory(file)).use { runBlocking { it.open() } }

        assertTrue(Files.exists(file))
        assertFalse(Files.exists(wal) && Files.size(wal) == 4096L, "the orphaned -wal was kept")
        assertFalse(Files.exists(shm) && Files.size(shm) == 32768L, "the orphaned -shm was kept")
    }

    @Test
    fun theSidecarsOfAnExistingDatabaseAreKept() {
        Files.write(file, byteArrayOf(0))
        Files.write(wal, byteArrayOf(1))
        Files.write(shm, byteArrayOf(2))

        removeOrphanedSidecars(Path(file.toString()))

        assertEquals(listOf<Byte>(1), Files.readAllBytes(wal).toList())
        assertEquals(listOf<Byte>(2), Files.readAllBytes(shm).toList())
    }

    @Test
    fun aMissingDatabaseLosesOnlyItsOwnSidecars() {
        val other = Files.write(dir.resolve("other.db-wal"), byteArrayOf(3))
        Files.write(wal, byteArrayOf(1))

        removeOrphanedSidecars(Path(file.toString()))

        assertFalse(Files.exists(wal))
        assertTrue(Files.exists(other))
    }

    @AfterTest
    fun deleteDir() {
        dir.toFile().deleteRecursively()
    }
}
