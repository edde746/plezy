import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/mixins/paginated_item_loader.dart';
import 'package:plezy/mixins/standard_paginated_view.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import '../test_helpers/media_items.dart';

/// Test probe wired with a controllable `fetchPage` so individual tests can
/// stage successes, failures, and slow responses.
class _PaginatedProbe extends StatefulWidget {
  const _PaginatedProbe({required this.fetcher, this.onState, this.onPageLoadedHook});

  /// Returns a future for the requested `(start, size)` slice. Tests stage
  /// futures via this fetcher to control timing and error paths.
  final Future<LibraryPage<MediaItem>> Function(int start, int size, AbortController? abort) fetcher;

  final void Function(_PaginatedProbeState)? onState;
  final void Function(int start, List<MediaItem> items)? onPageLoadedHook;

  @override
  State<_PaginatedProbe> createState() => _PaginatedProbeState();
}

class _PaginatedProbeState extends State<_PaginatedProbe>
    with PaginatedItemLoader<MediaItem, _PaginatedProbe>, StandardPaginatedView<MediaItem, _PaginatedProbe> {
  int fetchCalls = 0;
  final List<({int start, int size})> fetchArgs = [];

  /// View fields required by [StandardPaginatedView], mirroring the
  /// `items`/`isLoading`/`errorMessage` trio the real screens expose.
  @override
  List<MediaItem> items = [];
  @override
  bool isLoading = false;
  @override
  String? errorMessage;

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    fetchCalls++;
    fetchArgs.add((start: start, size: size));
    return widget.fetcher(start, size, abort);
  }

  @override
  void onPageLoaded(int start, List<MediaItem> items) {
    widget.onPageLoadedHook?.call(start, items);
  }

  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  void dispose() {
    disposePagination();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

MediaItem _meta(int i) => testMediaItem(id: 'k$i', backend: MediaBackend.plex, kind: MediaKind.movie, title: 't$i');

LibraryPage<MediaItem> _result({required int start, required int size, required int totalSize}) {
  return LibraryPage<MediaItem>(
    items: List<MediaItem>.generate(size, (i) => _meta(start + i)),
    totalCount: totalSize,
    offset: start,
  );
}

void main() {
  group('PaginatedItemLoader', () {
    testWidgets('loadInitialPage populates loadedItems and totalSize', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 42),
        ),
      );

      final result = await state.loadInitialPage(10);
      await tester.pump();

      expect(state.fetchCalls, 1);
      expect(state.fetchArgs.first, (start: 0, size: 10));
      expect(state.totalSize, 42);
      expect(state.loadedItems.length, 10);
      expect(state.loadedItems[0]?.id, 'k0');
      expect(state.loadedItems[9]?.id, 'k9');
      expect(result.totalCount, 42);
    });

    testWidgets('onPageLoaded fires after a successful initial page', (tester) async {
      late _PaginatedProbeState state;
      final hooked = <(int, int)>[]; // (start, count)
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 5),
          onPageLoadedHook: (start, items) => hooked.add((start, items.length)),
        ),
      );

      await state.loadInitialPage(5);
      await tester.pump();

      expect(hooked, [(0, 5)]);
    });

    testWidgets('loadStandardPaginatedItems resets view state, publishes items, and fires onLoaded', (tester) async {
      late _PaginatedProbeState state;
      (int, int)? counts;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 7),
        ),
      );

      // Stale view state from a previous load must be cleared by the reset.
      state.items = [_meta(99)];
      state.errorMessage = 'stale error';

      await state.loadStandardPaginatedItems(
        pageSize: 3,
        errorMessageFor: (error, stackTrace) => fail('unexpected error: $error'),
        onLoaded: (loaded, total) => counts = (loaded, total),
      );
      await tester.pump();

      expect(state.items.map((item) => item.id), ['k0', 'k1', 'k2']);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(counts, (3, 7));
    });

    testWidgets('loadStandardPaginatedItems applies one error transaction', (tester) async {
      late _PaginatedProbeState state;
      Object? reportedError;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => throw StateError('failed page'),
        ),
      );

      await state.loadStandardPaginatedItems(
        pageSize: 3,
        errorMessageFor: (error, stackTrace) {
          reportedError = error;
          return 'could not load';
        },
        onLoaded: (_, _) => fail('items must not be applied'),
      );
      await tester.pump();

      expect(reportedError, isA<StateError>());
      expect(state.errorMessage, 'could not load');
      expect(state.isLoading, isFalse);
      expect(state.items, isEmpty);
    });

    testWidgets('totalSize == 0 means no more pages — ensureRangeLoaded is a no-op', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => const LibraryPage<MediaItem>(items: [], totalCount: 0),
        ),
      );

      await state.loadInitialPage(20);
      await tester.pump();

      expect(state.totalSize, 0);
      expect(state.loadedItems, isEmpty);

      // Subsequent range loads no-op when there's nothing on the server.
      await state.ensureRangeLoaded(0, 20);
      expect(state.fetchCalls, 1);

      state.prefetchAhead(0, 20);
      expect(state.fetchCalls, 1);

      state.ensureIndexLoaded(0);
      expect(state.fetchCalls, 1);
    });

    testWidgets('ensureRangeLoaded backfills missing indices with buffer clamping', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 50),
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();
      expect(state.loadedItems.length, 10);
      final initialFetches = state.fetchCalls;

      // Visible range [10, 20) — ensureRangeLoaded fetches the unloaded slice
      // out to totalSize (since totalSize < firstIndex+visible+buffer).
      await state.ensureRangeLoaded(10, 10);
      await tester.pumpAndSettle();

      expect(state.fetchCalls, greaterThan(initialFetches));
      // After settling, indices 10..49 should all be loaded.
      for (var i = 10; i < 50; i++) {
        expect(state.loadedItems.containsKey(i), isTrue, reason: 'expected index $i loaded');
      }
    });

    testWidgets('ensureIndexLoaded fetches the page containing the requested index', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 1000),
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();

      // pageSize=200, index=350 → page starts at 200.
      state.ensureIndexLoaded(350, pageSize: 200);
      await tester.pumpAndSettle();

      expect(state.fetchArgs.length, greaterThanOrEqualTo(2));
      final pageFetch = state.fetchArgs.last;
      expect(pageFetch.start, 200);
      expect(state.loadedItems.containsKey(350), isTrue);
    });

    testWidgets('failed fetch schedules a retry and the retry eventually succeeds', (tester) async {
      late _PaginatedProbeState state;
      var rangeAttempt = 0;

      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async {
            if (start == 0) {
              return _result(start: 0, size: size, totalSize: 400);
            }
            rangeAttempt++;
            if (rangeAttempt == 1) {
              // First range fetch fails — triggers retry path.
              throw MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'boom');
            }
            return _result(start: start, size: size, totalSize: 400);
          },
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();
      expect(state.totalSize, 400);

      // ensureIndexLoaded triggers a fetch that fails, which schedules a retry
      // via Timer (delay = 500 * 2 = 1000ms for first retry).
      state.ensureIndexLoaded(220, pageSize: 200);

      // Drain the failed Future, then advance past the retry timer's 1s delay
      // so the timer fires and re-invokes ensureIndexLoaded.
      await tester.pump();
      expect(state.paginationError, isA<MediaServerHttpException>());
      expect(state.isPaginationLoading, isFalse);
      await tester.pump(const Duration(milliseconds: 1100));
      // Drain the retry's Future.
      await tester.pump();
      expect(state.paginationError, isNull);
      expect(state.isPaginationLoading, isFalse);

      expect(state.loadedItems.containsKey(220), isTrue);
      expect(rangeAttempt, greaterThanOrEqualTo(2)); // failed + retry
    });

    testWidgets('cancelled fetch (MediaServerHttpErrorType.cancelled) does not schedule a retry', (tester) async {
      late _PaginatedProbeState state;
      var sawCancellation = false;

      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async {
            if (start == 0 && !sawCancellation) {
              return _result(start: 0, size: size, totalSize: 400);
            }
            sawCancellation = true;
            throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'aborted');
          },
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();
      final beforeFetches = state.fetchCalls;

      state.ensureIndexLoaded(220, pageSize: 200);
      // Pump just enough for the future to throw; do NOT pumpAndSettle past
      // the retry timer, since we expect no retry to be scheduled.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Wait past the would-be 1s retry delay; if a retry were scheduled,
      // we'd see another fetch attempt.
      await tester.pump(const Duration(milliseconds: 1500));

      expect(state.fetchCalls, beforeFetches + 1);
    });

    testWidgets('dispose during in-flight load is a no-op (no setState on unmounted)', (tester) async {
      late _PaginatedProbeState state;
      final completer = Completer<LibraryPage<MediaItem>>();

      await tester.pumpWidget(
        _PaginatedProbe(onState: (s) => state = s, fetcher: (start, size, abort) => completer.future),
      );

      // Kick off an initial load that will not complete until we say so.
      final pending = state.loadInitialPage(10);

      // Unmount the widget while the future is still pending.
      await tester.pumpWidget(const SizedBox.shrink());

      // Now resolve the future — the mixin should detect the generation bump
      // and not touch state.
      completer.complete(_result(start: 0, size: 10, totalSize: 999));
      await pending;
      await tester.pump();

      // State is unmounted; loadedItems should be empty (or at least the
      // in-flight fetch should not have populated state). totalSize was reset
      // to 0 by disposePagination() (via _requestId bump and clear).
      expect(state.mounted, isFalse);
      expect(state.totalSize, 0);
      expect(state.loadedItems, isEmpty);
    });

    testWidgets('removeLoadedItemAndShift removes index and shifts higher entries down', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 5),
        ),
      );

      await state.loadInitialPage(5);
      await tester.pump();
      expect(state.loadedItems.length, 5);
      expect(state.totalSize, 5);

      // Remove index 2 — items at 3 and 4 should shift down to 2 and 3.
      state.removeLoadedItemAndShift(2);

      expect(state.totalSize, 4);
      expect(state.loadedItems.length, 4);
      expect(state.loadedItems[0]?.id, 'k0');
      expect(state.loadedItems[1]?.id, 'k1');
      expect(state.loadedItems[2]?.id, 'k3'); // shifted from index 3
      expect(state.loadedItems[3]?.id, 'k4'); // shifted from index 4
      expect(state.loadedItems.containsKey(4), isFalse);
    });

    testWidgets('repopulateLoadedRange refetches the loaded span in place and reports the anchor', (tester) async {
      late _PaginatedProbeState state;
      // The server inserts one item at the top after the initial load: every
      // id shifts up one slot on the repopulating fetch.
      var inserted = false;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => inserted
              ? LibraryPage<MediaItem>(
                  items: [_meta(99), ...List<MediaItem>.generate(size - 1, (i) => _meta(start + i))],
                  totalCount: 41,
                  offset: start,
                )
              : _result(start: start, size: size, totalSize: 40),
        ),
      );
      await state.loadInitialPage(10);
      await tester.pump();

      inserted = true;
      final result = await state.repopulateLoadedRange(idOf: (item) => item.id, anchorId: 'k3');
      expect(result, isNotNull);
      expect(result!.anchorOldIndex, 3);
      expect(result.anchorNewIndex, 4, reason: 'the anchor moved down one slot');
      expect(state.totalSize, 41, reason: 'the span adopts the server count');
      expect(state.loadedItems[0]?.id, 'k99');
      expect(state.loadedItems[1]?.id, 'k0');
    });

    testWidgets('repopulateLoadedRange clamps a disjoint sparse span to maxSpan around the window center', (
      tester,
    ) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 10000),
        ),
      );
      // Initial pages plus an alpha-jump target: clusters at 0..19 and
      // 9000..9019 whose naive span would be a 9020-item request.
      await state.loadInitialPage(20);
      await tester.pump();
      state.ensureIndexLoaded(9000, pageSize: 20);
      await tester.pumpAndSettle();
      expect(state.loadedItems.containsKey(0), isTrue);
      expect(state.loadedItems.containsKey(9000), isTrue);

      state.fetchArgs.clear();
      final result = await state.repopulateLoadedRange(idOf: (item) => item.id, maxSpan: 100, windowCenter: 9010);
      expect(result, isNotNull);
      final request = state.fetchArgs.single;
      expect(request.size, lessThanOrEqualTo(100));
      expect(state.loadedItems.containsKey(0), isFalse, reason: 'entries outside the window degrade to unloaded slots');
      expect(state.loadedItems.containsKey(9010), isTrue);
    });

    testWidgets('removeLoadedItemAndShift decrements totalSize even for evicted indices', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 100),
        ),
      );

      await state.loadInitialPage(5);
      await tester.pump();
      expect(state.totalSize, 100);

      // Index 50 is not loaded, but the "deleted on server" invariant still
      // requires totalSize to drop by one.
      state.removeLoadedItemAndShift(50);
      expect(state.totalSize, 99);
      expect(state.loadedItems.length, 5);
    });

    testWidgets('removeLoadedItemAndShift clamps totalSize to 0 (never negative)', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 0),
        ),
      );

      state.removeLoadedItemAndShift(0);
      expect(state.totalSize, 0);
    });

    testWidgets('evictDistantItems is a no-op below the threshold', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 200),
        ),
      );

      await state.loadInitialPage(100);
      await tester.pump();

      state.evictDistantItems(50, maxKeep: 50, threshold: 600);
      // 100 entries < threshold of 600 — eviction skipped.
      expect(state.loadedItems.length, 100);
    });

    testWidgets('evictDistantItems trims to a window around centerIndex', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 1000),
        ),
      );

      await state.loadInitialPage(700);
      await tester.pump();
      expect(state.loadedItems.length, 700);

      state.evictDistantItems(300, maxKeep: 200, threshold: 600);

      // halfKeep = 100 → keeps [200, 400]; everything outside is evicted.
      for (final index in state.loadedItems.keys) {
        expect(index, greaterThanOrEqualTo(200));
        expect(index, lessThanOrEqualTo(400));
      }
      // Indices that were outside the window are gone.
      expect(state.loadedItems.containsKey(0), isFalse);
      expect(state.loadedItems.containsKey(199), isFalse);
      expect(state.loadedItems.containsKey(401), isFalse);
      expect(state.loadedItems.containsKey(699), isFalse);
    });

    testWidgets('clearPendingRanges allows another fetch attempt without dedupe', (tester) async {
      late _PaginatedProbeState state;
      final completers = <Completer<LibraryPage<MediaItem>>>[];

      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) {
            // First call (initial page) resolves immediately; later calls park.
            if (start == 0 && completers.isEmpty) {
              return Future.value(_result(start: 0, size: size, totalSize: 400));
            }
            final c = Completer<LibraryPage<MediaItem>>();
            completers.add(c);
            return c.future;
          },
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();

      // Trigger an in-flight range fetch — its indices are now "loading".
      state.ensureIndexLoaded(220, pageSize: 200);
      await tester.pump();
      expect(completers, hasLength(1));
      final fetchesAfterFirst = state.fetchCalls;

      // While the first fetch is still in-flight, a second ensureIndexLoaded
      // for the same page is deduped (no new fetch).
      state.ensureIndexLoaded(220, pageSize: 200);
      await tester.pump();
      expect(state.fetchCalls, fetchesAfterFirst);

      // After clearPendingRanges, the dedupe guard is gone — but the first
      // fetch is still in-flight; the second call now schedules a new fetch.
      state.clearPendingRanges();
      state.ensureIndexLoaded(220, pageSize: 200);
      await tester.pump();
      expect(state.fetchCalls, fetchesAfterFirst + 1);

      // Resolve both in-flight fetches so the test ends cleanly.
      for (final c in completers) {
        if (!c.isCompleted) c.complete(_result(start: 200, size: 200, totalSize: 400));
      }
      await tester.pumpAndSettle();
    });

    testWidgets('resetPaginationState clears items, totalSize, and bumps generation', (tester) async {
      late _PaginatedProbeState state;
      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) async => _result(start: start, size: size, totalSize: 50),
        ),
      );

      await state.loadInitialPage(10);
      await tester.pump();
      expect(state.totalSize, 50);
      expect(state.loadedItems.length, 10);

      // Production callers wrap this in setState; the mixin itself is sync.
      // ignore: invalid_use_of_protected_member
      state.setState(() => state.resetPaginationState());

      expect(state.totalSize, 0);
      expect(state.loadedItems, isEmpty);
    });

    testWidgets('a stale in-flight fetch from before resetPaginationState is dropped', (tester) async {
      late _PaginatedProbeState state;
      Completer<LibraryPage<MediaItem>>? staleFetch;

      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) {
            if (staleFetch == null) {
              staleFetch = Completer<LibraryPage<MediaItem>>();
              return staleFetch!.future;
            }
            return Future.value(_result(start: start, size: size, totalSize: 99));
          },
        ),
      );

      // Kick off the initial load — its future is `staleFetch` and won't
      // resolve until we say so.
      final firstLoad = state.loadInitialPageWithStatus(10);

      // Reset state mid-flight; the next loadInitialPage should be authoritative.
      // ignore: invalid_use_of_protected_member
      state.setState(() => state.resetPaginationState());

      // Resolve the *stale* future — the generation has been bumped, so this
      // result must be discarded.
      staleFetch!.complete(_result(start: 0, size: 10, totalSize: 50));
      final staleResult = await firstLoad;
      await tester.pump();

      expect(staleResult.applied, isFalse);
      expect(state.totalSize, 0); // stale result was dropped
      expect(state.loadedItems, isEmpty);

      // Now run a fresh load that resolves with totalSize=99.
      final freshResult = await state.loadInitialPageWithStatus(10);
      await tester.pump();
      expect(freshResult.applied, isTrue);
      expect(state.totalSize, 99);
    });

    testWidgets('a stale in-flight failure from before resetPaginationState is dropped', (tester) async {
      late _PaginatedProbeState state;
      Completer<LibraryPage<MediaItem>>? staleFetch;

      await tester.pumpWidget(
        _PaginatedProbe(
          onState: (s) => state = s,
          fetcher: (start, size, abort) {
            if (staleFetch == null) {
              staleFetch = Completer<LibraryPage<MediaItem>>();
              return staleFetch!.future;
            }
            return Future.value(_result(start: start, size: size, totalSize: 99));
          },
        ),
      );

      final firstLoad = state.loadInitialPageWithStatus(10);

      // ignore: invalid_use_of_protected_member
      state.setState(() => state.resetPaginationState());

      staleFetch!.completeError(MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'aborted'));
      final staleResult = await firstLoad;
      await tester.pump();

      expect(staleResult.applied, isFalse);
      expect(state.totalSize, 0);
      expect(state.loadedItems, isEmpty);

      final freshResult = await state.loadInitialPageWithStatus(10);
      await tester.pump();
      expect(freshResult.applied, isTrue);
      expect(state.totalSize, 99);
    });
  });
}
