/// The URL doesn't point at a reachable, initialized Seerr instance.
class SeerrUrlException implements Exception {
  final String message;
  const SeerrUrlException(this.message);

  @override
  String toString() => 'SeerrUrlException: $message';
}

/// Sign-in or session-refresh failure (bad credentials, revoked session).
/// [SeerrClient] treats this during re-auth as "the server rejected the
/// stored credentials" and unlinks the session.
class SeerrAuthException implements Exception {
  final String message;
  final int? statusCode;
  const SeerrAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'SeerrAuthException: $message${statusCode == null ? '' : ' ($statusCode)'}';
}

/// Silent re-auth could not even be ATTEMPTED — the credentials weren't
/// resolvable right now (e.g. the live Plex token supplier came up empty
/// during a degraded launch). Deliberately not a [SeerrAuthException]:
/// the failure is retryable and must not unlink the stored session.
class SeerrReauthUnavailableException implements Exception {
  final String message;
  const SeerrReauthUnavailableException(this.message);

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
