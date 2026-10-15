import 'dart:async';
import 'dart:convert';

import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:plezy/services/supporter/supporter_store.dart';

/// An in-memory store behind in_app_purchase's platform interface. Counts
/// every billing call so a suite can prove a build never touched billing.
final class FakeInAppPurchasePlatform extends InAppPurchasePlatform {
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  /// What `isAvailable` answers.
  bool available = true;

  /// The product query's answer; null answers with an empty product list.
  ProductDetails? product = supporterProduct();

  /// Thrown by the product query when set.
  Object? productQueryError;

  /// Holds the product query open until completed, when set.
  Completer<void>? productQueryGate;

  /// The error a product query reports alongside an empty result, as StoreKit
  /// does with `storekit_no_response`.
  IAPError? productResponseError;

  /// Whether `buyNonConsumable` reports that the store opened its flow.
  bool launchesPurchase = true;

  final List<String> boughtProductIds = [];
  final List<PurchaseDetails> completed = [];
  int productQueries = 0;
  int billingCalls = 0;

  bool get hasPurchaseListener => _purchases.hasListener;

  /// Delivers a store update on the purchase stream, as the plugin does.
  void deliver(List<PurchaseDetails> purchases) => _purchases.add(purchases);

  Future<void> close() => _purchases.close();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream {
    billingCalls++;
    return _purchases.stream;
  }

  @override
  Future<bool> isAvailable() async {
    billingCalls++;
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    billingCalls++;
    productQueries++;
    await productQueryGate?.future;
    if (productQueryError case final error?) throw error;
    final product = this.product;
    return ProductDetailsResponse(
      productDetails: [?product],
      notFoundIDs: [if (product == null) ...identifiers],
      error: product == null ? productResponseError : null,
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    billingCalls++;
    boughtProductIds.add(purchaseParam.productDetails.id);
    return launchesPurchase;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    billingCalls++;
    completed.add(purchase);
  }
}

ProductDetails supporterProduct({String price = r'$3.99'}) => ProductDetails(
  id: supporterProductId,
  title: 'Supporter',
  description: 'Cosmetic extras',
  price: price,
  rawPrice: 3.99,
  currencyCode: 'USD',
);

/// Google Play behind [platform], answering the purchase query from
/// [pastPurchases], or failing with [historyError] when set.
final class FakePlayStore {
  FakePlayStore(this.platform);

  final FakeInAppPurchasePlatform platform;
  List<GooglePlayPurchaseDetails> pastPurchases = [];
  IAPError? historyError;

  /// Holds the purchase query open until completed, when set.
  Completer<void>? historyGate;
  int historyQueries = 0;

  late final SupporterStore store = PlaySupporterStore(platform, queryPastPurchases: _query);

  Future<QueryPurchaseDetailsResponse> _query() async {
    platform.billingCalls++;
    historyQueries++;
    await historyGate?.future;
    return QueryPurchaseDetailsResponse(pastPurchases: historyError == null ? pastPurchases : [], error: historyError);
  }
}

/// A Play Billing purchase as the plugin reports it.
GooglePlayPurchaseDetails playPurchase({
  String productId = supporterProductId,
  PurchaseStateWrapper state = PurchaseStateWrapper.purchased,
  bool acknowledged = false,
}) => GooglePlayPurchaseDetails.fromPurchase(
  PurchaseWrapper(
    orderId: 'GPA.0000-$productId',
    packageName: 'com.edde746.plezy',
    purchaseTime: 0,
    purchaseToken: 'token-$productId',
    signature: 'signature',
    products: [productId],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: acknowledged,
    purchaseState: state,
  ),
).single;

/// The App Store (StoreKit 2) behind [platform], answering `Transaction.all`
/// from [transactions].
final class FakeAppStore {
  FakeAppStore(this.platform);

  final FakeInAppPurchasePlatform platform;
  List<SK2Transaction> transactions = [];
  int syncs = 0;

  /// Thrown by `AppStore.sync` when set, as the plugin reports a failure.
  Object? syncError;

  late final SupporterStore store = AppStoreSupporterStore(
    platform,
    transactions: () async {
      platform.billingCalls++;
      return transactions;
    },
    sync: () async {
      platform.billingCalls++;
      syncs++;
      if (syncError case final error?) throw error;
    },
  );
}

String _transactionJson(String productId, {required bool revoked}) => jsonEncode({
  'productId': productId,
  'purchaseDate': 1767225600000,
  if (revoked) 'revocationDate': 1767312000000,
  if (revoked) 'revocationReason': 0,
});

/// A verified StoreKit 2 transaction from `Transaction.all`.
SK2Transaction appStoreTransaction({String productId = supporterProductId, bool revoked = false}) => SK2Transaction(
  id: '2000000000000001',
  originalId: '2000000000000001',
  productId: productId,
  purchaseDate: '2026-01-01T00:00:00Z',
  appAccountToken: null,
  jsonRepresentation: _transactionJson(productId, revoked: revoked),
);

/// A StoreKit 2 transaction on the purchase stream, as the plugin reports a
/// purchase or a `Transaction.updates` refund.
SK2PurchaseDetails appStorePurchase({
  String productId = supporterProductId,
  PurchaseStatus status = PurchaseStatus.purchased,
  bool revoked = false,
}) => SK2PurchaseDetails(
  productID: productId,
  purchaseID: '2000000000000001',
  verificationData: PurchaseVerificationData(
    localVerificationData: _transactionJson(productId, revoked: revoked),
    serverVerificationData: 'jws',
    source: 'app_store',
  ),
  transactionDate: '1767225600000',
  status: status,
);
