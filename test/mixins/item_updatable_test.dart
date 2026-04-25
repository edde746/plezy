import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/item_updatable.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/services/plex_client.dart';

/// Probe that mixes in [ItemUpdatable] without supplying a real [PlexClient].
///
/// The `client` getter throws — these tests deliberately do not exercise the
/// `updateItem` network path (which would require a real or fake [PlexClient],
/// and PlexClient has a private constructor so it cannot be subclassed in
/// tests without modifying production code). Instead, we exercise the
/// `updateItemInLists` contract directly: that's the override-point screens
/// implement, and the only piece [ItemUpdatable] adds on top of a plain
/// `setState` call site.
class _Probe extends StatefulWidget {
  const _Probe({this.onState});
  final void Function(_ProbeState)? onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ItemUpdatable {
  /// In-memory list, mirroring the typical screen pattern: a list keyed by
  /// `ratingKey` whose entries get swapped out by `updateItemInLists`.
  final List<PlexMetadata> items = <PlexMetadata>[];

  /// Records every `updateItemInLists` invocation for assertions.
  final List<({String ratingKey, PlexMetadata metadata})> updates = [];

  @override
  PlexClient get client => throw UnimplementedError(
    'updateItem network path requires a real PlexClient; not testable without '
    'a fake. See test header for the gap.',
  );

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    updates.add((ratingKey: ratingKey, metadata: updatedMetadata));
    final index = items.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      items[index] = updatedMetadata;
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

PlexMetadata _meta(String ratingKey, {String? title}) => PlexMetadata(ratingKey: ratingKey, title: title);

void main() {
  group('ItemUpdatable', () {
    testWidgets('mixin satisfies its own type predicate', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      expect(state, isA<ItemUpdatable>());
    });

    testWidgets('updateItemInLists is called with the forwarded ratingKey/metadata', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      final updated = _meta('42', title: 'Updated');
      state.updateItemInLists('42', updated);

      expect(state.updates, hasLength(1));
      expect(state.updates.first.ratingKey, '42');
      expect(identical(state.updates.first.metadata, updated), isTrue);
    });

    testWidgets('updateItemInLists swaps a matching entry by ratingKey', (tester) async {
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

    testWidgets('updateItemInLists is a no-op for an unknown ratingKey', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      state.items
        ..add(_meta('1'))
        ..add(_meta('2'));

      state.updateItemInLists('999', _meta('999'));

      expect(state.items.map((i) => i.ratingKey).toList(), ['1', '2']);
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

      expect(state.updates.map((u) => u.ratingKey).toList(), ['1', '2', '1']);
      expect(state.items[0].title, 'A2');
      expect(state.items[1].title, 'B');
    });
  });
}
