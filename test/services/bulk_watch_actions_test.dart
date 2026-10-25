import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/bulk_watch_actions.dart';
import 'package:plezy/services/watch_actions.dart';
import '../test_helpers/media_items.dart';

void main() {
  final items = List.generate(3, (i) => testMediaItem(id: '$i'));

  test('runs serially and retains thrown and skipped failures without replay', () async {
    final calls = <String>[];
    final successes = <String>[];
    final pending = Completer<WatchMarkOutcome>();
    final batch = markBulkWatched(
      items,
      mark: (item) async {
        calls.add(item.id);
        if (item.id == '0') return pending.future;
        if (item.id == '1') throw StateError('server unavailable');
        return WatchMarkOutcome.skipped;
      },
      isCurrent: () => true,
      onSuccess: (item, _) => successes.add(item.id),
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['0']);
    pending.complete(WatchMarkOutcome.marked);
    final result = await batch;
    expect(calls, ['0', '1', '2']);
    expect(successes, ['0']);
    expect(result.succeeded, 1);
    expect(result.failed, items.sublist(1));
    expect(result.cancelled, isFalse);
  });

  test('a retired session stops after the pending request without publishing success', () async {
    var current = true;
    final pending = Completer<WatchMarkOutcome>();
    var calls = 0;
    final batch = markBulkWatched(
      items,
      mark: (_) {
        calls++;
        return pending.future;
      },
      isCurrent: () => current,
      onSuccess: (_, _) => fail('retired result must not update the UI'),
    );
    current = false;
    pending.complete(WatchMarkOutcome.marked);
    final result = await batch;
    expect(calls, 1);
    expect(result.cancelled, isTrue);
  });
}
