import 'package:flutter/services.dart';

/// A user transport intent. `play`/`pause` are *directed* — a remote with
/// dedicated buttons must not flip the state it explicitly asked for.
enum TransportCommand { play, pause, toggle }

/// Maps hardware media transport keys to their intent. Returns null for keys
/// that are not transport keys (including the configured play/pause hotkey,
/// which callers resolve to [TransportCommand.toggle] themselves).
///
/// Shared by the video player screen (foreground remote transport, #1375) and
/// the music hardware-transport handler (#1948); it deliberately lives outside
/// `lib/widgets/` so the music service layer does not import widget code.
TransportCommand? classifyTransportKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.mediaPlay) return TransportCommand.play;
  if (key == LogicalKeyboardKey.mediaPause) return TransportCommand.pause;
  if (key == LogicalKeyboardKey.mediaPlayPause) return TransportCommand.toggle;
  return null;
}

/// Which way a hardware seek or track key points.
enum MediaSeekDirection { forward, backward }

/// Maps the hardware skip keys — the ones that mean "move within what is
/// playing" — to their direction, or null for anything else.
MediaSeekDirection? classifyMediaSeekKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaSkipForward) {
    return MediaSeekDirection.forward;
  }
  if (key == LogicalKeyboardKey.mediaRewind || key == LogicalKeyboardKey.mediaSkipBackward) {
    return MediaSeekDirection.backward;
  }
  return null;
}

/// Maps the hardware track keys to their direction, or null for anything else.
MediaSeekDirection? classifyMediaTrackKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.mediaTrackNext) return MediaSeekDirection.forward;
  if (key == LogicalKeyboardKey.mediaTrackPrevious) return MediaSeekDirection.backward;
  return null;
}

/// Every hardware key the video player treats as "move within this item":
/// the skip keys and the track keys alike, because a video steps a chapter
/// where music changes track.
///
/// The music session needs the two apart, which is why they stay separate
/// functions: [classifyMediaSeekKey] seeks there and [classifyMediaTrackKey]
/// changes track. The video player wants them merged, and merging them here
/// once beats spelling the same `??` out at each of its focus nodes.
MediaSeekDirection? classifyPlayerSkipKey(LogicalKeyboardKey key) =>
    classifyMediaSeekKey(key) ?? classifyMediaTrackKey(key);
