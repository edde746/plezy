import 'dart:convert';

/// Immutable Simkl OAuth session.
///
/// Simkl access tokens don't expire (per their docs), so there's no
/// refresh_token — just the bearer and a display name for the settings UI.
class SimklSession {
  final String accessToken;
  final String? username;
  final int createdAt;

  const SimklSession({required this.accessToken, required this.createdAt, this.username});

  SimklSession copyWith({String? accessToken, String? username, int? createdAt}) => SimklSession(
    accessToken: accessToken ?? this.accessToken,
    username: username ?? this.username,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'username': username,
    'created_at': createdAt,
  };

  factory SimklSession.fromJson(Map<String, dynamic> json) => SimklSession(
    accessToken: json['access_token'] as String,
    username: json['username'] as String?,
    createdAt: (json['created_at'] as num).toInt(),
  );

  String encode() => json.encode(toJson());
  static SimklSession decode(String raw) => SimklSession.fromJson(json.decode(raw) as Map<String, dynamic>);
}
