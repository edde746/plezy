package com.edde746.plezy.presentation.supporter

import com.edde746.plezy.strings.T
import com.edde746.plezy.supporter.AppIconCatalog
import com.edde746.plezy.supporter.AppIcons
import com.edde746.plezy.supporter.FakeAppIconSwitch
import com.edde746.plezy.supporter.FakeAppStoreBilling
import com.edde746.plezy.supporter.FakePlayBilling
import com.edde746.plezy.supporter.MemoryEntitlementCache
import com.edde746.plezy.supporter.Supporter
import com.edde746.plezy.supporter.SupporterAvailability
import com.edde746.plezy.supporter.SupporterError
import com.edde746.plezy.supporter.SupporterPurchaseStatus
import com.edde746.plezy.supporter.SupporterStoreState
import com.edde746.plezy.supporter.appStorePurchase
import com.edde746.plezy.supporter.purchasable
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SupporterStoresTest {
    private fun sheet(state: SupporterStoreState, unlocked: Boolean = false, icons: Boolean = true) =
        SupporterSheetUiState.of(state, unlocked, icons)

    // ---- The sheet -----------------------------------------------------------------------------------------------

    @Test
    fun theOfferSellsAtTheStoresPriceAndRestoreIsAlwaysThere() {
        val offer = sheet(SupporterStoreState(price = "3,99 €"))
        assertEquals(T.supporter.buy(price = "3,99 €"), offer.buyLabel)
        assertTrue(offer.buyEnabled)
        assertFalse(offer.retry)
        assertTrue(offer.restoreEnabled)
        assertNull(offer.notice)
    }

    @Test
    fun buyWaitsForThePriceWithASpinner() {
        val loading = sheet(SupporterStoreState(loadingProduct = true))
        assertEquals(T.supporter.loadingPrice, loading.buyLabel)
        assertFalse(loading.buyEnabled)
        assertTrue(loading.buySpinner)
        assertTrue(loading.restoreEnabled)
    }

    @Test
    fun aPriceThatFailedToLoadOffersRetryAndSaysWhy() {
        val failed = sheet(SupporterStoreState(productError = SupporterError.PRODUCT_QUERY_FAILED))
        assertTrue(failed.retry)
        assertEquals(T.supporter.errors.productQueryFailed, failed.notice?.message)
        assertTrue(failed.notice!!.failure)
    }

    @Test
    fun oneNoticeAtATimeTheLatestActionsErrorBeforeThePricesBeforeThePendingPurchase() {
        val both = sheet(
            SupporterStoreState(productError = SupporterError.PRODUCT_NOT_FOUND, error = SupporterError.RESTORE_FAILED, status = SupporterPurchaseStatus.PENDING),
        )
        assertEquals(T.supporter.errors.restoreFailed, both.notice?.message)

        val priceAndPending = sheet(SupporterStoreState(productError = SupporterError.PRODUCT_NOT_FOUND, status = SupporterPurchaseStatus.PENDING))
        assertEquals(T.supporter.errors.productNotFound, priceAndPending.notice?.message)

        val pending = sheet(SupporterStoreState(price = "\$3.99", status = SupporterPurchaseStatus.PENDING))
        assertEquals(T.supporter.pending, pending.notice?.message)
        assertFalse(pending.notice!!.failure)
        assertFalse(pending.buyEnabled, "a pending purchase can't be bought again")
    }

    @Test
    fun findingNothingToRestoreIsAnAnswerNotAFailure() {
        val notice = sheet(SupporterStoreState(price = "\$3.99", error = SupporterError.NOTHING_TO_RESTORE)).notice!!
        assertEquals(T.supporter.errors.nothingToRestore, notice.message)
        assertFalse(notice.failure)
    }

    @Test
    fun buttonsWaitWhileTheStoreIsBusy() {
        val purchasing = sheet(SupporterStoreState(price = "\$3.99", status = SupporterPurchaseStatus.PURCHASING))
        assertFalse(purchasing.buyEnabled)
        assertTrue(purchasing.buySpinner)
        assertFalse(purchasing.restoreEnabled)

        val restoring = sheet(SupporterStoreState(price = "\$3.99", status = SupporterPurchaseStatus.RESTORING))
        assertFalse(restoring.buyEnabled)
        assertTrue(restoring.restoreSpinner)
    }

    @Test
    fun platformsWithoutAlternateAppIconsDoNotOfferThem() {
        assertEquals(listOf(SupporterPerk.PRESET_THEMES, SupporterPerk.CUSTOM_THEME), sheet(SupporterStoreState(), icons = false).perks)
        assertTrue(SupporterPerk.APP_ICONS in sheet(SupporterStoreState(), icons = true).perks)
    }

    @Test
    fun openingTheSheetDropsTheLastFailureAndLoadsThePrice() = runTest {
        val supporter = purchasable(FakePlayBilling(), MemoryEntitlementCache(), backgroundScope)
        val store = SupporterSheetStore(supporter, offersAppIcons = true, backgroundScope)
        supporter.restore()
        assertEquals(SupporterError.NOTHING_TO_RESTORE, supporter.storeState.value.error)

        store.open()
        runCurrent()

        assertEquals("\$3.99", supporter.storeState.value.price)
        assertTrue(store.state.value.buyEnabled)
    }

    @Test
    fun theSheetOpensOnlyInBuildsThatSellThePurchase() = runTest {
        for (availability in SupporterAvailability.entries) {
            val supporter = Supporter(availability, null, MemoryEntitlementCache(), cached = false, backgroundScope)
            val store = SupporterSheetStore(supporter, offersAppIcons = true, backgroundScope)
            assertEquals(availability == SupporterAvailability.PURCHASABLE, store.canOpen)
        }
    }

    // ---- Settings tile -------------------------------------------------------------------------------------------

    @Test
    fun theSettingsTileNamesThePackAndOffersThePerksWhileLockedAndThanksOnceUnlocked() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, MemoryEntitlementCache(), backgroundScope)
        val store = SupporterSheetStore(supporter, offersAppIcons = true, backgroundScope)
        val themesOnly = SupporterSheetStore(supporter, offersAppIcons = false, backgroundScope)
        runCurrent()

        assertEquals("Theme & Icon Pack", store.tile.value.title)
        assertEquals(T.supporter.tileSubtitle, store.tile.value.subtitle)
        assertEquals(T.supporter.tileSubtitleThemesOnly, themesOnly.tile.value.subtitle)

        supporter.init()
        appStore.deliver(appStorePurchase())
        runCurrent()

        assertEquals(T.supporter.title, store.tile.value.title)
        assertEquals(T.supporter.tileUnlocked, store.tile.value.subtitle)
        assertTrue(store.state.value.unlocked)
    }

    // ---- App icon picker -----------------------------------------------------------------------------------------

    @Test
    fun theAppIconRowShowsOnlyWherePerksShowAndTheDeviceCanSwitch() = runTest {
        for ((availability, supported) in listOf(SupporterAvailability.FREE to true, SupporterAvailability.HIDDEN to true, SupporterAvailability.FREE to false)) {
            val supporter = Supporter(availability, null, MemoryEntitlementCache(), cached = false, backgroundScope)
            val switch = FakeAppIconSwitch().apply { this.supported = supported; current = "ember" }
            val icons = AppIcons(switch.takeIf { supporter.available }, supporter.unlocked, backgroundScope)
            val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}

            icons.refresh()
            runCurrent()

            val shown = availability != SupporterAvailability.HIDDEN && supported
            assertEquals(shown, picker.state.value.shown, "$availability, supported $supported")
            if (shown) assertEquals(T.appIcon.names.ember, picker.state.value.currentLabel)
        }
    }

    @Test
    fun lockedAlternatesCarryALockTheDefaultNeverDoes() = runTest {
        val supporter = purchasable(FakePlayBilling(), MemoryEntitlementCache(), backgroundScope)
        val icons = AppIcons(FakeAppIconSwitch(), supporter.unlocked, backgroundScope)
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}
        icons.refresh()
        runCurrent()

        val tiles = picker.state.value.tiles
        assertEquals(AppIconCatalog.options.map { it.id }, tiles.map { it.id })
        val default = tiles.first()
        assertTrue(default.current)
        assertFalse(default.locked)
        assertEquals(T.appIcon.current, default.stateLabel)
        assertTrue(tiles.drop(1).all { it.locked && it.stateLabel == T.appIcon.locked })
        assertEquals(T.appIcon.lockedHint, picker.state.value.lockedHint)
    }

    @Test
    fun aLockedAlternateOpensTheSupporterSheetAndAPurchaseThereAppliesIt() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, MemoryEntitlementCache(), backgroundScope)
        val switch = FakeAppIconSwitch()
        val icons = AppIcons(switch, supporter.unlocked, backgroundScope)
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}
        supporter.init()
        icons.refresh()

        picker.choose("neon")
        assertEquals(AppIconPickerEvent.OpenSupporter, picker.events.first())
        appStore.deliver(appStorePurchase())
        runCurrent()
        picker.supporterSheetClosed()
        runCurrent()

        assertEquals("neon", switch.current)
        assertEquals("neon", picker.state.value.tiles.single { it.current }.id)
    }

    @Test
    fun closingTheSupporterSheetWithoutBuyingLeavesTheIcon() = runTest {
        val supporter = purchasable(FakePlayBilling(), MemoryEntitlementCache(), backgroundScope)
        val switch = FakeAppIconSwitch()
        val icons = AppIcons(switch, supporter.unlocked, backgroundScope)
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}
        icons.refresh()

        picker.choose("neon")
        picker.supporterSheetClosed()
        runCurrent()

        assertEquals(AppIconCatalog.DEFAULT_ID, switch.current)
        assertTrue(switch.calls.none { it.startsWith("setIcon") })

        // The picker takes the next choice: the default, always selectable, is the one shown already.
        picker.choose("ember")
        assertEquals(AppIconPickerEvent.OpenSupporter, picker.events.first())
    }

    @Test
    fun aRefusedSwitchShowsANoticeOverTheAppAndKeepsTheCurrentIcon() = runTest {
        val supporter = Supporter(SupporterAvailability.FREE, null, MemoryEntitlementCache(), cached = false, backgroundScope)
        val switch = FakeAppIconSwitch().apply { refuseWith = com.edde746.plezy.supporter.AppIconError.FAILED }
        val icons = AppIcons(switch, supporter.unlocked, backgroundScope)
        val notices = mutableListOf<String>()
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) { notices += it }
        icons.refresh()

        picker.choose("ember")
        runCurrent()

        assertEquals(listOf(T.appIcon.changeFailed), notices)
        assertEquals(AppIconCatalog.DEFAULT_ID, icons.state.value.currentId)
    }

    @Test
    fun aChoiceIsIgnoredWhileAnotherIsStillBeingApplied() = runTest {
        val supporter = Supporter(SupporterAvailability.FREE, null, MemoryEntitlementCache(), cached = false, backgroundScope)
        val switch = FakeAppIconSwitch().apply { setGate = CompletableDeferred() }
        val icons = AppIcons(switch, supporter.unlocked, backgroundScope)
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}
        icons.refresh()

        picker.choose("ember")
        runCurrent()
        picker.choose("neon")
        picker.choose(AppIconCatalog.DEFAULT_ID)
        runCurrent()
        switch.setGate!!.complete(Unit)
        runCurrent()
        assertEquals(listOf("setIcon:ember"), switch.calls.filter { it.startsWith("setIcon") })
        assertEquals("ember", icons.state.value.currentId)

        picker.choose("neon")
        runCurrent()
        assertEquals("neon", icons.state.value.currentId, "the next choice once the first is applied")
    }

    @Test
    fun aLockedChoiceWaitingForTheSupporterSheetHoldsOffOtherChoices() = runTest {
        val supporter = purchasable(FakePlayBilling(), MemoryEntitlementCache(), backgroundScope)
        val switch = FakeAppIconSwitch()
        val icons = AppIcons(switch, supporter.unlocked, backgroundScope)
        val picker = AppIconPickerStore(icons, supporter, backgroundScope) {}
        icons.refresh()
        switch.current = "ember"
        icons.refresh()

        picker.choose("neon")
        assertEquals(AppIconPickerEvent.OpenSupporter, picker.events.first())
        picker.choose(AppIconCatalog.DEFAULT_ID)
        runCurrent()
        assertTrue(switch.calls.none { it.startsWith("setIcon") }, "the sheet is still open")

        picker.supporterSheetClosed()
        picker.choose(AppIconCatalog.DEFAULT_ID)
        runCurrent()
        assertEquals(AppIconCatalog.DEFAULT_ID, switch.current, "the default is always selectable")
    }
}
