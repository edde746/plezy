package com.edde746.plezy.supporter

import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Counts [flow]'s changes after now: [Supporter.unlocked] changes only when the entitlement does. */
@OptIn(ExperimentalCoroutinesApi::class)
private fun TestScope.countChanges(flow: StateFlow<Boolean>): () -> Int {
    var changes = 0
    backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { flow.drop(1).collect { changes++ } }
    return { changes }
}

class SupporterTest {
    private val cache = MemoryEntitlementCache()

    // ---- Availability -------------------------------------------------------------------------------------------

    @Test
    fun aMicrosoftStoreInstallGetsThePerksFreeTheSameCompileOutsideTheStoreHidesThem() {
        assertEquals(SupporterAvailability.FREE, SupporterAvailability.of(SupporterMode.MSSTORE, packagedInstall = true))
        assertEquals(SupporterAvailability.HIDDEN, SupporterAvailability.of(SupporterMode.MSSTORE, packagedInstall = false))
    }

    @Test
    fun storeAndFreeBuildsIgnoreThePackagedInstallCheck() {
        for (packaged in listOf(true, false)) {
            assertEquals(SupporterAvailability.PURCHASABLE, SupporterAvailability.of(SupporterMode.IAP, packaged))
            assertEquals(SupporterAvailability.FREE, SupporterAvailability.of(SupporterMode.UNLOCKED, packaged))
            assertEquals(SupporterAvailability.HIDDEN, SupporterAvailability.of(SupporterMode.OFF, packaged))
        }
    }

    @Test
    fun theStoresSellThePerksAmazonAndTheDesktopsGiveThemAndSideloadedPhonesLeaveThemOut() {
        for (phoneOrTv in listOf(DevicePlatform.ANDROID, DevicePlatform.ANDROID_TV, DevicePlatform.IOS, DevicePlatform.IPADOS)) {
            assertEquals(SupporterMode.IAP, SupporterMode.of(BuildFlavor.STORE, phoneOrTv))
            assertEquals(SupporterMode.OFF, SupporterMode.of(BuildFlavor.SIDELOADED, phoneOrTv))
        }
        assertEquals(SupporterMode.UNLOCKED, SupporterMode.of(BuildFlavor.AMAZON, DevicePlatform.ANDROID_TV))
        assertEquals(SupporterMode.UNLOCKED, SupporterMode.of(BuildFlavor.SIDELOADED, DevicePlatform.MACOS))
        assertEquals(SupporterMode.UNLOCKED, SupporterMode.of(BuildFlavor.SIDELOADED, DevicePlatform.LINUX))
        for (flavor in BuildFlavor.entries) assertEquals(SupporterMode.MSSTORE, SupporterMode.of(flavor, DevicePlatform.WINDOWS))
    }

    @Test
    fun onlyTheSideloadedBuildsLinkToDonations() {
        assertTrue(SupporterPlatform.of(BuildFlavor.SIDELOADED, DevicePlatform.ANDROID).donations)
        assertFalse(SupporterPlatform.of(BuildFlavor.STORE, DevicePlatform.ANDROID).donations)
        assertFalse(SupporterPlatform.of(BuildFlavor.AMAZON, DevicePlatform.ANDROID).donations)
    }

    // ---- The Settings hub's top tile per Apple platform: the Supporter tile in purchasable builds, else the donation
    // ---- tile in the builds that link to donations ------------------------------------------------------------------

    /** The hub's top tile of a [flavor] build on [platform]: the Supporter tile, the donation tile, or none. */
    private fun hubTile(flavor: BuildFlavor, platform: String): String? {
        val supporter = SupporterPlatform.of(flavor, platform)
        return when {
            supporter.availability == SupporterAvailability.PURCHASABLE -> "supporter"
            supporter.donationUrl != null -> "donate"
            else -> null
        }
    }

    @Test
    fun iPhoneShowsTheSupporterTileFromTheAppStoreAndTheDonationTileInTheGitHubIpa() {
        assertEquals("supporter", hubTile(BuildFlavor.STORE, DevicePlatform.IOS))
        assertEquals("donate", hubTile(BuildFlavor.SIDELOADED, DevicePlatform.IOS))
        assertNull(SupporterPlatform.of(BuildFlavor.STORE, DevicePlatform.IOS).donationUrl)
    }

    @Test
    fun iPadShowsTheSupporterTileFromTheAppStoreAndTheDonationTileInTheGitHubIpa() {
        assertEquals("supporter", hubTile(BuildFlavor.STORE, DevicePlatform.IPADOS))
        assertEquals("donate", hubTile(BuildFlavor.SIDELOADED, DevicePlatform.IPADOS))
        assertNull(SupporterPlatform.of(BuildFlavor.STORE, DevicePlatform.IPADOS).donationUrl)
    }

    @Test
    fun appleTvShowsTheSupporterTileInEveryBuildAndNeverTheDonationTile() {
        for (flavor in BuildFlavor.entries) {
            assertEquals(SupporterMode.IAP, SupporterMode.of(flavor, DevicePlatform.TVOS))
            assertEquals("supporter", hubTile(flavor, DevicePlatform.TVOS))
            assertFalse(SupporterPlatform.of(flavor, DevicePlatform.TVOS).donations)
        }
        assertNull(SupporterPlatform.of(BuildFlavor.SIDELOADED, DevicePlatform.TVOS).withMode(SupporterMode.UNLOCKED).donationUrl)
    }

    @Test
    fun macShowsTheDonationTileWithThePerksFreeAndNoSupporterTile() {
        val mac = SupporterPlatform.of(BuildFlavor.SIDELOADED, DevicePlatform.MACOS)
        assertEquals(SupporterAvailability.FREE, mac.availability)
        assertEquals("donate", hubTile(BuildFlavor.SIDELOADED, DevicePlatform.MACOS))
        assertEquals(SupporterPlatform.DONATION_URL, mac.donationUrl)
    }

    // ---- Cached entitlement and the start -----------------------------------------------------------------------

    @Test
    fun theStartPaintsThePerksFromTheBuildAndTheCache() {
        assertTrue(Supporter.startupUnlocked(SupporterAvailability.PURCHASABLE, cached = true))
        assertFalse(Supporter.startupUnlocked(SupporterAvailability.PURCHASABLE, cached = false))
        assertTrue(Supporter.startupUnlocked(SupporterAvailability.FREE, cached = false))
        assertFalse(Supporter.startupUnlocked(SupporterAvailability.HIDDEN, cached = true))
    }

    @Test
    fun aPurchasableSupporterIsUnlockedFromTheCacheBeforeInitCompletes() = runTest {
        cache.value = true
        val supporter = purchasable(FakeAppStoreBilling(), cache, backgroundScope)
        val changes = countChanges(supporter.unlocked)

        assertTrue(supporter.unlocked.value)
        supporter.init()

        assertTrue(supporter.unlocked.value)
        assertEquals(0, changes())
    }

    @Test
    fun initRestoresACachedEntitlementTheStartCouldNotReadAndNotifies() = runTest {
        cache.value = true
        val supporter = Supporter(SupporterAvailability.PURCHASABLE, SupporterStore.of(FakeAppStoreBilling()), cache, cached = false, backgroundScope)
        val changes = countChanges(supporter.unlocked)

        assertFalse(supporter.unlocked.value)
        supporter.init()

        assertTrue(supporter.unlocked.value)
        assertEquals(1, changes())
    }

    @Test
    fun aHiddenBuildStaysLockedEvenWithACachedEntitlement() = runTest {
        cache.value = true
        val supporter = Supporter(SupporterAvailability.HIDDEN, null, cache, cached = true, backgroundScope)
        supporter.init()

        assertFalse(supporter.available)
        assertFalse(supporter.unlocked.value)
    }

    @Test
    fun freeAndHiddenBuildsNeverTouchBilling() = runTest {
        for (availability in listOf(SupporterAvailability.FREE, SupporterAvailability.HIDDEN)) {
            val billing = FakePlayBilling()
            val supporter = Supporter(availability, SupporterStore.of(billing), cache, cached = false, backgroundScope)

            supporter.init()
            supporter.loadProduct()
            supporter.purchase()
            supporter.restore()
            runCurrent()

            assertEquals(0, billing.billingCalls, "$availability")
            assertEquals(availability == SupporterAvailability.FREE, supporter.unlocked.value)
        }
    }

    // ---- Google Play ---------------------------------------------------------------------------------------------

    @Test
    fun theProductLoadsWithTheStoresLocalizedPrice() = runTest {
        val play = FakePlayBilling().apply { price = "3,99 €" }
        val supporter = purchasable(play, cache, backgroundScope)

        supporter.loadProduct()

        val state = supporter.storeState.value
        assertFalse(state.loadingProduct)
        assertEquals("3,99 €", state.price)
        assertNull(state.productError)
    }

    @Test
    fun aStoreWithoutTheProductOrOneThatFailsTheQueryLeavesBuyWithoutAPrice() = runTest {
        val missing = purchasable(FakePlayBilling().apply { price = null }, cache, backgroundScope)
        missing.loadProduct()
        assertNull(missing.storeState.value.price)
        assertEquals(SupporterError.PRODUCT_NOT_FOUND, missing.storeState.value.productError)

        val failingPlay = FakePlayBilling().apply { productQueryError = Exception("offline") }
        val failing = purchasable(failingPlay, cache, backgroundScope)
        failing.loadProduct()
        assertEquals(SupporterError.PRODUCT_QUERY_FAILED, failing.storeState.value.productError)

        val answeringWithAnError = purchasable(FakePlayBilling().apply { price = null; productErrorCode = "service_unavailable" }, cache, backgroundScope)
        answeringWithAnError.loadProduct()
        assertEquals(SupporterError.PRODUCT_QUERY_FAILED, answeringWithAnError.storeState.value.productError)

        // Retrying after the store recovers prices the product.
        failingPlay.productQueryError = null
        failing.loadProduct()
        assertEquals("\$3.99", failing.storeState.value.price)
        assertNull(failing.storeState.value.productError)
    }

    @Test
    fun aCompletedPurchaseUnlocksNotifiesCachesAndIsAcknowledged() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        val changes = countChanges(supporter.unlocked)

        supporter.purchase()
        assertEquals(listOf(SUPPORTER_PRODUCT_ID), play.bought)
        assertEquals(SupporterPurchaseStatus.PURCHASING, supporter.storeState.value.status)

        val purchase = playPurchase()
        play.deliver(purchase)
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertEquals(1, changes())
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertNull(supporter.storeState.value.error)
        assertEquals(listOf(purchase), play.completed)
        assertTrue(cache.value)
    }

    @Test
    fun anAlreadyAcknowledgedPurchaseUnlocksWithoutAcknowledgingItAgain() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()

        play.deliver(playPurchase(acknowledged = true))
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertTrue(play.completed.isEmpty())
    }

    @Test
    fun aPendingPurchaseWaitsWithoutUnlockingOrAcknowledgingThenUnlocksOncePaid() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        supporter.purchase()

        play.deliver(playPurchase(pending = true))
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.PENDING, supporter.storeState.value.status)
        assertTrue(play.completed.isEmpty())
        assertFalse(cache.value)

        val paid = playPurchase()
        play.deliver(paid)
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertEquals(listOf(paid), play.completed)
    }

    @Test
    fun aPurchaseStillWaitingForPaymentAtStartupShowsAsPending() = runTest {
        val play = FakePlayBilling().apply { pastPurchases = listOf(playPurchase(pending = true)) }
        val supporter = purchasable(play, cache, backgroundScope)

        supporter.init()

        assertFalse(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.PENDING, supporter.storeState.value.status)
    }

    @Test
    fun aPendingPurchasePaidWhileInTheBackgroundUnlocksAndIsAcknowledgedOnReturningToTheForeground() = runTest {
        val play = FakePlayBilling().apply { pastPurchases = listOf(playPurchase(pending = true)) }
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        assertEquals(SupporterPurchaseStatus.PENDING, supporter.storeState.value.status)

        val paid = playPurchase()
        play.pastPurchases = listOf(paid)
        supporter.onForeground()

        assertTrue(supporter.unlocked.value)
        assertTrue(cache.value)
        assertEquals(listOf(paid), play.completed)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
    }

    @Test
    fun aFailedPurchaseReportsTheFailureAndLeavesTheEntitlementAlone() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        val changes = countChanges(supporter.unlocked)
        supporter.purchase()

        play.deliver(playBillingFailure())
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(0, changes())
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertEquals(SupporterError.PURCHASE_FAILED, supporter.storeState.value.error)
        assertFalse(cache.value)
    }

    @Test
    fun aPurchaseFlowTheStoreWillNotOpenReportsTheFailure() = runTest {
        val play = FakePlayBilling().apply { launchesPurchase = false }
        val supporter = purchasable(play, cache, backgroundScope)

        supporter.purchase()
        runCurrent()

        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertEquals(SupporterError.PURCHASE_FAILED, supporter.storeState.value.error)
    }

    @Test
    fun aFailedPurchaseOfAnAccountThatOwnsItAlreadyUnlocks() = runTest {
        val play = FakePlayBilling().apply { launchesPurchase = false }
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        play.pastPurchases = listOf(playPurchase(acknowledged = true))

        supporter.purchase()
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertNull(supporter.storeState.value.error)
    }

    @Test
    fun closingTheStoreSheetReturnsToTheOfferWithoutAnError() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.purchase()

        play.deliver(playBillingCancel())
        runCurrent()

        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertNull(supporter.storeState.value.error)
        assertFalse(supporter.unlocked.value)
    }

    @Test
    fun restorePurchasesUnlocksAPurchaseTheAccountOwnsAndAcknowledgesIt() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        val owned = playPurchase()
        play.pastPurchases = listOf(owned)

        supporter.restore()

        assertTrue(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertNull(supporter.storeState.value.error)
        assertEquals(listOf(owned), play.completed)
        assertTrue(cache.value)
    }

    @Test
    fun restorePurchasesWithNothingToRestoreSaysSoAndStaysLocked() = runTest {
        val supporter = purchasable(FakePlayBilling(), cache, backgroundScope)

        supporter.restore()

        assertFalse(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertEquals(SupporterError.NOTHING_TO_RESTORE, supporter.storeState.value.error)
    }

    @Test
    fun aFailingPurchaseQueryKeepsTheCachedUnlockAndRestoreSaysTheStoreWasUnreachable() = runTest {
        cache.value = true
        val play = FakePlayBilling().apply { historyError = Exception("restore_transactions_failed") }
        val supporter = purchasable(play, cache, backgroundScope)
        val changes = countChanges(supporter.unlocked)

        supporter.init()
        supporter.restore()

        assertTrue(supporter.unlocked.value)
        assertEquals(0, changes())
        assertEquals(SupporterError.RESTORE_FAILED, supporter.storeState.value.error)
        assertTrue(cache.value)
    }

    @Test
    fun unavailablePlayBillingAnsweringWithAnEmptyHistoryIsNotARefund() = runTest {
        // No Google account or no Play Store: the purchase query comes back empty and error-free from a client that
        // never connected.
        cache.value = true
        val play = FakePlayBilling().apply { available = false }
        val supporter = purchasable(play, cache, backgroundScope)
        val changes = countChanges(supporter.unlocked)

        supporter.init()
        supporter.loadProduct()
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertEquals(0, changes())
        assertEquals(SupporterError.STORE_UNAVAILABLE, supporter.storeState.value.productError)
        assertTrue(cache.value)

        supporter.restore()

        assertTrue(supporter.unlocked.value)
        assertEquals(SupporterError.STORE_UNAVAILABLE, supporter.storeState.value.error)
        assertTrue(cache.value)
    }

    @Test
    fun clearingTheErrorLeavesTheOfferWithoutTheLastFailure() = runTest {
        val supporter = purchasable(FakePlayBilling(), cache, backgroundScope)
        supporter.restore()
        assertEquals(SupporterError.NOTHING_TO_RESTORE, supporter.storeState.value.error)

        supporter.clearError()

        assertNull(supporter.storeState.value.error)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
    }

    @Test
    fun aRefundedPurchaseLocksThePerksNotifiesAndClearsTheCache() = runTest {
        cache.value = true
        val play = FakePlayBilling().apply { pastPurchases = listOf(playPurchase(productId = "some_other_product")) }
        val supporter = purchasable(play, cache, backgroundScope)
        val changes = countChanges(supporter.unlocked)
        assertTrue(supporter.unlocked.value)

        supporter.init()
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(1, changes())
        assertFalse(cache.value)
    }

    @Test
    fun aRefundCheckThatStartedBeforeAPurchaseCompletedCannotRevokeIt() = runTest {
        val play = FakePlayBilling().apply { historyGate = CompletableDeferred() }
        val supporter = purchasable(play, cache, backgroundScope)
        val init = launch { supporter.init() }
        runCurrent()
        assertEquals(1, play.historyQueries)

        play.deliver(playPurchase())
        runCurrent()
        assertTrue(supporter.unlocked.value)

        // The query that started before the purchase answers without it.
        play.historyGate!!.complete(Unit)
        init.join()

        assertTrue(supporter.unlocked.value)
        assertTrue(cache.value)
    }

    @Test
    fun otherProductsAreNeitherUnlockedNorAcknowledged() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()

        play.deliver(playPurchase(productId = "some_other_product"))
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertTrue(play.completed.isEmpty())
    }

    @Test
    fun closingTheSupporterStopsListeningToTheStore() = runTest {
        val play = FakePlayBilling()
        val supporter = purchasable(play, cache, backgroundScope)
        supporter.init()
        assertTrue(play.listener != null)

        supporter.close()

        assertNull(play.listener)
    }

    // ---- App Store -----------------------------------------------------------------------------------------------

    @Test
    fun anAppStorePurchaseUnlocksCachesAndFinishesTheTransaction() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.init()
        supporter.purchase()

        val purchase = appStorePurchase()
        appStore.deliver(purchase)
        runCurrent()

        assertTrue(supporter.unlocked.value)
        assertEquals(listOf(purchase), appStore.completed)
        assertTrue(cache.value)
    }

    @Test
    fun askToBuyWaitsWithoutUnlocking() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.purchase()

        appStore.deliver(appStorePurchase(status = StorePurchaseStatus.PENDING))
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(SupporterPurchaseStatus.PENDING, supporter.storeState.value.status)
        assertTrue(appStore.completed.isEmpty())
    }

    @Test
    fun restorePurchasesSyncsTheAppleAccountAndUnlocksItsPurchase() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.init()
        appStore.transactions = listOf(appStoreTransaction())

        supporter.restore()

        assertEquals(1, appStore.syncs)
        assertTrue(supporter.unlocked.value)
        assertNull(supporter.storeState.value.error)
        assertTrue(cache.value)
    }

    @Test
    fun anAppStoreWithoutTheProductReportsItMissingNotAConnectionFailure() = runTest {
        val supporter = purchasable(FakeAppStoreBilling().apply { price = null }, cache, backgroundScope)

        supporter.loadProduct()

        assertNull(supporter.storeState.value.price)
        assertEquals(SupporterError.PRODUCT_NOT_FOUND, supporter.storeState.value.productError)
    }

    @Test
    fun cancellingTheAppleAccountSignInDuringRestoreReturnsToTheOfferWithoutAnError() = runTest {
        val appStore = FakeAppStoreBilling().apply { syncFailure = AppStoreBilling.SYNC_CANCELLED }
        val supporter = purchasable(appStore, cache, backgroundScope)

        supporter.restore()

        assertEquals(1, appStore.syncs)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertNull(supporter.storeState.value.error)
        assertFalse(supporter.unlocked.value)
    }

    @Test
    fun aFailedAppleAccountSyncWithNoPurchaseInTheHistoryReportsTheFailure() = runTest {
        val supporter = purchasable(FakeAppStoreBilling().apply { syncFailure = "networkError" }, cache, backgroundScope)

        supporter.restore()

        assertEquals(SupporterError.RESTORE_FAILED, supporter.storeState.value.error)
    }

    @Test
    fun anEmptyHistoryKeepsTheCachedUnlockAnotherAppleAccountMayBeSignedIn() = runTest {
        cache.value = true
        val supporter = purchasable(FakeAppStoreBilling(), cache, backgroundScope)

        supporter.init()

        assertTrue(supporter.unlocked.value)
        assertTrue(cache.value)
    }

    @Test
    fun aRefundInTheHistoryLocksThePerksAtStartup() = runTest {
        cache.value = true
        val appStore = FakeAppStoreBilling().apply { transactions = listOf(appStoreTransaction(revoked = true)) }
        val supporter = purchasable(appStore, cache, backgroundScope)
        val changes = countChanges(supporter.unlocked)

        supporter.init()
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(1, changes())
        assertFalse(cache.value)
    }

    @Test
    fun aRefundDeliveredWhileRunningLocksThePerksAndFinishesTheTransaction() = runTest {
        val appStore = FakeAppStoreBilling().apply { transactions = listOf(appStoreTransaction()) }
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.init()
        assertTrue(supporter.unlocked.value)
        val changes = countChanges(supporter.unlocked)

        val refund = appStorePurchase(revoked = true)
        appStore.deliver(refund)
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertEquals(1, changes())
        assertEquals(listOf(refund), appStore.completed)
        assertFalse(cache.value)
    }

    @Test
    fun aRefundDeliveredWhileAnOwnedHistoryIsReadKeepsThePerksLocked() = runTest {
        cache.value = true
        val appStore = FakeAppStoreBilling().apply {
            transactions = listOf(appStoreTransaction())
            historyGate = CompletableDeferred()
        }
        val supporter = purchasable(appStore, cache, backgroundScope)
        val init = launch { supporter.init() }
        runCurrent()
        assertEquals(1, appStore.historyQueries)

        appStore.deliver(appStorePurchase(revoked = true))
        runCurrent()
        assertFalse(supporter.unlocked.value)

        // The history that began before the refund answers with the purchase still owned.
        appStore.historyGate!!.complete(Unit)
        init.join()
        assertFalse(supporter.unlocked.value)
        assertFalse(cache.value)
    }

    @Test
    fun otherAppStoreProductsAreIgnored() = runTest {
        val appStore = FakeAppStoreBilling().apply { transactions = listOf(appStoreTransaction(productId = "some_other_product")) }
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.init()

        appStore.deliver(appStorePurchase(productId = "some_other_product"))
        runCurrent()

        assertFalse(supporter.unlocked.value)
        assertTrue(appStore.completed.isEmpty())
    }

    @Test
    fun anAppStoreProductLoadTellsAnUnavailableStoreAFailedQueryAndAThrowingQueryApart() = runTest {
        val unavailable = purchasable(FakeAppStoreBilling().apply { available = false }, cache, backgroundScope)
        unavailable.loadProduct()
        assertEquals(SupporterError.STORE_UNAVAILABLE, unavailable.storeState.value.productError)

        val answering = purchasable(FakeAppStoreBilling().apply { price = null; productErrorCode = "networkError" }, cache, backgroundScope)
        answering.loadProduct()
        assertEquals(SupporterError.PRODUCT_QUERY_FAILED, answering.storeState.value.productError)

        val throwing = purchasable(FakeAppStoreBilling().apply { productQueryError = IllegalStateException("StoreKit") }, cache, backgroundScope)
        throwing.loadProduct()
        assertEquals(SupporterError.PRODUCT_QUERY_FAILED, throwing.storeState.value.productError)
    }

    @Test
    fun anAppStorePurchaseLoadsTheProductFirstAndNeverStartsWhileUnlockedOrAlreadyBuying() = runTest {
        val appStore = FakeAppStoreBilling()
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.purchase()
        assertEquals("\$3.99", supporter.storeState.value.price, "the product loads first")
        assertEquals(listOf(SUPPORTER_PRODUCT_ID), appStore.bought)
        assertEquals(SupporterPurchaseStatus.PURCHASING, supporter.storeState.value.status)

        supporter.purchase()
        assertEquals(1, appStore.bought.size, "a purchase in flight")

        appStore.deliver(appStorePurchase())
        runCurrent()
        assertTrue(supporter.unlocked.value)
        supporter.purchase()
        assertEquals(1, appStore.bought.size, "unlocked already")

        val missing = FakeAppStoreBilling().apply { price = null }
        purchasable(missing, MemoryEntitlementCache(), backgroundScope).purchase()
        assertTrue(missing.bought.isEmpty(), "nothing to buy without the product")

        val free = FakeAppStoreBilling()
        Supporter(SupporterAvailability.FREE, SupporterStore.of(free), MemoryEntitlementCache(), false, backgroundScope).purchase()
        assertTrue(free.bought.isEmpty(), "a build that gives the perks sells nothing")
    }

    @Test
    fun aThrowingAppStorePurchaseFailsAndThenTheHistoryDecidesWhetherTheAccountOwnsIt() = runTest {
        val appStore = FakeAppStoreBilling().apply { buyError = IllegalStateException("StoreKit") }
        val supporter = purchasable(appStore, cache, backgroundScope)
        supporter.purchase()
        runCurrent()
        assertEquals(SupporterError.PURCHASE_FAILED, supporter.storeState.value.error)
        assertEquals(SupporterPurchaseStatus.IDLE, supporter.storeState.value.status)
        assertEquals(1, appStore.historyQueries)
        assertFalse(supporter.unlocked.value)

        appStore.transactions = listOf(appStoreTransaction())
        supporter.purchase()
        runCurrent()
        assertTrue(supporter.unlocked.value)
        assertNull(supporter.storeState.value.error)
    }

    @Test
    fun anAppStoreHistoryThatStartedBeforeAPurchaseCompletedCannotRevokeIt() = runTest {
        val appStore = FakeAppStoreBilling().apply {
            transactions = listOf(appStoreTransaction(revoked = true))
            historyGate = CompletableDeferred()
        }
        val supporter = purchasable(appStore, cache, backgroundScope)
        val init = launch { supporter.init() }
        runCurrent()
        assertEquals(1, appStore.historyQueries)

        appStore.deliver(appStorePurchase())
        runCurrent()
        assertTrue(supporter.unlocked.value)

        // The history that began before the purchase answers with only the old refund.
        appStore.historyGate!!.complete(Unit)
        init.join()
        assertTrue(supporter.unlocked.value)
        assertTrue(cache.value)
    }
}
