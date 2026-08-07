import '../models.dart';

/// Reactive streams for player state changes.
///
/// Subscribe to these streams to receive updates when the player state changes.
/// For synchronous state access, use [PlayerState].
class PlayerStreams {
  /// Stream of playing state changes.
  final Stream<bool> playing;

  /// Stream of completion state changes.
  final Stream<bool> completed;

  /// Stream of buffering state changes.
  final Stream<bool> buffering;

  /// Stream of position updates.
  final Stream<Duration> position;

  /// Emits whenever something asks the playhead to move discontinuously — every
  /// seek, whatever asked for it, and every source opened at a start position
  /// by an in-place reload.
  ///
  /// The value is where the playhead is being put, or null when the backend
  /// computes its own destination (`sub-seek`) and Dart does not know it yet.
  /// A null MAY be followed by a non-null event once the destination has been
  /// read back — but not always: an unreadable position publishes nothing
  /// rather than guessing, and the backend's next tick supplies it instead.
  ///
  /// These are announced at REQUEST time, not on completion, because the window
  /// a consumer has to care about is exactly while the backend is still
  /// working. Treat an event as intent plus a possible correction rather than
  /// as an observed landing: a seek the backend rejects is usually followed by
  /// a second event carrying the position it was actually left at, though a
  /// request that never reached the backend at all has nothing to correct.
  /// Listeners that issue seeks themselves will also see their own requests
  /// here, so they must recognise their own targets rather than assume every
  /// event is foreign.
  ///
  /// [position] cannot stand in for this: a seek writes its target there
  /// optimistically, and stale backend ticks then report the pre-seek position
  /// again until the seek lands, so a listener cannot tell the two apart.
  final Stream<Duration?> playheadJump;

  /// Stream of duration changes (when media is loaded).
  final Stream<Duration> duration;

  /// Stream of seekability changes for the current media item.
  final Stream<bool> seekable;

  /// Stream of buffer position updates.
  final Stream<Duration> buffer;

  /// Stream of volume changes.
  final Stream<double> volume;

  /// Stream of playback rate changes.
  final Stream<double> rate;

  /// Stream of available tracks updates.
  final Stream<Tracks> tracks;

  /// Stream of track selection changes.
  final Stream<TrackSelection> track;

  /// Stream of log messages from the player.
  final Stream<PlayerLog> log;

  /// Stream of player errors.
  final Stream<PlayerError> error;

  /// Stream of audio device changes.
  final Stream<AudioDevice> audioDevice;

  /// Stream of available audio devices.
  final Stream<List<AudioDevice>> audioDevices;

  /// Stream that emits when playback restarts (first frame ready after load/seek).
  final Stream<void> playbackRestart;

  /// Stream that emits when the player has loaded the current media file.
  final Stream<void> fileLoaded;

  /// Emits when mpv starts loading a new file. This delimits load-scoped
  /// readiness and failure signals for callers that arm before [Player.open].
  final Stream<void> fileStarted;

  /// Emits only when the active file ends because loading or playback failed.
  /// Generic platform/property errors remain on [error] and must not be
  /// mistaken for a media-open failure.
  final Stream<void> fileLoadFailed;

  /// Emits once mpv has discovered a non-external audio or video track for
  /// the current file. Unlike [fileLoaded], this can fire before remote
  /// subtitle sidecars finish opening.
  final Stream<void> primaryMediaReady;

  /// Emits when the compositor's preferred colour description for the video
  /// plane changes: the window moved to another output, or an output's HDR
  /// state was toggled under it. Linux only, where it is the only notice that
  /// [Player.isHdrOutputSupported] may now answer differently - dragging a
  /// window between monitors raises no app lifecycle event on Wayland.
  final Stream<void> hdrOutputChanged;

  /// Stream of seekable buffer ranges from the demuxer cache.
  final Stream<List<BufferRange>> bufferRanges;

  /// Stream that emits when the native player backend switches (e.g., ExoPlayer to MPV).
  /// Only emitted on Android when ExoPlayer encounters an unsupported format.
  final Stream<void> backendSwitched;

  /// Emits the URI the backend auto-advanced into after playing out the
  /// current item, when a next item was pre-armed via [Player.setNext]
  /// (gapless music). Only audio players emit this; the value is the armed
  /// [Media.uri].
  final Stream<String> trackTransition;

  const PlayerStreams({
    required this.playing,
    required this.completed,
    required this.buffering,
    required this.position,
    required this.duration,
    required this.seekable,
    required this.buffer,
    required this.volume,
    required this.rate,
    required this.tracks,
    required this.track,
    required this.log,
    required this.error,
    required this.audioDevice,
    required this.audioDevices,
    required this.bufferRanges,
    required this.playbackRestart,
    this.playheadJump = const Stream<Duration?>.empty(),
    this.fileLoaded = const Stream<void>.empty(),
    this.fileStarted = const Stream<void>.empty(),
    this.fileLoadFailed = const Stream<void>.empty(),
    this.primaryMediaReady = const Stream<void>.empty(),
    this.hdrOutputChanged = const Stream<void>.empty(),
    required this.backendSwitched,
    this.trackTransition = const Stream<String>.empty(),
  });
}
