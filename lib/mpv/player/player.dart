import 'dart:io' show Platform;

import '../../media/media_display_criteria.dart';
import '../models.dart';
import 'platform/player_android.dart';
import 'player_native.dart';
import 'player_state.dart';
import 'player_streams.dart';
import 'platform/player_linux.dart';
import 'platform/player_windows.dart';

export 'player_base.dart';

/// Abstract interface for the video player.
///
/// This interface defines all playback control methods, state access,
/// and reactive streams for the video player.
///
/// Example usage:
/// ```dart
/// final player = Player();
/// await player.open(Media('https://example.com/video.mp4'));
/// await player.play();
///
/// // Configure player properties
/// await player.setProperty('hwdec', 'auto');
/// await player.setProperty('demuxer-max-bytes', '150000000');
///
/// // Listen to position updates
/// player.streams.position.listen((position) {
///   print('Position: $position');
/// });
///
/// // Access current state
/// print('Playing: ${player.state.playing}');
/// ```
abstract class Player {
  /// Current synchronous state snapshot.
  ///
  /// Use this for immediate state access in UI.
  PlayerState get state;

  /// Reactive streams for state changes.
  ///
  /// Use these for reactive UI updates.
  PlayerStreams get streams;

  /// Fresh playback position, stored on every native position tick.
  ///
  /// [PlayerState.position] is only refreshed at ~4Hz alongside the position
  /// stream; use this for time-sensitive reads (sync anchors, drift math).
  /// ExoPlayer's native tick is itself 250ms, which bounds freshness there.
  Duration get currentPosition;

  /// Whether audio passthrough (bitstream output) is currently active.
  ///
  /// [setRate] with a non-1.0 rate tears passthrough down, so callers that
  /// adjust the rate transiently (e.g. sync micro-corrections) must check
  /// this first.
  bool get audioPassthroughActive;

  /// Texture ID for Flutter's Texture widget (video rendering).
  ///
  /// This is set by the platform implementation when video
  /// rendering is initialized. Returns null if not ready.
  int? get textureId;

  /// The type of player backend being used (e.g., 'mpv', 'exoplayer').
  String get playerType;

  /// Open a media source for playback.
  ///
  /// [media] - The media source to open.
  /// [play] - Whether to start playback immediately (default: true).
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration timelineOffset = Duration.zero,
    Duration? timelineDuration,
  });

  /// Start or resume playback.
  Future<void> play();

  /// Pause playback.
  Future<void> pause();

  /// Toggle between play and pause.
  Future<void> playOrPause();

  /// Stop playback and reset position.
  Future<void> stop();

  /// Seek to a specific position.
  Future<void> seek(Duration position);

  /// Arm (or replace/clear) the item the backend should auto-advance into
  /// when the current one plays out — the gapless-audio primitive.
  ///
  /// Audio players keep a native playlist of `[current, next?]`: ExoPlayer
  /// via `addMediaItem`, mpv via `loadfile append` with `gapless-audio`.
  /// When the advance happens the backend emits
  /// [PlayerStreams.trackTransition] with the armed [Media.uri] instead of
  /// `completed`. Pass `null` to clear. No-op on video backends.
  Future<void> setNext(Media? media);

  /// Select an audio track.
  Future<void> selectAudioTrack(AudioTrack track);

  /// Select a subtitle track.
  ///
  /// Pass [SubtitleTrack.off] to disable subtitles.
  Future<void> selectSubtitleTrack(SubtitleTrack track);

  /// Select a secondary subtitle track (displayed simultaneously with primary).
  ///
  /// Only supported on mpv backends (desktop + Android mpv fallback).
  /// Pass [SubtitleTrack.off] to disable secondary subtitles.
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track);

  /// Whether this player backend supports secondary subtitle tracks.
  bool get supportsSecondarySubtitles;

  /// Whether this backend ingests external subtitles in [open] (single
  /// prepare(), safe to auto-play immediately). Backends returning false
  /// need external subtitles added after open via [addSubtitleTrack] while
  /// paused, and the caller resumes once the tracks are selected.
  bool get attachesExternalSubtitlesAtOpen;

  /// Whether the backend detects container fps from rendered frame
  /// timestamps, so `container-fps` only becomes available a few frames
  /// after playback starts (retry the property read instead of giving up).
  bool get detectsFpsAfterRender;

  /// Whether the video decoder must be refreshed (seek-in-place or
  /// drop-buffers) after a display mode switch. True for mpv on Android,
  /// where MediaCodec can stall against the reconfigured surface.
  bool get needsDecoderRefreshAfterDisplaySwitch;

  /// Whether [getStats] aggregates performance stats natively for the
  /// active backend (the Android plugin covers both ExoPlayer and its mpv
  /// fallback). Backends returning false are sampled via mpv property
  /// reads instead.
  bool get providesNativeStats;

  /// Add an external subtitle track.
  ///
  /// [uri] - URL or path to the subtitle file.
  /// [title] - Optional display title.
  /// [language] - Optional language code.
  /// [select] - Whether to select this track immediately.
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false});

  /// Set the playback volume.
  ///
  /// [volume] - Volume level from 0.0 (muted) to 100.0 (max).
  Future<void> setVolume(double volume);

  /// Set the playback rate/speed.
  ///
  /// [rate] - Playback rate from 0.25 to 4.0 (1.0 = normal speed).
  Future<void> setRate(double rate);

  /// Set the audio output device.
  ///
  /// [device] - The audio device to use.
  Future<void> setAudioDevice(AudioDevice device);

  /// Set an MPV property by name.
  ///
  /// Common properties:
  /// - 'hwdec': Hardware decoding mode ('auto', 'no', 'videotoolbox', etc.)
  /// - 'demuxer-max-bytes': Buffer size in bytes
  /// - 'audio-delay': Audio sync offset in seconds (e.g., '0.5')
  /// - 'sub-delay': Subtitle sync offset in seconds
  /// - 'sub-font': Subtitle font name
  /// - 'sub-font-size': Subtitle font size
  /// - 'sub-color': Subtitle text color
  /// - 'sub-back-color': Subtitle background color
  /// - 'sub-border-size': Subtitle border size
  /// - 'sub-margin-y': Vertical subtitle margin
  /// - 'sub-ass': Enable/disable ASS subtitle rendering ('yes'/'no')
  /// - 'audio-exclusive': Exclusive audio mode ('yes'/'no')
  /// - 'audio-spdif': Audio passthrough formats (e.g., 'ac3,eac3,dts,truehd')
  Future<void> setProperty(String name, String value);

  /// Get an MPV property value by name.
  Future<String?> getProperty(String name);

  /// Set the native MPV log message level (e.g., "warn", "v", "debug").
  ///
  /// This controls the volume of log messages sent from the native player
  /// over the event channel. Use "warn" in production and "v" for debugging.
  Future<void> setLogLevel(String level);

  /// Execute a raw MPV command.
  ///
  /// [args] - Command and arguments as a list of strings.
  Future<void> command(List<String> args);

  /// Prime native display matching from server metadata before the decoder
  /// emits stream properties. Unsupported platforms ignore this.
  ///
  /// [extraDelayMs] is added after a native display-switch completion event,
  /// for TVs or AVRs that need extra HDMI settle time.
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0});

  /// Configure subtitle fonts for libass rendering.
  ///
  /// Extracts a comprehensive Unicode font (Go Noto) to the cache directory
  /// and sets `sub-fonts-dir` and `sub-font` properties.
  Future<void> configureSubtitleFonts();

  /// Enable or disable audio passthrough mode.
  ///
  /// When enabled, supported audio codecs (AC3, DTS, etc.) will be
  /// passed through to the audio device without decoding.
  Future<void> setAudioPassthrough(bool enabled);

  /// Enable or disable loudness normalization.
  ///
  /// mpv backends insert/remove the `loudnorm` audio filter. Android
  /// ExoPlayer attaches platform audio effects (DynamicsProcessing on
  /// API 28+, LoudnessEnhancer otherwise) and forces decoded non-tunneled
  /// PCM output while enabled so the effects can process the stream.
  Future<void> setAudioNormalization(bool enabled);

  /// Force a stereo downmix with a Kodi-style center channel boost.
  ///
  /// [centerBoostDb] (0-12) raises the center channel above its standard
  /// -3 dB downmix coefficient to improve dialogue clarity. [normalize]
  /// attenuates the mix so it cannot clip; off keeps the original level
  /// (Kodi's "maintain original volume"). mpv backends rebuild the audio
  /// chain via `audio-channels`; Android ExoPlayer routes a
  /// ChannelMixingAudioProcessor in the audio sink and force-decodes
  /// encoded audio while enabled.
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize});

  /// Show or hide the video rendering layer.
  ///
  /// On macOS, this controls the Metal layer visibility.
  /// On other platforms, this may have no effect.
  ///
  /// When [restoreOnWindowVisible] is true, macOS may restore the layer as soon
  /// as AppKit reports the window visible again instead of waiting for Dart's
  /// lifecycle resume callback.
  ///
  /// Returns true if the operation was successful.
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false});

  /// Update the video frame/surface dimensions.
  ///
  /// On iOS/macOS, this updates the Metal layer's frame to match the current
  /// window size. Call this when the layout changes (e.g., device rotation).
  /// On other platforms, this is a no-op.
  Future<void> updateFrame();

  /// Set the video frame rate for display refresh rate matching.
  ///
  /// On Android, this hints the system to adjust the display refresh rate
  /// to match the video content's frame rate, reducing judder and saving
  /// battery on LTPO displays.
  ///
  /// [fps] - The video frame rate (e.g., 23.976, 24, 30, 60).
  /// [durationMs] - The video duration in milliseconds.
  /// [extraDelayMs] - Extra settle time (ms) added to the native display-change
  ///                  wait before playback is auto-resumed. Used to absorb the
  ///                  user-configured "display switch delay" on Android TV.
  ///
  /// Returns `true` if a display mode switch was initiated and the platform
  /// will resume playback once the display settles; `false` if no switch was
  /// needed (seamless fallback, invalid fps, no matching mode), in which case
  /// the caller is responsible for starting playback itself.
  ///
  /// On other platforms, this is a no-op that returns `false`.
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
  });

  /// Clear the video frame rate hint and restore default display mode.
  ///
  /// Call this when playback ends to restore the normal display refresh rate.
  /// On other platforms, this is a no-op.
  Future<void> clearVideoFrameRate();

  /// Apply subtitle styling to the native rendering layer.
  ///
  /// ExoPlayer renders subtitles natively (CaptionStyleCompat for text subs,
  /// libass font scale for ASS), so styling must be pushed after [open].
  /// No-op on mpv backends, which style subtitles via `sub-*` properties.
  Future<void> setSubtitleStyle({
    required double fontSize,
    required String textColor,
    required double borderSize,
    required String borderColor,
    required String bgColor,
    required int bgOpacity,
    int subtitlePosition = 100,
    bool bold = false,
    bool italic = false,
  });

  /// Apply the box-fit mode to the native video layer
  /// (0=FIT, 1=ZOOM/cover, 2=FILL/stretch).
  ///
  /// ExoPlayer scales via AspectRatioFrameLayout; mpv backends are a no-op
  /// here and scale via `panscan`/`video-aspect-override` properties instead.
  Future<void> setBoxFitMode(int mode);

  /// Apply custom zoom to the native video layer. No-op on mpv backends,
  /// which zoom via the `video-zoom` property.
  Future<void> setVideoZoom(double scale);

  /// Aggregated native playback stats (codecs, dimensions, dropped frames…).
  ///
  /// Returns an empty map on backends without native stats aggregation;
  /// query mpv properties directly there instead.
  Future<Map<String, dynamic>> getStats();

  /// The backend actually playing right now, resolved from the native side.
  ///
  /// Unlike [playerType] (the configured backend), this reflects runtime
  /// fallbacks — e.g. 'mpv' after ExoPlayer hit an unsupported format.
  Future<String> runtimePlayerType();

  /// Request audio focus before starting playback.
  ///
  /// On Android, this notifies the system that the app wants to play audio,
  /// causing other media apps (Spotify, podcasts, etc.) to pause.
  ///
  /// Returns true if audio focus was granted.
  /// On other platforms, this is a no-op and returns true.
  Future<bool> requestAudioFocus();

  /// Abandon audio focus when playback stops.
  ///
  /// On Android, this notifies the system that the app is done playing audio,
  /// allowing other apps to resume their playback.
  ///
  /// On other platforms, this is a no-op.
  Future<void> abandonAudioFocus();

  /// Whether the player has been disposed.
  bool get disposed;

  /// Dispose of the player and release resources.
  ///
  /// [preserveDisplayMode] keeps any native display-mode hint active while a
  /// replacement video route is being opened. Use false when leaving playback.
  ///
  /// After calling this, the player instance should not be used.
  Future<void> dispose({bool preserveDisplayMode = false});

  /// Creates a new player instance.
  ///
  /// Returns a platform-specific implementation:
  /// - macOS/iOS: [PlayerNative] using MPVKit/libmpv with Metal rendering
  /// - Android: [PlayerAndroid] using ExoPlayer (default) or [PlayerNative] using MPV (fallback)
  /// - Windows: [PlayerWindows] using libmpv with native window embedding
  /// - Linux: [PlayerLinux] using libmpv with OpenGL rendering via GtkGLArea
  ///
  /// On Android, pass [useExoPlayer] to override the default:
  /// - true: Use ExoPlayer (default, better hardware support)
  /// - false: Use MPV (more features, ASS subtitle rendering)
  factory Player({bool? useExoPlayer}) {
    if (Platform.isAndroid) {
      // Default to ExoPlayer on Android, with MPV as fallback
      // The caller should pass useExoPlayer based on SettingsService.getUseExoPlayer()
      final useExo = useExoPlayer ?? true;
      if (useExo) {
        return PlayerAndroid(); // ExoPlayer (default)
      }
      return PlayerNative(); // MPV fallback
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return PlayerNative();
    }
    if (Platform.isWindows) {
      return PlayerWindows();
    }
    if (Platform.isLinux) {
      return PlayerLinux();
    }
    throw UnsupportedError('Player is not supported on this platform');
  }

  /// Creates the dedicated audio-only player used for music playback.
  ///
  /// An mpv audio-only core on every platform — regardless of the Android
  /// video backend setting — running on its own native core and channels
  /// (`com.plezy/mpv_audio_player`), so it never contends with the video
  /// pipeline. Desktop and Android need none of the video plumbing (display
  /// modes, GL textures, surfaces) — the plain mpv wrapper suffices. Only
  /// one native player is kept alive at a time: the music service disposes
  /// this instance when video playback claims the session (see
  /// `PlaybackCoordinator`), and the video core only exists while the video
  /// player screen is open.
  factory Player.audio() {
    if (Platform.isAndroid || Platform.isMacOS || Platform.isIOS || Platform.isWindows || Platform.isLinux) {
      return PlayerNative.audio();
    }
    throw UnsupportedError('Player is not supported on this platform');
  }
}
