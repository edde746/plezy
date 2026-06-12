/// Per-screen state for Android display frame-rate matching: the retry
/// counter for backends that detect fps only after rendering, whether a
/// switch was already applied for the current item, and the MediaSession
/// pause-suppression window armed around HDMI renegotiations.
///
/// One instance lives on the player screen; the open/reload pipelines call
/// [resetForNewItem] before each open and the display-matching paths flip
/// [applied]/[retries] as they negotiate.
class FrameRateMatcher {
  /// Retries left for late fps detection (ExoPlayer reports container fps
  /// only after ~8 rendered frames).
  int retries = 0;

  /// Whether a display switch was already applied for the current item —
  /// the post-first-frame path bails instead of switching twice.
  bool applied = false;

  bool _suppressMediaPause = false;

  /// Whether a MediaSession PauseEvent should be ignored right now because
  /// the display is (or may still be) renegotiating HDMI. Fire Stick (and
  /// similar Android TV devices) send onPause() through the MediaSession
  /// callback when the display mode changes for frame rate matching.
  bool get suppressesMediaPause => _suppressMediaPause;

  /// Arm the pause-suppression window around an HDMI renegotiation. The
  /// window outlasts the switch by a safety margin on top of the user's
  /// configured extra delay.
  void beginSuppressWindow(int delaySec) {
    _suppressMediaPause = true;
    Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
      _suppressMediaPause = false;
    });
  }

  /// Reset the per-item negotiation state before opening new media.
  void resetForNewItem() {
    retries = 0;
    applied = false;
  }
}
