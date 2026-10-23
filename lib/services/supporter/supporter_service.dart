import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../../mixins/disposable_change_notifier_mixin.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../settings_service.dart';
import 'supporter_mode.dart';
import 'supporter_store.dart';

/// The StoreKit plugin's error code for a product query that found nothing.
const _storeKitNoProducts = 'storekit_no_response';

/// Where a purchase or restore the user started currently stands.
enum SupporterPurchaseStatus {
  idle,

  /// The store's purchase flow is open.
  purchasing,

  /// The store accepted the purchase but is waiting on payment or on a parent
  /// (Ask to Buy). Perks unlock when the store completes it.
  pending,

  /// Restore Purchases is reading the store account.
  restoring,
}

/// Why the store could not price, sell or restore the Supporter purchase.
enum SupporterError {
  /// Purchases are not possible here: no store account, the store app is
  /// missing, or purchases are restricted on this device.
  storeUnavailable,

  /// The store answered without the Supporter product.
  productNotFound,

  /// The store could not be reached for the product and its price.
  productQueryFailed,

  /// The store reported a failed purchase.
  purchaseFailed,

  /// Restore could not read the store account.
  restoreFailed,

  /// The store account has no Supporter purchase to restore.
  nothingToRestore,
}

/// The store-facing state the Supporter sheet renders.
@immutable
class SupporterStoreState {
  const SupporterStoreState({
    this.isLoadingProduct = false,
    this.price,
    this.productError,
    this.status = SupporterPurchaseStatus.idle,
    this.error,
  });

  final bool isLoadingProduct;

  /// The store's localized price label, once the product has loaded.
  final String? price;

  /// Why [price] is unavailable after loading finished.
  final SupporterError? productError;

  final SupporterPurchaseStatus status;

  /// Why the last purchase or restore did not unlock the perks.
  final SupporterError? error;

  bool get isBusy => status == SupporterPurchaseStatus.purchasing || status == SupporterPurchaseStatus.restoring;

  SupporterStoreState copyWith({
    bool? isLoadingProduct,
    String? price,
    SupporterError? Function()? productError,
    SupporterPurchaseStatus? status,
    SupporterError? Function()? error,
  }) => SupporterStoreState(
    isLoadingProduct: isLoadingProduct ?? this.isLoadingProduct,
    price: price ?? this.price,
    productError: productError != null ? productError() : this.productError,
    status: status ?? this.status,
    error: error != null ? error() : this.error,
  );
}

/// App-lifetime owner of the Supporter entitlement, provided at the root
/// scope: a purchase belongs to the store account on this device, not to a
/// profile.
///
/// [isUnlocked] turns false only after a confirmed revocation (a refund), never
/// because the store is unreachable, so a listener may treat a true→false
/// transition as a real revocation. Listeners are notified only when
/// [isUnlocked] changes; the purchase sheet's store state is [storeState].
///
/// How each store reports a revocation:
/// - Google Play: a successful purchase query that no longer lists the
///   product, checked at startup and on Restore Purchases. Play sends the app
///   nothing when a refund happens.
/// - App Store: StoreKit 2 delivers the revoked transaction through
///   `Transaction.updates` while the app runs, and `Transaction.all` keeps it
///   with a `revocationDate` for the startup check. An empty history is not a
///   revocation, because another Apple Account may be signed in.
///
/// Known gap: the StoreKit plugin forwards a purchase StoreKit could not
/// verify (`VerificationResult.unverified`) as purchased, and that path does
/// not expose the verification result, so such a purchase unlocks. Every
/// other StoreKit path (updates, history) drops unverified transactions.
class SupporterService extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// Seeds the cached entitlement synchronously, so the first frame under the
  /// providers already renders unlocked perks. Billing starts in [init].
  SupporterService()
    : this._(
        supporterAvailabilityFor(supporterBuildMode, isPackagedInstall: PlatformDetector.isPackagedInstall()),
        // Const guard: builds other than `iap` never reach the billing plugin.
        createStore: supporterBuildMode == SupporterMode.iap ? SupporterStore.forThisDevice : null,
      );

  /// Without [purchased], seeds from the cache like the app does. [store]
  /// stands in for the device's store in purchasable tests; without one, no
  /// billing runs and purchases report [SupporterError.storeUnavailable].
  @visibleForTesting
  SupporterService.forTesting({required SupporterAvailability availability, bool? purchased, SupporterStore? store})
    : this._(availability, purchased: purchased, createStore: store == null ? null : () => store);

  SupporterService._(this.availability, {bool? purchased, this._createStore})
    : _purchased =
          purchased ??
          (availability == SupporterAvailability.purchasable &&
              (SettingsService.instanceOrNull?.read(SettingsService.supporterEntitlementCached) ?? false));

  /// Fixed for the life of the process.
  final SupporterAvailability availability;

  final SupporterStore? Function()? _createStore;
  bool _storeCreated = false;
  SupporterStore? _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;

  /// Bumped by every confirmed purchase or revocation from the purchase
  /// stream, so a history query that started earlier cannot revoke a purchase
  /// that completed while it ran.
  int _entitlementGeneration = 0;

  bool _purchased;

  final ValueNotifier<SupporterStoreState> _storeState = ValueNotifier(const SupporterStoreState());

  /// Product, purchase and restore progress for the Supporter sheet.
  ValueListenable<SupporterStoreState> get storeState => _storeState;

  /// Whether any perk UI is shown on this install.
  bool get isAvailable => availability != SupporterAvailability.hidden;

  /// Whether perks are usable right now.
  bool get isUnlocked => switch (availability) {
    SupporterAvailability.hidden => false,
    SupporterAvailability.free => true,
    SupporterAvailability.purchasable => _purchased,
  };

  /// Restores the last confirmed entitlement when the constructor could not
  /// read it, then refreshes it from the store.
  Future<void> init() async {
    if (availability != SupporterAvailability.purchasable) return;
    final settings = await SettingsService.getInstance();
    if (isDisposed) return;
    // The cache only ever raises the entitlement here; lowering it takes a
    // confirmed revocation.
    if (settings.read(SettingsService.supporterEntitlementCached) && !_purchased) {
      _purchased = true;
      safeNotifyListeners();
    }
    final store = _ensureStore();
    if (store == null) return;
    final ownership = await _refreshEntitlement(store);
    if (isDisposed) return;
    if (ownership == SupporterOwnership.pending && !_purchased && !_storeState.value.isBusy) {
      _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.pending));
    }
  }

  /// [isUnlocked] for the pre-provider startup frame, from the same build
  /// policy and entitlement cache this service starts from.
  static bool startupUnlocked(SettingsService settings) =>
      switch (supporterAvailabilityFor(supporterBuildMode, isPackagedInstall: PlatformDetector.isPackagedInstall())) {
        SupporterAvailability.hidden => false,
        SupporterAvailability.free => true,
        SupporterAvailability.purchasable => settings.read(SettingsService.supporterEntitlementCached),
      };

  /// Loads the Supporter product and its localized price, once per process.
  Future<void> loadProduct() async {
    if (availability != SupporterAvailability.purchasable) return;
    final current = _storeState.value;
    if (_product != null || current.isLoadingProduct) return;
    final store = _ensureStore();
    if (store == null) {
      _setStoreState(current.copyWith(productError: () => SupporterError.storeUnavailable));
      return;
    }
    _setStoreState(current.copyWith(isLoadingProduct: true, productError: () => null, error: () => null));
    SupporterError? failure;
    try {
      if (!await store.platform.isAvailable()) {
        failure = SupporterError.storeUnavailable;
      } else {
        final response = await store.platform.queryProductDetails({supporterProductId});
        _product = response.productDetails.firstWhereOrNull((p) => p.id == supporterProductId);
        if (_product == null) {
          // StoreKit 2 reports a query that found no product as the error
          // `storekit_no_response` rather than an empty result.
          final error = response.error;
          if (error != null && error.code != _storeKitNoProducts) {
            appLogger.w('Supporter: product query failed: ${error.code} ${error.message}');
            failure = SupporterError.productQueryFailed;
          } else {
            appLogger.w('Supporter: the store has no "$supporterProductId" product');
            failure = SupporterError.productNotFound;
          }
        }
      }
    } catch (error, stackTrace) {
      appLogger.w('Supporter: product query failed', error: error, stackTrace: stackTrace);
      failure = SupporterError.productQueryFailed;
    }
    if (isDisposed) return;
    _setStoreState(
      _storeState.value.copyWith(isLoadingProduct: false, price: _product?.price, productError: () => failure),
    );
  }

  /// Starts the store's purchase flow. The outcome arrives on the purchase
  /// stream and shows up in [storeState] and [isUnlocked].
  Future<void> purchase() async {
    if (availability != SupporterAvailability.purchasable || _purchased || _storeState.value.isBusy) return;
    final store = _ensureStore();
    if (store == null) {
      _setStoreState(_storeState.value.copyWith(error: () => SupporterError.storeUnavailable));
      return;
    }
    if (_product == null) await loadProduct();
    final product = _product;
    if (product == null || isDisposed || _storeState.value.isBusy) return;
    _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.purchasing, error: () => null));
    try {
      final launched = await store.platform.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
      if (!launched) {
        appLogger.w('Supporter: the store did not open its purchase flow');
        _failPurchase(store);
      }
    } catch (error, stackTrace) {
      appLogger.w('Supporter: purchase failed', error: error, stackTrace: stackTrace);
      _failPurchase(store);
    }
  }

  /// Restore Purchases: re-reads the store account and unlocks if it owns the
  /// Supporter purchase.
  Future<void> restore() async {
    if (availability != SupporterAvailability.purchasable || _storeState.value.isBusy) return;
    final store = _ensureStore();
    if (store == null) {
      _setStoreState(_storeState.value.copyWith(error: () => SupporterError.storeUnavailable));
      return;
    }
    _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.restoring, error: () => null));
    var synced = true;
    try {
      await store.syncForRestore();
    } on SupporterRestoreCancelled {
      if (!isDisposed) _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
      return;
    } catch (error, stackTrace) {
      // The history may still hold the purchase; only report this failure if
      // it does not.
      appLogger.w('Supporter: store sync for restore failed', error: error, stackTrace: stackTrace);
      synced = false;
    }
    if (isDisposed) return;
    var failure = SupporterError.restoreFailed;
    final ownership = await _refreshEntitlement(store, onFailure: (error) => failure = error);
    if (isDisposed) return;
    _setStoreState(switch (ownership) {
      SupporterOwnership.owned => _storeState.value.copyWith(status: SupporterPurchaseStatus.idle),
      SupporterOwnership.pending => _storeState.value.copyWith(status: SupporterPurchaseStatus.pending),
      SupporterOwnership.revoked || SupporterOwnership.unknown => _storeState.value.copyWith(
        status: SupporterPurchaseStatus.idle,
        error: () => synced ? SupporterError.nothingToRestore : SupporterError.restoreFailed,
      ),
      null => _storeState.value.copyWith(status: SupporterPurchaseStatus.idle, error: () => failure),
    });
  }

  /// Drops the last purchase or restore error, so a sheet opened later starts
  /// from the offer rather than an old failure.
  void clearError() {
    if (_storeState.value.error != null && !_storeState.value.isBusy) {
      _setStoreState(_storeState.value.copyWith(error: () => null));
    }
  }

  /// Creates the store and subscribes to its purchase stream on first use.
  /// Subscribing early matters: StoreKit replays unfinished transactions and
  /// Play delivers completed pending purchases to the first listener.
  SupporterStore? _ensureStore() {
    if (_storeCreated || isDisposed) return _store;
    _storeCreated = true;
    final SupporterStore store;
    try {
      final created = _createStore?.call();
      if (created == null) return null;
      store = created;
    } catch (error, stackTrace) {
      appLogger.e('Supporter: store setup failed', error: error, stackTrace: stackTrace);
      return null;
    }
    _store = store;
    _purchaseSubscription = store.platform.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(store, purchases)),
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('Supporter: purchase stream error', error: error, stackTrace: stackTrace);
      },
    );
    return store;
  }

  Future<void> _handlePurchases(SupporterStore store, List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (isDisposed) return;
      if (purchase.productID == supporterProductId) {
        await _handleSupporterPurchase(store, purchase);
      } else if (purchase.productID.isEmpty && _storeState.value.status == SupporterPurchaseStatus.purchasing) {
        // Play reports a cancelled or failed billing flow without a product.
        if (purchase.status == PurchaseStatus.canceled) {
          _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
        } else if (purchase.status == PurchaseStatus.error) {
          appLogger.w('Supporter: purchase failed: ${purchase.error?.code} ${purchase.error?.message}');
          _failPurchase(store);
        }
      }
      // Any other product is not Plezy's; leave it to the store.
    }
  }

  Future<void> _handleSupporterPurchase(SupporterStore store, PurchaseDetails purchase) async {
    final status = purchase.status;
    if (store.isRevocation(purchase)) {
      _entitlementGeneration++;
      appLogger.i('Supporter: the store revoked the purchase');
      _setPurchased(false);
    } else {
      switch (status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _entitlementGeneration++;
          _setPurchased(true);
          _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle, error: () => null));
        case PurchaseStatus.pending:
          if (!_purchased) {
            _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.pending, error: () => null));
          }
        case PurchaseStatus.canceled:
          if (_storeState.value.status == SupporterPurchaseStatus.purchasing) {
            _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
          }
        case PurchaseStatus.error:
          appLogger.w('Supporter: purchase failed: ${purchase.error?.code} ${purchase.error?.message}');
          if (_storeState.value.status == SupporterPurchaseStatus.purchasing) _failPurchase(store);
      }
    }
    // Completing acknowledges a Play purchase (Play refunds one left
    // unacknowledged for three days) and finishes a StoreKit transaction.
    // A pending Play purchase cannot be acknowledged until it is paid.
    if (purchase.pendingCompletePurchase && (status == PurchaseStatus.purchased || status == PurchaseStatus.restored)) {
      await _complete(store, purchase);
    }
  }

  Future<void> _complete(SupporterStore store, PurchaseDetails purchase) async {
    try {
      await store.platform.completePurchase(purchase);
    } catch (error, stackTrace) {
      // Left incomplete, the store reports it again on the next launch's
      // history refresh or transaction replay.
      appLogger.e('Supporter: completing the purchase failed', error: error, stackTrace: stackTrace);
    }
  }

  /// A purchase attempt failed. The account may already own the product (an
  /// earlier purchase on another device, or one left unfinished), so the
  /// history decides before the error stands.
  void _failPurchase(SupporterStore store) {
    if (_storeState.value.status == SupporterPurchaseStatus.purchasing) {
      _setStoreState(
        _storeState.value.copyWith(status: SupporterPurchaseStatus.idle, error: () => SupporterError.purchaseFailed),
      );
    }
    unawaited(_refreshEntitlement(store));
  }

  /// Applies the store's history. Returns null when the store could not
  /// answer, in which case the cached entitlement stands and [onFailure]
  /// learns why.
  Future<SupporterOwnership?> _refreshEntitlement(
    SupporterStore store, {
    void Function(SupporterError error)? onFailure,
  }) async {
    final generation = _entitlementGeneration;
    final SupporterHistory history;
    try {
      history = await store.queryHistory();
    } catch (error, stackTrace) {
      appLogger.w(
        'Supporter: store history unavailable; keeping the cached entitlement',
        error: error,
        stackTrace: stackTrace,
      );
      onFailure?.call(
        error is SupporterStoreUnavailable ? SupporterError.storeUnavailable : SupporterError.restoreFailed,
      );
      return null;
    }
    if (isDisposed) return null;
    switch (history.ownership) {
      case SupporterOwnership.owned:
        _setPurchased(true);
        _setStoreState(_storeState.value.copyWith(error: () => null));
        for (final purchase in history.unfinished) {
          await _complete(store, purchase);
        }
      case SupporterOwnership.revoked:
        if (generation == _entitlementGeneration) {
          if (_purchased) appLogger.i('Supporter: the store no longer lists the purchase; it was refunded or revoked');
          _setPurchased(false);
        }
        _clearPendingStatus();
      case SupporterOwnership.unknown:
        _clearPendingStatus();
      case SupporterOwnership.pending:
        break;
    }
    return history.ownership;
  }

  void _clearPendingStatus() {
    if (_storeState.value.status == SupporterPurchaseStatus.pending) {
      _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
    }
  }

  /// Commits a confirmed entitlement change and caches it.
  void _setPurchased(bool purchased) {
    if (isDisposed || _purchased == purchased) return;
    _purchased = purchased;
    unawaited(_persist(purchased));
    safeNotifyListeners();
  }

  Future<void> _persist(bool purchased) async {
    try {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.supporterEntitlementCached, purchased);
    } catch (error, stackTrace) {
      appLogger.e('Supporter: caching the entitlement failed', error: error, stackTrace: stackTrace);
    }
  }

  void _setStoreState(SupporterStoreState state) {
    if (isDisposed) return;
    _storeState.value = state;
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    _storeState.dispose();
    super.dispose();
  }
}
