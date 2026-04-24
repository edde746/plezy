import 'dart:convert';

import '../oauth_proxy_client.dart';

/// Immutable MyAnimeList OAuth session.
///
/// Access tokens expire in ~31 days. Refresh token rotates with each refresh
/// (rare but documented in MAL's API contract).
class MalSession {
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

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
  bool get needsRefresh => DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt - 300;

  MalSession copyWith({String? accessToken, String? refreshToken, int? expiresAt, String? username, int? createdAt}) {
    return MalSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresIn = r.expiresIn ?? 31 * 24 * 60 * 60;
    return MalSession(
      accessToken: r.accessToken,
      refreshToken: r.refreshToken ?? '',
      expiresAt: createdAt + expiresIn,
      createdAt: createdAt,
    );
  }

  String encode() => json.encode(toJson());
  static MalSession decode(String raw) => MalSession.fromJson(json.decode(raw) as Map<String, dynamic>);
}
