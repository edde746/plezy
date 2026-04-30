/// A binding between a [Profile] and a [Connection], carrying the
/// per-profile user-level token used when the profile is active.
///
/// For Plex: [userToken] is a Plex Home-user token from
/// `/home/users/{uuid}/switch`; [userIdentifier] is the Home user UUID.
/// A `null` [userToken] is the lazy-fetch sentinel — the
/// `ActiveProfileBinder` performs the switch on first activation and
/// caches the resulting token back into this row.
///
/// For Jellyfin: [userToken] mirrors the Connection's accessToken (one
/// user per connection); [userIdentifier] is the Jellyfin user id.
class ProfileConnection {
  final String profileId;
  final String connectionId;
  final String? userToken;
  final String userIdentifier;
  final bool isDefault;
  final DateTime? tokenAcquiredAt;
  final DateTime? lastUsedAt;

  const ProfileConnection({
    required this.profileId,
    required this.connectionId,
    this.userToken,
    required this.userIdentifier,
    this.isDefault = false,
    this.tokenAcquiredAt,
    this.lastUsedAt,
  });

  bool get hasToken => userToken != null && userToken!.isNotEmpty;

  ProfileConnection copyWith({
    String? profileId,
    String? connectionId,
    String? userToken,
    bool clearUserToken = false,
    String? userIdentifier,
    bool? isDefault,
    DateTime? tokenAcquiredAt,
    bool clearTokenAcquiredAt = false,
    DateTime? lastUsedAt,
    bool clearLastUsedAt = false,
  }) {
    return ProfileConnection(
      profileId: profileId ?? this.profileId,
      connectionId: connectionId ?? this.connectionId,
      userToken: clearUserToken ? null : (userToken ?? this.userToken),
      userIdentifier: userIdentifier ?? this.userIdentifier,
      isDefault: isDefault ?? this.isDefault,
      tokenAcquiredAt: clearTokenAcquiredAt ? null : (tokenAcquiredAt ?? this.tokenAcquiredAt),
      lastUsedAt: clearLastUsedAt ? null : (lastUsedAt ?? this.lastUsedAt),
    );
  }
}
