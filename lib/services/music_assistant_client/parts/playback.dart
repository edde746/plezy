part of '../../music_assistant_client.dart';

/// Playback on this device.
///
/// Music Assistant pushes audio to a player it knows about, and stock servers
/// no longer offer one this app can stream from, so nothing resolves to a URL
/// here. Its tracks play on a speaker, through [MusicOutputController].
mixin _MusicAssistantPlaybackMethods on _MusicAssistantClientInternals {
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    throw PlaybackException('Music Assistant plays on speakers, not on this device. Choose a speaker first.');
  }

  /// Playback reporting is a no-op on this backend, deliberately.
  ///
  /// Music Assistant already knows what its own queue is doing, and there is no
  /// per-item watched flag or resume position to report into. These are called
  /// on every track, so they return quietly rather than throwing.
  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {}

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {}

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {}

  /// Deliberately unreachable: `positionMs / durationMs` cannot reach 2.0, so
  /// no amount of playback ever counts as watched here.
  ///
  /// There is no played flag on this backend — [markWatched] refuses outright,
  /// and rightly so, because a user asking to mark something played must not be
  /// told it worked when no server recorded it. The progress tracker's
  /// automatic end-of-track scrobble goes through the same refusal, though, and
  /// it is not a user asking for anything: with a crossable threshold every
  /// track that plays out logs a scrobble failure and schedules a retry that
  /// can never succeed. Saying the threshold is out of reach is the honest
  /// version of "there is nothing to cross into".
  @override
  double get watchedThreshold => 2.0;

  @override
  bool get marksWatchedOnPlaybackStopped => false;
}
