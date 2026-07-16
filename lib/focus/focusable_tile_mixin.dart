import 'package:flutter/material.dart';

import '../utils/scroll_utils.dart';
import 'owned_focus_node_binding.dart';

/// Manages the internal/external FocusNode lifecycle for list-tile widgets and
/// auto-scrolls the tile into view when it gains focus.
mixin FocusableTileStateMixin<T extends StatefulWidget> on State<T> {
  final _focusNodeBinding = OwnedFocusNodeBinding();

  FocusNode? get widgetFocusNode;

  FocusNode get effectiveFocusNode => _focusNodeBinding.node;

  void initFocusNode() {
    _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange);
  }

  void updateFocusNode(FocusNode? oldFocusNode) {
    if (oldFocusNode != widgetFocusNode) {
      _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange);
    }
  }

  void disposeFocusNode() {
    _focusNodeBinding.dispose();
  }

  void _onFocusChange() {
    if (effectiveFocusNode.hasFocus) {
      scrollContextToCenter(context);
    }
  }
}
