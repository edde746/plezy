import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../exceptions/media_server_exceptions.dart';
import '../../utils/app_logger.dart';
import '../../utils/media_server_http_client.dart';
import 'silo_json.dart';

/// Transport for one Silo server's native `/api/v2` contract.
///
/// Contract notes (routes, auth rules, retry classes) live in
/// `docs/silo-native-api.md`; they were taken from the server's committed
/// OpenAPI document and verified against a live server by the Granary client.
///
/// Rules this class enforces:
/// * every call goes to `<baseUrl>/api/v2/<path>`, so reverse-proxy path
///   prefixes work;
/// * a bearer call rejected with 401 is replayed once after a single-flight
///   refresh; a refused refresh ends the session ([MediaServerAuthException]);
///   a 503 during refresh keeps the tokens;
/// * transient failures are retried at most twice, and only for operations
///   the server marks safe to repeat ([SiloRetry]);
/// * tokens never appear in URLs or logs.
class SiloApi {
  SiloApi({
    required String baseUrl,
    required this.identity,
    SiloTokens? tokens,
    this.profileId,
    this.profileToken,
    this.onTokensChanged,
    this.onSessionEnded,
    http.Client? httpClient,
  }) : baseUrl = _stripTrailingSlash(baseUrl),
       _tokens = tokens,
       _http = MediaServerHttpClient(
         client: httpClient,
         baseUrl: '${_stripTrailingSlash(baseUrl)}/api/v2',
         defaultHeaders: identity.headers,
         connectTimeout: const Duration(seconds: 8),
         receiveTimeout: const Duration(seconds: 20),
       );

  /// Server base including any path prefix, without `/api/v2`.
  final String baseUrl;
  final SiloClientIdentity identity;
  final MediaServerHttpClient _http;

  /// Household profile acting for profile-scoped calls (`X-Profile-Id`).
  String? profileId;

  /// PIN proof for a PIN-locked profile (`X-Profile-Token`).
  String? profileToken;

  /// Called after every successful refresh with the rotated pair, so the
  /// owner can persist it before the old refresh token is needed again.
  FutureOr<void> Function(SiloTokens tokens)? onTokensChanged;

  /// Called once when the server refuses the refresh token.
  void Function()? onSessionEnded;

  SiloTokens? _tokens;
  Future<SiloTokens>? _refreshing;
  bool _closed = false;

  SiloTokens? get tokens => _tokens;
  bool get hasSession => _tokens != null;

  static const startTimeout = Duration(seconds: 45);
  static const mutationTimeout = Duration(seconds: 10);
  static const _maxTransientRetries = 2;

  void close() {
    _closed = true;
    _http.close();
  }

  /// Headers every media request (original stream, HLS playlists and
  /// segments, subtitle sidecars) must carry. The server rejects media
  /// requests without the account bearer and the acting profile.
  Map<String, String> get mediaHeaders => {
    ...identity.headers,
    if (_tokens != null) 'Authorization': 'Bearer ${_tokens!.accessToken}',
    if (profileId != null && profileId!.isNotEmpty) 'X-Profile-Id': profileId!,
    if (profileToken != null && profileToken!.isNotEmpty) 'X-Profile-Token': profileToken!,
  };

  /// Resolve a server-relative URL from a response (`/api/v2/...`) under the
  /// server's path prefix. Absolute URLs are returned unchanged.
  String resolveServerUrl(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final base = Uri.parse(baseUrl);
    final prefix = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
    final relative = Uri.parse(value.startsWith('/') ? value : '/$value');
    final alreadyPrefixed = prefix.isNotEmpty && (relative.path == prefix || relative.path.startsWith('$prefix/'));
    final path = alreadyPrefixed ? relative.path : '$prefix${relative.path}';
    // The query is replayed byte-for-byte (signed parameters must not be
    // re-encoded), so the URL is assembled as a string.
    final query = relative.hasQuery ? '?${relative.query}' : '';
    return '${base.scheme}://${base.authority}$path$query';
  }

  /// Whether [url] is on this server's origin (scheme, host and port). Only
  /// such URLs may receive [mediaHeaders].
  bool isSameOrigin(String url) {
    final a = Uri.tryParse(url);
    final b = Uri.tryParse(baseUrl);
    if (a == null || b == null) return false;
    return a.scheme == b.scheme && a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;
  }

  // ------------------------------------------------------------------ calls

  /// Issue one v2 operation and return its decoded JSON body (or `null` for
  /// an empty body). Non-2xx answers throw [MediaServerHttpException] whose
  /// `responseData` is the RFC 9457 problem; read its id with
  /// [siloProblemId].
  Future<dynamic> call(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    bool profileScoped = true,
    SiloRetry retry = SiloRetry.idempotent,
    Duration? timeout,
    AbortController? abort,
  }) async {
    if (_closed) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'Silo client closed');
    }
    if (auth && _tokens == null) {
      throw const MediaServerAuthException('Not signed in to this Silo server', statusCode: 401);
    }
    var response = await _sendWithRetries(
      method,
      path,
      query: query,
      body: body,
      auth: auth,
      profileScoped: profileScoped,
      retry: retry,
      timeout: timeout,
      abort: abort,
    );
    if (auth && response.statusCode == 401) {
      final problem = siloProblemId(response.data);
      appLogger.d('Silo: 401 on $method $path ($problem); refreshing once');
      await _refreshSession(rejectedAccessToken: _tokens?.accessToken);
      response = await _sendWithRetries(
        method,
        path,
        query: query,
        body: body,
        auth: auth,
        profileScoped: profileScoped,
        retry: retry,
        timeout: timeout,
        abort: abort,
      );
    }
    _throwIfError(response);
    return response.data;
  }

  Future<MediaServerResponse> _sendWithRetries(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required bool auth,
    required bool profileScoped,
    required SiloRetry retry,
    Duration? timeout,
    AbortController? abort,
  }) async {
    var attempt = 0;
    while (true) {
      final headers = <String, String>{
        if (auth && _tokens != null) 'Authorization': 'Bearer ${_tokens!.accessToken}',
        if (profileScoped && profileId != null && profileId!.isNotEmpty) 'X-Profile-Id': profileId!,
        if (profileScoped && profileToken != null && profileToken!.isNotEmpty) 'X-Profile-Token': profileToken!,
        'Accept': 'application/json, application/problem+json',
      };
      try {
        final response = await switch (method) {
          'GET' => _http.get(path, queryParameters: query, headers: headers, timeout: timeout, abort: abort),
          'POST' => _http.post(path, queryParameters: query, headers: headers, body: body, timeout: timeout, abort: abort),
          'PUT' => _http.put(path, queryParameters: query, headers: headers, body: body, timeout: timeout, abort: abort),
          'DELETE' => _http.delete(path, queryParameters: query, headers: headers, body: body, timeout: timeout, abort: abort),
          _ => throw ArgumentError.value(method, 'method'),
        };
        _checkRedirect(response);
        final status = response.statusCode;
        final retryable = retry != SiloRetry.never && _isTransientStatus(status) && attempt < _maxTransientRetries;
        if (!retryable) return response;
        await Future<void>.delayed(_retryDelay(attempt, response.headers['retry-after']));
      } on MediaServerHttpException catch (e) {
        final retryable = retry != SiloRetry.never && e.isTransient && attempt < _maxTransientRetries;
        if (!retryable) rethrow;
        await Future<void>.delayed(_retryDelay(attempt, null));
      }
      attempt++;
      abort?.throwIfAborted();
    }
  }

  /// A redirect off this server's origin would have carried the bearer to
  /// another host; refuse to use the answer. (The HTTP stack follows
  /// same-request redirects itself, so this is a post-hoc guard.)
  void _checkRedirect(MediaServerResponse response) {
    final effective = response.effectiveUri;
    if (effective == null) return;
    if (!isSameOrigin(effective.toString())) {
      throw MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        message: 'The Silo server redirected to another origin; the answer was discarded',
      );
    }
  }

  static bool _isTransientStatus(int status) =>
      status == 408 || status == 429 || status == 502 || status == 503 || status == 504;

  static Duration _retryDelay(int attempt, String? retryAfter) {
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null && seconds >= 0) return Duration(seconds: min(seconds, 5));
    return Duration(milliseconds: 250 * pow(4, attempt).toInt());
  }

  void _throwIfError(MediaServerResponse response) {
    if (response.statusCode < 400) return;
    final problem = siloProblemId(response.data);
    if (response.statusCode == 401) {
      throw MediaServerAuthException(
        'Silo refused the session (${problem ?? 'unauthorized'})',
        statusCode: 401,
      );
    }
    throw MediaServerHttpException(
      type: MediaServerHttpErrorType.unknown,
      statusCode: response.statusCode,
      responseData: response.data,
      requestUri: response.requestUri,
      message: problem ?? 'HTTP ${response.statusCode}',
    );
  }

  // ---------------------------------------------------------------- session

  /// Refresh the access token. Concurrent callers share one request. When
  /// [rejectedAccessToken] is no longer current, another caller already
  /// refreshed and the new tokens are used without a second request.
  Future<SiloTokens> _refreshSession({String? rejectedAccessToken}) {
    final current = _tokens;
    if (current == null) {
      return Future.error(const MediaServerAuthException('Not signed in to this Silo server', statusCode: 401));
    }
    if (rejectedAccessToken != null && current.accessToken != rejectedAccessToken) {
      return Future.value(current);
    }
    return _refreshing ??= _doRefresh(current).whenComplete(() => _refreshing = null);
  }

  Future<SiloTokens> _doRefresh(SiloTokens current) async {
    final response = await _sendWithRetries(
      'POST',
      '/auth/refresh',
      body: {'refresh_token': current.refreshToken},
      auth: false,
      profileScoped: false,
      retry: SiloRetry.sameBody,
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      appLogger.w('Silo: refresh refused (${siloProblemId(response.data)}); session ended');
      _tokens = null;
      onSessionEnded?.call();
      throw MediaServerAuthException('Your Silo session ended. Sign in again.', statusCode: 401);
    }
    _throwIfError(response);
    final data = asMap(response.data);
    final next = SiloTokens.fromRefresh(data, previousRefreshToken: current.refreshToken);
    if (next.accessToken.isEmpty) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.unknown, message: 'Silo refresh returned no token');
    }
    _tokens = next;
    try {
      await onTokensChanged?.call(next);
    } catch (e, st) {
      appLogger.w('Silo: persisting rotated tokens failed', error: e, stackTrace: st);
    }
    return next;
  }

  /// Refresh now when the access token expires within [margin]. Playback
  /// calls this before handing [mediaHeaders] to the player, which keeps
  /// using them for the length of the title.
  Future<void> ensureFreshFor(Duration margin) async {
    final current = _tokens;
    if (current == null) return;
    final expiresAt = current.expiresAt;
    if (expiresAt == null) return;
    if (expiresAt.difference(DateTime.now()) > margin) return;
    await _refreshSession(rejectedAccessToken: current.accessToken);
  }

  void installTokens(SiloTokens tokens) => _tokens = tokens;

  // -------------------------------------------------------------- discovery

  Future<Map<String, dynamic>> systemInfo() async =>
      asMap(await call('GET', '/system/info', auth: false, profileScoped: false, timeout: const Duration(seconds: 10)));

  Future<Map<String, dynamic>> serverIdentity() async => asMap(
    await call('GET', '/system/identity', auth: false, profileScoped: false, timeout: const Duration(seconds: 10)),
  );

  Future<Map<String, dynamic>> authProviders() async =>
      asMap(await call('GET', '/auth/providers', auth: false, profileScoped: false));

  // ------------------------------------------------------------------- auth

  /// Password sign-in. Never retried: the server counts failed attempts.
  Future<SiloTokens> login({required String username, required String password}) async {
    final data = asMap(
      await call(
        'POST',
        '/auth/login',
        body: {'username': username, 'password': password},
        auth: false,
        profileScoped: false,
        retry: SiloRetry.never,
      ),
    );
    final tokens = SiloTokens.fromLogin(data);
    _tokens = tokens;
    return tokens;
  }

  /// Revoke this login session on the server. Local state is dropped even
  /// when the server cannot be reached.
  Future<void> logout() async {
    try {
      if (_tokens != null) {
        await call('POST', '/auth/logout', profileScoped: false, timeout: const Duration(seconds: 8));
      }
    } catch (e) {
      appLogger.w('Silo: logout request failed; clearing the local session anyway', error: e);
    } finally {
      _tokens = null;
    }
  }

  Future<Map<String, dynamic>> currentAccount() async => asMap(await call('GET', '/account/me', profileScoped: false));

  Future<List<Map<String, dynamic>>> profiles() async =>
      mapList(asMap(await call('GET', '/profiles', profileScoped: false))['items']);

  /// `{valid, profile_token?, expires_at?}`. A wrong PIN is `valid: false`;
  /// repeated failures lock the profile (429). Never retried.
  Future<Map<String, dynamic>> verifyProfilePin(String profileId, String pin) async => asMap(
    await call(
      'POST',
      '/profiles/${seg(profileId)}/verify-pin',
      body: {'pin': pin},
      profileScoped: false,
      retry: SiloRetry.never,
    ),
  );

  // ---------------------------------------------------------------- catalog

  Future<List<Map<String, dynamic>>> userLibraries() async =>
      mapList(asMap(await call('GET', '/user/libraries'))['items']);

  Future<List<Map<String, dynamic>>> homeSections({String imageSize = 'medium'}) async =>
      mapList(asMap(await call('GET', '/home/sections', query: {'image_size': imageSize}))['sections']);

  Future<Map<String, dynamic>> homeSectionItems(String sectionId, {String imageSize = 'medium'}) async => asMap(
    await call('GET', '/home/sections/${seg(sectionId)}/items', query: {'image_size': imageSize}),
  );

  /// `listCatalogItems`. Keys are the operation's query parameters
  /// (`library_id`, `q`, `type`, `sort`, `limit`, `cursor`, `seek`, ...).
  Future<Map<String, dynamic>> catalog(Map<String, dynamic> query, {AbortController? abort}) async =>
      asMap(await call('GET', '/catalog', query: query, abort: abort));

  Future<Map<String, dynamic>> catalogItem(String contentId, {String imageSize = 'large'}) async => asMap(
    await call('GET', '/catalog/items/${seg(contentId)}', query: {'image_size': imageSize}),
  );

  Future<Map<String, dynamic>> seriesSeasons(String seriesId) async =>
      asMap(await call('GET', '/catalog/series/${seg(seriesId)}/seasons', query: {'image_size': 'medium'}));

  Future<Map<String, dynamic>> seasonEpisodes(String seriesId, int seasonNumber) async => asMap(
    await call(
      'GET',
      '/catalog/series/${seg(seriesId)}/seasons/$seasonNumber/episodes',
      query: {'image_size': 'medium'},
    ),
  );

  /// `getWatchState`: versions, tracks, markers and saved progress.
  Future<Map<String, dynamic>> watchState(String contentId, {String? fileId}) async => asMap(
    await call('GET', '/watch/${seg(contentId)}', query: {if (fileId != null && fileId.isNotEmpty) 'file_id': fileId}),
  );

  Future<void> markWatched(String contentId) =>
      call('POST', '/watched/${seg(contentId)}', retry: SiloRetry.never, timeout: mutationTimeout);

  Future<void> unmarkWatched(String contentId) =>
      call('DELETE', '/watched/${seg(contentId)}', retry: SiloRetry.never, timeout: mutationTimeout);

  // --------------------------------------------------------------- playback

  Future<Map<String, dynamic>> playbackCapabilities() async => asMap(await call('GET', '/playback/capabilities'));

  /// `201` with a decision, including refusals (`adaptation_unavailable`).
  /// The same [body] (same `playback_attempt_id`) is safe to resend.
  Future<Map<String, dynamic>> startPlayback(Map<String, dynamic> body) async =>
      asMap(await call('POST', '/playback/start', body: body, retry: SiloRetry.sameBody, timeout: startTimeout));

  Future<Map<String, dynamic>> replanPlayback(String sessionId, Map<String, dynamic> body) async => asMap(
    await call(
      'POST',
      '/playback/${seg(sessionId)}/replan',
      body: body,
      retry: SiloRetry.sameBody,
      timeout: startTimeout,
    ),
  );

  Future<Map<String, dynamic>> playbackProgress(String sessionId, Map<String, dynamic> body) async => asMap(
    await call(
      'POST',
      '/playback/${seg(sessionId)}/progress',
      body: body,
      retry: SiloRetry.sameBody,
      timeout: mutationTimeout,
    ),
  );

  Future<Map<String, dynamic>> stopPlayback(String sessionId, Map<String, dynamic> body) async => asMap(
    await call('DELETE', '/playback/${seg(sessionId)}', body: body, retry: SiloRetry.sameBody, timeout: mutationTimeout),
  );

  /// Diagnostics only: sent once, failures ignored.
  Future<void> routeEvent(Map<String, dynamic> body) async {
    try {
      await call(
        'POST',
        '/playback/route-events',
        body: body,
        retry: SiloRetry.never,
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      appLogger.d('Silo: route event dropped', error: e);
    }
  }

  static String _stripTrailingSlash(String url) {
    var out = url.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}

/// Retry class from the operation's `x-silo-retry-safety`.
enum SiloRetry {
  /// Reads and naturally idempotent writes.
  idempotent,

  /// `domain_identity`: safe to resend with the identical body.
  sameBody,

  /// `non_retryable`: sent once (sign-in, PIN, mark watched).
  never,
}

class SiloTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  const SiloTokens({required this.accessToken, required this.refreshToken, this.expiresAt});

  factory SiloTokens.fromLogin(Map<String, dynamic> json) => SiloTokens(
    accessToken: str(json['access_token']),
    refreshToken: str(json['refresh_token']),
    expiresAt: _expiry(json['expires_in']),
  );

  factory SiloTokens.fromRefresh(Map<String, dynamic> json, {required String previousRefreshToken}) {
    final rotated = str(json['refresh_token']);
    return SiloTokens(
      accessToken: str(json['access_token']),
      refreshToken: rotated.isEmpty ? previousRefreshToken : rotated,
      expiresAt: _expiry(json['expires_in']),
    );
  }

  static DateTime? _expiry(Object? expiresIn) {
    final seconds = intOrNull(expiresIn);
    return seconds == null || seconds <= 0 ? null : DateTime.now().add(Duration(seconds: seconds));
  }

  @override
  String toString() => 'SiloTokens(<redacted>, expiresAt: $expiresAt)';
}

/// Identity headers sent on every request. Silo lists sign-ins by device in
/// its login-session view.
class SiloClientIdentity {
  final String appName;
  final String appVersion;
  final String deviceId;
  final String deviceName;
  final String platform;

  const SiloClientIdentity({
    required this.appName,
    required this.appVersion,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  Map<String, String> get headers => {
    'X-Silo-Client': appName,
    'X-Silo-Client-Version': appVersion,
    'X-Silo-Device-Id': _safeDeviceId(deviceId),
    'X-Silo-Device-Name': _headerSafe(deviceName),
    'X-Silo-Device-Platform': _headerSafe(platform.toLowerCase()),
  };

  /// `[A-Za-z0-9._:-]{1,128}`.
  static String _safeDeviceId(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '-');
    final clipped = cleaned.length > 128 ? cleaned.substring(0, 128) : cleaned;
    return clipped.isEmpty ? 'plezy-device' : clipped;
  }

  static String _headerSafe(String value) {
    final ascii = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    final clipped = ascii.length > 120 ? ascii.substring(0, 120) : ascii;
    return clipped.isEmpty ? 'Plezy' : clipped;
  }
}

/// Encode one path segment. Silo content ids contain `:` (`movie:heat-1995`),
/// which the server expects literally.
String seg(String value) => Uri.encodeComponent(value).replaceAll('%3A', ':');

/// The stable identifier of an RFC 9457 problem body: the last path segment
/// of its `type` (`.../problems/session_expired` → `session_expired`).
String? siloProblemId(Object? data) {
  if (data is! Map) return null;
  final type = data['type'];
  if (type is! String || type.isEmpty) return null;
  final trimmed = type.endsWith('/') ? type.substring(0, type.length - 1) : type;
  final slash = trimmed.lastIndexOf('/');
  return slash < 0 ? trimmed : trimmed.substring(slash + 1);
}

/// The problem id carried by a failure thrown from [SiloApi.call].
String? siloProblemIdOf(Object error) =>
    error is MediaServerHttpException ? siloProblemId(error.responseData) ?? (error.message.isEmpty ? null : error.message) : null;
