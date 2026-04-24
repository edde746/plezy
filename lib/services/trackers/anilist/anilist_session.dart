import 'dart:convert';

/// Immutable AniList OAuth session.
///
/// Implicit grant — no refresh token. Tokens are valid for 1 year; on expiry
/// the user must re-auth.
class AnilistSession {
  final String accessToken;
  final int expiresAt;
  final String? username;
  final int createdAt;

  const AnilistSession({
    required this.accessToken,
    required this.expiresAt,
    required this.createdAt,
    this.username,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;

  AnilistSession copyWith({String? accessToken, int? expiresAt, String? username, int? createdAt}) {
    return AnilistSession(
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'expires_at': expiresAt,
    'username': username,
    'created_at': createdAt,
  };

  factory AnilistSession.fromJson(Map<String, dynamic> json) => AnilistSession(
    accessToken: json['access_token'] as String,
    expiresAt: (json['expires_at'] as num).toInt(),
    username: json['username'] as String?,
    createdAt: (json['created_at'] as num).toInt(),
  );

  String encode() => json.encode(toJson());
  static AnilistSession decode(String raw) => AnilistSession.fromJson(json.decode(raw) as Map<String, dynamic>);
}
