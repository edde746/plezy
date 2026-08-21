import 'package:flutter/foundation.dart' show TargetPlatform, VoidCallback, defaultTargetPlatform;
import 'package:flutter/services.dart';

import '../../focus/transport_keys.dart';

/// Routes hardware media transport keys to the live music session while the
/// app is in the foreground on Android (TV and mobile).
///
/// Background presses reach the session through the Android MediaSession
/// (`MediaControlsManager.controlEvents`). Foreground presses from HID remotes
/// — USB/Bluetooth keyboards with media buttons, the common Android TV setup —
/// are delivered as key events to the focused window instead, where nothing
/// outside the video player screen handled them (#1948). This handler owns
/// them globally: it acts on the initial key-down and consumes down, repeat,
/// and up so a press can neither leak to Android's fallback MediaSession
/// dispatch (the stale-session class of #1375) nor double as input to a
/// focused library item (#1510).
///
/// Android-only by design: Apple platforms deliver transport through the
/// native remote bridge / MPRemoteCommandCenter, and desktop OSes route media
/// keys through SMTC/MPRIS/MPNowPlaying — consuming raw key events there
/// would run commands twice.
///
/// `MusicPlaybackServiceImpl` owns one instance per session, on the same
/// lifecycle as the OS media session. Video playback can never race this
/// handler: `PlaybackCoordinator.claimVideo()` disposes the music session —
/// unregistering the handler — before the video core exists, so the video
/// player screen's own transport handling stays the sole consumer there.
class MusicHardwareTransportHandler {
  MusicHardwareTransportHandler({
    required this._hasActiveSession,
    required this._onPlay,
    required this._onPause,
    required this._onTogglePlayPause,
    required this._onNext,
    required this._onPrevious,
    required this._onStop,
    required this._onSkipForward,
    required this._onSkipBackward,
  });

  final bool Function() _hasActiveSession;
  final VoidCallback _onPlay;
  final VoidCallback _onPause;
  final VoidCallback _onTogglePlayPause;
  final VoidCallback _onNext;
  final VoidCallback _onPrevious;
  final VoidCallback _onStop;
  final VoidCallback _onSkipForward;
  final VoidCallback _onSkipBackward;

  bool _registered = false;

  /// Install the global key handler. No-op off Android and when already
  /// registered.
  void register() {
    if (_registered || defaultTargetPlatform != TargetPlatform.android) return;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _registered = true;
  }

  /// Remove the global key handler. Idempotent.
  void unregister() {
    if (!_registered) return;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _registered = false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_hasActiveSession()) return false;
    final action = _actionFor(event.logicalKey);
    if (action == null) return false;
    // Act on the initial press only; consume the whole down/repeat/up burst so
    // none of it reaches the platform's fallback media-button dispatch.
    if (event is KeyDownEvent) action();
    return true;
  }

  /// The session action a transport key maps to, or null for keys this
  /// handler does not own. Mirrors what `MediaControlRouter` accepts from the
  /// MediaSession so foreground and background presses behave identically.
  VoidCallback? _actionFor(LogicalKeyboardKey key) {
    final transport = classifyTransportKey(key);
    if (transport != null) {
      return switch (transport) {
        TransportCommand.play => _onPlay,
        TransportCommand.pause => _onPause,
        TransportCommand.toggle => _onTogglePlayPause,
      };
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) return _onNext;
    if (key == LogicalKeyboardKey.mediaTrackPrevious) return _onPrevious;
    if (key == LogicalKeyboardKey.mediaStop) return _onStop;
    if (key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaSkipForward) {
      return _onSkipForward;
    }
    if (key == LogicalKeyboardKey.mediaRewind || key == LogicalKeyboardKey.mediaSkipBackward) {
      return _onSkipBackward;
    }
    return null;
  }
}
