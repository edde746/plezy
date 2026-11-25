package com.edde746.plezy.supporter

import com.edde746.plezy.strings.InterfaceLocale
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** A home screen that switches icons as the platforms do, recording each call. */
internal class FakeAppIconSwitch : AppIconSwitch {
    var supported = true
    var current = AppIconCatalog.DEFAULT_ID
    var failWith: Exception? = null
    var refuseWith: AppIconError? = null
    var gate: CompletableDeferred<Unit>? = null
    var setGate: CompletableDeferred<Unit>? = null
    val calls = mutableListOf<String>()

    override suspend fun isSupported(): Boolean {
        calls += "isSupported"
        gate?.await()
        failWith?.let { throw it }
        return supported
    }

    override suspend fun current(): String {
        calls += "getCurrent"
        return current
    }

    override suspend fun setIcon(id: String): AppIconError? {
        calls += "setIcon:$id"
        setGate?.await()
        refuseWith?.let { return it }
        if (AppIconCatalog.byId(id) == null) return AppIconError.UNKNOWN_ICON
        current = id
        return null
    }
}

class AppIconsTest {
    private val platform = FakeAppIconSwitch()

    // ---- The catalog ---------------------------------------------------------------------------------------------

    @Test
    fun theDefaultIconComesFirstAndEveryIdIsUnique() {
        val ids = AppIconCatalog.options.map { it.id }
        assertEquals(AppIconCatalog.DEFAULT_ID, ids.first())
        assertEquals(ids.size, ids.toSet().size)
        assertEquals(23, ids.count { it != AppIconCatalog.DEFAULT_ID })
        assertNull(AppIconCatalog.byId("retired"))
    }

    @Test
    fun theCatalogKeepsItsPermanentIdsInOrderEachWithItsOwnName() {
        InterfaceLocale.setSystemLanguages(listOf("en"))
        val ids = listOf(
            "default", "midnight", "ember", "paper", "oled", "line", "ocean", "ultraviolet", "matcha", "sunset", "gold",
            "titanium", "glass", "crt", "vhs", "synthwave", "pixel", "neon", "sticker", "ticket", "pop", "strata", "facet",
            "tilde",
        )
        assertEquals(ids, AppIconCatalog.options.map { it.id })
        val labels = AppIconCatalog.options.map { it.label }
        assertTrue(labels.none { it.isBlank() || it in ids }, "every icon has a localized name: $labels")
        assertEquals(labels.size, labels.toSet().size)
        assertEquals("Ember", AppIconCatalog.byId("ember")?.label)
    }

    // ---- refresh -------------------------------------------------------------------------------------------------

    @Test
    fun aDeviceThatCanSwitchReportsSupportAndTheIconItsHomeScreenShows() = runTest {
        platform.current = "vhs"
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)

        icons.refresh()

        assertTrue(icons.state.value.supported)
        assertEquals("vhs", icons.state.value.currentId)
    }

    @Test
    fun aLauncherThatCannotSwitchLeavesThePickerUnsupportedOnTheDefaultIcon() = runTest {
        platform.supported = false
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)

        icons.refresh()

        assertFalse(icons.state.value.supported)
        assertEquals(AppIconCatalog.DEFAULT_ID, icons.state.value.currentId)
        assertEquals(listOf("isSupported"), platform.calls, "an unsupported launcher is never asked for its icon")
    }

    @Test
    fun aBuildWithoutAlternateIconsNeverAsksThePlatformAndStaysUnsupported() = runTest {
        val icons = AppIcons(null, MutableStateFlow(true), backgroundScope)

        icons.refresh()

        assertFalse(icons.state.value.supported)
        assertEquals(AppIconError.UNSUPPORTED, icons.setIcon("ember"))
    }

    @Test
    fun aPlatformErrorReadsAsUnsupportedInsteadOfEscaping() = runTest {
        platform.failWith = IllegalStateException("package manager died")
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)

        icons.refresh()

        assertFalse(icons.state.value.supported)
    }

    @Test
    fun concurrentRefreshesShareOnePlatformRoundTrip() = runTest {
        platform.gate = CompletableDeferred()
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)

        val first = launch { icons.refresh() }
        val second = launch { icons.refresh() }
        runCurrent()
        platform.gate!!.complete(Unit)
        first.join()
        second.join()

        assertEquals(listOf("isSupported", "getCurrent"), platform.calls)
    }

    @Test
    fun aRefreshNotifiesOnlyWhenTheIconOrSupportChanged() = runTest {
        platform.current = "vhs"
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)
        val seen = mutableListOf<AppIconState>()
        backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { icons.state.collect { seen += it } }

        icons.refresh()
        runCurrent()
        icons.refresh()
        runCurrent()
        assertEquals(listOf(AppIconState(), AppIconState(true, "vhs")), seen)

        platform.current = "neon"
        icons.refresh()
        runCurrent()
        assertEquals(listOf(AppIconState(), AppIconState(true, "vhs"), AppIconState(true, "neon")), seen)
    }

    // ---- setIcon -------------------------------------------------------------------------------------------------

    @Test
    fun switchesTheHomeScreenIcon() = runTest {
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)
        icons.refresh()

        assertNull(icons.setIcon("ember"))

        assertEquals("ember", platform.current)
        assertEquals("setIcon:ember", platform.calls.last())
        assertEquals("ember", icons.state.value.currentId)
    }

    @Test
    fun aPlatformRefusalSurfacesItsCodeAndKeepsTheCurrentIcon() = runTest {
        platform.current = "paper"
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)
        icons.refresh()

        assertEquals(AppIconError.UNKNOWN_ICON, icons.setIcon("bogus"))

        assertEquals("paper", icons.state.value.currentId)
    }

    @Test
    fun anUnsupportedDeviceRefusesWithoutCallingThePlatform() = runTest {
        platform.supported = false
        val icons = AppIcons(platform, MutableStateFlow(true), backgroundScope)
        icons.refresh()
        platform.calls.clear()

        assertEquals(AppIconError.UNSUPPORTED, icons.setIcon("ember"))

        assertTrue(platform.calls.isEmpty())
    }

    // ---- Supporter revocation ------------------------------------------------------------------------------------

    @Test
    fun aConfirmedRevocationPutsTheDefaultIconBackOnTheHomeScreen() = runTest {
        val unlocked = MutableStateFlow(true)
        platform.current = "neon"
        val icons = AppIcons(platform, unlocked, backgroundScope)
        icons.refresh()

        unlocked.value = false
        runCurrent()

        assertEquals(AppIconCatalog.DEFAULT_ID, platform.current)
        assertEquals(AppIconCatalog.DEFAULT_ID, icons.state.value.currentId)
    }

    @Test
    fun anEntitlementThatWasNeverUnlockedDoesNotTouchTheIcon() = runTest {
        val unlocked = MutableStateFlow(false)
        platform.current = "neon"
        val icons = AppIcons(platform, unlocked, backgroundScope)
        icons.refresh()
        runCurrent()
        platform.calls.clear()

        unlocked.value = false
        runCurrent()

        assertEquals("neon", platform.current)
        assertTrue(platform.calls.isEmpty())
    }

    @Test
    fun unlockingKeepsWhateverIconTheDeviceShows() = runTest {
        val unlocked = MutableStateFlow(false)
        val icons = AppIcons(platform, unlocked, backgroundScope)
        icons.refresh()
        runCurrent()
        platform.calls.clear()

        unlocked.value = true
        runCurrent()

        assertTrue(platform.calls.isEmpty())
        assertEquals(AppIconCatalog.DEFAULT_ID, icons.state.value.currentId)
    }

    @Test
    fun aRefundFromTheStoreRestoresTheDefaultIcon() = runTest {
        val appStore = FakeAppStoreBilling().apply { transactions = listOf(appStoreTransaction()) }
        val supporter = purchasable(appStore, MemoryEntitlementCache(true), backgroundScope)
        platform.current = "neon"
        val icons = AppIcons(platform, supporter.unlocked, backgroundScope)
        supporter.init()
        icons.refresh()

        appStore.deliver(appStorePurchase(revoked = true))
        runCurrent()

        assertEquals(AppIconCatalog.DEFAULT_ID, platform.current)
    }
}
