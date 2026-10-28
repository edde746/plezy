import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/subtitles/subtitle_search_result.dart';
import 'settings_service.dart';

/// Remembers provider subtitle revisions the viewer rejected so search and
/// automatic preferred-language downloads do not repeatedly offer the same row.
abstract final class SubtitleRejectionService {
  static const int maximumRememberedRevisions = 256;
  static const Duration retention = Duration(days: 180);

  static Future<void> _writeQueue = Future<void>.value();

  static String revisionKey({
    required String serverId,
    required String itemId,
    required int mediaIndex,
    required SubtitleSearchResult result,
  }) {
    final identity = <Object?>[
      serverId.trim(),
      itemId.trim(),
      mediaIndex,
      result.id,
      result.key.trim(),
      result.providerTitle?.trim().toLowerCase(),
      result.codec?.trim().toLowerCase(),
      (result.languageCode ?? result.language)?.trim().toLowerCase(),
      result.title?.trim(),
      result.displayTitle?.trim(),
      result.forced,
      result.hearingImpaired,
    ];
    return sha256.convert(utf8.encode(jsonEncode(identity))).toString();
  }

  static bool isRejected(
    SettingsService settings, {
    required String serverId,
    required String itemId,
    required int mediaIndex,
    required SubtitleSearchResult result,
  }) {
    if (result.key.trim().isEmpty) return false;
    try {
      final rejected = settings.read(SettingsService.subtitleRejectedRevisions);
      final timestamp = rejected[revisionKey(
        serverId: serverId,
        itemId: itemId,
        mediaIndex: mediaIndex,
        result: result,
      )];
      if (timestamp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      return age >= 0 && age <= retention.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  static Future<void> reject(
    SettingsService settings, {
    required String serverId,
    required String itemId,
    required int mediaIndex,
    required SubtitleSearchResult result,
  }) {
    if (result.key.trim().isEmpty) return Future<void>.value();
    final key = revisionKey(
      serverId: serverId,
      itemId: itemId,
      mediaIndex: mediaIndex,
      result: result,
    );
    return _enqueueWrite(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entries = _prune(settings.read(SettingsService.subtitleRejectedRevisions), now);
      entries[key] = now;
      while (entries.length > maximumRememberedRevisions) {
        final oldest = entries.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
        entries.remove(oldest);
      }
      await settings.write(SettingsService.subtitleRejectedRevisions, Map.unmodifiable(entries));
    });
  }

  static Future<void> restore(
    SettingsService settings, {
    required String serverId,
    required String itemId,
    required int mediaIndex,
    required SubtitleSearchResult result,
  }) {
    if (result.key.trim().isEmpty) return Future<void>.value();
    final key = revisionKey(
      serverId: serverId,
      itemId: itemId,
      mediaIndex: mediaIndex,
      result: result,
    );
    return _enqueueWrite(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entries = _prune(settings.read(SettingsService.subtitleRejectedRevisions), now);
      entries.remove(key);
      await settings.write(SettingsService.subtitleRejectedRevisions, Map.unmodifiable(entries));
    });
  }

  static Future<void> _enqueueWrite(Future<void> Function() action) {
    final previous = _writeQueue;
    final operation = previous.catchError((Object _, StackTrace __) {}).then((_) => action());
    _writeQueue = operation.catchError((Object _, StackTrace __) {});
    return operation;
  }

  static Map<String, int> _prune(Map<String, int> source, int now) {
    final cutoff = now - retention.inMilliseconds;
    return <String, int>{
      for (final entry in source.entries)
        if (entry.value >= cutoff && entry.value <= now) entry.key: entry.value,
    };
  }
}
