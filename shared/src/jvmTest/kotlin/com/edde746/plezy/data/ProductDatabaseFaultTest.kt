package com.edde746.plezy.data

import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.Startup
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.db.PlezyDatabase
import com.edde746.plezy.secrets.MemorySecretStore
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The product's start on the desktop (as on Apple) checks the database's schema as it opens it, before anything reads it. */
class ProductDatabaseFaultTest {
    private val db = fileDatabase()

    @AfterTest
    fun delete() = db.delete()

    @Test
    fun aDatabaseAnUnreleasedBuildChangedFailsTheProductStartAsUnreadable() {
        val driver = db.factory.createDriver(PlezyDatabase.Schema)
        try {
            userVersion(driver)
            driver.execute(null, "ALTER TABLE downloaded_media DROP COLUMN transcode_quality", 0)
        } finally {
            driver.close()
        }
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)

        val failure = runCatching {
            AppBootstrap.product(db.factory, MemorySecretStore(), BuildFlavor.SIDELOADED, "test", Startup(0))
        }.exceptionOrNull()

        assertTrue(failure is StartupFailedException, "the start went on: $failure")
        assertEquals(StartupPhase.DATABASE, failure.record.phase)
        assertEquals(DataFault.UNREADABLE, failure.record.dataFault)
    }
}
