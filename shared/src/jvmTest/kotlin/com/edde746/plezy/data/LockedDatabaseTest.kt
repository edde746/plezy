package com.edde746.plezy.data

import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import java.sql.DriverManager
import java.util.Properties
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes

/** A read and a query flow's readers when a read fails: another connection holds the database's lock, or a table is gone. */
class LockedDatabaseTest {
    @Test
    fun aReaderSeesTheNextChangeAfterAReadThatFoundTheDatabaseLocked() = runTest {
        val file = Files.createTempFile("plezy-locked", ".db")
        // No busy timeout: a read that meets another connection's lock fails at once with SQLITE_BUSY.
        val driver = JdbcSqliteDriver("jdbc:sqlite:$file", Properties().apply { setProperty("busy_timeout", "0") }, PlezyDatabase.Schema)
        try {
            val db = Db(PlezyDatabase(driver), StandardTestDispatcher(testScheduler), { 0L })
            val seen = mutableListOf<Int>()
            backgroundScope.launch { DeviceSettingsRepository(db).observe().collect { seen += it.subtitles.backgroundOpacity } }
            runCurrent()

            DriverManager.getConnection("jdbc:sqlite:$file").use { other ->
                other.createStatement().use { statement ->
                    statement.execute("BEGIN EXCLUSIVE")
                    statement.execute("INSERT INTO device_setting VALUES ('subtitle_background_opacity', '2')")
                    driver.notifyListeners("device_setting")
                    runCurrent()
                    statement.execute("COMMIT")
                }
            }
            advanceTimeBy(1.minutes)
            runCurrent()

            assertEquals(listOf(0, 2), seen)
        } finally {
            driver.close()
            Files.deleteIfExists(file)
        }
    }

    @Test
    fun aReadThatFindsTheDatabaseBusyIsReadAgainAndSucceeds() = runTest {
        val file = Files.createTempFile("plezy-locked", ".db")
        val driver = JdbcSqliteDriver("jdbc:sqlite:$file", Properties().apply { setProperty("busy_timeout", "0") }, PlezyDatabase.Schema)
        try {
            val db = Db(PlezyDatabase(driver), StandardTestDispatcher(testScheduler), { 0L })
            val read = DriverManager.getConnection("jdbc:sqlite:$file").use { other ->
                other.createStatement().use { statement ->
                    statement.execute("BEGIN EXCLUSIVE")
                    statement.execute("INSERT INTO device_setting VALUES ('subtitle_background_opacity', '2')")
                    val read = backgroundScope.async { runCatching { DeviceSettingsRepository(db).settings().subtitles.backgroundOpacity } }
                    runCurrent()
                    assertFalse(read.isCompleted, "the busy read waits to read again")
                    statement.execute("COMMIT")
                    read
                }
            }
            advanceTimeBy(1.minutes)
            runCurrent()

            assertEquals(2, read.await().getOrThrow())
        } finally {
            driver.close()
            Files.deleteIfExists(file)
        }
    }

    @Test
    fun aReadThatFailsOtherwiseEndsItsReaderOnce() = runTest {
        val file = Files.createTempFile("plezy-locked", ".db")
        val driver = JdbcSqliteDriver("jdbc:sqlite:$file", Properties(), PlezyDatabase.Schema)
        try {
            val db = Db(PlezyDatabase(driver), StandardTestDispatcher(testScheduler), { 0L })
            val seen = mutableListOf<Int>()
            val reader = DriverManager.getConnection("jdbc:sqlite:$file").use { other ->
                other.createStatement().use { statement ->
                    statement.execute("ALTER TABLE device_setting RENAME TO device_setting_away")
                    val reader = backgroundScope.async { runCatching { DeviceSettingsRepository(db).observe().collect { seen += it.subtitles.backgroundOpacity } } }
                    runCurrent()
                    statement.execute("ALTER TABLE device_setting_away RENAME TO device_setting")
                    statement.execute("INSERT INTO device_setting VALUES ('subtitle_background_opacity', '2')")
                    driver.notifyListeners("device_setting")
                    reader
                }
            }
            advanceTimeBy(1.minutes)
            runCurrent()

            assertTrue(reader.isCompleted, "the failure reached the reader instead of being read again")
            assertTrue(reader.await().isFailure)
            assertEquals(emptyList(), seen, "nothing was read again")
        } finally {
            driver.close()
            Files.deleteIfExists(file)
        }
    }
}
