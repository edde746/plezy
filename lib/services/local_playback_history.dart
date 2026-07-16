import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../utils/app_logger.dart';
import 'settings_service.dart';

/// Device-local record of when items were last played, keyed by item
/// [MediaItem.globalKey] and, for episodes/seasons, also by
/// [MediaItem.seriesGlobalKey] (#1492).
///
/// Servers have no per-version/per-sibling "last played" signal (a Plex
/// timeline report carries no media id, and guid-linked duplicates share
/// synced watch state), so this local history is what lets the Continue
/// Watching dedup keep the sibling the user actually played.
class LocalPlaybackHistory {
  LocalPlaybackHistory._();

  static const _maxEntries = 400;

  /// Repeat writes for the same item within this window are skipped —
  /// in-place reloads (seek transcode restarts, track switches) re-commit
  /// the same session and don't need to re-serialize the map each time.
  static const _rewriteIntervalMs = 60 * 1000;

  static String? _lastRecordedKey;
  static int _lastRecordedAtMs = 0;

  /// Test-only: clear the same-item rewrite suppression.
  @visibleForTesting
  static void resetForTesting() {
    _lastRecordedKey = null;
    _lastRecordedAtMs = 0;
  }

  /// Record that [item] just started playing. Best-effort: playback must
  /// never fail on a preferences error.
  static Future<void> recordPlayback(MediaItem item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = item.globalKey;
    if (key == _lastRecordedKey && now - _lastRecordedAtMs < _rewriteIntervalMs) return;
    try {
      final settings = await SettingsService.getInstance();
      final updated = {...settings.read(SettingsService.localLastPlayedAt), key: now};
      final seriesKey = item.seriesGlobalKey;
      if (seriesKey != null) updated[seriesKey] = now;
      await settings.write(SettingsService.localLastPlayedAt, _prune(updated));
      _lastRecordedKey = key;
      _lastRecordedAtMs = now;
    } catch (e) {
      appLogger.w('Failed to record local playback history for $key', error: e);
    }
  }

  /// One read of the full history for a dedup pass. Empty on any error.
  static Future<Map<String, int>> snapshot() async {
    try {
      final settings = await SettingsService.getInstance();
      return settings.read(SettingsService.localLastPlayedAt);
    } catch (_) {
      return const {};
    }
  }

  static Map<String, int> _prune(Map<String, int> history) {
    if (history.length <= _maxEntries) return history;
    final entries = history.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(_maxEntries));
  }
}
