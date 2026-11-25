package com.edde746.plezy.supporter

/** Product ID of the one-time Supporter purchase, the same on the App Store and Google Play. */
const val SUPPORTER_PRODUCT_ID = "supporter"

/** Where one purchase on the store's purchase stream stands. */
enum class StorePurchaseStatus { PURCHASED, RESTORED, PENDING, CANCELED, ERROR }

/**
 * One purchase as the store reports it. [productId] is empty where Play reports a billing flow that failed or was
 * closed before a purchase existed. [revoked]: the store reports a refund or revocation of it (StoreKit's
 * `revocationDate`). [pendingComplete]: the store waits for the app to complete it (an unacknowledged Play purchase, an
 * unfinished StoreKit transaction). [token] is what completing it names (Play's purchase token, StoreKit's transaction
 * id).
 */
data class StorePurchase(
    val productId: String,
    val status: StorePurchaseStatus,
    val revoked: Boolean = false,
    val pendingComplete: Boolean = false,
    val token: String = "",
    val errorMessage: String? = null,
)

/** A product query's answer: the store-localized [price], or none with the store's [errorCode] (null: no error). */
data class StoreProduct(val price: String?, val errorCode: String? = null)

/** The purchases a store's purchase stream delivers, on the main thread. */
fun interface StorePurchaseListener {
    fun onPurchases(purchases: List<StorePurchase>)
}

/**
 * The device's store as the Supporter purchase uses it: buying and the purchase stream, implemented natively (Play
 * Billing, StoreKit 2). Calls come from the main thread; answers don't throw unless a method says so.
 */
interface StoreBilling {
    /** Whether the store's billing is usable now. */
    suspend fun isAvailable(): Boolean

    suspend fun queryProduct(productId: String): StoreProduct

    /** Opens the store's purchase flow; false when it would not open. The outcome arrives on the purchase stream. */
    suspend fun buy(productId: String): Boolean

    /** Acknowledges a Play purchase or finishes a StoreKit transaction. */
    suspend fun complete(purchase: StorePurchase)

    /** Starts the purchase stream; StoreKit replays unfinished transactions and Play delivers completed pending ones. */
    fun listen(listener: StorePurchaseListener)

    fun stopListening()
}

/** Google Play's billing, with Play's purchase query. */
interface PlayBilling : StoreBilling {
    /** The account's owned and pending one-time purchases. Throws when Play answers with an error. */
    suspend fun queryPastPurchases(): List<StorePurchase>
}

/** One StoreKit 2 transaction of the account's history (`Transaction.all`). */
data class StoreTransaction(val productId: String, val revoked: Boolean)

/** The App Store's billing (StoreKit 2), with the account's transaction history. */
interface AppStoreBilling : StoreBilling {
    /** `Transaction.all`'s verified transactions. */
    suspend fun transactions(): List<StoreTransaction>

    /**
     * `AppStore.sync`, which asks the user to sign in to the App Store: null when it synced, else what failed;
     * [SYNC_CANCELLED] when the user dismissed the sign-in.
     */
    suspend fun sync(): String?

    companion object {
        const val SYNC_CANCELLED = "userCancelled"
    }
}

/** What a store's purchase history says about the Supporter purchase on the signed-in store account. */
enum class SupporterOwnership {
    /** A completed purchase that has not been refunded or revoked. */
    OWNED,

    /** Only a purchase that is still waiting for payment (Play's pending payment methods). */
    PENDING,

    /** The store confirmed the account does not own it: refunded or revoked. */
    REVOKED,

    /** The store holds no record either way, so the cached entitlement stands. */
    UNKNOWN,
}

/** One answer from a store's purchase history; [unfinished]: owned purchases the store still expects completed. */
data class SupporterHistory(val ownership: SupporterOwnership, val unfinished: List<StorePurchase> = emptyList())

/** The store's billing is not usable here: no store app, no signed-in account, or an unsupported billing version. */
class SupporterStoreUnavailable : Exception("The store's billing is unavailable")

/** The user dismissed the store's sign-in during Restore Purchases. */
class SupporterRestoreCancelled : Exception("The store sign-in was cancelled")

/**
 * The store behind the Supporter purchase: [billing] buys and reports transactions; each store answers whether the
 * account still owns the purchase, refunds included, through its own history.
 */
sealed class SupporterStore(val billing: StoreBilling) {
    /**
     * The account's Supporter purchase history. Throws when the store cannot answer, [SupporterStoreUnavailable] when
     * billing itself is unavailable; a failure never means "not owned".
     */
    abstract suspend fun queryHistory(): SupporterHistory

    /** The step a user-initiated restore takes before [queryHistory]; throws [SupporterRestoreCancelled]. */
    abstract suspend fun syncForRestore()

    companion object {
        fun of(billing: StoreBilling): SupporterStore = when (billing) {
            is PlayBilling -> PlaySupporterStore(billing)
            is AppStoreBilling -> AppStoreSupporterStore(billing)
            else -> error("No Supporter store for ${billing::class.simpleName}")
        }
    }
}

/** Google Play: the history is Play Billing's purchase query, which lists owned and pending purchases. */
class PlaySupporterStore(private val play: PlayBilling) : SupporterStore(play) {
    /**
     * Play Billing answers a query on a client that never connected (no Play Store, no Google account, an unsupported
     * billing version) with an empty, error-free list, which would read as a refund: only a query on a connected
     * client confirms the product is gone.
     */
    override suspend fun queryHistory(): SupporterHistory {
        if (!play.isAvailable()) throw SupporterStoreUnavailable()
        val purchases = play.queryPastPurchases()
        if (!play.isAvailable()) throw SupporterStoreUnavailable()
        val supporter = purchases.filter { it.productId == SUPPORTER_PRODUCT_ID }
        val owned = supporter.filter { it.status == StorePurchaseStatus.PURCHASED }
        if (owned.isNotEmpty()) return SupporterHistory(SupporterOwnership.OWNED, owned.filter { it.pendingComplete })
        if (supporter.any { it.status == StorePurchaseStatus.PENDING }) return SupporterHistory(SupporterOwnership.PENDING)
        // A successful query without the product: Play removed it, so it was refunded or revoked. Play sends the app
        // no other revocation signal.
        return SupporterHistory(SupporterOwnership.REVOKED)
    }

    /** Play's purchase query already reads the account's current purchases. */
    override suspend fun syncForRestore() {}
}

/** App Store (StoreKit 2): the history is `Transaction.all`, which keeps refunded transactions with their revocation. */
class AppStoreSupporterStore(private val appStore: AppStoreBilling) : SupporterStore(appStore) {
    override suspend fun queryHistory(): SupporterHistory {
        val supporter = appStore.transactions().filter { it.productId == SUPPORTER_PRODUCT_ID }
        // No transaction is not a revocation: another Apple Account may be signed in, or the device hasn't synced.
        if (supporter.isEmpty()) return SupporterHistory(SupporterOwnership.UNKNOWN)
        if (supporter.any { !it.revoked }) return SupporterHistory(SupporterOwnership.OWNED)
        return SupporterHistory(SupporterOwnership.REVOKED)
    }

    override suspend fun syncForRestore() {
        val failure = appStore.sync() ?: return
        if (failure.contains(AppStoreBilling.SYNC_CANCELLED)) throw SupporterRestoreCancelled()
        throw IllegalStateException("The App Store sync failed: $failure")
    }
}
