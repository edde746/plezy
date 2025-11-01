import 'package:logger/logger.dart';

/// Centralized logger instance for the application.
///
/// Usage:
/// ```dart
/// import 'package:plezy/utils/app_logger.dart';
///
/// appLogger.d('Debug message');
/// appLogger.i('Info message');
/// appLogger.w('Warning message');
/// appLogger.e('Error message', error: e, stackTrace: stackTrace);
/// ```
final appLogger = Logger(printer: SimplePrinter(), level: Level.debug);
