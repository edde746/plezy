import 'dart:ui' show PointerDeviceKind;
import 'package:plezy/media/ids.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Minimal source-bearing stand-in: the rail only reads [hasAnySource].
class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  @override
  bool get hasAnySource => true;
}

MediaLibrary _library({
  required String id,
  required String title,
  required ServerId serverId,
  required String serverName,
}) {
  return MediaLibrary(
    id: id,
    backend: MediaBackend.plex,
    title: title,
    kind: MediaKind.movie,
    serverId: serverId,
    serverName: serverName,
  );
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

BoxDecoration? _railItemDecoration(WidgetTester tester, Finder item) {
  return tester.widget<Container>(find.descendant(of: item, matching: find.byType(Container)).first).decoration
      as BoxDecoration?;
}

AnimatedOpacity _railSurfaceOpacity(WidgetTester tester) {
  return tester
      .widgetList<AnimatedOpacity>(
        find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedOpacity)),
      )
      .singleWhere((widget) => widget.child is AnimatedContainer);
}

/// The Libraries header's expand/collapse chevron, matched by the symbol that
/// only the given state renders.
Finder _librariesChevron(IconData icon) {
  return find.descendant(of: find.widgetWithText(NavigationRailItem, 'Libraries'), matching: find.byIcon(icon));
}

Future<void> _pumpBasicRail(
  WidgetTester tester, {
  GlobalKey<SideNavigationRailState>? sideNavKey,
  NavigationTabId selectedTab = NavigationTabId.discover,
  String? selectedLibraryKey,
  List<MediaLibrary> libraries = const [],
  bool isSidebarFocused = false,
  bool alwaysExpanded = false,
  double? height,
  CatalogSourcesProvider? catalogSources,
}) async {
  await SettingsService.getInstance();

  final librariesProvider = LibrariesProvider();
  if (libraries.isNotEmpty) {
    await librariesProvider.updateLibraryOrder(libraries);
  }
  addTearDown(librariesProvider.dispose);

  final hiddenLibrariesProvider = HiddenLibrariesProvider();
  await hiddenLibrariesProvider.ensureInitialized();
  addTearDown(hiddenLibrariesProvider.dispose);

  final manager = MultiServerManager();
  final multiServerProvider = testMultiServerProvider(manager);
  addTearDown(multiServerProvider.dispose);

  final rail = SideNavigationRail(
    key: sideNavKey,
    selectedTab: selectedTab,
    selectedLibraryKey: selectedLibraryKey,
    isSidebarFocused: isSidebarFocused,
    alwaysExpanded: alwaysExpanded,
    onDestinationSelected: (_) {},
    onLibrarySelected: (_) {},
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          if (catalogSources != null) ChangeNotifierProvider<CatalogSourcesProvider>.value(value: catalogSources),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: height == null ? rail : SizedBox(height: height, child: rail),
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

  testWidgets('closed TV rail is slim and keeps primary icons centered', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await SettingsService.getInstance();

    final librariesProvider = LibrariesProvider();
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
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
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: false,
                alwaysExpanded: false,
                onDestinationSelected: (_) {},
                onLibrarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(tester.getSize(rail).width, SideNavigationRailState.tvCollapsedWidth);

    final firstIconCenter = tester.getCenter(find.byType(AppIcon).first).dx;
    expect(firstIconCenter - tester.getTopLeft(rail).dx, closeTo(SideNavigationRailState.tvCollapsedWidth / 2, 0.1));

    final selectedItem = find.byType(NavigationRailItem).first;
    final selectedItemContainer = tester.widget<Container>(
      find.descendant(of: selectedItem, matching: find.byType(Container)).first,
    );
    expect((selectedItemContainer.decoration as BoxDecoration?)?.color, isNull);

    expect(_railSurfaceOpacity(tester).opacity, 0.0);
  });

  testWidgets('closed non-TV rail keeps an opaque surface', (tester) async {
    await _pumpBasicRail(tester);

    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(tester.getSize(rail).width, SideNavigationRailState.collapsedWidth);
    expect(_railSurfaceOpacity(tester).opacity, 1.0);
  });

  testWidgets('closed desktop rail shows icon-only pill destinations', (tester) async {
    await _pumpBasicRail(tester);

    // Collapsed destinations are icon-only; labels appear only expanded.
    expect(find.text('Home'), findsNothing);

    final homeItem = find.byType(NavigationRailItem).first;
    final pillFinder = find.descendant(of: homeItem, matching: find.byType(Container)).first;
    expect(
      tester.getSize(pillFinder),
      const Size(NavigationRailItem.collapsedIndicatorWidth, NavigationRailItem.collapsedIndicatorHeight),
    );
    // Home is the selected tab: the pill carries the active indicator tint.
    expect(_railItemDecoration(tester, homeItem)?.color, testMonoTokens.text.withValues(alpha: 0.1));

    // Pill (and its icon) are centered in the rail.
    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(
      tester.getCenter(pillFinder).dx - tester.getTopLeft(rail).dx,
      closeTo(SideNavigationRailState.collapsedWidth / 2, 0.1),
    );
  });

  testWidgets('expanded rail destination uses a full-width stadium indicator', (tester) async {
    await _pumpBasicRail(tester, alwaysExpanded: true);

    final homeItem = find.byType(NavigationRailItem).first;
    final indicator = find.descendant(of: homeItem, matching: find.byType(Container)).first;
    expect(tester.getSize(indicator), const Size(SideNavigationRailState.expandedWidth - 24, 48));
    expect(_railItemDecoration(tester, homeItem)?.borderRadius, BorderRadius.circular(MonoTokens.radiusFull));
  });

  testWidgets('expanded TV rail keeps a transparent surface', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await SettingsService.getInstance();

    final librariesProvider = LibrariesProvider();
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
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
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: true,
                alwaysExpanded: false,
                onDestinationSelected: (_) {},
                onLibrarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(tester.getSize(rail).width, SideNavigationRailState.expandedWidth);

    expect(_railSurfaceOpacity(tester).opacity, 0.0);
  });

  testWidgets('expanded rail keeps selected background outside sidebar keyboard focus', (tester) async {
    await _pumpBasicRail(tester, alwaysExpanded: true);

    final selectedItem = find.byType(NavigationRailItem).first;
    expect(_railItemDecoration(tester, selectedItem)?.color, testMonoTokens.text.withValues(alpha: 0.1));
  });

  testWidgets('D-pad sidebar focus hides selected item background after focus moves', (tester) async {
    final sideNavKey = GlobalKey<SideNavigationRailState>();
    await _pumpBasicRail(tester, sideNavKey: sideNavKey, isSidebarFocused: true, alwaysExpanded: true);

    sideNavKey.currentState!.focusActiveItem();
    await tester.pumpAndSettle();
    await _press(tester, LogicalKeyboardKey.arrowDown);

    final selectedItem = find.byType(NavigationRailItem).first;
    expect(_railItemDecoration(tester, selectedItem)?.color, isNull);
  });

  testWidgets('focusActiveItem focuses selected library and scrolls it into view', (tester) async {
    final sideNavKey = GlobalKey<SideNavigationRailState>();
    final libraries = List.generate(
      18,
      (index) => _library(id: '$index', title: 'Library $index', serverId: ServerId('server'), serverName: 'Server'),
    );
    final targetLibrary = libraries.last;

    await _pumpBasicRail(
      tester,
      sideNavKey: sideNavKey,
      selectedTab: NavigationTabId.libraries,
      selectedLibraryKey: targetLibrary.globalKey,
      libraries: libraries,
      isSidebarFocused: true,
      alwaysExpanded: true,
      height: 260,
    );

    final scrollable = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(Scrollable)).first;
    final scrollableState = tester.state<ScrollableState>(scrollable);
    expect(scrollableState.position.pixels, 0);

    sideNavKey.currentState!.focusActiveItem();
    await tester.pump();
    await tester.pumpAndSettle();

    final targetItemFinder = find.widgetWithText(NavigationRailItem, targetLibrary.title);
    expect(targetItemFinder, findsOneWidget);
    final targetItem = tester.widget<NavigationRailItem>(targetItemFinder);
    expect(targetItem.focusNode.hasFocus, isTrue);
    expect(scrollableState.position.pixels, greaterThan(0));

    final railRect = tester.getRect(find.byType(SideNavigationRail));
    final targetRect = tester.getRect(find.text(targetLibrary.title));
    expect(targetRect.top, greaterThanOrEqualTo(railRect.top));
    expect(targetRect.bottom, lessThanOrEqualTo(railRect.bottom));
  });

  testWidgets('Explore item follows the showExploreTab appearance setting', (tester) async {
    final catalogSources = _FakeCatalogSourcesProvider();
    addTearDown(catalogSources.dispose);

    await _pumpBasicRail(tester, alwaysExpanded: true, catalogSources: catalogSources);
    expect(find.widgetWithText(NavigationRailItem, 'Explore'), findsOneWidget);

    await SettingsService.instance.write(SettingsService.showExploreTab, false);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(NavigationRailItem, 'Explore'), findsNothing);

    await SettingsService.instance.write(SettingsService.showExploreTab, true);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(NavigationRailItem, 'Explore'), findsOneWidget);
  });

  testWidgets('collapsing the Libraries section survives a fresh rail', (tester) async {
    final movies = _library(id: '1', title: 'Movies', serverId: ServerId('server-a'), serverName: 'Server A');

    await _pumpBasicRail(tester, alwaysExpanded: true, libraries: [movies]);
    expect(_librariesChevron(Symbols.expand_less_rounded), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationRailItem, 'Libraries'));
    await tester.pumpAndSettle();
    expect(_librariesChevron(Symbols.expand_more_rounded), findsOneWidget);
    expect(SettingsService.instance.read(SettingsService.librariesSectionExpanded), isFalse);

    // Tear the rail down so the next pump builds a brand-new State — the app
    // restart the session-only flag used to lose (#1896).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpBasicRail(tester, alwaysExpanded: true, libraries: [movies]);
    expect(_librariesChevron(Symbols.expand_more_rounded), findsOneWidget);
  });

  testWidgets('a collapsed Libraries section keeps its rows out of D-pad order', (tester) async {
    await SettingsService.getInstance();
    await SettingsService.instance.write(SettingsService.librariesSectionExpanded, false);

    final movies = _library(id: '1', title: 'Movies', serverId: ServerId('server-a'), serverName: 'Server A');

    final librariesProvider = LibrariesProvider();
    await librariesProvider.updateLibraryOrder([movies]);
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
    addTearDown(multiServerProvider.dispose);

    final sideNavKey = GlobalKey<SideNavigationRailState>();
    NavigationTabId? selectedTab;

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                key: sideNavKey,
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: true,
                alwaysExpanded: true,
                onDestinationSelected: (tab) => selectedTab = tab,
                onLibrarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    sideNavKey.currentState!.focusActiveItem();
    await tester.pumpAndSettle();

    // Home -> Libraries -> Search. The Movies row is skipped while collapsed.
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);

    expect(selectedTab, NavigationTabId.search);
  });

  testWidgets('collapsed rail with expanded Libraries skips focus-excluded library rows', (tester) async {
    // The library rows render under ExcludeFocus while the rail is collapsed
    // even though the Libraries section pref is expanded; targeting one used
    // to swallow DOWN forever, cutting off everything below the header.
    await SettingsService.getInstance();
    await SettingsService.instance.write(SettingsService.librariesSectionExpanded, true);

    final movies = _library(id: '1', title: 'Movies', serverId: ServerId('server-a'), serverName: 'Server A');

    final librariesProvider = LibrariesProvider();
    await librariesProvider.updateLibraryOrder([movies]);
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
    addTearDown(multiServerProvider.dispose);

    final sideNavKey = GlobalKey<SideNavigationRailState>();
    NavigationTabId? selectedTab;

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ],
          child: InputModeTracker(
            child: MaterialApp(
              theme: ThemeData(extensions: const [testMonoTokens]),
              home: Scaffold(
                body: SideNavigationRail(
                  key: sideNavKey,
                  selectedTab: NavigationTabId.discover,
                  isSidebarFocused: false,
                  alwaysExpanded: false,
                  onDestinationSelected: (tab) => selectedTab = tab,
                  onLibrarySelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    sideNavKey.currentState!.focusActiveItem();
    await tester.pumpAndSettle();

    // Home -> Libraries -> Search. The Movies row stays out of D-pad order
    // while the rail is collapsed, so DOWN lands on the next real row.
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);

    expect(selectedTab, NavigationTabId.search);
  });

  testWidgets('hover expands the rail as an overlay and collapses on exit', (tester) async {
    await SettingsService.getInstance();

    final librariesProvider = LibrariesProvider();
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
    addTearDown(multiServerProvider.dispose);

    final scrimReports = <bool>[];

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: false,
                alwaysExpanded: false,
                onDestinationSelected: (_) {},
                onInteractionExpandedChanged: scrimReports.add,
                onLibrarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(tester.getSize(rail).width, SideNavigationRailState.collapsedWidth);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(799, 599));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(rail));
    await tester.pumpAndSettle();

    // Floating overlays read as an M3E modal panel: extra-rounded trailing
    // corners and an edge shadow, and the shell is told to scrim content.
    final surface = _railSurfaceOpacity(tester).child! as AnimatedContainer;
    final surfaceDecoration = surface.decoration! as BoxDecoration;
    expect(
      surfaceDecoration.borderRadius,
      const BorderRadius.horizontal(right: Radius.circular(SideNavigationRailState.overlayCornerRadius)),
    );
    expect(surfaceDecoration.boxShadow, isNotEmpty);
    expect(scrimReports.last, isTrue);

    expect(tester.getSize(rail).width, SideNavigationRailState.expandedWidth);

    await gesture.moveTo(tester.getBottomRight(rail) + const Offset(100, -10));
    await tester.pumpAndSettle();

    expect(tester.getSize(rail).width, SideNavigationRailState.collapsedWidth);
    expect(scrimReports.last, isFalse);
  });

  testWidgets('Apple TV D-pad focus skips hidden downloads item', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await SettingsService.getInstance();

    final librariesProvider = LibrariesProvider();
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
    addTearDown(multiServerProvider.dispose);

    final sideNavKey = GlobalKey<SideNavigationRailState>();
    NavigationTabId? selectedTab;

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                key: sideNavKey,
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: true,
                alwaysExpanded: true,
                onDestinationSelected: (tab) => selectedTab = tab,
                onLibrarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    sideNavKey.currentState!.focusActiveItem();
    await tester.pumpAndSettle();

    // Home -> Libraries -> Search -> Settings. Downloads is hidden on Apple TV.
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);

    expect(selectedTab, NavigationTabId.settings);
  });

  testWidgets('D-pad down from a hidden server header focuses that hidden server library', (tester) async {
    await SettingsService.getInstance();

    final visibleServerALibrary = _library(
      id: '1',
      title: 'Visible Server A',
      serverId: ServerId('server-a'),
      serverName: 'Server A',
    );
    final hiddenServerALibrary = _library(
      id: '2',
      title: 'Hidden Server A',
      serverId: ServerId('server-a'),
      serverName: 'Server A',
    );
    final visibleServerBLibrary = _library(
      id: '1',
      title: 'Visible Server B',
      serverId: ServerId('server-b'),
      serverName: 'Server B',
    );

    final librariesProvider = LibrariesProvider();
    await librariesProvider.updateLibraryOrder([visibleServerALibrary, hiddenServerALibrary, visibleServerBLibrary]);
    addTearDown(librariesProvider.dispose);

    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    await hiddenLibrariesProvider.ensureInitialized();
    await hiddenLibrariesProvider.hideLibrary(hiddenServerALibrary.globalKey);
    addTearDown(hiddenLibrariesProvider.dispose);

    final manager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(manager);
    addTearDown(multiServerProvider.dispose);

    final sideNavKey = GlobalKey<SideNavigationRailState>();
    var selectedLibraryKey = '';

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SideNavigationRail(
                key: sideNavKey,
                selectedTab: NavigationTabId.discover,
                isSidebarFocused: true,
                alwaysExpanded: true,
                onDestinationSelected: (_) {},
                onLibrarySelected: (key) => selectedLibraryKey = key,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    sideNavKey.currentState!.focusActiveItem();
    await tester.pumpAndSettle();

    // Home -> Libraries -> Server A header -> visible A -> Server B header -> visible B -> Hidden Libraries.
    for (var i = 0; i < 6; i++) {
      await _press(tester, LogicalKeyboardKey.arrowDown);
    }
    await _press(tester, LogicalKeyboardKey.enter);

    // Hidden Libraries -> hidden Server A header -> hidden Server A library.
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);

    expect(selectedLibraryKey, hiddenServerALibrary.globalKey);
  });

  testWidgets('rail item focus repaints locally without rebuilding its parent', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var parentBuilds = 0;

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                parentBuilds++;
                return NavigationRailItem(
                  icon: Symbols.home_rounded,
                  label: const Text('Home'),
                  isSelected: false,
                  onTap: () {},
                  focusNode: focusNode,
                );
              },
            ),
          ),
        ),
      ),
    );

    final item = find.byType(NavigationRailItem);
    expect(_railItemDecoration(tester, item)?.color, isNull);
    expect(parentBuilds, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(_railItemDecoration(tester, item)?.color, isNotNull);
    expect(parentBuilds, 1);
  });
}
