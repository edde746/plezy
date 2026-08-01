import 'package:flutter/material.dart';

import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../theme/mono_motion.dart';
import '../theme/mono_tokens.dart';
import '../utils/platform_detector.dart';

/// M3E connected button group: the selected segment is a filled pill, the
/// unselected segments are rounded squares, and the row's outermost corners
/// are fully rounded so the whole group reads as one pill. Segments morph
/// shape+fill on selection and squish (radius narrows) on press.
///
/// Reuses [ButtonSegment] as a plain data holder (value/icon/label/enabled/
/// tooltip) so [SegmentedButton] call sites port without changes.
///
/// D-pad: LEFT/RIGHT rove within the group with the edges trapped (#1181),
/// SELECT commits, UP/DOWN exit via framework traversal. Focus visuals are
/// background fills gated by keyboard mode. No width/flex morphing of the
/// selected segment (deliberate simplification of the full M3E behavior).
class ExpressiveButtonGroup<T> extends StatefulWidget {
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// true: Row of Expanded — full-width equal segments (settings use).
  /// false: intrinsic segment widths (dialogs / sheets).
  final bool expandSegments;
  final double minHeight;
  final bool enabled;

  const ExpressiveButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expandSegments = true,
    this.minHeight = 40,
    this.enabled = true,
  });

  @override
  State<ExpressiveButtonGroup<T>> createState() => _ExpressiveButtonGroupState<T>();
}

class _ExpressiveButtonGroupState<T> extends State<ExpressiveButtonGroup<T>> {
  late List<FocusNode> _focusNodes;
  late List<VoidCallback> _focusListeners;
  late List<bool> _focusStates;
  int? _pressedIndex;

  /// Segment whose press was just released; keeps the un-squish on the fast
  /// press duration until the selection change re-triggers the shape morph.
  int? _releasedIndex;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _initNodes();
  }

  @override
  void didUpdateWidget(ExpressiveButtonGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length) {
      _disposeNodes();
      _initNodes();
      _pressedIndex = null;
      _releasedIndex = null;
      _hoveredIndex = null;
    }
    if (oldWidget.selected != widget.selected) _releasedIndex = null;
  }

  void _initNodes() {
    _focusNodes = List.generate(widget.segments.length, (i) => FocusNode(debugLabel: 'ButtonGroup[$i]'));
    _focusStates = List.generate(widget.segments.length, (i) => false);
    _focusListeners = [];
    for (var i = 0; i < _focusNodes.length; i++) {
      final idx = i;
      void listener() {
        final hasFocus = _focusNodes[idx].hasFocus;
        if (_focusStates[idx] != hasFocus) {
          setState(() => _focusStates[idx] = hasFocus);
        }
      }

      _focusListeners.add(listener);
      _focusNodes[i].addListener(listener);
    }
  }

  void _disposeNodes() {
    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].removeListener(_focusListeners[i]);
      _focusNodes[i].dispose();
    }
  }

  @override
  void dispose() {
    _disposeNodes();
    super.dispose();
  }

  void _commit(ButtonSegment<T> segment) {
    if (segment.value != widget.selected) widget.onChanged(segment.value);
  }

  BorderRadius _radiiFor(int i, bool selected, bool pressed, MonoTokens t) {
    if (selected) {
      return BorderRadius.circular(pressed ? t.radiusLg : MonoTokens.radiusFull);
    }
    // The row-end corners stay fully rounded even while pressed so the group
    // keeps its pill silhouette.
    final inner = Radius.circular(pressed ? t.radiusXs : t.radiusSm);
    const outer = Radius.circular(MonoTokens.radiusFull);
    return BorderRadius.horizontal(
      left: i == 0 ? outer : inner,
      right: i == widget.segments.length - 1 ? outer : inner,
    );
  }

  Color _fillFor(bool selected, bool focused, bool hovered, ColorScheme cs, MonoTokens t) {
    if (selected) return focused ? Color.lerp(cs.primary, cs.surface, 0.25)! : cs.primary;
    if (focused) return t.text.withValues(alpha: 0.18);
    if (hovered) return t.text.withValues(alpha: 0.12);
    return t.text.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Row(
      mainAxisSize: widget.expandSegments ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.segments.length; i++) ...[
          if (i > 0) SizedBox(width: t.groupGap),
          if (widget.expandSegments) Expanded(child: _buildSegment(context, i)) else _buildSegment(context, i),
        ],
      ],
    );
  }

  Widget _buildSegment(BuildContext context, int i) {
    final theme = Theme.of(context);
    final t = tokens(context);
    final segment = widget.segments[i];
    final enabled = widget.enabled && segment.enabled;
    final selected = segment.value == widget.selected;
    final focused = _focusStates[i] && InputModeTracker.isKeyboardMode(context);
    final pressed = _pressedIndex == i;
    // Press squish in/out runs on the fast duration; everything else (the
    // selection morph) on the expressive shape duration.
    final duration = (pressed || _releasedIndex == i) ? MonoMotion.press(context) : MonoMotion.shape(context);

    final foreground = selected ? theme.colorScheme.onPrimary : t.text;
    final label = segment.label == null
        ? null
        : AnimatedDefaultTextStyle(
            duration: MonoMotion.fill(context),
            curve: MonoMotion.standard,
            style: theme.textTheme.labelLarge!.copyWith(
              color: foreground,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: segment.label!,
          );
    final icon = segment.icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: foreground, size: 18),
            child: segment.icon!,
          );

    final content = icon != null && label != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 8), label])
        : (label ?? icon);

    Widget child = AnimatedContainer(
      duration: duration,
      curve: MonoMotion.emphasized,
      constraints: BoxConstraints(minHeight: widget.minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fillFor(selected, focused, _hoveredIndex == i, theme.colorScheme, t),
        borderRadius: _radiiFor(i, selected, pressed, t),
      ),
      // Labels never wrap: a group where one segment breaks onto two lines
      // while its neighbors stay on one reads broken. Overlong labels scale
      // down to fit instead.
      child: content == null ? null : FittedBox(fit: BoxFit.scaleDown, child: content),
    );

    if (!enabled) {
      child = Opacity(opacity: 0.4, child: child);
    } else {
      child = GestureDetector(
        onTapDown: (_) => setState(() => _pressedIndex = i),
        onTapUp: (_) => setState(() {
          _pressedIndex = null;
          _releasedIndex = i;
        }),
        onTapCancel: () => setState(() {
          _pressedIndex = null;
          _releasedIndex = i;
        }),
        onTap: () => _commit(segment),
        child: child,
      );
      // Hover tracking + click cursor; skipped on TV like ClickableCursor,
      // except on desktop (force-TV mode there still has a real mouse).
      if (!PlatformDetector.isTV() || PlatformDetector.isDesktopOS()) {
        child = MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredIndex = i),
          onExit: (_) => setState(() => _hoveredIndex = _hoveredIndex == i ? null : _hoveredIndex),
          child: child,
        );
      }
    }

    if (segment.tooltip != null) child = Tooltip(message: segment.tooltip!, child: child);

    return Focus(
      focusNode: _focusNodes[i],
      canRequestFocus: enabled,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) => dpadKeyHandler(
        onSelect: () => _commit(segment),
        onLeft: i > 0 ? () => _focusNodes[i - 1].requestFocus() : null,
        onRight: i < widget.segments.length - 1 ? () => _focusNodes[i + 1].requestFocus() : null,
        trapHorizontalEdges: true,
      )(node, event),
      child: Semantics(button: true, selected: selected, enabled: enabled, child: child),
    );
  }
}
