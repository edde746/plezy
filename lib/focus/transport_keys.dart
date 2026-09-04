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
