/// MPV Player library for Flutter.
///
/// This library provides a platform-agnostic interface for video playback
/// using MPV as the underlying player engine.
///
/// ## Features
///
/// - Stream-based reactive state updates
/// - Audio passthrough support for lossless audio
/// - Subtitle rendering with libass
/// - Hardware-accelerated decoding
/// - Cross-platform support (macOS, iOS, Android, Windows, Linux)
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_application_1/mpv/mpv.dart';
///
/// // Create a player
/// final player = MpvPlayer();
///
/// // Configure player properties
/// await player.setProperty('hwdec', 'auto');
/// await player.setProperty('demuxer-max-bytes', '150000000');
/// await player.setAudioPassthrough(true);
///
/// // Open and play media
/// await player.open(MpvMedia('https://example.com/video.mp4'));
///
/// // Listen to state changes
/// player.streams.position.listen((position) {
///   print('Position: $position');
/// });
///
/// // Display video
/// MpvVideo(
///   player: player,
///   controls: (context) => MyCustomControls(),
/// )
///
/// // Clean up
/// await player.dispose();
/// ```
library;

// Import for type alias
import 'src/models/mpv_track_selection.dart' as track_selection;

// Player
export 'src/player/mpv_player.dart';
export 'src/player/mpv_player_state.dart';
export 'src/player/mpv_player_streams.dart';
export 'src/player/mpv_player_stub.dart';

// Models
export 'src/models/mpv_media.dart';
export 'src/models/mpv_audio_device.dart';
export 'src/models/mpv_audio_track.dart';
export 'src/models/mpv_subtitle_track.dart';
export 'src/models/mpv_tracks.dart';
export 'src/models/mpv_track_selection.dart';
export 'src/models/mpv_log.dart';
export 'src/models/mpv_log_level.dart';

// Video
export 'src/video/mpv_video.dart';

// Type alias for compatibility (must be after exports)
typedef MpvTrack = track_selection.MpvTrackSelection;
