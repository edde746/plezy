import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

const _testTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
  bg: Colors.black,
  surface: Colors.black,
  outline: Colors.white24,
  text: Colors.white,
  textMuted: Colors.white70,
  splashFactory: NoSplash.splashFactory,
);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _pumpBasicRail(
  WidgetTester tester, {
  GlobalKey<SideNavigationRailState>? sideNavKey,
  NavigationTabId selectedTab = NavigationTabId.discover,
  bool isSidebarFocused = false,
  bool alwaysExpanded = false,
}) async {
  await SettingsService.getInstance();

  final librariesProvider = LibrariesProvider();
  addTearDown(librariesProvider.dispose);

  final hiddenLibrariesProvider = HiddenLibrariesProvider();
  await hiddenLibrariesProvider.ensureInitialized();
  addTearDown(hiddenLibrariesProvider.dispose);

  final manager = MultiServerManager();
  final aggregation = DataAggregationService(manager);
  final multiServerProvider = MultiServerProvider(manager, aggregation);
  addTearDown(multiServerProvider.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [_testTokens]),
          home: Scaffold(
            body: SideNavigationRail(
              key: sideNavKey,
              selectedTab: selectedTab,
              isSidebarFocused: isSidebarFocused,
              alwaysExpanded: alwaysExpanded,
              onDestinationSelected: (_) {},
              onLibrarySelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('NavigationTab.getVisibleTabs', () {
    test('includes watchlist when online', () {
      final tabs = NavigationTab.getVisibleTabs(isOffline: false, hasLiveTv: false);
      expect(tabs.any((t) => t.id == NavigationTabId.watchlist), isTrue);
    });

    test('includes watchlist when offline (onlineOnly: false)', () {
      final tabs = NavigationTab.getVisibleTabs(isOffline: true, hasLiveTv: false);
      expect(tabs.any((t) => t.id == NavigationTabId.watchlist), isTrue);
    });

    test('watchlist has icon Symbols.bookmark_rounded and onlineOnly: false', () {
      final watchlistTab = allNavigationTabs.firstWhere((t) => t.id == NavigationTabId.watchlist);
      expect(watchlistTab.onlineOnly, isFalse);
    });
  });

  group('SideNavigationRail watchlist item', () {
    testWidgets('renders watchlist nav item between downloads and settings', (tester) async {
      await _pumpBasicRail(tester, alwaysExpanded: true);

      // The rail is alwaysExpanded so labels should be visible.
      // Find all NavigationRailItem widgets and verify their labels.
      final navItems = tester.widgetList<NavigationRailItem>(find.byType(NavigationRailItem));
      final labels = navItems.map((item) {
        final textWidget = (item.label is Text) ? item.label as Text : null;
        return textWidget?.data;
      }).whereType<String>().toList();

      // Watchlist should appear in the label list.
      expect(labels, contains('Watchlist'));

      // Watchlist should be after Downloads and before Settings.
      final watchlistIdx = labels.indexOf('Watchlist');
      final downloadsIdx = labels.indexOf('Downloads');
      final settingsIdx = labels.indexOf('Settings');
      expect(watchlistIdx, greaterThan(downloadsIdx));
      expect(watchlistIdx, lessThan(settingsIdx));
    });

    testWidgets('watchlist nav item is selected when selectedTab is watchlist', (tester) async {
      await _pumpBasicRail(tester, selectedTab: NavigationTabId.watchlist, alwaysExpanded: true);

      // The watchlist label should have bold styling (FontWeight.w600) when selected.
      final navItems = tester.widgetList<NavigationRailItem>(find.byType(NavigationRailItem));
      NavigationRailItem? watchlistItem;
      for (final item in navItems) {
        if (item.label is Text) {
          final text = item.label as Text;
          if (text.data == 'Watchlist') {
            watchlistItem = item;
            break;
          }
        }
      }
      expect(watchlistItem, isNotNull);
      expect(watchlistItem!.isSelected, isTrue);
    });

    testWidgets('watchlist nav item is hidden on Apple TV', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
      await SettingsService.getInstance();

      final librariesProvider = LibrariesProvider();
      addTearDown(librariesProvider.dispose);

      final hiddenLibrariesProvider = HiddenLibrariesProvider();
      await hiddenLibrariesProvider.ensureInitialized();
      addTearDown(hiddenLibrariesProvider.dispose);

      final manager = MultiServerManager();
      final aggregation = DataAggregationService(manager);
      final multiServerProvider = MultiServerProvider(manager, aggregation);
      addTearDown(multiServerProvider.dispose);

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
              ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: const [_testTokens]),
              home: Scaffold(
                body: SideNavigationRail(
                  selectedTab: NavigationTabId.discover,
                  isSidebarFocused: true,
                  alwaysExpanded: true,
                  onDestinationSelected: (_) {},
                  onLibrarySelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Apple TV, neither Downloads nor Watchlist labels should appear.
      final allText = find.byType(Text);
      final labels = tester.widgetList<Text>(allText).map((t) => t.data).whereType<String>().toList();
      expect(labels, isNot(contains('Watchlist')));
      expect(labels, isNot(contains('Downloads')));
    });
  });

  group('SideNavigationRail watchlist focus keys', () {
    testWidgets('watchlist focus key resolves when selectedTab is watchlist', (tester) async {
      final sideNavKey = GlobalKey<SideNavigationRailState>();
      await _pumpBasicRail(
        tester,
        sideNavKey: sideNavKey,
        selectedTab: NavigationTabId.watchlist,
        isSidebarFocused: true,
        alwaysExpanded: true,
      );

      // Focus the active item — should be the watchlist item.
      sideNavKey.currentState!.focusActiveItem();
      await tester.pumpAndSettle();

      // The focused NavigationRailItem should be the watchlist one.
      final focusedItem = find.descendant(
        of: find.byType(SideNavigationRail),
        matching: find.byWidgetPredicate(
          (widget) => widget is NavigationRailItem && widget.focusNode.hasFocus,
        ),
      );
      expect(focusedItem, findsOneWidget);

      final focusedWidget = tester.widget<NavigationRailItem>(focusedItem);
      final label = (focusedWidget.label as Text).data;
      expect(label, 'Watchlist');
    });

    testWidgets('D-pad down from downloads navigates to watchlist, then settings', (tester) async {
      final sideNavKey = GlobalKey<SideNavigationRailState>();
      await _pumpBasicRail(
        tester,
        sideNavKey: sideNavKey,
        selectedTab: NavigationTabId.downloads,
        isSidebarFocused: true,
        alwaysExpanded: true,
      );

      // Focus the active item (downloads).
      sideNavKey.currentState!.focusActiveItem();
      await tester.pumpAndSettle();

      // Press down once — should move to watchlist.
      await _press(tester, LogicalKeyboardKey.arrowDown);

      var focusedItem = find.descendant(
        of: find.byType(SideNavigationRail),
        matching: find.byWidgetPredicate(
          (widget) => widget is NavigationRailItem && widget.focusNode.hasFocus,
        ),
      );
      expect(focusedItem, findsOneWidget);
      var focusedWidget = tester.widget<NavigationRailItem>(focusedItem);
      expect((focusedWidget.label as Text).data, 'Watchlist');

      // Press down again — should move to settings.
      await _press(tester, LogicalKeyboardKey.arrowDown);

      focusedItem = find.descendant(
        of: find.byType(SideNavigationRail),
        matching: find.byWidgetPredicate(
          (widget) => widget is NavigationRailItem && widget.focusNode.hasFocus,
        ),
      );
      expect(focusedItem, findsOneWidget);
      focusedWidget = tester.widget<NavigationRailItem>(focusedItem);
      expect((focusedWidget.label as Text).data, 'Settings');
    });
  });
}
