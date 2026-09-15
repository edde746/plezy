/// The URL doesn't point at a reachable, initialized Seerr instance.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrUrlException implements Exception {
  final String message;
  final String? display;

  /// Status of the response that disqualified the URL, when one arrived at
  /// all. Null means nothing answered (DNS, refused, TLS, timeout), which is
  /// how candidate racing tells "reached a server that isn't a usable Seerr"
  /// apart from "never reached anything".
  final int? statusCode;
  const SeerrUrlException(this.message, {this.display, this.statusCode});

  @override
  String toString() => 'SeerrUrlException: $message';
}

/// Sign-in or session-refresh failure (bad credentials, revoked session).
/// [SeerrClient] treats this during re-auth as "the server rejected the
/// stored credentials" and unlinks the session.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrAuthException implements Exception {
  final String message;
  final String? display;
  final int? statusCode;
  const SeerrAuthException(this.message, {this.statusCode, this.display});

  @override
  String toString() => 'SeerrAuthException: $message${statusCode == null ? '' : ' ($statusCode)'}';
}

/// Silent re-auth could not safely restore this principal (e.g. a missing
/// live Plex token or a login that resolved to another user). Deliberately
/// not a [SeerrAuthException]: this does not prove the stored credentials
/// were rejected and must not unlink the session.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrReauthUnavailableException implements Exception {
  final String message;
  final String? display;
  const SeerrReauthUnavailableException(this.message, {this.display});

  @override
  String toString() => 'SeerrReauthUnavailableException: $message';
}

/// Something in front of Seerr answered instead of Seerr: a forward-auth
/// redirect to an SSO login page, an HTTP Basic challenge, an auth wall or
/// API gateway's 401/403 — JSON-bodied or not. Seerr's own API never
/// redirects and rejects in exactly two JSON shapes ([SeerrRejection]), so
/// anything else is diagnostic. Deliberately not a [SeerrAuthException]: the
/// stored session may be perfectly valid behind the wall, so [SeerrClient]
/// must not unlink it.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrProxyException implements Exception {
  final String message;
  final String display;
  final int statusCode;
  const SeerrProxyException(this.message, {required this.display, required this.statusCode});

  @override
  String toString() => 'SeerrProxyException($statusCode): $message';
}

/// Non-auth API failure with a server-provided message (e.g. quota
/// exceeded on a request, duplicate request).
class SeerrApiException implements Exception {
  final String message;
  final int statusCode;
  const SeerrApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'SeerrApiException($statusCode): $message';
}

/// Seerr's `isAuthenticated(permission)` middleware refused a live session
/// the action's permission bit — the body is identical to a session
/// rejection, and only the `GET /auth/me` probe [SeerrClient] runs tells
/// them apart. Distinct from [SeerrApiException] so request surfaces can
/// localize it instead of echoing the server's English body, and from
/// [SeerrAuthException] because the session is fine and must stay linked.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrPermissionException implements Exception {
  final String message;
  final String display;
  final int statusCode;
  const SeerrPermissionException(this.message, {required this.display, required this.statusCode});

  @override
  String toString() => 'SeerrPermissionException($statusCode): $message';
}
