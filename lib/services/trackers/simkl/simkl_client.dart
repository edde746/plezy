import 'dart:async';

import 'package:http/http.dart' as http;

import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'simkl_constants.dart';

/// HTTP wrapper for the Simkl REST API.
///
/// Simkl tokens don't expire; a 401 is terminal (user revoked access at
/// simkl.com/settings/apps). [onSessionInvalidated] clears the local session
/// in that case.
class SimklClient implements DisposableTrackerClient {
  final TrackerSession session;
  final TrackerHttpClient _http;
  final void Function() onSessionInvalidated;

  SimklClient(this.session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _http = TrackerHttpClient(service: TrackerService.simkl, logLabel: 'Simkl', httpClient: httpClient);

  @override
  void dispose() => _http.dispose();

  /// Fetch current user info. Used to populate the display name.
  Future<Map<String, dynamic>?> getUserSettings() async {
    final res = await _request('GET', '/users/settings');
    return res is Map ? res.cast<String, dynamic>() : null;
  }

  /// Mark one or more items as watched. Body shape:
  /// ```
  /// {"movies": [{"ids": {"simkl": 123}}], "shows": [...]}
  /// ```
  Future<void> addToHistory(Map<String, dynamic> body) => _request('POST', '/sync/history', body: body);

  Future<void> removeFromHistory(Map<String, dynamic> body) => _request('POST', '/sync/history/remove', body: body);

  Future<void> addRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings', body: body);

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  Future<List<dynamic>> getRatings(String type) async {
    final res = await _request('GET', '/sync/ratings/$type');
    if (res is List) return res;
    if (res is Map && res[type] is List) return res[type] as List<dynamic>;
    return const [];
  }

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${SimklConstants.apiBase}$path');
    final headers = SimklConstants.headers(accessToken: session.accessToken);
    final res = await _http.sendJson(method, uri, headers: headers, body: body, allowedMethods: const {'GET', 'POST'});

    if (res.statusCode == 401) {
      onSessionInvalidated();
      throw const TrackerAuthException(
        service: TrackerService.simkl,
        message: 'Session invalidated (401)',
        statusCode: 401,
        isPermanent: true,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TrackerApiException(service: TrackerService.simkl, statusCode: res.statusCode, body: res.body);
    }
    return TrackerHttpClient.decodeJson(res.body);
  }
}
