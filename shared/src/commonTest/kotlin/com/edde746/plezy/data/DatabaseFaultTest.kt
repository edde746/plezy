package com.edde746.plezy.data

import app.cash.sqldelight.db.AfterVersion
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.runBlocking
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.writeString
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant

/**
 * The start finds saved data it can't use and fails at the database with the fault the startup failure screen offers
 * to reset ([StartupFailureRecord.dataFault]); the reset moves the database aside, deletes the secrets and the app's own
 * downloads, and the next open is a first run.
 */
class DatabaseFaultTest {
    private val databases = mutableListOf<FileDatabase>()
    private val scratch = Path(SystemTemporaryDirectory, "plezy-reset-${Random.nextLong().toULong()}")

    @AfterTest
    fun deleteFiles() {
        databases.forEach(FileDatabase::delete)
        deleteTree(scratch)
    }

    @Test
    fun aFileThatIsNoDatabaseFailsTheStartAsUnreadable() {
        val db = database()
        SystemFileSystem.sink(db.file).buffered().use { it.writeString("not a database ".repeat(400)) }

        val failure = startFailure(db)

        assertEquals(StartupPhase.DATABASE, failure.phase)
        assertEquals(DataFault.UNREADABLE, failure.dataFault)
    }

    @Test
    fun aDatabaseMissingAColumnOfThisVersionFailsTheStartAsUnreadable() {
        val db = database()
        withDriver(db) { it.execute(null, "ALTER TABLE downloaded_media DROP COLUMN transcode_quality", 0) }

        val failure = startFailure(db)

        assertEquals(DataFault.UNREADABLE, failure.dataFault)
        assertEquals("DatabaseUnreadableException", failure.errorType)
        assertTrue("table downloaded_media differs" in failure.message, failure.message)
    }

    @Test
    fun aDatabaseWithAnIndexOfAnEarlierBuildFailsTheStartAsUnreadable() {
        val db = database()
        withDriver(db) { it.execute(null, "CREATE INDEX idx_left_behind ON api_cache(pinned)", 0) }

        assertTrue("index idx_left_behind unexpected" in startFailure(db).message)
    }

    @Test
    fun aFreshDatabaseAndTheSameOneReopenedPassTheSchemaCheck() = runBlocking {
        val db = database()
        LocalData(db.factory).use { it.open() }
        LocalData(db.factory).use { it.open() }
    }

    @Test
    fun aFailedMigrationIsUnreadableButAFullDiskIsNot() {
        val failing = assertFailsWith<DatabaseUnreadableException> {
            ReportingSchema(FailingMigration(IllegalStateException("no such table: gone")), {}).migrate(NoDatabase(), 1, 2)
        }
        assertEquals(DataFault.UNREADABLE, record(failing).dataFault)

        val full = assertFailsWith<IllegalStateException> {
            ReportingSchema(FailingMigration(IllegalStateException("[SQLITE_FULL] database or disk is full")), {}).migrate(NoDatabase(), 1, 2)
        }
        assertNull(record(full).dataFault, "a full disk is recovered from, not reset")
    }

    @Test
    fun sqliteWordsForADamagedFileAreUnreadableAndOtherFailuresAreNot() {
        for (text in listOf("file is not a database (code 26 SQLITE_NOTADB)", "[SQLITE_CORRUPT] database disk image is malformed", "disk I/O error (code 10)")) {
            assertEquals(DataFault.UNREADABLE, DataFault.of(unreadableOrItself(RuntimeException(text))), text)
        }
        for (text in listOf("[SQLITE_BUSY] database is locked", "[SQLITE_FULL] database or disk is full")) {
            assertNull(DataFault.of(unreadableOrItself(RuntimeException(text))), text)
        }
        assertEquals(DataFault.NEWER, DataFault.of(RuntimeException(DatabaseNewerThanAppException(2, 1))))
    }

    @Test
    fun aRecordKeepsItsDataFaultThroughTheNextStart() {
        val record = record(DatabaseUnreadableException("damaged"))
        assertEquals(DataFault.UNREADABLE, StartupFailureRecord.fromJson(record.toJson())?.dataFault)
    }

    @Test
    fun theResetMovesTheDatabaseAsideDeletesTheSecretsAndTheAppsDownloadsAndTheNextOpenIsAFirstRun() = runBlocking {
        val db = database()
        withDriver(db) {
            it.execute(null, "INSERT INTO connections (id, kind, config_json, created_at) VALUES ('c', 'jellyfin', '{}', 1)", 0)
            it.execute(null, "ALTER TABLE downloaded_media DROP COLUMN transcode_quality", 0)
        }
        val dir = db.file.parent!!
        val earlierCopy = Path(dir, "${db.file.name}.unreadable-1")
        write(earlierCopy)
        val secrets = MemorySecretStore().apply {
            put("connection.c", byteArrayOf(1))
            put("tracker.trakt", byteArrayOf(2))
        }
        val base = Path(scratch, "base")
        write(Path(base, "downloads", "server", "movie.mkv"))
        write(Path(base, "artwork", "poster.jpg"))
        write(Path(base, "plezy_downloads.db"))
        val temp = Path(scratch, "temp")
        write(Path(temp, "partial"))

        DataReset(db.factory, secrets, DownloadStoragePlatform(BaseDirectory.APPLICATION_SUPPORT, { base.toString() }, supportsSaf = false), temp.toString())
            .apply { now = { Instant.fromEpochMilliseconds(42) } }
            .reset()

        assertFalse(SystemFileSystem.exists(db.file), "the database was left in place")
        val aside = Path(dir, "${db.file.name}.unreadable-42")
        assertTrue(SystemFileSystem.exists(aside), "the database wasn't moved aside")
        assertFalse(SystemFileSystem.exists(earlierCopy), "an earlier copy was kept")
        assertTrue(secrets.entries.isEmpty(), "secrets left: ${secrets.entries.keys}")
        assertFalse(SystemFileSystem.exists(Path(base, "downloads")))
        assertFalse(SystemFileSystem.exists(Path(base, "artwork")))
        assertTrue(SystemFileSystem.exists(Path(base, "plezy_downloads.db")), "a file outside the download folders went")
        assertTrue(SystemFileSystem.list(temp).isEmpty(), "partial downloads left")

        LocalData(db.factory).use { data ->
            data.open()
            assertTrue(data.db.read { connectionQueries.selectAll().executeAsList() }.isEmpty(), "the reset database still has connections")
        }
        // The copy moved aside is the database as it was.
        assertEquals(1L, storedSchemaVersion(aside))
    }

    @Test
    fun aDatabaseALaterReleaseWroteFailsTheStartAsNewer() {
        val db = database()
        withDriver(db) { it.execute(null, "PRAGMA user_version = ${PlezyDatabase.Schema.version + 1}", 0) }

        assertEquals(DataFault.NEWER, startFailure(db).dataFault)
    }

    private fun database(): FileDatabase = fileDatabase().also { databases += it }

    /** Creates [db] at this version's schema, runs [block] on its driver and closes it. */
    private fun withDriver(db: FileDatabase, block: (SqlDriver) -> Unit) {
        val driver = db.factory.createDriver(PlezyDatabase.Schema)
        try {
            userVersion(driver)
            block(driver)
        } finally {
            driver.close()
        }
    }

    /** The record of the start that opens [db] as every platform does (Android's in RootSession, where it's the same). */
    private fun startFailure(db: FileDatabase): StartupFailureRecord {
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        val directory = Path(scratch, "files").toString()
        return assertFailsWith<StartupFailedException> {
            AppBootstrap.product(
                directory, MemorySecretStore(), BuildFlavor.SIDELOADED, "test", development = false,
                earlierRelease = null, downloadTempDirectory = null,
            ) {
                val data = LocalData(db.factory)
                try {
                    data.open()
                } catch (e: Exception) {
                    data.close()
                    throw e
                }
                data
            }
        }.record
    }

    private fun record(error: Throwable) = StartupFailureRecord.of(error, "test", "test", StartupPhase.DATABASE)

    private fun write(path: Path) {
        path.parent?.let { SystemFileSystem.createDirectories(it) }
        SystemFileSystem.sink(path).buffered().use { it.writeString("x") }
    }

    private fun deleteTree(path: Path) {
        val metadata = SystemFileSystem.metadataOrNull(path) ?: return
        if (metadata.isDirectory) SystemFileSystem.list(path).forEach(::deleteTree)
        SystemFileSystem.delete(path, mustExist = false)
    }

    /** This version's schema, whose migration fails with [error]. */
    private class FailingMigration(private val error: Exception) : SqlSchema<QueryResult.Value<Unit>> by PlezyDatabase.Schema {
        override fun migrate(driver: SqlDriver, oldVersion: Long, newVersion: Long, vararg callbacks: AfterVersion): QueryResult.Value<Unit> =
            throw error
    }
}

/** A driver for a migration that fails before it reaches the database. */
private class NoDatabase : SqlDriver {
    override fun <R> executeQuery(
        identifier: Int?,
        sql: String,
        mapper: (app.cash.sqldelight.db.SqlCursor) -> QueryResult<R>,
        parameters: Int,
        binders: (app.cash.sqldelight.db.SqlPreparedStatement.() -> Unit)?,
    ): QueryResult<R> = error("no database")

    override fun execute(identifier: Int?, sql: String, parameters: Int, binders: (app.cash.sqldelight.db.SqlPreparedStatement.() -> Unit)?): QueryResult<Long> =
        error("no database")

    override fun newTransaction(): QueryResult<app.cash.sqldelight.Transacter.Transaction> = error("no database")
    override fun currentTransaction(): app.cash.sqldelight.Transacter.Transaction? = null
    override fun addListener(vararg queryKeys: String, listener: app.cash.sqldelight.Query.Listener) = Unit
    override fun removeListener(vararg queryKeys: String, listener: app.cash.sqldelight.Query.Listener) = Unit
    override fun notifyListeners(vararg queryKeys: String) = Unit
    override fun close() = Unit
}
