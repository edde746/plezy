import 'dart:async';
import 'dart:convert';

import '../../models/trakt/trakt_ids.dart';
import '../base_shared_preferences_service.dart';
import '../../utils/app_logger.dart';
import 'trakt_constants.dart';

/// One pending watched/unwatched push waiting to be drained to Trakt.
class TraktSyncQueueItem {
  final TraktSyncOp op;
  final String ratingKey;
  final String serverId;
  final TraktMediaKind kind;
  final TraktIds ids;

  /// For episodes only.
  final int? season;
  final int? number;

  final String watchedAtIso;
  final int attempts;

  const TraktSyncQueueItem({
    required this.op,
    required this.ratingKey,
    required this.serverId,
    required this.kind,
    required this.ids,
    required this.watchedAtIso,
    this.season,
    this.number,
    this.attempts = 0,
  });

  TraktSyncQueueItem incrementAttempts() => TraktSyncQueueItem(
    op: op,
    ratingKey: ratingKey,
    serverId: serverId,
    kind: kind,
    ids: ids,
    watchedAtIso: watchedAtIso,
    season: season,
    number: number,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => {
    'op': op.name,
    'ratingKey': ratingKey,
    'serverId': serverId,
    'kind': kind.name,
    'ids': ids.toJson(),
    if (season != null) 'season': season,
    if (number != null) 'number': number,
    'watchedAtIso': watchedAtIso,
    'attempts': attempts,
  };

  factory TraktSyncQueueItem.fromJson(Map<String, dynamic> json) => TraktSyncQueueItem(
    op: TraktSyncOp.fromName(json['op'] as String),
    ratingKey: json['ratingKey'] as String,
    serverId: json['serverId'] as String,
    kind: TraktMediaKind.fromName(json['kind'] as String),
    ids: TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
    season: (json['season'] as num?)?.toInt(),
    number: (json['number'] as num?)?.toInt(),
    watchedAtIso: json['watchedAtIso'] as String,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
  );
}

/// Per-profile persisted retry queue for failed Trakt history pushes.
///
/// Cap at [maxAttempts] before dropping permanently — matches
/// `OfflineWatchSyncService.maxSyncAttempts`.
///
/// Serialises all writes (`add`, `save`, `drainWith`) through a Completer chain
/// so concurrent `add()` calls don't interleave read-modify-write and lose items.
class TraktSyncQueue {
  static const String _baseKey = 'trakt_sync_queue';
  static const int maxAttempts = 5;

  Future<void> _writeLock = Future<void>.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final previous = _writeLock;
    final completer = Completer<void>();
    _writeLock = completer.future;
    return previous.then((_) => action()).whenComplete(completer.complete);
  }

  Future<List<TraktSyncQueueItem>> load(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final key = traktUserKey(userUuid, _baseKey);
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => TraktSyncQueueItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      appLogger.e('Trakt sync queue parse failed, discarding', error: e, stackTrace: st);
      await prefs.setString(traktUserKey(userUuid, '${_baseKey}_corrupt'), raw);
      await prefs.remove(key);
      return [];
    }
  }

  Future<void> save(String userUuid, List<TraktSyncQueueItem> items) {
    return _locked(() => _saveRaw(userUuid, items));
  }

  Future<void> _saveRaw(String userUuid, List<TraktSyncQueueItem> items) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final key = traktUserKey(userUuid, _baseKey);
    if (items.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, json.encode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> add(String userUuid, TraktSyncQueueItem item) {
    return _locked(() async {
      final items = await load(userUuid);
      items.add(item);
      await _saveRaw(userUuid, items);
    });
  }

  /// Atomic drain: load the queue, run [processor] for each item, and save the
  /// items the processor decided to retain. Holds the write lock for the whole
  /// cycle so concurrent `add()`s wait until the drain completes (no lost items).
  ///
  /// [processor] returns `null` to drop the item, or a (possibly mutated) item
  /// to retain for the next drain (e.g. `item.incrementAttempts()`).
  Future<void> drainWith(String userUuid, Future<TraktSyncQueueItem?> Function(TraktSyncQueueItem) processor) {
    return _locked(() async {
      final items = await load(userUuid);
      if (items.isEmpty) return;
      final remaining = <TraktSyncQueueItem>[];
      for (final item in items) {
        final keep = await processor(item);
        if (keep != null) remaining.add(keep);
      }
      await _saveRaw(userUuid, remaining);
    });
  }
}
