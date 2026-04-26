import '../media/media_backend.dart';
import '../models/plex/plex_home_user.dart';
import '../services/plex_auth_service.dart';

/// Identifier of a backend kind a [Connection] points at. Lighter-weight than
/// [MediaBackend] for places that only care about persistence/auth shape
/// (e.g. database column values).
enum ConnectionKind {
  plex,
  jellyfin;

  String get id => switch (this) {
    ConnectionKind.plex => 'plex',
    ConnectionKind.jellyfin => 'jellyfin',
  };

  static ConnectionKind fromId(String id) => switch (id) {
    'plex' => ConnectionKind.plex,
    'jellyfin' => ConnectionKind.jellyfin,
    _ => throw ArgumentError('Unknown ConnectionKind id: $id'),
  };

  MediaBackend get backend => switch (this) {
    ConnectionKind.plex => MediaBackend.plex,
    ConnectionKind.jellyfin => MediaBackend.jellyfin,
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
  /// (badges, etc.). Just a passthrough to [kind.backend].
  MediaBackend get backend => kind.backend;

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

  /// Server base URL, no trailing slash. e.g. `https://jellyfin.home.lan`.
  final String baseUrl;

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
  });

  @override
  ConnectionKind get kind => ConnectionKind.jellyfin;

  @override
  String get displayName => '$userName · $serverName';

  @override
  String get displayLabel => serverName;

  @override
  String? get displaySubtitle => '$userName · ${_truncateUrl(baseUrl)}';

  static String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}…';
  }

  JellyfinConnection copyWith({
    String? id,
    String? baseUrl,
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
    return JellyfinConnection(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
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
    return JellyfinConnection(
      id: id,
      baseUrl: json['baseUrl'] as String? ?? '',
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
