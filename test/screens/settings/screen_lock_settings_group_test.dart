import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/screen_lock_settings_group.dart';
import 'package:plezy/services/screen_lock_capabilities.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/video_controls/widgets/screen_lock_overlay.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    ScreenLockCapabilities.debugReset(loader: () async => const ScreenLockCapabilities(deviceKey: 'test-device'));
  });

  tearDown(ScreenLockCapabilities.debugReset);

  Future<void> pumpGroup(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.android),
        home: const Scaffold(body: SingleChildScrollView(child: ScreenLockSettingsGroup())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseCount(WidgetTester tester, int count) async {
    await tester.tap(find.byKey(const ValueKey('screen-lock-finger-count')));
    await tester.pumpAndSettle();
    final label = count == 1 ? '1 finger' : '$count fingers';
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<List<TestGesture>> touchArea(WidgetTester tester, int count) async {
    final area = tester.getRect(find.byKey(const ValueKey('screen-lock-test-area')));
    final touches = <TestGesture>[];
    for (var i = 0; i < count; i++) {
      final gesture = await tester.createGesture(pointer: i + 1, kind: PointerDeviceKind.touch);
      await gesture.down(area.topLeft + Offset(40.0 + i * 55, 120));
      touches.add(gesture);
    }
    await tester.pump();
    return touches;
  }

  Future<void> release(List<TestGesture> gestures) async {
    for (final gesture in gestures) {
      await gesture.up();
    }
  }

  testWidgets('duration preset persists independently of the finger count', (tester) async {
    await pumpGroup(tester);
    await tester.tap(find.text('Unlock Hold Duration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 s'));
    await tester.pumpAndSettle();

    expect(SettingsService.instance.read(SettingsService.screenLockHoldDurationMs), 3000);
    expect(SettingsService.instance.read(SettingsService.screenLockFingerCount), 1);
    expect(find.text('3 s'), findsOneWidget);
    expect(find.byType(ScreenLockOverlay), findsNothing);
  });

  testWidgets('choosing multiple fingers requires a successful hold before saving', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.screenLockHoldDurationMs, 2000);
    await pumpGroup(tester);
    await chooseCount(tester, 3);

    expect(find.byType(ScreenLockOverlay), findsOneWidget);
    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    final touches = await touchArea(tester, 2);
    await tester.pump(const Duration(seconds: 3));
    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    expect(find.byType(ScreenLockOverlay), findsOneWidget);
    await release(touches);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedDeviceKey), isEmpty);
  });

  for (final count in [3, 4, 5]) {
    testWidgets('$count-finger confirmation saves proof for this device after the full hold', (tester) async {
      final settings = SettingsService.instance;
      await settings.write(SettingsService.screenLockHoldDurationMs, 2000);
      await pumpGroup(tester);
      await chooseCount(tester, count);
      final touches = await touchArea(tester, count);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(settings.read(SettingsService.screenLockFingerCount), 1);
      await tester.pump(const Duration(milliseconds: 1));
      await release(touches);
      await tester.pumpAndSettle();

      expect(settings.read(SettingsService.screenLockFingerCount), count);
      expect(settings.read(SettingsService.screenLockVerifiedFingerCount), count);
      expect(settings.read(SettingsService.screenLockVerifiedDeviceKey), 'test-device');
      expect(find.byType(ScreenLockOverlay), findsNothing);
      expect(find.text('$count fingers'), findsOneWidget);
    });
  }

  testWidgets('one finger can be restored without a multi-touch confirmation', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.screenLockFingerCount, 3);
    await pumpGroup(tester);
    await chooseCount(tester, 1);

    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    expect(find.byType(ScreenLockOverlay), findsNothing);
  });

  testWidgets('preview uses current effective count and does not change settings', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.screenLockFingerCount, 3);
    await settings.write(SettingsService.screenLockVerifiedFingerCount, 3);
    await settings.write(SettingsService.screenLockVerifiedDeviceKey, 'test-device');
    await settings.write(SettingsService.screenLockHoldDurationMs, 1500);
    await pumpGroup(tester);
    await tester.tap(find.byKey(const ValueKey('screen-lock-preview')));
    await tester.pumpAndSettle();

    final overlay = tester.widget<ScreenLockOverlay>(find.byType(ScreenLockOverlay));
    expect(overlay.requiredFingers, 3);
    expect(overlay.holdDuration, const Duration(milliseconds: 1500));
    expect(overlay.autoHideHint, isFalse);
    final touches = await touchArea(tester, 3);
    await tester.pump(const Duration(milliseconds: 1500));
    await release(touches);
    await tester.pumpAndSettle();

    expect(settings.read(SettingsService.screenLockFingerCount), 3);
    expect(settings.read(SettingsService.screenLockHoldDurationMs), 1500);
    expect(settings.read(SettingsService.screenLockVerifiedFingerCount), 3);
  });

  testWidgets('unidentified devices cannot save unscoped multi-touch proof', (tester) async {
    ScreenLockCapabilities.debugReset(
      loader: () async => const ScreenLockCapabilities(deviceKey: 'unverified:android'),
    );
    await pumpGroup(tester);
    await tester.tap(find.byKey(const ValueKey('screen-lock-finger-count')));
    await tester.pumpAndSettle();

    expect(find.text('1 finger'), findsNWidgets(2));
    expect(find.text('2 fingers'), findsNothing);
    expect(find.text('5 fingers'), findsNothing);
  });
}
