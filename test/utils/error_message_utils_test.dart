import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/i18n/strings.g.dart';
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
}

class _RecordingLogOutput extends LogOutput {
  int writeCount = 0;

  @override
  void output(OutputEvent event) {
    writeCount++;
  }
}
