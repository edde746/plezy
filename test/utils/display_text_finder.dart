import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/presentation_formats.dart';

/// Match the visible label, allowing the bidi isolation used for server titles.
/// Still requires the complete string; a substring cannot satisfy the assertion.
Finder findDisplayText(String text) => find.byWidgetPredicate((widget) {
  if (widget is! Text) return false;
  final value = widget.data ?? widget.textSpan?.toPlainText();
  return value == text || value == isolateDisplayText(text);
});

Finder findWidgetWithDisplayText(Type type, String text) =>
    find.ancestor(of: findDisplayText(text), matching: find.byType(type));
