package com.edde746.plezy.importer

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.cinterop.BetaInteropApi
import kotlinx.coroutines.test.runTest
import platform.Foundation.NSData
import platform.Foundation.NSNumber
import platform.Foundation.NSUserDefaults
import platform.Foundation.create
import platform.Foundation.numberWithBool
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** A Mac or iPhone that never ran Plezy's earlier releases: the app's defaults domain holds only the system's keys. */
class AppleFreshInstallImportTest {
    private val suite = "com.edde746.plezy.importer-fresh-test"
    private val defaults = NSUserDefaults(suiteName = suite)
    private val data = testData(TestClock())

    @AfterTest
    fun close() {
        defaults.removePersistentDomainForName(suite)
        data.close()
    }

    @OptIn(BetaInteropApi::class)
    @Test
    fun aDomainWithoutAnythingTheEarlierReleasesWroteIsNothingToImport() = runTest {
        defaults.setPersistentDomain(
            mapOf<Any?, Any?>(
                "NSSplitView Subview Frames main, SidebarNavigationSplitView" to listOf("0.000000, 0.000000, 260.000000, 800.000000, NO, NO"),
                "NSWindow Frame main" to "100 100 1280 800 0 0 1920 1055 ",
                "SUHasLaunchedBefore" to NSNumber.numberWithBool(true),
                "downloads.transfers" to NSData.create(base64EncodedString = "W10=", options = 0u),
            ),
            forName = suite,
        )
        val prefs = readUserDefaultsEarlierReleasePrefs(defaults, suite)
        assertNull(prefs)

        val found = readEarlierRelease(prefs, database = null, purgeableDatabase = false)
        assertEquals(EarlierReleaseOutcome.NOTHING, EarlierReleaseImport(data, MemorySecretStore()).importFound(found))
        assertEquals(EarlierReleaseOutcome.NOTHING, EarlierReleaseImport(data, MemorySecretStore()).outcome())
    }
}
