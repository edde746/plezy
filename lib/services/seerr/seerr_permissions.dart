/// Bitmask constants for Seerr's permission field (inherited from Overseerr).
///
/// Each permission is a single bit (2^N) — the user's `permissions` field is
/// the OR of every granted bit. The [ADMIN] flag is special: any user with
/// ADMIN is treated as having every other permission, even if those bits
/// aren't individually set. Use [has] to evaluate, never bare bitwise checks.
class SeerrPermissions {
  SeerrPermissions._();

  /// User has full admin access — implicitly grants every other permission.
  static const int admin = 2;

  static const int manageSettings = 4;
  static const int manageUsers = 8;
  static const int manageRequests = 16;
  static const int request = 32;
  static const int vote = 64;

  static const int autoApprove = 128;
  static const int autoApproveMovie = 256;
  static const int autoApproveTv = 512;

  static const int requestMovie = 1024;
  static const int requestTv = 2048;

  static const int manageIssues = 4096;
  static const int viewIssues = 8192;
  static const int createIssues = 16384;

  static const int autoRequest = 32768;
  static const int autoRequestMovie = 65536;
  static const int autoRequestTv = 131072;

  static const int recentView = 262144;
  static const int watchlistView = 524288;

  static const int request4k = 1048576;
  static const int request4kMovie = 2097152;
  static const int request4kTv = 4194304;

  /// Lets the user pick server, quality profile, root folder, language
  /// profile, and (for admins) the user the request is attributed to.
  static const int requestAdvanced = 8388608;

  static const int requestView = 16777216;

  static const int autoApprove4k = 33554432;
  static const int autoApprove4kMovie = 67108864;
  static const int autoApprove4kTv = 134217728;

  /// True when [granted] includes [flag] — or when [granted] includes [admin]
  /// (which implicitly grants everything). Use this everywhere; never `&`
  /// directly.
  static bool has(int granted, int flag) {
    if ((granted & admin) != 0) return true;
    return (granted & flag) != 0;
  }

  /// Whether the user can request a 4K movie (or TV show when [forTv]=true).
  static bool can4kRequest({required int permissions, required bool forTv}) {
    if ((permissions & admin) != 0) return true;
    if (has(permissions, request4k)) return true;
    return forTv ? has(permissions, request4kTv) : has(permissions, request4kMovie);
  }
}
