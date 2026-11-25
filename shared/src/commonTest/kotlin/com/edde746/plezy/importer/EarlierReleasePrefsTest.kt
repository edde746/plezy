package com.edde746.plezy.importer

import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.DoubleValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.LongValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class EarlierReleasePrefsTest {
    @Test
    fun migratedStoreIgnoresTheStalePrefixedCopies() {
        val prefs = EarlierReleasePrefs.resolve(
            mapOf(
                "flutter.view_mode" to StringValue("list"),
                "flutter.only_legacy" to StringValue("stale"),
                "view_mode" to StringValue("grid"),
                EarlierReleasePrefs.MIGRATION_SENTINEL to BoolValue(true),
            ),
        )

        assertEquals(mapOf("view_mode" to StringValue("grid"), EarlierReleasePrefs.MIGRATION_SENTINEL to BoolValue(true)), prefs.values)
    }

    @Test
    fun unmigratedStoreReadsPrefixedKeysWithBareKeysWinning() {
        val prefs = EarlierReleasePrefs.resolve(
            mapOf(
                "view_mode" to StringValue("grid"),
                "flutter.view_mode" to StringValue("list"),
                "flutter.volume" to DoubleValue(80.0),
            ),
        )

        assertEquals(mapOf("view_mode" to StringValue("grid"), "volume" to DoubleValue(80.0)), prefs.values)
    }

    @Test
    fun typedReadsOfAnotherTypeAreAbsent() {
        val prefs = EarlierReleasePrefs(mapOf("seek_time_small" to LongValue(15)))

        assertEquals(15L, prefs.long("seek_time_small"))
        assertNull(prefs.string("seek_time_small"))
        assertNull(prefs.double("seek_time_small"))
        assertNull(prefs.bool("missing"))
    }
}
