package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ByteVar
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.get
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.usePinned
import kotlinx.coroutines.runBlocking
import platform.Foundation.NSData
import platform.Foundation.NSFileManager
import platform.Foundation.NSTemporaryDirectory
import platform.Foundation.NSUUID
import platform.Foundation.create
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
class AppleDatabaseFileTest {
    private val manager = NSFileManager.defaultManager
    private val dir = "${NSTemporaryDirectory().trimEnd('/')}/plezy-db-${NSUUID().UUIDString}"
    private val file = "$dir/$DATABASE_FILE_NAME"
    private val wal = "$file-wal"
    private val shm = "$file-shm"

    init {
        manager.createDirectoryAtPath(dir, withIntermediateDirectories = true, attributes = null, error = null)
    }

    @Test
    fun openRemovesOrphanedSidecarsWhenTheMainDatabaseIsAbsent() {
        // What a crashed first open or a restore without the database leaves: SQLite would read it into the new one.
        write(wal, 4096)
        write(shm, 32768)

        LocalData(DatabaseFactory(dir)).use { runBlocking { it.open() } }

        assertTrue(manager.fileExistsAtPath(file))
        // SQLite makes fresh sidecars of the new database; the orphans' bytes must not be among them.
        assertFalse(holdsOnly(wal, 0x5A), "the orphaned -wal was kept")
        assertFalse(holdsOnly(shm, 0x5A), "the orphaned -shm was kept")
    }

    @Test
    fun aFileDatabaseRunsInWalModeWithNormalSyncAndForeignKeysOn() {
        LocalData(DatabaseFactory(dir)).use { data ->
            runBlocking { data.open() }

            assertEquals("wal", pragma(data, "journal_mode").lowercase())
            assertEquals("1", pragma(data, "synchronous"), "NORMAL: a commit in WAL mode doesn't wait for the disk")
            assertEquals("1", pragma(data, "foreign_keys"))
        }
    }

    @AfterTest
    fun deleteDir() {
        manager.removeItemAtPath(dir, error = null)
    }

    private fun pragma(data: LocalData, name: String): String =
        data.driver.executeQuery(null, "PRAGMA $name", { cursor ->
            cursor.next()
            QueryResult.Value(cursor.getString(0) ?: cursor.getLong(0).toString())
        }, 0).value

    private fun write(path: String, bytes: Int) {
        val contents = ByteArray(bytes) { 0x5A }.usePinned { NSData.create(bytes = it.addressOf(0), length = bytes.toULong()) }
        manager.createFileAtPath(path, contents = contents, attributes = null)
    }

    private fun holdsOnly(path: String, byte: Byte): Boolean {
        val data = manager.contentsAtPath(path) ?: return false
        val length = data.length.toInt()
        if (length == 0) return false
        val bytes = data.bytes!!.reinterpret<ByteVar>()
        return (0 until length).all { bytes[it] == byte }
    }
}
