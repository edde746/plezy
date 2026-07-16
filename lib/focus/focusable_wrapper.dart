import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/clickable_cursor.dart';
import '../utils/text_input_diagnostics.dart';
import 'card_focus_scope.dart';
import 'dpad_navigator.dart';
import 'dpad_select_long_press_controller.dart';
import 'focus_glow_overlay.dart';
import 'focus_theme.dart';
import 'input_mode_tracker.dart';
import 'owned_focus_node_binding.dart';
import 'key_event_utils.dart';

String _describeFocusableKey(KeyEvent event) {
  return 'type=${event.runtimeType} logical=${event.logicalKey.keyLabel}/${event.logicalKey.keyId} '
      'physical=${event.physicalKey.usbHidUsage} deviceType=${event.deviceType} character=${event.character}';
}

void _logFocusableWrapper(String message) {
  TextInputDiagnostics.log('FocusableWrapper', message);
}

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

  /// Called when the user presses DOWN and there's no focusable item below.
  final VoidCallback? onNavigateDown;

  /// Called when the user presses LEFT and there's no focusable item to the left.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses RIGHT and there's no focusable item to the right.
  final VoidCallback? onNavigateRight;

  /// Called when the user presses BACK.
  final VoidCallback? onBack;

  /// Whether this widget should request focus when first built.
  final bool autofocus;

  /// Optional external FocusNode for programmatic focus control.
  final FocusNode? focusNode;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Per-corner radii for the focus indicator; overrides [borderRadius] when
  /// set (M3E grouped cards: large outer / small inner corners).
  final BorderRadius? borderRadii;

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

  /// Custom key event handler. Return any non-ignored result to stop default handling.
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

  /// Custom color for the focus border. Only used when [useBackgroundFocus] is false.
  /// Useful for filled buttons where the default primary border blends in.
  final Color? focusColor;

  /// Whether to disable the scale animation on focus.
  /// Useful for elements like sliders where scaling looks odd.
  final bool disableScale;

  /// Scale used for the focus animation.
  final double focusScale;

  /// Whether to draw a glow around the focused widget.
  final bool useFocusGlow;

  /// Skip drawing the focus border here and expose the focus state through a
  /// [CardFocusScope] instead, so the child places the border on the exact
  /// rect it wants highlighted (e.g. MediaCard's poster image).
  final bool delegateFocusBorder;

  /// Whether descendants can receive focus.
  /// Set to false when the child widget has its own Focus (e.g. buttons)
  /// that would compete with this wrapper's focus handling.
  final bool descendantsAreFocusable;

  const FocusableWrapper({
    super.key,
    required this.child,
    this.onSelect,
    this.onLongPress,
    this.onFocusChange,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = FocusTheme.defaultBorderRadius,
    this.borderRadii,
    this.autoScroll = true,
    this.scrollAlignment = 0.5,
    this.useComfortableZone = false,
    this.semanticLabel,
    this.canRequestFocus = true,
    this.onKeyEvent,
    this.enableLongPress = false,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.useBackgroundFocus = false,
    this.focusColor,
    this.disableScale = false,
    this.focusScale = FocusTheme.focusScale,
    this.useFocusGlow = false,
    this.delegateFocusBorder = false,
    this.descendantsAreFocusable = true,
  });

  @override
  State<FocusableWrapper> createState() => _FocusableWrapperState();
}

class _FocusableWrapperState extends State<FocusableWrapper> with SingleTickerProviderStateMixin {
  final OwnedFocusNodeBinding _focusNodeBinding = OwnedFocusNodeBinding();
  FocusNode get _focusNode => _focusNodeBinding.node;
  bool _isFocused = false;

  // Created lazily on first focus/keyboard-mode build: touch scrolling builds
  // hundreds of these wrappers and must not pay for a Ticker per card.
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  final _selectLongPress = DpadSelectLongPressController();

  @override
  void initState() {
    super.initState();
    _bindFocusNode();
  }

  void _bindFocusNode() {
    _focusNodeBinding.bind(externalNode: widget.focusNode, debugLabel: widget.semanticLabel ?? 'FocusableWrapper');
    _focusNode.canRequestFocus = widget.canRequestFocus;
  }

  AnimationController _ensureAnimationController() {
    final existing = _animationController;
    if (existing != null) return existing;
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _animationController = controller;
    _scaleAnimation = _createScaleAnimation(controller);
    return controller;
  }

  Animation<double> _createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: widget.focusScale,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(FocusableWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle focusNode changes
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocusNode();
    }

    // Update canRequestFocus
    if (widget.canRequestFocus != oldWidget.canRequestFocus) {
      _focusNode.canRequestFocus = widget.canRequestFocus;
    }

    if (widget.focusScale != oldWidget.focusScale) {
      final controller = _animationController;
      if (controller != null) {
        _scaleAnimation = _createScaleAnimation(controller);
      }
    }
  }

  @override
  void dispose() {
    _selectLongPress.dispose();
    _animationController?.dispose();
    _focusNodeBinding.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });

      // Reset long press state when focus is lost
      if (!hasFocus) {
        _selectLongPress.reset();
      }

      // Animate scale
      if (hasFocus) {
        _ensureAnimationController().forward();
      } else {
        _animationController?.reverse();
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

      // Find the nearest vertical scrollable that actually has scroll range.
      // Skip inner scrollables with no extent (e.g. shrinkWrap ListView
      // with NeverScrollableScrollPhysics inside an outer scroll view)
      // and horizontal scrollables (e.g. TabBarView) since we only do
      // vertical scroll calculations.
      var scrollable = Scrollable.maybeOf(context);
      while (scrollable != null) {
        final pos = scrollable.position;
        if (pos.axis == Axis.vertical && pos.maxScrollExtent > pos.minScrollExtent) break;
        scrollable = Scrollable.maybeOf(scrollable.context);
      }
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

      if (!position.maxScrollExtent.isFinite) return;
      final targetOffset = (currentOffset + scrollDelta).clamp(position.minScrollExtent, position.maxScrollExtent);

      position.animateTo(targetOffset, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final diagnosticsEnabled = TextInputDiagnostics.enabled;
    KeyEventResult finish(KeyEventResult result, String reason) {
      if (diagnosticsEnabled) {
        _logFocusableWrapper(
          'node=${node.debugLabel} result=$result reason=$reason key=(${_describeFocusableKey(event)}) '
          'onNav(up=${widget.onNavigateUp != null},down=${widget.onNavigateDown != null},'
          'left=${widget.onNavigateLeft != null},right=${widget.onNavigateRight != null}) '
          'onSelect=${widget.onSelect != null} onBack=${widget.onBack != null}',
        );
      }
      return result;
    }

    if (diagnosticsEnabled) {
      _logFocusableWrapper('node=${node.debugLabel} received key=(${_describeFocusableKey(event)})');
    }

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      if (event is KeyUpEvent && key.isSelectKey) {
        _selectLongPress.reset();
      }
      return finish(KeyEventResult.handled, 'select-key-up-suppressed');
    }

    // Call custom key handler first
    if (widget.onKeyEvent != null) {
      final result = widget.onKeyEvent!(node, event);
      if (result != KeyEventResult.ignored) {
        return finish(result, 'custom-onKeyEvent');
      }
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) {
        return finish(backResult, 'onBack');
      }
    }

    // Handle SELECT key with optional long-press detection
    if (key.isSelectKey) {
      if (widget.enableLongPress) {
        final result = _selectLongPress.handleKeyEvent(
          event,
          duration: widget.longPressDuration,
          isOwnerActive: () => mounted,
          onShortPress: () => widget.onSelect?.call(),
          onLongPress: () => widget.onLongPress?.call(),
        );
        if (result != KeyEventResult.ignored) {
          return finish(result, 'select-long-press');
        }
      } else if (widget.onSelect != null) {
        return finish(handleOneShotSelect(event, widget.onSelect!), 'one-shot-select');
      }
    }

    // Ignore key up events for other keys
    if (!event.isActionable) {
      return finish(KeyEventResult.ignored, 'non-actionable');
    }

    // Context menu key
    if (key.isContextMenuKey) {
      _selectLongPress.reset();
      widget.onLongPress?.call();
      return finish(KeyEventResult.handled, 'context-menu');
    }

    // UP arrow - if callback provided, navigate up
    if (key == LogicalKeyboardKey.arrowUp && widget.onNavigateUp != null) {
      widget.onNavigateUp!();
      return finish(KeyEventResult.handled, 'onNavigateUp');
    }

    // DOWN arrow - if callback provided, navigate down
    if (key == LogicalKeyboardKey.arrowDown && widget.onNavigateDown != null) {
      widget.onNavigateDown!();
      return finish(KeyEventResult.handled, 'onNavigateDown');
    }

    // LEFT arrow - if callback provided, navigate left (caller is responsible
    // for only providing this callback when the item is at the left edge)
    if (key == LogicalKeyboardKey.arrowLeft && widget.onNavigateLeft != null) {
      widget.onNavigateLeft!();
      return finish(KeyEventResult.handled, 'onNavigateLeft');
    }

    // RIGHT arrow - if callback provided, navigate right (caller is responsible
    // for only providing this callback when the item is at the right edge)
    if (key == LogicalKeyboardKey.arrowRight && widget.onNavigateRight != null) {
      widget.onNavigateRight!();
      return finish(KeyEventResult.handled, 'onNavigateRight');
    }

    return finish(KeyEventResult.ignored, 'fall-through');
  }

  @override
  Widget build(BuildContext context) {
    // Only show focus effects during keyboard/d-pad navigation. In pointer/
    // touch mode no card ever shows focus chrome, so skip the animated
    // scale/border wrappers entirely — they cost real build time multiplied
    // by every card in a grid. The Focus node stays mounted so d-pad
    // traversal finds the cards the moment keyboard mode activates (which
    // rebuilds this widget via the inherited dependency below).
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final showFocus = _isFocused && isKeyboardMode;

    Widget inner;
    if (!isKeyboardMode) {
      inner = widget.child;
    } else {
      final duration = FocusTheme.getAnimationDuration(context);
      final controller = _ensureAnimationController();
      // Update animation duration if theme changes
      if (controller.duration != duration) {
        controller.duration = duration;
      }

      inner = AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (context, child) {
          final shouldScale = showFocus && !widget.disableScale;
          // The glow (full-bleed cards) is drawn in an overlay above siblings so
          // it stays symmetric; the in-card decoration only carries the border.
          Widget card;
          if (widget.delegateFocusBorder) {
            card = CardFocusScope(showFocus: showFocus, child: widget.child);
          } else {
            final focusDecoration = widget.useBackgroundFocus
                ? FocusTheme.focusBackgroundDecoration(
                    isFocused: showFocus,
                    borderRadius: widget.borderRadius,
                    radii: widget.borderRadii,
                  )
                : FocusTheme.focusDecoration(
                    context,
                    isFocused: showFocus,
                    borderRadius: widget.borderRadius,
                    radii: widget.borderRadii,
                    color: widget.focusColor,
                  );
            card = AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              decoration: focusDecoration,
              child: widget.child,
            );
          }
          if (widget.useFocusGlow) {
            card = FocusGlowOverlay(
              isFocused: showFocus,
              borderRadius: widget.borderRadius,
              color: widget.focusColor ?? FocusTheme.getFocusBorderColor(context),
              child: card,
            );
          }
          return Transform.scale(scale: shouldScale ? _scaleAnimation!.value : 1.0, child: card);
        },
      );
    }

    Widget result = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: inner,
    );

    // Add semantics if label provided
    if (widget.semanticLabel != null) {
      result = Semantics(label: widget.semanticLabel, button: widget.onSelect != null, child: result);
    }

    if (widget.onSelect != null || widget.onLongPress != null) {
      result = ClickableCursor(child: result);
    }

    return result;
  }
}
