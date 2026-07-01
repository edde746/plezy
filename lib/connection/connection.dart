import '../media/media_backend.dart';
import '../models/plex/plex_home_user.dart';
import '../services/plex_auth_service.dart';

/// Identifier of a backend kind a [Connection] points at. Lighter-weight than
/// [MediaBackend] for places that only care about persistence/auth shape
/// (e.g. database column values).
enum ConnectionKind {
  plex,
  jellyfin,
  seerr;

  String get id => switch (this) {
    ConnectionKind.plex => 'plex',
    ConnectionKind.jellyfin => 'jellyfin',
    ConnectionKind.seerr => 'seerr',
  };

  static ConnectionKind fromId(String id) => switch (id) {
    'plex' => ConnectionKind.plex,
    'jellyfin' => ConnectionKind.jellyfin,
    'seerr' => ConnectionKind.seerr,
    _ => throw ArgumentError('Unknown ConnectionKind id: $id'),
  };

  /// Whether this kind backs a playable media library. False for ancillary
  /// services (Seerr, etc.) that share the connection storage but are not
  /// part of the [MediaBackend] consumer surface.
  bool get isMediaBackend => switch (this) {
    ConnectionKind.plex || ConnectionKind.jellyfin => true,
    ConnectionKind.seerr => false,
  };

  MediaBackend get backend => switch (this) {
    ConnectionKind.plex => MediaBackend.plex,
    ConnectionKind.jellyfin => MediaBackend.jellyfin,
    ConnectionKind.seerr => throw StateError('ConnectionKind.seerr has no MediaBackend; gate on isMediaBackend first'),
  };
}

/// Health snapshot for a connection. Updated by the orchestrator each time a
/// session is established or refreshed.
enum ConnectionStatus { unknown, online, offline, authError, disabled }

/// A media server connection — a unit of authentication the user added.
///
/// A `PlexAccountConnection` carries one Plex account + its discovered servers + an
/// optional active Home profile. A `JellyfinConnection` is a single server +
/// user. Most users only ever add one connection.
sealed class Connection {
  String get id;
  ConnectionKind get kind;
  String get displayName;
  ConnectionStatus get status;
  DateTime get createdAt;
  DateTime? get lastAuthenticatedAt;

  /// Backend kind as a [MediaBackend] — for UI that branches on backend
  /// (badges, etc.). Just a passthrough to [kind.backend]. Only valid when
  /// [isMediaBackend] is true; throws for ancillary kinds (e.g. Seerr).
  MediaBackend get backend => kind.backend;

  /// Whether this connection backs a playable media library. False for
  /// ancillary services like Seerr. Use to gate UI that assumes a media
  /// backend (badges, library lookups, server pickers).
  bool get isMediaBackend => kind.isMediaBackend;

  /// Primary label shown in connection-list UIs. Plex shows the active
  /// profile/account name; Jellyfin shows the server name.
  String get displayLabel;

  /// Secondary line shown beneath [displayLabel] in connection-list UIs.
  /// Plex: server count; Jellyfin: `userName · baseUrl`. May be null when
  /// no useful subtitle exists.
  String? get displaySubtitle;

  /// Backend-specific config payload, persisted as JSON. Each subclass
  /// defines the schema.
  Map<String, Object?> toConfigJson();
}

/// A Plex account connection.
///
/// Fields here mirror what [PlexAuthService] gathers during PIN OAuth: an
/// account token (long-lived), the per-device client identifier (so plex.tv
/// doesn't see a "new device" each launch), and the optional Home user the
/// user has switched into.
class PlexAccountConnection extends Connection {
  @override
  final String id;

  @override
  final ConnectionStatus status;

  @override
  final DateTime createdAt;

  @override
  final DateTime? lastAuthenticatedAt;

  /// plex.tv account access token.
  final String accountToken;

  /// Per-device client identifier. Stable across launches.
  final String clientIdentifier;

  /// Display name shown for this connection (typically the Plex account email
  /// or username, fallback "Plex").
  final String accountLabel;

  /// Active Home user, or `null` for the main account.
  final PlexHomeUser? activeProfile;

  /// Servers discovered for this account (cached). Populated by the auth
  /// flow and refreshed periodically.
  final List<PlexServer> servers;

  PlexAccountConnection({
    required this.id,
    required this.accountToken,
    required this.clientIdentifier,
    required this.accountLabel,
    this.activeProfile,
    this.servers = const [],
    this.status = ConnectionStatus.unknown,
    required this.createdAt,
    this.lastAuthenticatedAt,
  });

  @override
  ConnectionKind get kind => ConnectionKind.plex;

  @override
  String get displayName => activeProfile != null && activeProfile!.title.isNotEmpty
      ? '${activeProfile!.title} · $accountLabel'
      : accountLabel;

  @override
  String get displayLabel => displayName;

  @override
  String? get displaySubtitle => servers.length == 1 ? '1 Plex server' : '${servers.length} Plex servers';

  PlexAccountConnection copyWith({
    String? id,
    String? accountToken,
    String? clientIdentifier,
    String? accountLabel,
    PlexHomeUser? activeProfile,
    bool clearActiveProfile = false,
    List<PlexServer>? servers,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    return PlexAccountConnection(
      id: id ?? this.id,
      accountToken: accountToken ?? this.accountToken,
      clientIdentifier: clientIdentifier ?? this.clientIdentifier,
      accountLabel: accountLabel ?? this.accountLabel,
      activeProfile: clearActiveProfile ? null : (activeProfile ?? this.activeProfile),
      servers: servers ?? this.servers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    );
  }

  @override
  Map<String, Object?> toConfigJson() {
    return {
      'accountToken': accountToken,
      'clientIdentifier': clientIdentifier,
      'accountLabel': accountLabel,
      'activeProfile': activeProfile?.toJson(),
      'servers': servers.map((s) => s.toJson()).toList(),
    };
  }

  factory PlexAccountConnection.fromConfigJson({
    required String id,
    required Map<String, Object?> json,
    required ConnectionStatus status,
    required DateTime createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    final profileJson = json['activeProfile'];
    final activeProfile = profileJson is Map<String, dynamic> ? PlexHomeUser.fromJson(profileJson) : null;
    final serversJson = json['servers'];
    final servers = serversJson is List
        ? serversJson.whereType<Map<String, dynamic>>().map(PlexServer.fromJson).toList()
        : <PlexServer>[];
    return PlexAccountConnection(
      id: id,
      accountToken: json['accountToken'] as String? ?? '',
      clientIdentifier: json['clientIdentifier'] as String? ?? '',
      accountLabel: json['accountLabel'] as String? ?? 'Plex',
      activeProfile: activeProfile,
      servers: servers,
      status: status,
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }
}

/// A single-server Jellyfin connection.
class JellyfinConnection extends Connection {
  @override
  final String id;

  @override
  final ConnectionStatus status;

  @override
  final DateTime createdAt;

  @override
  final DateTime? lastAuthenticatedAt;

  /// Active server base URL, no trailing slash. e.g. `https://jellyfin.home.lan`.
  final String baseUrl;

  /// Candidate server URLs for this Jellyfin server, with [baseUrl] first.
  /// Existing installs only have [baseUrl]; deserialization backfills this.
  final List<String> baseUrls;

  /// Server's reported name (System/Info).
  final String serverName;

  /// Server's machine identifier (System/Info `Id`).
  final String serverMachineId;

  /// Authenticated Jellyfin user id (UUID).
  final String userId;

  /// Authenticated user's display name.
  final String userName;

  /// Long-lived access token from `/Users/AuthenticateByName`.
  final String accessToken;

  /// Per-device client identifier (same value sent in the
  /// `Authorization: MediaBrowser DeviceId="..."` header).
  final String deviceId;

  /// Whether this user is a Jellyfin admin (`/Users/{id}.Policy.IsAdministrator`).
  /// Captured at auth time so the UI can gate admin-only entries (delete,
  /// match/unmatch, edit metadata) without an extra round-trip.
  final bool isAdministrator;

  JellyfinConnection({
    required this.id,
    required this.baseUrl,
    List<String>? baseUrls,
    required this.serverName,
    required this.serverMachineId,
    required this.userId,
    required this.userName,
    required this.accessToken,
    required this.deviceId,
    this.isAdministrator = false,
    this.status = ConnectionStatus.unknown,
    required this.createdAt,
    this.lastAuthenticatedAt,
  }) : baseUrls = _normalizeBaseUrls(baseUrl, baseUrls);

  @override
  ConnectionKind get kind => ConnectionKind.jellyfin;

  @override
  String get displayName => '$userName · $serverName';

  @override
  String get displayLabel => serverName;

  @override
  String? get displaySubtitle {
    final extraCount = baseUrls.length - 1;
    final suffix = extraCount > 0 ? ' +$extraCount' : '';
    return '$userName · ${_truncateUrl(baseUrl)}$suffix';
  }

  static String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}…';
  }

  static List<String> _normalizeBaseUrls(String activeBaseUrl, List<String>? urls) {
    final result = <String>[];
    final seen = <String>{};

    void add(String url) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) return;
      result.add(trimmed);
    }

    add(activeBaseUrl);
    for (final url in urls ?? const <String>[]) {
      add(url);
    }
    return List.unmodifiable(result);
  }

  JellyfinConnection copyWith({
    String? id,
    String? baseUrl,
    List<String>? baseUrls,
    String? serverName,
    String? serverMachineId,
    String? userId,
    String? userName,
    String? accessToken,
    String? deviceId,
    bool? isAdministrator,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    final nextBaseUrl = baseUrl ?? this.baseUrl;
    return JellyfinConnection(
      id: id ?? this.id,
      baseUrl: nextBaseUrl,
      baseUrls: baseUrls ?? this.baseUrls,
      serverName: serverName ?? this.serverName,
      serverMachineId: serverMachineId ?? this.serverMachineId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      accessToken: accessToken ?? this.accessToken,
      deviceId: deviceId ?? this.deviceId,
      isAdministrator: isAdministrator ?? this.isAdministrator,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    );
  }

  @override
  Map<String, Object?> toConfigJson() {
    return {
      'baseUrl': baseUrl,
      'baseUrls': baseUrls,
      'serverName': serverName,
      'serverMachineId': serverMachineId,
      'userId': userId,
      'userName': userName,
      'accessToken': accessToken,
      'deviceId': deviceId,
      'isAdministrator': isAdministrator,
    };
  }

  factory JellyfinConnection.fromConfigJson({
    required String id,
    required Map<String, Object?> json,
    required ConnectionStatus status,
    required DateTime createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    final rawBaseUrls = json['baseUrls'];
    final baseUrls = rawBaseUrls is List ? rawBaseUrls.whereType<String>().toList(growable: false) : const <String>[];
    final rawBaseUrl = json['baseUrl'] as String?;
    final baseUrl = rawBaseUrl != null && rawBaseUrl.isNotEmpty
        ? rawBaseUrl
        : (baseUrls.isNotEmpty ? baseUrls.first : '');
    return JellyfinConnection(
      id: id,
      baseUrl: baseUrl,
      baseUrls: baseUrls,
      serverName: json['serverName'] as String? ?? 'Jellyfin',
      serverMachineId: json['serverMachineId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      isAdministrator: json['isAdministrator'] as bool? ?? false,
      status: status,
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }
}

/// A user's authenticated session to a Seerr instance (the Overseerr +
/// Jellyseerr successor at https://seerr.dev). One row per (seerr instance,
/// jellyfin user) — the same Seerr can be backed by multiple Plezy profiles
/// when several Jellyfin users sign in from the same install.
///
/// Seerr is not a media server (it does not stream content) so this kind has
/// `isMediaBackend == false`. It rides the existing [ConnectionRegistry] and
/// [ProfileConnectionRegistry] storage to avoid a parallel schema.
class SeerrConnection extends Connection {
  @override
  final String id;

  @override
  final ConnectionStatus status;

  @override
  final DateTime createdAt;

  @override
  final DateTime? lastAuthenticatedAt;

  /// Base URL of the Seerr instance, no trailing slash. e.g.
  /// `https://requests.example.lan`. All API calls hit `{baseUrl}/api/v1/...`.
  final String baseUrl;

  /// Server-reported application title (from `/api/v1/settings/public`), used
  /// as the primary label in connection-list UIs. Falls back to "Seerr".
  final String instanceLabel;

  /// Jellyfin username used to authenticate. Re-displayed at login and used
  /// for silent re-auth on session expiry.
  final String jellyfinUsername;

  /// Jellyfin password, persisted (encrypted via CredentialVault) so the
  /// client can silently re-auth when Seerr's `connect.sid` cookie expires.
  /// May be empty for legacy rows pre-dating the silent-reauth feature.
  final String jellyfinPassword;

  /// Active Seerr session cookie value (the `connect.sid=...` content),
  /// encrypted at rest. The HTTP client replays this on every authenticated
  /// request as the `Cookie` header.
  final String sessionCookie;

  /// Seerr-side user id. Used to scope `/api/v1/user/{id}/requests`.
  final int seerrUserId;

  /// Permissions bitmask returned by `/auth/me`. Drives feature gates like
  /// "can request 4K".
  final int permissions;

  SeerrConnection({
    required this.id,
    required this.baseUrl,
    required this.instanceLabel,
    required this.jellyfinUsername,
    required this.jellyfinPassword,
    required this.sessionCookie,
    required this.seerrUserId,
    required this.permissions,
    this.status = ConnectionStatus.unknown,
    required this.createdAt,
    this.lastAuthenticatedAt,
  });

  @override
  ConnectionKind get kind => ConnectionKind.seerr;

  @override
  String get displayName => '$jellyfinUsername · $instanceLabel';

  @override
  String get displayLabel => instanceLabel;

  @override
  String? get displaySubtitle => '$jellyfinUsername · ${_truncateSeerrUrl(baseUrl)}';

  static String _truncateSeerrUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}…';
  }

  SeerrConnection copyWith({
    String? id,
    String? baseUrl,
    String? instanceLabel,
    String? jellyfinUsername,
    String? jellyfinPassword,
    String? sessionCookie,
    int? seerrUserId,
    int? permissions,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    return SeerrConnection(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      instanceLabel: instanceLabel ?? this.instanceLabel,
      jellyfinUsername: jellyfinUsername ?? this.jellyfinUsername,
      jellyfinPassword: jellyfinPassword ?? this.jellyfinPassword,
      sessionCookie: sessionCookie ?? this.sessionCookie,
      seerrUserId: seerrUserId ?? this.seerrUserId,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    );
  }

  @override
  Map<String, Object?> toConfigJson() {
    return {
      'baseUrl': baseUrl,
      'instanceLabel': instanceLabel,
      'jellyfinUsername': jellyfinUsername,
      'jellyfinPassword': jellyfinPassword,
      'sessionCookie': sessionCookie,
      'seerrUserId': seerrUserId,
      'permissions': permissions,
    };
  }

  factory SeerrConnection.fromConfigJson({
    required String id,
    required Map<String, Object?> json,
    required ConnectionStatus status,
    required DateTime createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    return SeerrConnection(
      id: id,
      baseUrl: json['baseUrl'] as String? ?? '',
      instanceLabel: json['instanceLabel'] as String? ?? 'Seerr',
      jellyfinUsername: json['jellyfinUsername'] as String? ?? '',
      jellyfinPassword: json['jellyfinPassword'] as String? ?? '',
      sessionCookie: json['sessionCookie'] as String? ?? '',
      seerrUserId: (json['seerrUserId'] as num?)?.toInt() ?? 0,
      permissions: (json['permissions'] as num?)?.toInt() ?? 0,
      status: status,
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }
}
