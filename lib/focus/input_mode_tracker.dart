import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tv_detection_service.dart';

/// Tracks whether the user is navigating via keyboard/d-pad or pointer (mouse/touch).
///
/// Focus effects should only be shown during keyboard navigation.
enum InputMode { keyboard, pointer }

/// Provides input mode tracking to descendant widgets.
///
/// Wrap your app with this widget to enable input mode detection:
/// ```dart
/// InputModeTracker(
///   child: MaterialApp(...),
/// )
/// ```
///
/// Then check the mode in focusable widgets:
/// ```dart
/// final showFocus = _isFocused && InputModeTracker.isKeyboardMode(context);
/// ```
class InputModeTracker extends StatefulWidget {
  final Widget child;

  const InputModeTracker({super.key, required this.child});

  /// Get the current input mode.
  static InputMode of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_InputModeProvider>();
    return provider?.mode ?? InputMode.pointer;
  }

  /// Convenience method to check if we're in keyboard mode.
  static bool isKeyboardMode(BuildContext context) {
    return of(context) == InputMode.keyboard;
  }

  @override
  State<InputModeTracker> createState() => _InputModeTrackerState();
}

class _InputModeTrackerState extends State<InputModeTracker> {
  // Default to keyboard mode on Android TV, pointer mode elsewhere
  InputMode _mode = TvDetectionService.isTVSync()
      ? InputMode.keyboard
      : InputMode.pointer;

  @override
  void initState() {
    super.initState();
    // Listen to hardware keyboard events globally
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Only switch to keyboard mode on key down (not repeats or releases)
    if (event is KeyDownEvent) {
      _setMode(InputMode.keyboard);
    }
    // Return false to let the event continue propagating
    return false;
  }

  void _setMode(InputMode mode) {
    if (_mode != mode) {
      setState(() => _mode = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Switch to pointer mode on mouse activity
      onPointerDown: (_) => _setMode(InputMode.pointer),
      onPointerHover: (_) => _setMode(InputMode.pointer),
      behavior: HitTestBehavior.translucent,
      child: _InputModeProvider(mode: _mode, child: widget.child),
    );
  }
}

/// InheritedWidget that provides the current input mode.
class _InputModeProvider extends InheritedWidget {
  final InputMode mode;

  const _InputModeProvider({required this.mode, required super.child});

  @override
  bool updateShouldNotify(_InputModeProvider oldWidget) {
    return mode != oldWidget.mode;
  }
}
