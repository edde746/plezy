package com.edde746.plezy.supporter

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Where a purchase or restore the user started stands. */
enum class SupporterPurchaseStatus {
    IDLE,

    /** The store's purchase flow is open. */
    PURCHASING,

    /** The store took the purchase but waits on payment or a parent (Ask to Buy); perks unlock when it completes. */
    PENDING,

    /** Restore Purchases is reading the store account. */
    RESTORING,
}

/** Why the store could not price, sell or restore the Supporter purchase. */
enum class SupporterError {
    /** No store account, no store app, or purchases restricted on this device. */
    STORE_UNAVAILABLE,

    /** The store answered without the Supporter product. */
    PRODUCT_NOT_FOUND,

    /** The store could not be reached for the product and its price. */
    PRODUCT_QUERY_FAILED,
    PURCHASE_FAILED,

    /** Restore could not read the store account. */
    RESTORE_FAILED,

    /** The store account has no Supporter purchase to restore. */
    NOTHING_TO_RESTORE,
}

/**
 * The store-facing state the Supporter sheet draws: the product's [price] once loaded, or [productError] after loading
 * failed; the purchase's [status] and the last action's [error].
 */
data class SupporterStoreState(
    val loadingProduct: Boolean = false,
    val price: String? = null,
    val productError: SupporterError? = null,
    val status: SupporterPurchaseStatus = SupporterPurchaseStatus.IDLE,
    val error: SupporterError? = null,
) {
    val busy: Boolean get() = status == SupporterPurchaseStatus.PURCHASING || status == SupporterPurchaseStatus.RESTORING
}

/** The last confirmed entitlement, kept on the device ([AppSettings.supporterEntitlementCached]). */
interface EntitlementCache {
    suspend fun read(): Boolean

    suspend fun write(unlocked: Boolean)
}

/** [AppSettings.supporterEntitlementCached] in [this] device's settings: never exported, never reset. */
fun DeviceSettingsRepository.entitlementCache(): EntitlementCache = object : EntitlementCache {
    override suspend fun read() = value(AppSettings.supporterEntitlementCached)

    override suspend fun write(unlocked: Boolean) = set(AppSettings.supporterEntitlementCached, unlocked)
}

/**
 * The Supporter entitlement for the app's lifetime: a purchase belongs to the store account on this device, not to a
 * profile. [unlocked] turns false only after a confirmed revocation (a refund), never because the store is unreachable,
 * so a true→false change is a real revocation ([AppIcons] puts the default icon back on it).
 *
 * How each store reports a revocation:
 * - Google Play: a successful purchase query that no longer lists the product, checked at startup, on each return to
 *   the foreground ([onForeground]) and on Restore Purchases; Play sends the app nothing when a refund happens.
 * - App Store: StoreKit 2 delivers the revoked transaction on its updates while the app runs, and `Transaction.all`
 *   keeps it with its revocation for the startup check. An empty history is not a revocation: another Apple Account
 *   may be signed in.
 *
 * @param cached the cached entitlement, read before the app's first frame, so a perk never flashes locked
 *   ([startupUnlocked]).
 * @param store the device's store; null where none sells the purchase, and a purchase then reports
 *   [SupporterError.STORE_UNAVAILABLE].
 */
class Supporter(
    val availability: SupporterAvailability,
    private val store: SupporterStore?,
    private val cache: EntitlementCache,
    cached: Boolean,
    private val scope: CoroutineScope,
) {
    private val mutableUnlocked = MutableStateFlow(startupUnlocked(availability, cached))
    private val mutableStoreState = MutableStateFlow(SupporterStoreState())
    private var listening = false
    private var price: String? = null
    private var closed = false

    /**
     * Bumped by every confirmed purchase or revocation from the purchase stream, so a history query that began earlier
     * can't revoke a purchase, or unlock a revoked one, that the stream confirmed while it ran.
     */
    private var entitlementGeneration = 0

    /** Whether the perks are usable now. */
    val unlocked: StateFlow<Boolean> = mutableUnlocked.asStateFlow()

    /** Product, purchase and restore progress for the Supporter sheet. */
    val storeState: StateFlow<SupporterStoreState> = mutableStoreState.asStateFlow()

    /** Whether any perk UI shows on this install. */
    val available: Boolean get() = availability != SupporterAvailability.HIDDEN

    /** Restores a cached entitlement the start couldn't read, then refreshes it from the store. */
    suspend fun init() {
        if (availability != SupporterAvailability.PURCHASABLE) return
        // The cache only raises the entitlement here; lowering it takes a confirmed revocation.
        if (cache.read() && !purchased) setUnlocked(true)
        val store = ensureStore() ?: return
        val ownership = refreshEntitlement(store)
        if (ownership == SupporterOwnership.PENDING && !purchased && !storeState.value.busy) {
            setState { copy(status = SupporterPurchaseStatus.PENDING) }
        }
    }

    /**
     * The app came back to the foreground. On Google Play the history is read again: a pending purchase paid or a refund
     * made while the app was in the background reaches it only that way, and a purchase it finds unacknowledged is
     * acknowledged. StoreKit's purchase stream already reports both while the app runs.
     */
    suspend fun onForeground() {
        if (availability != SupporterAvailability.PURCHASABLE || store !is PlaySupporterStore) return
        refreshEntitlement(ensureStore() ?: return)
    }

    /** Loads the Supporter product and its localized price, once per process (again after a failure). */
    suspend fun loadProduct() {
        if (availability != SupporterAvailability.PURCHASABLE) return
        if (price != null || storeState.value.loadingProduct) return
        val store = ensureStore()
        if (store == null) {
            setState { copy(productError = SupporterError.STORE_UNAVAILABLE) }
            return
        }
        setState { copy(loadingProduct = true, productError = null, error = null) }
        val failure: SupporterError? = try {
            if (!store.billing.isAvailable()) {
                SupporterError.STORE_UNAVAILABLE
            } else {
                val product = store.billing.queryProduct(SUPPORTER_PRODUCT_ID)
                price = product.price
                when {
                    product.price != null -> null
                    product.errorCode != null -> {
                        Log.w(TAG) { "the product query failed: ${product.errorCode}" }
                        SupporterError.PRODUCT_QUERY_FAILED
                    }
                    else -> {
                        Log.w(TAG) { "the store has no \"$SUPPORTER_PRODUCT_ID\" product" }
                        SupporterError.PRODUCT_NOT_FOUND
                    }
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the product query failed" }
            SupporterError.PRODUCT_QUERY_FAILED
        }
        setState { copy(loadingProduct = false, price = this@Supporter.price, productError = failure) }
    }

    /** Opens the store's purchase flow; the outcome arrives on the purchase stream, in [storeState] and [unlocked]. */
    suspend fun purchase() {
        if (availability != SupporterAvailability.PURCHASABLE || purchased || storeState.value.busy) return
        val store = ensureStore()
        if (store == null) {
            setState { copy(error = SupporterError.STORE_UNAVAILABLE) }
            return
        }
        if (price == null) loadProduct()
        if (price == null || closed || storeState.value.busy) return
        setState { copy(status = SupporterPurchaseStatus.PURCHASING, error = null) }
        val launched = try {
            store.billing.buy(SUPPORTER_PRODUCT_ID)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the purchase failed" }
            false
        }
        if (!launched) {
            Log.w(TAG) { "the store did not open its purchase flow" }
            failPurchase(store)
        }
    }

    /** Restore Purchases: reads the store account again and unlocks if it owns the Supporter purchase. */
    suspend fun restore() {
        if (availability != SupporterAvailability.PURCHASABLE || storeState.value.busy) return
        val store = ensureStore()
        if (store == null) {
            setState { copy(error = SupporterError.STORE_UNAVAILABLE) }
            return
        }
        setState { copy(status = SupporterPurchaseStatus.RESTORING, error = null) }
        var synced = true
        try {
            store.syncForRestore()
        } catch (e: SupporterRestoreCancelled) {
            setState { copy(status = SupporterPurchaseStatus.IDLE) }
            return
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The history may still hold the purchase; this failure stands only if it doesn't.
            Log.w(TAG, e) { "the store sync for restore failed" }
            synced = false
        }
        var failure = SupporterError.RESTORE_FAILED
        val ownership = refreshEntitlement(store) { failure = it }
        setState {
            when (ownership) {
                SupporterOwnership.OWNED -> copy(status = SupporterPurchaseStatus.IDLE)
                SupporterOwnership.PENDING -> copy(status = SupporterPurchaseStatus.PENDING)
                SupporterOwnership.REVOKED, SupporterOwnership.UNKNOWN -> copy(
                    status = SupporterPurchaseStatus.IDLE,
                    error = if (synced) SupporterError.NOTHING_TO_RESTORE else SupporterError.RESTORE_FAILED,
                )
                null -> copy(status = SupporterPurchaseStatus.IDLE, error = failure)
            }
        }
    }

    /** Drops the last purchase or restore error, so a sheet opened later starts from the offer. */
    fun clearError() {
        val state = storeState.value
        if (state.error != null && !state.busy) setState { copy(error = null) }
    }

    /** Stops listening to the store. */
    fun close() {
        closed = true
        if (listening) store?.billing?.stopListening()
        listening = false
    }

    private val purchased: Boolean get() = mutableUnlocked.value

    /**
     * The store, listening to its purchase stream from the first use: StoreKit replays unfinished transactions and Play
     * delivers completed pending purchases to the first listener.
     */
    private fun ensureStore(): SupporterStore? {
        if (closed || store == null) return null
        if (!listening) {
            listening = true
            store.billing.listen { purchases -> scope.launch { handlePurchases(store, purchases) } }
        }
        return store
    }

    private suspend fun handlePurchases(store: SupporterStore, purchases: List<StorePurchase>) {
        for (purchase in purchases) {
            if (closed) return
            if (purchase.productId == SUPPORTER_PRODUCT_ID) {
                handleSupporterPurchase(store, purchase)
            } else if (purchase.productId.isEmpty() && storeState.value.status == SupporterPurchaseStatus.PURCHASING) {
                // Play reports a cancelled or failed billing flow without a product.
                when (purchase.status) {
                    StorePurchaseStatus.CANCELED -> setState { copy(status = SupporterPurchaseStatus.IDLE) }
                    StorePurchaseStatus.ERROR -> {
                        Log.w(TAG) { "the purchase failed: ${purchase.errorMessage}" }
                        failPurchase(store)
                    }
                    else -> {}
                }
            }
            // Any other product isn't Plezy's: the store keeps it.
        }
    }

    private suspend fun handleSupporterPurchase(store: SupporterStore, purchase: StorePurchase) {
        val status = purchase.status
        if (purchase.revoked) {
            entitlementGeneration++
            Log.i(TAG) { "the store revoked the purchase" }
            setUnlocked(false)
        } else {
            when (status) {
                StorePurchaseStatus.PURCHASED, StorePurchaseStatus.RESTORED -> {
                    entitlementGeneration++
                    setUnlocked(true)
                    setState { copy(status = SupporterPurchaseStatus.IDLE, error = null) }
                }
                StorePurchaseStatus.PENDING ->
                    if (!purchased) setState { copy(status = SupporterPurchaseStatus.PENDING, error = null) }
                StorePurchaseStatus.CANCELED ->
                    if (storeState.value.status == SupporterPurchaseStatus.PURCHASING) setState { copy(status = SupporterPurchaseStatus.IDLE) }
                StorePurchaseStatus.ERROR -> {
                    Log.w(TAG) { "the purchase failed: ${purchase.errorMessage}" }
                    if (storeState.value.status == SupporterPurchaseStatus.PURCHASING) failPurchase(store)
                }
            }
        }
        // Completing acknowledges a Play purchase (Play refunds one left unacknowledged for three days) and finishes a
        // StoreKit transaction; a pending Play purchase can't be acknowledged until it is paid.
        if (purchase.pendingComplete && (status == StorePurchaseStatus.PURCHASED || status == StorePurchaseStatus.RESTORED)) {
            complete(store, purchase)
        }
    }

    private suspend fun complete(store: SupporterStore, purchase: StorePurchase) {
        try {
            store.billing.complete(purchase)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Left incomplete, the store reports it again in its next history (Play) or transaction replay (StoreKit).
            Log.e(TAG, e) { "completing the purchase failed" }
        }
    }

    /** A purchase failed. The account may own the product already, so the history decides before the error stands. */
    private fun failPurchase(store: SupporterStore) {
        if (storeState.value.status == SupporterPurchaseStatus.PURCHASING) {
            setState { copy(status = SupporterPurchaseStatus.IDLE, error = SupporterError.PURCHASE_FAILED) }
        }
        scope.launch { refreshEntitlement(store) }
    }

    /**
     * Applies the store's history. Null when the store couldn't answer: the cached entitlement stands and [onFailure]
     * learns why.
     */
    private suspend fun refreshEntitlement(store: SupporterStore, onFailure: (SupporterError) -> Unit = {}): SupporterOwnership? {
        val generation = entitlementGeneration
        val history = try {
            store.queryHistory()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the store history is unavailable; keeping the cached entitlement" }
            onFailure(if (e is SupporterStoreUnavailable) SupporterError.STORE_UNAVAILABLE else SupporterError.RESTORE_FAILED)
            return null
        }
        if (closed) return null
        when (history.ownership) {
            SupporterOwnership.OWNED -> if (generation == entitlementGeneration) {
                setUnlocked(true)
                setState { copy(error = null) }
                clearPendingStatus()
                for (purchase in history.unfinished) complete(store, purchase)
            }
            SupporterOwnership.REVOKED -> {
                if (generation == entitlementGeneration) {
                    if (purchased) Log.i(TAG) { "the store no longer lists the purchase: it was refunded or revoked" }
                    setUnlocked(false)
                }
                clearPendingStatus()
            }
            SupporterOwnership.UNKNOWN -> clearPendingStatus()
            SupporterOwnership.PENDING -> {}
        }
        return history.ownership
    }

    private fun clearPendingStatus() {
        if (storeState.value.status == SupporterPurchaseStatus.PENDING) setState { copy(status = SupporterPurchaseStatus.IDLE) }
    }

    /** Commits a confirmed entitlement change and caches it. */
    private suspend fun setUnlocked(unlocked: Boolean) {
        if (closed || mutableUnlocked.value == unlocked) return
        mutableUnlocked.value = unlocked
        try {
            cache.write(unlocked)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "caching the entitlement failed" }
        }
    }

    private fun setState(change: SupporterStoreState.() -> SupporterStoreState) {
        if (!closed) mutableStoreState.update(change)
    }

    companion object {
        /** Whether the perks paint from the first frame: [availability]'s rule over the [cached] entitlement. */
        fun startupUnlocked(availability: SupporterAvailability, cached: Boolean): Boolean = when (availability) {
            SupporterAvailability.HIDDEN -> false
            SupporterAvailability.FREE -> true
            SupporterAvailability.PURCHASABLE -> cached
        }

        private const val TAG = "Supporter"
    }
}
