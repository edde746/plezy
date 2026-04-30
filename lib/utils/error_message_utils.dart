import '../i18n/strings.g.dart';
import 'app_logger.dart';
import '../exceptions/media_server_exceptions.dart';

/// Shared helpers for translating network errors into user-friendly messages.
String mapHttpErrorToMessage(MediaServerHttpException error, {required String context}) {
  switch (error.type) {
    case MediaServerHttpErrorType.connectionTimeout:
    case MediaServerHttpErrorType.receiveTimeout:
      return t.errors.connectionTimeout(context: context);
    case MediaServerHttpErrorType.connectionError:
      return t.errors.connectionFailed;
    default:
      appLogger.e('Error loading $context', error: error);
      final msg = error.message.isNotEmpty ? error.message : t.common.unknown;
      return t.errors.failedToLoad(context: context, error: msg);
  }
}

/// Generic fallback for unexpected errors.
String mapUnexpectedErrorToMessage(dynamic error, {required String context}) {
  appLogger.e('Unexpected error in $context', error: error);
  return t.errors.failedToLoad(context: context, error: error.toString());
}
