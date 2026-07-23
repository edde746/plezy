import 'dart:async';
import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/endpoint_race.dart';

typedef _Result = ({String url, bool ok});

void main() {
  const headStart = Duration(milliseconds: 60);

  Stream<EndpointRaceSelection<String, _Result>> race({
    required List<String> candidates,
    String? preferred,
    required Future<_Result> Function(String url) probe,
    Future<_Result> Function(String url)? measure,
    String? Function(Map<String, _Result> results)? selectBest,
  }) {
    return raceEndpointCandidates<String, _Result>(
      label: 'test',
      candidates: candidates,
      urlOf: (c) => c,
      preferredUrl: preferred,
      probe: (c, _) => probe(c),
      measure: measure ?? (c) async => (url: c, ok: false),
      isSuccess: (r) => r.ok,
      selectBestCandidate: selectBest ?? (results) => results.keys.first,
      preferredTimeout: const Duration(milliseconds: 500),
      preferredHeadStart: headStart,
      raceTimeout: const Duration(milliseconds: 500),
    );
  }

  test('healthy cached endpoint wins within the head start without racing', () {
    fakeAsync((async) {
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];
      late Completer<_Result> cachedGate;

      race(
        candidates: ['a', 'cached'],
        preferred: 'cached',
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          final gate = Completer<_Result>();
          if (url == 'cached') cachedGate = gate;
          return gate.future;
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      expect(probeCounts, {'cached': 1});
      cachedGate.complete((url: 'cached', ok: true));
      async.flushMicrotasks();

      expect(selections.first.phase, EndpointRacePhase.first);
      expect(selections.first.candidate, 'cached');
      expect(selections.first.fromPreferred, isTrue);
      expect(probeCounts.containsKey('a'), isFalse);

      async.elapse(headStart);
      async.flushMicrotasks();
    });
  });

  test('stale-slow cached endpoint overlaps the race instead of serially blocking it', () {
    fakeAsync((async) {
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];
      late Completer<_Result> cachedGate;
      late Completer<_Result> fastGate;

      race(
        candidates: ['fast', 'cached'],
        preferred: 'cached',
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          final gate = Completer<_Result>();
          if (url == 'cached') {
            cachedGate = gate;
          } else {
            fastGate = gate;
          }
          return gate.future;
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      expect(probeCounts, {'cached': 1});
      async.elapse(headStart - const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(probeCounts, {'cached': 1});

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(probeCounts, {'cached': 1, 'fast': 1});

      fastGate.complete((url: 'fast', ok: true));
      async.flushMicrotasks();
      expect(selections.first.phase, EndpointRacePhase.first);
      expect(selections.first.candidate, 'fast');
      expect(selections.first.fromPreferred, isFalse);
      expect(probeCounts['cached'], 1);

      cachedGate.complete((url: 'cached', ok: false));
      async.flushMicrotasks();
    });
  });

  test('cached endpoint that answers after the head start still wins when first', () {
    fakeAsync((async) {
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];
      late Completer<_Result> cachedGate;
      late Completer<_Result> slowGate;

      race(
        candidates: ['slow', 'cached'],
        preferred: 'cached',
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          final gate = Completer<_Result>();
          if (url == 'cached') {
            cachedGate = gate;
          } else {
            slowGate = gate;
          }
          return gate.future;
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      expect(probeCounts, {'cached': 1});
      async.elapse(headStart);
      async.flushMicrotasks();
      expect(probeCounts, {'cached': 1, 'slow': 1});

      cachedGate.complete((url: 'cached', ok: true));
      async.flushMicrotasks();
      expect(selections.first.candidate, 'cached');
      expect(selections.first.fromPreferred, isTrue);
      expect(probeCounts['cached'], 1);

      slowGate.complete((url: 'slow', ok: true));
      async.flushMicrotasks();
    });
  });

  test('cached endpoint failing within the head start falls back to a fresh race', () {
    fakeAsync((async) {
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];
      final cachedGates = <Completer<_Result>>[];
      late Completer<_Result> altGate;

      race(
        candidates: ['cached', 'alt'],
        preferred: 'cached',
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          final gate = Completer<_Result>();
          if (url == 'cached') {
            cachedGates.add(gate);
          } else {
            altGate = gate;
          }
          return gate.future;
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      cachedGates.single.complete((url: 'cached', ok: false));
      async.flushMicrotasks();
      expect(probeCounts, {'cached': 2, 'alt': 1});

      cachedGates.last.complete((url: 'cached', ok: false));
      altGate.complete((url: 'alt', ok: true));
      async.flushMicrotasks();

      expect(selections.first.candidate, 'alt');
      expect(selections.first.fromPreferred, isFalse);
      expect(probeCounts['cached'], 2);

      async.elapse(headStart);
      async.flushMicrotasks();
    });
  });

  test('preferred URL not among candidates skips the cached probe entirely', () {
    fakeAsync((async) {
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];
      final gates = <String, Completer<_Result>>{};

      race(
        candidates: ['a', 'b'],
        preferred: 'custom-url',
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          return (gates[url] = Completer<_Result>()).future;
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      expect(probeCounts.containsKey('custom-url'), isFalse);
      gates['a']!.complete((url: 'a', ok: true));
      gates['b']!.complete((url: 'b', ok: false));
      async.flushMicrotasks();

      expect(selections.first.candidate, 'a');
      expect(selections.first.fromPreferred, isFalse);
    });
  });

  test('emits nothing when every candidate fails', () async {
    final selections = await race(
      candidates: ['a', 'b'],
      preferred: 'a',
      probe: (url) async => (url: url, ok: false),
    ).toList();

    expect(selections, isEmpty);
  });

  test('phase 2 still promotes the selector-best endpoint', () {
    fakeAsync((async) {
      final selections = <EndpointRaceSelection<String, _Result>>[];
      final gates = <String, Completer<_Result>>{};

      race(
        candidates: ['quick', 'better'],
        probe: (url) => (gates[url] = Completer<_Result>()).future,
        measure: (url) async => (url: url, ok: true),
        selectBest: (results) => 'better',
      ).listen(selections.add);
      async.flushMicrotasks();

      gates['quick']!.complete((url: 'quick', ok: true));
      async.flushMicrotasks();
      gates['better']!.complete((url: 'better', ok: true));
      async.flushMicrotasks();

      expect(selections, hasLength(2));
      expect(selections.first.phase, EndpointRacePhase.first);
      expect(selections.first.candidate, 'quick');
      expect(selections.last.phase, EndpointRacePhase.best);
      expect(selections.last.candidate, 'better');
    });
  });
}
