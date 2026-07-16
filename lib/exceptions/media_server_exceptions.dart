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

/// Auth polling reached a terminal server-side expiry/rejection state before
/// the user completed the external sign-in flow.
class MediaServerPinExpiredException extends MediaServerAuthException {
  const MediaServerPinExpiredException() : super('PIN expired before sign-in');
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
    return switch (error) {
      MediaServerHttpException() => error,
      RequestAbortedException(:final message, uri: final errorUri) => MediaServerHttpException(
        type: MediaServerHttpErrorType.cancelled,
        message: message,
        requestUri: errorUri ?? uri,
      ),
      TimeoutException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionTimeout,
        message: message,
        requestUri: uri,
      ),
      SocketException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: message,
        requestUri: uri,
      ),
      HttpException(:final message) => MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: message,
        requestUri: uri,
      ),
      ClientException(:final message, uri: final errorUri) => MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: message,
        requestUri: errorUri ?? uri,
      ),
      _ => MediaServerHttpException(type: MediaServerHttpErrorType.unknown, message: error.toString(), requestUri: uri),
    };
  }

  /// Whether the error looks transient (network/timeout) and worth retrying.
  bool get isTransient =>
      type == MediaServerHttpErrorType.connectionTimeout ||
      type == MediaServerHttpErrorType.connectionError ||
      type == MediaServerHttpErrorType.receiveTimeout;

  /// Whether the request was aborted client-side (client teardown or an
  /// explicit abort), as opposed to failing against the server. A cancelled
  /// fetch says nothing about the server's actual content — callers must not
  /// treat it as an empty result.
  bool get isCancellation => type == MediaServerHttpErrorType.cancelled;

  @override
  String toString() {
    final parts = <String>[type.name];
    if (statusCode != null) parts.add('HTTP $statusCode');
    if (message.isNotEmpty) parts.add(message);
    final uri = requestUri;
    if (uri != null) parts.add('${uri.host}${uri.path}');
    return 'MediaServerHttpException(${parts.join(': ')})';
  }
}
