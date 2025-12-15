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
/// final player = Player();
///
/// // Configure player properties
/// await player.setProperty('hwdec', 'auto');
/// await player.setProperty('demuxer-max-bytes', '150000000');
/// await player.setAudioPassthrough(true);
///
/// // Open and play media
/// await player.open(Media('https://example.com/video.mp4'));
///
/// // Listen to state changes
/// player.streams.position.listen((position) {
///   print('Position: $position');
/// });
///
/// // Display video
/// Video(
///   player: player,
///   controls: (context) => MyCustomControls(),
/// )
///
/// // Clean up
/// await player.dispose();
/// ```
library;

// Player
export 'player/player.dart';
export 'player/player_state.dart';
export 'player/player_streams.dart';

// Models
export 'models.dart';

// Video
export 'video.dart';
