import 'package:flutter/foundation.dart';

import '../../media/lyrics.dart';
import '../../media/media_item.dart';

/// Repeat behavior of the music queue.
enum MusicRepeatMode { off, all, one }

/// Coarse playback state of the music session.
enum MusicPlaybackStatus { idle, loading, playing, paused, error }

/// What kind of container playback was started from. The player keeps
/// artist/playlist/mix provenance stable, while album and ad-hoc queues use
/// the active track's album for the "Playing from …" line.
enum MusicPlayContextKind { album, artist, playlist, mix, tracks }

/// Outcome of [MusicPlaybackService.playInstantMix]. Fetch failures throw
/// instead of surfacing here; [superseded] means a newer play request claimed
/// the session while the mix was loading, so the caller must stay silent.
enum InstantMixOutcome { started, empty, superseded }

/// Provenance of the current queue (album/artist/playlist/instant mix).
class MusicPlayContext {
  /// Display title of the session source. Used directly for stable
  /// artist/playlist/mix provenance labels.
  final String title;

  final MusicPlayContextKind kind;

  const MusicPlayContext({required this.title, required this.kind});
}

/// Backend-neutral music playback session: owns the audio `Player`, the
/// queue (shuffle/repeat), OS media-session feed, and progress reporting.
///
/// UI consumes this via `context.watch<MusicPlaybackService>()` — it is
/// registered per profile session (see `profile_session_screen.dart`) so a
/// profile switch tears the session down. [notifyListeners] fires only on
/// discrete changes (track, status, queue shape, modes) — progress bars
/// subscribe to [positionStream] instead.
abstract class MusicPlaybackService extends ChangeNotifier {
  MediaItem? get currentTrack;
  MusicPlaybackStatus get status;
  bool get isPlaying => status == MusicPlaybackStatus.playing;

  Duration? get duration;
  Duration get position;
  Stream<Duration> get positionStream;

  /// Mirrors `Player.streams.playheadJump`: something is moving the playhead
  /// discontinuously, to this position, or to somewhere only the backend knows
  /// when null. Request-time intent, not an observed landing.
  /// Consumers coalescing their own relative seeks use it to drop a pending
  /// target something else superseded (#1819).
  Stream<Duration?> get playheadJumpStream => const Stream<Duration?>.empty();

  /// Full queue in playback order (shuffle already applied).
  List<MediaItem> get queue;

  /// Index of [currentTrack] within [queue]; -1 when idle.
  int get currentIndex;

  MusicPlayContext? get playContext;
  bool get shuffled;
  MusicRepeatMode get repeatMode;

  /// Playback failures the UI should surface (snackbar); the service already
  /// handles recovery (skip / stop) itself.
  Stream<Object> get errors;

  /// Claims the latest user intent to replace playback after asynchronous
  /// queue construction. Callers must check [isPlayIntentCurrent] before
  /// committing fetched tracks.
  int beginPlayIntent();

  /// Whether [intent] is still the latest playback-replacement request.
  bool isPlayIntentCurrent(int intent);

  /// Changes whenever a queue session starts or stops. Asynchronous enqueue
  /// actions use this to avoid appending fetched tracks to a newer session.
  int get queueSessionRevision;

  /// Start a new queue from [tracks], optionally at [startTrack] (defaults
  /// to the first track). [shuffle] anchors [startTrack] first and shuffles
  /// the rest after it; with no [startTrack] the whole list shuffles, so the
  /// queue opens on a random track rather than always the first one (#1811).
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  });

  /// Fetch an instant mix seeded from [seed] and play it.
  ///
  /// Throws when the mix cannot be fetched (no reachable server, transport
  /// or server error) and returns [InstantMixOutcome.empty] when the server
  /// answered with no tracks — the tap site owns surfacing both (#2141). The
  /// [errors] stream stays reserved for mid-playback failures, so the two
  /// feedback paths never double up.
  Future<InstantMixOutcome> playInstantMix(MediaItem seed);

  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();

  /// Advance to the next queue entry (respecting repeat mode).
  Future<void> next();

  /// Restart the current track when more than a few seconds in, otherwise
  /// step to the previous queue entry.
  Future<void> previous();

  Future<void> seek(Duration position);

  /// Music playback volume, 0–100. Preview updates are exposed separately so
  /// a slider does not notify every service consumer on each drag event.
  double get volume;
  ValueListenable<double> get volumeListenable;
  Future<void> setVolume(double volume, {bool persist = true});

  void setRepeatMode(MusicRepeatMode mode);
  void toggleShuffle();

  /// Jump playback to queue index [index].
  Future<void> jumpTo(int index);

  void removeAt(int index);
  void reorder(int from, int to);

  /// Insert after the current track.
  void addNext(List<MediaItem> tracks);
  void addToEnd(List<MediaItem> tracks);

  /// Drop everything after the current track.
  void clearUpcoming();

  /// Stop playback and clear the session (mini-player disappears).
  Future<void> stop();

  /// Whether a sleep timer (timed or end-of-track) is armed.
  bool get sleepTimerActive;

  /// The duration the timed sleep timer was armed with (for marking the
  /// chosen preset); null in end-of-track mode or when inactive.
  Duration? get sleepTimerDuration;

  /// Whether the sleep timer pauses at the end of the current track instead
  /// of after a fixed duration.
  bool get sleepTimerEndOfTrack;

  /// Arm the sleep timer: a fixed [duration], or [endOfTrack] to pause when
  /// the current track finishes. Pass `null` with `endOfTrack: false` to
  /// cancel. Fires as a pause (session stays); cancelled by [stop].
  void setSleepTimer(Duration? duration, {bool endOfTrack = false});

  /// Lyrics for [track] (defaults to the current track's backend). Delegates
  /// to `MediaServerClient.fetchLyrics`; null = none available.
  Future<Lyrics?> fetchLyrics(MediaItem track);
}
