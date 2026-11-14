import 'dart:collection';

import 'package:logger/logger.dart';

import 'log_redaction_manager.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

/// Mirrors the log to a file so a run can be read *after* it happened.
///
/// The buffer above is memory-only, so anything learned on a device dies with
/// the process: a console is only attached while a debugger is, and by the
/// time a problem is described it is already gone. One file in the app's
/// support directory can be pulled off the device with
/// `devicectl device copy from`, which is the only way to see what a build
/// running on real hardware actually did.
///
/// Always on in debug and profile builds. A release build writes only while
/// the debug-logging setting is on.
abstract final class _SessionLogFile {
  static const String fileName = 'plezy-session.log';
  static const String previousFileName = 'plezy-session.prev.log';
  static const int maxBytes = 4 * 1024 * 1024;

  static IOSink? _sink;
  static bool _startedOpening = false;
  static int _written = 0;
  static final List<String> _pending = [];
  static bool _draining = false;

  static bool _enabled = kDebugMode || kProfileMode;

  /// Follows `SettingsService.enableDebugLogging`.
  static void setEnabled(bool enabled) {
    _enabled = enabled || kDebugMode || kProfileMode;
  }

  static void write(LogEntry entry) {
    if (!_enabled) return;
    if (!_startedOpening) {
      _startedOpening = true;
      unawaited(_open());
    }
    if (_written > maxBytes) return;
    final line =
        '${entry.timestamp.toIso8601String()} [${entry.level.name}] ${entry.message}'
        '${entry.error == null ? '' : '  ERROR: ${entry.error}'}';
    _written += line.length + 1;
    _pending.add(line);
    unawaited(_drain());
  }

  /// Lines go out in batches, one flush at a time: an [IOSink] throws if it is
  /// written to while a flush is pending, so a burst of lines cannot each flush
  /// their own.
  static Future<void> _drain() async {
    final sink = _sink;
    if (sink == null || _draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        final batch = _pending.join('\n');
        _pending.clear();
        sink.writeln(batch);
        await sink.flush();
      }
    } catch (_) {
      // A failed sink must never take the app down with it.
      _sink = null;
      _pending.clear();
    } finally {
      _draining = false;
    }
  }

  static Future<void> _open() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$fileName');
      // The previous session is kept beside the current one. Truncating on
      // every launch lost exactly the run worth reading: anything that
      // restarts the app after a problem — a test harness, a crash, the user
      // reopening it to describe what happened — took the evidence with it.
      try {
        if (file.existsSync()) file.renameSync('${dir.path}/$previousFileName');
      } catch (_) {
        // A missing or unrenameable previous file is not worth failing over.
      }
      // Deliberately never closed: it lives for the process, and closing it
      // on the way down would lose exactly the lines that explain why.
      // ignore: close_sinks
      final sink = file.openWrite(mode: FileMode.write);
      sink.writeln('--- session started ${DateTime.now().toIso8601String()} ---');
      _sink = sink;
      unawaited(_drain());
    } catch (_) {
      _sink = null;
    }
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

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: event.level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    MemoryLogOutput.add(entry);
    // Here rather than in a LogOutput: `appLogger` is built without an
    // `output:`, so this printer is the one path every line takes.
    _SessionLogFile.write(entry);

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

/// Whether the session log file is being written. Follows the same switch.
void setSessionLogEnabled(bool enabled) => _SessionLogFile.setEnabled(enabled);

/// Update the logger's level dynamically based on the debug setting.
///
/// [ProductionFilter] is the only gate: [Logger] asks its filter on every
/// event, so changing the filter level is sufficient even in release mode.
void setLoggerLevel(bool debugEnabled) {
  setSessionLogEnabled(debugEnabled);
  _productionFilter.setLevel(debugEnabled ? Level.debug : Level.info);
}
