package com.edde746.plezy.data

import app.cash.sqldelight.db.QueryResult
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals

class DatabaseFileTest {
    @Test
    fun reopeningKeepsTheData() = runTest {
        val file = Files.createTempDirectory("plezy-db").resolve("nested").resolve(DATABASE_FILE_NAME)

        val first = testData(factory = DatabaseFactory(file))
        val before = first.deviceSettings.settings().audioNormalization
        first.deviceSettings.set(AppSettings.audioNormalization, !before)
        first.close()

        val second = testData(factory = DatabaseFactory(file))
        assertEquals(!before, second.deviceSettings.settings().audioNormalization)
        second.close()
    }

    @Test
    fun `reads one after another use one open connection`() = runTest {
        val data = testData(factory = DatabaseFactory(Files.createTempDirectory("plezy-db").resolve(DATABASE_FILE_NAME)))
        // A temporary table lives as long as the connection that made it.
        data.db.useDriver { data.driver.execute(null, "CREATE TEMP TABLE probe(x)", 0) }

        repeat(20) { read ->
            val probes = data.db.read {
                data.driver.executeQuery(null, "SELECT count(*) FROM sqlite_temp_master WHERE name = 'probe'", { cursor ->
                    cursor.next()
                    QueryResult.Value(cursor.getLong(0))
                }, 0).value
            }
            assertEquals(1L, probes, "read ${read + 1} opened a connection of its own")
        }
        data.close()
    }
}
