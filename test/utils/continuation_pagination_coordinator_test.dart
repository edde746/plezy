import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/continuation_pagination_coordinator.dart';

void main() {
  group('ContinuationPaginationCoordinator', () {
    test('loads multiple pages and advances start indexes', () async {
      final starts = <int>[];
      final loaded = <int>[];
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (start) async {
          starts.add(start);
          final items = start == 2 ? [2, 3] : [4];
          return ContinuationPage(items: items, totalCount: 5, consumedCount: items.length);
        },
        onPage: (page) => loaded.addAll(page.items),
      );

      coordinator.setContinuation(startIndex: 2, totalCount: 5);
      final status = await coordinator.loadRemaining();

      expect(status, ContinuationLoadStatus.completed);
      expect(starts, [2, 4]);
      expect(loaded, [2, 3, 4]);
      expect(coordinator.nextStartIndex, isNull);
      expect(coordinator.totalCount, 5);
    });

    test('rejects a page from a stale generation', () async {
      final pendingPage = Completer<ContinuationPage<int>>();
      final loaded = <int>[];
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (_) => pendingPage.future,
        onPage: (page) => loaded.addAll(page.items),
      );

      coordinator.setContinuation(startIndex: 1, totalCount: 2);
      final staleLoad = coordinator.loadRemaining();
      final freshGeneration = coordinator.runNewGeneration(() async {});
      pendingPage.complete(const ContinuationPage(items: [1], totalCount: 2, consumedCount: 1));

      expect(await staleLoad, ContinuationLoadStatus.stale);
      expect(await freshGeneration, isTrue);
      expect(loaded, isEmpty);
      expect(coordinator.totalCount, isNull);
    });

    test('retry resumes at the failed start index', () async {
      var attempts = 0;
      final loaded = <int>[];
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (start) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary');
          return ContinuationPage(items: [start], totalCount: 2, consumedCount: 1);
        },
        onPage: (page) => loaded.addAll(page.items),
      );

      coordinator.setContinuation(startIndex: 1, totalCount: 2);
      expect(await coordinator.loadRemaining(), ContinuationLoadStatus.failed);
      expect(coordinator.error, isA<StateError>());
      expect(coordinator.nextStartIndex, 1);

      expect(await coordinator.retry(), ContinuationLoadStatus.completed);
      expect(attempts, 2);
      expect(loaded, [1]);
      expect(coordinator.error, isNull);
    });

    test('empty page terminates an incomplete continuation', () async {
      var requests = 0;
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (_) async {
          requests++;
          return const ContinuationPage(items: [], totalCount: 10, consumedCount: 0);
        },
        onPage: (_) => fail('An empty page must not be applied'),
      );

      coordinator.setContinuation(startIndex: 3, totalCount: 10);

      expect(await coordinator.loadRemaining(), ContinuationLoadStatus.completed);
      expect(requests, 1);
      expect(coordinator.hasMore, isFalse);
      expect(coordinator.error, isNull);
    });

    test('duplicate load requests share one in-flight operation', () async {
      final pendingPage = Completer<ContinuationPage<int>>();
      var requests = 0;
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (_) {
          requests++;
          return pendingPage.future;
        },
        onPage: (_) {},
      );

      coordinator.setContinuation(startIndex: 0, totalCount: 1);
      final first = coordinator.loadRemaining();
      final duplicate = coordinator.loadRemaining();

      expect(identical(first, duplicate), isTrue);
      expect(requests, 1);

      pendingPage.complete(const ContinuationPage(items: [0], totalCount: 1, consumedCount: 1));
      expect(await first, ContinuationLoadStatus.completed);
      expect(await duplicate, ContinuationLoadStatus.completed);
    });

    test('partial failure keeps applied pages and retry continues after them', () async {
      final starts = <int>[];
      final loaded = <int>[];
      var failSecondPage = true;
      final coordinator = ContinuationPaginationCoordinator<int>(
        loadPage: (start) async {
          starts.add(start);
          if (start == 2 && failSecondPage) {
            failSecondPage = false;
            throw StateError('second page failed');
          }
          return ContinuationPage(items: [start], totalCount: 3, consumedCount: 1);
        },
        onPage: (page) => loaded.addAll(page.items),
      );

      coordinator.setContinuation(startIndex: 1, totalCount: 3);
      expect(await coordinator.loadRemaining(), ContinuationLoadStatus.failed);
      expect(loaded, [1]);
      expect(coordinator.nextStartIndex, 2);

      expect(await coordinator.retry(), ContinuationLoadStatus.completed);
      expect(starts, [1, 2, 2]);
      expect(loaded, [1, 2]);
    });
  });
}
