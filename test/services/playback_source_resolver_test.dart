import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playback_context.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_source_resolver.dart';
import '../test_helpers/media_items.dart';

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
      metadata: testMediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
      selectedMediaIndex: 0,
      offlineLibraryMode: false,
      qualityPreset: TranscodeQualityPreset.original,
    );

    expect(context.result.videoUrl, 'https://example.com/video.mp4');
    expect(context.reportingClient, same(client));
    expect(context.reportingMode, PlaybackReportingMode.online);
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
      metadata: testMediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
      selectedMediaIndex: 0,
      offlineLibraryMode: false,
      qualityPreset: TranscodeQualityPreset.original,
      sessionIdentifier: 'playback-session-id',
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
      metadata: testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv'),
      selectedMediaIndex: 0,
      offlineLibraryMode: false,
      qualityPreset: TranscodeQualityPreset.original,
      sessionIdentifier: 'playback-session-id',
    );

    expect(context.sourceKind, PlaybackSourceKind.remoteDirect);
    expect(context.streamHeaders, isNot(contains('X-Plex-Session-Identifier')));
  });
}
