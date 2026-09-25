import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/downloaded_video_source.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/saf_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/pump.dart';
import '../test_helpers/saf_fakes.dart';

void main() {
  testWidgets('replacement releases the native owner and Back never exposes an abandoned player', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final pages = <_PlaybackPageState>[];
    int? nativeOwner;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') {
          if (nativeOwner != null) throw PlatformException(code: 'owner_still_active');
          nativeOwner = (call.arguments as Map)['instanceId'] as int;
          return true;
        }
        if (call.method == 'dispose') {
          if (nativeOwner == (call.arguments as Map)['instanceId']) nativeOwner = null;
        }
        return null;
      },
      testBody: () async {
        Future<bool?> launch(String name) => VideoPlayerRoute(
          builder: (_) => _PlaybackPage(name: name, onCreate: pages.add),
        ).push(navigator.currentState!);

        try {
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              home: const Scaffold(body: Text('Browse')),
            ),
          );
          final first = launch('First');
          await pumpUntil(tester, () => find.text('First ready').evaluate().isNotEmpty);

          unawaited(launch('Second'));
          await pumpUntil(tester, () => find.text('Second ready').evaluate().isNotEmpty);
          expect(await first, isTrue, reason: 'the original caller must refresh its watch state after replacement');
          expect(find.byType(_PlaybackPage, skipOffstage: false), findsOneWidget);

          // A settings/detail route above the player is not ours to remove.
          unawaited(
            navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Cover')))),
          );
          await tester.pumpAndSettle();
          unawaited(launch('Third'));
          await pumpUntil(tester, () => find.text('Third ready').evaluate().isNotEmpty);
          expect(find.byType(_PlaybackPage, skipOffstage: false), findsOneWidget);

          // Neither incoming page has reached initState at the second commit.
          unawaited(launch('Superseded'));
          unawaited(launch('Latest'));
          await pumpUntil(tester, () => find.text('Latest ready').evaluate().isNotEmpty);
          expect(find.byType(_PlaybackPage, skipOffstage: false), findsOneWidget);

          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Cover'), findsOneWidget);
          expect(find.byType(_PlaybackPage, skipOffstage: false), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Browse'), findsOneWidget);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await pumpUntil(tester, () => pages.every((page) => page.retired));
        }
        expect(nativeOwner, isNull);
      },
    );
  });

  group('video player launch identity', () {
    final plexA = testMediaItem(
      id: '123',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Plex A',
      serverId: 'plex-a',
    );
    final plexB = testMediaItem(
      id: '123',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Plex B',
      serverId: 'plex-b',
    );
    final jellyfin = testMediaItem(
      id: '123',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Jellyfin',
      serverId: 'jellyfin-a',
    );

    VideoPlayerLaunchIdentity identity(
      MediaItem item, {
      int mediaIndex = 0,
      String? sourceId,
      TranscodeQualityPreset? quality,
      bool isOffline = false,
      VideoPlayerRouteKind routeKind = VideoPlayerRouteKind.vod,
    }) {
      return VideoPlayerLaunchIdentity(
        metadata: item,
        mediaIndex: mediaIndex,
        selectedMediaSourceId: sourceId,
        selectedQualityPreset: quality,
        isOffline: isOffline,
        routeKind: routeKind,
      );
    }

    test('active guard blocks only the complete server-qualified route target', () {
      final guard = VideoPlayerActiveRouteGuard();
      final owner = Object();
      final target = identity(plexA);
      guard.activate(owner, target);

      expect(guard.activeGlobalKey, 'plex-a:123');
      expect(guard.blocks(target), isTrue);
      expect(guard.blocks(identity(plexB)), isFalse);
      expect(guard.blocks(identity(jellyfin)), isFalse);
      expect(guard.blocks(identity(plexA, mediaIndex: 1)), isFalse);
      expect(guard.blocks(identity(plexA, sourceId: 'source-b')), isFalse);
      expect(guard.blocks(identity(plexA, quality: TranscodeQualityPreset.p720_4mbps)), isFalse);
      expect(guard.blocks(identity(plexA, isOffline: true)), isFalse);
      expect(guard.blocks(identity(plexA, routeKind: VideoPlayerRouteKind.liveTv)), isFalse);
    });

    test('blank and null source IDs identify the same route target', () {
      expect(identity(plexA, sourceId: ''), identity(plexA));
      expect(identity(plexA, sourceId: '   '), identity(plexA));
    });

    test('owner checks preserve a replacement and support exact rollback', () {
      final guard = VideoPlayerActiveRouteGuard();
      final ownerA = Object();
      final ownerB = Object();
      final initial = identity(plexA, sourceId: 'source-a');
      final replacement = identity(plexB, quality: TranscodeQualityPreset.p1080_8mbps);
      guard.activate(ownerA, initial);
      guard.activate(ownerB, replacement);

      expect(guard.clear(ownerA), isFalse);
      expect(guard.update(ownerA, identity(jellyfin)), isFalse);
      expect(guard.blocks(replacement), isTrue);

      final beforeReload = guard.identityFor(ownerB);
      final reloadTarget = identity(plexB, sourceId: 'source-b', quality: TranscodeQualityPreset.p720_4mbps);
      expect(guard.update(ownerB, reloadTarget), isTrue);
      expect(guard.blocks(reloadTarget), isTrue);
      expect(guard.update(ownerB, beforeReload!), isTrue);
      expect(guard.blocks(replacement), isTrue);

      expect(guard.clear(ownerB), isTrue);
      expect(guard.activeGlobalKey, isNull);
    });
  });

  group('media version preference persistence', () {
    const versions = [
      MediaVersion(id: '101', videoResolution: '1080', videoCodec: 'h264', container: 'mkv'),
      MediaVersion(id: '102', videoResolution: '4k', videoCodec: 'hevc', container: 'mkv'),
    ];

    final episode = testMediaItem(
      id: 'ep-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      serverId: 'srv-1',
      grandparentId: 'show-1',
      mediaVersions: versions,
    );

    setUp(() {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
    });

    test('save writes under the server-scoped series key', () async {
      await saveMediaVersionPreferenceFor(episode, index: 1, versions: versions);

      final settings = await SettingsService.getInstance();
      final prefs = settings.read(SettingsService.mediaVersionPreferences);
      expect(prefs.keys, ['srv-1:show-1']);
      expect(prefs['srv-1:show-1']!.versionId, '102');
      expect(prefs['srv-1:show-1']!.signature, '4k:hevc:mkv');
      expect(prefs['srv-1:show-1']!.index, 1);
    });

    test('reads legacy unscoped-key int entries and migrates them on write', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          'media_version_preferences': jsonEncode({'show-1': 1}),
        },
      );
      SettingsService.resetForTesting();

      final saved = await savedMediaVersionPreferenceFor(episode);
      expect(saved, isNotNull);
      expect(saved!.index, 1);
      expect(saved.versionId, isNull);

      await saveMediaVersionPreferenceFor(episode, index: 0, versions: versions);
      final settings = await SettingsService.getInstance();
      final prefs = settings.read(SettingsService.mediaVersionPreferences);
      expect(prefs.keys, ['srv-1:show-1']);
      expect(prefs['srv-1:show-1']!.versionId, '101');
    });

    test('resolveSavedMediaVersionFor verifies against populated mediaVersions', () async {
      // Stored index points at 0, but the id pins version 102 → index 1.
      resetSharedPreferencesForTest(
        initialAsync: {
          'media_version_preferences': jsonEncode({
            'srv-1:show-1': {'id': '102', 'sig': '4k:hevc:mkv', 'idx': 0},
          }),
        },
      );
      SettingsService.resetForTesting();

      final resolved = await resolveSavedMediaVersionFor(episode);
      expect(resolved, isNotNull);
      expect(resolved!.index, 1);
      expect(resolved.sourceId, '102');
      expect(resolved.signature, '4k:hevc:mkv');
    });

    test('resolveSavedMediaVersionFor passes stored index/signature through without versions', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          'media_version_preferences': jsonEncode({
            'srv-1:show-1': {'id': '102', 'sig': '4k:hevc:mkv', 'idx': 1},
          }),
        },
      );
      SettingsService.resetForTesting();

      final bare = testMediaItem(
        id: 'ep-2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        title: 'Episode 2',
        serverId: 'srv-1',
        grandparentId: 'show-1',
      );
      final resolved = await resolveSavedMediaVersionFor(bare);
      expect(resolved, isNotNull);
      expect(resolved!.index, 1);
      // An id from another item must not be forwarded as an explicit pick.
      expect(resolved.sourceId, isNull);
      expect(resolved.signature, '4k:hevc:mkv');
    });

    test('resolveSavedMediaVersionFor returns null when nothing is stored', () async {
      expect(await resolveSavedMediaVersionFor(episode), isNull);
    });
  });

  group('launching a downloaded item while its server is reachable (issue #2466)', () {
    const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
    const localCopy = 'content://sdcard/Movie.mkv';
    final movie = testMediaItem(id: 'movie-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv');
    // Only the second version is on disk, so a launch that ignored the
    // download would request version 0 and stream it.
    final downloadedRow = DownloadedMediaItem(
      id: 1,
      serverId: 'srv',
      ratingKey: 'movie-1',
      globalKey: 'srv:movie-1',
      type: 'movie',
      status: DownloadStatus.completed.index,
      progress: 100,
      downloadedBytes: 0,
      videoFilePath: localCopy,
      retryCount: 0,
      mediaIndex: 1,
      mediaSourceId: 'v1',
    );

    late List<String> externalLaunches;
    late _ExternalUrlClient client;

    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      SafStorageService.setOpsForTesting(FakeSafStorage());
      await (await SettingsService.getInstance()).write(SettingsService.useExternalPlayer, true);
      externalLaunches = [];
      client = _ExternalUrlClient();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(urlLauncherChannel, (
        call,
      ) async {
        if (call.method != 'launch') return null;
        externalLaunches.add((call.arguments as Map)['url'] as String);
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        urlLauncherChannel,
        null,
      );
      SafStorageService.setOpsForTesting(null);
      SettingsService.resetForTesting();
    });

    Future<void> launch(WidgetTester tester, {int? selectedMediaIndex, String? selectedMediaSourceId}) async {
      final servers = testMultiServer(clients: [client]);
      final downloads = _CompletedDownloads(downloadedRow);
      final offlineWatch = _OfflineWatchSync();
      addTearDown(downloads.dispose);
      addTearDown(offlineWatch.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: servers.provider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloads),
            ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
          ],
          child: const MaterialApp(home: Scaffold(body: Text('Detail'))),
        ),
      );
      unawaited(
        navigateToVideoPlayer(
          tester.element(find.text('Detail')),
          metadata: movie,
          selectedMediaIndex: selectedMediaIndex,
          selectedMediaSourceId: selectedMediaSourceId,
          resolveWatchState: false,
        ),
      );
      await pumpUntil(tester, () => externalLaunches.isNotEmpty, describe: () => 'no external player launch');
    }

    testWidgets('plain Play hands the external player the downloaded copy', (tester) async {
      await launch(tester);

      expect(externalLaunches, [localCopy]);
      expect(client.resolvedMediaIndexes, isEmpty, reason: 'the server must not be asked for a stream');
    });

    testWidgets('an explicitly chosen version that is not downloaded streams from the server', (tester) async {
      await launch(tester, selectedMediaIndex: 0, selectedMediaSourceId: 'v0');

      expect(externalLaunches, ['https://server/stream/0']);
      expect(client.resolvedMediaIndexes, [0]);
    });
  });
}

/// A route-owned real Dart player: native calls are mocked, but ownership
/// acquisition, event-channel handoff and asynchronous disposal are not.
class _PlaybackPage extends StatefulWidget {
  const _PlaybackPage({required this.name, required this.onCreate});

  final String name;
  final ValueChanged<_PlaybackPageState> onCreate;

  @override
  State<_PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<_PlaybackPage> {
  late final PlayerNative player;
  String status = 'loading';
  bool retired = false;

  @override
  void initState() {
    super.initState();
    player = PlayerNative();
    widget.onCreate(this);
    unawaited(() async {
      try {
        await player.setProperty('pause', 'no');
        if (mounted) setState(() => status = 'ready');
      } catch (_) {
        if (mounted) setState(() => status = 'failed');
      }
    }());
  }

  @override
  void dispose() {
    unawaited(player.dispose().whenComplete(() => retired = true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Text('${widget.name} $status'));
}

class _ExternalUrlClient implements MediaServerClient {
  final resolvedMediaIndexes = <int>[];

  @override
  ServerId get serverId => ServerId('srv');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalPlaybackTarget?> resolveExternalPlayback(
    MediaItem item, {
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    resolvedMediaIndexes.add(mediaIndex);
    return ExternalPlaybackTarget(url: 'https://server/stream/$mediaIndex');
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One completed download, resolved through the production version-match and
/// reachability rules.
class _CompletedDownloads extends ChangeNotifier implements DownloadProvider {
  _CompletedDownloads(this.row);

  final DownloadedMediaItem row;

  @override
  bool isDownloaded(String globalKey) => globalKey == row.globalKey;

  @override
  Future<DownloadedMediaItem?> getCompletedDownload(String globalKey) async => globalKey == row.globalKey ? row : null;

  @override
  Future<String?> getVideoFilePath(String globalKey, {int? mediaIndex, String? mediaSourceId}) async {
    if (globalKey != row.globalKey) return null;
    final source = await resolveDownloadedVideoSource(
      row,
      requestedMediaIndex: mediaIndex,
      requestedMediaSourceId: mediaSourceId,
    );
    return source?.path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OfflineWatchSync extends ChangeNotifier implements OfflineWatchSyncService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
