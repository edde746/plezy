import '../media/media_backend.dart';
import '../media/media_browser_dialect.dart';
import '../models/plex/plex_home_user.dart';
import '../services/plex_auth_service.dart';
import '../utils/json_utils.dart';
import '../utils/url_utils.dart';

/// A media server connection — a unit of authentication the user added.
///
/// A `PlexAccountConnection` carries one Plex account + its discovered servers + an
/// optional active Home profile. A `JellyfinConnection` is a single server +
/// user. Most users only ever add one connection.
sealed class Connection {
  String get id;
  MediaBackend get kind;
  String get displayName;
  DateTime get createdAt;
  DateTime? get lastAuthenticatedAt;

  /// Alias for [kind] kept for UI call sites that read "backend"
  /// (badges, etc.).
  MediaBackend get backend => kind;

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
    required this.createdAt,
    this.lastAuthenticatedAt,
  });

  @override
  MediaBackend get kind => MediaBackend.plex;

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
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }
}

/// A single-server connection to a MediaBrowser-family server — Jellyfin or its
/// Emby ancestor. [dialect] selects which of the two wire dialects this
/// connection speaks; every other field has the same meaning on both.
class JellyfinConnection extends Connection {
  @override
  final String id;

  @override
  final DateTime createdAt;

  @override
  final DateTime? lastAuthenticatedAt;

  /// Which MediaBrowser dialect this server speaks. Drives [kind], [backend]
  /// and every route/capability delta in [JellyfinClient].
  final MediaBrowserDialect dialect;

  /// Active server base URL, no trailing slash. e.g. `https://jellyfin.home.lan`.
  final String baseUrl;

  /// Candidate server URLs for this server, with [baseUrl] first.
  /// Existing installs only have [baseUrl]; deserialization backfills this.
  final List<String> baseUrls;

  /// Server's reported name (System/Info).
  final String serverName;

  /// Server's machine identifier (System/Info `Id`).
  final String serverMachineId;

  /// Authenticated user id. A UUID on Jellyfin, an opaque hex string on Emby.
  final String userId;

  final String userName;

  /// Long-lived access token from `/Users/AuthenticateByName`.
  final String accessToken;

  /// Per-device client identifier (same value sent in the
  /// `Authorization: MediaBrowser DeviceId="..."` header).
  final String deviceId;

  /// Whether this user is a server admin (`/Users/{id}.Policy.IsAdministrator`).
  /// Captured at auth time so the UI can gate admin-only entries (delete,
  /// match/unmatch, edit metadata) without an extra round-trip.
  final bool isAdministrator;

  /// The authenticated user's `PrimaryImageTag`, or `null` when they have no
  /// profile picture. The server omits the key entirely in that case, and the
  /// tag is `MD5(imagePath + lastModified)` so it changes on every upload —
  /// which makes the derived avatar URL self-invalidating. Captured at auth
  /// time and refreshed by [JellyfinClient.checkHealth].
  final String? primaryImageTag;

  JellyfinConnection({
    required this.id,
    required String baseUrl,
    List<String>? baseUrls,
    required this.serverName,
    required this.serverMachineId,
    required this.userId,
    required this.userName,
    required this.accessToken,
    required this.deviceId,
    this.dialect = MediaBrowserDialect.jellyfin,
    this.isAdministrator = false,
    this.primaryImageTag,
    required this.createdAt,
    this.lastAuthenticatedAt,
  }) : baseUrl = canonicalizeBaseUrl(baseUrl),
       baseUrls = _normalizeBaseUrls(baseUrl, baseUrls);

  @override
  MediaBackend get kind => dialect.backend;

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
      final normalized = canonicalizeBaseUrl(url);
      if (normalized.isEmpty || !seen.add(normalized)) return;
      result.add(normalized);
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
    MediaBrowserDialect? dialect,
    bool? isAdministrator,
    String? primaryImageTag,

    /// Deleting a profile picture drops `PrimaryImageTag` from the user DTO, so
    /// a refresh must be able to null the cached value — a bare
    /// `primaryImageTag: null` is indistinguishable from "unchanged".
    bool clearPrimaryImageTag = false,
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
      dialect: dialect ?? this.dialect,
      isAdministrator: isAdministrator ?? this.isAdministrator,
      primaryImageTag: clearPrimaryImageTag ? null : (primaryImageTag ?? this.primaryImageTag),
      createdAt: createdAt ?? this.createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    );
  }

  /// The persisted payload deliberately omits [dialect]: the `connections.kind`
  /// column is the authoritative, indexed discriminator and
  /// [JellyfinConnection.fromConfigJson] receives it from there.
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
      'primaryImageTag': primaryImageTag,
    };
  }

  factory JellyfinConnection.fromConfigJson({
    required String id,
    required Map<String, Object?> json,
    required DateTime createdAt,
    DateTime? lastAuthenticatedAt,
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
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
      dialect: dialect,
      serverName: json['serverName'] as String? ?? dialect.productName,
      serverMachineId: json['serverMachineId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      isAdministrator: json['isAdministrator'] as bool? ?? false,
      primaryImageTag: normalizePrimaryImageTag(json['primaryImageTag']),
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }

  /// Tolerant read of a Jellyfin user DTO's `PrimaryImageTag`.
  ///
  /// The tag is decorative — a fork or a drifted scalar type must never brick
  /// sign-in — so this coerces through [readStringField] rather than casting,
  /// and collapses absent/blank to `null` ("no picture").
  static String? readPrimaryImageTag(Map<String, Object?> userDto) =>
      normalizePrimaryImageTag(readStringField(userDto, 'PrimaryImageTag'));

  static String? normalizePrimaryImageTag(Object? raw) {
    final tag = raw?.toString().trim();
    return tag == null || tag.isEmpty ? null : tag;
  }
}

/// A connection to one Silo server through its native `/api/v2` contract,
/// signed in as one account and acting as one of its household profiles.
///
/// The id is `{serverId}/{profileId}` so two Plezy profiles bound to two Silo
/// profiles on the same server keep separate rows, caches and progress (the
/// same compound shape [JellyfinConnection] uses for its users).
///
/// [refreshToken] rotates on every refresh, so the client persists the
/// updated connection through `MultiServerManager.onSiloConnectionUpdated`.
/// [profileToken] proves a PIN for a PIN-locked profile and expires; once it
/// does the server refuses profile-scoped calls and the user signs in again.
class SiloConnection extends Connection {
  @override
  final String id;

  @override
  final DateTime createdAt;

  @override
  final DateTime? lastAuthenticatedAt;

  /// Server base URL including any reverse-proxy path prefix, without the
  /// `/api/v2` suffix and without a trailing slash.
  final String baseUrl;

  /// `server_id` from `GET /api/v2/system/identity`: the deployment's stable
  /// identity at every address. Used as the public [ServerId].
  final String serverId;
  final String serverName;

  final String accountId;
  final String userName;

  /// Server role of the account (`admin`, `user`, ...).
  final String role;

  final String profileId;
  final String profileName;

  final String accessToken;
  final String refreshToken;

  /// When [accessToken] stops being accepted.
  final DateTime? accessTokenExpiresAt;

  final String? profileToken;
  final DateTime? profileTokenExpiresAt;

  /// Per-installation device id sent as `X-Silo-Device-Id`.
  final String deviceId;

  SiloConnection({
    required this.serverId,
    required String baseUrl,
    required this.serverName,
    required this.accountId,
    required this.userName,
    required this.profileId,
    required this.profileName,
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
    required this.createdAt,
    this.role = '',
    this.accessTokenExpiresAt,
    this.profileToken,
    this.profileTokenExpiresAt,
    this.lastAuthenticatedAt,
    String? id,
  }) : id = id ?? siloConnectionId(serverId: serverId, profileId: profileId),
       baseUrl = canonicalizeBaseUrl(baseUrl);

  static String siloConnectionId({required String serverId, required String profileId}) => '$serverId/$profileId';

  @override
  MediaBackend get kind => MediaBackend.silo;

  @override
  String get displayName => '$profileName · $serverName';

  @override
  String get displayLabel => serverName;

  @override
  String? get displaySubtitle => '$profileName · $userName';

  bool get isAdministrator => role == 'admin';

  SiloConnection copyWith({
    String? baseUrl,
    String? serverName,
    String? userName,
    String? role,
    String? profileName,
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    String? profileToken,
    DateTime? profileTokenExpiresAt,
    bool clearProfileToken = false,
    DateTime? lastAuthenticatedAt,
  }) {
    return SiloConnection(
      id: id,
      serverId: serverId,
      baseUrl: baseUrl ?? this.baseUrl,
      serverName: serverName ?? this.serverName,
      accountId: accountId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      profileId: profileId,
      profileName: profileName ?? this.profileName,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      profileToken: clearProfileToken ? null : (profileToken ?? this.profileToken),
      profileTokenExpiresAt: clearProfileToken ? null : (profileTokenExpiresAt ?? this.profileTokenExpiresAt),
      deviceId: deviceId,
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    );
  }

  @override
  Map<String, Object?> toConfigJson() {
    return {
      'baseUrl': baseUrl,
      'serverId': serverId,
      'serverName': serverName,
      'accountId': accountId,
      'userName': userName,
      'role': role,
      'profileId': profileId,
      'profileName': profileName,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresAt': accessTokenExpiresAt?.toUtc().toIso8601String(),
      'profileToken': profileToken,
      'profileTokenExpiresAt': profileTokenExpiresAt?.toUtc().toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory SiloConnection.fromConfigJson({
    required String id,
    required Map<String, Object?> json,
    required DateTime createdAt,
    DateTime? lastAuthenticatedAt,
  }) {
    String str(String key) => json[key] is String ? json[key] as String : '';
    DateTime? date(String key) => json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    final profileToken = str('profileToken');
    return SiloConnection(
      id: id,
      serverId: str('serverId'),
      baseUrl: str('baseUrl'),
      serverName: str('serverName').isEmpty ? 'Silo' : str('serverName'),
      accountId: str('accountId'),
      userName: str('userName'),
      role: str('role'),
      profileId: str('profileId'),
      profileName: str('profileName'),
      accessToken: str('accessToken'),
      refreshToken: str('refreshToken'),
      accessTokenExpiresAt: date('accessTokenExpiresAt'),
      profileToken: profileToken.isEmpty ? null : profileToken,
      profileTokenExpiresAt: date('profileTokenExpiresAt'),
      deviceId: str('deviceId'),
      createdAt: createdAt,
      lastAuthenticatedAt: lastAuthenticatedAt,
    );
  }
}
