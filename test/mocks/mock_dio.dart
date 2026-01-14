import 'package:dio/dio.dart';

/// A mock Dio client for testing purposes.
/// Allows setting up expected responses for HTTP requests.
class MockDio implements Dio {
  final List<MockResponse> _responses = [];
  final List<RequestLog> requestLog = [];

  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors get interceptors => Interceptors();

  /// Add an expected response for a given path and method
  void mockResponse({
    required String path,
    required String method,
    dynamic data,
    int statusCode = 200,
    Map<String, dynamic>? headers,
  }) {
    _responses.add(MockResponse(
      path: path,
      method: method.toUpperCase(),
      data: data,
      statusCode: statusCode,
      headers: headers ?? {},
    ));
  }

  /// Clear all mocked responses
  void clearMocks() {
    _responses.clear();
    requestLog.clear();
  }

  Response<T> _findResponse<T>(String path, String method, {dynamic data, Map<String, dynamic>? queryParameters}) {
    requestLog.add(RequestLog(
      path: path,
      method: method,
      data: data,
      queryParameters: queryParameters,
    ));

    final mock = _responses.firstWhere(
      (r) => r.path == path && r.method == method.toUpperCase(),
      orElse: () => throw DioException(
        requestOptions: RequestOptions(path: path),
        message: 'No mock response found for $method $path',
        type: DioExceptionType.unknown,
      ),
    );

    return Response<T>(
      requestOptions: RequestOptions(path: path, method: method),
      data: mock.data as T?,
      statusCode: mock.statusCode,
      headers: Headers.fromMap(
        mock.headers.map((key, value) => MapEntry(key, [value.toString()])),
      ),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _findResponse<T>(path, 'GET', data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _findResponse<T>(path, 'POST', data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _findResponse<T>(path, 'PUT', data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _findResponse<T>(path, 'DELETE', data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _findResponse<T>(path, 'PATCH', data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _findResponse<T>(path, 'HEAD', data: data, queryParameters: queryParameters);
  }

  // Not implemented methods - throw if called
  @override
  void close({bool force = false}) {}

  @override
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final method = options?.method ?? 'GET';
    return _findResponse<T>(path, method, data: data, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    Object? data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return request<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return get<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> postUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return post<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> putUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return put<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return delete<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return patch<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response<T>> headUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return head<T>(uri.toString(), data: data, options: options);
  }

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    throw UnimplementedError('download is not mocked');
  }

  @override
  Future<Response> downloadUri(
    Uri uri,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    throw UnimplementedError('downloadUri is not mocked');
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    return request<T>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(method: requestOptions.method),
    );
  }

  @override
  HttpClientAdapter get httpClientAdapter => throw UnimplementedError();

  @override
  set httpClientAdapter(HttpClientAdapter adapter) {}

  @override
  Transformer get transformer => throw UnimplementedError();

  @override
  set transformer(Transformer transformer) {}
}

/// Represents a mocked HTTP response
class MockResponse {
  final String path;
  final String method;
  final dynamic data;
  final int statusCode;
  final Map<String, dynamic> headers;

  MockResponse({
    required this.path,
    required this.method,
    this.data,
    this.statusCode = 200,
    this.headers = const {},
  });
}

/// Log of requests made to the mock Dio client
class RequestLog {
  final String path;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;

  RequestLog({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
  });
}
