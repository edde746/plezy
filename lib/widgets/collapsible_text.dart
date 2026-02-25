import 'package:flutter/material.dart';

class CollapsibleText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final bool small;

  const CollapsibleText({super.key, required this.text, this.maxLines = 4, this.style, this.small = false});

  @override
  State<CollapsibleText> createState() => _CollapsibleTextState();
}

class _CollapsibleTextState extends State<CollapsibleText> {
  bool _expanded = false;

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

        return GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: displayText, style: style),
                if (!_expanded) WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildBadge(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context) {
    final isSmall = widget.small;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8, vertical: isSmall ? 0 : 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.all(Radius.circular(isSmall ? 8 : 10)),
      ),
      child: Text(
        '\u00B7\u00B7\u00B7',
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: isSmall ? 1.5 : 2,
        ),
      ),
    );
  }
}
