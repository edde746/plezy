/// Sealed exception base for Seerr operations.
sealed class SeerrException implements Exception {
  final String message;
  const SeerrException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The configured base URL didn't respond as a Seerr instance (HTTP error,
/// not JSON, or `/settings/public` reports `initialized: false`).
class SeerrUrlException extends SeerrException {
  const SeerrUrlException(super.message);
}

/// Authentication failed (401/403). Distinguished so the UI can prompt for
/// a fresh password rather than treating it as a generic transport error.
class SeerrAuthException extends SeerrException {
  final int? statusCode;
  const SeerrAuthException(super.message, {this.statusCode});
}

/// Generic HTTP failure (non-2xx response that isn't an auth failure).
class SeerrHttpException extends SeerrException {
  final int statusCode;
  final String? body;
  SeerrHttpException(this.statusCode, {String? message, this.body}) : super(message ?? 'HTTP $statusCode');
}

/// Server rejected the request for non-auth reasons (quota exceeded, bad
/// payload, etc.). Carries the human-friendly message from Seerr.
class SeerrRequestException extends SeerrException {
  final int statusCode;
  const SeerrRequestException(super.message, {required this.statusCode});
}
