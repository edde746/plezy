import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/playlist/playlist_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playlist_items_loader.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('loads playlist continuation pages from an unmodifiable first page', (tester) async {
    final items = List.generate(
      playlistItemsPageSize + 5,
      (index) => MediaItem(
        id: 'item_$index',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Item $index',
        serverId: 'server_1',
        serverName: 'Server',
      ),
    );
    final harness = await _createHarness(items);

    await tester.pumpWidget(
      harness.wrap(const SizedBox(width: 1280, height: 720, child: PlaylistDetailScreen(playlist: _playlist))),
    );

    for (var i = 0; i < 10 && harness.client.requestedStarts.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [0, playlistItemsPageSize]);
    expect(harness.client.requestedSizes, [playlistItemsPageSize, playlistItemsPageSize]);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30000));
    await tester.pumpAndSettle();

    expect(find.text('Item ${playlistItemsPageSize + 4}'), findsOneWidget);
    expect(find.textContaining('Unsupported operation'), findsNothing);
    expect(find.text(t.common.retry), findsNothing);
  });

  testWidgets('iOS top safe-area tap scrolls long playlists to top', (tester) async {
    final items = _mediaItems(playlistItemsPageSize + 5);
    final harness = await _createHarness(items);

    await tester.pumpWidget(
      harness.wrap(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 25)),
          child: SizedBox(width: 390, height: 844, child: PlaylistDetailScreen(playlist: _playlist)),
        ),
        platform: TargetPlatform.iOS,
      ),
    );

    for (var i = 0; i < 10 && harness.client.requestedStarts.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));

    await tester.tapAt(const Offset(20, 10));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, 0);
  });

  testWidgets('pushed iOS playlist route allows native pop gesture', (tester) async {
    final harness = await _createHarness(_mediaItems(1));
    MaterialPageRoute<void>? playlistRoute;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              playlistRoute = MaterialPageRoute<void>(builder: (_) => const PlaylistDetailScreen(playlist: _playlist));
              Navigator.of(context).push(playlistRoute!);
            },
            child: const Text('Open playlist'),
          ),
        ),
        platform: TargetPlatform.iOS,
      ),
    );

    await tester.tap(find.text('Open playlist'));
    await tester.pumpAndSettle();

    expect(playlistRoute, isNotNull);
    expect(playlistRoute!.popGestureEnabled, isTrue);
  });
}

const _playlist = MediaPlaylist(
  id: 'playlist_1',
  backend: MediaBackend.plex,
  title: 'Long Playlist',
  playlistType: 'video',
  serverId: 'server_1',
  serverName: 'Server',
);

List<MediaItem> _mediaItems(int count) {
  return List.generate(
    count,
    (index) => MediaItem(
      id: 'item_$index',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Item $index',
      serverId: 'server_1',
      serverName: 'Server',
    ),
  );
}

Future<_PlaylistHarness> _createHarness(List<MediaItem> items) async {
  await SettingsService.getInstance();

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);

  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();

  final client = _PagedPlaylistClient(items);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    multiServerProvider.dispose();
    await db.close();
  });

  return _PlaylistHarness(client: client, multiServerProvider: multiServerProvider, downloadProvider: downloadProvider);
}

class _PlaylistHarness {
  final _PagedPlaylistClient client;
  final MultiServerProvider multiServerProvider;
  final DownloadProvider downloadProvider;

  const _PlaylistHarness({required this.client, required this.multiServerProvider, required this.downloadProvider});

  Widget wrap(Widget child, {TargetPlatform platform = TargetPlatform.android}) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: platform),
          home: child,
        ),
      ),
    );
  }
}

class _PagedPlaylistClient implements MediaServerClient {
  final List<MediaItem> items;
  final List<int?> requestedStarts = [];
  final List<int?> requestedSizes = [];

  _PagedPlaylistClient(this.items);

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    requestedStarts.add(start);
    requestedSizes.add(size);

    final offset = start ?? 0;
    final limit = size ?? items.length;
    return LibraryPage(items: items.skip(offset).take(limit).toList(), totalCount: items.length, offset: offset);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
