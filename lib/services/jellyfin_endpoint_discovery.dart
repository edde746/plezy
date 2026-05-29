import 'dart:async';

import 'package:http/http.dart' as http;

import '../exceptions/media_server_exceptions.dart';
import '../utils/endpoint_race.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/url_utils.dart';

/// Result of a successful Jellyfin URL probe (`/System/Info/Public`).
class JellyfinServerInfo {
  final String serverName;

  /// Server's `Id` field — Jellyfin's machine identifier (UUID hex).
  final String machineId;

  /// Server's reported version string.
  final String version;

  const JellyfinServerInfo({required this.serverName, required this.machineId, required this.version});
}

class JellyfinEndpointRaceResult {
  final String activeBaseUrl;
  final List<String> baseUrls;
  final JellyfinServerInfo serverInfo;

  const JellyfinEndpointRaceResult({required this.activeBaseUrl, required this.baseUrls, required this.serverInfo});
}

class JellyfinEndpointProbeResult {
  final bool success;
  final int latencyMs;
  final JellyfinServerInfo? serverInfo;
  final String? error;

  const JellyfinEndpointProbeResult({required this.success, required this.latencyMs, this.serverInfo, this.error});
}

class JellyfinEndpointCandidate {
  final String url;
  final int index;

  const JellyfinEndpointCandidate({required this.url, required this.index});
}

class JellyfinEndpointDiscovery {
  JellyfinEndpointDiscovery({http.Client Function()? testHttpClientFactory})
    : _testHttpClientFactory = testHttpClientFactory;

  final http.Client Function()? _testHttpClientFactory;

  MediaServerHttpClient _buildHttpClient({required String baseUrl}) {
    LogRedactionManager.registerServerUrl(baseUrl);
    return MediaServerHttpClient(baseUrl: baseUrl, client: _testHttpClientFactory?.call());
  }

  /// Probe the server identified by [baseUrl] without authenticating.
  Future<JellyfinServerInfo> probe(String baseUrl, {Duration timeout = MediaServerTimeouts.jellyfinProbe}) async {
    final normalised = normalizeBaseUrl(baseUrl);
    final client = _buildHttpClient(baseUrl: normalised);
    try {
      final response = await client.get('/System/Info/Public', timeout: timeout);
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerUrlException('Server response was not JSON');
      }
      final id = data['Id'];
      final name = data['ServerName'] ?? data['LocalAddress'];
      if (id is! String || name is! String) {
        throw MediaServerUrlException('Server response missing Id/ServerName — not a Jellyfin server?');
      }
      return JellyfinServerInfo(serverName: name, machineId: id, version: data['Version'] as String? ?? '');
    } on MediaServerUrlException {
      rethrow;
    } on MediaServerHttpException catch (e) {
      throw MediaServerUrlException('Server probe failed: ${e.message}');
    } on TimeoutException {
      throw MediaServerUrlException('Server did not respond in time');
    } catch (e) {
      throw MediaServerUrlException('Server probe failed: $e');
    } finally {
      client.close();
    }
  }

  Future<JellyfinEndpointRaceResult> raceEndpoints(
    Iterable<String> baseUrls, {
    String? preferredUrl,
    String? expectedMachineId,
  }) async {
    final urls = normalizeBaseUrls(baseUrls);
    if (urls.isEmpty) {
      throw MediaServerUrlException('Enter at least one Jellyfin server URL');
    }

    final preferred = preferredUrl == null || preferredUrl.trim().isEmpty ? null : normalizeBaseUrl(preferredUrl);
    final candidates = [for (var i = 0; i < urls.length; i++) JellyfinEndpointCandidate(url: urls[i], index: i)];

    EndpointRaceSelection<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>? firstSelection;
    EndpointRaceSelection<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>? bestSelection;

    await for (final selection in raceEndpointCandidates<JellyfinEndpointCandidate, JellyfinEndpointProbeResult>(
      label: 'Jellyfin server URL',
      candidates: candidates,
      preferredUrl: preferred,
      urlOf: (candidate) => candidate.url,
      failureLogFields: (candidate, result) => {'error': result.error, 'latencyMs': result.latencyMs},
      probe: (candidate, timeout) => _probeWithLatency(candidate.url, timeout: timeout),
      measure: (candidate) => _probeWithAverageLatency(candidate.url, attempts: 2),
      isSuccess: (result) => result.success,
      selectBestCandidate: (results) => _selectLowestLatencyCandidate(results),
    )) {
      if (selection.phase == EndpointRacePhase.first) {
        firstSelection = selection;
      } else {
        bestSelection = selection;
      }
    }

    final selected = bestSelection ?? firstSelection;
    final selectedInfo = selected?.result.serverInfo;
    if (selected == null || selectedInfo == null) {
      throw MediaServerUrlException('No reachable Jellyfin server found');
    }

    final Map<JellyfinEndpointCandidate, JellyfinEndpointProbeResult> successfulResults =
        bestSelection?.successfulResults ?? firstSelection?.successfulResults ?? const {};
    final expected = expectedMachineId?.trim().isNotEmpty == true ? expectedMachineId!.trim() : selectedInfo.machineId;
    for (final result in successfulResults.values) {
      final info = result.serverInfo;
      if (info != null && info.machineId != expected) {
        throw MediaServerUrlException('The URLs point to different Jellyfin servers');
      }
    }

    if (selectedInfo.machineId != expected) {
      throw MediaServerUrlException('The URL does not match this Jellyfin server');
    }

    return JellyfinEndpointRaceResult(
      activeBaseUrl: selected.candidate.url,
      baseUrls: _activeFirst(selected.candidate.url, urls),
      serverInfo: selectedInfo,
    );
  }

  Future<JellyfinEndpointProbeResult> _probeWithLatency(String baseUrl, {required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final info = await probe(baseUrl, timeout: timeout);
      stopwatch.stop();
      return JellyfinEndpointProbeResult(success: true, latencyMs: stopwatch.elapsedMilliseconds, serverInfo: info);
    } catch (e) {
      stopwatch.stop();
      return JellyfinEndpointProbeResult(success: false, latencyMs: stopwatch.elapsedMilliseconds, error: e.toString());
    }
  }

  Future<JellyfinEndpointProbeResult> _probeWithAverageLatency(String baseUrl, {required int attempts}) async {
    final results = <JellyfinEndpointProbeResult>[];
    JellyfinServerInfo? info;
    for (var i = 0; i < attempts; i++) {
      final result = await _probeWithLatency(baseUrl, timeout: MediaServerTimeouts.connectionRace);
      if (!result.success) {
        return JellyfinEndpointProbeResult(success: false, latencyMs: result.latencyMs, error: result.error);
      }
      info = result.serverInfo;
      results.add(result);
    }
    final avgLatency = results.map((result) => result.latencyMs).reduce((a, b) => a + b) ~/ results.length;
    return JellyfinEndpointProbeResult(success: true, latencyMs: avgLatency, serverInfo: info);
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

  static String normalizeBaseUrl(String input) => stripTrailingSlash(input);

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
