import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/services/supporter/supporter_store.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/supporter_store_fakes.dart';

Future<void> _cacheEntitlement(bool value) async {
  final settings = await SettingsService.getInstance();
  await settings.write(SettingsService.supporterEntitlementCached, value);
}

Future<bool> _cachedEntitlement() async =>
    (await SettingsService.getInstance()).read(SettingsService.supporterEntitlementCached);

SupporterService _purchasable(SupporterStore store) {
  final service = SupporterService.forTesting(availability: SupporterAvailability.purchasable, store: store);
  addTearDown(service.dispose);
  return service;
}

/// Counts [SupporterService] notifications, which fire only when
/// `isUnlocked` changes.
int Function() _countNotifications(SupporterService service) {
  var count = 0;
  service.addListener(() => count++);
  return () => count;
}

/// How Play reports a billing flow that failed before a purchase existed.
PurchaseDetails _playBillingFailure() => PurchaseDetails(
  productID: '',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'google_play',
  ),
  transactionDate: null,
  status: PurchaseStatus.error,
)..error = IAPError(source: 'google_play', code: 'purchase_error', message: 'BillingResponse.error');

/// How Play reports a billing flow the user closed.
PurchaseDetails _playBillingCancel() => PurchaseDetails(
  productID: '',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'google_play',
  ),
  transactionDate: null,
  status: PurchaseStatus.canceled,
);

void main() {
  setUp(resetSharedPreferencesForTest);

  group('supporterAvailabilityFor', () {
    test('a Microsoft Store install gets the perks free; the same compile outside the Store hides them', () {
      expect(supporterAvailabilityFor(SupporterMode.msstore, isPackagedInstall: true), SupporterAvailability.free);
      expect(supporterAvailabilityFor(SupporterMode.msstore, isPackagedInstall: false), SupporterAvailability.hidden);
    });

    test('store and free builds ignore the packaged-install check', () {
      for (final packaged in [true, false]) {
        expect(
          supporterAvailabilityFor(SupporterMode.iap, isPackagedInstall: packaged),
          SupporterAvailability.purchasable,
        );
        expect(
          supporterAvailabilityFor(SupporterMode.unlocked, isPackagedInstall: packaged),
          SupporterAvailability.free,
        );
        expect(supporterAvailabilityFor(SupporterMode.off, isPackagedInstall: packaged), SupporterAvailability.hidden);
      }
    });
  });

  group('cached entitlement', () {
    test('a purchasable service is unlocked from the cache before init completes', () async {
      await _cacheEntitlement(true);
      final service = SupporterService.forTesting(availability: SupporterAvailability.purchasable);
      addTearDown(service.dispose);
      final notifications = _countNotifications(service);

      expect(service.isUnlocked, isTrue);
      await service.init();

      expect(service.isUnlocked, isTrue);
      expect(notifications(), 0);
    });

    test('init restores a cached entitlement the constructor could not read yet, and notifies', () async {
      await _cacheEntitlement(true);
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
      final service = SupporterService.forTesting(availability: SupporterAvailability.purchasable);
      addTearDown(service.dispose);
      final notifications = _countNotifications(service);

      expect(service.isUnlocked, isFalse);
      await service.init();

      expect(service.isUnlocked, isTrue);
      expect(notifications(), 1);
    });

    test('a hidden build stays locked even with a cached entitlement', () async {
      await _cacheEntitlement(true);
      final service = SupporterService.forTesting(availability: SupporterAvailability.hidden);
      addTearDown(service.dispose);

      await service.init();

      expect(service.isAvailable, isFalse);
      expect(service.isUnlocked, isFalse);
    });

    test('a free build is unlocked without any purchase', () async {
      final service = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(service.dispose);
      await service.init();
      expect(service.isUnlocked, isTrue);
    });
  });

  test('free and hidden builds never touch billing', () async {
    for (final availability in [SupporterAvailability.free, SupporterAvailability.hidden]) {
      final platform = FakeInAppPurchasePlatform();
      addTearDown(platform.close);
      final service = SupporterService.forTesting(availability: availability, store: FakePlayStore(platform).store);
      addTearDown(service.dispose);

      await service.init();
      await service.loadProduct();
      await service.purchase();
      await service.restore();
      await pumpEventQueue();

      expect(platform.billingCalls, 0, reason: '$availability');
      expect(service.isUnlocked, availability == SupporterAvailability.free);
    }
  });

  group('on Google Play', () {
    late FakeInAppPurchasePlatform platform;
    late FakePlayStore play;

    setUp(() {
      platform = FakeInAppPurchasePlatform();
      play = FakePlayStore(platform);
      addTearDown(platform.close);
    });

    test('the product loads with the store\'s localized price', () async {
      platform.product = supporterProduct(price: '3,99 €');
      final service = _purchasable(play.store);

      final load = service.loadProduct();
      expect(service.storeState.value.isLoadingProduct, isTrue);
      await load;

      final state = service.storeState.value;
      expect(state.isLoadingProduct, isFalse);
      expect(state.price, '3,99 €');
      expect(state.productError, isNull);
    });

    test('a store without the product, or one that fails the query, leaves Buy without a price', () async {
      platform.product = null;
      final missing = _purchasable(play.store);
      await missing.loadProduct();
      expect(missing.storeState.value.price, isNull);
      expect(missing.storeState.value.productError, SupporterError.productNotFound);

      final failingPlatform = FakeInAppPurchasePlatform()..productQueryError = Exception('offline');
      addTearDown(failingPlatform.close);
      final failing = _purchasable(FakePlayStore(failingPlatform).store);
      await failing.loadProduct();
      expect(failing.storeState.value.productError, SupporterError.productQueryFailed);

      // Retrying after the store recovers prices the product.
      failingPlatform.productQueryError = null;
      await failing.loadProduct();
      expect(failing.storeState.value.price, r'$3.99');
      expect(failing.storeState.value.productError, isNull);
    });

    test('a completed purchase unlocks, notifies, caches and is acknowledged', () async {
      final service = _purchasable(play.store);
      await service.init();
      final notifications = _countNotifications(service);

      await service.purchase();
      expect(platform.boughtProductIds, [supporterProductId]);
      expect(service.storeState.value.status, SupporterPurchaseStatus.purchasing);

      final purchase = playPurchase();
      platform.deliver([purchase]);
      await pumpEventQueue();

      expect(service.isUnlocked, isTrue);
      expect(notifications(), 1);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, isNull);
      expect(platform.completed, [purchase]);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('an already acknowledged purchase unlocks without acknowledging it again', () async {
      final service = _purchasable(play.store);
      await service.init();

      platform.deliver([playPurchase(acknowledged: true)]);
      await pumpEventQueue();

      expect(service.isUnlocked, isTrue);
      expect(platform.completed, isEmpty);
    });

    test('a pending purchase waits without unlocking or acknowledging, then unlocks once paid', () async {
      final service = _purchasable(play.store);
      await service.init();
      await service.purchase();

      platform.deliver([playPurchase(state: PurchaseStateWrapper.pending)]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(service.storeState.value.status, SupporterPurchaseStatus.pending);
      expect(platform.completed, isEmpty);
      expect(await _cachedEntitlement(), isFalse);

      final paid = playPurchase();
      platform.deliver([paid]);
      await pumpEventQueue();

      expect(service.isUnlocked, isTrue);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(platform.completed, [paid]);
    });

    test('a purchase still waiting for payment at startup shows as pending', () async {
      play.pastPurchases = [playPurchase(state: PurchaseStateWrapper.pending)];
      final service = _purchasable(play.store);

      await service.init();

      expect(service.isUnlocked, isFalse);
      expect(service.storeState.value.status, SupporterPurchaseStatus.pending);
    });

    test('a failed purchase reports the failure and leaves the entitlement alone', () async {
      final service = _purchasable(play.store);
      await service.init();
      final notifications = _countNotifications(service);
      await service.purchase();

      platform.deliver([_playBillingFailure()]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(notifications(), 0);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, SupporterError.purchaseFailed);
      expect(await _cachedEntitlement(), isFalse);
    });

    test('a purchase flow the store will not open reports the failure', () async {
      platform.launchesPurchase = false;
      final service = _purchasable(play.store);

      await service.purchase();
      await pumpEventQueue();

      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, SupporterError.purchaseFailed);
    });

    test('closing the store sheet returns to the offer without an error', () async {
      final service = _purchasable(play.store);
      await service.purchase();

      platform.deliver([_playBillingCancel()]);
      await pumpEventQueue();

      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, isNull);
      expect(service.isUnlocked, isFalse);
    });

    test('Restore Purchases unlocks a purchase the account owns and acknowledges it', () async {
      final service = _purchasable(play.store);
      await service.init();
      final owned = playPurchase();
      play.pastPurchases = [owned];

      await service.restore();

      expect(service.isUnlocked, isTrue);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, isNull);
      expect(platform.completed, [owned]);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('Restore Purchases with nothing to restore says so and stays locked', () async {
      final service = _purchasable(play.store);

      await service.restore();

      expect(service.isUnlocked, isFalse);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, SupporterError.nothingToRestore);
    });

    test('a failing purchase query keeps the cached unlock and Restore says the store was unreachable', () async {
      await _cacheEntitlement(true);
      play.historyError = IAPError(source: 'google_play', code: 'restore_transactions_failed', message: '3');
      final service = _purchasable(play.store);
      final notifications = _countNotifications(service);

      await service.init();
      await service.restore();

      expect(service.isUnlocked, isTrue);
      expect(notifications(), 0);
      expect(service.storeState.value.error, SupporterError.restoreFailed);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('unavailable Play Billing answering with an empty history is not a refund', () async {
      // No Google account or no Play Store: the purchase query comes back
      // empty and error-free from a client that never connected.
      await _cacheEntitlement(true);
      platform.available = false;
      final service = _purchasable(play.store);
      final notifications = _countNotifications(service);

      await service.init();
      await service.loadProduct();
      await pumpEventQueue();

      expect(service.isUnlocked, isTrue);
      expect(notifications(), 0);
      expect(service.storeState.value.productError, SupporterError.storeUnavailable);
      expect(await _cachedEntitlement(), isTrue);

      await service.restore();

      expect(service.isUnlocked, isTrue);
      expect(service.storeState.value.error, SupporterError.storeUnavailable);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('clearing the error leaves the offer without the last failure', () async {
      final service = _purchasable(play.store);
      await service.restore();
      expect(service.storeState.value.error, SupporterError.nothingToRestore);

      service.clearError();

      expect(service.storeState.value.error, isNull);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
    });

    test('a refunded purchase locks the perks, notifies and clears the cache', () async {
      await _cacheEntitlement(true);
      play.pastPurchases = [playPurchase(productId: 'some_other_product')];
      final service = _purchasable(play.store);
      final notifications = _countNotifications(service);
      expect(service.isUnlocked, isTrue);

      await service.init();
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(notifications(), 1);
      expect(await _cachedEntitlement(), isFalse);
    });

    test('a refund check that started before a purchase completed cannot revoke it', () async {
      play.historyGate = Completer<void>();
      final service = _purchasable(play.store);
      final init = service.init();
      await pumpEventQueue();
      expect(play.historyQueries, 1);

      platform.deliver([playPurchase()]);
      await pumpEventQueue();
      expect(service.isUnlocked, isTrue);

      // The query that started before the purchase answers without it.
      play.historyGate!.complete();
      await init;

      expect(service.isUnlocked, isTrue);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('other products are neither unlocked nor acknowledged', () async {
      final service = _purchasable(play.store);
      await service.init();

      platform.deliver([playPurchase(productId: 'some_other_product')]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(platform.completed, isEmpty);
    });

    test('disposing the service cancels its purchase stream subscription', () async {
      final service = SupporterService.forTesting(availability: SupporterAvailability.purchasable, store: play.store);
      await service.init();
      expect(platform.hasPurchaseListener, isTrue);

      service.dispose();

      expect(platform.hasPurchaseListener, isFalse);
    });
  });

  group('on the App Store', () {
    late FakeInAppPurchasePlatform platform;
    late FakeAppStore appStore;

    setUp(() {
      platform = FakeInAppPurchasePlatform();
      appStore = FakeAppStore(platform);
      addTearDown(platform.close);
    });

    test('a completed purchase unlocks, caches and finishes the transaction', () async {
      final service = _purchasable(appStore.store);
      await service.init();
      await service.purchase();

      final purchase = appStorePurchase();
      platform.deliver([purchase]);
      await pumpEventQueue();

      expect(service.isUnlocked, isTrue);
      expect(platform.completed, [purchase]);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('Ask to Buy waits without unlocking', () async {
      final service = _purchasable(appStore.store);
      await service.purchase();

      platform.deliver([appStorePurchase(status: PurchaseStatus.pending)]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(service.storeState.value.status, SupporterPurchaseStatus.pending);
      expect(platform.completed, isEmpty);
    });

    test('Restore Purchases syncs the Apple Account and unlocks its purchase', () async {
      final service = _purchasable(appStore.store);
      await service.init();
      appStore.transactions = [appStoreTransaction()];

      await service.restore();

      expect(appStore.syncs, 1);
      expect(service.isUnlocked, isTrue);
      expect(service.storeState.value.error, isNull);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('a store without the product reports it missing, not a connection failure', () async {
      // StoreKit 2 answers an empty product query with this error.
      platform.product = null;
      platform.productResponseError = IAPError(
        source: 'app_store',
        code: 'storekit_no_response',
        message: 'StoreKit: Failed to get response from platform.',
      );
      final service = _purchasable(appStore.store);

      await service.loadProduct();

      expect(service.storeState.value.price, isNull);
      expect(service.storeState.value.productError, SupporterError.productNotFound);
    });

    test('cancelling the Apple Account sign-in during Restore returns to the offer without an error', () async {
      appStore.syncError = PlatformException(
        code: 'storekit2_failed_to_sync_to_app_store',
        message: 'Storekit has failed to sync to the app store.',
        details: 'userCancelled',
      );
      final service = _purchasable(appStore.store);

      await service.restore();

      expect(appStore.syncs, 1);
      expect(service.storeState.value.status, SupporterPurchaseStatus.idle);
      expect(service.storeState.value.error, isNull);
      expect(service.isUnlocked, isFalse);
    });

    test('a failed Apple Account sync with no purchase in the history reports the failure', () async {
      appStore.syncError = PlatformException(
        code: 'storekit2_failed_to_sync_to_app_store',
        message: 'Storekit has failed to sync to the app store.',
        details: 'networkError',
      );
      final service = _purchasable(appStore.store);

      await service.restore();

      expect(service.storeState.value.error, SupporterError.restoreFailed);
    });

    test('an empty history keeps the cached unlock: another Apple Account may be signed in', () async {
      await _cacheEntitlement(true);
      final service = _purchasable(appStore.store);

      await service.init();

      expect(service.isUnlocked, isTrue);
      expect(await _cachedEntitlement(), isTrue);
    });

    test('a refund in the history locks the perks at startup', () async {
      await _cacheEntitlement(true);
      appStore.transactions = [appStoreTransaction(revoked: true)];
      final service = _purchasable(appStore.store);
      final notifications = _countNotifications(service);

      await service.init();
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(notifications(), 1);
      expect(await _cachedEntitlement(), isFalse);
    });

    test('a refund delivered while running locks the perks and finishes the transaction', () async {
      appStore.transactions = [appStoreTransaction()];
      final service = _purchasable(appStore.store);
      await service.init();
      expect(service.isUnlocked, isTrue);
      final notifications = _countNotifications(service);

      final refund = appStorePurchase(revoked: true);
      platform.deliver([refund]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(notifications(), 1);
      expect(platform.completed, [refund]);
      expect(await _cachedEntitlement(), isFalse);
    });

    test('other products are ignored', () async {
      appStore.transactions = [appStoreTransaction(productId: 'some_other_product')];
      final service = _purchasable(appStore.store);
      await service.init();

      platform.deliver([appStorePurchase(productId: 'some_other_product')]);
      await pumpEventQueue();

      expect(service.isUnlocked, isFalse);
      expect(platform.completed, isEmpty);
    });
  });
}
