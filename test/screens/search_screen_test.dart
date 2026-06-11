import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/search_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
  });

  testWidgets('stale callbacks are no-ops after SearchScreen is disposed', (tester) async {
    final key = GlobalKey<State<SearchScreen>>();

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(home: SearchScreen(key: key)),
      ),
    );

    final state = key.currentState!;
    final searchInput = state as SearchInputFocusable;
    searchInput.setSearchQuery('movie');
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(() => (state as Refreshable).refresh(), returnsNormally);
    expect(() => (state as dynamic).updateItem('movie_1'), returnsNormally);
    expect(() => (state as FullRefreshable).fullRefresh(), returnsNormally);
    expect(() => searchInput.setSearchQuery('new movie'), returnsNormally);
    expect(() => (state as FocusableTab).focusActiveTabIfReady(), returnsNormally);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV OSK search key moves focus to the first result', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    final state = key.currentState!;
    (state as SearchInputFocusable).setSearchQuery('movie');
    // rate_limiter's Debounce compares DateTime.now() against the fake-clock
    // timer, so it never invokes under FakeAsync — run the search via
    // refresh() (same _performSearch path) to get results behind the dialog.
    (state as Refreshable).refresh();
    await tester.pumpAndSettle();
    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);

    await tester.tap(_keyboardDoneKey());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
    expect(find.text('Movie 1'), findsOneWidget);

    // Dispose the screen so its still-armed debounce timer is cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TV OSK search key before the debounce fires searches immediately', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    (key.currentState! as SearchInputFocusable).setSearchQuery('movie');
    await tester.pump(const Duration(milliseconds: 100));
    expect(client.queries, isEmpty);

    await tester.tap(_keyboardDoneKey());
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
  });
}

Future<(_FakeMediaServerClient, GlobalKey<State<SearchScreen>>)> _pumpTvSearchScreen(WidgetTester tester) async {
  TvDetectionService.debugSetAppleTVOverride(null);
  await TvDetectionService.getInstance(forceTv: true);
  TvDetectionService.setForceTVSync(true);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  final client = _FakeMediaServerClient(
    items: [
      MediaItem(
        id: 'movie_1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie 1',
        serverId: 'server_1',
        serverName: 'Server',
      ),
    ],
  );
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final provider = MultiServerProvider(manager, DataAggregationService(manager));
  addTearDown(provider.dispose);

  final key = GlobalKey<State<SearchScreen>>();
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<MultiServerProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: SearchScreen(key: key),
        ),
      ),
    ),
  );
  return (client, key);
}

Finder _keyboardDoneKey() {
  return find.descendant(
    of: find.byKey(const Key('tv_virtual_keyboard_panel')),
    matching: find.byIcon(Icons.search_rounded),
  );
}

class _FakeMediaServerClient implements MediaServerClient {
  final List<MediaItem> items;
  final List<String> queries = [];

  _FakeMediaServerClient({required this.items});

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 100}) async {
    queries.add(query);
    return items;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
