import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart' as openiap;
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../../mixins/disposable_change_notifier_mixin.dart';
import '../../utils/app_logger.dart';
import '../settings_service.dart';
import 'amazon_supporter_store.dart';
import 'supporter_mode.dart';
import 'supporter_store.dart';

/// The StoreKit plugin's error code for a product query that found nothing.
const _storeKitNoProducts = 'storekit_no_response';
const _amazonStoreBuild = bool.fromEnvironment('AMAZON_STORE');

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

/// Why the store could not price, sell or restore the lifetime unlock.
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

  /// The store account has no lifetime unlock to restore.
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

/// App-lifetime owner of the lifetime access entitlement, provided at the root
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
  static const fullAccessTrialDuration = Duration(days: 7);

  /// Seeds the cached entitlement synchronously, so the first frame under the
  /// providers already renders unlocked perks. Billing starts in [init].
  SupporterService()
    : this._(
        supporterAvailabilityFor(supporterBuildMode),
        // Const guard: builds other than `iap` never reach the billing plugin.
        createStore: supporterBuildMode == SupporterMode.iap && !_amazonStoreBuild
            ? SupporterStore.forThisDevice
            : null,
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
              (SettingsService.instanceOrNull?.read(SettingsService.supporterEntitlementCached) ?? false)),
      _trialStartedAtEpochMs =
          SettingsService.instanceOrNull?.read(SettingsService.appAccessTrialStartedAtEpochMs) ?? 0;

  /// Fixed for the life of the process.
  final SupporterAvailability availability;

  final SupporterStore? Function()? _createStore;
  bool _storeCreated = false;
  SupporterStore? _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  AmazonSupporterStore? _amazonStore;
  StreamSubscription<openiap.Purchase>? _amazonPurchaseSubscription;
  StreamSubscription<openiap.PurchaseError>? _amazonErrorSubscription;
  ProductDetails? _product;
  openiap.Product? _amazonProduct;
  int _trialStartedAtEpochMs;
  Timer? _trialExpiryTimer;
  bool _ready = false;

  /// Bumped by every confirmed purchase or revocation from the purchase
  /// stream, so a history query that started earlier cannot revoke a purchase
  /// that completed while it ran.
  int _entitlementGeneration = 0;

  bool _purchased;

  final ValueNotifier<SupporterStoreState> _storeState = ValueNotifier(const SupporterStoreState());

  /// Product, trial, purchase and restore progress for app access.
  ValueListenable<SupporterStoreState> get storeState => _storeState;

  bool get isReady => _ready;

  bool get hasLifetimeUnlock => _purchased;

  bool get hasStartedTrial => _trialStartedAtEpochMs > 0;

  DateTime? get trialEndsAt => hasStartedTrial
      ? DateTime.fromMillisecondsSinceEpoch(_trialStartedAtEpochMs, isUtc: true).add(fullAccessTrialDuration)
      : null;

  bool get isTrialActive {
    final end = trialEndsAt;
    return end != null && DateTime.now().toUtc().isBefore(end);
  }

  Duration? get trialRemaining {
    final end = trialEndsAt;
    if (end == null) return null;
    final remaining = end.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get hasAccess => availability != SupporterAvailability.purchasable || _purchased || isTrialActive;

  bool get shouldOfferTrial => availability == SupporterAvailability.purchasable && !_purchased && !hasStartedTrial;

  bool get canStartTrial => shouldOfferTrial;

  bool get _lifetimeProductLoaded => _amazonStoreBuild ? _amazonProduct != null : _product != null;

  /// Whether any perk UI is shown on this install.
  bool get isAvailable => availability != SupporterAvailability.hidden;

  /// Whether entitlement-controlled presentation is usable right now.
  bool get isUnlocked => switch (availability) {
    SupporterAvailability.hidden => true,
    SupporterAvailability.free => true,
    SupporterAvailability.purchasable => _purchased || isTrialActive,
  };

  /// Starts a fresh trial automatically, then refreshes lifetime ownership.
  Future<void> init() async {
    if (availability != SupporterAvailability.purchasable) {
      _ready = true;
      safeNotifyListeners();
      return;
    }
    try {
      final settings = await SettingsService.getInstance();
      if (isDisposed) return;
      // The cache only ever raises a lifetime entitlement here; lowering it
      // takes a confirmed revocation.
      if (settings.read(SettingsService.supporterEntitlementCached) && !_purchased) _purchased = true;
      _trialStartedAtEpochMs = settings.read(SettingsService.appAccessTrialStartedAtEpochMs);
      _scheduleTrialExpiry();
      safeNotifyListeners();

      // A free trial should let people use the app immediately. Starting it
      // here keeps the first-launch path full access without a paywall choice.
      if (!_purchased && !hasStartedTrial) await startTrial();

      if (_amazonStoreBuild) {
        final store = _ensureAmazonStore();
        if (store != null) {
          await store.initialize();
          if (isDisposed) return;
          final ownership = await _refreshAmazonEntitlement(store);
          if (ownership == SupporterOwnership.pending && !_purchased && !_storeState.value.isBusy) {
            _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.pending));
          }
        }
      } else {
        final store = _ensureStore();
        if (store != null) {
          final ownership = await _refreshEntitlement(store);
          if (isDisposed) return;
          if (ownership == SupporterOwnership.pending && !_purchased && !_storeState.value.isBusy) {
            _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.pending));
          }
        }
      }
    } catch (error, stackTrace) {
      appLogger.w('PlezyNG access initialization failed', error: error, stackTrace: stackTrace);
    } finally {
      if (!isDisposed) {
        _ready = true;
        safeNotifyListeners();
      }
    }
  }

  /// [isUnlocked] for the pre-provider startup frame, from the same build
  /// policy and entitlement cache this service starts from.
  static bool startupUnlocked(SettingsService settings) => switch (supporterAvailabilityFor(supporterBuildMode)) {
    SupporterAvailability.hidden => true,
    SupporterAvailability.free => true,
    SupporterAvailability.purchasable =>
      settings.read(SettingsService.supporterEntitlementCached) ||
          _trialIsActive(settings.read(SettingsService.appAccessTrialStartedAtEpochMs)),
  };

  static bool _trialIsActive(int startedAtEpochMs) =>
      startedAtEpochMs > 0 &&
      DateTime.now().toUtc().isBefore(
        DateTime.fromMillisecondsSinceEpoch(startedAtEpochMs, isUtc: true).add(fullAccessTrialDuration),
      );

  Future<bool> startTrial() async {
    if (!canStartTrial) return false;
    final startedAtEpochMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    try {
      final settings = await SettingsService.getInstance();
      if (isDisposed || !canStartTrial) return false;
      await settings.write(SettingsService.appAccessTrialStartedAtEpochMs, startedAtEpochMs);
      _trialStartedAtEpochMs = startedAtEpochMs;
      _scheduleTrialExpiry();
      safeNotifyListeners();
      return true;
    } catch (error, stackTrace) {
      appLogger.e('PlezyNG trial start could not be saved', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  void _scheduleTrialExpiry() {
    _trialExpiryTimer?.cancel();
    final remaining = trialRemaining;
    if (remaining == null || remaining == Duration.zero || _purchased) return;
    _trialExpiryTimer = Timer(remaining, safeNotifyListeners);
  }

  /// Loads the lifetime unlock product and its localized price, once per process.
  Future<void> loadProduct() async {
    if (availability != SupporterAvailability.purchasable) return;
    final current = _storeState.value;
    if (_lifetimeProductLoaded || current.isLoadingProduct) return;
    if (_amazonStoreBuild) {
      final amazonStore = _ensureAmazonStore();
      if (amazonStore == null) {
        _setStoreState(current.copyWith(productError: () => SupporterError.storeUnavailable));
        return;
      }
      _setStoreState(current.copyWith(isLoadingProduct: true, productError: () => null, error: () => null));
      SupporterError? failure;
      try {
        final products = await amazonStore.queryProducts({lifetimeUnlockProductId});
        _amazonProduct = products.firstWhereOrNull((product) => product.id == lifetimeUnlockProductId);
        if (_amazonProduct == null) {
          appLogger.w('PlezyNG: Amazon Appstore has no "$lifetimeUnlockProductId" product');
          failure = SupporterError.productNotFound;
        }
      } catch (error, stackTrace) {
        appLogger.w('PlezyNG: Amazon Appstore product query failed', error: error, stackTrace: stackTrace);
        failure = error is StateError ? SupporterError.storeUnavailable : SupporterError.productQueryFailed;
      }
      if (isDisposed) return;
      _setStoreState(
        _storeState.value.copyWith(
          isLoadingProduct: false,
          price: _amazonProduct?.displayPrice,
          productError: () => failure,
        ),
      );
      return;
    }
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
        final productIds = {lifetimeUnlockProductId};
        final response = await store.platform.queryProductDetails(productIds);
        _product = response.productDetails.firstWhereOrNull((p) => p.id == lifetimeUnlockProductId);
        if (_product == null) {
          // StoreKit 2 reports a query that found no product as the error
          // `storekit_no_response` rather than an empty result.
          final error = response.error;
          if (error != null && error.code != _storeKitNoProducts) {
            appLogger.w('PlezyNG access: product query failed: ${error.code} ${error.message}');
            failure = SupporterError.productQueryFailed;
          } else {
            appLogger.w('PlezyNG: the store has no "$lifetimeUnlockProductId" product');
            failure = SupporterError.productNotFound;
          }
        }
      }
    } catch (error, stackTrace) {
      appLogger.w('PlezyNG access: product query failed', error: error, stackTrace: stackTrace);
      failure = SupporterError.productQueryFailed;
    }
    if (isDisposed) return;
    _setStoreState(
      _storeState.value.copyWith(isLoadingProduct: false, price: _product?.price, productError: () => failure),
    );
  }

  /// Starts the lifetime purchase flow. The outcome arrives on the purchase
  /// stream and shows up in [storeState] and [hasLifetimeUnlock].
  Future<void> purchase() async {
    if (availability != SupporterAvailability.purchasable || _purchased || _storeState.value.isBusy) return;
    if (_amazonStoreBuild) {
      await _startAmazonPurchase();
      return;
    }
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
        appLogger.w('PlezyNG access: the store did not open its purchase flow');
        _failPurchase(store);
      }
    } catch (error, stackTrace) {
      appLogger.w('PlezyNG access: purchase failed', error: error, stackTrace: stackTrace);
      _failPurchase(store);
    }
  }

  /// Restore Purchases: re-reads the store account's lifetime unlock.
  Future<void> restore() async {
    if (availability != SupporterAvailability.purchasable || _storeState.value.isBusy) return;
    if (_amazonStoreBuild) {
      await _restoreAmazonPurchases();
      return;
    }
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
    if (_amazonStoreBuild || _storeCreated || isDisposed) return _store;
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

  AmazonSupporterStore? _ensureAmazonStore() {
    if (!_amazonStoreBuild || isDisposed) return null;
    final current = _amazonStore;
    if (current != null) return current;
    final store = AmazonSupporterStore();
    _amazonStore = store;
    _amazonPurchaseSubscription = store.purchases.listen(
      (purchase) => unawaited(_handleAmazonPurchase(store, purchase)),
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('PlezyNG: Amazon Appstore purchase stream error', error: error, stackTrace: stackTrace);
      },
    );
    _amazonErrorSubscription = store.purchaseErrors.listen(
      (error) => _handleAmazonPurchaseError(store, error),
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('PlezyNG: Amazon Appstore purchase error stream failed', error: error, stackTrace: stackTrace);
      },
    );
    return store;
  }

  Future<bool> _startAmazonPurchase() async {
    final store = _ensureAmazonStore();
    if (store == null) {
      _setStoreState(_storeState.value.copyWith(error: () => SupporterError.storeUnavailable));
      return false;
    }
    if (!_lifetimeProductLoaded) await loadProduct();
    if (_amazonProduct == null || isDisposed) {
      _setStoreState(_storeState.value.copyWith(error: () => SupporterError.productNotFound));
      return false;
    }
    _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.purchasing, error: () => null));
    try {
      await store.purchase(lifetimeUnlockProductId);
      return true;
    } catch (error, stackTrace) {
      appLogger.w('PlezyNG: Amazon Appstore purchase could not start', error: error, stackTrace: stackTrace);
      _failAmazonPurchase(store);
      return false;
    }
  }

  Future<void> _restoreAmazonPurchases() async {
    final store = _ensureAmazonStore();
    if (store == null) {
      _setStoreState(_storeState.value.copyWith(error: () => SupporterError.storeUnavailable));
      return;
    }
    _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.restoring, error: () => null));
    var synced = true;
    try {
      await store.syncForRestore();
    } catch (error, stackTrace) {
      appLogger.w('PlezyNG: Amazon restore sync failed', error: error, stackTrace: stackTrace);
      synced = false;
    }
    if (isDisposed) return;
    var failure = SupporterError.restoreFailed;
    final ownership = await _refreshAmazonEntitlement(store, onFailure: (error) => failure = error);
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

  Future<SupporterOwnership?> _refreshAmazonEntitlement(
    AmazonSupporterStore store, {
    void Function(SupporterError error)? onFailure,
  }) async {
    final generation = _entitlementGeneration;
    try {
      final purchases = await store.queryHistory();
      if (isDisposed) return null;
      final amazonPurchases = purchases.where(_isAmazonPurchase).toList();
      final lifetimePurchases = amazonPurchases.where((purchase) => purchase.productId == lifetimeUnlockProductId);
      if (lifetimePurchases.any((purchase) => purchase.purchaseState == openiap.PurchaseState.Purchased)) {
        _setPurchased(true);
        _setStoreState(_storeState.value.copyWith(error: () => null));
        return SupporterOwnership.owned;
      }
      if (lifetimePurchases.any((purchase) => purchase.purchaseState == openiap.PurchaseState.Pending)) {
        return SupporterOwnership.pending;
      }
      if (generation == _entitlementGeneration) {
        if (_purchased) appLogger.i('PlezyNG: Amazon no longer reports the lifetime entitlement');
        _setPurchased(false);
      }
      _clearPendingStatus();
      return SupporterOwnership.revoked;
    } catch (error, stackTrace) {
      appLogger.w(
        'PlezyNG: Amazon purchase history unavailable; keeping the cached entitlement',
        error: error,
        stackTrace: stackTrace,
      );
      onFailure?.call(SupporterError.restoreFailed);
      return null;
    }
  }

  bool _isAmazonPurchase(openiap.Purchase purchase) =>
      purchase.store == openiap.IapStore.Amazon || purchase.storeId == 'amazon';

  Future<void> _handleAmazonPurchase(AmazonSupporterStore store, openiap.Purchase purchase) async {
    if (!_isAmazonPurchase(purchase)) return;
    if (purchase.purchaseState == openiap.PurchaseState.Pending) {
      _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.pending, error: () => null));
      return;
    }
    if (purchase.purchaseState != openiap.PurchaseState.Purchased) {
      _failAmazonPurchase(store);
      return;
    }
    switch (purchase.productId) {
      case lifetimeUnlockProductId:
        _entitlementGeneration++;
        _setPurchased(true);
        _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle, error: () => null));
      default:
        return;
    }
    try {
      await store.finish(purchase);
    } catch (error, stackTrace) {
      appLogger.e('PlezyNG: Amazon transaction fulfillment failed', error: error, stackTrace: stackTrace);
    }
  }

  void _handleAmazonPurchaseError(AmazonSupporterStore store, openiap.PurchaseError error) {
    if (error.code == openiap.ErrorCode.UserCancelled) {
      if (_storeState.value.status == SupporterPurchaseStatus.purchasing) {
        _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
      }
      return;
    }
    appLogger.w('PlezyNG: Amazon Appstore purchase failed: ${error.code} ${error.message}');
    _failAmazonPurchase(store);
  }

  void _failAmazonPurchase(AmazonSupporterStore store) {
    if (_storeState.value.status == SupporterPurchaseStatus.purchasing) {
      _setStoreState(
        _storeState.value.copyWith(status: SupporterPurchaseStatus.idle, error: () => SupporterError.purchaseFailed),
      );
    }
    unawaited(_refreshAmazonEntitlement(store));
  }

  Future<void> _handlePurchases(SupporterStore store, List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (isDisposed) return;
      if (purchase.productID == lifetimeUnlockProductId) {
        await _handleLifetimeUnlockPurchase(store, purchase);
      } else if (purchase.productID.isEmpty && _storeState.value.status == SupporterPurchaseStatus.purchasing) {
        // Play reports a cancelled or failed billing flow without a product.
        if (purchase.status == PurchaseStatus.canceled) {
          _setStoreState(_storeState.value.copyWith(status: SupporterPurchaseStatus.idle));
        } else if (purchase.status == PurchaseStatus.error) {
          appLogger.w('Supporter: purchase failed: ${purchase.error?.code} ${purchase.error?.message}');
          _failPurchase(store);
        }
      }
      // Any other product is not PlezyNG's; leave it to the store.
    }
  }

  Future<void> _handleLifetimeUnlockPurchase(SupporterStore store, PurchaseDetails purchase) async {
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
    if (purchased) _trialExpiryTimer?.cancel();
    safeNotifyListeners();
  }

  Future<void> _persist(bool purchased) async {
    try {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.supporterEntitlementCached, purchased);
    } catch (error, stackTrace) {
      appLogger.e('PlezyNG access: caching the lifetime unlock failed', error: error, stackTrace: stackTrace);
    }
  }

  void _setStoreState(SupporterStoreState state) {
    if (isDisposed) return;
    _storeState.value = state;
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    unawaited(_amazonPurchaseSubscription?.cancel());
    unawaited(_amazonErrorSubscription?.cancel());
    unawaited(_amazonStore?.dispose());
    _trialExpiryTimer?.cancel();
    _storeState.dispose();
    super.dispose();
  }
}
