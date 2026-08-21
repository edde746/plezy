import 'package:flutter/material.dart';

import '../utils/scroll_utils.dart';
import 'input_mode_tracker.dart';
import 'owned_focus_node_binding.dart';

/// Manages the internal/external FocusNode lifecycle for list-tile widgets and
/// auto-scrolls the tile into view when it gains focus.
mixin FocusableTileStateMixin<T extends StatefulWidget> on State<T> {
  final _focusNodeBinding = OwnedFocusNodeBinding();
  FocusNode? _boundExternalNode;

  FocusNode? get widgetFocusNode;

  FocusNode get effectiveFocusNode => _focusNodeBinding.node;

  @override
  void initState() {
    super.initState();
    _bindFocusNode();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_boundExternalNode != widgetFocusNode) {
      _bindFocusNode();
    }
  }

  @override
  void dispose() {
    _focusNodeBinding.dispose();
    super.dispose();
  }

  void _bindFocusNode() {
    _boundExternalNode = widgetFocusNode;
    _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange);
  }

  void _onFocusChange() {
    // Reveal on focus is keyboard/D-pad-only: pointer-mode focus is
    // programmatic and invisible, so revealing it would yank the scroll view
    // (issue #2031).
    if (effectiveFocusNode.hasFocus && InputModeTracker.currentMode == InputMode.keyboard) {
      scrollContextToCenter(context);
    }
  }
}
