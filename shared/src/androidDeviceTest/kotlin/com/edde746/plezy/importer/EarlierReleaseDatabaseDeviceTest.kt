package com.edde746.plezy.importer

import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.data.testData
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.test.runTest
import java.io.File
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The earlier releases' database read through Android's own SQLite. */
class EarlierReleaseDatabaseDeviceTest {
    private val directory = File(InstrumentationRegistry.getInstrumentation().targetContext.cacheDir, "flutter-import-test")
    private val data = testData()

    @AfterTest
    fun removeDirectory() {
        data.close()
        directory.deleteRecursively()
    }

    @Test
    fun anEmptyVersionZeroFileHoldsNoRows() {
        directory.mkdirs()
        val file = File(directory, EARLIER_RELEASE_DATABASE_FILE_NAME).apply { createNewFile() }

        val db = readEarlierReleaseDatabase(file.path)

        assertEquals(0, db.schemaVersion)
        assertTrue(db.connections.isEmpty() && db.downloadedMedia.isEmpty() && db.pinnedApiCache.isEmpty())
        assertEquals(0L, file.length())
    }

    @Test
    fun aCachedListingLargerThanACursorWindowLeavesTheImportWorking() = runTest {
        // The earlier releases cached a whole library listing as one row; Android reads at most 2 MB of a row.
        directory.mkdirs()
        val pinnedKey = "jf-machine/user-1:/Users/user-1/Items/ep-7"
        val pinnedData = """{"Id":"ep-7","Name":"Episode 7"}"""
        val file = File(directory, EARLIER_RELEASE_DATABASE_FILE_NAME).apply { createNewFile() }
        openEarlierReleaseSqlite(file.path).use { db ->
            createEarlierReleaseSchema(db)
            val insert = "INSERT INTO api_cache (cache_key, data, cached_at, pinned) VALUES (?, ?, ?, ?)"
            db.execute(insert, listOf(pinnedKey, pinnedData, "1700000000", "1"))
            val listing = """{"Items":"${"x".repeat(3 * 1024 * 1024)}"}"""
            db.execute(insert, listOf("jf-machine/user-1:/Users/user-1/Items?ParentId=library", listing, "1700000100", "0"))
        }
        val install = EarlierReleaseLocations(
            baseDirectory = directory.path,
            supportDirectory = directory.path,
            legacyDatabase = null,
            orphanedSupportDirectory = null,
            preferences = EarlierReleasePreferencesLocation.AndroidStores(File(directory, "none.preferences_pb").path, File(directory, "none.xml").path),
        )

        assertEquals(EarlierReleaseOutcome.IMPORTED, EarlierReleaseImport(data, MemorySecretStore()).run(install))

        val cached = data.db.read { apiCacheQueries.selectByPrefix("").executeAsList() }
        assertEquals(listOf(Triple(pinnedKey, pinnedData, true)), cached.map { Triple(it.cache_key, it.data_, it.pinned) })
    }
}
