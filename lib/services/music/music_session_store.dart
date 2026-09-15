import 'dart:convert';

import '../../database/app_database.dart';
import '../../media/media_item.dart';
import '../../utils/app_logger.dart';
import 'music_playback_service.dart';
import 'music_queue_controller.dart';

/// Everything needed to rebuild a parked music session on the next launch:
/// the full queue state plus provenance and the playhead. Volume is excluded —
/// it is already a global preference reapplied to every player.
class MusicSessionSnapshot {
  final MusicQueueState queue;
  final MusicPlayContext? playContext;
  final Duration position;

  const MusicSessionSnapshot({required this.queue, required this.playContext, required this.position});
}

/// Per-profile persistence for the last music session (#2148).
///
/// Serialization boundary between [MusicSessionSnapshot] and the
/// `MusicSessions` Drift row. [save] rewrites the whole row (queue JSON
/// included) and runs only on queue-shape/mode changes; [updateProgress] is
/// the cheap cursor/playhead write-through used on track changes, pauses, and
/// the throttled position tick. Decoding is best-effort: any malformed row is
/// discarded as a whole — restore must never produce a half-valid session.
class MusicSessionStore {
  MusicSessionStore({required this._database, required this._profileId});

  final AppDatabase _database;
  final String _profileId;

  /// Upper bound on persisted queue length. Oversized queues are windowed
  /// around the cursor in playback order (the permutation is materialized, so
  /// un-shuffling a restored oversized queue keeps the current order rather
  /// than recovering the original one) to bound row size and JSON work.
  static const int maxPersistedTracks = 1000;

  /// How much of an oversized queue's window sits *before* the cursor; the
  /// rest is upcoming tracks, which matter more to a resumed session.
  static const int _historyWindow = maxPersistedTracks ~/ 4;

  Future<void> save(MusicSessionSnapshot snapshot) async {
    final queue = _windowed(snapshot.queue);
    await _database.upsertMusicSession(
      MusicSessionRow(
        profileId: _profileId,
        queueJson: jsonEncode([for (final track in queue.items) track.toJson()]),
        orderJson: jsonEncode(queue.order),
        cursor: queue.cursor,
        shuffled: queue.shuffled,
        repeatMode: _repeatModeId(queue.repeatMode),
        contextTitle: snapshot.playContext?.title,
        contextKind: snapshot.playContext != null ? _contextKindId(snapshot.playContext!.kind) : null,
        positionMs: snapshot.position.inMilliseconds.clamp(0, 1 << 62),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> updateProgress({required int cursor, required Duration position}) {
    return _database.updateMusicSessionProgress(
      profileId: _profileId,
      cursor: cursor,
      positionMs: position.inMilliseconds.clamp(0, 1 << 62),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<MusicSessionSnapshot?> load() async {
    final row = await _database.getMusicSession(_profileId);
    if (row == null) return null;
    try {
      final itemsJson = jsonDecode(row.queueJson) as List<dynamic>;
      final items = [for (final json in itemsJson) MediaItem.fromJson(json as Map<String, dynamic>)];
      final order = [for (final index in jsonDecode(row.orderJson) as List<dynamic>) index as int];
      final repeatMode = _repeatModeFromId(row.repeatMode);
      if (repeatMode == null) return null;
      final contextKind = row.contextKind != null ? _contextKindFromId(row.contextKind!) : null;
      return MusicSessionSnapshot(
        queue: MusicQueueState(
          items: items,
          order: order,
          cursor: row.cursor,
          shuffled: row.shuffled,
          repeatMode: repeatMode,
        ),
        playContext: row.contextTitle != null && contextKind != null
            ? MusicPlayContext(title: row.contextTitle!, kind: contextKind)
            : null,
        position: Duration(milliseconds: row.positionMs < 0 ? 0 : row.positionMs),
      );
    } catch (e, st) {
      appLogger.w('Discarding malformed persisted music session', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> clear() => _database.deleteMusicSessionForProfile(_profileId);

  /// Materialize an oversized queue down to a [maxPersistedTracks]-long window
  /// of the playback order around the cursor (identity permutation).
  MusicQueueState _windowed(MusicQueueState state) {
    if (state.items.length <= maxPersistedTracks) return state;
    final queue = [for (final index in state.order) state.items[index]];
    final start = (state.cursor - _historyWindow).clamp(0, queue.length - maxPersistedTracks);
    return MusicQueueState(
      items: queue.sublist(start, start + maxPersistedTracks),
      order: [for (var i = 0; i < maxPersistedTracks; i++) i],
      cursor: state.cursor - start,
      shuffled: state.shuffled,
      repeatMode: state.repeatMode,
    );
  }

  /// Stable persisted ids — never the enum `.name`, which a rename would
  /// corrupt (same policy as [OfflineActionType.id]).
  static String _repeatModeId(MusicRepeatMode mode) => switch (mode) {
    MusicRepeatMode.off => 'off',
    MusicRepeatMode.all => 'all',
    MusicRepeatMode.one => 'one',
  };

  static MusicRepeatMode? _repeatModeFromId(String id) => switch (id) {
    'off' => MusicRepeatMode.off,
    'all' => MusicRepeatMode.all,
    'one' => MusicRepeatMode.one,
    _ => null,
  };

  static String _contextKindId(MusicPlayContextKind kind) => switch (kind) {
    MusicPlayContextKind.album => 'album',
    MusicPlayContextKind.artist => 'artist',
    MusicPlayContextKind.playlist => 'playlist',
    MusicPlayContextKind.mix => 'mix',
    MusicPlayContextKind.tracks => 'tracks',
  };

  static MusicPlayContextKind? _contextKindFromId(String id) => switch (id) {
    'album' => MusicPlayContextKind.album,
    'artist' => MusicPlayContextKind.artist,
    'playlist' => MusicPlayContextKind.playlist,
    'mix' => MusicPlayContextKind.mix,
    'tracks' => MusicPlayContextKind.tracks,
    _ => null,
  };
}
