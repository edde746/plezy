import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/focusable_chip_mixin.dart';
import '../focus/input_mode_tracker.dart';
import 'focus_builders.dart';

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

class _FocusableTabChipState extends State<FocusableTabChip>
    with FocusableChipStateMixin<FocusableTabChip> {
  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  String get debugLabel => 'tab_chip_${widget.label}';

  @override
  void initState() {
    super.initState();
    initFocusNode();
  }

  @override
  void didUpdateWidget(FocusableTabChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(oldWidget.focusNode);
  }

  @override
  void dispose() {
    disposeFocusNode();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    return handleChipKeyEvent(
      node,
      event,
      ChipKeyCallbacks(
        onSelect: widget.onSelect,
        onNavigateLeft: widget.onNavigateLeft,
        onNavigateRight: widget.onNavigateRight,
        onNavigateDown: widget.onNavigateDown,
        onBack: widget.onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = isFocused && InputModeTracker.isKeyboardMode(context);

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

    return FocusBuilders.buildFocusableChip(
      context: context,
      focusNode: focusNode,
      isFocused: isFocused,
      onKeyEvent: _handleKeyEvent,
      onTap: widget.onSelect,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: backgroundColor,
      child: Text(
        widget.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
