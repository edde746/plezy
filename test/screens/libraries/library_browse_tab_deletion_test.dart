import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/deletion_aware.dart';
import 'package:plezy/utils/deletion_notifier.dart';

/// Regression coverage for the bug where "Delete all downloads" on a show
/// silently removed the show from the library browse grid.
///
/// The library browse view is server-backed: a local download deletion leaves
/// the server data intact, so `DeletionEvent.isDownloadOnly` must short-circuit
/// `onDeletionEvent`. Without that guard, the show vanished from browse even
/// though search (which hits the server) still found it.
///
/// We assert the behaviour twice:
///
/// 1. **Behavioural** — a stub widget that uses the same `DeletionAware` mixin
///    and the same guard pattern as `_LibraryBrowseTabState.onDeletionEvent`
///    receives events from the live `DeletionNotifier` and demonstrates that
///    download-only events stop at the guard. This pins the *pattern* the tab
///    follows.
///
/// 2. **Source-presence** — we read the actual library_browse_tab source and
///    assert the guard line is still there, so a future refactor of the
///    handler can't silently drop it.
void main() {
  testWidgets('download-only deletion events stop at the isDownloadOnly guard', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _GuardedDeletionStub()));
    await tester.pump();

    final state = tester.state<_GuardedDeletionStubState>(find.byType(_GuardedDeletionStub));

    DeletionNotifier().notify(
      DeletionEvent(
        itemId: 'show-download-only',
        serverId: 'srv',
        parentChain: const [],
        mediaType: 'show',
        isDownloadOnly: true,
      ),
    );
    await tester.pump();

    expect(state.handled, isEmpty, reason: 'download-only events must short-circuit before mutating loaded items');

    DeletionNotifier().notify(
      DeletionEvent(itemId: 'show-server-side', serverId: 'srv', parentChain: const [], mediaType: 'show'),
    );
    await tester.pump();

    expect(state.handled.map((e) => e.itemId), [
      'show-server-side',
    ], reason: 'genuine server-side deletions must still flow through');
  });

  test('library_browse_tab onDeletionEvent still guards against isDownloadOnly', () {
    final source = File('lib/screens/libraries/tabs/library_browse_tab.dart').readAsStringSync();
    expect(
      source,
      contains('event.isDownloadOnly'),
      reason:
          'onDeletionEvent must short-circuit on download-only events — see '
          'DeletionEvent.isDownloadOnly. Bug regression: deleting all downloads '
          'for a show silently removed the show from the library browse grid.',
    );
  });
}

class _GuardedDeletionStub extends StatefulWidget {
  const _GuardedDeletionStub();

  @override
  State<_GuardedDeletionStub> createState() => _GuardedDeletionStubState();
}

class _GuardedDeletionStubState extends State<_GuardedDeletionStub> with DeletionAware {
  /// Events that made it past the guard. The guard mirrors the one in
  /// `_LibraryBrowseTabState.onDeletionEvent` — keep them in sync.
  final List<DeletionEvent> handled = [];

  // null = receive every event, so the guard inside onDeletionEvent is what
  // we're actually testing (not the upstream itemId filter).
  @override
  Set<String>? get deletionIds => null;

  @override
  void onDeletionEvent(DeletionEvent event) {
    if (event.isDownloadOnly) return;
    handled.add(event);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
