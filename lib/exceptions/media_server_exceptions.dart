import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

/// Sealed base for backend-agnostic media-server exceptions. Both Plex and
/// Jellyfin auth/HTTP layers throw subtypes from this hierarchy so consumers
/// can catch with one filter and match exhaustively when they care which
/// failure mode it is.
///
/// [message] is English for stable logs and Sentry grouping. [display] is the
/// localized user-facing text when this failure is rendered in the UI.
sealed class MediaServerException implements Exception {
  final String message;
  final String? display;
  const MediaServerException(this.message, {this.display});

  @override
  String toString() => '$runtimeType: $message';
}

/// The supplied base URL is unreachable, returns the wrong shape, or doesn't
/// look like the expected backend at all. Surfaces in onboarding probes
/// (Jellyfin `/System/Info/Public`, Plex resource discovery).
class MediaServerUrlException extends MediaServerException {
  const MediaServerUrlException(super.message, {super.display});
}

/// Authentication failed — bad password, expired token, disabled user,
/// rate-limit. [statusCode] is the HTTP status when the failure was a 4xx
/// response; null for transport-layer auth signals (e.g. token rejected
/// during refresh).
class MediaServerAuthException extends MediaServerException {
  final int? statusCode;
  const MediaServerAuthException(super.message, {this.statusCode, super.display});
}

/// Auth polling reached a terminal server-side expiry/rejection state before
/// the user completed the external sign-in flow.
class MediaServerPinExpiredException extends MediaServerAuthException {
  const MediaServerPinExpiredException({super.display}) : super('PIN expired before sign-in');
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

  MediaServerHttpException({
    required this.type,
    String? message,
    super.display,
    this.statusCode,
    this.responseData,
    this.requestUri,
  }) : super(message ?? '');

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

/// The backend already has a recording scheduled for the requested airing.
///
/// Plex signals duplicates with a bare 409, which UI maps by status code.
/// Jellyfin/Emby answer `POST /LiveTv/Timers` duplicates with a 400 that is
/// indistinguishable from a malformed request by status alone — only the DVR
/// adapter knows that call site's semantics, so it rethrows this type and UI
/// maps it to the "already scheduled" outcome without a backend check.
class RecordingConflictException extends MediaServerException {
  const RecordingConflictException(super.message, {super.display});
}

/// The server explicitly terminated the client's playback session (admin
/// "stop stream", paused-too-long auto-termination, concurrent-stream limit).
///
/// Plex signals this with `terminationCode`/`terminationText` on the
/// MediaContainer of a timeline report response. The MediaBrowser backends
/// deliver admin stops as a WebSocket remote-control command Plezy does not
/// subscribe to, so they never throw this — intentionally unsupported there.
///
/// Progress reporting must stop when this is thrown: continuing the heartbeat
/// loop re-registers the session server-side as a zombie row the admin can no
/// longer clear (#1916).
class PlaybackSessionTerminatedException extends MediaServerException {
  /// Server-defined termination code (e.g. Plex 2006 for an admin stop).
  final int code;

  /// Human-readable server-supplied reason; may carry an admin message.
  final String? reason;

  PlaybackSessionTerminatedException({required this.code, this.reason})
    : super('Server terminated playback session (code $code)${reason == null ? '' : ': $reason'}');
}
