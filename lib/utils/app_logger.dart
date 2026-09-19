import 'dart:collection';

import 'package:logger/logger.dart';

import 'log_redaction_manager.dart';

/// Represents a single log entry stored in memory
class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({required this.timestamp, required this.level, required this.message, this.error, this.stackTrace});

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

/// In-memory log store with a circular buffer.
///
/// Fed by [MemoryAwareLogPrinter.log()]; console output goes through the
/// logger's default [ConsoleOutput].
class MemoryLogOutput {
  static const int maxLogSizeBytes = 5 * 1024 * 1024;
  static final ListQueue<LogEntry> _logs = ListQueue<LogEntry>();
  static int _currentSize = 0;

  /// Append [entry], evicting the oldest entries once the buffer exceeds
  /// [maxLogSizeBytes] — O(1) with ListQueue.
  static void add(LogEntry entry) {
    _logs.add(entry);
    _currentSize += entry.estimatedSize;
    while (_currentSize > maxLogSizeBytes && _logs.isNotEmpty) {
      _currentSize -= _logs.removeFirst().estimatedSize;
    }
  }

  static List<LogEntry> getLogs() => _logs.toList().reversed.toList();

  static void clearLogs() {
    _logs.clear();
    _currentSize = 0;
  }
}

/// Custom log printer that also stores error and stack trace information
class MemoryAwareLogPrinter extends LogPrinter {
  final LogPrinter _wrappedPrinter;

  MemoryAwareLogPrinter(this._wrappedPrinter);

  @override
  List<String> log(LogEvent event) {
    final message = LogRedactionManager.redact(event.message.toString());
    final error = event.error != null ? LogRedactionManager.redact(event.error.toString()) : null;
    final stackTrace = event.stackTrace != null
        ? StackTrace.fromString(LogRedactionManager.redact(event.stackTrace.toString()))
        : null;

    MemoryLogOutput.add(
      LogEntry(timestamp: DateTime.now(), level: event.level, message: message, error: error, stackTrace: stackTrace),
    );

    return _wrappedPrinter.log(LogEvent(event.level, message, time: event.time, error: error, stackTrace: stackTrace));
  }
}

/// Custom production filter that respects our level setting even in release mode
class ProductionFilter extends LogFilter {
  Level _currentLevel = Level.debug;

  void setLevel(Level level) {
    _currentLevel = level;
  }

  bool isEnabledFor(Level level) => level.value >= _currentLevel.value;

  @override
  bool shouldLog(LogEvent event) => isEnabledFor(event.level);
}

final _productionFilter = ProductionFilter();

/// Whether [appLogger].d would actually emit.
///
/// Dart builds a log call's message argument *before* the filter can drop it,
/// so a `.d()` whose message costs real work — string interpolation in a loop,
/// `redact()`, `jsonEncode`, a collection `toString()` — pays that cost on
/// every call in release, where the line is then discarded. Guard those call
/// sites with this; plain constant or cheap messages need no guard.
bool get debugLoggingEnabled => _productionFilter.isEnabledFor(Level.debug);

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
///
/// Non-final so tests can swap in a recording logger.
Logger appLogger = Logger(printer: MemoryAwareLogPrinter(SimplePrinter()), filter: _productionFilter);

/// Update the logger's level dynamically based on the debug setting.
///
/// [ProductionFilter] is the only gate: [Logger] asks its filter on every
/// event, so changing the filter level is sufficient even in release mode.
void setLoggerLevel(bool debugEnabled) {
  _productionFilter.setLevel(debugEnabled ? Level.debug : Level.info);
}
