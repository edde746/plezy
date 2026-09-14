import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/android_exit_diagnostics.dart';
import 'package:plezy/utils/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup phase vocabulary is fixed and elapsed logging is monotonic', () async {
    expect(AndroidStartupPhase.values.map((phase) => phase.id), [
      'native_on_create',
      'dart_main',
      'runApp',
      'first_frame',
      'database_open_started',
      'database_ready',
      'credentials_loaded',
      'binding_started',
      'binding_settled',
      'main_screen',
    ]);
    expect(AndroidUiState.values.map((state) => state.id), ['main_screen', 'player']);

    MemoryLogOutput.clearLogs();
    AndroidExitDiagnostics.markTelemetryReady();
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.databaseOpenStarted);
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.databaseReady);
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.credentialsLoaded);
    await Future<void>.delayed(Duration.zero);

    final messages = MemoryLogOutput.getLogs()
        .map((entry) => entry.message)
        .where((message) => message.startsWith('Startup phase:'))
        .toList()
        .reversed
        .toList();
    expect(messages, hasLength(3));
    expect(messages[0], contains('phase=database_open_started'));
    expect(messages[1], contains('phase=database_ready'));
    expect(messages[2], contains('phase=credentials_loaded'));

    final elapsed = messages
        .map((message) => int.parse(RegExp(r'elapsedMs=(\d+)').firstMatch(message)!.group(1)!))
        .toList();
    expect(elapsed[1], greaterThanOrEqualTo(elapsed[0]));
    expect(elapsed[2], greaterThanOrEqualTo(elapsed[1]));
  });
}
