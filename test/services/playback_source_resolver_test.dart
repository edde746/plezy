import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playback_context.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_source_resolver.dart';
import 'package:plezy/services/saf_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/io_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/saf_fakes.dart';

class _PlaybackClient implements MediaServerClient {
  _PlaybackClient({this.clientBackend = MediaBackend.plex, PlaybackInitializationResult? result})
    : result =
          result ??
          PlaybackInitializationResult(availableVersions: const [], videoUrl: 'https://example.com/video.mp4');

  final MediaBackend clientBackend;
  final PlaybackInitializationResult result;

  @override
  ServerId get serverId => ServerId('srv');

  @override
  MediaBackend get backend => clientBackend;

  @override
  double get watchedThreshold => 0.9;

  @override
  Map<String, String> get streamHeaders => const {'X-Test': 'token'};

  @override
  void close() {}

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('online playback uses registered client even when status is stale offline', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final client = _PlaybackClient();
    manager.debugRegisterClientForTesting(client, online: false);

    final context = await PlaybackSourceResolver(serverManager: manager, database: db).resolve(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.original,
      ),
      offlineLibraryMode: false,
    );

    expect(context.result.videoUrl, 'https://example.com/video.mp4');
    expect(context.reportingClient, same(client));
    expect(context.reportingMode, PlaybackReportingMode.online);
  });

  test('offline launch cannot fall through to a live server when the download is missing', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });
    manager.debugRegisterClientForTesting(_PlaybackClient(), online: true);
    await expectLater(
      PlaybackSourceResolver(serverManager: manager, database: db).resolve(
        PlaybackInitializationOptions(
          metadata: testMediaItem(
            id: 'missing-download',
            backend: MediaBackend.plex,
            kind: MediaKind.movie,
            serverId: 'srv',
          ),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.original,
        ),
        offlineLibraryMode: true,
      ),
      throwsA(
        isA<PlaybackException>().having((error) => error.reason, 'reason', PlaybackFailureReason.noPlayableSource),
      ),
    );
  });

  test('plex direct playback adds playback session header to stream headers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final client = _PlaybackClient();
    manager.debugRegisterClientForTesting(client, online: true);

    final context = await PlaybackSourceResolver(serverManager: manager, database: db).resolve(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.original,
        sessionIdentifier: 'playback-session-id',
      ),
      offlineLibraryMode: false,
    );

    expect(context.sourceKind, PlaybackSourceKind.remoteDirect);
    expect(context.streamHeaders, containsPair('X-Test', 'token'));
    expect(context.streamHeaders, containsPair('X-Plex-Session-Identifier', 'playback-session-id'));
  });

  test('non-plex direct playback does not add plex session header', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final client = _PlaybackClient(clientBackend: MediaBackend.jellyfin);
    manager.debugRegisterClientForTesting(client, online: true);

    final context = await PlaybackSourceResolver(serverManager: manager, database: db).resolve(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv'),
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.original,
        sessionIdentifier: 'playback-session-id',
      ),
      offlineLibraryMode: false,
    );

    expect(context.sourceKind, PlaybackSourceKind.remoteDirect);
    expect(context.streamHeaders, isNot(contains('X-Plex-Session-Identifier')));
  });

  group('downloaded copy under a capped quality preset (issue #2466)', () {
    late AppDatabase db;
    late MultiServerManager manager;
    late Directory tmpRoot;
    late PathProviderPlatform previousPathProvider;

    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      // The download lives on SD-card SAF storage, as in the report.
      SafStorageService.setOpsForTesting(FakeSafStorage());
      tmpRoot = await Directory.systemTemp.createTemp('playback_source_resolver_test_');
      previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      manager = MultiServerManager()..debugRegisterClientForTesting(_PlaybackClient(), online: true);
      await db
          .into(db.downloadedMedia)
          .insert(
            DownloadedMediaCompanion.insert(
              serverId: ServerId('srv'),
              ratingKey: 'movie-1',
              globalKey: 'srv:movie-1',
              type: 'movie',
              status: DownloadStatus.completed.index,
              videoFilePath: const Value('content://sdcard/movie-1.mkv'),
            ),
          );
    });

    tearDown(() async {
      manager.dispose();
      await db.close();
      SafStorageService.setOpsForTesting(null);
      DownloadStorageService.resetForTesting();
      SettingsService.resetForTesting();
      PathProviderPlatform.instance = previousPathProvider;
      await tmpRoot.delete(recursive: true);
    });

    Future<PlaybackContext> resolveAt720p({required bool downloadOutranksQuality}) {
      return PlaybackSourceResolver(serverManager: manager, database: db).resolve(
        PlaybackInitializationOptions(
          metadata: testMediaItem(id: 'movie-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.p720_2mbps,
        ),
        offlineLibraryMode: false,
        downloadOutranksQuality: downloadOutranksQuality,
      );
    }

    test('a saved default quality plays the download while the server is reachable', () async {
      final context = await resolveAt720p(downloadOutranksQuality: true);

      expect(context.sourceKind, PlaybackSourceKind.localFile);
      expect(context.result.videoUrl, 'content://sdcard/movie-1.mkv');
      expect(context.reportingMode, PlaybackReportingMode.onlineWithOfflineFallback);
    });

    test('a quality picked for this playback streams from the server', () async {
      final context = await resolveAt720p(downloadOutranksQuality: false);

      expect(context.sourceKind, PlaybackSourceKind.remoteDirect);
      expect(context.result.videoUrl, 'https://example.com/video.mp4');
    });
  });
}
