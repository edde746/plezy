import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';

import '../../test_helpers/prefs.dart';

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

  group('SupporterService', () {
    test('a purchasable build restores the cached entitlement and notifies', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.supporterEntitlementCached, true);
      final service = SupporterService.forTesting(availability: SupporterAvailability.purchasable);
      var notified = 0;
      service.addListener(() => notified++);

      expect(service.isUnlocked, isFalse);
      await service.init();

      expect(service.isUnlocked, isTrue);
      expect(notified, 1);
      service.dispose();
    });

    test('a hidden build stays locked even with a cached entitlement', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.supporterEntitlementCached, true);
      final service = SupporterService.forTesting(availability: SupporterAvailability.hidden);

      await service.init();

      expect(service.isAvailable, isFalse);
      expect(service.isUnlocked, isFalse);
      service.dispose();
    });

    test('a free build is unlocked without any purchase', () async {
      final service = SupporterService.forTesting(availability: SupporterAvailability.free);
      await service.init();
      expect(service.isUnlocked, isTrue);
      service.dispose();
    });
  });
}
