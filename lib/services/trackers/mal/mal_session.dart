import '../oauth_proxy_client.dart';
import '../tracker_session_utils.dart';

/// Immutable MyAnimeList OAuth session.
///
/// Access tokens expire in ~31 days. Refresh token rotates with each refresh
/// (rare but documented in MAL's API contract).
class MalSession with EncodedTrackerSession {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final String? username;
  final int createdAt;

  const MalSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.createdAt,
    this.username,
  });

  bool get isExpired => isTrackerTokenExpired(expiresAt);
  bool get needsRefresh => trackerTokenNeedsRefresh(expiresAt);

  MalSession copyWith({String? accessToken, String? refreshToken, int? expiresAt, String? username, int? createdAt}) {
    return MalSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'username': username,
    'created_at': createdAt,
  };

  factory MalSession.fromJson(Map<String, dynamic> json) => MalSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresAt: (json['expires_at'] as num).toInt(),
    username: json['username'] as String?,
    createdAt: (json['created_at'] as num).toInt(),
  );

  /// Build a session from MAL's `/oauth2/token` response.
  factory MalSession.fromTokenResponse(Map<String, dynamic> json) {
    final createdAt = trackerSessionNowEpochSeconds();
    final expiresIn = (json['expires_in'] as num).toInt();
    return MalSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: createdAt + expiresIn,
      createdAt: createdAt,
    );
  }

  /// Build a session from an OAuth-proxy result. MAL's refresh_token is
  /// required for the 31-day refresh loop.
  factory MalSession.fromProxyResult(OAuthProxyResult r) {
    final createdAt = trackerSessionNowEpochSeconds();
    final expiresIn = r.expiresIn ?? 31 * 24 * 60 * 60;
    return MalSession(
      accessToken: r.accessToken,
      refreshToken: r.refreshToken ?? '',
      expiresAt: createdAt + expiresIn,
      createdAt: createdAt,
    );
  }

  static MalSession decode(String raw) => decodeTrackerSessionJson(raw, MalSession.fromJson);
}
