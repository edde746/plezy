package com.edde746.plezy.importer

import kotlin.experimental.ExperimentalNativeApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The earlier releases' data is the running app's own: a build under another bundle ID never reaches the release's. */
class AppleEarlierReleaseLocationsTest {
    private val other = "com.example.otherbuild"

    @Test
    fun thePreferencesAreTheDefaultsDomainOfTheAppsOwnId() {
        assertEquals(EarlierReleasePreferencesLocation.UserDefaults(other), EarlierReleaseLocations.apple(other).preferences)
    }

    @OptIn(ExperimentalNativeApi::class)
    @Test
    fun onTheMacTheDataAndTheCachesAreUnderTheAppsOwnId() {
        if (Platform.osFamily != OsFamily.MACOSX) return
        val locations = EarlierReleaseLocations.apple(other)
        assertTrue(locations.baseDirectory.endsWith("/Library/Application Support/$other"), locations.baseDirectory)
        assertEquals(locations.baseDirectory, locations.supportDirectory)
        assertTrue(locations.temporaryDirectory!!.endsWith("/Library/Caches/$other"), locations.temporaryDirectory)
    }
}
