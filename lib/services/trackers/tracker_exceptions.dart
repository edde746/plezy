import 'tracker_constants.dart';

class TrackerApiException implements Exception {
  final TrackerService service;
  final int statusCode;
  final String body;

  const TrackerApiException({required this.service, required this.statusCode, required this.body});

  @override
  String toString() => 'TrackerApiException(${service.name}, HTTP $statusCode): $body';
}

class TrackerAuthException implements Exception {
  final TrackerService service;
  final String message;
  final int? statusCode;
  final bool isPermanent;

  const TrackerAuthException({required this.service, required this.message, this.statusCode, this.isPermanent = false});

  @override
  String toString() => 'TrackerAuthException(${service.name}): $message';
}

class TrackerRateLimitException implements Exception {
  final TrackerService service;
  final int? retryAfterSeconds;

  const TrackerRateLimitException({required this.service, this.retryAfterSeconds});

  @override
  String toString() => 'TrackerRateLimitException(${service.name}, retry-after: $retryAfterSeconds s)';
}
