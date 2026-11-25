package com.edde746.plezy.servers

import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class HiddenLibrariesStoreTest {
    @Test
    fun `starts uninitialized and exposes empty set`() = runTest {
        val p = HiddenLibrariesStore(FakeLibraryPreferences(), scope = backgroundScope)
        assertFalse(p.isInitialized)
        assertTrue(p.hiddenLibraryKeys.isEmpty())
        p.ensureInitialized()
        assertTrue(p.isInitialized)
        assertTrue(p.hiddenLibraryKeys.isEmpty())
    }

    @Test
    fun `hideLibrary persists key and notifies listeners`() = runTest {
        val prefs = FakeLibraryPreferences()
        val p = HiddenLibrariesStore(prefs, scope = backgroundScope)
        p.ensureInitialized()
        var notified = -1
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { p.state.collect { notified++ } }

        p.hideLibrary("lib-1")
        assertTrue("lib-1" in p.hiddenLibraryKeys)
        assertEquals(setOf("lib-1"), prefs.hiddenLibraries())
        assertEquals(1, notified)

        p.hideLibrary("lib-1")
        assertEquals(1, notified)
    }

    @Test
    fun `persists across provider instances via SharedPreferences`() = runTest {
        val prefs = FakeLibraryPreferences()
        val first = HiddenLibrariesStore(prefs, scope = backgroundScope)
        first.ensureInitialized()
        first.hideLibrary("lib-A")
        first.hideLibrary("lib-B")
        first.close()

        val second = HiddenLibrariesStore(prefs, scope = backgroundScope)
        second.ensureInitialized()
        assertEquals(setOf("lib-A", "lib-B"), second.hiddenLibraryKeys)
    }

    @Test
    fun `unhideLibrary removes the key`() = runTest {
        val p = HiddenLibrariesStore(FakeLibraryPreferences(), scope = backgroundScope)
        p.ensureInitialized()
        p.hideLibrary("lib-1")
        p.hideLibrary("lib-2")

        p.unhideLibrary("lib-1")
        assertEquals(setOf("lib-2"), p.hiddenLibraryKeys)

        p.unhideLibrary("lib-3")
        assertEquals(setOf("lib-2"), p.hiddenLibraryKeys)
    }

    @Test
    fun `refresh re reads from storage`() = runTest {
        val prefs = FakeLibraryPreferences()
        val p = HiddenLibrariesStore(prefs, scope = backgroundScope)
        p.ensureInitialized()
        assertTrue(p.hiddenLibraryKeys.isEmpty())

        prefs.setHiddenLibraries(setOf("external-1", "external-2"))

        p.refresh()
        assertEquals(setOf("external-1", "external-2"), p.hiddenLibraryKeys)
    }

    @Test
    fun `explicit profile id stays isolated when active profile changes`() = runTest {
        val prefs = FakeLibraryPreferences()
        prefs.setHiddenLibraries(setOf("srv:movies"), "owner")
        prefs.setHiddenLibraries(setOf("srv:kids"), "kids")
        prefs.activeProfileId = "owner"

        val owner = HiddenLibrariesStore(prefs, profileId = "owner", scope = backgroundScope)
        val kids = HiddenLibrariesStore(prefs, profileId = "kids", scope = backgroundScope)

        prefs.activeProfileId = "kids"
        owner.refresh()
        kids.refresh()

        assertEquals(setOf("srv:movies"), owner.hiddenLibraryKeys)
        assertEquals(setOf("srv:kids"), kids.hiddenLibraryKeys)

        owner.hideLibrary("srv:documentaries")

        assertEquals(setOf("srv:movies", "srv:documentaries"), prefs.hiddenLibraries("owner"))
        assertEquals(setOf("srv:kids"), prefs.hiddenLibraries("kids"))
        assertEquals(setOf("srv:kids"), prefs.hiddenLibraries())
    }

    @Test
    fun `refresh marks provider initialized after deterministic reload`() = runTest {
        val prefs = FakeLibraryPreferences()
        prefs.setHiddenLibraries(setOf("srv:movies"), "owner")

        val p = HiddenLibrariesStore(prefs, profileId = "owner", scope = backgroundScope)
        assertFalse(p.isInitialized)

        p.refresh()

        assertTrue(p.isInitialized)
        assertEquals(setOf("srv:movies"), p.hiddenLibraryKeys)
    }

    @Test
    fun `safeNotifyListeners no ops after dispose`() = runTest {
        val p = HiddenLibrariesStore(FakeLibraryPreferences(), scope = backgroundScope)
        p.ensureInitialized()
        p.close()
        p.refresh()
        p.hideLibrary("lib-1")
        assertTrue(p.hiddenLibraryKeys.isEmpty())
    }

    @Test
    fun `removing a server strips its entries from order and hidden lists`() {
        val keys = listOf("A:1", "B:1", "A:2", "AB:3", "bare")
        assertEquals(listOf("B:1", "AB:3", "bare"), keys.withoutServer(ServerId("A")))
    }
}
