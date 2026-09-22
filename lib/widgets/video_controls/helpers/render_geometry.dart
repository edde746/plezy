import 'package:flutter/widgets.dart';

/// Size of the render box behind [context], or [Size.zero] when it has not
/// been laid out yet.
///
/// The transport controls measure themselves from gesture callbacks, which can
/// fire against a context whose element is between builds.
Size renderBoxSizeOf(BuildContext context) {
  final renderObject = context.findRenderObject();
  return renderObject is RenderBox ? renderObject.size : Size.zero;
}
