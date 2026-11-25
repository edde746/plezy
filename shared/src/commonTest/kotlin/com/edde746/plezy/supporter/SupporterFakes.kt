package com.edde746.plezy.supporter

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope

/** The cached entitlement in memory. */
internal class MemoryEntitlementCache(var value: Boolean = false) : EntitlementCache {
    override suspend fun read() = value

    override suspend fun write(unlocked: Boolean) {
        value = unlocked
    }
}

/** The billing calls both stores share: product, purchase flow, completion and the purchase stream. */
internal abstract class FakeBilling : StoreBilling {
    var available = true
    var price: String? = "\$3.99"
    var productErrorCode: String? = null
    var productQueryError: Exception? = null
    var launchesPurchase = true
    var buyError: Exception? = null
    val bought = mutableListOf<String>()
    val completed = mutableListOf<StorePurchase>()
    var listener: StorePurchaseListener? = null

    /** Every call that reaches billing. */
    var billingCalls = 0

    override suspend fun isAvailable(): Boolean {
        billingCalls++
        return available
    }

    override suspend fun queryProduct(productId: String): StoreProduct {
        billingCalls++
        productQueryError?.let { throw it }
        return StoreProduct(price.takeIf { productId == SUPPORTER_PRODUCT_ID }, productErrorCode)
    }

    override suspend fun buy(productId: String): Boolean {
        billingCalls++
        bought += productId
        buyError?.let { throw it }
        return launchesPurchase
    }

    override suspend fun complete(purchase: StorePurchase) {
        completed += purchase
    }

    override fun listen(listener: StorePurchaseListener) {
        billingCalls++
        this.listener = listener
    }

    override fun stopListening() {
        listener = null
    }

    fun deliver(vararg purchases: StorePurchase) = checkNotNull(listener) { "nothing listens" }.onPurchases(purchases.toList())
}

internal class FakePlayBilling : FakeBilling(), PlayBilling {
    var pastPurchases = listOf<StorePurchase>()
    var historyError: Exception? = null
    var historyGate: CompletableDeferred<Unit>? = null
    var historyQueries = 0

    override suspend fun queryPastPurchases(): List<StorePurchase> {
        historyQueries++
        // The answer is what the account held when the query began.
        val answer = pastPurchases
        historyGate?.await()
        historyError?.let { throw it }
        return answer
    }
}

internal class FakeAppStoreBilling : FakeBilling(), AppStoreBilling {
    var transactions = listOf<StoreTransaction>()
    var syncFailure: String? = null
    var syncs = 0

    var historyGate: CompletableDeferred<Unit>? = null
    var historyQueries = 0

    override suspend fun transactions(): List<StoreTransaction> {
        historyQueries++
        // The answer is what the account held when the query began.
        val answer = transactions
        historyGate?.await()
        return answer
    }

    override suspend fun sync(): String? {
        syncs++
        return syncFailure
    }
}

/** A Play purchase: completed (unacknowledged unless [acknowledged]) or [pending]. */
internal fun playPurchase(
    productId: String = SUPPORTER_PRODUCT_ID,
    pending: Boolean = false,
    acknowledged: Boolean = false,
) = StorePurchase(
    productId,
    if (pending) StorePurchaseStatus.PENDING else StorePurchaseStatus.PURCHASED,
    pendingComplete = !acknowledged,
    token = "token-$productId",
)

/** How Play reports a billing flow that failed, or that the user closed, before a purchase existed. */
internal fun playBillingFailure() = StorePurchase("", StorePurchaseStatus.ERROR, errorMessage = "BillingResponse.error")

internal fun playBillingCancel() = StorePurchase("", StorePurchaseStatus.CANCELED)

/** A StoreKit transaction on the purchase stream: unfinished, so completing finishes it. */
internal fun appStorePurchase(
    productId: String = SUPPORTER_PRODUCT_ID,
    status: StorePurchaseStatus = StorePurchaseStatus.PURCHASED,
    revoked: Boolean = false,
) = StorePurchase(productId, status, revoked = revoked, pendingComplete = true, token = "1000")

internal fun appStoreTransaction(productId: String = SUPPORTER_PRODUCT_ID, revoked: Boolean = false) = StoreTransaction(productId, revoked)

internal fun purchasable(billing: StoreBilling, cache: MemoryEntitlementCache, scope: CoroutineScope) =
    Supporter(SupporterAvailability.PURCHASABLE, SupporterStore.of(billing), cache, cache.value, scope)
