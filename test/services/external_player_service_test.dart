import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/playback_report_metadata.dart';
import 'package:plezy/services/external_player_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';

class _RecordingClient implements MediaServerClient {
  bool failStart = false;
  bool failStop = false;
  final started = <({int positionMs, int? durationMs})>[];
  final stopped = <({int positionMs, int? durationMs})>[];

  @override
  String get serverId => 'srv';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  double get watchedThreshold => 0.9;

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    started.add((positionMs: position.inMilliseconds, durationMs: duration?.inMilliseconds));
    if (failStart) throw StateError('start failed');
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    stopped.add((positionMs: position.inMilliseconds, durationMs: duration?.inMilliseconds));
    if (failStop) throw StateError('stop failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item({int? durationMs}) {
  return MediaItem(
    id: 'item-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: 'srv',
    durationMs: durationMs,
  );
}

void main() {
  test('Android external progress preserves null duration and still stops after start failure', () async {
    final client = _RecordingClient()..failStart = true;

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
      positionMs: 5000,
      durationMs: null,
      metadata: _item(),
      client: client,
    );

    expect(client.started, [(positionMs: 5000, durationMs: null)]);
    expect(client.stopped, [(positionMs: 5000, durationMs: null)]);
  });

  test('Android external progress queues unknown-duration resume when no client is available', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    final service = OfflineWatchSyncService(database: db, serverManager: manager);
    addTearDown(() async {
      service.dispose();
      manager.dispose();
      await db.close();
    });

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
      positionMs: 5000,
      durationMs: null,
      metadata: _item(),
      client: null,
      offlineWatchService: service,
    );

    final action = await db.getLatestWatchAction('srv:item-1');
    expect(action, isNotNull);
    expect(action!.viewOffset, 5000);
    expect(action.duration, isNull);
    expect(action.shouldMarkWatched, isFalse);
  });
}
