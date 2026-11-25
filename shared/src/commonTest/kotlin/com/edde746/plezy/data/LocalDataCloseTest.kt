package com.edde746.plezy.data

import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Closing the database while work on other threads still reads it. */
class LocalDataCloseTest {
    @Test
    fun closingWaitsForAQueryFlowStillReadingItsRows() = runTest {
        val data = testData()
        data.deviceSettings.set(AppSettings.audioNormalization, true)
        data.deviceSettings.set(AppSettings.gestureVolumeSwipe, false)
        val reading = CompletableDeferred<Unit>()
        val closing = CompletableDeferred<Unit>()
        val events = MutableStateFlow(emptyList<String>())
        // Maps its rows on the I/O thread, the first one still as the database closes and for a while after.
        val query = data.db.database.deviceSettingQueries.selectAll { key, _ ->
            if (reading.complete(Unit)) runBlocking { closing.await(); delay(100) }
            events.update { it + "row" }
            key
        }
        val rows = async { data.db.observeList(query).first() }
        withContext(Dispatchers.Default) { reading.await() }
        closing.complete(Unit)
        data.close()
        events.update { it + "closed" }

        assertEquals(listOf("row", "row", "closed"), events.value, "the query's rows were read before the database closed")
        assertEquals(setOf(AppSettings.audioNormalization.key, AppSettings.gestureVolumeSwipe.key), rows.await().toSet())
    }

    @Test
    fun aReadAfterCloseFails() = runTest {
        val data = testData()
        data.close()
        assertFailsWith<IllegalStateException> { data.deviceSettings.settings() }
    }
}
