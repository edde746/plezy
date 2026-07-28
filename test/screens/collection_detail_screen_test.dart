import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/collection_detail_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/paged_fakes.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('music collection contents use square grid geometry and cards', (tester) async {
    final album = testMediaItem(
      id: 'album_1',
      backend: MediaBackend.plex,
      kind: MediaKind.album,
      title: 'Album 1',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final harness = await _createHarness([album]);
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _collection))),
    );
    await tester.pumpAndSettle();

    final layout = tester.widget<MediaCardSliverLayout>(find.byType(MediaCardSliverLayout));
    expect(layout.shape, CardShape.square);
    expect(layout.fullBleedImage, isFalse);
    expect(tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard)).cardShapeOverride, CardShape.square);
  });

  testWidgets('collection cards announce list position without duplicate actions', (tester) async {
    final semantics = tester.ensureSemantics();
    final items = [
      testMediaItem(
        id: 'movie_1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'First movie',
        serverId: 'server_1',
        serverName: 'Server',
      ),
      testMediaItem(
        id: 'movie_2',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Second movie',
        serverId: 'server_1',
        serverName: 'Server',
      ),
    ];
    final harness = await _createHarness(items);
    await SettingsService.instance.write(SettingsService.viewMode, ViewMode.list);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _collection))),
    );
    await tester.pumpAndSettle();

    final cards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(cards.map((card) => card.semanticValue), ['Row 1 of 2', 'Row 2 of 2']);

    final first = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(items.first))).getSemanticsData();
    expect(first.value, 'Row 1 of 2');
    semantics.dispose();
  });
}

final _collection = MediaItem(
  id: 'collection_1',
  backend: MediaBackend.plex,
  kind: MediaKind.collection,
  title: 'Music Collection',
  libraryId: 'music',
  serverId: 'server_1',
  serverName: 'Server',
);

Future<_CollectionHarness> _createHarness(List<MediaItem> items) async {
  await SettingsService.getInstance();

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(database);
  JellyfinApiCache.initialize(database);

  final downloadManager = DownloadManagerService(
    database: database,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
  await downloadProvider.ensureInitialized();

  final client = _CollectionClient(items);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    multiServerProvider.dispose();
    await database.close();
  });

  return _CollectionHarness(multiServerProvider: multiServerProvider, downloadProvider: downloadProvider);
}

class _CollectionHarness {
  final MultiServerProvider multiServerProvider;
  final DownloadProvider downloadProvider;

  const _CollectionHarness({required this.multiServerProvider, required this.downloadProvider});

  Widget wrap(Widget child) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(theme: monoTheme(dark: true), home: child),
      ),
    );
  }
}

class _CollectionClient implements MediaServerClient {
  final List<MediaItem> items;

  const _CollectionClient(this.items);

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async {
    return fakeLibraryPage(items, start: start, size: size);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
