package com.edde746.plezy.data

import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import com.edde746.plezy.data.db.PlezyDatabase
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.nameWithoutExtension
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Each released schema (`src/commonMain/sqldelight/databases/<version>.db`, the release step's snapshot) with a row in
 * every table migrates, as the app opens it, to the schema of a fresh install, and keeps its rows. No release has a
 * snapshot yet; `DatabaseMigrationTest` runs the same checks over a made-up next version.
 */
class ReleasedSchemaMigrationTest {
    @Test
    fun everyReleasedSchemaMigratesToAFreshInstallsSchemaAndKeepsItsRows() {
        val snapshots = Path.of("src/commonMain/sqldelight/databases").takeIf(Files::isDirectory)
            ?.listDirectoryEntries("*.db").orEmpty()
        val fresh = open(Files.createTempDirectory("plezy-db").resolve(DATABASE_FILE_NAME)) { schemaShape(it) }
        for (snapshot in snapshots) {
            val version = snapshot.nameWithoutExtension.toLong()
            val file = Files.createTempDirectory("plezy-db").resolve(DATABASE_FILE_NAME)
            Files.copy(snapshot, file)
            val rows = JdbcSqliteDriver("jdbc:sqlite:$file", Properties()).use { driver ->
                // The snapshot holds the schema only: the version is the one its release opens it at.
                driver.execute(null, "PRAGMA user_version = $version", 0)
                seedEveryTable(driver)
                readEveryRow(driver)
            }

            open(file) { driver ->
                assertEquals(PlezyDatabase.Schema.version, userVersion(driver), "version $version's database")
                assertEquals(fresh, schemaShape(driver), "version $version's schema, migrated")
                assertRowsSurvive(rows, readEveryRow(driver))
            }
        }
    }

    private fun <T> open(file: Path, block: (app.cash.sqldelight.db.SqlDriver) -> T): T =
        DatabaseFactory(file).createDriver(PlezyDatabase.Schema).use(block)
}
