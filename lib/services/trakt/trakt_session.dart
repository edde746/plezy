import '../trackers/tracker_session_utils.dart';

/// Immutable Trakt OAuth session.
///
/// Persisted as a JSON blob under `user_{uuid}_trakt_session` in
/// `SharedPreferences`. Tokens are stored in plaintext, matching the security
/// model of the existing Plex token.
class TraktSession {
  final String accessToken;
  final String refreshToken;

  /// Epoch seconds at which the access token expires.
  final int expiresAt;

  /// Trakt username (`@handle`), populated after `getUserSettings`.
  final String? username;

  final String scope;

  /// Epoch seconds at which the session was first created.
  final int createdAt;

  const TraktSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scope,
    required this.createdAt,
    this.username,
  });

  /// Whether the access token has already expired.
  bool get isExpired => isTrackerTokenExpired(expiresAt);

  /// Whether the access token will expire in the next 5 minutes.
  bool get needsRefresh => trackerTokenNeedsRefresh(expiresAt);

  TraktSession copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresAt,
    String? username,
    String? scope,
    int? createdAt,
  }) {
    return TraktSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'username': username,
    'scope': scope,
    'created_at': createdAt,
  };

  factory TraktSession.fromJson(Map<String, dynamic> json) {
    return TraktSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: (json['expires_at'] as num).toInt(),
      username: json['username'] as String?,
      scope: json['scope'] as String? ?? 'public',
      createdAt: (json['created_at'] as num).toInt(),
    );
  }

  /// Build a session from Trakt's `/oauth/token` or `/oauth/device/token` response,
  /// which uses `expires_in` (relative seconds) rather than `expires_at`.
  factory TraktSession.fromTokenResponse(Map<String, dynamic> json) {
    final createdAt = (json['created_at'] as num?)?.toInt() ?? trackerSessionNowEpochSeconds();
    final expiresIn = (json['expires_in'] as num).toInt();
    return TraktSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: createdAt + expiresIn,
      scope: json['scope'] as String? ?? 'public',
      createdAt: createdAt,
    );
  }

  String encode() => encodeTrackerSessionJson(toJson());
  static TraktSession decode(String raw) => decodeTrackerSessionJson(raw, TraktSession.fromJson);
}
