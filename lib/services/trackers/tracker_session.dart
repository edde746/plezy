import 'oauth_proxy_client.dart';
import 'tracker_constants.dart';
import 'tracker_exceptions.dart';
import 'tracker_session_utils.dart';

class TrackerSession with EncodedTrackerSession {
  final String accessToken;
  final String? refreshToken;
  final int? expiresAt;
  final String? username;
  final int createdAt;
  final String? scope;

  const TrackerSession({
    required this.accessToken,
    required this.createdAt,
    this.refreshToken,
    this.expiresAt,
    this.username,
    this.scope,
  });

  bool get isExpired => expiresAt != null && isTrackerTokenExpired(expiresAt!);
  bool get needsRefresh => expiresAt != null && trackerTokenNeedsRefresh(expiresAt!);

  String requireRefreshToken(TrackerService service) => _requireRefreshToken(service, refreshToken);

  TrackerSession copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresAt,
    String? username,
    int? createdAt,
    String? scope,
  }) {
    return TrackerSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      scope: scope ?? this.scope,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'username': username,
    'scope': scope,
    'created_at': createdAt,
  };

  factory TrackerSession.fromJson(Map<String, dynamic> json, {TrackerService? service}) {
    final session = TrackerSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: (json['expires_at'] as num?)?.toInt(),
      username: json['username'] as String?,
      scope: json['scope'] as String? ?? (service == TrackerService.trakt ? 'public' : null),
      createdAt: (json['created_at'] as num).toInt(),
    );
    // When decoding a persisted blob we know the service, so re-impose the
    // per-service invariants the old json_serializable decoders guaranteed.
    // A corrupt/truncated blob then throws (and TrackerAccountStore.load's
    // catch falls back to a clean re-auth) rather than loading a broken,
    // never-expiring session.
    if (service != null) session._validatePersisted(service);
    return session;
  }

  void _validatePersisted(TrackerService service) {
    void requireExpiry() {
      if (expiresAt == null) {
        throw TrackerAuthException(service: service, message: 'Corrupt persisted session', isPermanent: true);
      }
    }

    switch (service) {
      case TrackerService.mal:
      case TrackerService.trakt:
        _validateRefreshToken(service, refreshToken);
        requireExpiry();
      case TrackerService.anilist:
        requireExpiry();
      case TrackerService.simkl:
        return;
    }
  }

  factory TrackerSession.fromOAuthProxyResult(TrackerService service, OAuthProxyResult result) {
    final createdAt = trackerSessionNowEpochSeconds();
    return switch (service) {
      TrackerService.anilist => TrackerSession(
        accessToken: result.accessToken,
        expiresAt: createdAt + (result.expiresIn ?? 365 * 24 * 60 * 60),
        createdAt: createdAt,
      ),
      TrackerService.mal => TrackerSession(
        accessToken: result.accessToken,
        refreshToken: _requireRefreshToken(service, result.refreshToken),
        expiresAt: createdAt + (result.expiresIn ?? 31 * 24 * 60 * 60),
        createdAt: createdAt,
      ),
      _ => throw ArgumentError('OAuth proxy sessions are not supported for ${service.name}'),
    };
  }

  factory TrackerSession.fromTokenResponse(TrackerService service, Map<String, dynamic> json) {
    final createdAt = (json['created_at'] as num?)?.toInt() ?? trackerSessionNowEpochSeconds();
    return switch (service) {
      TrackerService.mal => TrackerSession(
        accessToken: json['access_token'] as String,
        refreshToken: _requireRefreshToken(service, json['refresh_token'] as String?),
        expiresAt: createdAt + (json['expires_in'] as num).toInt(),
        createdAt: createdAt,
      ),
      TrackerService.simkl => TrackerSession(accessToken: json['access_token'] as String, createdAt: createdAt),
      TrackerService.trakt => TrackerSession(
        accessToken: json['access_token'] as String,
        refreshToken: _requireRefreshToken(service, json['refresh_token'] as String?),
        expiresAt: createdAt + (json['expires_in'] as num).toInt(),
        scope: json['scope'] as String? ?? 'public',
        createdAt: createdAt,
      ),
      _ => throw ArgumentError('Token-response sessions are not supported for ${service.name}'),
    };
  }

  static void _validateRefreshToken(TrackerService service, String? token) {
    // Reject empty as well as null: a blank refresh token can never refresh, so
    // failing fast (at connect, or as a clean re-auth on load) is more correct
    // than persisting a session that is silently doomed at the next expiry. The
    // connect-time factories route through here too, so new sessions can never
    // reach the persisted empty-token state the old decoders tolerated.
    if (token == null || token.isEmpty) {
      throw TrackerAuthException(service: service, message: 'Missing refresh token', isPermanent: true);
    }
  }

  static String _requireRefreshToken(TrackerService service, String? token) {
    _validateRefreshToken(service, token);
    return token!;
  }

  static TrackerSession decode(String raw, {TrackerService? service}) =>
      decodeTrackerSessionJson(raw, (json) => TrackerSession.fromJson(json, service: service));
}
