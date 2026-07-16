import 'package:flutter/material.dart';

import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
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

  /// Hides this widget's expand/collapse label and semantic tap action while
  /// preserving the semantics of the text itself.
  final bool suppressExpandSemantics;

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
    this.suppressExpandSemantics = false,
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
          Widget result = Text(widget.text, style: style);
          final hasFocusBehavior =
              widget.focusNode != null ||
              widget.onNavigateUp != null ||
              widget.onNavigateDown != null ||
              widget.onNavigateLeft != null ||
              widget.onNavigateRight != null;
          if (!hasFocusBehavior) return result;

          result = FocusableWrapper(
            focusNode: widget.focusNode,
            onNavigateUp: widget.onNavigateUp,
            onNavigateDown: widget.onNavigateDown,
            onNavigateLeft: widget.onNavigateLeft,
            onNavigateRight: widget.onNavigateRight,
            descendantsAreFocusable: false,
            disableScale: true,
            useBackgroundFocus: true,
            borderRadius: 8,
            child: result,
          );
          if (widget.skipTraversal) {
            result = ExcludeFocusTraversal(child: result);
          }
          return result;
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

        result = FocusableWrapper(
          focusNode: widget.focusNode,
          onSelect: _toggleExpanded,
          onNavigateUp: widget.onNavigateUp,
          onNavigateDown: widget.onNavigateDown,
          onNavigateLeft: widget.onNavigateLeft,
          onNavigateRight: widget.onNavigateRight,
          semanticLabel: widget.suppressExpandSemantics
              ? null
              : _expanded
              ? t.accessibility.collapseText
              : t.accessibility.expandText,
          descendantsAreFocusable: false,
          disableScale: true,
          useBackgroundFocus: true,
          borderRadius: 8,
          child: result,
        );
        if (widget.skipTraversal) {
          result = ExcludeFocusTraversal(child: result);
        }

        return ClickableCursor(
          child: GestureDetector(
            onTap: _toggleExpanded,
            excludeFromSemantics: widget.suppressExpandSemantics,
            child: result,
          ),
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
