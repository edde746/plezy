import 'dart:async';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;

import '../../../models/simkl/simkl_all_items_entry.dart';
import '../../../models/simkl/simkl_best_item.dart';
import '../../../models/simkl/simkl_detail.dart';
import '../../../models/simkl/simkl_search_result.dart';
import '../../../models/simkl/simkl_trending_item.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/serial_future_queue.dart';
import '../future_coalescer.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_page.dart';
import '../tracker_session.dart';
import 'simkl_auth_service.dart';
import 'simkl_constants.dart';

DateTime _systemNow() => clock.now();

/// HTTP wrapper for the Simkl REST API.
///
/// Serves both token generations while AUTH V1 is being retired. The
/// `client_id` always follows the session's token ([SimklConstants.clientIdFor]).
/// AUTH V2 access tokens live seven days: they refresh shortly before expiry
/// or on a 401, retried once, with concurrent refreshes coalesced so this
/// client stays the grant's single refresh owner. Legacy V1 tokens never
/// expire, so a 401 on one is terminal (the user revoked access on simkl.com).
///
/// Writes to the main API host run one at a time, [writeSpacing] apart, since
/// Simkl allows one POST per second per user and extends a throttling block on
/// repeated overages. When Simkl refuses a request (rate limit, daily quota,
/// throttle block, per-user write lock) every main-host request fails fast
/// with [TrackerRateLimitException] until the refusal's hold expires, so a
/// refusal is never answered with more traffic. The public data host is a
/// CDN and is neither paced nor held.
class SimklClient implements DisposableTrackerClient {
  /// `429 rate_limit`: the per-second rate. Clears almost immediately; any
  /// `Retry-After` on it carries the daily reset and is ignored.
  static const Duration _burstHold = Duration(seconds: 2);

  /// `429 user_limit_exceeded`/`app_limit_exceeded` without a usable
  /// `Retry-After`.
  static const Duration _dailyQuotaFallbackHold = Duration(hours: 1);

  /// Any other 429 without a usable `Retry-After`.
  static const Duration _unknownLimitFallbackHold = Duration(seconds: 60);

  /// `412`: a throttling block from repeated POST overages, which more
  /// overages extend.
  static const Duration _throttleBlockHold = Duration(minutes: 5);

  /// `400 RATE_LIMIT`: the previous write for this user still holds Simkl's
  /// 20-second per-user write lock. It clears as soon as that write finishes.
  static const Duration _writeLockHold = Duration(seconds: 5);

  TrackerSession _session;
  final TrackerHttpClient _http;
  SimklAuthService? _authService;
  final void Function() onSessionInvalidated;
  final void Function(TrackerSession session)? onSessionUpdated;
  final Duration _writeSpacing;
  final DateTime Function() _now;

  final _refreshCoalescer = FutureCoalescer<TrackerSession>();
  final _writes = SerialFutureQueue();
  DateTime? _holdUntil;

  SimklClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
    this._authService,
    this._writeSpacing = SimklConstants.writeSpacing,
    DateTime Function()? clock,
  }) : _session = session,
       _http = TrackerHttpClient(logLabel: 'Simkl', httpClient: httpClient),
       _now = clock ?? _systemNow;

  TrackerSession get session => _session;

  bool get _isV2 => SimklConstants.isV2AccessToken(_session.accessToken);

  /// Created on first refresh: legacy sessions and the provider's short-lived
  /// clients never need one.
  SimklAuthService get _auth => _authService ??= SimklAuthService();

  @override
  void dispose() {
    _http.dispose();
    _authService?.dispose();
  }

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

  /// Best-effort server-side revoke of an AUTH V2 grant. Revoking the refresh
  /// token ends both halves. AUTH V1 has no revoke endpoint, so a legacy
  /// session is left alone. Failure is non-fatal: the local session is
  /// already gone by the time this runs, and Simkl answers 200 regardless.
  Future<void> revoke() async {
    final session = _session;
    if (!SimklConstants.isV2AccessToken(session.accessToken)) return;
    try {
      await _http.sendForm(
        'POST',
        Uri.parse(SimklConstants.revokeUrl),
        headers: SimklConstants.oauthHeaders(appVersion: await SimklConstants.appVersion()),
        body: {'client_id': SimklConstants.v2ClientId, 'token': session.refreshToken ?? session.accessToken},
        timeout: TrackerConstants.revokeTimeout,
        operation: 'Simkl token revoke',
        allowedMethods: const {'POST'},
      );
    } catch (e) {
      appLogger.d('Simkl: revoke failed (non-fatal)', error: e);
    }
  }

  Future<TrackerSession> _refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TrackerSession> _doRefresh() async {
    try {
      final fresh = await _auth.refresh(_session);
      _session = fresh;
      onSessionUpdated?.call(fresh);
      return fresh;
    } catch (e) {
      appLogger.w('Simkl: refresh failed', error: e);
      // Only a terminally-invalid grant clears the session; transient 5xx and
      // network failures fall through so a later 401 can retry.
      if (e is TrackerAuthException && e.isPermanent) onSessionInvalidated();
      rethrow;
    }
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
  }) {
    if (baseOverride != null && baseOverride != SimklConstants.apiBase) {
      return _sendToDataHost(method, '$baseOverride$path', query: query);
    }

    Future<http.Response> send() => _sendToApi(method, path, body: body, query: query, allowStatuses: allowStatuses);
    if (method == 'GET') return send();

    final result = _writes.run(send);
    // Hold the queue for the spacing after the write settles, without making
    // its caller wait for it.
    if (_writeSpacing > Duration.zero) unawaited(_writes.run(() => Future<void>.delayed(_writeSpacing)));
    return result;
  }

  /// The public CDN. Called without a token, so its 401s say nothing about
  /// the session, and its refusals say nothing about the API's.
  Future<http.Response> _sendToDataHost(String method, String url, {Map<String, String>? query}) async {
    final appVersion = await SimklConstants.appVersion();
    final clientId = SimklConstants.clientIdFor(_session.accessToken);
    final uri = Uri.parse(url).replace(
      queryParameters: SimklConstants.queryParameters(clientId: clientId, appVersion: appVersion, query: query),
    );
    final response = await _http.sendJson(
      method,
      uri,
      headers: SimklConstants.headers(clientId: clientId, appVersion: appVersion),
      allowedMethods: const {'GET'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TrackerApiException(service: TrackerService.simkl, statusCode: response.statusCode);
    }
    return response;
  }

  Future<http.Response> _sendToApi(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required Set<int> allowStatuses,
  }) async {
    _throwIfHeld();

    if (_isV2 && _session.needsRefresh) {
      try {
        await _refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and retry.
      }
    }

    var sent = await _send(method, path, body: body, query: query);

    if (sent.response.statusCode == 401) {
      if (!SimklConstants.isV2AccessToken(sent.accessToken)) {
        // Legacy V1 tokens never expire: a 401 means the user revoked access.
        _invalidate();
      }
      // A request that raced a refresh already holds a superseded token; it
      // retries with the current one rather than refreshing again, since every
      // refresh kills the grant's previous access token. A failed refresh
      // propagates its TrackerAuthException, matching MDBList and Trakt.
      if (sent.accessToken == _session.accessToken) await _refresh();
      sent = await _send(method, path, body: body, query: query);
      if (sent.response.statusCode == 401) _invalidate();
    }

    final response = sent.response;
    _throwIfRefused(response);
    if (allowStatuses.contains(response.statusCode)) return response;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TrackerApiException(service: TrackerService.simkl, statusCode: response.statusCode);
    }
    return response;
  }

  Future<({http.Response response, String accessToken})> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final appVersion = await SimklConstants.appVersion();
    final accessToken = _session.accessToken;
    final clientId = SimklConstants.clientIdFor(accessToken);
    final uri = Uri.parse('${SimklConstants.apiBase}$path').replace(
      queryParameters: SimklConstants.queryParameters(clientId: clientId, appVersion: appVersion, query: query),
    );
    final response = await _http.sendJson(
      method,
      uri,
      headers: SimklConstants.headers(clientId: clientId, appVersion: appVersion, accessToken: accessToken),
      body: body,
      allowedMethods: const {'GET', 'POST'},
    );
    return (response: response, accessToken: accessToken);
  }

  Never _invalidate() {
    onSessionInvalidated();
    throw const TrackerAuthException(
      service: TrackerService.simkl,
      message: 'Session invalidated (401)',
      statusCode: 401,
      isPermanent: true,
    );
  }

  void _throwIfHeld() {
    final until = _holdUntil;
    if (until == null) return;
    final remaining = until.difference(_now());
    if (remaining <= Duration.zero) {
      _holdUntil = null;
      return;
    }
    throw TrackerRateLimitException(service: TrackerService.simkl, retryAfterSeconds: _ceilSeconds(remaining));
  }

  /// Map Simkl's refusals to a hold and throw. Each wants a different wait,
  /// so the body decides, not the status alone.
  void _throwIfRefused(http.Response response) {
    final (label, hold) = switch (response.statusCode) {
      429 => switch (_errorCode(response)) {
        'rate_limit' => ('per-second rate limit', _burstHold),
        'user_limit_exceeded' => ('daily user quota', _retryAfter(response) ?? _dailyQuotaFallbackHold),
        'app_limit_exceeded' => ('daily app quota', _retryAfter(response) ?? _dailyQuotaFallbackHold),
        _ => ('rate limit', _retryAfter(response) ?? _unknownLimitFallbackHold),
      },
      412 => ('throttle block', _throttleBlockHold),
      400 when _errorCode(response) == 'RATE_LIMIT' => ('per-user write lock', _writeLockHold),
      _ => (null, null),
    };
    if (label == null || hold == null) return;

    final until = _now().add(hold);
    final current = _holdUntil;
    if (current == null || until.isAfter(current)) _holdUntil = until;
    appLogger.w('Simkl: refused (HTTP ${response.statusCode}, $label); holding requests for ${_ceilSeconds(hold)}s');
    throw TrackerRateLimitException(service: TrackerService.simkl, retryAfterSeconds: _ceilSeconds(hold));
  }

  static String? _errorCode(http.Response response) {
    final decoded = TrackerHttpClient.decodeJson(response.body);
    if (decoded is! Map) return null;
    final error = decoded['error'];
    return error is String ? error : null;
  }

  static Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after']?.trim() ?? '');
    return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
  }

  static int _ceilSeconds(Duration duration) => (duration.inMilliseconds + 999) ~/ 1000;
}
