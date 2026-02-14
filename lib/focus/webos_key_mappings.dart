import 'package:flutter/services.dart';

/// webOS Magic Remote key code mappings.
///
/// The webOS Magic Remote sends standard keyboard events for D-pad
/// navigation (arrow keys, Enter, Escape) which Flutter handles natively.
/// This file maps webOS-specific keys (color buttons, media keys, etc.)
/// to Flutter LogicalKeyboardKey constants for extended functionality.
///
/// Reference: https://webostv.developer.lge.com/develop/guides/magic-remote
class WebOSKeys {
  WebOSKeys._();

  // Standard keys (handled by Flutter automatically)
  // Arrow keys: LogicalKeyboardKey.arrowUp/Down/Left/Right
  // OK/Enter: LogicalKeyboardKey.enter
  // Back: keyCode 461 → mapped to Escape in index.html

  // Media control keys (standard across TV remotes)
  static const int play = 415;
  static const int pause = 19;
  static const int stop = 413;
  static const int rewind = 412;
  static const int fastForward = 417;

  // Color buttons
  static const int red = 403;
  static const int green = 404;
  static const int yellow = 405;
  static const int blue = 406;

  // webOS-specific
  static const int back = 461;
  static const int channelUp = 33;
  static const int channelDown = 34;
  static const int info = 457;

  /// Check if a key event is a webOS media control key.
  static bool isMediaKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaStop ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaFastForward;
  }

  /// Check if a key event is a webOS color button.
  static bool isColorButton(int keyCode) {
    return keyCode == red || keyCode == green || keyCode == yellow || keyCode == blue;
  }
}
