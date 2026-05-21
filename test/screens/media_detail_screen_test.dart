import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/media_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(true);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('TV detail reveals season hubs together after all episode caches load', (tester) async {
    await SettingsService.getInstance();

    final show = MediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season1 = MediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season2 = MediaItem(
      id: 'season_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 2',
      index: 2,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode1 = MediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season1.id,
      parentIndex: season1.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode2 = MediaItem(
      id: 'episode_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 2',
      index: 1,
      parentId: season2.id,
      parentIndex: season2.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    final descendantsCompleter = Completer<List<MediaItem>>();
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1, season2],
      },
      pendingPlayableDescendants: descendantsCompleter.future,
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: SizedBox(width: 1280, height: 720, child: MediaDetailScreen(metadata: show)),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Season 1'), findsNothing);
    expect(find.text('Season 2'), findsNothing);

    descendantsCompleter.complete([episode1, episode2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
  });
}

class _FakeMediaServerClient implements MediaServerClient {
  final MediaItem show;
  final Map<String, List<MediaItem>> childrenByParent;
  final Future<List<MediaItem>> pendingPlayableDescendants;

  _FakeMediaServerClient({
    required this.show,
    required this.childrenByParent,
    required this.pendingPlayableDescendants,
  });

  @override
  String get serverId => 'server_1';

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async {
    return (item: show, onDeckEpisode: null);
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    return childrenByParent[parentId] ?? const [];
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final items = await pendingPlayableDescendants;
    return LibraryPage(items: items, totalCount: items.length, offset: start ?? 0);
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
