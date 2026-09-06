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

/// Silent re-auth could not even be ATTEMPTED — the credentials weren't
/// resolvable right now (e.g. the live Plex token supplier came up empty
/// during a degraded launch). Deliberately not a [SeerrAuthException]:
/// the failure is retryable and must not unlink the stored session.
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
