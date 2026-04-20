import 'package:flutter/material.dart';

import '../utils/scroll_utils.dart';

/// Manages the internal/external FocusNode lifecycle for list-tile widgets and
/// auto-scrolls the tile into view when it gains focus.
mixin FocusableTileStateMixin<T extends StatefulWidget> on State<T> {
  late FocusNode _effectiveFocusNode;
  bool _ownsNode = false;

  FocusNode? get widgetFocusNode;

  FocusNode get effectiveFocusNode => _effectiveFocusNode;

  void initFocusNode() {
    if (widgetFocusNode != null) {
      _effectiveFocusNode = widgetFocusNode!;
      _ownsNode = false;
    } else {
      _effectiveFocusNode = FocusNode();
      _ownsNode = true;
    }
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void updateFocusNode(FocusNode? oldFocusNode) {
    if (oldFocusNode != widgetFocusNode) {
      disposeFocusNode();
      initFocusNode();
    }
  }

  void disposeFocusNode() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    if (_ownsNode) _effectiveFocusNode.dispose();
  }

  void _onFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      scrollContextToCenter(context);
    }
  }
}
