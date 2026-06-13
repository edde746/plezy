import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/endpoint_race.dart';

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

  Future<_Result> resultAfter(String url, Duration delay, {required bool ok}) async {
    await Future<void>.delayed(delay);
    return (url: url, ok: ok);
  }

  test('healthy cached endpoint wins within the head start without racing', () async {
    final probeCounts = <String, int>{};
    final selections = await race(
      candidates: ['a', 'cached'],
      preferred: 'cached',
      probe: (url) {
        probeCounts[url] = (probeCounts[url] ?? 0) + 1;
        return resultAfter(url, const Duration(milliseconds: 10), ok: true);
      },
    ).toList();

    expect(selections.first.phase, EndpointRacePhase.first);
    expect(selections.first.candidate, 'cached');
    expect(selections.first.fromPreferred, isTrue);
    expect(probeCounts['cached'], 1);
    // The race never started; only the phase-2 measure touches other URLs.
    expect(probeCounts.containsKey('a'), isFalse);
  });

  test('stale-slow cached endpoint overlaps the race instead of serially blocking it', () async {
    final probeCounts = <String, int>{};
    final stopwatch = Stopwatch()..start();
    final firstTimes = <int>[];
    final selections = <EndpointRaceSelection<String, _Result>>[];
    await for (final selection in race(
      candidates: ['fast', 'cached'],
      preferred: 'cached',
      probe: (url) {
        probeCounts[url] = (probeCounts[url] ?? 0) + 1;
        return resultAfter(
          url,
          url == 'cached' ? const Duration(milliseconds: 250) : const Duration(milliseconds: 10),
          ok: url != 'cached',
        );
      },
    )) {
      selections.add(selection);
      firstTimes.add(stopwatch.elapsedMilliseconds);
    }

    expect(selections.first.candidate, 'fast');
    expect(selections.first.fromPreferred, isFalse);
    // Emitted shortly after the head start — not after the cached probe's
    // full budget (the pre-change serial behavior).
    expect(firstTimes.first, lessThan(200));
    // The pending cached probe was merged into the race, not re-fired.
    expect(probeCounts['cached'], 1);

    // Let the still-pending cached probe finish inside the test body.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });

  test('cached endpoint that answers after the head start still wins when first', () async {
    final probeCounts = <String, int>{};
    final selections = await race(
      candidates: ['slow', 'cached'],
      preferred: 'cached',
      probe: (url) {
        probeCounts[url] = (probeCounts[url] ?? 0) + 1;
        return resultAfter(
          url,
          url == 'cached' ? const Duration(milliseconds: 120) : const Duration(milliseconds: 350),
          ok: true,
        );
      },
    ).toList();

    expect(selections.first.candidate, 'cached');
    expect(selections.first.fromPreferred, isTrue);
    expect(probeCounts['cached'], 1);

    await Future<void>.delayed(const Duration(milliseconds: 400));
  });

  test('cached endpoint failing within the head start falls back to a fresh race', () async {
    final probeCounts = <String, int>{};
    final selections = await race(
      candidates: ['cached', 'alt'],
      preferred: 'cached',
      probe: (url) {
        probeCounts[url] = (probeCounts[url] ?? 0) + 1;
        return resultAfter(url, const Duration(milliseconds: 10), ok: url == 'alt');
      },
    ).toList();

    expect(selections.first.candidate, 'alt');
    expect(selections.first.fromPreferred, isFalse);
    // Fast-fail keeps today's semantics: the cached URL re-races as a
    // normal candidate (one probe up front, one inside the race).
    expect(probeCounts['cached'], 2);
  });

  test('preferred URL not among candidates skips the cached probe entirely', () async {
    final probeCounts = <String, int>{};
    final selections = await race(
      candidates: ['a', 'b'],
      preferred: 'custom-url',
      probe: (url) {
        probeCounts[url] = (probeCounts[url] ?? 0) + 1;
        return resultAfter(url, const Duration(milliseconds: 10), ok: url == 'a');
      },
    ).toList();

    expect(selections.first.candidate, 'a');
    expect(selections.first.fromPreferred, isFalse);
    expect(probeCounts.containsKey('custom-url'), isFalse);
  });

  test('emits nothing when every candidate fails', () async {
    final selections = await race(
      candidates: ['a', 'b'],
      preferred: 'a',
      probe: (url) => resultAfter(url, const Duration(milliseconds: 10), ok: false),
    ).toList();

    expect(selections, isEmpty);
  });

  test('phase 2 still promotes the selector-best endpoint', () async {
    final selections = await race(
      candidates: ['quick', 'better'],
      probe: (url) => resultAfter(
        url,
        url == 'quick' ? const Duration(milliseconds: 10) : const Duration(milliseconds: 80),
        ok: true,
      ),
      measure: (url) async => (url: url, ok: true),
      selectBest: (results) => 'better',
    ).toList();

    expect(selections, hasLength(2));
    expect(selections.first.phase, EndpointRacePhase.first);
    expect(selections.first.candidate, 'quick');
    expect(selections.last.phase, EndpointRacePhase.best);
    expect(selections.last.candidate, 'better');
  });
}
