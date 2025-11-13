import 'package:logger/logger.dart';

/// Redacts sensitive information from log messages
String _redactSensitiveData(String message) {
  String redacted = message;

  // Redact Plex tokens (alphanumeric strings typically 20+ characters)
  // Pattern: X-Plex-Token=... or token=... or accessToken=... or similar
  redacted = redacted.replaceAllMapped(
    RegExp(r'([Tt]oken[=:]\s*)([A-Za-z0-9_-]{10,})', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED]',
  );

  // Redact authorization headers
  redacted = redacted.replaceAllMapped(
    RegExp(
      r'([Aa]uthorization[=:]\s*)([A-Za-z0-9_\-\.]+)',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[REDACTED]',
  );

  // Redact API keys
  redacted = redacted.replaceAllMapped(
    RegExp(r'([Aa]pi[Kk]ey[=:]\s*)([A-Za-z0-9_-]{10,})', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED]',
  );

  // Redact passwords
  redacted = redacted.replaceAllMapped(
    RegExp(r'([Pp]assword[=:]\s*)([^\s&,;]+)', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED]',
  );

  // Redact full URLs with tokens in query parameters
  redacted = redacted.replaceAllMapped(
    RegExp(
      r'(https?://[^\s]*[?&])([Xx]-[Pp]lex-[Tt]oken|token)=([A-Za-z0-9_-]+)',
    ),
    (match) => '${match.group(1)}${match.group(2)}=[REDACTED]',
  );

  // Redact IP addresses in dot notation (e.g., 192.168.1.100)
  redacted = redacted.replaceAllMapped(
    RegExp(r'\b(\d{1,3}\.)(\d{1,3}\.)(\d{1,3}\.)(\d{1,3})\b'),
    (match) => '${match.group(1)}***.***.${match.group(4)}',
  );

  // Redact IP addresses in dash notation (e.g., 192-168-1-11)
  redacted = redacted.replaceAllMapped(
    RegExp(r'\b(\d{1,3}-)(\d{1,3}-)(\d{1,3}-)(\d{1,3})\b'),
    (match) => '${match.group(1)}***-***-${match.group(4)}',
  );

  // Redact standalone token-like strings (20+ alphanumeric characters)
  // Only if they appear in common token contexts
  redacted = redacted.replaceAllMapped(RegExp(r'\b([A-Za-z0-9_-]{20,})\b'), (
    match,
  ) {
    final token = match.group(1)!;
    // Only redact if it looks like a token (mixed case or contains hyphens/underscores)
    if (token.contains(RegExp(r'[A-Z]')) && token.contains(RegExp(r'[a-z]')) ||
        token.contains('_') ||
        token.contains('-')) {
      return '[REDACTED_TOKEN]';
    }
    return token;
  });

  return redacted;
}

/// Represents a single log entry stored in memory
class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// Estimate the memory size of this log entry in bytes
  int get estimatedSize {
    int size = 0;
    // DateTime: ~8 bytes
    size += 8;
    // Level enum: ~4 bytes
    size += 4;
    // Message string: 2 bytes per character (UTF-16)
    size += message.length * 2;
    // Error string: 2 bytes per character if present
    if (error != null) {
      size += error.toString().length * 2;
    }
    // Stack trace string: 2 bytes per character if present
    if (stackTrace != null) {
      size += stackTrace.toString().length * 2;
    }
    return size;
  }
}

/// Custom log output that stores logs in memory with a circular buffer
class MemoryLogOutput extends LogOutput {
  static const int maxLogSizeBytes = 5 * 1024 * 1024; // 5 MB
  static final List<LogEntry> _logs = [];
  static int _currentSize = 0;

  /// Get all stored logs (newest first)
  static List<LogEntry> getLogs() => List.unmodifiable(_logs.reversed);

  /// Clear all stored logs
  static void clearLogs() {
    _logs.clear();
    _currentSize = 0;
  }

  /// Get current log buffer size in bytes
  static int getCurrentSize() => _currentSize;

  /// Get current log buffer size in MB
  static double getCurrentSizeMB() => _currentSize / (1024 * 1024);

  @override
  void output(OutputEvent event) {
    // Extract relevant information from the log event
    for (var line in event.lines) {
      final logEntry = LogEntry(
        timestamp: DateTime.now(),
        level: event.level,
        message: _redactSensitiveData(line),
      );

      _logs.add(logEntry);
      _currentSize += logEntry.estimatedSize;

      // Maintain buffer size limit (remove oldest entries)
      while (_currentSize > maxLogSizeBytes && _logs.isNotEmpty) {
        final removed = _logs.removeAt(0);
        _currentSize -= removed.estimatedSize;
      }
    }
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
    final error = event.error != null
        ? _redactSensitiveData(event.error.toString())
        : null;

    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      level: event.level,
      message: message,
      error: error,
      stackTrace: event.stackTrace,
    );

    MemoryLogOutput._logs.add(logEntry);
    MemoryLogOutput._currentSize += logEntry.estimatedSize;

    // Maintain buffer size limit (remove oldest entries)
    while (MemoryLogOutput._currentSize > MemoryLogOutput.maxLogSizeBytes &&
        MemoryLogOutput._logs.isNotEmpty) {
      final removed = MemoryLogOutput._logs.removeAt(0);
      MemoryLogOutput._currentSize -= removed.estimatedSize;
    }

    // Delegate to wrapped printer for console output
    return _wrappedPrinter.log(event);
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

/// Global filter instance
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

  // Update the filter level
  _productionFilter.setLevel(newLevel);

  // Recreate the logger instance with the new level
  // This ensures it works in release mode where Logger.level might be optimized away
  appLogger = Logger(
    printer: MemoryAwareLogPrinter(SimplePrinter()),
    filter: _productionFilter,
    level: newLevel,
  );

  // Also set the static level for consistency
  Logger.level = newLevel;
}
