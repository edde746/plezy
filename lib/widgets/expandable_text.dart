import 'package:flutter/material.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';

/// A widget that displays text with a "more" button if it exceeds a certain number of lines.
/// When "more" is tapped, opens a full-screen dialog showing the complete text.
class ExpandableText extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 10,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a TextPainter to measure if text exceeds maxLines
        final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        final exceedsMaxLines = textPainter.didExceedMaxLines;

        if (!exceedsMaxLines) {
          // Text fits within maxLines, show it normally
          return Text(
            text,
            style: textStyle,
            textAlign: textAlign,
          );
        }

        // Text exceeds maxLines, show truncated version with "more" button
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: textStyle,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullTextDialog(context),
              child: Text(
                t.common.more,
                style: textStyle?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => handleBackKeyNavigation(dialogContext, event),
          child: Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.common.description,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        text,
                        style: style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                        textAlign: textAlign,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

