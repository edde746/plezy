import '../utils/app_logger.dart';
import '../utils/session_identifier.dart';
import 'jellyfin_client.dart';
import 'playback_report_session.dart';

/// Lightweight state machine for Jellyfin live TV playback heartbeats.
///
/// Delegates start/progress/stop ordering to [PlaybackReportSession] so live
/// heartbeats follow the same terminal-state rules as normal playback. The
/// Plex live path keeps its bespoke capture-buffer flow inline at the call
/// site; this tracker only covers Jellyfin's `/Sessions/Playing*` flow.
class JellyfinLiveSessionTracker {
  JellyfinLiveSessionTracker({String? playSessionId}) : _playSessionId = playSessionId ?? generateSessionIdentifier();

  final String _playSessionId;
  PlaybackReportSession? _session;

  /// Session id reused across all heartbeats for this playback. Exposed
  /// for callers that need to thread it elsewhere (e.g. analytics logs).
  String get playSessionId => _playSessionId;

  /// Send the appropriate heartbeat for [state] (`'playing'`, `'paused'`,
  /// or `'stopped'`). Errors are swallowed — heartbeats are best-effort.
  Future<void> report({
    required JellyfinClient client,
    required String itemId,
    required String state,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      final session = _session ??= PlaybackReportSession(client: client, itemId: itemId, playSessionId: _playSessionId);
      await session.report(PlaybackReportSnapshot(state: state, position: position, duration: duration));
    } catch (e) {
      appLogger.d('Jellyfin live progress report failed', error: e);
    }
  }
}
