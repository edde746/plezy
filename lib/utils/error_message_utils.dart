import 'package:dio/dio.dart';
import '../i18n/strings.g.dart';
import 'app_logger.dart';

/// Shared helpers for translating network errors into user-friendly messages.
String mapDioErrorToMessage(DioException error, {required String context}) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return t.errors.connectionTimeout(context: context);
    case DioExceptionType.connectionError:
      return t.errors.connectionFailed;
    default:
      appLogger.e('Error loading $context', error: error);
      return t.errors.failedToLoad(
        context: context,
        error: error.message ?? t.common.unknown,
      );
  }
}

/// Generic fallback for unexpected errors.
String mapUnexpectedErrorToMessage(dynamic error, {required String context}) {
  appLogger.e('Unexpected error in $context', error: error);
  return t.errors.failedToLoad(
    context: context,
    error: error.toString(),
  );
}
