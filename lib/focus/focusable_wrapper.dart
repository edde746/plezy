import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dpad_navigator.dart';
import 'focus_theme.dart';
import 'input_mode_tracker.dart';
import 'key_event_utils.dart';

/// A wrapper widget that makes its child focusable with D-pad navigation support.
///
/// Provides:
/// - Visual focus indicator (border + scale animation)
/// - Keyboard/D-pad event handling (Enter/Select to activate)
/// - Optional auto-scroll to keep focused item visible
/// - Long-press detection for SELECT key
/// - Navigation callbacks (UP, BACK)
class FocusableWrapper extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Called when the item is selected (Enter/Select/GamepadA).
  /// For short press when [enableLongPress] is true.
  final VoidCallback? onSelect;

  /// Called when long press is triggered (hold SELECT key or context menu key).
  /// Only triggered if [enableLongPress] is true.
  final VoidCallback? onLongPress;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the user presses UP and there's no focusable item above.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses LEFT and there's no focusable item to the left.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses BACK.
  final VoidCallback? onBack;

  /// Whether this widget should request focus when first built.
  final bool autofocus;

  /// Optional external FocusNode for programmatic focus control.
  final FocusNode? focusNode;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Whether to scroll the widget into view when focused.
  final bool autoScroll;

  /// Alignment for auto-scroll (0.0 = start, 0.5 = center, 1.0 = end).
  final double scrollAlignment;

  /// Whether to use comfortable zone scrolling (only scroll if item is outside middle 60%).
  /// If false, always scrolls to [scrollAlignment].
  final bool useComfortableZone;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Whether the wrapper can receive focus.
  final bool canRequestFocus;

  /// Custom key event handler. Return KeyEventResult.handled to consume the event.
  /// This is called before the default key handling.
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  /// Whether to enable long-press detection for SELECT key.
  /// When enabled, holding SELECT triggers [onLongPress] after 500ms.
  /// Short press triggers [onSelect].
  final bool enableLongPress;

  /// Duration for long-press detection.
  final Duration longPressDuration;

  /// Whether to use background color instead of border for focus indicator.
  /// Useful for video controls where outline doesn't look good.
  final bool useBackgroundFocus;

  /// Whether to disable the scale animation on focus.
  /// Useful for elements like sliders where scaling looks odd.
  final bool disableScale;

  const FocusableWrapper({
    super.key,
    required this.child,
    this.onSelect,
    this.onLongPress,
    this.onFocusChange,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onBack,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = FocusTheme.defaultBorderRadius,
    this.autoScroll = true,
    this.scrollAlignment = 0.5,
    this.useComfortableZone = false,
    this.semanticLabel,
    this.canRequestFocus = true,
    this.onKeyEvent,
    this.enableLongPress = false,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.useBackgroundFocus = false,
    this.disableScale = false,
  });

  @override
  State<FocusableWrapper> createState() => _FocusableWrapperState();
}

class _FocusableWrapperState extends State<FocusableWrapper> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _ownsNode = false;
  bool _isFocused = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Long-press detection for SELECT key
  Timer? _longPressTimer;
  bool _isSelectKeyDown = false;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
    _initAnimations();
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode(
        debugLabel: widget.semanticLabel ?? 'FocusableWrapper',
        canRequestFocus: widget.canRequestFocus,
      );
      _ownsNode = true;
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: FocusTheme.focusScale,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(FocusableWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle focusNode changes
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsNode) {
        _focusNode.dispose();
      }
      _initFocusNode();
    }

    // Update canRequestFocus
    if (widget.canRequestFocus != oldWidget.canRequestFocus) {
      _focusNode.canRequestFocus = widget.canRequestFocus;
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _animationController.dispose();
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });

      // Reset long press state when focus is lost
      if (!hasFocus) {
        _longPressTimer?.cancel();
        _isSelectKeyDown = false;
      }

      // Animate scale
      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }

      // Auto-scroll into view
      if (hasFocus && widget.autoScroll) {
        _scrollIntoView();
      }

      // Notify listener
      widget.onFocusChange?.call(hasFocus);
    }
  }

  // Extra padding for focus decoration (scale + border extends beyond item bounds)
  // Scale 1.02 adds ~1% on each side, plus 2.5px border = ~8px total padding needed
  static const double _focusDecorationPadding = 8.0;

  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFocused) return;

      final renderObject = context.findRenderObject();
      if (renderObject == null) return;

      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;

      final viewport = scrollable.context.findRenderObject() as RenderBox?;
      if (viewport == null) return;

      // Get item's position relative to viewport
      final itemBox = renderObject as RenderBox;
      final itemPosition = itemBox.localToGlobal(Offset.zero, ancestor: viewport);

      final viewportHeight = viewport.size.height;
      final itemHeight = itemBox.size.height;
      final itemVerticalCenter = itemPosition.dy + itemHeight / 2;

      // Account for focus decoration when checking item visibility
      final itemTop = itemPosition.dy - _focusDecorationPadding;
      final itemBottom = itemPosition.dy + itemHeight + _focusDecorationPadding;

      if (widget.useComfortableZone) {
        // Define comfortable zone - if item (including focus decoration) is within middle 60% of viewport, don't scroll
        final comfortZoneTop = viewportHeight * 0.2;
        final comfortZoneBottom = viewportHeight * 0.8;

        if (itemTop >= comfortZoneTop && itemBottom <= comfortZoneBottom) {
          // Item is in comfortable zone, no need to scroll
          return;
        }
      } else {
        // When not using comfortable zone, still skip scroll if item is already
        // close to target position (prevents jitter when navigating horizontally)
        final targetY = viewportHeight * widget.scrollAlignment;
        final distance = (itemVerticalCenter - targetY).abs();
        // Skip scroll if within half the item height of target
        if (distance < itemHeight / 2) {
          return;
        }
      }

      // Calculate target scroll offset for the immediate scrollable only.
      // This avoids Scrollable.ensureVisible which scrolls ALL ancestor scrollables,
      // which can cause issues with nested scroll views (e.g., chips bar scrolling
      // out of view when focusing grid items in library browse tab).
      final position = scrollable.position;
      final currentOffset = position.pixels;

      // Target: item center should be at scrollAlignment of viewport
      // Add padding to ensure focus decoration is fully visible
      final targetViewportY = viewportHeight * widget.scrollAlignment;
      var scrollDelta = itemVerticalCenter - targetViewportY;

      // If item would be near the top edge, add extra scroll to show focus decoration
      final projectedItemTop = itemTop - scrollDelta;
      if (projectedItemTop < _focusDecorationPadding) {
        scrollDelta -= (_focusDecorationPadding - projectedItemTop);
      }

      final targetOffset = (currentOffset + scrollDelta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      position.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      return KeyEventResult.handled;
    }

    // Call custom key handler first
    if (widget.onKeyEvent != null) {
      final result = widget.onKeyEvent!(node, event);
      if (result == KeyEventResult.handled) {
        return result;
      }
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    // Handle SELECT key with optional long-press detection
    if (key.isSelectKey) {
      if (widget.enableLongPress) {
        if (event is KeyDownEvent) {
          // Only start timer on initial press, not repeats
          if (!_isSelectKeyDown) {
            _isSelectKeyDown = true;
            _longPressTimer?.cancel();
            _longPressTimer = Timer(widget.longPressDuration, () {
              // Long press detected
              if (mounted) {
                SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
                widget.onLongPress?.call();
              }
            });
          }
          return KeyEventResult.handled;
        } else if (event is KeyRepeatEvent) {
          // Consume repeat events to prevent system sounds
          return KeyEventResult.handled;
        } else if (event is KeyUpEvent) {
          final timerWasActive = _longPressTimer?.isActive ?? false;
          _longPressTimer?.cancel();
          if (timerWasActive && _isSelectKeyDown) {
            // Timer still active - short press
            widget.onSelect?.call();
          }
          // If timer already fired, long press was triggered - do nothing on key up
          _isSelectKeyDown = false;
          return KeyEventResult.handled;
        }
      } else {
        // Simple select handling without long-press
        if (event is KeyDownEvent) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
      }
    }

    // Ignore key up events for other keys
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    // Context menu key
    if (key.isContextMenuKey) {
      SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
      widget.onLongPress?.call();
      return KeyEventResult.handled;
    }

    // UP arrow - if callback provided, navigate up
    if (key == LogicalKeyboardKey.arrowUp && widget.onNavigateUp != null) {
      widget.onNavigateUp!();
      return KeyEventResult.handled;
    }

    // LEFT arrow - if callback provided, navigate left (caller is responsible
    // for only providing this callback when the item is at the left edge)
    if (key == LogicalKeyboardKey.arrowLeft && widget.onNavigateLeft != null) {
      widget.onNavigateLeft!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final duration = FocusTheme.getAnimationDuration(context);
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = _isFocused && InputModeTracker.isKeyboardMode(context);

    // Update animation duration if theme changes
    if (_animationController.duration != duration) {
      _animationController.duration = duration;
    }

    // Choose decoration based on useBackgroundFocus
    final decoration = widget.useBackgroundFocus
        ? FocusTheme.focusBackgroundDecoration(isFocused: showFocus, borderRadius: widget.borderRadius)
        : FocusTheme.focusDecoration(context, isFocused: showFocus, borderRadius: widget.borderRadius);

    Widget result = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final shouldScale = showFocus && !widget.disableScale;
          return Transform.scale(
            scale: shouldScale ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              decoration: decoration,
              child: widget.child,
            ),
          );
        },
      ),
    );

    // Add semantics if label provided
    if (widget.semanticLabel != null) {
      result = Semantics(label: widget.semanticLabel, button: widget.onSelect != null, child: result);
    }

    return result;
  }
}
