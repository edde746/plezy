import '../tracker_session_utils.dart';

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

  Map<String, dynamic> toJson() => {'access_token': accessToken, 'username': username, 'created_at': createdAt};

  factory SimklSession.fromJson(Map<String, dynamic> json) => SimklSession(
    accessToken: json['access_token'] as String,
    username: json['username'] as String?,
    createdAt: (json['created_at'] as num).toInt(),
  );

  /// Build a session from Simkl's device-code `/oauth/pin/<code>` response.
  /// Simkl doesn't expose a creation timestamp so we stamp "now".
  factory SimklSession.fromTokenResponse(Map<String, dynamic> json) =>
      SimklSession(accessToken: json['access_token'] as String, createdAt: trackerSessionNowEpochSeconds());

  String encode() => encodeTrackerSessionJson(toJson());
  static SimklSession decode(String raw) => decodeTrackerSessionJson(raw, SimklSession.fromJson);
}
