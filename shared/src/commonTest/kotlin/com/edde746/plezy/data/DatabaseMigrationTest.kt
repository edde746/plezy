package com.edde746.plezy.data

import app.cash.sqldelight.db.AfterVersion
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals

/**
 * Opening a database an earlier or a later release wrote. No release has a migration yet, so the tests make one: the
 * schema of a release after this one ([NextSchema]), whose migration from this one changes a table and adds an index.
 */
class DatabaseMigrationTest {
    private val databases = mutableListOf<FileDatabase>()

    @AfterTest
    fun deleteDatabases() = databases.forEach(FileDatabase::delete)

    @Test
    fun anOlderDatabaseMigratesToTheSchemaOfAFreshInstallAndKeepsItsRows() {
        val older = olderDatabaseWithRows()
        val (before, rows) = older.use(PlezyDatabase.Schema) { schemaShape(it) to readEveryRow(it) }

        val migrated = older.use(NextSchema()) { Triple(schemaShape(it), readEveryRow(it), userVersion(it)) }
        val fresh = fileDatabase().also(databases::add).use(NextSchema()) { schemaShape(it) }

        assertNotEquals(before, migrated.first, "the migration changed nothing")
        assertEquals(fresh, migrated.first)
        assertRowsSurvive(rows, migrated.second)
        assertEquals(PlezyDatabase.Schema.version + 1, migrated.third)
    }

    @Test
    fun anOlderDatabaseIsCopiedAsideBeforeItsMigrationAndTheCopyGoesOnceItsDone() {
        val older = olderDatabaseWithRows()
        val copy = Path(older.file.parent!!, "${older.file.name}.v${PlezyDatabase.Schema.version}.bak")

        older.use(NextSchema()) {}
        assertEquals(PlezyDatabase.Schema.version, storedSchemaVersion(copy), "the copy is the database before its migration")

        older.use(NextSchema()) {}
        assertFalse(SystemFileSystem.exists(copy), "the copy stayed once the database was at the current version")
    }

    @Test
    fun aFailedMigrationLeavesTheDatabaseAsItWas() {
        val older = olderDatabaseWithRows()
        val (schema, rows) = older.use(PlezyDatabase.Schema) { schemaShape(it) to readEveryRow(it) }

        val failure = assertFailsWith<IllegalStateException> {
            older.use(NextSchema(failAfterMigrating = true)) {}
        }
        assertEquals("the migration failed", failure.message)
        val copy = Path(older.file.parent!!, "${older.file.name}.v${PlezyDatabase.Schema.version}.bak")
        assertEquals(PlezyDatabase.Schema.version, storedSchemaVersion(copy), "the copy aside after a failed migration")

        older.use(PlezyDatabase.Schema) {
            assertEquals(PlezyDatabase.Schema.version, userVersion(it))
            assertEquals(schema, schemaShape(it))
            assertEquals(rows, readEveryRow(it))
        }
    }

    @Test
    fun aDatabaseALaterReleaseWroteIsRefusedAndLeftAsItIs() {
        val newer = fileDatabase().also(databases::add)
        newer.use(NextSchema()) { seedEveryTable(it) }

        val refused = assertFailsWith<DatabaseNewerThanAppException> { newer.use(PlezyDatabase.Schema) {} }
        assertEquals(PlezyDatabase.Schema.version + 1, refused.stored)
        assertEquals(PlezyDatabase.Schema.version, refused.supported)
        assertEquals(PlezyDatabase.Schema.version + 1, storedSchemaVersion(newer.file))
        newer.use(NextSchema()) { assertEquals(1, readEveryRow(it).getValue("api_cache").size) }
    }

    @Test
    fun aDatabaseALaterReleaseWroteFailsTheStartAtTheDatabase() {
        val newer = fileDatabase().also(databases::add)
        newer.use(NextSchema()) {}
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        val directory = Path(SystemTemporaryDirectory, "plezy-start-${Random.nextLong().toULong()}").toString()

        val failure = assertFailsWith<StartupFailedException> {
            AppBootstrap.product(
                directory, MemorySecretStore(), BuildFlavor.SIDELOADED, "test", development = false,
                earlierRelease = null, downloadTempDirectory = null,
            ) { LocalData(newer.factory) }
        }
        assertEquals(StartupPhase.DATABASE, failure.record.phase)
        assertIs<DatabaseNewerThanAppException>(failure.cause)
    }

    /** A database at this release's schema version, one row in each table. */
    private fun olderDatabaseWithRows(): FileDatabase = fileDatabase().also { databases += it }.apply {
        use(PlezyDatabase.Schema) { seedEveryTable(it) }
    }

    /** Opens the database with [schema] (creating or migrating it), runs [block] over it and closes it. */
    private fun <T> FileDatabase.use(schema: SqlSchema<QueryResult.Value<Unit>>, block: (SqlDriver) -> T): T {
        val driver = factory.createDriver(schema)
        return try {
            // Android's driver opens the database at its first statement.
            userVersion(driver)
            block(driver)
        } finally {
            driver.close()
        }
    }

    /**
     * This release's schema and a release after it, whose migration adds a column to `api_cache` and an index; with
     * [failAfterMigrating], the migration fails after both.
     */
    private class NextSchema(private val failAfterMigrating: Boolean = false) : SqlSchema<QueryResult.Value<Unit>> {
        override val version: Long = PlezyDatabase.Schema.version + 1

        override fun create(driver: SqlDriver): QueryResult.Value<Unit> {
            PlezyDatabase.Schema.create(driver)
            next(driver)
            return QueryResult.Unit
        }

        override fun migrate(driver: SqlDriver, oldVersion: Long, newVersion: Long, vararg callbacks: AfterVersion): QueryResult.Value<Unit> {
            if (oldVersion < PlezyDatabase.Schema.version) PlezyDatabase.Schema.migrate(driver, oldVersion, PlezyDatabase.Schema.version, *callbacks)
            next(driver)
            check(!failAfterMigrating) { "the migration failed" }
            return QueryResult.Unit
        }

        private fun next(driver: SqlDriver) {
            driver.execute(null, "ALTER TABLE api_cache ADD COLUMN migration_probe TEXT", 0)
            driver.execute(null, "CREATE INDEX idx_api_cache_migration_probe ON api_cache(migration_probe)", 0)
        }
    }
}
