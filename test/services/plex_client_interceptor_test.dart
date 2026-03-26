import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/plex_url_helper.dart';

// Builds a Dio instance wired with the same security interceptor logic used in
// PlexClient._() so we can test it without constructing a full PlexClient
// (which requires network access via _initMediaProviders).
Dio _buildDio({required String baseUrl, String? token}) {
  final config = _FakeConfig(baseUrl: baseUrl, token: token);

  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final headerToken = options.headers['X-Plex-Token'];
        final queryToken = options.queryParameters['X-Plex-Token'];
        final uriToken = options.uri.queryParameters['X-Plex-Token'];

        if (headerToken != null || queryToken != null || uriToken != null) {
          final fullUrl = options.uri.toString();
          if (!PlexUrlHelper.isSecureDestination(fullUrl, config.baseUrl)) {
            options.headers.remove('X-Plex-Token');

            if (options.queryParameters.containsKey('X-Plex-Token')) {
              options.queryParameters.remove('X-Plex-Token');
            }

            if (uriToken != null) {
              final originalPathUri = Uri.parse(options.path);
              if (originalPathUri.queryParameters.containsKey('X-Plex-Token')) {
                final pathQueryParameters = Map<String, List<String>>.from(originalPathUri.queryParametersAll);
                pathQueryParameters.remove('X-Plex-Token');
                options.path = originalPathUri.replace(
                  queryParameters: pathQueryParameters.isEmpty ? {} : pathQueryParameters,
                ).toString();
              }
            }
          }
        }
        return handler.next(options);
      },
    ),
  );

  // Capture the request options before any real network call is made.
  dio.httpClientAdapter = _CapturingAdapter();

  return dio;
}

class _FakeConfig {
  final String baseUrl;
  final String? token;
  _FakeConfig({required this.baseUrl, this.token});
}

/// Adapter that records the final RequestOptions and returns a 200 response.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    captured = options;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const secureBase = 'http://192.168.1.100:32400';
  const insecureUrl = 'https://example.com/data';

  group('PlexClient security interceptor – header token', () {
    test('strips X-Plex-Token header when destination is insecure', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get(insecureUrl, options: Options(headers: {'X-Plex-Token': 'secret'}));

      expect(adapter.captured!.headers.containsKey('X-Plex-Token'), isFalse);
    });

    test('preserves X-Plex-Token header when destination is the configured base URL', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get('$secureBase/library/sections',
          options: Options(headers: {'X-Plex-Token': 'secret'}));

      expect(adapter.captured!.headers['X-Plex-Token'], 'secret');
    });

    test('preserves X-Plex-Token header when destination is plex.tv', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get('https://plex.tv/api/v2/user',
          options: Options(headers: {'X-Plex-Token': 'secret'}));

      expect(adapter.captured!.headers['X-Plex-Token'], 'secret');
    });
  });

  group('PlexClient security interceptor – query parameter token', () {
    test('strips X-Plex-Token query param when destination is insecure', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get(insecureUrl, queryParameters: {'X-Plex-Token': 'secret', 'foo': 'bar'});

      expect(adapter.captured!.queryParameters.containsKey('X-Plex-Token'), isFalse);
      // Other query params are preserved
      expect(adapter.captured!.queryParameters['foo'], 'bar');
    });

    test('preserves X-Plex-Token query param when destination is the base URL', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get('$secureBase/playback', queryParameters: {'X-Plex-Token': 'secret'});

      expect(adapter.captured!.queryParameters['X-Plex-Token'], 'secret');
    });

    test('does not affect request when no token is present', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get(insecureUrl, queryParameters: {'foo': 'bar'});

      expect(adapter.captured!.queryParameters.containsKey('X-Plex-Token'), isFalse);
      expect(adapter.captured!.queryParameters['foo'], 'bar');
    });
  });

  group('PlexClient security interceptor – token baked into URI path', () {
    test('strips X-Plex-Token baked into path when destination is insecure', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      // Token embedded directly in the path string
      await dio.get('https://example.com/data?X-Plex-Token=secret&quality=high');

      final uri = Uri.parse(adapter.captured!.path);
      expect(uri.queryParameters.containsKey('X-Plex-Token'), isFalse);
      // Other params in path are preserved
      expect(uri.queryParameters['quality'], 'high');
    });

    test('strips token from path even when queryParameters map is also cleared', () async {
      final dio = _buildDio(baseUrl: secureBase);
      final adapter = dio.httpClientAdapter as _CapturingAdapter;

      await dio.get('https://example.com/data?X-Plex-Token=secret');

      final uri = Uri.parse(adapter.captured!.path);
      expect(uri.queryParameters.containsKey('X-Plex-Token'), isFalse);
      expect(adapter.captured!.queryParameters.containsKey('X-Plex-Token'), isFalse);
      expect(adapter.captured!.headers.containsKey('X-Plex-Token'), isFalse);
    });
  });
}
