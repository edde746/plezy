import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../models/simkl/simkl_all_items_entry.dart';
import '../../../models/simkl/simkl_best_item.dart';
import '../../../models/simkl/simkl_detail.dart';
import '../../../models/simkl/simkl_search_result.dart';
import '../../../models/simkl/simkl_trending_item.dart';
import '../tracker_page.dart';

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

  /// Report real-time playback. [action] is `start`, `pause` or `stop`.
  ///
  /// Simkl's own rules, not ours: a `stop` at >= 80% progress marks the item
  /// watched, below that it saves a resumable playback. Only `stop` documents a
  /// 409 (the item was already marked watched within the last hour), so it is
  /// the only action that accepts one as success.
  Future<void> scrobble(String action, Map<String, dynamic> body, {bool allowConflict = false}) =>
      _request('POST', '/scrobble/$action', body: body, allowStatuses: allowConflict ? const {409} : const {});

  Future<void> addRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings', body: body);

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  Future<List<dynamic>> getRatings(String type) async {
    final res = await _request('GET', '/sync/ratings/$type');
    if (res is List) return res;
    if (res is Map && res[type] is List) return res[type] as List<dynamic>;
    return const [];
  }

  // --- Catalog endpoints (Explore tab) ---

  Future<List<SimklTrendingItem>> getTrending(SimklCatalogType type) async {
    final decoded = await _request(
      'GET',
      '/discover/trending/${type.name}/week_100.json',
      baseOverride: SimklConstants.dataBase,
    );
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) SimklTrendingItem.fromJson(item),
    ];
  }

  Future<TrackerPage<SimklSearchResult>> searchCatalog(
    SimklCatalogType type,
    String search, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _requestResponse(
      'GET',
      '/search/${type.searchPath}',
      query: {'q': search, 'page': '${page < 1 ? 1 : page}', 'limit': '${limit.clamp(1, 50)}', 'extended': 'full'},
    );
    final decoded = TrackerHttpClient.decodeJson(response.body);
    final items = [
      if (decoded is List)
        for (final item in decoded)
          if (item is Map<String, dynamic>) SimklSearchResult.fromJson(item),
    ];
    return TrackerPage.fromResponse(response, items);
  }

  Future<List<SimklBestItem>> getBest(SimklCatalogType type, {String filter = 'watched'}) async {
    if (type == SimklCatalogType.movies) {
      throw ArgumentError.value(type, 'type', 'Simkl has no supported best-movies catalog');
    }
    final decoded = await _request('GET', '/${type.name}/best/$filter');
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) SimklBestItem.fromJson(item),
    ];
  }

  Future<SimklAllItems> getAllItems({String type = 'all', String status = 'plantowatch', String? extended}) async {
    final decoded = await _request('GET', '/sync/all-items/$type/$status', query: {'extended': ?extended});
    return decoded is Map<String, dynamic> ? SimklAllItems.fromJson(decoded) : const SimklAllItems();
  }

  Future<void> addToList(Map<String, dynamic> body) async {
    await _request('POST', '/sync/add-to-list', body: body);
  }

  Future<SimklDetail?> getDetail(SimklCatalogType urlType, int simklId) async {
    final decoded = await _request('GET', '/${urlType.detailPath}/$simklId');
    return decoded is Map<String, dynamic> ? SimklDetail.fromJson(decoded) : null;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? baseOverride,
    Set<int> allowStatuses = const {},
  }) async {
    final response = await _requestResponse(
      method,
      path,
      body: body,
      query: query,
      baseOverride: baseOverride,
      allowStatuses: allowStatuses,
    );
    return TrackerHttpClient.decodeJson(response.body);
  }

  Future<http.Response> _requestResponse(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? baseOverride,
    Set<int> allowStatuses = const {},
  }) async {
    final base = baseOverride ?? SimklConstants.apiBase;
    final uri = Uri.parse('$base$path').replace(queryParameters: SimklConstants.queryParameters(query));
    final mainApiHost = uri.host == Uri.parse(SimklConstants.apiBase).host;
    final headers = SimklConstants.headers(accessToken: mainApiHost ? session.accessToken : null);
    final response = await _http.sendJson(
      method,
      uri,
      headers: headers,
      body: body,
      allowedMethods: const {'GET', 'POST'},
    );

    // Only the authenticated host may invalidate: the data host is called
    // without a token, so its 401s say nothing about the session.
    if (mainApiHost && response.statusCode == 401) {
      onSessionInvalidated();
      throw const TrackerAuthException(
        service: TrackerService.simkl,
        message: 'Session invalidated (401)',
        statusCode: 401,
        isPermanent: true,
      );
    }
    if (allowStatuses.contains(response.statusCode)) return response;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TrackerApiException(service: TrackerService.simkl, statusCode: response.statusCode);
    }
    return response;
  }
}
