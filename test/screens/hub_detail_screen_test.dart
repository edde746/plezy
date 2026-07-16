import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/hub_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:provider/provider.dart';

import '../test_helpers/paged_fakes.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('Jellyfin hub advances by raw page size after screen filtering', (tester) async {
    final items = List.generate(
      205,
      (index) => _item(index, libraryId: index.isEven ? '7' : '8', backend: MediaBackend.jellyfin),
    );
    final harness = await _createHarness(items, backend: MediaBackend.jellyfin);

    await tester.pumpWidget(
      harness.wrap(
        HubDetailScreen(
          hub: MediaHub(
            id: 'home.recent',
            title: 'Recent',
            type: 'movie',
            items: items.take(5).toList(),
            size: items.length,
            more: true,
            libraryId: '7',
            serverId: 'server_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [0, 200]);
    expect(harness.client.fullHubRequests, 0);
    expect(find.text(t.common.retry), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30000));
    await tester.pumpAndSettle();
    expect(find.text('Item 204'), findsOneWidget);
    expect(find.text('Item 203'), findsNothing);
  });

  testWidgets('Plex hub replaces its preview with the full-hub response', (tester) async {
    final items = List.generate(205, (index) => _item(index, backend: MediaBackend.plex));
    final harness = await _createHarness(items, backend: MediaBackend.plex);

    await tester.pumpWidget(
      harness.wrap(
        HubDetailScreen(
          hub: MediaHub(
            id: '/hubs/home/recentlyAdded',
            title: 'Recently Added',
            type: 'movie',
            items: items.take(5).toList(),
            size: items.length,
            more: true,
            serverId: 'server_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [0]);
    expect(harness.client.fullHubRequests, 1);
    expect(find.text(t.common.retry), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30000));
    await tester.pumpAndSettle();
    expect(find.text('Item 204'), findsOneWidget);
  });
}

MediaItem _item(int index, {required MediaBackend backend, String? libraryId}) => testMediaItem(
  id: 'item_$index',
  backend: backend,
  kind: MediaKind.movie,
  title: 'Item $index',
  libraryId: libraryId,
  serverId: 'server_1',
  serverName: 'Server',
);

Future<_HubHarness> _createHarness(List<MediaItem> items, {required MediaBackend backend}) async {
  await SettingsService.getInstance();
  final client = _PagedHubClient(items, backend: backend);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final provider = MultiServerProvider(manager, DataAggregationService(manager));
  addTearDown(provider.dispose);
  return _HubHarness(client: client, provider: provider);
}

class _HubHarness {
  const _HubHarness({required this.client, required this.provider});

  final _PagedHubClient client;
  final MultiServerProvider provider;

  Widget wrap(Widget child) => TranslationProvider(
    child: ChangeNotifierProvider<MultiServerProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: SizedBox(width: 1280, height: 720, child: child),
      ),
    ),
  );
}

class _PagedHubClient implements MediaServerClient {
  _PagedHubClient(this.items, {required this.backend});

  final List<MediaItem> items;
  final List<int?> requestedStarts = [];
  int fullHubRequests = 0;

  @override
  final MediaBackend backend;

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  ServerCapabilities get capabilities =>
      backend == MediaBackend.plex ? ServerCapabilities.plex : ServerCapabilities.jellyfin;

  @override
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(
    String hubId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    requestedStarts.add(start);
    return fakeLibraryPage(items, start: start, size: size);
  }

  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) async {
    fullHubRequests++;
    return List.unmodifiable(items);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
