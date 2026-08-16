import 'app_logger.dart';
import 'platform_detector.dart';

class TextInputDiagnostics {
  /// Compile-time switch: run with
  /// `--dart-define=PLEZY_TEXT_INPUT_DIAGNOSTICS=true` to enable. Const so the
  /// guarded branches (and their log-string interpolation) compile out of
  /// every normal build.
  static const bool enabled = bool.fromEnvironment('PLEZY_TEXT_INPUT_DIAGNOSTICS');

  static void log(String source, String message) {
    if (!enabled || !PlatformDetector.isTV()) return;
    appLogger.i('TextInputDiag $source: $message');
  }
}
