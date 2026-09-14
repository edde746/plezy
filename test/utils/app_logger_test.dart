import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

void main() {
  late MemoryAwareLogPrinter printer;

  setUp(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    printer = MemoryAwareLogPrinter(SimplePrinter());
  });

  tearDown(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  test('redacts message, error, and stack trace before storage and rendering', () {
    const messageSecret = 'message.value-_/+~==';
    const errorSecret = 'error.value-_/+~==';
    const stackSecret = 'stack.value-_/+~==';
    const passwordSecret = 'password.value-_/+~==';
    final stackTrace = StackTrace.fromString(
      '#0 connect (Authorization: Bearer $stackSecret)\n'
      '#1 retry (package:plezy/connect.dart:12:4)',
    );

    final renderedLines = printer.log(
      LogEvent(
        Level.error,
        'connect operation Authorization: Bearer $messageSecret status=pending',
        error:
            'request failed Authorization=Basic $errorSecret '
            '{"password":"$passwordSecret","status":401}',
        stackTrace: stackTrace,
      ),
    );

    final rendered = renderedLines.join('\n');
    final stored = MemoryLogOutput.getLogs().single;
    final storedText = '${stored.message}\n${stored.error}\n${stored.stackTrace}';

    for (final secret in [messageSecret, errorSecret, passwordSecret]) {
      expect(rendered, isNot(contains(secret)));
    }
    for (final secret in [messageSecret, errorSecret, passwordSecret, stackSecret]) {
      expect(storedText, isNot(contains(secret)));
    }
    expect(rendered, contains('connect operation'));
    expect(rendered, contains('status=pending'));
    expect(rendered, contains('request failed'));
    expect(rendered, contains('"status":401'));
    expect(storedText, contains('connect operation'));
    expect(storedText, contains('"status":401'));
    expect(storedText, contains('#1 retry'));
    expect(storedText, contains('#0 connect'));
  });

  test('applies registered literal redaction to every logger field', () {
    const registeredToken = 'registered-token-sentinel';
    const registeredError = 'registered-error-sentinel';
    const registeredStack = 'registered-stack-sentinel';
    LogRedactionManager.registerToken(registeredToken);
    LogRedactionManager.registerCustomValue(registeredError);
    LogRedactionManager.registerCustomValue(registeredStack);

    final rendered = MemoryAwareLogPrinter(_FieldRenderingPrinter())
        .log(
          LogEvent(
            Level.warning,
            'operation=refresh credential=$registeredToken status=starting',
            error: 'category=remote detail=$registeredError status=failed',
            stackTrace: StackTrace.fromString('#0 refresh $registeredStack\n#1 caller preserved'),
          ),
        )
        .join('\n');
    final stored = MemoryLogOutput.getLogs().single;
    final storedText = '${stored.message}\n${stored.error}\n${stored.stackTrace}';

    for (final secret in [registeredToken, registeredError, registeredStack]) {
      expect(rendered, isNot(contains(secret)));
      expect(storedText, isNot(contains(secret)));
    }
    expect(rendered, contains('operation=refresh'));
    expect(rendered, contains('status=failed'));
    expect(rendered, contains('#1 caller preserved'));
  });
}

class _FieldRenderingPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return ['${event.message}\n${event.error}\n${event.stackTrace}'];
  }
}
