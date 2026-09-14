import 'dart:async';

import 'package:http/http.dart' as http;

import '../i18n/strings.g.dart';

import '../exceptions/media_server_exceptions.dart';
import '../media/media_browser_dialect.dart';
import '../utils/endpoint_race.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/url_utils.dart';

/// Result of a successful MediaBrowser server URL probe (`/System/Info/Public`).
class JellyfinServerInfo {
  final String serverName;

  /// Server's `Id` field — its stable machine identifier.
  final String machineId;

  /// Server's reported version string.
  final String version;

  /// Dialect detected from public system info, or `null` when the response has
  /// no trustworthy Jellyfin/Emby discriminator.
  final MediaBrowserDialect? dialect;

  const JellyfinServerInfo({required this.serverName, required this.machineId, required this.version, this.dialect});
}

class JellyfinEndpointRaceResult {
  final String activeBaseUrl;

  /// Active-first endpoints selected for persistence. Candidates that reported
  /// another machine ID are excluded; candidates that returned no trustworthy
  /// identity are retained for a later retry.
  final List<String> baseUrls;
  final JellyfinServerInfo serverInfo;
  final Map<String, String> _verifiedEffectiveBaseUrls;
  final Set<String> _machineMismatchBaseUrls;

  const JellyfinEndpointRaceResult._({
    required this.activeBaseUrl,
    required this.baseUrls,
    required this.serverInfo,
    required this._verifiedEffectiveBaseUrls,
    required this._machineMismatchBaseUrls,
  });

  /// Reconciles endpoints from an existing authenticated connection after a
  /// partial race.
  ///
  /// Same-machine candidates are replaced with their verified effective URL,
  /// candidates that reported another machine ID are removed, and candidates
  /// that returned no trustworthy identity are retained for a later retry.
  /// Fresh user input must continue to use [baseUrls] instead.
  List<String> reconcilePreviouslyStoredBaseUrls(Iterable<String> storedBaseUrls) {
    final retained = <String>[];
    for (final url in JellyfinEndpointDiscovery.normalizeBaseUrls(storedBaseUrls)) {
      final verifiedEffectiveUrl = _verifiedEffectiveBaseUrls[url];
      if (verifiedEffectiveUrl != null) {
        retained.add(verifiedEffectiveUrl);
      } else if (!_machineMismatchBaseUrls.contains(url)) {
        retained.add(url);
      }
    }
    return JellyfinEndpointDiscovery._activeFirst(activeBaseUrl, retained);
  }
}

class JellyfinEndpointProbeResult {
  final bool success;
  final int latencyMs;
  final JellyfinServerInfo? serverInfo;
  final String? effectiveBaseUrl;
  final String? failureType;

  const JellyfinEndpointProbeResult({
    required this.success,
    required this.latencyMs,
    this.serverInfo,
    this.effectiveBaseUrl,
    this.failureType,
  });
}

class JellyfinEndpointCandidate {
  final String url;
  final int index;

  const JellyfinEndpointCandidate({required this.url, required this.index});
}

class JellyfinEndpointUserInputCandidates {
  final List<String> probeBaseUrls;
  final List<String> explicitBaseUrls;
  final List<List<String>> validationBaseUrlGroups;

  const JellyfinEndpointUserInputCandidates({
    required this.probeBaseUrls,
    required this.explicitBaseUrls,
    required this.validationBaseUrlGroups,
  });
}

class JellyfinEndpointDiscovery {
  static const int defaultPort = 8096;

  JellyfinEndpointDiscovery({this.dialect = MediaBrowserDialect.jellyfin, this._testHttpClientFactory});

  final MediaBrowserDialect dialect;
  final http.Client Function()? _testHttpClientFactory;

  MediaServerHttpClient _buildHttpClient({required String baseUrl}) {
    LogRedactionManager.registerServerUrl(baseUrl);
    return MediaServerHttpClient(baseUrl: baseUrl, client: _testHttpClientFactory?.call());
  }

  /// Probe the server identified by [baseUrl] without authenticating.
  Future<JellyfinServerInfo> probe(
    String baseUrl, {
    Duration timeout = MediaServerTimeouts.jellyfinProbe,
    AbortController? abort,
  }) async {
    final result = await _probeServer(baseUrl, timeout: timeout, abort: abort);
    return result.serverInfo;
  }

  Future<({JellyfinServerInfo serverInfo, String effectiveBaseUrl})> _probeServer(
    String baseUrl, {
    required Duration timeout,
    AbortController? abort,
  }) async {
    final normalised = normalizeBaseUrl(baseUrl);
    final client = _buildHttpClient(baseUrl: normalised);
    try {
      final response = await client.get('/System/Info/Public', timeout: timeout, abort: abort);
      throwIfHttpError(response);
      final effectiveBaseUrl = _resolveEffectiveBaseUrl(normalised, response);
      if (effectiveBaseUrl != normalised) {
        LogRedactionManager.registerServerUrl(effectiveBaseUrl);
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerUrlException('Server response was not JSON', display: t.addServer.responseNotJson);
      }
      final id = data['Id'];
      final name = data['ServerName'] ?? data['LocalAddress'];
      if (id is! String || name is! String) {
        throw MediaServerUrlException(
          'Server response missing Id/ServerName — not a ${dialect.productName} server?',
          display: t.addServer.responseMissingIdentity(product: dialect.productName),
        );
      }
      return (
        serverInfo: JellyfinServerInfo(
          serverName: name,
          machineId: id,
          version: data['Version'] as String? ?? '',
          dialect: MediaBrowserDialect.detectFromPublicSystemInfo(data),
        ),
        effectiveBaseUrl: effectiveBaseUrl,
      );
    } on MediaServerUrlException {
      rethrow;
    } on MediaServerHttpException catch (e) {
      if (e.isCancellation) rethrow;
      throw MediaServerUrlException(
        'Server probe failed: ${e.message}',
        display: t.addServer.probeFailed(error: e.message),
      );
    } on TimeoutException {
      throw MediaServerUrlException('Server did not respond in time', display: t.addServer.serverTimedOut);
    } catch (e) {
      throw MediaServerUrlException('Server probe failed: $e', display: t.addServer.probeFailed(error: e));
    } finally {
      client.close();
    }
  }

  /// Races public MediaBrowser server probes and returns persistence-safe endpoints.
  ///
  /// [baseUrlsToPersist] contains caller-selected persistence candidates.
  /// Candidates that reported another machine are excluded; candidates that
  /// returned no trustworthy identity are retained for a later retry.
  Future<JellyfinEndpointRaceResult> raceEndpoints(
    Iterable<String> baseUrls, {
    String? preferredUrl,
    String? expectedMachineId,
    Iterable<String>? baseUrlsToPersist,
    Iterable<String>? baseUrlsToValidate,
    Iterable<Iterable<String>>? baseUrlValidationGroups,
  }) async {
    final urls = normalizeBaseUrls(baseUrls);
    if (urls.isEmpty) {
      throw MediaServerUrlException(
        'Enter at least one ${dialect.productName} server URL',
        display: t.addServer.enterAtLeastOneUrl(product: dialect.productName),
      );
    }

    final persistUrls = baseUrlsToPersist == null ? urls : normalizeBaseUrls(baseUrlsToPersist);
    final validateUrls = baseUrlsToValidate == null ? urls : normalizeBaseUrls(baseUrlsToValidate);
    final validateUrlSet = validateUrls.toSet();
    final validationGroups = baseUrlValidationGroups == null ? null : _normalizeBaseUrlGroups(baseUrlValidationGroups);

    final preferred = preferredUrl == null || preferredUrl.trim().isEmpty ? null : normalizeBaseUrl(preferredUrl);
    final candidates = [for (var i = 0; i < urls.length; i++) JellyfinEndpointCandidate(url: urls[i], index: i)];
    final identityResults = <JellyfinEndpointCandidate, JellyfinEndpointProbeResult>{};
    final phaseOneIdentityProbes = <Future<JellyfinEndpointProbeResult>>[];
    JellyfinEndpointProbeResult recordIdentity(
      JellyfinEndpointCandidate candidate,
      JellyfinEndpointProbeResult result,
    ) {
      if (result.serverInfo != null) identityResults[candidate] = result;
      return result;
    }

    EndpointRaceSelection<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>? firstSelection;
    EndpointRaceSelection<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>? bestSelection;

    await for (final selection in raceEndpointCandidates<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>(
      label: '${dialect.productName} server URL',
      candidates: candidates,
      preferredUrl: preferred,
      urlOf: (candidate) => candidate.url,
      failureLogFields: (candidate, result) => {'failureType': result.failureType, 'latencyMs': result.latencyMs},
      probe: (candidate, timeout) {
        final identityProbe = _probeWithLatency(
          candidate.url,
          timeout: timeout,
        ).then((result) => recordIdentity(candidate, result));
        phaseOneIdentityProbes.add(identityProbe);
        return identityProbe;
      },
      measure: (candidate) async =>
          recordIdentity(candidate, await _probeWithAverageLatency(candidate.url, attempts: 2)),
      isSuccess: (result) => result.success,
      selectBestCandidate: (results) => _selectLowestLatencyCandidate(results),
    )) {
      if (selection.phase == EndpointRacePhase.first) {
        firstSelection = selection;
      } else {
        bestSelection = selection;
      }
    }

    // The first-success race deliberately returns while slower phase-one
    // probes are still running. Each probe already carries the race timeout;
    // wait for those bounded results before deciding which persisted
    // fallbacks proved the expected machine identity.
    await Future.wait(phaseOneIdentityProbes);

    final selected = bestSelection ?? firstSelection;
    if (selected == null || selected.result.serverInfo == null) {
      throw MediaServerUrlException(
        'No reachable ${dialect.productName} server found',
        display: t.addServer.noReachableServer(product: dialect.productName),
      );
    }

    final Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult> successfulResults =
        bestSelection?.successfulResults ?? firstSelection?.successfulResults ?? const {};
    var selectedCandidate = selected.candidate;
    var selectedResult = selected.result;

    final expectedMachineIdTrimmed = expectedMachineId?.trim();
    final hasExpectedMachineId = expectedMachineIdTrimmed?.isNotEmpty == true;
    if (hasExpectedMachineId) {
      final matchingResults = Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>.fromEntries(
        successfulResults.entries.where((entry) => entry.value.serverInfo?.machineId == expectedMachineIdTrimmed),
      );
      final matchingCandidate = _selectLowestLatencyCandidate(matchingResults);
      final matchingResult = matchingCandidate == null ? null : matchingResults[matchingCandidate];
      if (matchingCandidate != null && matchingResult != null) {
        selectedCandidate = matchingCandidate;
        selectedResult = matchingResult;
      }
    }

    final selectedInfo = selectedResult.serverInfo;
    if (selectedInfo == null) {
      throw MediaServerUrlException(
        'No reachable ${dialect.productName} server found',
        display: t.addServer.noReachableServer(product: dialect.productName),
      );
    }

    final expected = hasExpectedMachineId ? expectedMachineIdTrimmed! : selectedInfo.machineId;
    if (validationGroups != null) {
      if (validationGroups.length > 1) {
        for (final group in validationGroups) {
          final groupSet = group.toSet();
          final groupResults = Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>.fromEntries(
            identityResults.entries.where((entry) => groupSet.contains(entry.key.url)),
          );
          final candidate = _selectValidationCandidate(groupResults, expectedMachineId: expectedMachineIdTrimmed);
          final info = candidate == null ? null : groupResults[candidate]?.serverInfo;
          if (info != null && info.machineId != expected) {
            throw MediaServerUrlException(
              'The URLs point to different ${dialect.productName} servers',
              display: t.addServer.urlsPointToDifferentServers(product: dialect.productName),
            );
          }
        }
      }
    } else {
      for (final entry in identityResults.entries) {
        if (!validateUrlSet.contains(entry.key.url)) continue;
        final info = entry.value.serverInfo;
        if (info != null && info.machineId != expected) {
          throw MediaServerUrlException(
            'The URLs point to different ${dialect.productName} servers',
            display: t.addServer.urlsPointToDifferentServers(product: dialect.productName),
          );
        }
      }
    }

    if (selectedInfo.machineId != expected) {
      throw MediaServerUrlException(
        'The URL does not match this ${dialect.productName} server',
        display: t.addServer.urlDoesNotMatchServer(product: dialect.productName),
      );
    }

    final effectiveUrls = <String, String>{};
    final machineMismatchBaseUrls = <String>{};
    for (final entry in identityResults.entries) {
      if (entry.value.serverInfo?.machineId != expected) {
        machineMismatchBaseUrls.add(entry.key.url);
        continue;
      }
      final effectiveBaseUrl = entry.value.effectiveBaseUrl;
      if (effectiveBaseUrl != null) {
        effectiveUrls[entry.key.url] = effectiveBaseUrl;
      }
    }
    final activeBaseUrl = selectedResult.effectiveBaseUrl ?? selectedCandidate.url;
    effectiveUrls[selectedCandidate.url] = activeBaseUrl;
    final persistedUrls = [
      for (final url in persistUrls)
        if (!machineMismatchBaseUrls.contains(url)) effectiveUrls[url] ?? url,
    ];

    return JellyfinEndpointRaceResult._(
      activeBaseUrl: activeBaseUrl,
      baseUrls: _activeFirst(activeBaseUrl, persistedUrls),
      serverInfo: selectedInfo,
      verifiedEffectiveBaseUrls: Map.unmodifiable(effectiveUrls),
      machineMismatchBaseUrls: Set.unmodifiable(machineMismatchBaseUrls),
    );
  }

  Future<JellyfinEndpointProbeResult> _probeWithLatency(String baseUrl, {required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final probe = await _probeServer(baseUrl, timeout: timeout);
      stopwatch.stop();
      return JellyfinEndpointProbeResult(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        serverInfo: probe.serverInfo,
        effectiveBaseUrl: probe.effectiveBaseUrl,
      );
    } catch (e) {
      stopwatch.stop();
      return JellyfinEndpointProbeResult(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        failureType: e.runtimeType.toString(),
      );
    }
  }

  Future<JellyfinEndpointProbeResult> _probeWithAverageLatency(String baseUrl, {required int attempts}) async {
    final results = <JellyfinEndpointProbeResult>[];
    JellyfinServerInfo? info;
    String? effectiveBaseUrl;
    for (var i = 0; i < attempts; i++) {
      final result = await _probeWithLatency(baseUrl, timeout: MediaServerTimeouts.connectionRace);
      if (!result.success) {
        return JellyfinEndpointProbeResult(
          success: false,
          latencyMs: result.latencyMs,
          failureType: result.failureType,
          serverInfo: info,
          effectiveBaseUrl: effectiveBaseUrl,
        );
      }
      info = result.serverInfo;
      effectiveBaseUrl = result.effectiveBaseUrl;
      results.add(result);
    }
    final avgLatency = results.map((result) => result.latencyMs).reduce((a, b) => a + b) ~/ results.length;
    return JellyfinEndpointProbeResult(
      success: true,
      latencyMs: avgLatency,
      serverInfo: info,
      effectiveBaseUrl: effectiveBaseUrl,
    );
  }

  JellyfinEndpointCandidate? _selectLowestLatencyCandidate(
    Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult> results,
  ) {
    if (results.isEmpty) return null;
    final entries = results.entries.toList()
      ..sort((a, b) {
        final latency = a.value.latencyMs.compareTo(b.value.latencyMs);
        if (latency != 0) return latency;
        return a.key.index.compareTo(b.key.index);
      });
    return entries.first.key;
  }

  JellyfinEndpointCandidate? _selectValidationCandidate(
    Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult> results, {
    required String? expectedMachineId,
  }) {
    if (expectedMachineId?.isNotEmpty == true) {
      final matchingResults = Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>.fromEntries(
        results.entries.where((entry) => entry.value.serverInfo?.machineId == expectedMachineId),
      );
      final match = _selectLowestLatencyCandidate(matchingResults);
      if (match != null) return match;
    }
    return _selectLowestLatencyCandidate(results);
  }

  String _resolveEffectiveBaseUrl(String requestedBaseUrl, MediaServerResponse response) {
    final requestedUri = response.requestUri;
    final effectiveUri = response.effectiveUri;
    if (requestedUri == null || effectiveUri == null || effectiveUri == requestedUri) {
      return requestedBaseUrl;
    }

    final requestedBaseUri = Uri.tryParse(requestedBaseUrl);
    final effectiveScheme = effectiveUri.scheme.toLowerCase();
    if (requestedBaseUri == null ||
        requestedBaseUri.host.isEmpty ||
        (effectiveScheme != 'http' && effectiveScheme != 'https')) {
      throw MediaServerUrlException(
        'Server redirected to an unsupported URL',
        display: t.addServer.redirectUnsupported,
      );
    }
    if (requestedBaseUri.host.toLowerCase() != effectiveUri.host.toLowerCase()) {
      throw MediaServerUrlException(
        'Server redirected to a different host. Enter the final ${dialect.productName} URL directly',
        display: t.addServer.redirectDifferentHost(product: dialect.productName),
      );
    }
    if (requestedBaseUri.scheme.toLowerCase() == 'https' && effectiveScheme != 'https') {
      throw MediaServerUrlException(
        'Server redirected from HTTPS to an insecure URL',
        display: t.addServer.redirectInsecure,
      );
    }

    const publicInfoPath = '/System/Info/Public';
    if (!effectiveUri.path.endsWith(publicInfoPath)) {
      throw MediaServerUrlException(
        'Server redirected to an unsupported URL. Enter the final ${dialect.productName} URL directly',
        display: t.addServer.redirectUnsupportedEnterFinal(product: dialect.productName),
      );
    }
    final basePath = effectiveUri.path.substring(0, effectiveUri.path.length - publicInfoPath.length);
    return normalizeBaseUrl(effectiveUri.replace(path: basePath, query: null, fragment: null).toString());
  }

  /// Normalizes a concrete MediaBrowser base URL without inventing a scheme or port.
  static String normalizeBaseUrl(String input) => canonicalizeBaseUrl(input);

  /// Expands a user-typed add/edit form entry into temporary probe candidates.
  /// These guesses are for discovery only; failed guesses should not be stored.
  static List<String> expandInputToBaseUrls(
    String input, {
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
  }) => expandBaseUrlCandidates(input, guesses: _schemelessGuesses(dialect));

  /// Ordered guesses for a schemeless entry: the default HTTP install port
  /// first (the overwhelmingly common LAN case), then TLS on the default port
  /// and on the dialect's TLS ports, then plain HTTP on port 80.
  static List<BaseUrlGuess> _schemelessGuesses(MediaBrowserDialect dialect) => [
    (scheme: 'http', port: defaultPort),
    (scheme: 'https', port: null),
    for (final port in dialect.httpsPortGuesses) (scheme: 'https', port: port),
    (scheme: 'http', port: null),
  ];

  /// Splits a raw add/edit form field into the individual URLs the user typed.
  /// Entries are separated by newlines and/or commas; blanks are dropped.
  static List<String> parseUserEnteredUrls(String raw) {
    return raw.split(RegExp(r'[\n,]+')).map((url) => url.trim()).where((url) => url.isNotEmpty).toList(growable: false);
  }

  static JellyfinEndpointUserInputCandidates buildUserInputCandidates(
    Iterable<String> input, {
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
  }) {
    final probeBaseUrls = <String>[];
    final explicitBaseUrls = <String>[];
    final validationBaseUrlGroups = <List<String>>[];
    final seenProbe = <String>{};
    final seenExplicit = <String>{};

    void addProbe(String url) {
      final normalized = normalizeBaseUrl(url);
      if (normalized.isEmpty || !seenProbe.add(normalized)) return;
      probeBaseUrls.add(normalized);
    }

    void addExplicit(String url) {
      final normalized = normalizeBaseUrl(url);
      if (normalized.isEmpty || !seenExplicit.add(normalized)) return;
      explicitBaseUrls.add(normalized);
    }

    for (final raw in input) {
      final normalized = normalizeBaseUrl(raw);
      if (normalized.isEmpty) continue;
      if (hasUrlScheme(normalized)) {
        addProbe(normalized);
        addExplicit(normalized);
        validationBaseUrlGroups.add([normalized]);
      } else {
        final group = <String>[];
        for (final candidate in expandInputToBaseUrls(normalized, dialect: dialect)) {
          addProbe(candidate);
          group.add(candidate);
        }
        if (group.isNotEmpty) {
          validationBaseUrlGroups.add(List.unmodifiable(group));
        }
      }
    }

    return JellyfinEndpointUserInputCandidates(
      probeBaseUrls: List.unmodifiable(probeBaseUrls),
      explicitBaseUrls: List.unmodifiable(explicitBaseUrls),
      validationBaseUrlGroups: List.unmodifiable(validationBaseUrlGroups),
    );
  }

  static List<String> normalizeBaseUrls(Iterable<String> input) {
    final result = <String>[];
    final seen = <String>{};
    for (final raw in input) {
      final normalized = normalizeBaseUrl(raw);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      result.add(normalized);
    }
    return List.unmodifiable(result);
  }

  static List<List<String>> _normalizeBaseUrlGroups(Iterable<Iterable<String>> groups) {
    final result = <List<String>>[];
    for (final group in groups) {
      final normalized = normalizeBaseUrls(group);
      if (normalized.isNotEmpty) result.add(normalized);
    }
    return List.unmodifiable(result);
  }

  static List<String> _activeFirst(String activeBaseUrl, List<String> urls) {
    final result = <String>[];
    final seen = <String>{};
    void add(String url) {
      if (url.isEmpty || !seen.add(url)) return;
      result.add(url);
    }

    add(activeBaseUrl);
    for (final url in urls) {
      add(url);
    }
    return List.unmodifiable(result);
  }
}
