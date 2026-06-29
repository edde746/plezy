/// Seerr-side user record returned by `GET /api/v1/auth/me` (and embedded in
/// `MediaRequest.requestedBy`).
///
/// `userType` enum (per Seerr's `lib/constants/user.ts`):
///   1 = PLEX (legacy Overseerr), 2 = LOCAL, 3 = PLEX_NAME (alt), 4 = JELLYFIN
/// Older builds used 1=local/2=plex/3=jellyfin. The Plezy client treats it as
/// opaque metadata and does not branch on the value beyond display.
class SeerrUser {
  final int id;
  final String? email;
  final String username;
  final int userType;
  final int permissions;
  final String? avatar;
  final int requestCount;

  const SeerrUser({
    required this.id,
    this.email,
    required this.username,
    required this.userType,
    required this.permissions,
    this.avatar,
    this.requestCount = 0,
  });

  factory SeerrUser.fromJson(Map<String, dynamic> json) {
    return SeerrUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String?,
      // Seerr may return either `username` (local accounts) or `jellyfinUsername`
      // / `plexUsername` (SSO). Pick the first non-empty.
      username: (json['username'] as String?)?.trim().isNotEmpty == true
          ? json['username'] as String
          : (json['jellyfinUsername'] as String?) ?? (json['plexUsername'] as String?) ?? '',
      userType: (json['userType'] as num?)?.toInt() ?? 0,
      permissions: (json['permissions'] as num?)?.toInt() ?? 0,
      avatar: json['avatar'] as String?,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
    );
  }
}
