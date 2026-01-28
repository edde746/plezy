import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

/// Key used to stamp requests with the failover generation they were issued under.
const _generationKey = '_failoverGeneration';

/// Maintains the list of endpoints we can cycle through when one fails.
class EndpointFailoverManager {
  EndpointFailoverManager(List<String> urls) {
    _setEndpoints(urls);
  }

  late List<String> _endpoints;
  int _currentIndex = 0;

  /// Incremented every time the active endpoint changes. Requests stamped with
  /// an older generation should not trigger additional failover cascades.
  int _generation = 0;
  int get generation => _generation;

  List<String> get endpoints => List.unmodifiable(_endpoints);

  String get current => _endpoints[_currentIndex];

  bool get hasFallback => _currentIndex < _endpoints.length - 1;

  /// Move to the next endpoint, returning its URL or null if exhausted.
  String? moveToNext() {
    if (!hasFallback) return null;
    _currentIndex++;
    _generation++;
    return _endpoints[_currentIndex];
  }

  /// Reset back to the first (preferred) endpoint. Called when all endpoints
  /// are exhausted so the next failure cycle starts from the best candidate.
  void resetToFirst() {
    if (_currentIndex != 0) {
      _currentIndex = 0;
      _generation++;
      appLogger.d('Failover endpoint list reset to first candidate');
    }
  }

  /// Replace the endpoint list and optionally set the active endpoint.
  void reset(List<String> urls, {String? currentBaseUrl}) {
    _setEndpoints(urls);
    if (currentBaseUrl != null) {
      final index = _endpoints.indexOf(currentBaseUrl);
      _currentIndex = index >= 0 ? index : 0;
    } else {
      _currentIndex = 0;
    }
    _generation++;
  }

  void _setEndpoints(List<String> urls) {
    final sanitized = <String>[];
    final seen = <String>{};
    for (final url in urls) {
      if (url.isEmpty || seen.contains(url)) continue;
      seen.add(url);
      sanitized.add(url);
    }
    if (sanitized.isEmpty) {
      throw ArgumentError('At least one endpoint is required');
    }
    _endpoints = sanitized;
    _currentIndex = _currentIndex.clamp(0, _endpoints.length - 1);
  }
}

/// Dio interceptor that retries failed requests on the next available endpoint.
class EndpointFailoverInterceptor extends Interceptor {
  EndpointFailoverInterceptor({
    required Dio dio,
    required this.endpointManager,
    required Future<void> Function(String newBaseUrl) onEndpointSwitch,
  }) : _dio = dio,
       _onEndpointSwitch = onEndpointSwitch;

  final Dio _dio;
  final EndpointFailoverManager endpointManager;
  final Future<void> Function(String newBaseUrl) _onEndpointSwitch;
  bool _isSwitching = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Stamp every outgoing request with the current failover generation so
    // we can detect stale requests in onError.
    options.extra[_generationKey] = endpointManager.generation;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isSwitching || !_shouldAttemptFailover(err)) {
      handler.next(err);
      return;
    }

    // If the endpoint changed since this request was dispatched, the request
    // timed out on an already-abandoned endpoint. Don't cascade another switch.
    final requestGeneration = err.requestOptions.extra[_generationKey] as int?;
    if (requestGeneration != null && requestGeneration != endpointManager.generation) {
      appLogger.d(
        'Skipping failover for stale request (generation $requestGeneration != ${endpointManager.generation})',
        error: {'path': err.requestOptions.path},
      );
      handler.next(err);
      return;
    }

    if (!endpointManager.hasFallback) {
      // All endpoints exhausted — reset to first so the next failure cycle
      // starts from the preferred endpoint (handles transient network outages).
      endpointManager.resetToFirst();
      handler.next(err);
      return;
    }

    final failedEndpoint = endpointManager.current;
    appLogger.w(
      'Endpoint request failed, evaluating failover',
      error: {'endpoint': failedEndpoint, 'type': err.type.name, 'statusCode': err.response?.statusCode},
      stackTrace: err.stackTrace,
    );

    final nextBaseUrl = endpointManager.moveToNext();
    if (nextBaseUrl == null) {
      appLogger.w('Endpoint failure but no fallback endpoints remain', error: {'failedEndpoint': failedEndpoint});
      handler.next(err);
      return;
    }

    _isSwitching = true;
    try {
      appLogger.i(
        'Switching Plex endpoint after request failure',
        error: {'from': failedEndpoint, 'to': nextBaseUrl, 'path': err.requestOptions.path},
      );
      await _onEndpointSwitch(nextBaseUrl);
      final response = await _retryRequest(err.requestOptions);
      appLogger.i('Endpoint failover retry succeeded', error: {'newEndpoint': nextBaseUrl});
      handler.resolve(response);
    } on DioException catch (dioError) {
      appLogger.w(
        'Endpoint failover retry failed',
        error: {'newEndpoint': nextBaseUrl, 'type': dioError.type.name, 'statusCode': dioError.response?.statusCode},
        stackTrace: dioError.stackTrace,
      );
      handler.next(dioError);
    } catch (_) {
      handler.next(err);
    } finally {
      _isSwitching = false;
    }
  }

  bool _shouldAttemptFailover(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    return false;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      validateStatus: requestOptions.validateStatus,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      extra: requestOptions.extra,
      listFormat: requestOptions.listFormat,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }
}
