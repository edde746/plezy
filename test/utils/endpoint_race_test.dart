import 'dart:async';
import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/endpoint_race.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

typedef _Result = ({String url, bool ok});

void main() {
  const headStart = Duration(milliseconds: 60);
  setUp(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    setLoggerLevel(true);
  });
  tearDown(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  Stream<EndpointRaceSelection<String, _Result>> race({
    required List<String> candidates,
    String? preferred,
    required Future<_Result> Function(String url) probe,
    Future<_Result> Function(String url)? measure,
    String? Function(Map<String, _Result> results)? selectBest,
    Map<String, Object?> Function(String candidate, _Result result)? failureLogFields,
    Duration Function(String url)? probeDelayOf,
  }) {
    return raceEndpointCandidates<String, _Result>(
      label: 'test',
      candidates: candidates,
      urlOf: (c) => c,
      preferredUrl: preferred,
      failureLogFields: failureLogFields,
      probeDelayOf: probeDelayOf,
      probe: (c, _) => probe(c),
      measure: measure ?? (c) async => (url: c, ok: false),
      isSuccess: (r) => r.ok,
      selectBestCandidate: selectBest ?? (results) => results.keys.first,
      preferredTimeout: const Duration(milliseconds: 500),
      preferredHeadStart: headStart,
      raceTimeout: const Duration(milliseconds: 500),
    );
  }

  test('preferred endpoint diagnostics contain no candidate literals', () async {
    const canary = 'https://preferred-race-canary.invalid/private-race-path';

    final selections = await race(
      candidates: const [canary],
      preferred: canary,
      probe: (url) async => (url: url, ok: true),
      measure: (url) async => (url: url, ok: true),
    ).toList();
    final storedFields = MemoryLogOutput.getLogs().expand<String>(
      (entry) => [entry.message, if (entry.error != null) entry.error.toString()],
    );

    expect(selections.map((selection) => selection.candidate), everyElement(canary));
    for (final field in storedFields) {
      expect(field, isNot(contains('preferred-race-canary.invalid')));
      expect(field, isNot(contains('private-race-path')));
    }
  });

  test('candidate failure diagnostics sanitize endpoint-bearing fields', () async {
    const canary = 'https://failure-race-canary.invalid/private-failure-path';

    final selections = await race(
      candidates: const [canary],
      probe: (url) async => (url: url, ok: false),
      failureLogFields: (candidate, _) => {
        'error': 'probe failed at $candidate on failure-race-canary.invalid path /private-failure-path',
      },
    ).toList();
    final storedFields = MemoryLogOutput.getLogs().expand<String>(
      (entry) => [entry.message, if (entry.error != null) entry.error.toString()],
    );

    expect(selections, isEmpty);
    for (final field in storedFields) {
      expect(field, isNot(contains('failure-race-canary.invalid')));
      expect(field, isNot(contains('private-failure-path')));
    }
  });

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

  test('handicapped candidate loses to a slower direct candidate inside the window', () {
    fakeAsync((async) {
      const handicap = Duration(milliseconds: 100);
      final probeCounts = <String, int>{};
      final selections = <EndpointRaceSelection<String, _Result>>[];

      race(
        candidates: ['direct', 'relay'],
        probeDelayOf: (url) => url == 'relay' ? handicap : Duration.zero,
        probe: (url) {
          probeCounts[url] = (probeCounts[url] ?? 0) + 1;
          // Relay would answer instantly; direct takes 50ms — still inside
          // the handicap window, so direct must win phase 1.
          final delay = url == 'direct' ? const Duration(milliseconds: 50) : Duration.zero;
          return Future<_Result>.delayed(delay, () => (url: url, ok: true));
        },
      ).listen(selections.add);
      async.flushMicrotasks();

      // Relay's probe has not started yet.
      expect(probeCounts, {'direct': 1});

      async.elapse(const Duration(milliseconds: 50));
      expect(selections.first.phase, EndpointRacePhase.first);
      expect(selections.first.candidate, 'direct');

      // Once the race is decided, the handicapped probe is skipped entirely.
      async.elapse(handicap);
      expect(probeCounts.containsKey('relay'), isFalse);
    });
  });

  test('handicapped candidate still wins when nothing else responds', () {
    fakeAsync((async) {
      const handicap = Duration(milliseconds: 100);
      final selections = <EndpointRaceSelection<String, _Result>>[];

      race(
        candidates: ['direct', 'relay'],
        probeDelayOf: (url) => url == 'relay' ? handicap : Duration.zero,
        probe: (url) async => (url: url, ok: url == 'relay'),
      ).listen(selections.add);
      async.flushMicrotasks();

      // Direct failed immediately; relay has not been probed yet, so the race
      // must still be undecided rather than completed empty.
      expect(selections, isEmpty);

      async.elapse(handicap);
      async.flushMicrotasks();
      expect(selections.first.phase, EndpointRacePhase.first);
      expect(selections.first.candidate, 'relay');
    });
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
