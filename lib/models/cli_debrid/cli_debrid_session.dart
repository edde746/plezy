import 'dart:convert';

/// An authenticated cli_debrid connection for one profile: instance URL and
/// the API token minted from cli_debrid's user-management screen.
///
/// Unlike Seerr, cli_debrid auth is a single static token — no password/
/// cookie/re-auth flow. [apiToken] is CredentialVault-protected at the store
/// boundary, mirroring [SeerrSession.secret]'s handling.
class CliDebridSession {
  final String baseUrl;
  final String apiToken;
  final String displayName;
  final int createdAt;

  const CliDebridSession({
    required this.baseUrl,
    required this.apiToken,
    required this.displayName,
    required this.createdAt,
  });

  CliDebridSession copyWith({String? apiToken, String? displayName}) => CliDebridSession(
    baseUrl: baseUrl,
    apiToken: apiToken ?? this.apiToken,
    displayName: displayName ?? this.displayName,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'base_url': baseUrl,
    'api_token': apiToken,
    'display_name': displayName,
    'created_at': createdAt,
  };

  factory CliDebridSession.fromJson(Map<String, Object?> json) => CliDebridSession(
    baseUrl: json['base_url'] as String,
    apiToken: json['api_token'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  );

  String encode() => jsonEncode(toJson());

  static CliDebridSession decode(String raw) =>
      CliDebridSession.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
}
