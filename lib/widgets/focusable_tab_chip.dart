import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';

/// A focusable tab chip that shows a color change when focused or selected.
///
/// Used for tab navigation in LibrariesScreen. Handles:
/// - SELECT key to activate the tab
/// - LEFT/RIGHT arrows to switch between tabs
/// - DOWN arrow to navigate to tab content
/// - BACK key to navigate to sidenav
class FocusableTabChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  /// Optional external focus node for programmatic focus control.
  final FocusNode? focusNode;

  /// Called when the user presses LEFT from this chip.
  /// Should switch to the previous tab.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses RIGHT from this chip.
  /// Should switch to the next tab.
  final VoidCallback? onNavigateRight;

  /// Called when the user presses DOWN from this chip.
  final VoidCallback? onNavigateDown;

  /// Called when the user presses BACK from this chip.
  final VoidCallback? onBack;

  const FocusableTabChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelect,
    this.focusNode,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onNavigateDown,
    this.onBack,
  });

  @override
  State<FocusableTabChip> createState() => _FocusableTabChipState();
}

class _FocusableTabChipState extends State<FocusableTabChip> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _focusNode {
    return widget.focusNode ??
        (_internalFocusNode ??= FocusNode(debugLabel: 'tab_chip_${widget.label}'));
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FocusableTabChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // SELECT key activates the tab
    if (key.isSelectKey) {
      widget.onSelect();
      return KeyEventResult.handled;
    }

    // LEFT arrow switches to previous tab
    if (key.isLeftKey && widget.onNavigateLeft != null) {
      widget.onNavigateLeft!();
      return KeyEventResult.handled;
    }

    // RIGHT arrow switches to next tab
    if (key.isRightKey && widget.onNavigateRight != null) {
      widget.onNavigateRight!();
      return KeyEventResult.handled;
    }

    // DOWN arrow navigates to tab content
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onNavigateDown?.call();
      return KeyEventResult.handled;
    }

    // BACK key navigates to sidenav
    if (key.isBackKey && widget.onBack != null) {
      widget.onBack!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = FocusTheme.getAnimationDuration(context);
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = _isFocused && InputModeTracker.isKeyboardMode(context);

    // Determine background color based on focus and selection state
    // - Selected + Focused: slightly dimmed primary (to show focus distinction)
    // - Selected only: primary color
    // - Focused only: primary color
    // - Neither: surface color
    Color backgroundColor;
    Color foregroundColor;

    if (widget.isSelected && showFocus) {
      // Selected + focused: dim the primary color slightly
      backgroundColor = Color.lerp(
        colorScheme.primary,
        colorScheme.surface,
        0.25,
      )!;
      foregroundColor = colorScheme.onPrimary;
    } else if (widget.isSelected || showFocus) {
      // Selected or focused (but not both): full primary
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
    } else {
      // Neither selected nor focused
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    final isHighlighted = showFocus || widget.isSelected;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }
}
