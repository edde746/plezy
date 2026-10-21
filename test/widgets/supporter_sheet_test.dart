import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/supporter_settings_tile.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/supporter_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/supporter_store_fakes.dart';

final class _Harness {
  _Harness({SupporterAvailability availability = SupporterAvailability.purchasable, bool purchased = false}) {
    platform = FakeInAppPurchasePlatform();
    play = FakePlayStore(platform);
    service = SupporterService.forTesting(availability: availability, purchased: purchased, store: play.store);
  }

  late final FakeInAppPurchasePlatform platform;
  late final FakePlayStore play;
  late final SupporterService service;
  final _openerKey = GlobalKey();

  Future<void> pump(WidgetTester tester, {Widget? body}) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<SupporterService>.value(
            value: service,
            child: MaterialApp(
              theme: monoTheme(MonoPalette.dark),
              home: OverlaySheetHost(
                child: Scaffold(
                  body: Center(child: body ?? SizedBox(key: _openerKey, width: 10, height: 10)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the sheet the way a locked perk does. A loading price spins, so
  /// [settle] is off while the product query is held open.
  Future<void> open(WidgetTester tester, {bool settle = true}) async {
    unawaited(showSupporterSheet(_openerKey.currentContext!));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> dispose() async {
    service.dispose();
    await platform.close();
  }
}

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

bool _enabled(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(_button(label)).enabled;

String? _focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows the perks and the store price, and Buy starts the purchase', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.platform.productQueryGate = Completer<void>();
    await harness.pump(tester);

    await harness.open(tester, settle: false);

    expect(find.text(t.supporter.title), findsOneWidget);
    expect(find.text(t.supporter.presetThemes), findsOneWidget);
    expect(find.text(t.supporter.customTheme), findsOneWidget);
    expect(find.text(t.supporter.appIcons), findsOneWidget);
    expect(_enabled(tester, t.supporter.loadingPrice), isFalse);
    expect(_enabled(tester, t.supporter.restore), isTrue);

    harness.platform.productQueryGate!.complete();
    await tester.pumpAndSettle();

    final buy = t.supporter.buy(price: r'$3.99');
    expect(_enabled(tester, buy), isTrue);
    await tester.tap(find.text(buy));
    await tester.pump();

    expect(harness.platform.boughtProductIds, ['supporter']);
    expect(_enabled(tester, buy), isFalse);
    expect(_enabled(tester, t.supporter.restore), isFalse);
  });

  testWidgets('platforms without alternate app icons do not offer them', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.pump(tester);

    await harness.open(tester);

    expect(find.text(t.supporter.presetThemes), findsOneWidget);
    expect(find.text(t.supporter.appIcons), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('an unavailable price explains why and Retry loads it', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.platform.productQueryError = Exception('offline');
    await harness.pump(tester);

    await harness.open(tester);

    expect(find.text(t.supporter.errors.productQueryFailed), findsOneWidget);
    expect(find.text(t.supporter.loadingPrice), findsNothing);

    harness.platform.productQueryError = null;
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.errors.productQueryFailed), findsNothing);
    expect(_enabled(tester, t.supporter.buy(price: r'$3.99')), isTrue);
  });

  testWidgets('a pending purchase says so and holds Buy until the store completes it', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.open(tester);
    final buy = t.supporter.buy(price: r'$3.99');

    await tester.tap(find.text(buy));
    await tester.pump();
    harness.platform.deliver([playPurchase(state: PurchaseStateWrapper.pending)]);
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.pending), findsOneWidget);
    expect(_enabled(tester, buy), isFalse);
    expect(_enabled(tester, t.supporter.restore), isTrue);

    harness.platform.deliver([playPurchase()]);
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.thankYouTitle), findsOneWidget);
    expect(find.text(t.supporter.pending), findsNothing);
  });

  testWidgets('a failed purchase shows the error and Buy works again', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.platform.launchesPurchase = false;
    await harness.pump(tester);
    await harness.open(tester);
    final buy = t.supporter.buy(price: r'$3.99');

    await tester.tap(find.text(buy));
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.errors.purchaseFailed), findsOneWidget);
    expect(_enabled(tester, buy), isTrue);

    harness.platform.launchesPurchase = true;
    await tester.tap(find.text(buy));
    await tester.pump();

    expect(find.text(t.supporter.errors.purchaseFailed), findsNothing);
    expect(harness.platform.boughtProductIds, hasLength(2));
  });

  testWidgets('Restore Purchases with nothing to restore says so', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.open(tester);

    await tester.tap(find.text(t.supporter.restore));
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.errors.nothingToRestore), findsOneWidget);
    expect(find.text(t.supporter.thankYouTitle), findsNothing);
  });

  testWidgets('an error from an earlier visit is gone when the sheet opens again', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.open(tester);
    await tester.tap(find.text(t.supporter.restore));
    await tester.pumpAndSettle();
    expect(find.text(t.supporter.errors.nothingToRestore), findsOneWidget);

    await tester.tap(find.byTooltip(t.common.close));
    await tester.pumpAndSettle();
    expect(find.byType(SupporterSheet), findsNothing);
    await harness.open(tester);

    expect(find.text(t.supporter.errors.nothingToRestore), findsNothing);
  });

  testWidgets('shows one notice at a time: the latest action\'s error replaces the price error', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.platform.productQueryError = Exception('offline');
    await harness.pump(tester);
    await harness.open(tester);
    expect(find.text(t.supporter.errors.productQueryFailed), findsOneWidget);

    await tester.tap(find.text(t.supporter.restore));
    await tester.pumpAndSettle();

    expect(find.text(t.supporter.errors.nothingToRestore), findsOneWidget);
    expect(find.text(t.supporter.errors.productQueryFailed), findsNothing);
    expect(find.text(t.common.retry), findsOneWidget);
  });

  testWidgets('an unlocked user sees the thank-you and Close dismisses the sheet', (tester) async {
    final harness = _Harness(purchased: true);
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.open(tester);

    expect(find.text(t.supporter.thankYouTitle), findsOneWidget);
    expect(find.textContaining(t.supporter.buy(price: '')), findsNothing);

    await tester.tap(find.text(t.common.close));
    await tester.pumpAndSettle();

    expect(find.byType(SupporterSheet), findsNothing);
  });

  testWidgets('a build without purchases opens nothing and never touches billing', (tester) async {
    final harness = _Harness(availability: SupporterAvailability.free);
    addTearDown(harness.dispose);
    await harness.pump(tester);

    await harness.open(tester);

    expect(find.byType(SupporterSheet), findsNothing);
    expect(harness.platform.billingCalls, 0);
  });

  group('on a TV remote', () {
    setUp(() {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      addTearDown(() {
        TvDetectionService.debugSetAppleTVOverride(null);
        PlatformDetector.debugSetIsDesktopOSOverride(null);
      });
    });

    testWidgets('focus moves from Restore to Buy once the price loads, and the D-pad reaches and selects both', (
      tester,
    ) async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.platform.productQueryGate = Completer<void>();
      await harness.pump(tester);
      await harness.open(tester, settle: false);

      // Buy cannot act without a price, so the sheet starts on Restore.
      expect(_focusedLabel(), 'supporter_restore');

      harness.platform.productQueryGate!.complete();
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'supporter_primary');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'supporter_restore');

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(harness.play.historyQueries, 1);
      expect(find.text(t.supporter.errors.nothingToRestore), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'supporter_primary');

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(harness.platform.boughtProductIds, ['supporter']);

      // Unlocking swaps the buttons for the thank-you; focus follows to Close.
      harness.platform.deliver([playPurchase()]);
      await tester.pumpAndSettle();
      expect(find.text(t.supporter.thankYouTitle), findsOneWidget);
      expect(_focusedLabel(), 'supporter_close');

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(SupporterSheet), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('on a 1080p TV (960x540) the intro stays in view whenever focus reaches the top button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.platform.productQueryError = Exception('offline');
      await harness.pump(tester);
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      final scrollable = find.descendant(of: find.byType(SupporterSheet), matching: find.byType(Scrollable));
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      bool inView(Finder target) {
        final viewport = tester.getRect(scrollable);
        final rect = tester.getRect(target);
        return rect.top >= viewport.top - 0.5 && rect.bottom <= viewport.bottom + 0.5;
      }

      final intro = find.text(t.supporter.intro);
      final retry = _button(t.common.retry);

      // Opening by D-pad focuses Retry without scrolling the intro away.
      expect(_focusedLabel(), 'supporter_primary');
      expect(inView(intro), isTrue);
      expect(inView(retry), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'supporter_restore');
      expect(inView(_button(t.supporter.restore)), isTrue);

      // A single UP returns to Retry with the intro back in view.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'supporter_primary');
      expect(inView(intro), isTrue);
      expect(inView(retry), isTrue);

      // UP on the top button also brings the intro back from any scroll.
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(inView(intro), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
      expect(inView(intro), isTrue);
      expect(_focusedLabel(), 'supporter_primary');
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('Settings tile', () {
    testWidgets('opens the sheet while locked and thanks the user once unlocked', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.pump(tester, body: const SupporterSettingsTile());

      expect(find.text(t.supporter.tileSubtitle), findsOneWidget);
      await tester.tap(find.text(t.settings.supportDeveloper));
      await tester.pumpAndSettle();
      expect(find.byType(SupporterSheet), findsOneWidget);

      await tester.tap(find.text(t.supporter.buy(price: r'$3.99')));
      await tester.pump();
      harness.platform.deliver([playPurchase()]);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.close));
      await tester.pumpAndSettle();

      expect(find.text(t.supporter.tileUnlocked), findsOneWidget);
      expect(find.text(t.supporter.tileSubtitle), findsNothing);
    });
  });
}
