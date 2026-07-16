import 'package:flutter/foundation.dart';

import '../../media/lyrics.dart';
import '../../media/media_item.dart';

/// Repeat behavior of the music queue.
enum MusicRepeatMode { off, all, one }

/// Coarse playback state of the music session.
enum MusicPlaybackStatus { idle, loading, playing, paused, error }

/// What kind of container playback was started from — drives the
/// "Playing from …" line in the player UI.
enum MusicPlayContextKind { album, artist, playlist, mix, tracks }

/// Provenance of the current queue (album/artist/playlist/instant mix).
class MusicPlayContext {
  /// Backend id of the source container, when it has one (instant mixes
  /// don't).
  final String? id;

  /// Display title ("Playing from {title}").
  final String title;

  final MusicPlayContextKind kind;

  const MusicPlayContext({this.id, required this.title, required this.kind});
}

/// Backend-neutral music playback session: owns the audio `Player`, the
/// queue (shuffle/repeat), OS media-session feed, and progress reporting.
///
/// UI consumes this via `context.watch<MusicPlaybackService>()` — it is
/// registered per profile session (see `profile_session_screen.dart`) so a
/// profile switch tears the session down. [notifyListeners] fires only on
/// discrete changes (track, status, queue shape, modes) — progress bars
/// subscribe to [positionStream] instead.
///
/// [StubMusicPlaybackService] is registered until the playback engine lands;
/// UI gates transport affordances on [isAvailable].
abstract class MusicPlaybackService extends ChangeNotifier {
  /// False on the stub — playback affordances should render disabled or
  /// fall back to a "not supported yet" notice.
  bool get isAvailable;

  MediaItem? get currentTrack;
  MusicPlaybackStatus get status;
  bool get isPlaying => status == MusicPlaybackStatus.playing;

  Duration? get duration;
  Duration get position;
  Stream<Duration> get positionStream;

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

  /// Start a new queue from [tracks], optionally at [startTrack] (defaults
  /// to the first track). [shuffle] shuffles with the start track anchored
  /// first.
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  });

  /// Fetch an instant mix seeded from [seed] and play it.
  Future<void> playInstantMix(MediaItem seed);

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

  /// When the timed sleep timer fires; null in end-of-track mode or when
  /// inactive.
  DateTime? get sleepTimerEndsAt;

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

/// No-op placeholder bound while the playback engine is not wired yet (or
/// on platforms where it failed to initialize). Keeps every UI consumer
/// null-safe without per-call-site feature checks.
class StubMusicPlaybackService extends MusicPlaybackService {
  final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(100);
  @override
  bool get isAvailable => false;

  @override
  MediaItem? get currentTrack => null;

  @override
  MusicPlaybackStatus get status => MusicPlaybackStatus.idle;

  @override
  Duration? get duration => null;

  @override
  Duration get position => Duration.zero;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  List<MediaItem> get queue => const [];

  @override
  int get currentIndex => -1;

  @override
  MusicPlayContext? get playContext => null;

  @override
  bool get shuffled => false;

  @override
  MusicRepeatMode get repeatMode => MusicRepeatMode.off;

  @override
  Stream<Object> get errors => const Stream.empty();

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  }) async {}

  @override
  Future<void> playInstantMix(MediaItem seed) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  double get volume => 100;
  @override
  ValueListenable<double> get volumeListenable => _volumeNotifier;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {}

  @override
  void setRepeatMode(MusicRepeatMode mode) {}

  @override
  void toggleShuffle() {}

  @override
  Future<void> jumpTo(int index) async {}

  @override
  void removeAt(int index) {}

  @override
  void reorder(int from, int to) {}

  @override
  void addNext(List<MediaItem> tracks) {}

  @override
  void addToEnd(List<MediaItem> tracks) {}

  @override
  void clearUpcoming() {}

  @override
  Future<void> stop() async {}

  @override
  bool get sleepTimerActive => false;

  @override
  DateTime? get sleepTimerEndsAt => null;

  @override
  Duration? get sleepTimerDuration => null;

  @override
  bool get sleepTimerEndOfTrack => false;

  @override
  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) {}

  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async => null;
  @override
  void dispose() {
    _volumeNotifier.dispose();
    super.dispose();
  }
}
