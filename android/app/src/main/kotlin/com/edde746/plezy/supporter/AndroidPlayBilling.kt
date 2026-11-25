package com.edde746.plezy.supporter

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CompletableDeferred

/**
 * Google Play Billing behind the Supporter purchase: one client for the process, connected on first use. The purchase
 * flow needs the activity on screen ([activity]); its outcome comes back through Play's purchases listener, which
 * [listen] forwards on the main thread.
 */
internal class AndroidPlayBilling(context: Context, private val activity: () -> Activity?) : PlayBilling {
    private var listener: StorePurchaseListener? = null
    private var connecting: CompletableDeferred<Boolean>? = null
    private val details = mutableMapOf<String, ProductDetails>()

    private val client: BillingClient by lazy(LazyThreadSafetyMode.NONE) {
        BillingClient.newBuilder(context.applicationContext)
            .setListener { result, purchases -> onPurchasesUpdated(result, purchases.orEmpty()) }
            .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
            .enableAutoServiceReconnection()
            .build()
    }

    /** Connects on first use; a client that can't connect (no Play Store, no account) is not ready. */
    override suspend fun isAvailable(): Boolean {
        if (client.isReady) return true
        val pending = connecting ?: CompletableDeferred<Boolean>().also { done ->
            connecting = done
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                        Log.w(TAG) { "Play Billing is unavailable: ${result.responseCode} ${result.debugMessage}" }
                    }
                    connecting = null
                    done.complete(result.responseCode == BillingClient.BillingResponseCode.OK)
                }

                override fun onBillingServiceDisconnected() {
                    connecting = null
                    done.complete(false)
                }
            })
        }
        return pending.await() && client.isReady
    }

    override suspend fun queryProduct(productId: String): StoreProduct {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build(),
                ),
            )
            .build()
        val answer = client.queryProductDetails(params)
        if (answer.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            return StoreProduct(null, "${answer.billingResult.responseCode} ${answer.billingResult.debugMessage}")
        }
        val product = answer.productDetailsList.orEmpty().firstOrNull { it.productId == productId } ?: return StoreProduct(null)
        details[productId] = product
        return StoreProduct(product.oneTimePurchaseOfferDetails?.formattedPrice)
    }

    override suspend fun buy(productId: String): Boolean {
        val product = details[productId] ?: return false
        val activity = activity() ?: return false
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product).build()))
            .build()
        val result = client.launchBillingFlow(activity, params)
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            Log.w(TAG) { "the purchase flow didn't open: ${result.responseCode} ${result.debugMessage}" }
        }
        return result.responseCode == BillingClient.BillingResponseCode.OK
    }

    override suspend fun complete(purchase: StorePurchase) {
        val result = client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.token).build())
        check(result.responseCode == BillingClient.BillingResponseCode.OK) { "acknowledging failed: ${result.responseCode} ${result.debugMessage}" }
    }

    override fun listen(listener: StorePurchaseListener) {
        this.listener = listener
    }

    override fun stopListening() {
        listener = null
    }

    override suspend fun queryPastPurchases(): List<StorePurchase> {
        val answer = client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build())
        val result = answer.billingResult
        check(result.responseCode == BillingClient.BillingResponseCode.OK) { "the purchase query failed: ${result.responseCode} ${result.debugMessage}" }
        return answer.purchasesList.flatMap { it.toStore() }
    }

    private fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>) {
        val delivered = when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> purchases.flatMap { it.toStore() }
            // Play reports a closed or failed flow without a purchase.
            BillingClient.BillingResponseCode.USER_CANCELED -> listOf(StorePurchase("", StorePurchaseStatus.CANCELED))
            // Owned already: the history decides (the purchase failed, and its refresh finds it).
            else -> listOf(StorePurchase("", StorePurchaseStatus.ERROR, errorMessage = "${result.responseCode} ${result.debugMessage}"))
        }
        listener?.onPurchases(delivered)
    }

    private fun Purchase.toStore(): List<StorePurchase> {
        val status = when (purchaseState) {
            Purchase.PurchaseState.PURCHASED -> StorePurchaseStatus.PURCHASED
            Purchase.PurchaseState.PENDING -> StorePurchaseStatus.PENDING
            else -> return emptyList()
        }
        return products.map { StorePurchase(it, status, pendingComplete = !isAcknowledged, token = purchaseToken) }
    }

    private companion object {
        const val TAG = "PlayBilling"
    }
}
