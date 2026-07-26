import 'package:flutter/foundation.dart';
import 'package:plezy/media/lyrics.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/music/music_playback_service.dart';

/// No-op base for test doubles, which override only the members under test.
/// Production always binds `MusicPlaybackServiceImpl`.
class StubMusicPlaybackService extends MusicPlaybackService {
  final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(100);
  int _playIntentGeneration = 0;
  int _queueSessionRevision = 0;

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
  int beginPlayIntent() => ++_playIntentGeneration;

  @override
  bool isPlayIntentCurrent(int intent) => intent == _playIntentGeneration;

  @override
  int get queueSessionRevision => _queueSessionRevision;

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  }) async {
    beginPlayIntent();
    _queueSessionRevision++;
  }

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
  Future<void> stop() async {
    beginPlayIntent();
    _queueSessionRevision++;
  }

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
