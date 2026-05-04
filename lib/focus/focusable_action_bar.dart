import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';
import 'focus_theme.dart';
import 'input_mode_tracker.dart';
import 'key_event_utils.dart';

class FocusableAction {
  final IconData icon;
  final Color? iconColor;
  final double iconFill;

  final String? tooltip;
  final VoidCallback? onPressed;
  final Widget? child;

  const FocusableAction({
    this.icon = Icons.circle,
    this.iconColor,
    this.iconFill = 1.0,
    this.tooltip,
    this.onPressed,
    this.child,
  });
}

class FocusableActionBar extends StatefulWidget {
  final List<FocusableAction> actions;

  /// Called when the user presses down from any action button.
  final VoidCallback? onNavigateDown;

  /// Called when the user presses up from any action button.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses left from the leftmost button.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses right from the rightmost button.
  final VoidCallback? onNavigateRight;

  /// Called when the user presses the back key while an action is focused.
  final VoidCallback? onBack;

  const FocusableActionBar({
    super.key,
    required this.actions,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
  });

  @override
  State<FocusableActionBar> createState() => FocusableActionBarState();
}

class FocusableActionBarState extends State<FocusableActionBar> {
  late List<FocusNode> _focusNodes;
  late List<bool> _focusStates;

  FocusNode? getFocusNode(int index) => index >= 0 && index < _focusNodes.length ? _focusNodes[index] : null;

  void requestFocusOnFirst() {
    if (_focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _initNodes();
  }

  @override
  void didUpdateWidget(FocusableActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions.length != widget.actions.length) {
      _disposeNodes();
      _initNodes();
    }
  }

  void _initNodes() {
    _focusNodes = List.generate(widget.actions.length, (i) => FocusNode(debugLabel: 'ActionBar[$i]'));
    _focusStates = List.filled(widget.actions.length, false);
    for (var i = 0; i < _focusNodes.length; i++) {
      final idx = i;
      _focusNodes[i].addListener(() {
        final hasFocus = _focusNodes[idx].hasFocus;
        if (_focusStates[idx] != hasFocus) {
          setState(() => _focusStates[idx] = hasFocus);
        }
      });
    }
  }

  void _disposeNodes() {
    for (final node in _focusNodes) {
      node.dispose();
    }
  }

  @override
  void dispose() {
    _disposeNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboard = InputModeTracker.isKeyboardMode(context);
    final duration = FocusTheme.getAnimationDuration(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < widget.actions.length; i++) _buildButton(i, isKeyboard, duration)],
    );
  }

  Widget _buildButton(int index, bool isKeyboard, Duration duration) {
    final action = widget.actions[index];
    final isFocused = _focusStates[index];
    final showFocus = isFocused && isKeyboard;
    final opacity = isKeyboard && !isFocused ? 0.6 : 1.0;

    return Focus(
      focusNode: _focusNodes[index],
      onKeyEvent: (node, event) {
        if (widget.onBack != null) {
          final backResult = handleBackKeyAction(event, widget.onBack!);
          if (backResult != KeyEventResult.ignored) return backResult;
        }
        return dpadKeyHandler(
          onSelect: action.onPressed,
          onLeft: index > 0 ? () => _focusNodes[index - 1].requestFocus() : widget.onNavigateLeft,
          onRight: index < _focusNodes.length - 1
              ? () => _focusNodes[index + 1].requestFocus()
              : widget.onNavigateRight,
          onDown: widget.onNavigateDown,
          onUp: widget.onNavigateUp,
        )(node, event);
      },
      child: AnimatedOpacity(
        opacity: showFocus ? 1.0 : opacity,
        duration: duration,
        child: Container(
          decoration: FocusTheme.focusBackgroundDecoration(isFocused: showFocus, borderRadius: 20),
          child:
              action.child ??
              IconButton(
                icon: AppIcon(action.icon, fill: action.iconFill, color: action.iconColor),
                tooltip: action.tooltip,
                onPressed: action.onPressed,
              ),
        ),
      ),
    );
  }
}
