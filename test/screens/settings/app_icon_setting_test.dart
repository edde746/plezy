import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/app_icon_setting.dart';
import 'package:plezy/screens/settings/appearance_settings_screen.dart';
import 'package:plezy/services/app_icon/app_icon_catalog.dart';
import 'package:plezy/services/app_icon/app_icon_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/app_icon_fakes.dart';
import '../../test_helpers/prefs.dart';

void main() {
  late FakeAppIconPlatform platform;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    platform = FakeAppIconPlatform()..install();
    addTearDown(platform.uninstall);
  });

  void useViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<AppIconService> appIconsFor(SupporterService supporter, {bool platformHasAlternateIcons = true}) async {
    final service = AppIconService(supporter: supporter, platformHasAlternateIcons: platformHasAlternateIcons);
    addTearDown(service.dispose);
    await service.refresh();
    return service;
  }

  Widget providers({required SupporterService supporter, required AppIconService appIcons, required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupporterService>.value(value: supporter),
        ChangeNotifierProvider<AppIconService>.value(value: appIcons),
      ],
      child: child,
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    required SupporterService supporter,
    required AppIconService appIcons,
    Future<void> Function(BuildContext context)? openSupporterSheet,
  }) async {
    useViewport(tester, const Size(800, 1400));
    await tester.pumpWidget(
      providers(
        supporter: supporter,
        appIcons: appIcons,
        child: MaterialApp(
          theme: monoTheme(MonoPalette.dark),
          home: Scaffold(
            body: openSupporterSheet == null
                ? const AppIconPickerSheet()
                : AppIconPickerSheet(openSupporterSheet: openSupporterSheet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tile(String id) => find.byKey(ValueKey(id));

  Matcher marked(String label, String? value) => isSemantics(label: label, value: value ?? '');

  /// The node a screen reader lands on for the tile of [id].
  SemanticsNode tileSemantics(WidgetTester tester, String id) =>
      find.semantics.byLabel(appIconById(id)!.label(t)).evaluate().single;

  /// The icon whose tile holds D-pad focus.
  String? focusedId() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return null;
    for (final option in appIconCatalog) {
      final match = find.ancestor(of: find.byElementPredicate((e) => e == focused), matching: tile(option.id));
      if (match.evaluate().isNotEmpty) return option.id;
    }
    return null;
  }

  group('Appearance entry', () {
    /// Settings > Appearance as the app shows it: pushed over Settings, below
    /// the app's input-mode tracker.
    Future<void> pumpAppearance(WidgetTester tester, SupporterService supporter, AppIconService appIcons) async {
      useViewport(tester, const Size(1000, 3000));
      final theme = ThemeProvider(supporter: supporter);
      addTearDown(theme.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        providers(
          supporter: supporter,
          appIcons: appIcons,
          child: ChangeNotifierProvider<ThemeProvider>.value(
            value: theme,
            child: InputModeTracker(
              child: MaterialApp(
                navigatorKey: navigator,
                theme: monoTheme(MonoPalette.dark),
                home: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      unawaited(
        navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const AppearanceSettingsScreen())),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a build without the Supporter perks shows no App icon row', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.hidden);
      addTearDown(supporter.dispose);
      await pumpAppearance(tester, supporter, await appIconsFor(supporter));

      expect(find.text(t.appIcon.title), findsNothing);
    });

    testWidgets('a device that cannot switch icons shows no App icon row', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      platform.supported = false;
      await pumpAppearance(tester, supporter, await appIconsFor(supporter));

      expect(find.text(t.appIcon.title), findsNothing);
    });

    testWidgets('desktop builds show no App icon row', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      await pumpAppearance(tester, supporter, await appIconsFor(supporter, platformHasAlternateIcons: false));

      expect(find.text(t.appIcon.title), findsNothing);
    });

    testWidgets('the row sits right below Theme, names the current icon and opens the picker', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      platform.current = 'vhs';
      await pumpAppearance(tester, supporter, await appIconsFor(supporter));

      final row = find.text(t.appIcon.title);
      expect(row, findsOneWidget);
      expect(find.text(t.appIcon.names.vhs), findsOneWidget);
      final themeRow = tester.getRect(find.text(t.settings.theme));
      final iconRow = tester.getRect(row);
      expect(iconRow.top, greaterThan(themeRow.top));
      expect(iconRow.top - themeRow.top, lessThan(themeRow.height * 6), reason: 'directly below Theme');

      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(AppIconPickerSheet), findsOneWidget);
    });

    testWidgets('on TV the picker is a hosted sheet that starts D-pad focus in the grid and closes on Back', (
      tester,
    ) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      addTearDown(() {
        TvDetectionService.debugSetAppleTVOverride(null);
        PlatformDetector.debugSetIsDesktopOSOverride(null);
        BackKeyCoordinator.clear();
      });
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      await pumpAppearance(tester, supporter, await appIconsFor(supporter));

      // A remote arrow puts the app in D-pad mode; Select on the row opens the picker.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      Focus.of(tester.element(find.text(t.appIcon.title))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final picker = find.byType(AppIconPickerSheet);
      expect(picker, findsOneWidget);
      expect(find.ancestor(of: picker, matching: find.byType(OverlaySheetHost)), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing, reason: 'not the modal fallback');
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints == const BoxConstraints.tightFor(width: 32, height: 4),
        ),
        findsNothing,
        reason: 'no drag handle on TV',
      );
      expect(focusedId(), defaultAppIconId);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focusedId(), appIconCatalog[1].id, reason: 'the first RIGHT already moves along the grid');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);
      // Android TV can also dispatch a route Back for the same press.
      await tester.binding.handlePopRoute();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pumpAndSettle();

      expect(picker, findsNothing);
      expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
    });
  });

  group('picker', () {
    testWidgets('the default comes first and the current icon is marked', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      platform.current = 'gold';
      await pumpPicker(tester, supporter: supporter, appIcons: await appIconsFor(supporter));

      final first = tester.getTopLeft(tile(defaultAppIconId));
      for (final option in appIconCatalog.skip(1)) {
        final other = tester.getTopLeft(tile(option.id));
        expect(other.dy > first.dy || (other.dy == first.dy && other.dx > first.dx), isTrue, reason: option.id);
      }
      expect(tileSemantics(tester, 'gold'), marked(t.appIcon.names.gold, t.appIcon.current));
      expect(tileSemantics(tester, defaultAppIconId), marked(t.appIcon.defaultIcon, null));
      expect(tileSemantics(tester, 'ember'), marked(t.appIcon.names.ember, null));
      expect(find.text(t.appIcon.lockedHint), findsNothing);
    });

    testWidgets('a free build switches straight to the chosen icon', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      var sheetOpened = false;
      await pumpPicker(
        tester,
        supporter: supporter,
        appIcons: await appIconsFor(supporter),
        openSupporterSheet: (_) async => sheetOpened = true,
      );

      await tester.tap(tile('ember'));
      await tester.pumpAndSettle();

      expect(sheetOpened, isFalse);
      expect(platform.current, 'ember');
      expect(tileSemantics(tester, 'ember'), marked(t.appIcon.names.ember, t.appIcon.current));
      expect(tileSemantics(tester, defaultAppIconId), marked(t.appIcon.defaultIcon, null));
    });

    testWidgets('locked alternates carry a lock and a declined Supporter sheet changes nothing', (tester) async {
      final supporter = ToggleSupporter(unlocked: false);
      addTearDown(supporter.dispose);
      var sheetOpened = 0;
      await pumpPicker(
        tester,
        supporter: supporter,
        appIcons: await appIconsFor(supporter),
        openSupporterSheet: (_) async => sheetOpened++,
      );

      expect(find.text(t.appIcon.lockedHint), findsOneWidget);
      expect(tileSemantics(tester, 'ember'), marked(t.appIcon.names.ember, t.appIcon.locked));
      expect(tileSemantics(tester, defaultAppIconId), marked(t.appIcon.defaultIcon, t.appIcon.current));

      await tester.tap(tile('ember'));
      await tester.pumpAndSettle();

      expect(sheetOpened, 1);
      expect(platform.calls.where((call) => call.startsWith('setIcon')), isEmpty);
      expect(tileSemantics(tester, defaultAppIconId), marked(t.appIcon.defaultIcon, t.appIcon.current));
    });

    testWidgets('a purchase in the Supporter sheet applies the locked icon that opened it', (tester) async {
      final supporter = ToggleSupporter(unlocked: false);
      addTearDown(supporter.dispose);
      await pumpPicker(
        tester,
        supporter: supporter,
        appIcons: await appIconsFor(supporter),
        openSupporterSheet: (_) async => supporter.unlocked = true,
      );

      await tester.tap(tile('neon'));
      await tester.pumpAndSettle();

      expect(platform.current, 'neon');
      expect(find.text(t.appIcon.lockedHint), findsNothing);
      expect(tileSemantics(tester, 'neon'), marked(t.appIcon.names.neon, t.appIcon.current));
      expect(tileSemantics(tester, 'ember'), marked(t.appIcon.names.ember, null));
    });

    testWidgets('a locked build can always go back to the default icon without the sheet', (tester) async {
      final supporter = ToggleSupporter(unlocked: false);
      addTearDown(supporter.dispose);
      platform.current = 'neon';
      var sheetOpened = false;
      await pumpPicker(
        tester,
        supporter: supporter,
        appIcons: await appIconsFor(supporter),
        openSupporterSheet: (_) async => sheetOpened = true,
      );

      await tester.tap(tile(defaultAppIconId));
      await tester.pumpAndSettle();

      expect(sheetOpened, isFalse);
      expect(platform.current, defaultAppIconId);
    });

    testWidgets('a refused switch reports it and keeps the current icon', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      final appIcons = await appIconsFor(supporter);
      await pumpPicker(tester, supporter: supporter, appIcons: appIcons);
      platform.failWith = PlatformException(code: 'failed', message: 'launcher said no');

      await tester.tap(tile('ember'));
      await tester.pump();

      expect(find.text(t.appIcon.changeFailed), findsOneWidget);
      expect(tileSemantics(tester, defaultAppIconId), marked(t.appIcon.defaultIcon, t.appIcon.current));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    group('the Default tile looks like the default icon on the home screen', () {
      Future<void> pumpDefault(WidgetTester tester) async {
        final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
        addTearDown(supporter.dispose);
        await pumpPicker(tester, supporter: supporter, appIcons: await appIconsFor(supporter));
      }

      Finder defaultLogo() => find.descendant(of: tile(defaultAppIconId), matching: find.byType(SvgPicture));

      Color plate(WidgetTester tester) =>
          tester.widget<ColoredBox>(find.ancestor(of: defaultLogo(), matching: find.byType(ColoredBox)).first).color;

      testWidgets('on TV: the dark TV artwork', (tester) async {
        TvDetectionService.debugSetAppleTVOverride(true);
        addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
        await pumpDefault(tester);

        final image = tester.widget<Image>(find.descendant(of: tile(defaultAppIconId), matching: find.byType(Image)));
        expect((image.image as AssetImage).assetName, defaultAppIconTvosPreview);
        expect(defaultLogo(), findsNothing);
      });

      testWidgets('on Android phones: white, or #1A1A1A in night mode', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await pumpDefault(tester);
          expect(plate(tester), const Color(0xFFFFFFFF));

          tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          await tester.pump();
          expect(plate(tester), const Color(0xFF1A1A1A));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('on iOS: the light plate, also in dark mode', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          await pumpDefault(tester);
          expect(plate(tester), const Color(0xFFF1F1F1));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    testWidgets('D-pad moves through the grid by row and column and Select applies the icon', (tester) async {
      final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
      addTearDown(supporter.dispose);
      await pumpPicker(tester, supporter: supporter, appIcons: await appIconsFor(supporter));

      final firstFocus = find.descendant(of: tile(defaultAppIconId), matching: find.byType(Focus)).first;
      Focus.of(tester.element(find.descendant(of: firstFocus, matching: find.byType(Column)).first)).requestFocus();
      await tester.pumpAndSettle();
      expect(focusedId(), defaultAppIconId);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focusedId(), appIconCatalog[1].id);

      final before = tester.getCenter(tile(focusedId()!));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final below = focusedId()!;
      final after = tester.getCenter(tile(below));
      expect(after.dy, greaterThan(before.dy), reason: 'Down moves to the next row');
      expect(after.dx, closeTo(before.dx, 1), reason: 'Down keeps the column');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      final left = focusedId()!;
      expect(tester.getCenter(tile(left)).dx, lessThan(after.dx));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(platform.current, left);
    });
  });
}
