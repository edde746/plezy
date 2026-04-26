import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';

void main() {
  group('MediaServerHttpException.from', () {
    final uri = Uri.parse('http://example/api/thing');

    test('returns same instance for MediaServerHttpException input (no re-wrap)', () {
      final original = MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: 'boom',
        requestUri: uri,
      );
      final result = MediaServerHttpException.from(original, uri: uri);
      expect(identical(result, original), isTrue);
    });

    test('TimeoutException -> connectionTimeout', () {
      final tm = TimeoutException('took too long', const Duration(seconds: 1));
      final result = MediaServerHttpException.from(tm, uri: uri);
      expect(result.type, MediaServerHttpErrorType.connectionTimeout);
      expect(result.message, 'took too long');
      expect(result.requestUri, uri);
    });

    test('SocketException -> connectionError', () {
      final result = MediaServerHttpException.from(const SocketException('refused'), uri: uri);
      expect(result.type, MediaServerHttpErrorType.connectionError);
      expect(result.message, 'refused');
      expect(result.requestUri, uri);
    });

    test('HttpException -> connectionError', () {
      final result = MediaServerHttpException.from(const HttpException('bad header'), uri: uri);
      expect(result.type, MediaServerHttpErrorType.connectionError);
      expect(result.message, 'bad header');
      expect(result.requestUri, uri);
    });

    test('http.ClientException -> connectionError, prefers error.uri over passed uri', () {
      final clientUri = Uri.parse('http://other/path');
      final ex = http.ClientException('bad', clientUri);
      final result = MediaServerHttpException.from(ex, uri: uri);
      expect(result.type, MediaServerHttpErrorType.connectionError);
      expect(result.message, 'bad');
      expect(result.requestUri, clientUri);
    });

    test('http.ClientException with null uri falls back to passed uri', () {
      final ex = http.ClientException('bad');
      final result = MediaServerHttpException.from(ex, uri: uri);
      expect(result.requestUri, uri);
    });

    test('RequestAbortedException maps to cancelled (not connectionError) despite extending ClientException', () {
      final abortUri = Uri.parse('http://abort/x');
      final ex = http.RequestAbortedException(abortUri);
      final result = MediaServerHttpException.from(ex, uri: uri);
      expect(result.type, MediaServerHttpErrorType.cancelled);
      expect(result.requestUri, abortUri);
    });

    test('RequestAbortedException with no uri falls back to passed uri', () {
      final ex = http.RequestAbortedException();
      final result = MediaServerHttpException.from(ex, uri: uri);
      expect(result.type, MediaServerHttpErrorType.cancelled);
      expect(result.requestUri, uri);
    });

    test('unknown error -> unknown type with toString() message', () {
      final result = MediaServerHttpException.from(Exception('weird'), uri: uri);
      expect(result.type, MediaServerHttpErrorType.unknown);
      expect(result.message, contains('weird'));
      expect(result.requestUri, uri);
    });

    test('no uri passed -> requestUri is null for non-ClientException', () {
      final result = MediaServerHttpException.from(TimeoutException('t'));
      expect(result.requestUri, isNull);
    });

    test('toString includes type and message', () {
      final e = MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'halt');
      expect(e.toString(), 'MediaServerHttpException(cancelled: halt)');
    });
  });

  group('MediaServerHttpException.isTransient', () {
    MediaServerHttpException ex(MediaServerHttpErrorType t) => MediaServerHttpException(type: t);

    test('connectionTimeout is transient', () {
      expect(ex(MediaServerHttpErrorType.connectionTimeout).isTransient, isTrue);
    });

    test('receiveTimeout is transient', () {
      expect(ex(MediaServerHttpErrorType.receiveTimeout).isTransient, isTrue);
    });

    test('connectionError is transient', () {
      expect(ex(MediaServerHttpErrorType.connectionError).isTransient, isTrue);
    });

    test('cancelled is NOT transient (user-driven abort)', () {
      expect(ex(MediaServerHttpErrorType.cancelled).isTransient, isFalse);
    });

    test('unknown is NOT transient', () {
      expect(ex(MediaServerHttpErrorType.unknown).isTransient, isFalse);
    });
  });

  group('MediaServerHttpClient malformed JSON handling', () {
    test('preserves 401 status and raw body when JSON decoding fails', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => http.Response('{bad json', 401, headers: {'content-type': 'application/json'})),
      );
      addTearDown(client.close);

      await expectLater(
        client.get('/Users/Me'),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.responseData, 'responseData', '{bad json')
              .having((e) => e.requestUri?.path, 'requestUri.path', '/Users/Me'),
        ),
      );
    });

    test('preserves 500 status and raw body when JSON decoding fails', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => http.Response('{bad json', 500, headers: {'content-type': 'application/json'})),
      );
      addTearDown(client.close);

      await expectLater(
        client.get('/System/Info'),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.responseData, 'responseData', '{bad json'),
        ),
      );
    });

    test('preserves 200 status when successful JSON response is malformed', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => http.Response('{bad json', 200, headers: {'content-type': 'application/json'})),
      );
      addTearDown(client.close);

      await expectLater(
        client.get('/Items'),
        throwsA(isA<MediaServerHttpException>().having((e) => e.statusCode, 'statusCode', 200)),
      );
    });

    test('treats Content-Type header names case-insensitively', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient((_) async => http.Response('{bad json', 401, headers: {'Content-Type': 'application/json'})),
      );
      addTearDown(client.close);

      await expectLater(
        client.get('/Users/Me'),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.responseData, 'responseData', '{bad json'),
        ),
      );
    });

    test('decodes profiled JSON content types case-insensitively', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient(
          (_) async =>
              http.Response('{"ok":true}', 200, headers: {'Content-Type': 'application/json; profile="PascalCase"'}),
        ),
      );
      addTearDown(client.close);

      final response = await client.get('/Items');
      expect(response.data, {'ok': true});
    });

    test('decodes JSON when Content-Type value casing differs', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient(
          (_) async => http.Response('{"ok":true}', 200, headers: {'content-type': 'Application/JSON'}),
        ),
      );
      addTearDown(client.close);

      final response = await client.get('/Items');
      expect(response.data, {'ok': true});
    });
  });

  group('MediaServerHttpClient HTTP error handling', () {
    test('preserves requestUri for decodable HTTP errors', () async {
      final client = MediaServerHttpClient(
        baseUrl: 'https://example.test',
        client: MockClient(
          (_) async => http.Response('{"error":"nope"}', 500, headers: {'content-type': 'application/json'}),
        ),
      );
      addTearDown(client.close);

      await expectLater(
        () async => throwIfHttpError(await client.get('/System/Info')),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.requestUri?.path, 'requestUri.path', '/System/Info'),
        ),
      );
    });
  });
}
