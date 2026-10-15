import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Product ID of the one-time Supporter purchase, the same on the App Store and
/// Google Play.
const String supporterProductId = 'supporter';

/// What a store's purchase history says about the Supporter purchase on the
/// signed-in store account.
enum SupporterOwnership {
  /// A completed purchase that has not been refunded or revoked.
  owned,

  /// Only a purchase that is still waiting for payment (Play's pending payment methods).
  pending,

  /// The store confirmed the account does not own it: refunded or revoked.
  revoked,

  /// The store holds no record either way, so the cached entitlement stands.
  unknown,
}

/// One answer from a store's purchase history.
@immutable
class SupporterHistory {
  const SupporterHistory(this.ownership, {this.unfinished = const []});

  final SupporterOwnership ownership;

  /// Owned Supporter purchases the store still expects the app to complete.
  final List<PurchaseDetails> unfinished;
}

/// The store's billing service is not usable on this device: no store app,
/// no signed-in account, or an unsupported billing version.
class SupporterStoreUnavailable implements Exception {
  const SupporterStoreUnavailable();
}

/// The user dismissed the store's sign-in during Restore Purchases.
class SupporterRestoreCancelled implements Exception {
  const SupporterRestoreCancelled();
}

/// The store calls behind the Supporter purchase.
///
/// in_app_purchase's cross-store [platform] buys and reports transactions, but
/// cannot say whether the account still owns a purchase. Each store answers
/// that, including refunds and revocations, through its own history API.
abstract class SupporterStore {
  SupporterStore(this.platform);

  final InAppPurchasePlatform platform;

  /// Reads the account's Supporter purchase history from the store. Throws
  /// when the store cannot answer, [SupporterStoreUnavailable] when billing
  /// itself is unavailable; a failure never means "not owned".
  Future<SupporterHistory> queryHistory();

  /// The explicit step a user-initiated restore needs before [queryHistory].
  /// Throws [SupporterRestoreCancelled] when the user dismissed it.
  Future<void> syncForRestore();

  /// Whether a transaction on [InAppPurchasePlatform.purchaseStream] reports a
  /// refund or revocation rather than a purchase.
  bool isRevocation(PurchaseDetails purchase);

  /// The store for this device, or null where in_app_purchase has none.
  ///
  /// The first [InAppPurchase.instance] registers this OS's implementation:
  /// Google Play on Android and StoreKit 2 on iOS and macOS. tvOS reports iOS
  /// to Dart, so it gets StoreKit 2 from the plugin copy in the tvOS Runner.
  static SupporterStore? forThisDevice() {
    final os = defaultTargetPlatform;
    if (os != TargetPlatform.android && os != TargetPlatform.iOS && os != TargetPlatform.macOS) return null;
    final iap = InAppPurchase.instance;
    if (os == TargetPlatform.android) {
      return PlaySupporterStore(
        InAppPurchasePlatform.instance,
        queryPastPurchases: iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().queryPastPurchases,
      );
    }
    return AppStoreSupporterStore(
      InAppPurchasePlatform.instance,
      transactions: SK2Transaction.transactions,
      sync: AppStore().sync,
    );
  }
}

/// Google Play: the history is Play Billing's purchase query, which lists
/// owned and pending one-time purchases and drops refunded or revoked ones.
class PlaySupporterStore extends SupporterStore {
  PlaySupporterStore(super.platform, {required this._queryPastPurchases});

  final Future<QueryPurchaseDetailsResponse> Function() _queryPastPurchases;

  /// Play Billing answers a query on a client that never connected (no Play
  /// Store, no Google account, "billing API version 3 is not supported") with
  /// an empty, error-free list, which would read as a refund. Only a query on
  /// a connected client can confirm the product is gone.
  @override
  Future<SupporterHistory> queryHistory() async {
    if (!await platform.isAvailable()) throw const SupporterStoreUnavailable();
    final response = await _queryPastPurchases();
    if (!await platform.isAvailable()) throw const SupporterStoreUnavailable();
    final error = response.error;
    if (error != null) {
      throw InAppPurchaseException(source: error.source, code: error.code, message: error.message);
    }
    final supporter = response.pastPurchases.where((p) => p.productID == supporterProductId).toList();
    final owned = supporter.where((p) => p.status == PurchaseStatus.purchased).toList();
    if (owned.isNotEmpty) {
      return SupporterHistory(
        SupporterOwnership.owned,
        unfinished: [
          for (final purchase in owned)
            if (purchase.pendingCompletePurchase) purchase,
        ],
      );
    }
    if (supporter.any((p) => p.status == PurchaseStatus.pending)) {
      return const SupporterHistory(SupporterOwnership.pending);
    }
    // A successful query without the product: Play removed it, so it was
    // refunded or revoked. Play reports no other revocation signal to the app.
    return const SupporterHistory(SupporterOwnership.revoked);
  }

  /// Play's purchase query already reads the account's current purchases.
  @override
  Future<void> syncForRestore() async {}

  /// Play never reports a refund on the purchase stream; only [queryHistory]
  /// detects one.
  @override
  bool isRevocation(PurchaseDetails purchase) => false;
}

/// App Store (StoreKit 2): the history is `Transaction.all`, which keeps
/// refunded and revoked transactions with a `revocationDate`.
class AppStoreSupporterStore extends SupporterStore {
  AppStoreSupporterStore(super.platform, {required this._transactions, required this._sync});

  final Future<List<SK2Transaction>> Function() _transactions;
  final Future<void> Function() _sync;

  @override
  Future<SupporterHistory> queryHistory() async {
    final supporter = (await _transactions()).where((t) => t.productId == supporterProductId).toList();
    // No transaction is not a revocation: another Apple Account may be signed
    // in, or this device has not synced yet.
    if (supporter.isEmpty) return const SupporterHistory(SupporterOwnership.unknown);
    if (supporter.any((t) => !_jsonReportsRevocation(t.jsonRepresentation))) {
      return const SupporterHistory(SupporterOwnership.owned);
    }
    return const SupporterHistory(SupporterOwnership.revoked);
  }

  /// `AppStore.sync`, which asks the user to sign in to the App Store.
  @override
  Future<void> syncForRestore() async {
    try {
      await _sync();
    } on PlatformException catch (error) {
      // The plugin reports StoreKit's `userCancelled` in the error's text.
      if (error.code == 'storekit2_failed_to_sync_to_app_store' &&
          '${error.message} ${error.details}'.contains('userCancelled')) {
        throw const SupporterRestoreCancelled();
      }
      rethrow;
    }
  }

  /// StoreKit 2 delivers a refund or revocation through `Transaction.updates`.
  /// The plugin forwards it as a purchased transaction, so the revocation is
  /// read from the transaction's JSON (`jsonRepresentation`).
  @override
  bool isRevocation(PurchaseDetails purchase) =>
      purchase is SK2PurchaseDetails && _jsonReportsRevocation(purchase.verificationData.localVerificationData);
}

bool _jsonReportsRevocation(String? json) {
  if (json == null || json.isEmpty) return false;
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> && decoded['revocationDate'] != null;
  } on FormatException {
    return false;
  }
}
