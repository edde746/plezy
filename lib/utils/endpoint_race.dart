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
/// Phase 1 emits the first reachable endpoint quickly. A cached/preferred
/// endpoint is probed first and wins deterministically when it answers within
/// [preferredHeadStart]; otherwise the full candidate race starts with the
/// still-pending cached probe merged in as a participant, so a stale cached
/// endpoint (e.g. a LAN address probed from outside the LAN) costs the head
/// start instead of the full [preferredTimeout] serially. Phase 2 measures all
/// candidates and emits the selector's best endpoint, letting callers promote
/// a lower-latency URL in the background without blocking initial connection
/// setup.
///
/// [tierOf] makes phase 1 class-aware without delaying any probe: candidates
/// map to an integer tier (0 = preferred). Every probe still starts
/// immediately, but a success from a higher (fallback) tier — e.g. a Plex
/// relay — is held and only accepted once every lower-tier candidate has
/// failed, so a marginally slower direct endpoint always beats a fast relay
/// edge. The hold is bounded by [raceTimeout] because that already bounds
/// each probe. A cached/preferred URL resolving to a fallback-tier candidate
/// also gets no head start; it competes as an ordinary participant. Omitting
/// [tierOf] keeps the plain first-success race.
///
/// Diagnostic events intentionally omit candidate URLs. Backends register
/// endpoints separately for unavoidable network-layer diagnostics.
Stream<EndpointRaceSelection<C, R>> raceEndpointCandidates<C, R>({
  required String label,
  required List<C> candidates,
  required String Function(C candidate) urlOf,
  String Function(C candidate)? displayTypeOf,
  Map<String, Object?> Function(C candidate, R result)? failureLogFields,
  String? preferredUrl,
  C? Function(String url)? candidateForUrl,
  int Function(C candidate)? tierOf,
  required Future<R> Function(C candidate, Duration timeout) probe,
  required Future<R> Function(C candidate) measure,
  required bool Function(R result) isSuccess,
  required C? Function(Map<C, R> successfulResults) selectBestCandidate,
  void Function(C candidate, R result)? onFirstSuccess,
  Duration preferredTimeout = MediaServerTimeouts.preferredEndpointProbe,
  Duration preferredHeadStart = MediaServerTimeouts.preferredEndpointHeadStart,
  Duration raceTimeout = MediaServerTimeouts.connectionRace,
}) async* {
  if (candidates.isEmpty) {
    appLogger.w('No endpoint candidates available for $label discovery');
    return;
  }

  final stopwatch = Stopwatch()..start();
  C? firstCandidate;
  R? firstResult;
  var fromPreferred = false;

  C? cachedCandidate;
  Future<R>? pendingCachedProbe;
  if (preferredUrl != null && preferredUrl.isNotEmpty) {
    cachedCandidate = candidateForUrl?.call(preferredUrl) ?? _candidateForUrl(candidates, urlOf, preferredUrl);
  }
  if (cachedCandidate != null && tierOf != null && tierOf(cachedCandidate) > 0) {
    // A fallback-tier endpoint must never win the deterministic head start:
    // it stays an ordinary race participant so preferred-tier candidates can
    // beat it. Guarded here rather than at bind sites so every binder
    // self-heals a fallback URL persisted by older builds.
    appLogger.d('Cached $label endpoint is fallback-tier, racing without a head start');
    cachedCandidate = null;
  }
  if (cachedCandidate != null) {
    final cached = cachedCandidate;
    appLogger.d('Testing cached $label endpoint with a head start on the race');
    final cachedProbe = probe(cached, preferredTimeout);
    final headStartResult = await Future.any<R?>([cachedProbe, Future<R?>.delayed(preferredHeadStart, () => null)]);

    if (headStartResult != null && isSuccess(headStartResult)) {
      appLogger.i(
        'Cached $label endpoint succeeded, using immediately',
        error: {'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      firstCandidate = cached;
      firstResult = headStartResult;
      fromPreferred = true;
      onFirstSuccess?.call(cached, headStartResult);
    } else if (headStartResult != null) {
      // Failed within the head start (e.g. connection refused) — run the
      // plain race; the cached URL is among the candidates and gets a fresh
      // probe like any other.
      appLogger.w(
        'Cached $label endpoint failed, falling back to candidate race',
        error: {'elapsedMs': stopwatch.elapsedMilliseconds},
      );
    } else {
      appLogger.d('Cached $label endpoint still pending after head start, racing all candidates');
      pendingCachedProbe = cachedProbe;
    }
  }

  if (firstCandidate == null || firstResult == null) {
    // When the cached probe is still in flight, merge it into the race as a
    // participant (reusing its future) instead of probing the same URL twice.
    final mergedCached = pendingCachedProbe != null ? cachedCandidate : null;
    final raceCandidates = mergedCached == null
        ? candidates
        : <C>[mergedCached, ...candidates.where((c) => urlOf(c) != preferredUrl)];
    final first = await _raceFirstSuccess(
      label: label,
      candidates: raceCandidates,
      urlOf: urlOf,
      displayTypeOf: displayTypeOf,
      failureLogFields: failureLogFields,
      tierOf: tierOf,
      probe: (candidate, timeout) =>
          mergedCached != null && identical(candidate, mergedCached) ? pendingCachedProbe! : probe(candidate, timeout),
      isSuccess: isSuccess,
      onFirstSuccess: onFirstSuccess,
      timeout: raceTimeout,
    );
    if (first == null) {
      appLogger.e(
        'No working $label endpoints after race',
        error: {'candidateCount': raceCandidates.length, 'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      return;
    }
    firstCandidate = first.candidate;
    firstResult = first.result;
    fromPreferred = mergedCached != null && identical(firstCandidate, mergedCached);
    appLogger.i(
      '$label race found first working endpoint',
      error: {
        'type': displayTypeOf?.call(first.candidate),
        'fromPreferred': fromPreferred,
        'elapsedMs': stopwatch.elapsedMilliseconds,
      },
    );
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
    error: {'successfulCandidates': successfulResults.length, 'elapsedMs': stopwatch.elapsedMilliseconds},
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
  int Function(C candidate)? tierOf,
  String Function(C candidate)? displayTypeOf,
  Map<String, Object?> Function(C candidate, R result)? failureLogFields,
  void Function(C candidate, R result)? onFirstSuccess,
}) async {
  final completer = Completer<({C candidate, R result})?>();

  int tierFor(C candidate) => tierOf?.call(candidate) ?? 0;
  final pendingByTier = <int, int>{};
  for (final candidate in candidates) {
    pendingByTier.update(tierFor(candidate), (count) => count + 1, ifAbsent: () => 1);
  }

  // Best fallback-tier success so far: only accepted once no lower-tier
  // probe is still pending, so a preferred-tier endpoint that answers later
  // (but within its probe timeout) still wins.
  ({C candidate, R result, int tier})? held;

  bool lowerTierPending(int tier) {
    for (final entry in pendingByTier.entries) {
      if (entry.key < tier && entry.value > 0) return true;
    }
    return false;
  }

  void win(C candidate, R result) {
    onFirstSuccess?.call(candidate, result);
    completer.complete((candidate: candidate, result: result));
  }

  // Runs after a probe resolves without an immediate win: releases the held
  // fallback success once every lower tier has drained, and completes with
  // null when all candidates resolved without any success.
  void settle() {
    if (completer.isCompleted) return;
    final fallback = held;
    if (fallback != null && !lowerTierPending(fallback.tier)) {
      appLogger.i(
        '$label fallback-tier endpoint accepted after preferred tiers failed',
        error: {'type': displayTypeOf?.call(fallback.candidate)},
      );
      win(fallback.candidate, fallback.result);
      return;
    }
    if (pendingByTier.values.every((count) => count == 0)) {
      completer.complete(null);
    }
  }

  appLogger.d(
    'Running $label endpoint race to find first working endpoint',
    error: {'candidateCount': candidates.length},
  );

  for (final candidate in candidates) {
    final tier = tierFor(candidate);
    unawaited(
      probe(candidate, timeout)
          .then((result) {
            pendingByTier[tier] = pendingByTier[tier]! - 1;

            if (!isSuccess(result)) {
              final failureFields = failureLogFields?.call(candidate, result);
              appLogger.w(
                '$label endpoint candidate failed',
                error: {
                  'type': displayTypeOf?.call(candidate),
                  if (failureFields != null) ..._sanitizeEndpointFields(failureFields, urlOf(candidate)),
                },
              );
              settle();
              return;
            }

            if (completer.isCompleted) return;

            if (!lowerTierPending(tier)) {
              win(candidate, result);
              return;
            }

            // A fallback-tier endpoint answered while a preferred tier is
            // still probing (e.g. Plex relay vs direct). Hold it: it wins
            // only if every preferred-tier candidate fails, so a slower
            // direct endpoint always beats a fast relay edge (#1974).
            final current = held;
            if (current == null || tier < current.tier) {
              appLogger.d(
                '$label fallback-tier endpoint succeeded, holding while preferred tiers race',
                error: {'type': displayTypeOf?.call(candidate)},
              );
              held = (candidate: candidate, result: result, tier: tier);
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            pendingByTier[tier] = pendingByTier[tier]! - 1;
            appLogger.w(
              '$label endpoint candidate threw during race',
              error: {'errorType': error.runtimeType.toString()},
              stackTrace: stackTrace,
            );
            settle();
          }),
    );
  }

  return completer.future;
}

Map<String, Object?> _sanitizeEndpointFields(Map<String, Object?> fields, String endpoint) {
  final uri = Uri.tryParse(endpoint);
  final literals = <String>{
    if (endpoint.isNotEmpty) endpoint,
    if (uri != null && uri.host.isNotEmpty) uri.host,
    if (uri != null && uri.path.length > 1) uri.path,
  };
  return {
    for (final entry in fields.entries)
      entry.key: switch (entry.value) {
        final String value => literals.fold<String>(value, (safe, literal) => safe.replaceAll(literal, '[endpoint]')),
        null || num() || bool() => entry.value,
        final value => value.runtimeType.toString(),
      },
  };
}
