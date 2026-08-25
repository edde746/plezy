/// Constants for the Seerr (seerr-team/seerr) REST API.
abstract final class SeerrConstants {
  /// Every endpoint lives under this prefix on the instance base URL.
  static const String apiPath = '/api/v1';

  /// Express session cookie issued by the auth endpoints.
  static const String sessionCookieName = 'connect.sid';

  /// Default port of a Seerr install, tried for schemeless input that names no
  /// port of its own.
  static const int defaultPort = 5055;

  static const Duration probeTimeout = Duration(seconds: 8);
  static const Duration authTimeout = Duration(seconds: 20);
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Quick Connect poll cadence, matching the Seerr web UI's fixed 2000ms.
  static const Duration quickConnectPollInterval = Duration(seconds: 2);
}

/// Seerr `MediaServerType` values (server/constants/server.ts), sent as
/// `serverType` in the `/auth/jellyfin` body.
abstract final class SeerrMediaServerType {
  static const int plex = 1;
  static const int jellyfin = 2;
  static const int emby = 3;
}

/// Seerr permission bitmask (server/lib/permissions.ts). Only the bits the
/// app checks are named; the full mask is stored on the session untouched.
abstract final class SeerrPermission {
  static const int admin = 2;
  static const int request = 32;
  static const int request4k = 1024;
  static const int request4kMovie = 2048;
  static const int request4kTv = 4096;
  static const int requestAdvanced = 8192;
  static const int requestMovie = 262144;
  static const int requestTv = 524288;
}

/// Seerr permission semantics: `ADMIN` implies everything, otherwise the
/// user needs at least one of [anyOf].
bool seerrHasPermission(int userPermissions, List<int> anyOf) {
  if (userPermissions & SeerrPermission.admin != 0) return true;
  return anyOf.any((p) => userPermissions & p != 0);
}
