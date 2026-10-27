import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../app_icon.dart';

enum _UnlockPrompt { hidden, shown, armed }

/// Touch shield over the player while the screen lock is on.
///
/// Unlocking takes three deliberate taps: one anywhere reveals the unlock
/// button, one on the button arms it, and one more on the armed button
/// unlocks. Holding never unlocks, a tap anywhere off the button hides it
/// again, and a contact that puts a second finger down counts for nothing, so
/// the press-and-hold and mashing a small child produces cannot get through.
class ScreenLockOverlay extends StatefulWidget {
  const ScreenLockOverlay({super.key, required this.onUnlock});

  final VoidCallback onUnlock;

  /// How long the revealed button stays up, and how long an armed button
  /// waits for the confirming tap.
  static const promptDuration = Duration(seconds: 3);

  @override
  State<ScreenLockOverlay> createState() => _ScreenLockOverlayState();
}

class _ScreenLockOverlayState extends State<ScreenLockOverlay> {
  // Locking reveals the button straight away so the viewer sees the way out.
  _UnlockPrompt _prompt = _UnlockPrompt.shown;
  Timer? _hideTimer;
  int _pointersDown = 0;

  /// Whether the current contact sequence has had two fingers down at once.
  /// Cleared only when the next sequence starts: taps resolve after the
  /// overlay's own pointer-up bookkeeping, so the last finger lifting must not
  /// clear it before the tap that finger completes is judged.
  bool _multiTouch = false;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _setPrompt(_UnlockPrompt prompt) {
    _hideTimer?.cancel();
    setState(() => _prompt = prompt);
    if (prompt != _UnlockPrompt.hidden) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer = Timer(ScreenLockOverlay.promptDuration, () {
      if (mounted) setState(() => _prompt = _UnlockPrompt.hidden);
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointersDown == 0) _multiTouch = false;
    _pointersDown++;
    if (_pointersDown > 1 && !_multiTouch) {
      _multiTouch = true;
      _setPrompt(_UnlockPrompt.hidden);
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_pointersDown > 0) _pointersDown--;
  }

  void _handleBackgroundTap() {
    if (_multiTouch) return;
    _setPrompt(_prompt == _UnlockPrompt.hidden ? _UnlockPrompt.shown : _UnlockPrompt.hidden);
  }

  void _handleButtonTap() {
    if (_multiTouch) return;
    switch (_prompt) {
      // The button hid under a finger that was already on it.
      case _UnlockPrompt.hidden:
        return;
      case _UnlockPrompt.shown:
        _setPrompt(_UnlockPrompt.armed);
      case _UnlockPrompt.armed:
        _hideTimer?.cancel();
        widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _prompt != _UnlockPrompt.hidden;
    final armed = _prompt == _UnlockPrompt.armed;
    final label = armed ? t.videoControls.tapAgainToUnlock : t.videoControls.tapToUnlock;
    final foreground = armed ? Colors.black : Colors.white;
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              container: true,
              label: t.videoControls.screenLockButton,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _handleBackgroundTap),
            ),
          ),
          // Top-centre, away from the middle of the picture where stray
          // touches land. A hidden button is not hit-testable, so the tap
          // that reveals it can never also count toward unlocking.
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: .topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: IgnorePointer(
                    ignoring: !visible,
                    child: AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Semantics(
                        container: true,
                        button: true,
                        liveRegion: true,
                        label: label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _handleButtonTap,
                          // Claims a hold as a long press, which does nothing,
                          // so holding the button never resolves as a tap.
                          onLongPress: () {},
                          child: ExcludeSemantics(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: armed ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.all(Radius.circular(28)),
                              ),
                              child: Row(
                                mainAxisSize: .min,
                                children: [
                                  AppIcon(
                                    armed ? Symbols.lock_open_rounded : Symbols.lock_rounded,
                                    fill: 1,
                                    color: foreground,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: TextStyle(color: foreground, fontSize: 14, fontWeight: .w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
