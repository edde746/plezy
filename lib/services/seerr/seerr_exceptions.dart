/// The URL doesn't point at a reachable, initialized Seerr instance.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
class SeerrUrlException implements Exception {
  final String message;
  final String? display;
  const SeerrUrlException(this.message, {this.display});

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

/// Non-auth API failure with a server-provided message (e.g. quota
/// exceeded on a request, duplicate request).
class SeerrApiException implements Exception {
  final String message;
  final int statusCode;
  const SeerrApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'SeerrApiException($statusCode): $message';
}
