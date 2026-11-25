package com.edde746.plezy.importer

import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.DoubleValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.LongValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringListValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.convert
import kotlinx.cinterop.usePinned
import kotlinx.coroutines.test.runTest
import platform.Foundation.NSData
import platform.Foundation.NSPropertyListSerialization
import platform.Foundation.NSUserDefaults
import platform.Foundation.create
import kotlin.io.encoding.Base64
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

class UserDefaultsEarlierReleasePrefsTest {
    private val suite = "com.edde746.plezy.importer-test"
    private val defaults = NSUserDefaults(suiteName = suite)

    @OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
    @BeforeTest
    fun loadTheFixtureDomain() {
        val bytes = Base64.decode(EarlierReleasePlistFixture.BASE64)
        val data = bytes.usePinned { NSData.create(bytes = it.addressOf(0), length = bytes.size.convert()) }
        @Suppress("UNCHECKED_CAST")
        val domain = NSPropertyListSerialization.propertyListWithData(data, options = 0.convert(), format = null, error = null) as Map<Any?, *>
        defaults.setPersistentDomain(domain, forName = suite)
    }

    @AfterTest
    fun removeTheDomain() = defaults.removePersistentDomainForName(suite)

    @Test
    fun readsNativeTypesUnderBareKeysAndSkipsOthers() {
        val prefs = readUserDefaultsEarlierReleasePrefs(defaults, suite)!!

        assertEquals(BoolValue(true), prefs[EarlierReleasePrefs.MIGRATION_SENTINEL])
        assertEquals(BoolValue(true), prefs["enable_debug_logging"])
        assertEquals(LongValue(15), prefs["seek_time_small"])
        assertEquals(DoubleValue(100.0), prefs["volume"])
        assertEquals(StringValue("grid"), prefs["view_mode"])
        assertEquals(StringListValue(listOf("2", "1", "7")), prefs["user_local-aaa_library_order"])
        assertEquals(StringValue("100 100 1280 800 0 0 1920 1055 "), prefs["NSWindow Frame com.edde746.plezy.MainWindow"])
        // A date and an array holding a number are no preference types; the stale prefixed copies are ignored.
        assertNull(prefs["last_seen_date"])
        assertNull(prefs["mixed_array"])
        assertNull(prefs["flutter.view_mode"])
    }

    @Test
    fun aMissingDomainIsNothingToImport() {
        assertNull(readUserDefaultsEarlierReleasePrefs(defaults, "$suite.absent"))
    }

    @Test
    fun restoresTheTvosRecoveryImageAndDecryptsItsToken() = runTest {
        val prefs = readUserDefaultsEarlierReleasePrefs(defaults, suite)!!

        val decision = assertIs<TvosRecoveryDecision.Restore>(classifyTvosStartup(prefs, databaseExists = false))
        assertEquals(listOf("jf-machine/user-1"), decision.rows.connections.map { it.id })
        assertEquals(listOf("local-aaa"), decision.rows.profiles.map { it.id })
        assertEquals(
            EarlierReleaseOfflineWatchProgressRow(
                4, "local-aaa", "jf-machine", "jf-machine/user-1", "ep-8", "jf-machine:ep-8", "progress", 5000, 60000, false,
                1_700_005_000_000, 1_700_005_000_001, 0, null,
            ),
            decision.rows.offlineWatchProgress.single(),
        )
        val binding = decision.rows.profileConnections.single()
        assertEquals("profile-token-tv", EarlierReleaseCredentialVault.from(prefs).reveal(binding.userToken))
    }
}
