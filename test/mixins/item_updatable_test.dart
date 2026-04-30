import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/mixins/item_updatable.dart';

/// Probe that mixes in [ItemUpdatable]. These tests exercise the
/// `updateItemInLists` contract directly — the override-point screens
/// implement and the only piece [ItemUpdatable] adds on top of a plain
/// `setState` call site. The network path (`updateItem`) keys off
/// `itemServerId`; left null here so it short-circuits.
class _Probe extends StatefulWidget {
  const _Probe({this.onState});
  final void Function(_ProbeState)? onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ItemUpdatable {
  /// In-memory list, mirroring the typical screen pattern: a list keyed by
  /// `id` whose entries get swapped out by `updateItemInLists`.
  final List<MediaItem> items = <MediaItem>[];

  /// Records every `updateItemInLists` invocation for assertions.
  final List<({String itemId, MediaItem metadata})> updates = [];

  @override
  void updateItemInLists(String itemId, MediaItem updatedItem) {
    updates.add((itemId: itemId, metadata: updatedItem));
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      items[index] = updatedItem;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

MediaItem _meta(String id, {String? title}) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie, title: title);

void main() {
  group('ItemUpdatable', () {
    testWidgets('mixin satisfies its own type predicate', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      expect(state, isA<ItemUpdatable>());
    });

    testWidgets('updateItemInLists is called with the forwarded itemId/metadata', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      final updated = _meta('42', title: 'Updated');
      state.updateItemInLists('42', updated);

      expect(state.updates, hasLength(1));
      expect(state.updates.first.itemId, '42');
      expect(identical(state.updates.first.metadata, updated), isTrue);
    });

    testWidgets('updateItemInLists swaps a matching entry by id', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      state.items
        ..add(_meta('1', title: 'One'))
        ..add(_meta('2', title: 'Two'))
        ..add(_meta('3', title: 'Three'));

      final replacement = _meta('2', title: 'Two (refreshed)');
      state.updateItemInLists('2', replacement);

      expect(state.items.map((i) => i.title).toList(), ['One', 'Two (refreshed)', 'Three']);
      expect(identical(state.items[1], replacement), isTrue);
    });

    testWidgets('updateItemInLists is a no-op for an unknown id', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      state.items
        ..add(_meta('1'))
        ..add(_meta('2'));

      state.updateItemInLists('999', _meta('999'));

      expect(state.items.map((i) => i.id).toList(), ['1', '2']);
      // Still recorded — the contract is "we received this update", regardless
      // of whether the screen's list contained the key.
      expect(state.updates, hasLength(1));
    });

    testWidgets('multiple updates accumulate in the screen-defined list', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      state.items.addAll([_meta('1'), _meta('2')]);

      state.updateItemInLists('1', _meta('1', title: 'A'));
      state.updateItemInLists('2', _meta('2', title: 'B'));
      state.updateItemInLists('1', _meta('1', title: 'A2'));

      expect(state.updates.map((u) => u.itemId).toList(), ['1', '2', '1']);
      expect(state.items[0].title, 'A2');
      expect(state.items[1].title, 'B');
    });
  });
}
