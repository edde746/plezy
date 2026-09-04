import 'dart:collection';

import 'package:flutter/painting.dart';

typedef _Key = (String, TextStyle, TextScaler, TextDirection);

final LinkedHashMap<_Key, Size> _sizes = LinkedHashMap<_Key, Size>();
const int _maxEntries = 512;

/// Size of [text] laid out on one unconstrained line, memoized per
/// (text, style, scaler, direction).
///
/// Metadata strips measure every field before building it so they can shed
/// parts that will not fit (#1893), and fitted titles need a line height to
/// know whether a box can overflow at all; each such measurement shapes a
/// string the render tree is about to shape again. Shaping dominates the TV
/// spotlight's info swap on low-end boxes, and the measured strings repeat
/// heavily — separators, "Movie", "TV-14", years, runtimes, "88%" — so a
/// small cache turns the measuring pass into hash lookups. Bounded and
/// insertion-ordered: the oldest entry goes first.
Size cachedSingleLineTextSize(
  String text, {
  required TextStyle style,
  required TextScaler textScaler,
  required TextDirection textDirection,
}) {
  final key = (text, style, textScaler, textDirection);
  final cached = _sizes[key];
  if (cached != null) return cached;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  if (_sizes.length >= _maxEntries) _sizes.remove(_sizes.keys.first);
  _sizes[key] = size;
  return size;
}
