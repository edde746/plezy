import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/plex/plex_home_user.dart';

/// Top-level profile — the user-facing identity in the app.
///
/// Two kinds:
/// - [ProfileKind.local]: a Plezy-only profile created by the user. May have
///   an optional 4-digit PIN.
/// - [ProfileKind.plexHome]: auto-surfaced from a connected Plex account's
///   Home users. PIN protection is handled server-side by Plex via the
///   `/home/users/{uuid}/switch` flow — `pinHash` is unused.
///
/// A profile owns 1+ connections via the `profile_connections` join table.
/// The join row carries the per-profile user-level token used to talk to
/// each connection.
class Profile {
  final String id;
  final ProfileKind kind;
  final String displayName;
  final String? avatarThumbUrl;

  /// Hashed PIN if set — only meaningful for [ProfileKind.local]. The raw
  /// PIN is never persisted; see [computePinHash].
  final String? pinHash;

  /// For [ProfileKind.plexHome]: the parent Plex account's connection id.
  /// `null` for local profiles.
  final String? parentConnectionId;

  /// For [ProfileKind.plexHome]: the Plex Home user UUID. Used by the
  /// active-profile binder to call `/home/users/{uuid}/switch`. `null` for
  /// local profiles.
  final String? plexHomeUserUuid;

  /// Plex Home flags — only meaningful for [ProfileKind.plexHome].
  final bool plexRestricted;
  final bool plexAdmin;

  /// Plex's `protected` flag — true when the home user has a PIN that must
  /// be entered before `/home/users/{uuid}/switch` will succeed.
  final bool plexProtected;

  final int sortOrder;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  Profile({
    required this.id,
    required this.kind,
    required this.displayName,
    this.avatarThumbUrl,
    this.pinHash,
    this.parentConnectionId,
    this.plexHomeUserUuid,
    this.plexRestricted = false,
    this.plexAdmin = false,
    this.plexProtected = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Construct an in-memory virtual `Profile` for a Plex Home user. These
  /// are never persisted — Plex owns the Home user list, so the picker
  /// reads them live from [PlexHomeService] and merges them with the local
  /// rows from [ProfileRegistry].
  factory Profile.virtualPlexHome({
    required String connectionId,
    required PlexHomeUser homeUser,
    DateTime? lastUsedAt,
  }) {
    return Profile(
      id: plexHomeProfileId(accountConnectionId: connectionId, homeUserUuid: homeUser.uuid),
      kind: ProfileKind.plexHome,
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
  }

  bool get isLocal => kind == ProfileKind.local;
  bool get isPlexHome => kind == ProfileKind.plexHome;

  /// True when entering this profile requires user-supplied PIN.
  ///
  /// Locals: gated by their own [pinHash].
  /// Plex Home: gated by Plex's own protected flag (`plexProtected`).
  bool get isPinProtected => isLocal ? (pinHash != null && pinHash!.isNotEmpty) : plexProtected;

  Profile copyWith({
    String? id,
    ProfileKind? kind,
    String? displayName,
    String? avatarThumbUrl,
    bool clearAvatar = false,
    String? pinHash,
    bool clearPin = false,
    String? parentConnectionId,
    String? plexHomeUserUuid,
    bool? plexRestricted,
    bool? plexAdmin,
    bool? plexProtected,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool clearLastUsedAt = false,
  }) {
    return Profile(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      avatarThumbUrl: clearAvatar ? null : (avatarThumbUrl ?? this.avatarThumbUrl),
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      parentConnectionId: parentConnectionId ?? this.parentConnectionId,
      plexHomeUserUuid: plexHomeUserUuid ?? this.plexHomeUserUuid,
      plexRestricted: plexRestricted ?? this.plexRestricted,
      plexAdmin: plexAdmin ?? this.plexAdmin,
      plexProtected: plexProtected ?? this.plexProtected,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: clearLastUsedAt ? null : (lastUsedAt ?? this.lastUsedAt),
    );
  }

  Map<String, Object?> toConfigJson() {
    return switch (kind) {
      ProfileKind.local => {'pinHash': pinHash},
      ProfileKind.plexHome => {
        'parentConnectionId': parentConnectionId,
        'restricted': plexRestricted,
        'admin': plexAdmin,
        'protected': plexProtected,
      },
    };
  }

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
      ProfileKind.local => Profile(
        id: id,
        kind: parsedKind,
        displayName: displayName,
        avatarThumbUrl: avatarThumbUrl,
        pinHash: json['pinHash'] as String?,
        sortOrder: sortOrder,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt,
      ),
      ProfileKind.plexHome => Profile(
        id: id,
        kind: parsedKind,
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
    };
  }
}

enum ProfileKind {
  local,
  plexHome;

  String get id => switch (this) {
    ProfileKind.local => 'local',
    ProfileKind.plexHome => 'plex_home',
  };

  static ProfileKind fromId(String id) => switch (id) {
    'local' => ProfileKind.local,
    'plex_home' => ProfileKind.plexHome,
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

/// Anchor on the trailing 36-char UUID — both `accountConnectionId` and
/// `homeUserUuid` may contain hyphens, so a `lastIndexOf('-')` would slice
/// inside the UUID itself.
final RegExp _trailingHomeUserUuidPattern = RegExp(
  r'-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$',
);

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
