import 'package:flutter/widgets.dart';

/// Focuses [firstItemFocusNode] when the owning widget's `suppressAutoFocus`
/// flag flips from true to false — the downloads screen's tab-switch handoff
/// to whichever content widget just became active.
///
/// Consumers implement [firstItemFocusDebugLabel] and [suppressAutoFocusOf],
/// then hand [firstItemFocusNode] to their first focusable item.
mixin UnsuppressFocusFirstMixin<T extends StatefulWidget> on State<T> {
  late final FocusNode firstItemFocusNode = FocusNode(debugLabel: firstItemFocusDebugLabel);

  String get firstItemFocusDebugLabel;

  /// Reads the owning widget's `suppressAutoFocus` flag.
  bool suppressAutoFocusOf(T widget);

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (suppressAutoFocusOf(oldWidget) && !suppressAutoFocusOf(widget)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && firstItemFocusNode.canRequestFocus) {
          firstItemFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    firstItemFocusNode.dispose();
    super.dispose();
  }
}
