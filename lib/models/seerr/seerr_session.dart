import 'dart:convert';

/// How the session was established — determines how a silent re-login is
/// performed when the server-side session expires.
enum SeerrAuthMethod {
  /// `POST /auth/plex` with the profile's Plex account token (read live at
  /// re-auth time, never copied into the session).
  plex,

  /// `POST /auth/jellyfin` with stored username/password, serverType 2.
  jellyfin,

  /// `POST /auth/jellyfin` with stored username/password, serverType 3.
  emby,

  /// `POST /auth/local` with stored email/password.
  local,
}

/// Which Seerr product the instance runs. The two products disagree on
/// `MediaStatus` wire codes 6/7 (see `SeerrMediaStatus.resolve`), so decoding
/// needs this context.
///
/// Derived from the *presence* of `mediaServerType` in `/settings/public`:
/// Jellyseerr/Seerr always send a numeric value (4 = NOT_CONFIGURED even
/// before setup), while Overseerr's `FullPublicSettings` has no such key.
/// Titles, URLs, and version strings are user-editable and untrustworthy.
enum SeerrProduct {
  overseerr,
  jellyseerr,

  /// Sessions persisted before the discriminator existed. Codes 6/7 decode
  /// to `blocklisted` (not available, not requestable — safe under either
  /// product) until the next `/settings/public` fetch refreshes the flag.
  unknown,
}

/// An authenticated Seerr session for one profile: instance URL, the Express
/// session cookie, the credentials needed to re-login silently, and the
/// Seerr-side user it maps to.
///
/// [secret] is the plaintext password while in memory; the store protects it
/// with CredentialVault before persisting. Empty for [SeerrAuthMethod.plex]
/// and after an unrecoverable decrypt failure (session then lives until the
/// cookie expires and the user must reconnect).
class SeerrSession {
  final String baseUrl;
  final SeerrAuthMethod method;

  /// Username (jellyfin/emby) or email (local); empty for plex.
  final String identifier;
  final String secret;

  /// `connect.sid` cookie value.
  final String cookie;
  final int userId;

  /// Seerr permission bitmask — see `SeerrPermission`.
  final int permissions;
  final String displayName;

  /// Instance `applicationTitle` from `/settings/public`.
  final String instanceLabel;

  /// Product discriminator captured from `/settings/public`; [SeerrProduct.unknown]
  /// for sessions persisted before it existed, until a settings fetch
  /// refreshes it.
  final SeerrProduct product;
  final int createdAt;

  const SeerrSession({
    required this.baseUrl,
    required this.method,
    required this.identifier,
    required this.secret,
    required this.cookie,
    required this.userId,
    required this.permissions,
    required this.displayName,
    required this.instanceLabel,
    this.product = SeerrProduct.unknown,
    required this.createdAt,
  });

  SeerrSession copyWith({
    String? secret,
    String? cookie,
    int? permissions,
    String? displayName,
    String? instanceLabel,
    SeerrProduct? product,
  }) => SeerrSession(
    baseUrl: baseUrl,
    method: method,
    identifier: identifier,
    secret: secret ?? this.secret,
    cookie: cookie ?? this.cookie,
    userId: userId,
    permissions: permissions ?? this.permissions,
    displayName: displayName ?? this.displayName,
    instanceLabel: instanceLabel ?? this.instanceLabel,
    product: product ?? this.product,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'base_url': baseUrl,
    'method': method.name,
    'identifier': identifier,
    'secret': secret,
    'cookie': cookie,
    'user_id': userId,
    'permissions': permissions,
    'display_name': displayName,
    'instance_label': instanceLabel,
    'product': product.name,
    'created_at': createdAt,
  };

  factory SeerrSession.fromJson(Map<String, Object?> json) => SeerrSession(
    baseUrl: json['base_url'] as String,
    // An unknown method must not fall back to another (re-auth would post
    // garbage credentials); the store's decode try/catch drops the session.
    method:
        SeerrAuthMethod.values.asNameMap()[json['method']] ??
        (throw ArgumentError('Unknown Seerr auth method: ${json['method']}')),
    identifier: json['identifier'] as String? ?? '',
    secret: json['secret'] as String? ?? '',
    cookie: json['cookie'] as String? ?? '',
    userId: (json['user_id'] as num).toInt(),
    permissions: (json['permissions'] as num?)?.toInt() ?? 0,
    displayName: json['display_name'] as String? ?? '',
    instanceLabel: json['instance_label'] as String? ?? '',
    // Legacy sessions predate the discriminator: decode conservatively as
    // unknown; the next /settings/public fetch refreshes and persists it.
    product: SeerrProduct.values.asNameMap()[json['product']] ?? SeerrProduct.unknown,
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  );

  String encode() => jsonEncode(toJson());

  static SeerrSession decode(String raw) => SeerrSession.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
}
