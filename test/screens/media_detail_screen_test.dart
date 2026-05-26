import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/i18n/strings.g.dart';
import 'package:vibe_stream/media/library_query.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_hub.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/providers/multi_server_provider.dart';
import 'package:vibe_stream/screens/media_detail_screen.dart';
import 'package:vibe_stream/services/data_aggregation_service.dart';
import 'package:vibe_stream/services/multi_server_manager.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/theme/mono_theme.dart';
import 'package:vibe_stream/utils/layout_constants.dart';
import 'package:vibe_stream/utils/media_server_http_client.dart';
import 'package:vibe_stream/utils/platform_detector.dart';
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

  testWidgets('TV detail scales fallback title to fit logo bounds', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const title = 'The Surprisingly Long Movie Title That Needs Two Whole Lines';
    final movie = MediaItem(
      id: 'movie_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: title,
      summary: 'A compact viewport should make the fallback title shrink before it can overlap the detail text.',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: MediaDetailScreen(metadata: movie),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final titleText = tester.widget<Text>(find.text(title));
    final baseFontSize = 56 * TvLayoutConstants.scaleForSize(const Size(800, 480));
    expect(titleText.style?.fontSize, isNotNull);
    expect(titleText.style!.fontSize!, lessThan(baseFontSize));
  });

  testWidgets('TV detail defaults to first regular season when specials precede it', (tester) async {
    await SettingsService.getInstance();

    final show = MediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final specials = MediaItem(
      id: 'season_0',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Specials',
      index: 0,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
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
    final specialEpisode = MediaItem(
      id: 'episode_special_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Special 1',
      index: 1,
      parentId: specials.id,
      parentIndex: specials.index,
      grandparentId: show.id,
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

    final descendantsCompleter = Completer<List<MediaItem>>();
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [specials, season1],
        specials.id: [specialEpisode],
        season1.id: [episode1],
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

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Specials'), findsNothing);
    expect(find.text('S1E1'), findsOneWidget);
  });

  testWidgets('TV detail summary uses light theme foreground color', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const summary = 'Light theme detail text should stay readable.';
    final movie = MediaItem(
      id: 'movie_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Readable Movie',
      summary: summary,
    );
    final theme = monoTheme(dark: false);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: theme,
          home: MediaDetailScreen(metadata: movie),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final summaryText = tester.widget<Text>(find.text(summary));
    expect(summaryText.style?.color, theme.colorScheme.onSurface.withValues(alpha: 0.78));
  });

  testWidgets('TV detail reveals selected season before remaining episode caches load', (tester) async {
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

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsNothing);

    descendantsCompleter.complete([episode1, episode2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
  });

  testWidgets('TV detail falls back to per-season episodes when descendant cache fails', (tester) async {
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

    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1, season2],
        season1.id: [episode1],
        season2.id: [episode2],
      },
      playableDescendantsError: Exception('descendant cache failed'),
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

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
  });
}

class _FakeMediaServerClient implements MediaServerClient {
  final MediaItem show;
  final Map<String, List<MediaItem>> childrenByParent;
  final Future<List<MediaItem>>? pendingPlayableDescendants;
  final Object? playableDescendantsError;

  _FakeMediaServerClient({
    required this.show,
    required this.childrenByParent,
    this.pendingPlayableDescendants,
    this.playableDescendantsError,
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
    final error = playableDescendantsError;
    if (error != null) throw error;
    final items = await pendingPlayableDescendants!;
    return LibraryPage(items: items, totalCount: items.length, offset: start ?? 0);
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
