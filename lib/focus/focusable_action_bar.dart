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
  final bool showFocus;
  final Duration animationDuration;

  const FocusableActionBuildState({required this.showFocus, required this.animationDuration});
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

  /// Row gap between this action and the one before it, overriding the bar's
  /// uniform [FocusableActionBar.spacing]. Lets visually joined pairs (the
  /// detail screen's split Play button) sit tighter than the rest of the row.
  /// Ignored on the first action.
  final double? spacingBefore;

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
    this.spacingBefore,
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
    final index = _nextEnabledIndex(-1);
    if (index != null) _focusNodes[index].requestFocus();
  }

  int? _previousEnabledIndex(int index) {
    for (var candidate = index - 1; candidate >= 0; candidate--) {
      if (widget.actions[candidate].onPressed != null) return candidate;
    }
    return null;
  }

  int? _nextEnabledIndex(int index) {
    for (var candidate = index + 1; candidate < widget.actions.length; candidate++) {
      if (widget.actions[candidate].onPressed != null) return candidate;
    }
    return null;
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
      _rebindNodes(oldWidget.actions);
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

  /// Stable identity for matching an action across list changes: the supplied
  /// [FocusableAction.focusNode] first, else [FocusableAction.debugLabel].
  /// Unlabeled actions have no identity and only ever match positionally.
  static Object? _actionIdentity(FocusableAction action) => action.focusNode ?? action.debugLabel;

  /// Whether the action-list shape is unchanged: same length and every
  /// labeled identity present in both lists sits at the index it had. Only
  /// then does an unlabeled action's position provably still refer to the
  /// same conceptual action.
  bool _unlabeledPositionsStable(List<FocusableAction> oldActions) {
    if (oldActions.length != widget.actions.length) return false;
    for (var i = 0; i < oldActions.length; i++) {
      final identity = _actionIdentity(oldActions[i]);
      if (identity == null) continue;
      for (var j = 0; j < widget.actions.length; j++) {
        if (j != i && _actionIdentity(widget.actions[j]) == identity) return false;
      }
    }
    return true;
  }

  OwnedFocusNodeBinding _createBinding(FocusableAction action, int index) {
    final binding = OwnedFocusNodeBinding();
    binding.bind(
      externalNode: action.focusNode,
      debugLabel: action.debugLabel ?? 'ActionBar[$index]',
      listener: () => _handleBindingFocusChange(binding),
    );
    return binding;
  }

  /// Index resolved at call time: a binding survives action-list changes, so
  /// a listener must not capture the slot it was created for.
  void _handleBindingFocusChange(OwnedFocusNodeBinding binding) {
    final index = _focusBindings.indexOf(binding);
    if (index != -1) {
      final hasFocus = binding.node.hasFocus;
      if (_focusStates[index] != hasFocus) {
        setState(() => _focusStates[index] = hasFocus);
      }
    }
    _notifyRowFocusIfChanged();
  }

  void _initNodes() {
    _focusBindings = [for (var i = 0; i < widget.actions.length; i++) _createBinding(widget.actions[i], i)];
    _focusNodes = [for (final binding in _focusBindings) binding.node];
    _focusStates = [for (final node in _focusNodes) node.hasFocus];
    _hasAnyFocus = _focusNodes.any((node) => node.hasFocus);
  }

  /// Rebind on an action-list change, reusing the binding of every action
  /// whose identity survives so its focus node is not disposed out from under
  /// the user (media detail's watchlist action arrives asynchronously and
  /// used to drop D-pad focus with the wholesale rebuild). A removed focused
  /// action is disposed with its listener already detached, so the genuine
  /// row-focus loss is reported through [_notifyRowFocusIfChanged] here.
  void _rebindNodes(List<FocusableAction> oldActions) {
    final oldBindings = _focusBindings;
    final focusedOldIndex = _focusNodes.indexWhere((node) => node.hasFocus);

    final claimed = List<bool>.filled(oldBindings.length, false);
    final unlabeledPositionsStable = _unlabeledPositionsStable(oldActions);
    int? matchOldIndex(int newIndex) {
      final identity = _actionIdentity(widget.actions[newIndex]);
      if (identity != null) {
        for (var i = 0; i < oldActions.length; i++) {
          if (!claimed[i] && _actionIdentity(oldActions[i]) == identity) return i;
        }
        return null;
      }
      // Positional reuse is the only option for an unlabeled action, but it
      // is only provably correct while the list shape is unchanged; across an
      // insertion/removal its successor is unknowable, so fall through to a
      // fresh binding — genuinely dropping focus beats silently retargeting
      // the focused binding (and its next Select) onto a different action.
      if (unlabeledPositionsStable && !claimed[newIndex] && _actionIdentity(oldActions[newIndex]) == null) {
        return newIndex;
      }
      return null;
    }

    var focusedNewIndex = -1;
    final newBindings = <OwnedFocusNodeBinding>[];
    for (var i = 0; i < widget.actions.length; i++) {
      final oldIndex = matchOldIndex(i);
      if (oldIndex == null) {
        newBindings.add(_createBinding(widget.actions[i], i));
        continue;
      }
      claimed[oldIndex] = true;
      if (oldIndex == focusedOldIndex) focusedNewIndex = i;
      newBindings.add(oldBindings[oldIndex]);
    }

    _focusBindings = newBindings;
    _focusNodes = [for (final binding in newBindings) binding.node];
    _focusStates = [for (final node in _focusNodes) node.hasFocus];

    for (var i = 0; i < oldBindings.length; i++) {
      if (!claimed[i]) oldBindings[i].dispose();
    }

    // The focused action survived: keep focus on it. The keyed row keeps its
    // Focus element attached across reorders, so this only re-requests focus
    // if the framework unfocused the node during widget churn.
    if (focusedNewIndex != -1 &&
        widget.actions[focusedNewIndex].onPressed != null &&
        !_focusNodes[focusedNewIndex].hasFocus) {
      _focusNodes[focusedNewIndex].requestFocus();
    }
    _notifyRowFocusIfChanged();
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
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.actions.length; i++) ...[
          if (i > 0 && _gapBefore(i) > 0) SizedBox(width: _gapBefore(i)),
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

  double _gapBefore(int index) => widget.actions[index].spacingBefore ?? widget.spacing;

  Widget _buildButton(int index, bool isKeyboard, Duration duration) {
    final action = widget.actions[index];
    final enabled = action.onPressed != null;
    final isFocused = _focusStates[index];
    final showFocus = isFocused && isKeyboard;
    final opacity = isKeyboard && _hasAnyFocus && !isFocused ? 0.6 : 1.0;
    final buildState = FocusableActionBuildState(showFocus: showFocus, animationDuration: duration);
    final customChild = action.builder?.call(context, buildState);

    return Focus(
      // Keyed on the binding so an insertion moves the element with its node
      // instead of detaching (and thereby unfocusing) it slot by slot.
      key: ObjectKey(_focusBindings[index]),
      focusNode: _focusNodes[index],
      canRequestFocus: enabled,
      autofocus: action.autofocus && enabled,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) {
        if (widget.onBack != null) {
          final backResult = handleBackKeyAction(event, widget.onBack!);
          if (backResult != KeyEventResult.ignored) return backResult;
        }
        final previousIndex = _previousEnabledIndex(index);
        final nextIndex = _nextEnabledIndex(index);
        return dpadKeyHandler(
          onSelect: action.onPressed,
          onLeft: previousIndex != null ? () => _focusNodes[previousIndex].requestFocus() : widget.onNavigateLeft,
          onRight: nextIndex != null ? () => _focusNodes[nextIndex].requestFocus() : widget.onNavigateRight,
          onDown: widget.onNavigateDown,
          onUp: widget.onNavigateUp,
          // Consume LEFT/RIGHT at the row's first/last enabled button when no
          // edge callback is wired, so focus can't fall off the row (#1181).
          trapHorizontalEdges: true,
        )(node, event);
      },
      child: ClickableCursor(
        enabled: enabled,
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
