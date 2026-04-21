import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/utils/plex_http_exception.dart';

void main() {
  group('PlexHttpException.from', () {
    final uri = Uri.parse('http://example/api/thing');

    test('returns same instance for PlexHttpException input (no re-wrap)', () {
      final original = PlexHttpException(type: PlexHttpErrorType.connectionError, message: 'boom', requestUri: uri);
      final result = PlexHttpException.from(original, uri: uri);
      expect(identical(result, original), isTrue);
    });

    test('TimeoutException -> connectionTimeout', () {
      final tm = TimeoutException('took too long', const Duration(seconds: 1));
      final result = PlexHttpException.from(tm, uri: uri);
      expect(result.type, PlexHttpErrorType.connectionTimeout);
      expect(result.message, 'took too long');
      expect(result.requestUri, uri);
    });

    test('SocketException -> connectionError', () {
      final result = PlexHttpException.from(const SocketException('refused'), uri: uri);
      expect(result.type, PlexHttpErrorType.connectionError);
      expect(result.message, 'refused');
      expect(result.requestUri, uri);
    });

    test('HttpException -> connectionError', () {
      final result = PlexHttpException.from(const HttpException('bad header'), uri: uri);
      expect(result.type, PlexHttpErrorType.connectionError);
      expect(result.message, 'bad header');
      expect(result.requestUri, uri);
    });

    test('http.ClientException -> connectionError, prefers error.uri over passed uri', () {
      final clientUri = Uri.parse('http://other/path');
      final ex = http.ClientException('bad', clientUri);
      final result = PlexHttpException.from(ex, uri: uri);
      expect(result.type, PlexHttpErrorType.connectionError);
      expect(result.message, 'bad');
      expect(result.requestUri, clientUri);
    });

    test('http.ClientException with null uri falls back to passed uri', () {
      final ex = http.ClientException('bad');
      final result = PlexHttpException.from(ex, uri: uri);
      expect(result.requestUri, uri);
    });

    test('RequestAbortedException maps to cancelled (not connectionError) despite extending ClientException', () {
      final abortUri = Uri.parse('http://abort/x');
      final ex = http.RequestAbortedException(abortUri);
      final result = PlexHttpException.from(ex, uri: uri);
      expect(result.type, PlexHttpErrorType.cancelled);
      expect(result.requestUri, abortUri);
    });

    test('RequestAbortedException with no uri falls back to passed uri', () {
      final ex = http.RequestAbortedException();
      final result = PlexHttpException.from(ex, uri: uri);
      expect(result.type, PlexHttpErrorType.cancelled);
      expect(result.requestUri, uri);
    });

    test('unknown error -> unknown type with toString() message', () {
      final result = PlexHttpException.from(Exception('weird'), uri: uri);
      expect(result.type, PlexHttpErrorType.unknown);
      expect(result.message, contains('weird'));
      expect(result.requestUri, uri);
    });

    test('no uri passed -> requestUri is null for non-ClientException', () {
      final result = PlexHttpException.from(TimeoutException('t'));
      expect(result.requestUri, isNull);
    });

    test('toString includes type and message', () {
      final e = PlexHttpException(type: PlexHttpErrorType.cancelled, message: 'halt');
      expect(e.toString(), 'PlexHttpException(cancelled: halt)');
    });
  });
}
