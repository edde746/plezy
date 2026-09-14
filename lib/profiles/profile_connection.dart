import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_connection.freezed.dart';

/// A binding between a [Profile] and a [Connection], carrying the
/// per-profile user-level token used when the profile is active.
///
/// For Plex: [userToken] is a Plex Home-user token from
/// `/home/users/{uuid}/switch`; [userIdentifier] is the Home user UUID.
/// A `null` [userToken] is the lazy-fetch sentinel — the
/// `ActiveProfileBinder` performs the switch on first activation and
/// caches the resulting token back into this row.
///
/// For the MediaBrowser backends (Jellyfin and Emby): [userToken] mirrors the
/// Connection's accessToken (one user per connection); [userIdentifier] is the
/// server-side user id.
@freezed
sealed class ProfileConnection with _$ProfileConnection {
  const ProfileConnection._();

  const factory ProfileConnection({
    required String profileId,
    required String connectionId,
    String? userToken,
    required String userIdentifier,
    @Default(false) bool isDefault,
    DateTime? tokenAcquiredAt,
    DateTime? lastUsedAt,
  }) = _ProfileConnection;

  bool get hasToken => userToken != null && userToken!.isNotEmpty;
}
