import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/app_icon/app_icon_catalog.dart';
import 'package:plezy/services/app_icon/app_icon_service.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';

import '../../test_helpers/app_icon_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAppIconPlatform platform;

  setUp(() {
    platform = FakeAppIconPlatform()..install();
    addTearDown(platform.uninstall);
  });

  AppIconService serviceFor(SupporterService supporter, {bool platformHasAlternateIcons = true}) {
    final service = AppIconService(supporter: supporter, platformHasAlternateIcons: platformHasAlternateIcons);
    addTearDown(service.dispose);
    return service;
  }

  SupporterService freeSupporter() {
    final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
    addTearDown(supporter.dispose);
    return supporter;
  }

  group('refresh', () {
    test('a device that can switch reports support and the icon its home screen shows', () async {
      platform.current = 'vhs';
      final service = serviceFor(freeSupporter());

      await service.refresh();

      expect(service.isSupported, isTrue);
      expect(service.currentId, 'vhs');
    });

    test('a launcher that cannot switch leaves the picker unsupported on the default icon', () async {
      platform.supported = false;
      final service = serviceFor(freeSupporter());

      await service.refresh();

      expect(service.isSupported, isFalse);
      expect(service.currentId, defaultAppIconId);
      expect(platform.calls, ['isSupported'], reason: 'an unsupported launcher is never asked for its icon');
    });

    test('desktop builds never ask the platform and stay unsupported', () async {
      final service = serviceFor(freeSupporter(), platformHasAlternateIcons: false);

      await service.refresh();

      expect(service.isSupported, isFalse);
      expect(platform.calls, isEmpty);
    });

    test('a platform error reads as unsupported instead of escaping', () async {
      platform.failWith = PlatformException(code: 'failed', message: 'package manager died');
      final service = serviceFor(freeSupporter());

      await service.refresh();

      expect(service.isSupported, isFalse);
    });

    test('a runner without the channel reads as unsupported', () async {
      platform.uninstall();
      final service = serviceFor(freeSupporter());

      await service.refresh();

      expect(service.isSupported, isFalse);
    });
  });

  group('setIcon', () {
    test('switches the home-screen icon and notifies listeners', () async {
      final service = serviceFor(freeSupporter());
      await service.refresh();
      var notified = 0;
      service.addListener(() => notified++);

      await service.setIcon('ember');

      expect(platform.current, 'ember');
      expect(platform.calls.last, 'setIcon:ember');
      expect(service.currentId, 'ember');
      expect(notified, 1);
    });

    test('a platform refusal surfaces its code and keeps the current icon', () async {
      platform.current = 'paper';
      final service = serviceFor(freeSupporter());
      await service.refresh();
      platform.failWith = PlatformException(code: 'unknown_icon', message: 'No app icon with id bogus');

      await expectLater(
        service.setIcon('bogus'),
        throwsA(isA<AppIconException>().having((e) => e.code, 'code', 'unknown_icon')),
      );
      expect(service.currentId, 'paper');
    });

    test('an unsupported device refuses without calling the platform', () async {
      platform.supported = false;
      final service = serviceFor(freeSupporter());
      await service.refresh();
      platform.calls.clear();

      await expectLater(
        service.setIcon('ember'),
        throwsA(isA<AppIconException>().having((e) => e.code, 'code', 'unsupported')),
      );
      expect(platform.calls, isEmpty);
    });
  });

  group('Supporter revocation', () {
    test('a confirmed revocation puts the default icon back on the home screen', () async {
      final supporter = ToggleSupporter(unlocked: true);
      addTearDown(supporter.dispose);
      platform.current = 'neon';
      final service = serviceFor(supporter);
      await service.refresh();

      supporter.unlocked = false;
      await platform.idle();

      expect(platform.current, defaultAppIconId);
      expect(service.currentId, defaultAppIconId);
    });

    test('an entitlement that was never unlocked does not touch the icon', () async {
      final supporter = ToggleSupporter(unlocked: false);
      addTearDown(supporter.dispose);
      platform.current = 'neon';
      final service = serviceFor(supporter);
      await service.refresh();
      platform.calls.clear();

      supporter.notifyAgain();
      await platform.idle();

      expect(platform.current, 'neon');
      expect(platform.calls, isEmpty);
    });

    test('unlocking keeps whatever icon the device shows', () async {
      final supporter = ToggleSupporter(unlocked: false);
      addTearDown(supporter.dispose);
      final service = serviceFor(supporter);
      await service.refresh();
      platform.calls.clear();

      supporter.unlocked = true;
      await platform.idle();

      expect(platform.calls, isEmpty);
      expect(service.currentId, defaultAppIconId);
    });
  });
}
