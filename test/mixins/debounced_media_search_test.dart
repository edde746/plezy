import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/mixins/debounced_media_search.dart';

import '../test_helpers/media_items.dart';

class _SearchProbe extends StatefulWidget {
  const _SearchProbe({required this.search});

  final Future<List<MediaItem>> Function(String query) search;

  @override
  State<_SearchProbe> createState() => _SearchProbeState();
}

class _SearchProbeState extends State<_SearchProbe> with DebouncedMediaSearch<_SearchProbe> {
  @override
  Future<List<MediaItem>> performSearchQuery(String query) => widget.search(query);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('reverting to the shown query clears a spinner an earlier keystroke orphaned', (tester) async {
    final pending = <String, Completer<List<MediaItem>>>{};
    await tester.pumpWidget(
      _SearchProbe(
        search: (query) {
          if (query == 'abc') return Future.value([testMediaItem(id: 'abc', title: 'abc')]);
          return (pending[query] = Completer<List<MediaItem>>()).future;
        },
      ),
    );
    final state = tester.state<_SearchProbeState>(find.byType(_SearchProbe));

    state.searchController.text = 'abc';
    await tester.pump(DebouncedMediaSearch.searchDebounceDuration);
    await tester.pump();
    expect(state.lastSearchedQuery, 'abc');
    expect(state.isSearching, isFalse);

    state.searchController.text = 'abcd';
    await tester.pump(DebouncedMediaSearch.searchDebounceDuration);
    expect(state.isSearching, isTrue);

    // The next keystroke kills the 'abcd' pass and re-arms the debounce...
    state.searchController.text = 'abcde';
    await tester.pump();
    // ...and reverting cancels that debounce: no pass is left to end the spinner.
    state.searchController.text = 'abc';
    await tester.pump(const Duration(seconds: 1));

    expect(state.isSearching, isFalse);
    expect(state.searchResults.map((item) => item.id), ['abc']);
    expect(pending.keys, ['abcd']);
  });
}
