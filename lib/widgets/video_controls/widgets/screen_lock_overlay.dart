import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_icon.dart';

/// Absorbs player touches until the requested fingers remain still together.
class ScreenLockOverlay extends StatefulWidget {
  const ScreenLockOverlay({
    super.key,
    required this.requiredFingers,
    required this.holdDuration,
    required this.onUnlock,
    required this.instruction,
    this.touchProgressLabelBuilder,
    this.autoHideHint = true,
  }) : assert(requiredFingers >= 1 && requiredFingers <= 5),
       assert(holdDuration > Duration.zero);

  final int requiredFingers;
  final Duration holdDuration;
  final VoidCallback onUnlock;
  final String instruction;
  final String Function(int currentFingers)? touchProgressLabelBuilder;
  final bool autoHideHint;

  @override
  State<ScreenLockOverlay> createState() => _ScreenLockOverlayState();
}

class _ScreenLockOverlayState extends State<ScreenLockOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final Map<int, Offset> _touchOrigins = {};
  late final AnimationController _progress;
  Timer? _holdTimer;
  Timer? _hintTimer;
  bool _hintVisible = true;
  bool _blockedUntilRelease = false;
  bool _completed = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _progress = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
      animationBehavior: AnimationBehavior.preserve,
    );
    _scheduleHintHide();
  }

  @override
  void didUpdateWidget(ScreenLockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requiredFingers != widget.requiredFingers || oldWidget.holdDuration != widget.holdDuration) {
      _stopHold();
      _progress.duration = widget.holdDuration;
      _blockedUntilRelease = _touchOrigins.isNotEmpty;
      _completed = false;
      _hintVisible = true;
      _scheduleHintHide();
    }
    if (oldWidget.autoHideHint != widget.autoHideHint) {
      _hintVisible = true;
      _scheduleHintHide();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _scheduleHintHide();
      return;
    }
    _stopHold();
    _touchOrigins.clear();
    _blockedUntilRelease = false;
    _hintTimer?.cancel();
    if (mounted) setState(() => _hintVisible = true);
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _progress.reset();
  }

  void _scheduleHintHide() {
    _hintTimer?.cancel();
    if (!widget.autoHideHint || _touchOrigins.isNotEmpty || _completed || !_active) return;
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  void _updateHold() {
    _stopHold();
    _hintTimer?.cancel();
    if (_completed || !_active || _blockedUntilRelease || _touchOrigins.length != widget.requiredFingers) {
      _scheduleHintHide();
      return;
    }
    unawaited(_progress.forward());
    // Time the hold independently of animation settings.
    _holdTimer = Timer(widget.holdDuration, () {
      _holdTimer = null;
      if (!mounted || _completed || !_active || _blockedUntilRelease) return;
      if (_touchOrigins.length != widget.requiredFingers) return;
      _completed = true;
      _progress.value = 1;
      widget.onUnlock();
    });
  }

  void _pointerDown(PointerDownEvent event) {
    if (!mounted || !_active || _completed || event.kind != PointerDeviceKind.touch) return;
    setState(() {
      _touchOrigins[event.pointer] = event.position;
      _hintVisible = true;
    });
    _updateHold();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!mounted) return;
    final origin = _touchOrigins[event.pointer];
    if (origin == null || _blockedUntilRelease || _completed) return;
    if ((event.position - origin).distance <= kTouchSlop) return;
    // A swipe cannot become an unlock by stopping in place. Every finger must
    // release before a fresh stationary hold can begin.
    _blockedUntilRelease = true;
    _stopHold();
  }

  void _pointerUp(PointerUpEvent event) {
    if (!mounted) return;
    if (!_touchOrigins.containsKey(event.pointer)) return;
    setState(() {
      _touchOrigins.remove(event.pointer);
      if (_touchOrigins.isEmpty) _blockedUntilRelease = false;
    });
    _updateHold();
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (!mounted) return;
    if (!_touchOrigins.containsKey(event.pointer)) return;
    setState(() {
      _touchOrigins.remove(event.pointer);
      _blockedUntilRelease = _touchOrigins.isNotEmpty;
    });
    _updateHold();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _hintTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel = widget.touchProgressLabelBuilder?.call(_touchOrigins.length);
    return Semantics(
      container: true,
      label: widget.instruction,
      // Claim contacts before an ancestor playback gesture can act on them.
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            EagerGestureRecognizer.new,
            (_) {},
          ),
        },
        child: ExcludeSemantics(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerCancel,
            child: AnimatedOpacity(
              opacity: _hintVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _progress,
                          builder: (context, child) => SizedBox.square(
                            dimension: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _progress.value,
                                  strokeWidth: 3,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                ),
                                child!,
                              ],
                            ),
                          ),
                          child: const AppIcon(Symbols.lock_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (progressLabel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            progressLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
