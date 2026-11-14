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
  JellyfinLiveSessionTracker({String? playSessionId, this.mediaSourceId, this.liveStreamId, this.playMethod})
    : _playSessionId = playSessionId ?? generateSessionIdentifier();

  final String _playSessionId;
  final String? mediaSourceId;
  final String? liveStreamId;
  final String? playMethod;
  PlaybackReportSession? _session;

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
      // Rebuilt when the client changes, not just when there isn't one: a
      // token refresh mid-broadcast hands in a fresh client, and `??=` kept
      // reporting against the disposed one for the rest of the session.
      final existing = _session;
      final session = existing != null && identical(existing.client, client)
          ? existing
          : (_session = PlaybackReportSession(
              client: client,
              itemId: itemId,
              playSessionId: _playSessionId,
              playMethod: playMethod,
              liveStreamId: liveStreamId,
            ));
      await session.report(
        PlaybackReportSnapshot(
          state: state,
          position: position,
          duration: duration,
          resolveStreamSelection: () => PlaybackStreamSelection(mediaSourceId: mediaSourceId),
        ),
      );
    } catch (e) {
      appLogger.d('Jellyfin live progress report failed', error: e);
    }
  }
}
