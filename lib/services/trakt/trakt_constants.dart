/// Bundled Trakt API credentials and base URLs.
///
/// The client_id/client_secret are extractable from the binary; this is
/// the standard pattern for native Trakt apps and is acceptable given the
/// same threat model as the Plex token already in `SharedPreferences`.
class TraktConstants {
  TraktConstants._();

  // Registered Trakt app credentials. Same threat model as the Plex token in
  // SharedPreferences — extractable from the binary, but acceptable for a
  // native client app. To rotate, update the registration at
  // https://trakt.tv/oauth/applications.
  static const String clientId = '9861e686e95c13409dd321736f903973cb9b8e5c6abd0634bec8962f52ea30f4';
  static const String clientSecret = 'acfa17b9d77fabd7e51175b7da6631aea69423530a6d49b3b3c38cd107cbd207';

  static const String apiBase = 'https://api.trakt.tv';
  static const String apiVersion = '2';

  // OAuth endpoints
  static const String deviceCodeUrl = '$apiBase/oauth/device/code';
  static const String deviceTokenUrl = '$apiBase/oauth/device/token';
  static const String tokenUrl = '$apiBase/oauth/token';
  static const String revokeUrl = '$apiBase/oauth/revoke';

  // Scopes — Trakt's OAuth doesn't use granular scopes; "public" is the only value
  static const String scope = 'public';

  /// Headers required on every Trakt API call.
  static Map<String, String> headers({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'trakt-api-version': apiVersion,
      'trakt-api-key': clientId,
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }
}

/// Build a `SharedPreferences` key scoped to the given Plex profile UUID.
/// Mirrors the `_userPrefix` pattern in [StorageService] so each profile gets
/// its own Trakt session and sync queue.
String traktUserKey(String userUuid, String baseKey) => userUuid.isEmpty ? baseKey : 'user_${userUuid}_$baseKey';

/// Scrobble lifecycle state sent to Trakt's `/scrobble/{name}` endpoints.
enum TraktScrobbleState { start, pause, stop }

/// Direction of a watched-status sync push.
enum TraktSyncOp {
  add,
  remove;

  static TraktSyncOp fromName(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => throw ArgumentError('Unknown TraktSyncOp: $name'));
}

/// Trakt-relevant media types. Accepts the neutral [MediaKind.id] string
/// (`'movie'`, `'episode'`) used across both Plex and Jellyfin watch events.
enum TraktMediaKind {
  movie,
  episode;

  static TraktMediaKind? tryFromMediaKindId(String type) => switch (type) {
    'movie' => movie,
    'episode' => episode,
    _ => null,
  };

  static TraktMediaKind fromName(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => throw ArgumentError('Unknown TraktMediaKind: $name'));
}
