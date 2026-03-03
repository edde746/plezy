import 'package:dio/dio.dart';

/// Creates a plain [Dio] instance with sensible default timeouts for ad-hoc
/// HTTP requests that don't go through [PlexClient].
///
/// Use this instead of bare `Dio()` so every call site gets consistent timeout
/// behaviour without duplicating configuration.
Dio createHttpClient({
  Duration connectTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 30),
}) {
  return Dio(
    BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    ),
  );
}
