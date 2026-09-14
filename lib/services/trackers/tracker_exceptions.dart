import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

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

/// True when a failed write says nothing about the write itself, so retrying it
/// later is the right answer and it must not spend one of a queued item's
/// attempts.
///
/// Four shapes qualify:
///
/// * The request never arrived — a timeout or transport error. A link coming
///   back up is no proof the endpoint is reachable, so counting these would let
///   a handful of connectivity flaps drop a watch.
/// * The service rate-limited us. Explicitly retryable, and typed only by Trakt
///   and AniList — MAL and Simkl surface a 429 as a plain
///   [TrackerApiException].
/// * The service failed on its own side (5xx). A bad hour for a service is not
///   evidence that this watch is unwritable.
/// * A token refresh failed recoverably. [TrackerAuthException.isPermanent] is
///   the services' own verdict: false means the refresh endpoint misbehaved
///   (5xx, network), true means the session is genuinely dead.
///
/// What is left counting is an answer *about the write*: 4xx says this item, on
/// this account, will not be written however often we ask. The consequence is
/// that a service returning 5xx indefinitely keeps its rows queued rather than
/// dropping them — deliberate, since the alternative is losing watches to an
/// outage, and rows coalesce per remote row so repeats do not accumulate.
bool isTrackerFailureTransient(Object error) {
  if (error is TimeoutException || error is SocketException || error is http.ClientException) return true;
  if (error is TrackerRateLimitException) return true;
  if (error is TrackerAuthException) return !error.isPermanent;
  if (error is TrackerApiException) return error.statusCode == 429 || error.statusCode >= 500;
  return false;
}
