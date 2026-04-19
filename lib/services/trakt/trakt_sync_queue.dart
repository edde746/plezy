import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/trakt/trakt_ids.dart';
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
class TraktSyncQueue {
  static const String _baseKey = 'trakt_sync_queue';
  static const int maxAttempts = 5;

  Future<List<TraktSyncQueueItem>> load(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(traktUserKey(userUuid, _baseKey));
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => TraktSyncQueueItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String userUuid, List<TraktSyncQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = traktUserKey(userUuid, _baseKey);
    if (items.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, json.encode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> add(String userUuid, TraktSyncQueueItem item) async {
    final items = await load(userUuid);
    items.add(item);
    await save(userUuid, items);
  }
}
