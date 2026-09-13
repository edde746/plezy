import 'dart:async';

/// Per-screen state for display matching: the retry counter for backends
/// that detect fps only after rendering, whether a switch was already applied
/// for the current item, the MediaSession pause-suppression window armed
/// around HDMI renegotiations, and the hold that keeps the first frame behind
/// the loading UI while the display is negotiated from it.
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

  Timer? _mediaPauseSuppressionTimer;
  Completer<void>? _displayNegotiation;

  /// While non-null, the first frame must stay behind the loading UI: the
  /// open is negotiating the display from what mpv presents, and revealing
  /// the frame first would freeze it on screen through the HDMI blank (and
  /// the Apple TV mode-switch wait) instead of the spinner the pre-load
  /// switch used to hide it behind.
  Future<void>? get displayNegotiation => _displayNegotiation?.future;

  /// A first-frame display negotiation is about to start for the item.
  void beginDisplayNegotiation() {
    endDisplayNegotiation();
    _displayNegotiation = Completer<void>();
  }

  /// The negotiation settled (or was abandoned): release the first frame.
  void endDisplayNegotiation() {
    final negotiation = _displayNegotiation;
    _displayNegotiation = null;
    if (negotiation != null && !negotiation.isCompleted) negotiation.complete();
  }

  /// Whether a MediaSession PauseEvent should be ignored right now because
  /// the display is (or may still be) renegotiating HDMI. Fire Stick (and
  /// similar Android TV devices) send onPause() through the MediaSession
  /// callback when the display mode changes for frame rate matching.
  bool get suppressesMediaPause => _mediaPauseSuppressionTimer?.isActive ?? false;

  /// Arm the pause-suppression window around an HDMI renegotiation. The
  /// window outlasts the switch by a safety margin on top of the user's
  /// configured extra delay.
  void beginSuppressWindow(int delaySec) {
    _mediaPauseSuppressionTimer?.cancel();
    _mediaPauseSuppressionTimer = Timer(Duration(seconds: 2 + delaySec + 1), () {
      _mediaPauseSuppressionTimer = null;
    });
  }

  /// Reset the per-item negotiation state before opening new media.
  void resetForNewItem() {
    retries = 0;
    applied = false;
    endDisplayNegotiation();
  }

  /// Cancel any active suppression window when the owning screen is disposed.
  void dispose() {
    _mediaPauseSuppressionTimer?.cancel();
    _mediaPauseSuppressionTimer = null;
    endDisplayNegotiation();
  }
}
