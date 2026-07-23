import 'tracker_constants.dart';

enum TrackerApiFailureCategory { graphqlErrors }

class TrackerApiException implements Exception {
  final TrackerService service;
  final int statusCode;
  final TrackerApiFailureCategory? category;

  const TrackerApiException({required this.service, required this.statusCode, this.category});

  @override
  String toString() {
    final categorySuffix = category == null ? '' : ', ${category!.name}';
    return 'TrackerApiException(${service.name}, HTTP $statusCode$categorySuffix)';
  }
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
