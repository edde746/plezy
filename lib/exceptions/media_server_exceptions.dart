import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

/// Sealed base for backend-agnostic media-server exceptions. Both Plex and
/// Jellyfin auth/HTTP layers throw subtypes from this hierarchy so consumers
/// can catch with one filter and match exhaustively when they care which
/// failure mode it is.
sealed class MediaServerException implements Exception {
  final String message;
  const MediaServerException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The supplied base URL is unreachable, returns the wrong shape, or doesn't
/// look like the expected backend at all. Surfaces in onboarding probes
/// (Jellyfin `/System/Info/Public`, Plex resource discovery).
class MediaServerUrlException extends MediaServerException {
  const MediaServerUrlException(super.message);
}

/// Authentication failed — bad password, expired token, disabled user,
/// rate-limit. [statusCode] is the HTTP status when the failure was a 4xx
/// response; null for transport-layer auth signals (e.g. token rejected
/// during refresh).
class MediaServerAuthException extends MediaServerException {
  final int? statusCode;
  const MediaServerAuthException(super.message, {this.statusCode});
}

/// HTTP transport / non-2xx errors. Carries the status code (when known),
/// the parsed response body, and the originating URI so callers can log
/// useful diagnostics. Both Plex and Jellyfin route their HTTP failures
/// through this type — it's the canonical backend-agnostic transport
/// exception.
enum MediaServerHttpErrorType { connectionTimeout, receiveTimeout, connectionError, cancelled, unknown }

class MediaServerHttpException extends MediaServerException {
  final MediaServerHttpErrorType type;
  final int? statusCode;
  final dynamic responseData;
  final Uri? requestUri;

  MediaServerHttpException({required this.type, String? message, this.statusCode, this.responseData, this.requestUri})
    : super(message ?? '');

  /// Map a caught exception to a [MediaServerHttpException].
  factory MediaServerHttpException.from(Object error, {Uri? uri}) {
    if (error is MediaServerHttpException) return error;

    if (error is RequestAbortedException) {
      return MediaServerHttpException(
        type: MediaServerHttpErrorType.cancelled,
        message: error.message,
        requestUri: error.uri ?? uri,
      );
    }

    if (error is TimeoutException) {
      return MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionTimeout,
        message: error.message,
        requestUri: uri,
      );
    }

    if (error is SocketException) {
      return MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: error.message,
        requestUri: uri,
      );
    }

    if (error is HttpException) {
      return MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: error.message,
        requestUri: uri,
      );
    }

    if (error is ClientException) {
      return MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: error.message,
        requestUri: error.uri ?? uri,
      );
    }

    return MediaServerHttpException(type: MediaServerHttpErrorType.unknown, message: error.toString(), requestUri: uri);
  }

  /// Whether the error looks transient (network/timeout) and worth retrying.
  bool get isTransient =>
      type == MediaServerHttpErrorType.connectionTimeout ||
      type == MediaServerHttpErrorType.connectionError ||
      type == MediaServerHttpErrorType.receiveTimeout;

  @override
  String toString() => 'MediaServerHttpException(${type.name}: $message)';
}
