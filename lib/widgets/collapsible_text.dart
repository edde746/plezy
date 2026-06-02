import 'package:flutter/material.dart';

import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import 'clickable_cursor.dart';

class CollapsibleText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final bool small;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final ValueChanged<bool>? onOverflowChanged;
  final bool skipTraversal;

  const CollapsibleText({
    super.key,
    required this.text,
    this.maxLines = 4,
    this.style,
    this.small = false,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onOverflowChanged,
    this.skipTraversal = true,
  });

  @override
  State<CollapsibleText> createState() => _CollapsibleTextState();
}

class _CollapsibleTextState extends State<CollapsibleText> {
  bool _expanded = false;
  bool? _lastReportedOverflow;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  void _reportOverflow(bool overflows) {
    if (_lastReportedOverflow == overflows) return;
    _lastReportedOverflow = overflows;
    if (widget.onOverflowChanged == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastReportedOverflow != overflows) return;
      widget.onOverflowChanged?.call(overflows);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final selectResult = handleOneShotSelect(event, _toggleExpanded);
    if (selectResult != KeyEventResult.ignored) return selectResult;

    if (!event.isActionable) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key.isUpKey && widget.onNavigateUp != null) {
      widget.onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (key.isDownKey && widget.onNavigateDown != null) {
      widget.onNavigateDown!();
      return KeyEventResult.handled;
    }
    if (key.isLeftKey && widget.onNavigateLeft != null) {
      widget.onNavigateLeft!();
      return KeyEventResult.handled;
    }
    if (key.isRightKey && widget.onNavigateRight != null) {
      widget.onNavigateRight!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = textPainter.didExceedMaxLines;
        _reportOverflow(overflows);

        if (!overflows) {
          textPainter.dispose();
          return Text(widget.text, style: style);
        }

        String displayText = widget.text;
        if (!_expanded) {
          // Find where to truncate to leave room for the badge on the last line
          final cutPoint = textPainter.getPositionForOffset(Offset(constraints.maxWidth - 54, textPainter.height - 1));
          displayText = widget.text.substring(0, cutPoint.offset).trimRight();
        }
        textPainter.dispose();

        Widget result = Text.rich(
          TextSpan(
            children: [
              TextSpan(text: displayText, style: style),
              if (!_expanded)
                WidgetSpan(
                  alignment: widget.small ? PlaceholderAlignment.baseline : PlaceholderAlignment.middle,
                  baseline: widget.small ? TextBaseline.alphabetic : null,
                  child: _buildBadge(context),
                ),
            ],
          ),
        );

        final focusNode = widget.focusNode;
        if (focusNode != null) {
          result = Focus(
            focusNode: focusNode,
            skipTraversal: widget.skipTraversal,
            onKeyEvent: _handleKeyEvent,
            child: ListenableBuilder(
              listenable: focusNode,
              builder: (context, child) {
                final showFocus = focusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: showFocus
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: child,
                );
              },
              child: result,
            ),
          );
        }

        return ClickableCursor(
          child: GestureDetector(onTap: _toggleExpanded, child: result),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context) {
    final isSmall = widget.small;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: .symmetric(horizontal: isSmall ? 6 : 8, vertical: isSmall ? 0 : 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.all(Radius.circular(isSmall ? 8 : 10)),
      ),
      child: Text(
        '\u00B7\u00B7\u00B7',
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: .bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: isSmall ? 1.5 : 2,
        ),
      ),
    );
  }
}
