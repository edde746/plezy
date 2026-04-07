import '../i18n/strings.g.dart';
import 'app_logger.dart';
import 'plex_http_exception.dart';

/// Shared helpers for translating network errors into user-friendly messages.
String mapHttpErrorToMessage(PlexHttpException error, {required String context}) {
  switch (error.type) {
    case PlexHttpErrorType.connectionTimeout:
    case PlexHttpErrorType.receiveTimeout:
      return t.errors.connectionTimeout(context: context);
    case PlexHttpErrorType.connectionError:
      return t.errors.connectionFailed;
    default:
      appLogger.e('Error loading $context', error: error);
      return t.errors.failedToLoad(context: context, error: error.message ?? t.common.unknown);
  }
}

/// Generic fallback for unexpected errors.
String mapUnexpectedErrorToMessage(dynamic error, {required String context}) {
  appLogger.e('Unexpected error in $context', error: error);
  return t.errors.failedToLoad(context: context, error: error.toString());
}
