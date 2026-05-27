part of '../video_controls.dart';

extension _TizenKeyEventMethods on _PlexVideoControlsState {
  /// Handles global key events on Tizen.
  ///
  /// The EFL video window holds Wayland keyboard focus, so Focus.onKeyEvent
  /// misses navigation keys even when _focusNode appears focused. All key
  /// handling is done here in the global handler instead.
  ///
  /// Not gated on _videoPlayerNavigationEnabled: that flag is always false on
  /// Tizen because TvDetectionService only covers Android TV and Apple TV.
  ///
  /// Returns true if the event was consumed, false to propagate.
  bool handleTizenGlobalKeyEvent(KeyEvent event) {
    // When the controls overlay is open and a UI element (chip, menu item) has
    // primary focus, propagate nav keys through the focus tree instead of
    // consuming them. This allows FocusableWrapper's hold timer (long press) and
    // chip-to-chip D-pad navigation to work. Reclaim Wayland focus on the
    // currently focused node rather than _focusNode to avoid stealing focus.
    final uiElementHasFocus = _showControls && !_focusNode.hasPrimaryFocus;
    if (uiElementHasFocus && (_isSelectKey(event.logicalKey) || _isDirectionalKey(event.logicalKey))) {
      FocusManager.instance.primaryFocus?.requestFocus();
      return false;
    }
    if (event is KeyDownEvent) {
      if (_isDirectionalKey(event.logicalKey) || _isSelectKey(event.logicalKey)) {
        if (_isDirectionalKey(event.logicalKey)) {
          final isHorizontal = event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight;
          if (!_showControls) {
            if (isHorizontal) {
              _showControlsWithTimelineFocus();
              if (widget.canControl) {
                unawaited(_seekByTime(forward: event.logicalKey == LogicalKeyboardKey.arrowRight));
              }
            } else {
              _showControlsWithFocus();
            }
          } else {
            _restartHideTimerIfPlaying();
          }
        } else {
          if (!_showControls) {
            _playOrPause();
            _showControlsWithFocus();
          } else {
            _restartHideTimerIfPlaying();
          }
        }
        _focusNode.requestFocus();
        return true;
      }
    }
    return true; // Consume all keys on Tizen to prevent leakage
  }
}
