import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/jellyfin/bonfire_profile.dart';
import '../models/plex/plex_home_user.dart';

part 'profile.freezed.dart';

/// Top-level profile — the user-facing identity in the app.
///
/// Three kinds:
/// - [LocalProfile]: a Plezy-only profile created by the user. May have
///   an optional 4-digit PIN.
/// - [PlexHomeProfile]: auto-surfaced from a connected Plex account's
///   Home users. PIN protection is handled server-side by Plex via the
///   `/home/users/{uuid}/switch` flow — `pinHash` is unused.
/// - [JellyfinBonfireProfile]: auto-surfaced from a Jellyfin server that has
///   the Bonfire/JellyProfiles plugin installed. PIN protection is handled
///   server-side by the plugin via `POST /plugins/profiles/switch` —
///   `pinHash` is unused.
///
/// A profile owns 1+ connections via the `profile_connections` join table.
/// The join row carries the per-profile user-level token used to talk to
/// each connection.
@freezed
sealed class Profile with _$Profile {
  const Profile._();

  const factory Profile.local({
    required String id,
    required String displayName,
    String? avatarThumbUrl,

    /// Hashed PIN if set. The raw PIN is never persisted; see [computePinHash].
    String? pinHash,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? lastUsedAt,
  }) = LocalProfile;

  const factory Profile.plexHome({
    required String id,
    required String displayName,
    String? avatarThumbUrl,

    /// The parent Plex account's connection id.
    String? parentConnectionId,

    /// The Plex Home user UUID. Used by the active-profile binder to call
    /// `/home/users/{uuid}/switch`.
    String? plexHomeUserUuid,
    @Default(false) bool plexRestricted,
    @Default(false) bool plexAdmin,

    /// Plex's `protected` flag — true when the home user has a PIN that must
    /// be entered before `/home/users/{uuid}/switch` will succeed.
    @Default(false) bool plexProtected,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? lastUsedAt,
  }) = PlexHomeProfile;

  const factory Profile.jellyfinBonfire({
    required String id,
    required String displayName,
    String? avatarThumbUrl,

    /// The parent Jellyfin connection's id (the token that can authorize a
    /// profile switch — usually the master user's connection).
    String? parentConnectionId,

    /// The Bonfire profile's Jellyfin user id (GUID). Used by the binder to
    /// call `POST /plugins/profiles/switch`.
    String? bonfireUserId,

    /// Bonfire's `isMaster` — the household owner profile.
    @Default(false) bool bonfireIsMaster,

    /// Bonfire's `isAdministrator` — a UI warning signal only, never an
    /// authorisation signal.
    @Default(false) bool bonfireIsAdministrator,

    /// Bonfire's `requiresPin` — a PIN must be entered to switch into this
    /// profile right now (already false on the LAN when the server has
    /// `bypassPinOnLocalNetwork`). Drives the prompt.
    @Default(false) bool bonfireRequiresPin,

    /// Bonfire's `hasPin` — a PIN is configured at all. Drives display only
    /// (shield icon); never prompt from this.
    @Default(false) bool bonfireHasPin,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? lastUsedAt,
  }) = JellyfinBonfireProfile;

  /// Construct an in-memory virtual `Profile` for a Plex Home user. These
  /// are never persisted — Plex owns the Home user list, so the picker
  /// reads them live from [PlexHomeService] and merges them with the local
  /// rows from `ProfileRegistry`.
  factory Profile.virtualPlexHome({
    required String connectionId,
    required PlexHomeUser homeUser,
    DateTime? lastUsedAt,
  }) => Profile.plexHome(
    id: plexHomeProfileId(accountConnectionId: connectionId, homeUserUuid: homeUser.uuid),
    displayName: homeUser.displayName,
    avatarThumbUrl: homeUser.thumb.isNotEmpty ? homeUser.thumb : null,
    parentConnectionId: connectionId,
    plexHomeUserUuid: homeUser.uuid,
    plexRestricted: homeUser.restricted,
    plexAdmin: homeUser.admin,
    plexProtected: homeUser.protected,
    sortOrder: homeUser.admin ? 0 : 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    lastUsedAt: lastUsedAt,
  );

  /// Construct an in-memory virtual `Profile` for a Bonfire/JellyProfiles
  /// profile. Like [Profile.virtualPlexHome], these are never persisted —
  /// the plugin owns the profile list, so the picker reads them live from
  /// [BonfireProfileService] and merges them with the local rows from
  /// `ProfileRegistry`. [serverBaseUrl] resolves the plugin's relative
  /// profile-image path to a thumb URL.
  factory Profile.virtualJellyfinBonfire({
    required String connectionId,
    required BonfireProfile profile,
    required String serverBaseUrl,
    DateTime? lastUsedAt,
  }) => Profile.jellyfinBonfire(
    id: bonfireProfileId(connectionId: connectionId, bonfireUserId: profile.profileUserId),
    displayName: profile.displayName,
    avatarThumbUrl: profile.imageUrlFor(serverBaseUrl),
    parentConnectionId: connectionId,
    bonfireUserId: profile.profileUserId,
    bonfireIsMaster: profile.isMaster,
    bonfireIsAdministrator: profile.isAdministrator,
    bonfireRequiresPin: profile.requiresPin,
    bonfireHasPin: profile.hasPin,
    // Master first, then the plugin's own household order (masters sort 0).
    sortOrder: profile.isMaster ? 0 : 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    lastUsedAt: lastUsedAt,
  );

  factory Profile.fromRow({
    required String id,
    required String kind,
    required String displayName,
    required String? avatarThumbUrl,
    required Map<String, Object?> json,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime? lastUsedAt,
  }) {
    final parsedKind = ProfileKind.fromId(kind);
    return switch (parsedKind) {
      ProfileKind.local => Profile.local(
        id: id,
        displayName: displayName,
        avatarThumbUrl: avatarThumbUrl,
        pinHash: json['pinHash'] as String?,
        sortOrder: sortOrder,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt,
      ),
      ProfileKind.plexHome => Profile.plexHome(
        id: id,
        displayName: displayName,
        avatarThumbUrl: avatarThumbUrl,
        parentConnectionId: json['parentConnectionId'] as String?,
        plexRestricted: json['restricted'] as bool? ?? false,
        plexAdmin: json['admin'] as bool? ?? false,
        plexProtected: (json['protected'] as bool?) ?? (json['hasPassword'] as bool? ?? false),
        sortOrder: sortOrder,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt,
      ),
      ProfileKind.jellyfinBonfire => Profile.jellyfinBonfire(
        id: id,
        displayName: displayName,
        avatarThumbUrl: avatarThumbUrl,
        parentConnectionId: json['parentConnectionId'] as String?,
        bonfireUserId: json['bonfireUserId'] as String?,
        bonfireIsMaster: json['bonfireIsMaster'] as bool? ?? false,
        bonfireIsAdministrator: json['bonfireIsAdministrator'] as bool? ?? false,
        bonfireRequiresPin: json['bonfireRequiresPin'] as bool? ?? false,
        bonfireHasPin: json['bonfireHasPin'] as bool? ?? false,
        sortOrder: sortOrder,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt,
      ),
    };
  }

  bool get isLocal => this is LocalProfile;
  bool get isPlexHome => this is PlexHomeProfile;
  bool get isJellyfinBonfire => this is JellyfinBonfireProfile;

  ProfileKind get kind => switch (this) {
    LocalProfile() => ProfileKind.local,
    PlexHomeProfile() => ProfileKind.plexHome,
    JellyfinBonfireProfile() => ProfileKind.jellyfinBonfire,
  };

  /// True when entering this profile requires user-supplied PIN.
  ///
  /// Locals: gated by their own [pinHash].
  /// Plex Home: gated by Plex's own protected flag (`plexProtected`).
  /// Bonfire: gated by the plugin's live `requiresPin` (already false on the
  /// LAN when the server bypasses PINs for local networks).
  bool get isPinProtected => switch (this) {
    LocalProfile(:final pinHash) => pinHash != null && pinHash.isNotEmpty,
    PlexHomeProfile(:final plexProtected) => plexProtected,
    JellyfinBonfireProfile(:final bonfireRequiresPin) => bonfireRequiresPin,
  };

  /// Hashed PIN, only set for [LocalProfile]. Returns null for plexHome and
  /// jellyfinBonfire — both delegate PINs to the server.
  String? get pinHash => switch (this) {
    LocalProfile(:final pinHash) => pinHash,
    PlexHomeProfile() => null,
    JellyfinBonfireProfile() => null,
  };

  /// Parent account connection id, only set for [PlexHomeProfile] and
  /// [JellyfinBonfireProfile].
  String? get parentConnectionId => switch (this) {
    LocalProfile() => null,
    PlexHomeProfile(:final parentConnectionId) => parentConnectionId,
    JellyfinBonfireProfile(:final parentConnectionId) => parentConnectionId,
  };

  /// Plex Home user UUID, only set for [PlexHomeProfile].
  String? get plexHomeUserUuid => switch (this) {
    LocalProfile() => null,
    PlexHomeProfile(:final plexHomeUserUuid) => plexHomeUserUuid,
    JellyfinBonfireProfile() => null,
  };

  bool get plexRestricted => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile(:final plexRestricted) => plexRestricted,
    JellyfinBonfireProfile() => false,
  };

  bool get plexAdmin => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile(:final plexAdmin) => plexAdmin,
    JellyfinBonfireProfile() => false,
  };

  bool get plexProtected => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile(:final plexProtected) => plexProtected,
    JellyfinBonfireProfile() => false,
  };

  /// Bonfire profile user id (GUID), only set for [JellyfinBonfireProfile].
  String? get bonfireUserId => switch (this) {
    LocalProfile() => null,
    PlexHomeProfile() => null,
    JellyfinBonfireProfile(:final bonfireUserId) => bonfireUserId,
  };

  bool get bonfireIsMaster => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile() => false,
    JellyfinBonfireProfile(:final bonfireIsMaster) => bonfireIsMaster,
  };

  bool get bonfireIsAdministrator => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile() => false,
    JellyfinBonfireProfile(:final bonfireIsAdministrator) => bonfireIsAdministrator,
  };

  bool get bonfireRequiresPin => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile() => false,
    JellyfinBonfireProfile(:final bonfireRequiresPin) => bonfireRequiresPin,
  };

  bool get bonfireHasPin => switch (this) {
    LocalProfile() => false,
    PlexHomeProfile() => false,
    JellyfinBonfireProfile(:final bonfireHasPin) => bonfireHasPin,
  };

  Map<String, Object?> toConfigJson() => switch (this) {
    LocalProfile(:final pinHash) => {'pinHash': pinHash},
    PlexHomeProfile(:final parentConnectionId, :final plexRestricted, :final plexAdmin, :final plexProtected) => {
      'parentConnectionId': parentConnectionId,
      'restricted': plexRestricted,
      'admin': plexAdmin,
      'protected': plexProtected,
    },
    JellyfinBonfireProfile(
      :final parentConnectionId,
      :final bonfireUserId,
      :final bonfireIsMaster,
      :final bonfireIsAdministrator,
      :final bonfireRequiresPin,
      :final bonfireHasPin,
    ) =>
      {
        'parentConnectionId': parentConnectionId,
        'bonfireUserId': bonfireUserId,
        'bonfireIsMaster': bonfireIsMaster,
        'bonfireIsAdministrator': bonfireIsAdministrator,
        'bonfireRequiresPin': bonfireRequiresPin,
        'bonfireHasPin': bonfireHasPin,
      },
  };
}

enum ProfileKind {
  local,
  plexHome,
  jellyfinBonfire;

  String get id => switch (this) {
    ProfileKind.local => 'local',
    ProfileKind.plexHome => 'plex_home',
    ProfileKind.jellyfinBonfire => 'jellyfin_bonfire',
  };

  static ProfileKind fromId(String id) => switch (id) {
    'local' => ProfileKind.local,
    'plex_home' => ProfileKind.plexHome,
    'jellyfin_bonfire' => ProfileKind.jellyfinBonfire,
    _ => throw ArgumentError('Unknown ProfileKind id: $id'),
  };
}

/// Salted SHA-256 of the PIN. The salt is fixed (per-app) — this is a
/// social-barrier hash, not real authentication. The threat model is
/// "kid bypassing parent's profile", not "adversary with device access".
const _pinSalt = 'plezy-app-profile-pin-v1';

String computePinHash(String rawPin) {
  final digest = sha256.convert(utf8.encode('$_pinSalt:$rawPin'));
  return digest.toString();
}

bool verifyPin(String rawPin, String hash) {
  return computePinHash(rawPin) == hash;
}

/// Deterministic id for a Plex Home profile so re-discovery is idempotent.
String plexHomeProfileId({required String accountConnectionId, required String homeUserUuid}) {
  return 'plex-home-$accountConnectionId-$homeUserUuid';
}

/// Anchor on the trailing home-user uuid — `accountConnectionId` may contain
/// hyphens, so a `lastIndexOf('-')` would slice inside a dashed uuid. The
/// `$` anchor resolves ambiguous hyphens: an earlier candidate split only
/// wins if the remainder is exactly one uuid.
///
/// Real plex.tv `/api/v2/home/users` uuids are 16-char plain hex
/// (e.g. `7b4af7a9f26254bd`); the 36-char dashed RFC-4122 shape is kept as a
/// defensive alternate.
final RegExp _trailingHomeUserUuidPattern = RegExp(
  r'-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{16})$',
);

/// Prefs scope for a profile id: Plex Home profiles scope by their bare
/// home-user uuid (`user_{uuid}_*`), other profiles by the full id.
///
/// Every `user_{scope}_{key}` prefs-key builder must apply this —
/// [StorageService]'s `_migratePlexHomeUserScopes` relocates full-profile-id
/// keys onto the uuid scope at every launch, so a builder that skips the
/// normalization writes keys that vanish on the next restart (Trakt
/// "unlinking" on hot restart was exactly this).
String profileUserScope(String profileId) =>
    parsePlexHomeProfileId(profileId)?.homeUserUuid ?? parseBonfireProfileId(profileId)?.bonfireUserId ?? profileId;

/// THE builder for profile-scoped prefs keys: `user_{scope}_{baseKey}`, or
/// the bare [baseKey] for the empty (signed-out/account-level) scope.
/// Pairs the `user_` prefix with [profileUserScope] in one place so no key
/// builder can skip the normalization (see the warning above).
String profileScopedPrefsKey(String userUuid, String baseKey) =>
    userUuid.isEmpty ? baseKey : 'user_${profileUserScope(userUuid)}_$baseKey';

/// Inverse of [plexHomeProfileId]. Returns `null` if [id] doesn't match the
/// `plex-home-{accountConnectionId}-{homeUserUuid}` shape.
({String accountConnectionId, String homeUserUuid})? parsePlexHomeProfileId(String id) {
  const prefix = 'plex-home-';
  if (!id.startsWith(prefix)) return null;
  final rest = id.substring(prefix.length);
  final match = _trailingHomeUserUuidPattern.firstMatch(rest);
  if (match == null) return null;
  final accountId = rest.substring(0, match.start);
  if (accountId.isEmpty) return null;
  return (accountConnectionId: accountId, homeUserUuid: match.group(1)!);
}

/// Deterministic id for a Bonfire profile so re-discovery is idempotent.
String bonfireProfileId({required String connectionId, required String bonfireUserId}) {
  return 'bonfire-$connectionId-$bonfireUserId';
}

/// Bonfire profile user ids are Jellyfin GUIDs (dashed RFC-4122). Trailing
/// anchor, same reasoning as [_trailingHomeUserUuidPattern].
final RegExp _trailingBonfireGuidPattern = RegExp(
  r'-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$',
);

/// Inverse of [bonfireProfileId]. Returns `null` if [id] doesn't match the
/// `bonfire-{connectionId}-{bonfireUserId}` shape.
({String connectionId, String bonfireUserId})? parseBonfireProfileId(String id) {
  const prefix = 'bonfire-';
  if (!id.startsWith(prefix)) return null;
  final rest = id.substring(prefix.length);
  final match = _trailingBonfireGuidPattern.firstMatch(rest);
  if (match == null) return null;
  final connectionId = rest.substring(0, match.start);
  if (connectionId.isEmpty) return null;
  return (connectionId: connectionId, bonfireUserId: match.group(1)!);
}
