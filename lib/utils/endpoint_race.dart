import 'dart:async';

import 'app_logger.dart';
import 'media_server_timeouts.dart';

enum EndpointRacePhase { first, best }

class EndpointRaceSelection<C, R> {
  final EndpointRacePhase phase;
  final C candidate;
  final R result;
  final bool fromPreferred;
  final Map<C, R> successfulResults;

  const EndpointRaceSelection({
    required this.phase,
    required this.candidate,
    required this.result,
    this.fromPreferred = false,
    this.successfulResults = const {},
  });
}

/// Shared two-phase endpoint discovery used by Plex and Jellyfin.
///
/// Phase 1 emits the first reachable endpoint quickly, using a cached/preferred
/// endpoint first when available. Phase 2 measures all candidates and emits the
/// selector's best endpoint, letting callers promote a lower-latency URL in the
/// background without blocking initial connection setup.
Stream<EndpointRaceSelection<C, R>> raceEndpointCandidates<C, R>({
  required String label,
  required List<C> candidates,
  required String Function(C candidate) urlOf,
  String Function(C candidate)? displayTypeOf,
  Map<String, Object?> Function(C candidate, R result)? failureLogFields,
  String? preferredUrl,
  C? Function(String url)? candidateForUrl,
  required Future<R> Function(C candidate, Duration timeout) probe,
  required Future<R> Function(C candidate) measure,
  required bool Function(R result) isSuccess,
  required C? Function(Map<C, R> successfulResults) selectBestCandidate,
  void Function(C candidate, R result)? onFirstSuccess,
  Duration preferredTimeout = MediaServerTimeouts.preferredEndpointProbe,
  Duration raceTimeout = MediaServerTimeouts.connectionRace,
}) async* {
  if (candidates.isEmpty) {
    appLogger.w('No endpoint candidates available for $label discovery');
    return;
  }

  C? firstCandidate;
  R? firstResult;
  var fromPreferred = false;

  if (preferredUrl != null && preferredUrl.isNotEmpty) {
    final cachedCandidate = candidateForUrl?.call(preferredUrl) ?? _candidateForUrl(candidates, urlOf, preferredUrl);
    if (cachedCandidate != null) {
      appLogger.d('Testing cached $label endpoint before running full race', error: {'uri': preferredUrl});
      final result = await probe(cachedCandidate, preferredTimeout);

      if (isSuccess(result)) {
        appLogger.i('Cached $label endpoint succeeded, using immediately', error: {'uri': preferredUrl});
        firstCandidate = cachedCandidate;
        firstResult = result;
        fromPreferred = true;
        onFirstSuccess?.call(cachedCandidate, result);
      } else {
        appLogger.w('Cached $label endpoint failed, falling back to candidate race', error: {'uri': preferredUrl});
      }
    }
  }

  if (firstCandidate == null || firstResult == null) {
    final first = await _raceFirstSuccess(
      label: label,
      candidates: candidates,
      urlOf: urlOf,
      displayTypeOf: displayTypeOf,
      failureLogFields: failureLogFields,
      probe: probe,
      isSuccess: isSuccess,
      onFirstSuccess: onFirstSuccess,
      timeout: raceTimeout,
    );
    if (first == null) {
      appLogger.e('No working $label endpoints after race', error: {'candidateCount': candidates.length});
      return;
    }
    appLogger.i(
      '$label race found first working endpoint',
      error: {'uri': urlOf(first.candidate), 'type': displayTypeOf?.call(first.candidate)},
    );
    firstCandidate = first.candidate;
    firstResult = first.result;
  }

  final resolvedFirstCandidate = firstCandidate;
  final resolvedFirstResult = firstResult;
  if (resolvedFirstCandidate == null || resolvedFirstResult == null) return;

  yield EndpointRaceSelection<C, R>(
    phase: EndpointRacePhase.first,
    candidate: resolvedFirstCandidate,
    result: resolvedFirstResult,
    fromPreferred: fromPreferred,
    successfulResults: {resolvedFirstCandidate: resolvedFirstResult},
  );

  final successfulResults = <C, R>{};
  await Future.wait(
    candidates.map((candidate) async {
      final result = await measure(candidate);
      if (isSuccess(result)) {
        successfulResults[candidate] = result;
      }
    }),
  );

  if (successfulResults.isEmpty) {
    appLogger.w('$label latency sweep found no additional working endpoints');
    return;
  }

  appLogger.d(
    'Completed latency sweep for $label endpoints',
    error: {'successfulCandidates': successfulResults.length},
  );

  final bestCandidate = selectBestCandidate(successfulResults);
  if (bestCandidate == null) return;
  final bestResult = successfulResults[bestCandidate];
  if (bestResult == null) return;

  yield EndpointRaceSelection<C, R>(
    phase: EndpointRacePhase.best,
    candidate: bestCandidate,
    result: bestResult,
    successfulResults: Map.unmodifiable(successfulResults),
  );
}

C? _candidateForUrl<C>(List<C> candidates, String Function(C candidate) urlOf, String url) {
  for (final candidate in candidates) {
    if (urlOf(candidate) == url) return candidate;
  }
  return null;
}

Future<({C candidate, R result})?> _raceFirstSuccess<C, R>({
  required String label,
  required List<C> candidates,
  required String Function(C candidate) urlOf,
  required Future<R> Function(C candidate, Duration timeout) probe,
  required bool Function(R result) isSuccess,
  required Duration timeout,
  String Function(C candidate)? displayTypeOf,
  Map<String, Object?> Function(C candidate, R result)? failureLogFields,
  void Function(C candidate, R result)? onFirstSuccess,
}) async {
  final completer = Completer<({C candidate, R result})?>();
  var completedTests = 0;

  appLogger.d(
    'Running $label endpoint race to find first working endpoint',
    error: {'candidateCount': candidates.length},
  );

  for (final candidate in candidates) {
    unawaited(
      probe(candidate, timeout)
          .then((result) {
            completedTests++;

            if (!isSuccess(result)) {
              appLogger.w(
                '$label endpoint candidate failed',
                error: {
                  'url': urlOf(candidate),
                  'type': displayTypeOf?.call(candidate),
                  ...?failureLogFields?.call(candidate, result),
                },
              );
            }

            if (isSuccess(result) && !completer.isCompleted) {
              onFirstSuccess?.call(candidate, result);
              completer.complete((candidate: candidate, result: result));
            }

            if (completedTests == candidates.length && !completer.isCompleted) {
              completer.complete(null);
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            completedTests++;
            appLogger.w(
              '$label endpoint candidate threw during race',
              error: {'url': urlOf(candidate), 'error': error.toString()},
              stackTrace: stackTrace,
            );
            if (completedTests == candidates.length && !completer.isCompleted) {
              completer.complete(null);
            }
          }),
    );
  }

  return completer.future;
}
