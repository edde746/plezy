import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playback_context.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_source_resolver.dart';

class _PlaybackClient implements MediaServerClient {
  @override
  String get serverId => 'srv';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  double get watchedThreshold => 0.9;

  @override
  Map<String, String> get streamHeaders => const {'X-Test': 'token'};

  @override
  void close() {}

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    return PlaybackInitializationResult(availableVersions: const [], videoUrl: 'https://example.com/video.mp4');
  }

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
      metadata: MediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
      selectedMediaIndex: 0,
      offlineLibraryMode: false,
      qualityPreset: TranscodeQualityPreset.original,
    );

    expect(context.result.videoUrl, 'https://example.com/video.mp4');
    expect(context.reportingClient, same(client));
    expect(context.reportingMode, PlaybackReportingMode.online);
  });
}
