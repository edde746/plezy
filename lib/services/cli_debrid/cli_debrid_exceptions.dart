/// The URL doesn't point at a reachable cli_debrid instance, or the probe
/// request itself failed (network error, non-JSON response, etc).
class CliDebridUrlException implements Exception {
  final String message;
  const CliDebridUrlException(this.message);

  @override
  String toString() => 'CliDebridUrlException: $message';
}

/// The API token was rejected (401), or no token/credentials were provided
/// where cli_debrid's user system requires one.
class CliDebridAuthException implements Exception {
  final String message;
  final int? statusCode;
  const CliDebridAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'CliDebridAuthException: $message${statusCode == null ? '' : ' ($statusCode)'}';
}

/// Non-auth API failure with a server-provided message (e.g. item not found,
/// ambiguous version match, database locked).
class CliDebridApiException implements Exception {
  final String message;
  final int statusCode;

  /// Present only for the rescrape-item "ambiguous" response — candidate
  /// version rows the caller should show a picker for and retry with.
  final List<Map<String, Object?>>? candidates;

  const CliDebridApiException(this.message, {required this.statusCode, this.candidates});

  @override
  String toString() => 'CliDebridApiException($statusCode): $message';
}
