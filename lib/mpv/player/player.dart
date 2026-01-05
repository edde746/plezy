import 'dart:io' show Platform;

import '../models.dart';
import 'player_native.dart';
import 'player_state.dart';
import 'player_streams.dart';
import 'platform/player_linux.dart';
import 'platform/player_windows.dart';

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

  /// Texture ID for Flutter's Texture widget (video rendering).
  ///
  /// This is set by the platform implementation when video
  /// rendering is initialized. Returns null if not ready.
  int? get textureId;

  // ============================================
  // Playback Control
  // ============================================

  /// Open a media source for playback.
  ///
  /// [media] - The media source to open.
  /// [play] - Whether to start playback immediately (default: true).
  Future<void> open(Media media, {bool play = true});

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

  // ============================================
  // Track Selection
  // ============================================

  /// Select an audio track.
  Future<void> selectAudioTrack(AudioTrack track);

  /// Select a subtitle track.
  ///
  /// Pass [SubtitleTrack.off] to disable subtitles.
  Future<void> selectSubtitleTrack(SubtitleTrack track);

  /// Add an external subtitle track.
  ///
  /// [uri] - URL or path to the subtitle file.
  /// [title] - Optional display title.
  /// [language] - Optional language code.
  /// [select] - Whether to select this track immediately.
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false});

  // ============================================
  // Volume and Rate
  // ============================================

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

  // ============================================
  // MPV Properties (Advanced)
  // ============================================

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

  /// Execute a raw MPV command.
  ///
  /// [args] - Command and arguments as a list of strings.
  Future<void> command(List<String> args);

  // ============================================
  // Passthrough Mode (Audio)
  // ============================================

  /// Enable or disable audio passthrough mode.
  ///
  /// When enabled, supported audio codecs (AC3, DTS, etc.) will be
  /// passed through to the audio device without decoding.
  Future<void> setAudioPassthrough(bool enabled);

  // ============================================
  // Visibility (macOS Metal Layer)
  // ============================================

  /// Show or hide the video rendering layer.
  ///
  /// On macOS, this controls the Metal layer visibility.
  /// On other platforms, this may have no effect.
  ///
  /// Returns true if the operation was successful.
  Future<bool> setVisible(bool visible);

  /// Update the video frame/surface dimensions.
  ///
  /// On iOS/macOS, this updates the Metal layer's frame to match the current
  /// window size. Call this when the layout changes (e.g., device rotation).
  /// On other platforms, this is a no-op.
  Future<void> updateFrame();

  // ============================================
  // Lifecycle
  // ============================================

  /// Dispose of the player and release resources.
  ///
  /// After calling this, the player instance should not be used.
  Future<void> dispose();

  // ============================================
  // Factory
  // ============================================

  /// Creates a new player instance.
  ///
  /// Returns a platform-specific implementation:
  /// - macOS/iOS/Android: [PlayerNative] using MPVKit/libmpv with texture rendering
  /// - Windows: [PlayerWindows] using libmpv with native window embedding
  /// - Linux: [PlayerLinux] using libmpv with OpenGL rendering via GtkGLArea
  factory Player() {
    if (Platform.isMacOS || Platform.isIOS || Platform.isAndroid) {
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
}
