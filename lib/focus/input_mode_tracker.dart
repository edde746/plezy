import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/platform_detector.dart';
import 'dpad_navigator.dart';
import 'focus_navigation_intent.dart';

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
  ///
  /// Set [listen] to false for event handlers and post-frame callbacks that
  /// only need a one-shot value. Those reads must not subscribe their owning
  /// screen to future input-mode changes.
  static InputMode of(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<_InputModeProvider>()
        : context.getInheritedWidgetOfExactType<_InputModeProvider>();
    return provider?.mode ?? InputMode.pointer;
  }

  /// Convenience method to check if we're in keyboard mode.
  static bool isKeyboardMode(BuildContext context, {bool listen = true}) {
    return of(context, listen: listen) == InputMode.keyboard;
  }

  /// Live input mode, readable without a [BuildContext].
  ///
  /// Focus-change listeners fire during key dispatch, before the inherited
  /// provider has rebuilt for a mode flip, so a context read through [of]
  /// is one frame stale on the first navigation key of a keyboard session.
  /// The tracker's own state is updated synchronously by its
  /// [HardwareKeyboard] handler, which runs before focus traversal moves
  /// focus. Falls back to the platform default when no tracker is mounted.
  static InputMode get currentMode => _instance?._mode ?? _defaultMode;

  /// Keyboard/D-pad on TV, pointer everywhere else.
  static InputMode get _defaultMode => PlatformDetector.isTV() ? InputMode.keyboard : InputMode.pointer;

  /// Report input from a device that cannot point and does not produce key
  /// events — a gamepad shoulder or a companion-remote tab command. Key-shaped
  /// input from those devices goes through [KeyEventSimulatorController], which
  /// runs the framework key pipeline and is observed here like any hardware key.
  ///
  /// Calls `setState`, so never call this during build. A no-op when no tracker
  /// is mounted.
  static void reportNonPointerInput() {
    final state = _instance;
    if (state != null && state.mounted) state._setMode(InputMode.keyboard);
  }

  static _InputModeTrackerState? _instance;

  @override
  State<InputModeTracker> createState() => _InputModeTrackerState();
}

class _InputModeTrackerState extends State<InputModeTracker> {
  InputMode _mode = InputModeTracker._defaultMode;

  /// Whether the in-flight Back press found a primary focus on KeyDown.
  bool _backDownHadFocus = false;

  @override
  void initState() {
    super.initState();
    // Published before anything can report input. The outgoing tracker of a
    // subtree swap disposes *after* the incoming one initialises, so teardown
    // is identity-guarded — otherwise startup's bootstrap→app swap would leave
    // the live registration cleared.
    InputModeTracker._instance = this;
    _updateFocusHighlightStrategy(_mode);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (identical(InputModeTracker._instance, this)) InputModeTracker._instance = null;
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Only a key that asks to navigate by focus starts a keyboard session.
    // Activation and dismissal act on what is already focused, so promoting on
    // them would arm focus chrome for a viewer who never asked to navigate.
    if (eventRequestsFocusNavigation(event)) {
      _setMode(InputMode.keyboard);
    }
    return _consumeBackReleaseWithoutFocus(event);
  }

  /// A Back KeyDown acted on a focus chain that has since been torn down, so
  /// its KeyUp arrives with no primary focus at all. The focus system skips
  /// dispatch and reports it unhandled; on Android the embedding then
  /// redispatches it and `onBackPressed` → `popRoute` performs a second,
  /// system-driven back. Claim it here in the hardware phase instead. A press
  /// that already had no focus on KeyDown is left alone: neither event was
  /// acted on, and the platform's own back is the correct outcome.
  bool _consumeBackReleaseWithoutFocus(KeyEvent event) {
    if (!event.logicalKey.isBackKey) return false;
    if (event is KeyDownEvent) {
      _backDownHadFocus = FocusManager.instance.primaryFocus != null;
      return false;
    }
    if (event is! KeyUpEvent) return false;
    final hadFocus = _backDownHadFocus;
    _backDownHadFocus = false;
    return hadFocus && FocusManager.instance.primaryFocus == null;
  }

  void _setMode(InputMode mode) {
    if (_mode != mode) {
      setState(() => _mode = mode);
    }
    _updateFocusHighlightStrategy(mode);
  }

  // Keep Material focus highlights in sync with our input mode so keyboard/gamepad
  // navigation immediately shows focus without waiting for a real keypress.
  void _updateFocusHighlightStrategy(InputMode mode) {
    final desiredStrategy = mode == InputMode.keyboard
        ? FocusHighlightStrategy.alwaysTraditional
        : FocusHighlightStrategy.automatic;

    if (FocusManager.instance.highlightStrategy != desiredStrategy) {
      FocusManager.instance.highlightStrategy = desiredStrategy;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Non-desktop TVs keep keyboard mode across synthetic pointer events, but
    // their controls remain pointer-reachable for engine-generated taps.
    if (PlatformDetector.isTV() && !PlatformDetector.isDesktopOS()) {
      return _InputModeProvider(mode: _mode, child: widget.child);
    }

    return Listener(
      onPointerDown: (_) => _setMode(InputMode.pointer),
      onPointerHover: (_) => _setMode(InputMode.pointer),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.passthrough,
        children: [
          _InputModeProvider(mode: _mode, child: widget.child),
          // Hide the desktop cursor in keyboard mode without excluding the
          // application subtree from the current pointer hit test.
          if (_mode == InputMode.keyboard)
            const Positioned.fill(
              child: MouseRegion(
                cursor: SystemMouseCursors.none,
                opaque: false,
                hitTestBehavior: HitTestBehavior.translucent,
              ),
            ),
        ],
      ),
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
