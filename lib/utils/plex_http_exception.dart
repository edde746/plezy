import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

enum PlexHttpErrorType { connectionTimeout, receiveTimeout, connectionError, cancelled, unknown }

class PlexHttpException implements Exception {
  final PlexHttpErrorType type;
  final String? message;
  final int? statusCode;
  final dynamic responseData;
  final Uri? requestUri;

  PlexHttpException({required this.type, this.message, this.statusCode, this.responseData, this.requestUri});

  /// Map a caught exception to a [PlexHttpException].
  factory PlexHttpException.from(Object error, {Uri? uri}) {
    if (error is PlexHttpException) return error;

    if (error is RequestAbortedException) {
      return PlexHttpException(type: PlexHttpErrorType.cancelled, message: error.message, requestUri: error.uri ?? uri);
    }

    if (error is TimeoutException) {
      return PlexHttpException(type: PlexHttpErrorType.connectionTimeout, message: error.message, requestUri: uri);
    }

    if (error is SocketException) {
      return PlexHttpException(type: PlexHttpErrorType.connectionError, message: error.message, requestUri: uri);
    }

    if (error is HttpException) {
      return PlexHttpException(type: PlexHttpErrorType.connectionError, message: error.message, requestUri: uri);
    }

    if (error is ClientException) {
      return PlexHttpException(
        type: PlexHttpErrorType.connectionError,
        message: error.message,
        requestUri: error.uri ?? uri,
      );
    }

    return PlexHttpException(type: PlexHttpErrorType.unknown, message: error.toString(), requestUri: uri);
  }

  /// Whether the error looks transient (network/timeout) and worth retrying.
  bool get isTransient =>
      type == PlexHttpErrorType.connectionTimeout ||
      type == PlexHttpErrorType.connectionError ||
      type == PlexHttpErrorType.receiveTimeout;

  @override
  String toString() => 'PlexHttpException(${type.name}: $message)';
}
