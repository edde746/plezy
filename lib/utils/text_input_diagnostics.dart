import 'app_logger.dart';
import 'platform_detector.dart';

class TextInputDiagnostics {
  static bool enabled = false;

  static void log(String source, String message) {
    if (!enabled || !PlatformDetector.isTV()) return;
    appLogger.i('TextInputDiag $source: $message');
  }
}
