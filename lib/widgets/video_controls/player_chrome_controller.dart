import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show BuildContext, ListenableBuilder, MouseRegion, StatelessWidget, SystemMouseCursors, Widget;

/// Reasons that keep the video-player chrome visible and suppress auto-hide.
enum PlayerChromeHold { pip, contentStrip, promptInteraction, scrub }

/// Focus target to request after chrome has rebuilt visible controls.
enum PlayerChromeFocusTarget { playPause, timeline }

/// Owns video-player chrome visibility and auto-hide policy for one player route.
class PlayerChromeController extends ChangeNotifier implements ValueListenable<bool> {
  PlayerChromeController({bool controlsVisible = true}) : _controlsVisible = controlsVisible;

  bool _controlsVisible;
  bool _contentStripVisible = false;
  bool _playing = false;
  bool _hasFirstFrame = true;
  Duration _hideDelay = const Duration(seconds: 3);
  Timer? _hideTimer;
  PlayerChromeFocusTarget? _pendingFocusTarget;
  final Set<PlayerChromeHold> _holds = <PlayerChromeHold>{};
  final Stopwatch _pointerActivityStopwatch = Stopwatch()..start();
  int _lastPointerActivityMs = -1000;

  @override
  bool get value => _controlsVisible;

  bool get controlsVisible => _controlsVisible;
  bool get contentStripVisible => _contentStripVisible;
  bool get hasVisibleHold => _holds.isNotEmpty;
  bool isHeld(PlayerChromeHold hold) => _holds.contains(hold);
  PlayerChromeFocusTarget? get pendingFocusTarget => _pendingFocusTarget;

  void configure({Duration? hideDelay, bool? hasFirstFrame}) {
    var restartTimer = false;
    if (hideDelay != null && hideDelay != _hideDelay) {
      _hideDelay = hideDelay;
      restartTimer = true;
    }
    if (hasFirstFrame != null && hasFirstFrame != _hasFirstFrame) {
      _hasFirstFrame = hasFirstFrame;
      restartTimer = true;
    }
    if (restartTimer) _startAutoHideForCurrentPlaybackState();
  }

  void setPlaying(bool playing) {
    if (_playing == playing) return;
    _playing = playing;
    if (!_controlsVisible) return;
    if (playing) {
      startAutoHide();
    } else {
      startPausedAutoHide();
    }
  }

  void setHasFirstFrame(bool hasFirstFrame) {
    if (_hasFirstFrame == hasFirstFrame) return;
    _hasFirstFrame = hasFirstFrame;
    if (!_hasFirstFrame) {
      cancelAutoHide();
      return;
    }
    _startAutoHideForCurrentPlaybackState();
  }

  void setContentStripVisible(bool visible) {
    if (_contentStripVisible == visible) return;
    _contentStripVisible = visible;
    if (visible) {
      hold(PlayerChromeHold.contentStrip);
    } else {
      release(PlayerChromeHold.contentStrip);
    }
  }

  void show({bool restartAutoHide = true, PlayerChromeFocusTarget? focusTarget}) {
    var shouldNotify = false;
    if (focusTarget != null) {
      _pendingFocusTarget = focusTarget;
      shouldNotify = true;
    }
    if (!_controlsVisible) {
      _controlsVisible = true;
      shouldNotify = true;
    }
    if (shouldNotify) notifyListeners();
    if (restartAutoHide) _startAutoHideForCurrentPlaybackState();
  }

  PlayerChromeFocusTarget? takeFocusTarget() {
    final target = _pendingFocusTarget;
    _pendingFocusTarget = null;
    return target;
  }

  bool hide({bool ignoreHolds = false}) {
    if (!_controlsVisible) return false;
    if (!ignoreHolds && _holds.isNotEmpty) return false;
    cancelAutoHide();
    _controlsVisible = false;
    if (_contentStripVisible) {
      _contentStripVisible = false;
      _holds.remove(PlayerChromeHold.contentStrip);
    }
    notifyListeners();
    return true;
  }

  void toggle() {
    if (_controlsVisible) {
      hide();
    } else {
      show();
    }
  }

  bool recordPointerActivity() {
    final nowMs = _pointerActivityStopwatch.elapsedMilliseconds;
    final shouldThrottle = _controlsVisible && nowMs - _lastPointerActivityMs < 120;
    if (shouldThrottle) return false;
    _lastPointerActivityMs = nowMs;

    show(restartAutoHide: false);
    _startAutoHideForCurrentPlaybackState();
    return true;
  }

  void startAutoHide() {
    _hideTimer?.cancel();
    if (!_hasFirstFrame || _holds.isNotEmpty || !_playing) return;
    _hideTimer = Timer(_hideDelay, () {
      if (_playing && _hasFirstFrame) hide();
    });
  }

  void startPausedAutoHide() {
    _hideTimer?.cancel();
    if (!_controlsVisible || !_hasFirstFrame || _holds.isNotEmpty) return;
    _hideTimer = Timer(_hideDelay, hide);
  }

  void _startAutoHideForCurrentPlaybackState() {
    if (!_controlsVisible) {
      cancelAutoHide();
      return;
    }
    if (_playing) {
      startAutoHide();
    } else {
      startPausedAutoHide();
    }
  }

  void restartAutoHideForCurrentPlaybackState() => _startAutoHideForCurrentPlaybackState();

  void hideForPointerExit() {
    if (_holds.contains(PlayerChromeHold.pip)) return;
    hide(ignoreHolds: true);
  }

  void cancelAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void hold(PlayerChromeHold hold) {
    if (!_holds.add(hold)) return;
    cancelAutoHide();
    if (!_controlsVisible) {
      _controlsVisible = true;
    }
    notifyListeners();
  }

  void release(PlayerChromeHold hold, {bool notify = true, bool restartAutoHide = true}) {
    if (!_holds.remove(hold)) return;
    if (notify) notifyListeners();
    if (restartAutoHide && _holds.isEmpty) _startAutoHideForCurrentPlaybackState();
  }

  @override
  void dispose() {
    cancelAutoHide();
    super.dispose();
  }
}

/// Defines the pointer boundary for all interactive video-player chrome.
class PlayerChromeInteractionRegion extends StatelessWidget {
  final PlayerChromeController controller;
  final bool hideOnExit;
  final Widget child;

  const PlayerChromeInteractionRegion({
    super.key,
    required this.controller,
    required this.hideOnExit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MouseRegion(
          cursor: controller.controlsVisible ? SystemMouseCursors.basic : SystemMouseCursors.none,
          onHover: (_) => controller.recordPointerActivity(),
          onExit: (_) {
            if (!hideOnExit) return;
            controller.cancelAutoHide();
            controller.hideForPointerExit();
          },
          child: child,
        );
      },
    );
  }
}
