import 'dart:collection';

import 'package:logger/logger.dart';

import 'log_redaction_manager.dart';

/// Redacts sensitive information from log messages based on known values.
String _redactSensitiveData(String message) {
  var redacted = LogRedactionManager.redact(message);

  // Fallbacks for sensitive fields we cannot track ahead of time.
  redacted = redacted.replaceAllMapped(
    RegExp(r'([Aa]uthorization[=:]\s*)([^\s,]+)'),
    (match) => '${match.group(1)}[REDACTED]',
  );

  redacted = redacted.replaceAllMapped(
    RegExp(r'([Pp]assword[=:]\s*)([^\s&,;]+)'),
    (match) => '${match.group(1)}[REDACTED]',
  );

  return redacted;
}

/// Represents a single log entry stored in memory
class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({required this.timestamp, required this.level, required this.message, this.error, this.stackTrace});

  /// Estimate the memory size of this log entry in bytes
  int get estimatedSize {
    int size = 0;
    size += 8;
    size += 4;
    size += message.length * 2;
    if (error != null) {
      size += error.toString().length * 2;
    }
    if (stackTrace != null) {
      size += stackTrace.toString().length * 2;
    }
    return size;
  }
}

/// Custom log output that stores logs in memory with a circular buffer
///
/// Storage is handled by [MemoryAwareLogPrinter.log()] — this class only
/// forwards formatted lines to the console via the default [ConsoleOutput].
class MemoryLogOutput extends LogOutput {
  static const int maxLogSizeBytes = 5 * 1024 * 1024;
  static final ListQueue<LogEntry> _logs = ListQueue<LogEntry>();
  static int _currentSize = 0;

  static final _consoleOutput = ConsoleOutput();

  static List<LogEntry> getLogs() => _logs.toList().reversed.toList();

  static void clearLogs() {
    _logs.clear();
    _currentSize = 0;
  }

  static int getCurrentSize() => _currentSize;

  static double getCurrentSizeMB() => _currentSize / (1024 * 1024);

  @override
  void output(OutputEvent event) {
    // Only print to console — storage is done in MemoryAwareLogPrinter.log()
    _consoleOutput.output(event);
  }
}

/// Custom log printer that also stores error and stack trace information
class MemoryAwareLogPrinter extends LogPrinter {
  final LogPrinter _wrappedPrinter;

  MemoryAwareLogPrinter(this._wrappedPrinter);

  @override
  List<String> log(LogEvent event) {
    // Store the log with error and stack trace if available
    final message = _redactSensitiveData(event.message.toString());
    final error = event.error != null ? _redactSensitiveData(event.error.toString()) : null;

    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      level: event.level,
      message: message,
      error: error,
      stackTrace: event.stackTrace,
    );

    MemoryLogOutput._logs.add(logEntry);
    MemoryLogOutput._currentSize += logEntry.estimatedSize;

    // Maintain buffer size limit (remove oldest entries) — O(1) with ListQueue
    while (MemoryLogOutput._currentSize > MemoryLogOutput.maxLogSizeBytes && MemoryLogOutput._logs.isNotEmpty) {
      final removed = MemoryLogOutput._logs.removeFirst();
      MemoryLogOutput._currentSize -= removed.estimatedSize;
    }

    return _wrappedPrinter.log(
      LogEvent(event.level, message, time: event.time, error: error, stackTrace: event.stackTrace),
    );
  }
}

/// Custom production filter that respects our level setting even in release mode
class ProductionFilter extends LogFilter {
  Level _currentLevel = Level.debug;

  void setLevel(Level level) {
    _currentLevel = level;
  }

  @override
  bool shouldLog(LogEvent event) {
    return event.level.value >= _currentLevel.value;
  }
}

final _productionFilter = ProductionFilter();

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
Logger appLogger = Logger(
  printer: MemoryAwareLogPrinter(SimplePrinter()),
  filter: _productionFilter,
  level: Level.debug,
);

/// Update the logger's level dynamically based on debug setting
/// Recreates the logger instance to ensure it works in release mode
void setLoggerLevel(bool debugEnabled) {
  final newLevel = debugEnabled ? Level.debug : Level.info;

  _productionFilter.setLevel(newLevel);

  appLogger = Logger(printer: MemoryAwareLogPrinter(SimplePrinter()), filter: _productionFilter, level: newLevel);

  Logger.level = newLevel;
}
