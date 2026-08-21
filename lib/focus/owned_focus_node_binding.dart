import 'package:flutter/widgets.dart';

typedef FocusNodeFactory = FocusNode Function(String? debugLabel);

FocusNode _createFocusNode(String? debugLabel) => FocusNode(debugLabel: debugLabel);

/// Owns either a caller-provided focus node or an internally-created one and
/// keeps one listener attached to exactly the active node.
class OwnedFocusNodeBinding {
  OwnedFocusNodeBinding() : _createNode = _createFocusNode;

  OwnedFocusNodeBinding.withFactory(this._createNode);

  final FocusNodeFactory _createNode;
  FocusNode? _node;
  VoidCallback? _listener;
  bool _ownsNode = false;

  FocusNode get node => _node!;

  void bind({required FocusNode? externalNode, VoidCallback? listener, String? debugLabel}) {
    dispose();
    _node = externalNode ?? _createNode(debugLabel);
    _ownsNode = externalNode == null;
    _listener = listener;
    if (listener != null) _node!.addListener(listener);
  }

  void dispose() {
    final node = _node;
    final listener = _listener;
    if (node == null) return;
    if (listener != null) node.removeListener(listener);
    if (_ownsNode) node.dispose();
    _node = null;
    _listener = null;
    _ownsNode = false;
  }
}
