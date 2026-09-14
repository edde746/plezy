import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/mobile_navigation_rail.dart';

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugReset();
    addTearDown(TvDetectionService.debugReset);
  });

  final tabs = allNavigationTabs.where((tab) => tab.id != NavigationTabId.settings).toList();

  Widget wrap(Widget rail, {TextDirection direction = TextDirection.ltr}) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Row(
            children: [
              rail,
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a destination reports its tab', (tester) async {
    NavigationTabId? selected;
    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: true,
          onDestinationSelected: (id) => selected = id,
        ),
      ),
    );

    await tester.tap(find.text(t.common.search));
    expect(selected, NavigationTabId.search);
  });

  testWidgets('labels follow the nav bar label setting', (tester) async {
    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: false,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    // The rail keeps the label for semantics, but gives it no space.
    expect(tester.getSize(find.text(t.navigation.libraries)), Size.zero);

    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: true,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    expect(tester.getSize(find.text(t.navigation.libraries)).width, greaterThan(0));
  });

  testWidgets('labels give way on a viewport too short to show every destination', (tester) async {
    // A landscape phone: ~410dp tall, six labelled destinations need ~430.
    tester.view.physicalSize = const Size(900, 410);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: true,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    expect(tester.getSize(find.text(t.navigation.libraries)), Size.zero);
    expect(tester.takeException(), isNull);
    // Every destination is still reachable without scrolling.
    expect(tester.getBottomLeft(find.byType(NavigationRail)).dy, lessThanOrEqualTo(410));

    expect(MobileNavigationRail.labelsFit(destinations: 6, hasLeading: false, height: 410), isFalse);
    expect(MobileNavigationRail.labelsFit(destinations: 6, hasLeading: false, height: 600), isTrue);
    expect(MobileNavigationRail.labelsFit(destinations: 7, hasLeading: true, height: 500), isFalse);
  });

  testWidgets('long-pressing Libraries opens the quick picker; a tap still selects it', (tester) async {
    NavigationTabId? selected;
    var quickPicks = 0;
    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: true,
          onDestinationSelected: (id) => selected = id,
          onLibrariesLongPress: () => quickPicks++,
        ),
      ),
    );

    final librariesTab = tabs.firstWhere((tab) => tab.id == NavigationTabId.libraries);
    final icon = find.byWidgetPredicate((w) => w is Icon && w.icon == librariesTab.icon);
    await tester.longPress(icon);
    await tester.pump();
    expect(quickPicks, 1);
    expect(selected, isNull);

    await tester.tap(icon);
    expect(selected, NavigationTabId.libraries);
    expect(quickPicks, 1);
  });

  testWidgets('offline shows a reconnect action that is inert while reconnecting', (tester) async {
    var reconnects = 0;
    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.downloads,
          showLabels: true,
          onDestinationSelected: (_) {},
          isOffline: true,
          onReconnect: () => reconnects++,
        ),
      ),
    );
    final reconnect = find.byTooltip(t.common.reconnect);
    expect(reconnect, findsOneWidget);
    await tester.tap(reconnect);
    expect(reconnects, 1);

    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.downloads,
          showLabels: true,
          onDestinationSelected: (_) {},
          isOffline: true,
          isReconnecting: true,
          onReconnect: () => reconnects++,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byTooltip(t.common.reconnect), warnIfMissed: false);
    expect(reconnects, 1);

    await tester.pumpWidget(
      wrap(
        MobileNavigationRail(
          tabs: tabs,
          selectedTab: NavigationTabId.discover,
          showLabels: true,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    expect(find.byTooltip(t.common.reconnect), findsNothing);
  });

  group('shouldUseLandscapeNavigationRail', () {
    Future<bool> evaluate(
      WidgetTester tester, {
      required Size size,
      TargetPlatform platform = TargetPlatform.android,
    }) async {
      late bool result;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Builder(
            builder: (context) {
              result = PlatformDetector.shouldUseLandscapeNavigationRail(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('a landscape phone or head unit uses the rail', (tester) async {
      expect(await evaluate(tester, size: const Size(1080, 600)), isTrue);
    });

    testWidgets('portrait keeps the bottom bar', (tester) async {
      expect(await evaluate(tester, size: const Size(600, 1080)), isFalse);
    });

    testWidgets('desktop keeps its own sidebar', (tester) async {
      expect(await evaluate(tester, size: const Size(1080, 600), platform: TargetPlatform.macOS), isFalse);
    });

    testWidgets('TV keeps its own sidebar', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
      expect(await evaluate(tester, size: const Size(1080, 600)), isFalse);
    });
  });
}
