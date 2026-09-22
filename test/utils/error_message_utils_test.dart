import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/utils/app_logger.dart' as logging;
import 'package:plezy/utils/error_message_utils.dart';

void main() {
  late Logger originalLogger;
  late _RecordingLogOutput logOutput;

  setUpAll(() async => LocaleSettings.setLocale(AppLocale.es));
  tearDownAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() {
    originalLogger = logging.appLogger;
    logOutput = _RecordingLogOutput();
    logging.appLogger = Logger(printer: SimplePrinter(), output: logOutput);
  });

  tearDown(() {
    logging.appLogger = originalLogger;
  });

  group('localizedLoadErrorMessage', () {
    test('distinguishes connection timeouts from connection failures', () {
      for (final type in [MediaServerHttpErrorType.connectionTimeout, MediaServerHttpErrorType.receiveTimeout]) {
        final message = localizedLoadErrorMessage(
          MediaServerHttpException(type: type, message: 'private timeout detail'),
          StackTrace.current,
          context: 'Biblioteca',
        );

        expect(message, 'Tiempo de conexión agotado al cargar Biblioteca');
        expect(message, isNot(contains('private timeout detail')));
      }

      final connectionMessage = localizedLoadErrorMessage(
        MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'private connection detail'),
        StackTrace.current,
        context: 'Biblioteca',
      );

      expect(connectionMessage, 'No se puede conectar al servidor multimedia');
      expect(connectionMessage, isNot(contains('private connection detail')));
    });

    test('logs an unexpected failure once and returns only the localized fallback', () {
      const privateDetail = 'token=super-secret';

      final message = localizedLoadErrorMessage(StateError(privateDetail), StackTrace.current, context: 'Biblioteca');

      expect(message, 'No se pudo cargar Biblioteca. Inténtalo de nuevo.');
      expect(message, isNot(contains(privateDetail)));
      expect(logOutput.writeCount, 1);
    });

    test('never exposes server status text, response data, or exception messages', () {
      const serverText = 'database failed for user@example.com';
      final error = MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        statusCode: 500,
        message: serverText,
        responseData: {'error': serverText},
      );

      final message = localizedLoadErrorMessage(error, StackTrace.current, context: 'Biblioteca');

      expect(message, 'No se pudo cargar Biblioteca. Inténtalo de nuevo.');
      expect(message, isNot(contains('500')));
      expect(message, isNot(contains(serverText)));
    });
  });

  group('localizedErrorReason', () {
    test('prefers the exception own display text', () {
      final error = MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionError,
        message: 'socket closed',
        display: 'El servidor rechazó la conexión',
      );

      expect(localizedErrorReason(error), 'El servidor rechazó la conexión');
    });

    test('distinguishes the failure kinds a caller can act on differently', () {
      String reason(MediaServerHttpErrorType type, {int? status}) =>
          localizedErrorReason(MediaServerHttpException(type: type, statusCode: status));

      final timedOut = reason(MediaServerHttpErrorType.connectionTimeout);
      final unreachable = reason(MediaServerHttpErrorType.connectionError);
      final refused = reason(MediaServerHttpErrorType.unknown, status: 403);
      final gone = reason(MediaServerHttpErrorType.unknown, status: 404);
      final serverSide = reason(MediaServerHttpErrorType.unknown, status: 503);

      expect(reason(MediaServerHttpErrorType.receiveTimeout), timedOut);
      expect({timedOut, unreachable, refused, gone, serverSide}, hasLength(5));
      expect(localizedErrorReason(Exception('boom')), isNot(anyOf(timedOut, unreachable, refused, gone, serverSide)));
    });

    test('keeps the specific reason from a display-safe playback failure', () {
      const error = PlaybackException('Stream selection is not available for this source');

      expect(localizedErrorReason(error), 'Stream selection is not available for this source');
    });

    test('never leaks the request host, path, status or exception text', () {
      const serverText = 'Internal Server Error at /library/metadata/42';
      final error = MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        message: serverText,
        statusCode: 500,
        responseData: {'error': serverText},
        requestUri: Uri.parse('https://media.example.test/library/metadata/42?X-Plex-Token=secret'),
      );

      final reason = localizedErrorReason(error);

      expect(reason, isNotEmpty);
      expect(reason, isNot(contains('500')));
      expect(reason, isNot(contains(serverText)));
      expect(reason, isNot(contains('media.example.test')));
      expect(reason, isNot(contains('/library/metadata')));
      expect(reason, isNot(contains('secret')));
      expect(reason, isNot(contains('MediaServerHttpException')));
    });
  });
}

class _RecordingLogOutput extends LogOutput {
  int writeCount = 0;

  @override
  void output(OutputEvent event) {
    writeCount++;
  }
}
