import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../widgets/app_icon.dart';
import '../widgets/clickable_cursor.dart';
import 'focus_theme.dart';
import 'input_mode_tracker.dart';
import 'key_event_utils.dart';
import 'owned_focus_node_binding.dart';

typedef FocusableActionBuilder = Widget Function(BuildContext context, FocusableActionBuildState state);

class FocusableActionBuildState {
  final FocusNode focusNode;
  final bool isFocused;
  final bool showFocus;
  final bool isKeyboardMode;
  final Duration animationDuration;

  const FocusableActionBuildState({
    required this.focusNode,
    required this.isFocused,
    required this.showFocus,
    required this.isKeyboardMode,
    required this.animationDuration,
  });
}

class FocusableAction {
  final IconData icon;
  final Color? iconColor;
  final double iconFill;
  final double iconSize;

  final String? debugLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  final String? tooltip;
  final VoidCallback? onPressed;
  final Widget? child;
  final FocusableActionBuilder? builder;

  const FocusableAction({
    this.icon = Symbols.circle_rounded,
    this.iconColor,
    this.iconFill = 1.0,
    this.iconSize = 24,
    this.debugLabel,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.onPressed,
    this.child,
    this.builder,
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

  /// Called when any action in the row gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

  final double spacing;
  final MainAxisSize mainAxisSize;

  const FocusableActionBar({
    super.key,
    required this.actions,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
    this.onFocusChange,
    this.spacing = 0,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  State<FocusableActionBar> createState() => FocusableActionBarState();
}

class FocusableActionBarState extends State<FocusableActionBar> {
  late List<OwnedFocusNodeBinding> _focusBindings;
  late List<FocusNode> _focusNodes;
  late List<bool> _focusStates;
  bool _hasAnyFocus = false;

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
    if (_shouldRebuildFocusNodes(oldWidget)) {
      _disposeNodes();
      _initNodes();
    }
  }

  bool _shouldRebuildFocusNodes(FocusableActionBar oldWidget) {
    if (oldWidget.actions.length != widget.actions.length) return true;
    for (var i = 0; i < widget.actions.length; i++) {
      if (oldWidget.actions[i].focusNode != widget.actions[i].focusNode) return true;
      if (oldWidget.actions[i].debugLabel != widget.actions[i].debugLabel) return true;
    }
    return false;
  }

  void _initNodes() {
    _focusBindings = [];
    _focusNodes = [];
    _focusStates = List<bool>.filled(widget.actions.length, false);
    for (var i = 0; i < widget.actions.length; i++) {
      final index = i;
      final binding = OwnedFocusNodeBinding();
      binding.bind(
        externalNode: widget.actions[i].focusNode,
        debugLabel: widget.actions[i].debugLabel ?? 'ActionBar[$i]',
        listener: () {
          final hasFocus = _focusNodes[index].hasFocus;
          if (_focusStates[index] != hasFocus) {
            setState(() => _focusStates[index] = hasFocus);
          }
          _notifyRowFocusIfChanged();
        },
      );
      _focusBindings.add(binding);
      _focusNodes.add(binding.node);
      _focusStates[i] = binding.node.hasFocus;
    }
    _hasAnyFocus = _focusNodes.any((node) => node.hasFocus);
  }

  void _notifyRowFocusIfChanged() {
    final hasAnyFocus = _focusNodes.any((node) => node.hasFocus);
    if (_hasAnyFocus == hasAnyFocus) return;
    _hasAnyFocus = hasAnyFocus;
    widget.onFocusChange?.call(hasAnyFocus);
  }

  void _disposeNodes() {
    for (final binding in _focusBindings) {
      binding.dispose();
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

    final row = Row(
      mainAxisSize: widget.mainAxisSize,
      children: [
        for (var i = 0; i < widget.actions.length; i++) ...[
          if (i > 0 && widget.spacing > 0) SizedBox(width: widget.spacing),
          _buildButton(i, isKeyboard, duration),
        ],
      ],
    );
    // While focus is outside the row (the common state — the user is browsing
    // content), every button is equally dimmed, so dim once at row level:
    // each sub-1.0 opacity is its own saveLayer, i.e. a full render-pass
    // switch on the tiled GPUs low-end TVs use, and these bars sit on screen
    // permanently. Per-button dims (below) take over only while the row holds
    // focus; mid-transition the two multiply, which stays visually seamless.
    return AnimatedOpacity(opacity: isKeyboard && !_hasAnyFocus ? 0.6 : 1.0, duration: duration, child: row);
  }

  Widget _buildButton(int index, bool isKeyboard, Duration duration) {
    final action = widget.actions[index];
    final isFocused = _focusStates[index];
    final showFocus = isFocused && isKeyboard;
    final opacity = isKeyboard && _hasAnyFocus && !isFocused ? 0.6 : 1.0;

    final buildState = FocusableActionBuildState(
      focusNode: _focusNodes[index],
      isFocused: isFocused,
      showFocus: showFocus,
      isKeyboardMode: isKeyboard,
      animationDuration: duration,
    );
    final customChild = action.builder?.call(context, buildState);

    return Focus(
      focusNode: _focusNodes[index],
      autofocus: action.autofocus,
      descendantsAreFocusable: false,
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
          // Consume LEFT/RIGHT at the row's first/last button when no edge
          // callback is wired, so focus can't fall off the row (#1181).
          trapHorizontalEdges: true,
        )(node, event);
      },
      child: ClickableCursor(
        enabled: action.onPressed != null || action.child != null || customChild != null,
        child: AnimatedOpacity(
          opacity: showFocus ? 1.0 : opacity,
          duration: duration,
          child:
              customChild ??
              Container(
                decoration: FocusTheme.focusBackgroundDecoration(isFocused: showFocus, borderRadius: 20),
                child:
                    action.child ??
                    IconButton(
                      icon: AppIcon(action.icon, size: action.iconSize, fill: action.iconFill, color: action.iconColor),
                      tooltip: action.tooltip,
                      onPressed: action.onPressed,
                    ),
              ),
        ),
      ),
    );
  }
}
