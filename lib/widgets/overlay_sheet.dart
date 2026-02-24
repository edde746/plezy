import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../utils/platform_detector.dart';

/// Entry in the sheet page stack.
class _OverlaySheetEntry {
  final WidgetBuilder builder;
  final Completer<dynamic> completer;
  final FocusNode? initialFocusNode;

  _OverlaySheetEntry({required this.builder, required this.completer, this.initialFocusNode});
}

/// Provides [OverlaySheetController] to descendants via [of] / [maybeOf].
class _OverlaySheetScope extends InheritedWidget {
  final OverlaySheetController controller;

  const _OverlaySheetScope({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_OverlaySheetScope oldWidget) => controller != oldWidget.controller;
}

/// Controller for the overlay-based bottom sheet system.
///
/// Use [of] or [maybeOf] to access from descendants.
class OverlaySheetController {
  final _OverlaySheetHostState _state;

  OverlaySheetController._(this._state);

  static OverlaySheetController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_OverlaySheetScope>();
    assert(scope != null, 'No OverlaySheetHost found in context');
    return scope!.controller;
  }

  static OverlaySheetController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_OverlaySheetScope>()?.controller;
  }

  /// Whether a sheet is currently showing (including while animating closed).
  bool get isOpen => _state._isOpen;

  /// Show a bottom sheet with [builder] content. Returns a Future that completes
  /// when the sheet is closed (with an optional result).
  Future<T?> show<T>({
    required WidgetBuilder builder,
    BoxConstraints? constraints,
    Color? backgroundColor,
    bool barrierDismissible = true,
    FocusNode? initialFocusNode,
  }) {
    return _state._show<T>(
      builder: builder,
      constraints: constraints,
      backgroundColor: backgroundColor,
      barrierDismissible: barrierDismissible,
      initialFocusNode: initialFocusNode,
    );
  }

  /// Push a sub-page within the open sheet. Returns a Future that completes
  /// when the pushed page is popped (with an optional result).
  Future<T?> push<T>({required WidgetBuilder builder, FocusNode? initialFocusNode}) {
    return _state._push<T>(builder: builder, initialFocusNode: initialFocusNode);
  }

  /// Pop the top sub-page, or close the sheet if on the last page.
  void pop([dynamic result]) {
    _state._pop(result);
  }

  /// Force close the sheet, completing all pending completers.
  void close([dynamic result]) {
    _state._close(result);
  }

  /// Re-focus the first focusable descendant within the sheet.
  /// Useful after internal page changes via setState.
  void refocus() {
    _state._refocus();
  }

  /// Show a sheet using the overlay system if available, otherwise fall back
  /// to [showModalBottomSheet]. Returns the result from the sheet.
  static Future<T?> showAdaptive<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    BoxConstraints? constraints,
    Color? backgroundColor,
    bool barrierDismissible = true,
    bool isScrollControlled = false,
    FocusNode? initialFocusNode,
  }) {
    final controller = maybeOf(context);
    if (controller != null) {
      return controller.show<T>(
        builder: builder,
        constraints: constraints,
        backgroundColor: backgroundColor,
        barrierDismissible: barrierDismissible,
        initialFocusNode: initialFocusNode,
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      constraints: constraints,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      barrierColor: Colors.black54,
      isScrollControlled: isScrollControlled,
    );
  }

  /// Push a sub-page using the overlay system if available, otherwise fall
  /// back to [showModalBottomSheet]. Returns the result from the page.
  static Future<T?> pushAdaptive<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    FocusNode? initialFocusNode,
  }) {
    final controller = maybeOf(context);
    if (controller != null) {
      return controller.push<T>(builder: builder, initialFocusNode: initialFocusNode);
    }
    return showModalBottomSheet<T>(context: context, builder: builder);
  }

  /// Close the sheet entirely. Uses overlay controller if available,
  /// otherwise pops the route.
  static void closeAdaptive(BuildContext context, [dynamic result]) {
    final controller = maybeOf(context);
    if (controller != null) {
      controller.close(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  /// Pop one level (sub-page or close if last page). Uses overlay controller
  /// if available, otherwise pops the route.
  static void popAdaptive(BuildContext context, [dynamic result]) {
    final controller = maybeOf(context);
    if (controller != null) {
      controller.pop(result);
    } else {
      Navigator.pop(context, result);
    }
  }
}

/// Host widget for the overlay-based bottom sheet system.
///
/// Sheets are rendered as overlays within this widget's Stack instead of as
/// modal routes, eliminating the route-based back-button race condition on
/// Android TV and providing centralized focus management for keyboard/dpad
/// navigation on all platforms.
///
/// Screens that contain a [PopScope] should check [OverlaySheetController.isOpen]
/// and skip their own back handling when a sheet is open.
class OverlaySheetHost extends StatefulWidget {
  final Widget child;

  const OverlaySheetHost({super.key, required this.child});

  @override
  State<OverlaySheetHost> createState() => _OverlaySheetHostState();
}

class _OverlaySheetHostState extends State<OverlaySheetHost> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _barrierAnimation;
  late final OverlaySheetController _controller;

  final List<_OverlaySheetEntry> _pageStack = [];
  final _sheetFocusScopeNode = FocusScopeNode(debugLabel: 'OverlaySheetScope');

  bool _isOpen = false;
  bool _isClosing = false;
  bool _barrierDismissible = true;
  BoxConstraints? _constraints;
  Color? _explicitBackgroundColor;

  // Drag-to-dismiss state
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = OverlaySheetController._(this);

    _animationController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
    );

    _barrierAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    for (final entry in _pageStack) {
      if (!entry.completer.isCompleted) {
        entry.completer.complete(null);
      }
    }
    _sheetFocusScopeNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<T?> _show<T>({
    required WidgetBuilder builder,
    BoxConstraints? constraints,
    Color? backgroundColor,
    bool barrierDismissible = true,
    FocusNode? initialFocusNode,
  }) {
    // If already open, close first (instant)
    if (_isOpen) {
      for (final entry in _pageStack) {
        if (!entry.completer.isCompleted) {
          entry.completer.complete(null);
        }
      }
      _pageStack.clear();
      _isClosing = false;
    }

    final completer = Completer<T?>();
    final entry = _OverlaySheetEntry(builder: builder, completer: completer, initialFocusNode: initialFocusNode);

    setState(() {
      _pageStack.add(entry);
      _isOpen = true;
      _isClosing = false;
      _barrierDismissible = barrierDismissible;
      _constraints = constraints;
      _explicitBackgroundColor = backgroundColor;
      _dragOffset = 0;
      _isDragging = false;
    });

    BackKeyUpSuppressor.clearSuppression();
    _animationController.forward(from: 0);
    _autoFocus();

    return completer.future;
  }

  Future<T?> _push<T>({required WidgetBuilder builder, FocusNode? initialFocusNode}) {
    if (!_isOpen || _isClosing) {
      return Future.value(null);
    }

    final completer = Completer<T?>();
    final entry = _OverlaySheetEntry(builder: builder, completer: completer, initialFocusNode: initialFocusNode);

    setState(() {
      _pageStack.add(entry);
    });

    _autoFocus();
    return completer.future;
  }

  void _pop([dynamic result]) {
    if (!_isOpen || _isClosing || _pageStack.isEmpty) return;

    if (_pageStack.length == 1) {
      _close(result);
      return;
    }

    final removed = _pageStack.removeLast();
    if (!removed.completer.isCompleted) {
      removed.completer.complete(result);
    }

    setState(() {});
    _autoFocus();
  }

  void _close([dynamic result]) {
    if (!_isOpen || _isClosing) return;
    _isClosing = true;

    _animationController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        for (final entry in _pageStack) {
          if (!entry.completer.isCompleted) {
            entry.completer.complete(result);
          }
        }
        _pageStack.clear();
        _isOpen = false;
        _isClosing = false;
        _dragOffset = 0;
        _isDragging = false;
      });
      // Clear stale back-key flags. handleBackKeyAction sets
      // markClosedViaBackKey() expecting a route pop, but the overlay
      // doesn't pop a route. Without clearing, the flag leaks into the
      // next real route pop and disables KeyUp suppression, causing a
      // double-pop on the underlying screen.
      BackKeyUpSuppressor.clearSuppression();
    });
  }

  void _autoFocus() {
    if (!InputModeTracker.isKeyboardMode(context)) return;

    // First post-frame: the FocusScope is now built and the node is attached.
    // Grab scope focus immediately so key events (especially back) are trapped.
    // Second post-frame: ListView.builder items are laid out and their
    // FocusNodes are registered — focus the first descendant for dpad nav.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) return;
      _sheetFocusScopeNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isOpen) return;
        // If the current top entry has an initialFocusNode that is attached,
        // focus that instead of the first descendant.
        final topEntry = _pageStack.isNotEmpty ? _pageStack.last : null;
        final initialNode = topEntry?.initialFocusNode;
        if (initialNode != null && initialNode.context != null) {
          initialNode.requestFocus();
        } else {
          _focusFirstDescendant();
        }

        // Clear stale select suppression from the press that opened this sheet,
        // but only if no select key is currently held down. This handles:
        // - Short press: key already released → clear flag (prevents first
        //   select inside the sheet from being eaten).
        // - Long press: key still held → keep flag so KeyRepeat/KeyUp events
        //   from the long press are correctly suppressed.
        if (!HardwareKeyboard.instance.logicalKeysPressed.any((k) => k.isSelectKey)) {
          SelectKeyUpSuppressor.clearSuppression();
        }
      });
    });
  }

  void _refocus() {
    if (!InputModeTracker.isKeyboardMode(context)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) return;
      _sheetFocusScopeNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isOpen) return;
        final topEntry = _pageStack.isNotEmpty ? _pageStack.last : null;
        final initialNode = topEntry?.initialFocusNode;
        if (initialNode != null && initialNode.context != null) {
          initialNode.requestFocus();
        } else {
          _focusFirstDescendant();
        }
      });
    });
  }

  void _focusFirstDescendant() {
    final descendants = _sheetFocusScopeNode.traversalDescendants.toList();
    if (descendants.isNotEmpty) {
      descendants.first.requestFocus();
    } else {
      _sheetFocusScopeNode.requestFocus();
    }
  }

  void _handleBack() {
    if (_pageStack.length > 1) {
      _pop();
    } else {
      _close();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    // Suppress stale select key-ups
    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      return KeyEventResult.handled;
    }

    // Suppress stale back key-ups
    if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
      return KeyEventResult.handled;
    }

    // Back key: pop sub-page or close sheet
    if (event.logicalKey.isBackKey) {
      return handleBackKeyAction(event, _handleBack);
    }

    // Let all other keys pass through. Directional keys need to reach
    // Flutter's DirectionalFocusAction for dpad/arrow navigation, and
    // select/enter keys need to reach ActivateAction for item taps.
    // The FocusScope traps traversal within the sheet; the screen-level
    // Focus catches any leaked nav keys.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // No PopScope here — the parent screen's PopScope should check
    // OverlaySheetController.isOpen and delegate to us. This avoids
    // the double-callback problem with nested PopScopes in one route.

    return _OverlaySheetScope(
      controller: _controller,
      child: Stack(
        children: [
          widget.child,
          // Barrier + sheet only when open
          if (_isOpen) ...[
            AnimatedBuilder(
              animation: _barrierAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _barrierDismissible ? () => _close() : null,
                  child: Container(color: Colors.black.withValues(alpha: _barrierAnimation.value)),
                );
              },
            ),
            _buildSheet(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    final effectiveConstraints =
        _constraints ??
        BoxConstraints(maxWidth: isDesktop ? 700 : double.infinity, maxHeight: isDesktop ? 400 : size.height * 0.75);

    Widget sheet = FocusScope(
      node: _sheetFocusScopeNode,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleKeyEvent,
        child: SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(0, _dragOffset.clamp(0, double.infinity)),
              child: Material(
                color: _explicitBackgroundColor ?? Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: effectiveConstraints,
                    child: _pageStack.isNotEmpty ? _pageStack.last.builder(context) : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Swipe-down-to-dismiss (skip on TV where there's no touchscreen)
    if (!PlatformDetector.isTV()) {
      sheet = GestureDetector(
        onVerticalDragStart: (_) {
          _isDragging = true;
          _dragOffset = 0;
        },
        onVerticalDragUpdate: (details) {
          if (!_isDragging) return;
          setState(() {
            _dragOffset += details.delta.dy;
          });
        },
        onVerticalDragEnd: (details) {
          if (!_isDragging) return;
          _isDragging = false;

          final sheetHeight = effectiveConstraints.minHeight;
          final velocity = details.primaryVelocity ?? 0;

          if (_dragOffset > sheetHeight * 0.25 || velocity > 500) {
            _close();
          } else {
            setState(() {
              _dragOffset = 0;
            });
          }
        },
        child: sheet,
      );
    }

    return sheet;
  }
}
