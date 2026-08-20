import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/owned_focus_node_binding.dart';

void main() {
  test('switching external nodes detaches the previous listener without disposing it', () {
    final first = _TrackingFocusNode();
    final second = _TrackingFocusNode();
    void listener() {}
    final binding = OwnedFocusNodeBinding();

    binding.bind(externalNode: first, listener: listener);
    binding.bind(externalNode: second, listener: listener);

    expect(first.addedListeners, 1);
    expect(first.removedListeners, 1);
    expect(first.disposeCalls, 0);
    expect(second.addedListeners, 1);

    binding.dispose();
    expect(second.removedListeners, 1);
    expect(second.disposeCalls, 0);
    first.dispose();
    second.dispose();
  });

  test('switching from an internal node disposes the owned node', () {
    late _TrackingFocusNode internal;
    final external = _TrackingFocusNode();
    final binding = OwnedFocusNodeBinding.withFactory(
      (debugLabel) => internal = _TrackingFocusNode(debugLabel: debugLabel),
    );

    binding.bind(externalNode: null, listener: () {}, debugLabel: 'internal');
    binding.bind(externalNode: external, listener: () {});

    expect(internal.debugLabel, 'internal');
    expect(internal.removedListeners, 1);
    expect(internal.disposeCalls, 1);
    expect(external.disposeCalls, 0);

    binding.dispose();
    external.dispose();
  });
}

class _TrackingFocusNode extends FocusNode {
  _TrackingFocusNode({super.debugLabel});

  int addedListeners = 0;
  int removedListeners = 0;
  int disposeCalls = 0;

  @override
  void addListener(VoidCallback listener) {
    addedListeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removedListeners++;
    super.removeListener(listener);
  }

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}
