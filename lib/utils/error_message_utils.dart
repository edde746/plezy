import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../services/playback_initialization_types.dart';
import 'app_logger.dart';

/// Logs a load failure once and returns a localized, user-safe message.
///
/// Do not call from `build`: it logs on every invocation. Use
/// [localizedLoadErrorText] there instead.
String localizedLoadErrorMessage(Object error, StackTrace stackTrace, {required String context}) {
  appLogger.e('Error loading $context', error: error, stackTrace: stackTrace);
  return localizedLoadErrorText(error, context: context);
}

/// Maps a load failure to a localized, user-safe message without logging.
///
/// The returned text never includes exception or server response content.
String localizedLoadErrorText(Object error, {required String context}) {
  if (error is MediaServerHttpException) {
    switch (error.type) {
      case MediaServerHttpErrorType.connectionTimeout:
      case MediaServerHttpErrorType.receiveTimeout:
        return t.errors.connectionTimeout(context: context);
      case MediaServerHttpErrorType.connectionError:
        return t.errors.connectionFailed;
      case MediaServerHttpErrorType.cancelled:
      case MediaServerHttpErrorType.unknown:
        break;
    }
  }

  return t.errors.unableToLoad(context: context);
}

/// A localized, user-safe reason for [error], for interpolation into a message
/// that already names the operation that failed ("Couldn't delete X: ...").
///
/// Prefers the exception's own [MediaServerException.display], which is the
/// field that exists for exactly this purpose. Otherwise maps the failure to a
/// fixed phrase.
///
/// Like [localizedLoadErrorText], the result never carries exception text,
/// server responses, hostnames or paths. `toString()` on these types carries
/// the runtime type, the English log message, and for
/// [MediaServerHttpException] the request host and path, so it must never
/// reach a snackbar.
String localizedErrorReason(Object error) {
  // Documented display-safe: `classifyPlaybackFailure` builds these with
  // localized text and `toString()` returns that message verbatim, so the
  // specific reason ("Stream selection is not available for this source") is
  // better than anything this function could substitute.
  if (error is PlaybackException) return error.message;
  if (error is MediaServerException) {
    final display = error.display;
    if (display != null && display.isNotEmpty) return display;
  }
  if (error is MediaServerHttpException) {
    switch (error.type) {
      case MediaServerHttpErrorType.connectionTimeout:
      case MediaServerHttpErrorType.receiveTimeout:
        return t.errors.reasonTimedOut;
      case MediaServerHttpErrorType.connectionError:
        return t.errors.reasonUnreachable;
      case MediaServerHttpErrorType.cancelled:
        return t.errors.reasonCancelled;
      case MediaServerHttpErrorType.unknown:
        break;
    }
    final status = error.statusCode;
    if (status == 401 || status == 403) return t.errors.reasonRefused;
    if (status == 404) return t.errors.reasonNotFound;
    if (status != null && status >= 500) return t.errors.reasonServerError;
  }
  if (error is MediaServerAuthException) return t.errors.reasonRefused;
  return t.errors.reasonUnexpected;
}
