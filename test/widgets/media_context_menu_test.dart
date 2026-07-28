import '../test_helpers/paged_fakes.dart';
import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/metadata_edit/metadata_edit_adapters.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/music/album_detail_screen.dart';
import 'package:plezy/screens/music/artist_detail_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/media_context_menu.dart';
import 'package:provider/provider.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';
import '../test_helpers/stub_music_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isAdminActionAllowedForMediaItem', () {
    test('blocks non-admin Plex Home users on Plex items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: false));

      expect(
        isAdminActionAllowedForMediaItem(isOwnerOrAdmin: true, itemBackend: MediaBackend.plex, activeProfile: profile),
        isFalse,
      );
    });

    test('does not apply Plex Home role to Jellyfin items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: false));

      expect(
        isAdminActionAllowedForMediaItem(
          isOwnerOrAdmin: true,
          itemBackend: MediaBackend.jellyfin,
          activeProfile: profile,
        ),
        isTrue,
      );
    });

    test('allows Plex admin Home users on Plex items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: true));

      expect(
        isAdminActionAllowedForMediaItem(isOwnerOrAdmin: true, itemBackend: MediaBackend.plex, activeProfile: profile),
        isTrue,
      );
    });
  });

  group('supportsMetadataEdit', () {
    test('allows Jellyfin video metadata edit through capability gate', () {
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection(),
        httpClient: MockClient((_) async => http.Response('', 204)),
      );
      addTearDown(client.close);

      expect(supportsMetadataEdit(client, MediaKind.movie), isTrue);
      expect(supportsMetadataEdit(client, MediaKind.show), isTrue);
      expect(supportsMetadataEdit(client, MediaKind.track), isFalse);
    });
  });

  group('MediaContextMenu actions', () {
    testWidgets('audio playlist play and shuffle actions use music playback', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final tracks = [
        testMediaItem(
          id: 'track-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.track,
          title: 'Track One',
          serverId: 'srv-1',
        ),
        testMediaItem(
          id: 'track-2',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.track,
          title: 'Track Two',
          serverId: 'srv-1',
        ),
      ];
      final client = _AudioPlaylistClient(tracks);
      final music = _RecordingMusicPlaybackService();
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        await stack.dispose();
        music.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      const playlist = MediaPlaylist(
        id: 'playlist-1',
        backend: MediaBackend.jellyfin,
        title: 'Road Trip',
        playlistType: 'audio',
        serverId: 'srv-1',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
              ChangeNotifierProvider<MusicPlaybackService>.value(value: music),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: playlist,
                    child: const SizedBox(width: 120, height: 80, child: Text('audio target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pumpAndSettle();

      expect(music.playedTracks, tracks);
      expect(music.playedContext?.id, playlist.id);
      expect(music.playedContext?.title, playlist.title);
      expect(music.playedContext?.kind, MusicPlayContextKind.playlist);
      expect(music.shuffle, isFalse);

      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.mediaMenu.shufflePlay));
      await tester.pumpAndSettle();

      expect(music.callCount, 2);
      expect(music.playedTracks, tracks);
      expect(music.shuffle, isTrue);

      final staleFetchGate = Completer<void>();
      client.fetchGate = staleFetchGate;
      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pump();

      final newerTrack = testMediaItem(
        id: 'newer-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Newer Track',
        serverId: 'srv-1',
      );
      await music.playFromList(
        tracks: [newerTrack],
        playContext: const MusicPlayContext(title: 'Newer Queue', kind: MusicPlayContextKind.tracks),
      );
      staleFetchGate.complete();
      await tester.pumpAndSettle();

      expect(music.callCount, 3, reason: 'the stale playlist fetch must not start a fourth queue');
      expect(music.playedTracks, [newerTrack]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Jellyfin video playlist context Play exposes cancellable loading', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final client = _AudioPlaylistClient([
        testMediaItem(
          id: 'movie-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.movie,
          title: 'Movie',
          serverId: 'srv-1',
        ),
      ])..blockWithAbort = true;
      final playback = PlaybackStateProvider();
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        playback.dispose();
        await stack.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      const playlist = MediaPlaylist(
        id: 'playlist-video',
        backend: MediaBackend.jellyfin,
        title: 'Video Playlist',
        playlistType: 'video',
        serverId: 'srv-1',
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
              ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: playlist,
                    child: const SizedBox(width: 120, height: 80, child: Text('video target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('video target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t.common.cancel), findsOneWidget);
      expect(client.activeAbort, isNotNull);
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(client.activeAbort!.isAborted, isTrue);
      expect(playback.isQueueActive, isFalse);
      expect(find.text('video target'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('file info client resolution failure shows an error without popping another route', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final manager = MultiServerManager();
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        await stack.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'missing-server',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: item,
                    child: const SizedBox(width: 120, height: 80, child: Text('target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('target')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.mediaMenu.fileInfo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('target'), findsOneWidget);
    });

    testWidgets('playlist picker filters playlists by title', (tester) async {
      final playlists = [
        for (var i = 0; i < 10; i++) (id: '$i', title: 'Alpha $i'),
        (id: 'gamma', title: 'Gamma Nights'),
      ];
      final menuKey = await _pumpPlexMovieMenu(tester, playlists);

      await _openPlaylistPicker(tester, menuKey);
      final textField = tester.widget<TextField>(find.byType(TextField));
      textField.controller!.text = 'gamma';
      textField.onChanged!('gamma');
      await tester.pumpAndSettle();

      expect(find.text('Gamma Nights'), findsOneWidget);
      expect(find.text('Alpha 0'), findsNothing);
      expect(find.text(t.common.createNew), findsOneWidget);
    });

    testWidgets('playlist picker wires TV focus, D-pad down, and back', (tester) async {
      final playlists = [for (var i = 0; i < 10; i++) (id: '$i', title: 'Playlist $i')];
      final menuKey = await _pumpPlexMovieMenu(tester, playlists);

      await _openPlaylistPicker(tester, menuKey);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode!.hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(Focus.of(tester.element(find.text(t.common.createNew))).hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text(t.playlists.selectPlaylist), findsNothing);
      expect(find.text('picker target'), findsOneWidget);
    });

    testWidgets('track album action uses the profile navigator from the sibling menu overlay', (tester) async {
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Track',
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        parentId: 'artist-1',
        parentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: [album]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToAlbum);

      expect(find.byType(AlbumDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(AlbumDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('album artist action uses the profile navigator from the sibling menu overlay', (tester) async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        parentId: 'artist-1',
        parentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final artist = testMediaItem(
        id: 'artist-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.artist,
        title: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: album, relatedItems: [artist]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToArtist);

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(ArtistDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('track artist action uses the profile navigator from the sibling menu overlay', (tester) async {
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Track',
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final artist = testMediaItem(
        id: 'artist-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.artist,
        title: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: [artist]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToArtist);

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(ArtistDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('a slow music enqueue does not append to a newer queue session', (tester) async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        serverId: 'srv-1',
      );
      final albumTrack = testMediaItem(
        id: 'album-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Album Track',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: album, relatedItems: [albumTrack]);
      final fetchGate = Completer<void>();
      harness.client.albumTracksGate = fetchGate;

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.music.playNext));
      await tester.pump();

      final newerTrack = testMediaItem(
        id: 'newer-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Newer Track',
        serverId: 'srv-1',
      );
      await harness.music.playFromList(
        tracks: [newerTrack],
        playContext: const MusicPlayContext(title: 'Newer Queue', kind: MusicPlayContextKind.tracks),
      );
      fetchGate.complete();
      await tester.pumpAndSettle();

      expect(harness.music.addedNext, isEmpty);
      expect(harness.music.playedTracks, [newerTrack]);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<GlobalKey<MediaContextMenuState>> _pumpPlexMovieMenu(
  WidgetTester tester,
  List<({String id, String title})> playlists,
) async {
  LocaleSettings.setLocaleSync(AppLocale.en);
  TvDetectionService.debugSetAppleTVOverride(true);
  addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  final client = testPlexClient(
    config: PlexConfig(
      baseUrl: 'https://plex.example.com',
      token: 'token',
      clientIdentifier: 'client-id',
      product: 'Plezy',
      version: '1',
    ),
    serverId: ServerId('plex-1'),
    httpClient: MockClient((request) async {
      if (request.url.path != '/playlists') return http.Response('not found', 404);
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'size': playlists.length,
            'totalSize': playlists.length,
            'Metadata': [
              for (final playlist in playlists)
                {
                  'ratingKey': playlist.id,
                  'key': '/playlists/${playlist.id}/items',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': playlist.title,
                  'smart': false,
                },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);
  final stack = await ProfileStack.create(db: db, withStorage: false);
  addTearDown(() async {
    await stack.dispose();
    multiServerProvider.dispose();
    manager.dispose();
    await db.close();
  });

  final menuKey = GlobalKey<MediaContextMenuState>();
  final item = testMediaItem(
    id: 'movie-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'plex-1',
  );
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: Center(
              child: MediaContextMenu(
                key: menuKey,
                item: item,
                child: const SizedBox(width: 120, height: 80, child: Text('picker target')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return menuKey;
}

Future<void> _openPlaylistPicker(WidgetTester tester, GlobalKey<MediaContextMenuState> menuKey) async {
  menuKey.currentState!.showContextMenu(tester.element(find.text('picker target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.common.addTo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.playlists.playlist));
  await tester.pumpAndSettle();
  expect(find.text(t.playlists.selectPlaylist), findsOneWidget);
}

class _AudioPlaylistClient implements MediaServerClient {
  final List<MediaItem> tracks;
  Completer<void>? fetchGate;
  bool blockWithAbort = false;
  AbortController? activeAbort;

  _AudioPlaylistClient(this.tracks);

  @override
  ServerId get serverId => ServerId('srv-1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    if (blockWithAbort) {
      activeAbort = abort;
      if (abort == null) {
        await Completer<void>().future;
      } else {
        await abort.trigger;
        abort.throwIfAborted();
      }
    }
    await fetchGate?.future;
    return fakeLibraryPage(tracks, start: start, size: size);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingMusicPlaybackService extends StubMusicPlaybackService {
  List<MediaItem>? playedTracks;
  final List<MediaItem> addedNext = [];
  MusicPlayContext? playedContext;
  bool? shuffle;
  int callCount = 0;

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  }) async {
    await super.playFromList(tracks: tracks, startTrack: startTrack, playContext: playContext, shuffle: shuffle);
    callCount++;
    playedTracks = tracks;
    playedContext = playContext;
    this.shuffle = shuffle;
  }

  @override
  void addNext(List<MediaItem> tracks) {
    addedNext.addAll(tracks);
  }
}

class _RelatedMusicClient implements MediaServerClient {
  _RelatedMusicClient(Iterable<MediaItem> items)
    : _items = {for (final item in items) item.id: item},
      albumTracks = items.where((item) => item.kind == MediaKind.track).toList();

  final Map<String, MediaItem> _items;
  final List<MediaItem> albumTracks;
  Completer<void>? albumTracksGate;

  @override
  ServerId get serverId => ServerId('srv-1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<MediaItem?> fetchItem(String id) async => _items[id];

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async {
    await albumTracksGate?.future;
    return albumTracks;
  }

  @override
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist) async => const [];

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SiblingMusicMenuHarness {
  const _SiblingMusicMenuHarness({
    required this.rootNavigatorKey,
    required this.profileNavigatorKey,
    required this.menuKey,
    required this.music,
    required this.client,
  });

  final GlobalKey<NavigatorState> rootNavigatorKey;
  final GlobalKey<NavigatorState> profileNavigatorKey;
  final GlobalKey<MediaContextMenuState> menuKey;
  final _RecordingMusicPlaybackService music;
  final _RelatedMusicClient client;
}

Future<_SiblingMusicMenuHarness> _pumpSiblingMusicMenu(
  WidgetTester tester, {
  required MediaItem item,
  required List<MediaItem> relatedItems,
}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();
  LocaleSettings.setLocaleSync(AppLocale.en);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  JellyfinApiCache.initialize(db);
  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();
  final client = _RelatedMusicClient(relatedItems);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);
  final stack = await ProfileStack.create(db: db, withStorage: false);
  final music = _RecordingMusicPlaybackService();
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final profileNavigatorKey = GlobalKey<NavigatorState>();
  final menuKey = GlobalKey<MediaContextMenuState>();

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    await stack.dispose();
    music.dispose();
    multiServerProvider.dispose();
    manager.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.macOS),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
            ChangeNotifierProvider<MusicPlaybackService>.value(value: music),
          ],
          child: ProfileNavigationScope(
            navigatorKey: profileNavigatorKey,
            routeObserver: RouteObserver<PageRoute<dynamic>>(),
            mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Navigator(
                  key: profileNavigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Center(child: Text('profile content'))),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    child: MediaContextMenu(
                      key: menuKey,
                      item: item,
                      child: const SizedBox(
                        width: 180,
                        height: 64,
                        child: Center(child: Text('mini-player menu target')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  return _SiblingMusicMenuHarness(
    rootNavigatorKey: rootNavigatorKey,
    profileNavigatorKey: profileNavigatorKey,
    menuKey: menuKey,
    music: music,
    client: client,
  );
}

Future<void> _selectSiblingMusicMenuAction(
  WidgetTester tester,
  _SiblingMusicMenuHarness harness,
  String actionLabel,
) async {
  harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabel));
  await tester.pumpAndSettle();
}

PlexHomeUser _homeUser({required bool admin}) {
  return PlexHomeUser(
    id: 0,
    uuid: 'home-user',
    title: 'Home User',
    username: null,
    email: null,
    friendlyName: null,
    thumb: 'https://plex.tv/users/home-user/avatar',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: false,
  );
}

JellyfinConnection _jellyfinConnection() {
  return JellyfinConnection(
    id: 'srv-1/user-1',
    baseUrl: 'https://jf.example.com',
    serverName: 'Home',
    serverMachineId: 'srv-1',
    userId: 'user-1',
    userName: 'edde',
    accessToken: 'tok',
    deviceId: 'dev',
    isAdministrator: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
