import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';

/// Named steps of the startup gate.
///
/// The gate used to report a bare `error.runtimeType` with no indication of
/// which step failed, and `Future.wait` discarded every error but the first,
/// so even that was ambiguous between four concurrent steps (#1732). Every
/// step now carries a stable identifier that reaches the failure screen, the
/// log, the persisted record and Sentry.
enum StartupPhase {
  preferences('preferences'),
  crashReporting('crash-reporting'),
  locale('locale'),
  windowManager('window-manager'),
  deviceCapabilities('device-capabilities'),
  storage('storage'),
  database('database'),
  imageCache('image-cache'),
  downloadStorage('download-storage');

  const StartupPhase(this.id);

  /// Stable wire/log identifier. Do not rename: persisted records and Sentry
  /// tags are matched on it.
  final String id;

  static StartupPhase? fromId(String? id) =>
      id == null ? null : StartupPhase.values.where((phase) => phase.id == id).firstOrNull;
}

/// Tags a startup failure with the gate phase it came from.
///
/// Transparent by design: [cause] is the original error, so existing
/// classification (`isStorageFullError`, corrupt-store detection) keeps working
/// on `exception.cause` and the reported runtime type stays the real one.
class StartupPhaseException implements Exception {
  const StartupPhaseException(this.phase, this.cause);

  final StartupPhase phase;
  final Object cause;

  /// Unwraps nested wrappers so callers always classify the real error.
  static Object unwrap(Object error) {
    var current = error;
    while (current is StartupPhaseException) {
      current = current.cause;
    }
    return current;
  }

  static StartupPhase? phaseOf(Object error) => error is StartupPhaseException ? error.phase : null;

  @override
  String toString() => 'StartupPhaseException(${phase.id}): ${StartupFailureRecord.describeErrorSafely(cause)}';
}

/// A startup-gate failure, reduced to an allowlist of fields that are safe to
/// show, copy, persist and upload.
///
/// Redaction is defence in depth here, not the mechanism: nothing derived from
/// preference contents, database rows or file bytes is ever placed in a
/// record. That matters because `LogRedactionManager`'s registered-value set is
/// seeded by `StorageService.onInit`, which runs *inside* the gate — a failure
/// at or before that step leaves only the pattern matcher active.
class StartupFailureRecord {
  StartupFailureRecord({
    required this.phase,
    required this.errorType,
    required String message,
    required String? stackTrace,
    required this.timestamp,
    required this.appVersion,
    required this.platform,
    this.repairable = false,
  }) : message = LogRedactionManager.redact(message),
       stackTrace = stackTrace == null ? null : LogRedactionManager.redact(stackTrace);

  /// Builds a record from a thrown [error].
  ///
  /// [StartupPhaseException] wrappers are unwrapped so the recorded type and
  /// message describe the real failure, and [phase] defaults to the one the
  /// wrapper carries.
  factory StartupFailureRecord.fromError({
    required Object error,
    required StackTrace? stackTrace,
    required String appVersion,
    required String platform,
    StartupPhase? phase,
    bool repairable = false,
    DateTime? timestamp,
  }) {
    final cause = StartupPhaseException.unwrap(error);
    return StartupFailureRecord(
      phase: phase ?? StartupPhaseException.phaseOf(error),
      errorType: cause.runtimeType.toString(),
      message: describeErrorSafely(cause),
      stackTrace: stackTrace?.toString(),
      timestamp: timestamp ?? DateTime.now(),
      appVersion: appVersion,
      platform: platform,
      repairable: repairable,
    );
  }

  /// Renders [error] without the payload some exception types embed.
  ///
  /// `FormatException.toString()` prints an excerpt of `source` around
  /// `offset`, and during startup that source is very often a document we must
  /// never surface: the preference store holds the credential-vault key,
  /// tracker refresh tokens and Seerr cookies in plaintext. Field-pattern
  /// redaction cannot be relied on here because the registered-value set is
  /// seeded inside the gate that just failed. Keep the parser's own message
  /// and offset, drop the excerpt.
  @visibleForTesting
  static String describeErrorSafely(Object error) {
    final cause = StartupPhaseException.unwrap(error);
    if (cause is! FormatException) return cause.toString();
    final offset = cause.offset;
    final message = cause.message.isEmpty ? 'FormatException' : cause.message;
    return offset == null ? message : '$message (at offset $offset)';
  }

  final StartupPhase? phase;
  final String errorType;

  /// Already redacted by the constructor.
  final String message;

  /// Already redacted by the constructor.
  final String? stackTrace;

  final DateTime timestamp;
  final String appVersion;
  final String platform;

  /// Whether the gate can offer an in-app repair for this failure.
  final bool repairable;

  String get phaseId => phase?.id ?? 'unknown';

  /// One-line summary for the failure screen and the log.
  String get headline => '[$phaseId] $errorType: $message';

  /// Full plain-text block for the clipboard and the diagnostics upload.
  String describe() {
    final buffer = StringBuffer()
      ..writeln('Plezy startup failure')
      ..writeln('Version: $appVersion')
      ..writeln('Platform: $platform')
      ..writeln('When: ${timestamp.toUtc().toIso8601String()}')
      ..writeln('Phase: $phaseId')
      ..writeln('Error: $errorType')
      ..writeln('Message: $message');
    final stack = stackTrace;
    if (stack != null && stack.isNotEmpty) {
      buffer
        ..writeln('Stack trace:')
        ..writeln(stack);
    }
    return buffer.toString().trimRight();
  }

  Map<String, Object?> toJson() => {
    'phase': phase?.id,
    'errorType': errorType,
    'message': message,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'platform': platform,
    'repairable': repairable,
  };

  static StartupFailureRecord? fromJson(Map<String, Object?> json) {
    final message = json['message'];
    final errorType = json['errorType'];
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (message is! String || errorType is! String || timestamp == null) return null;
    return StartupFailureRecord(
      phase: StartupPhase.fromId(json['phase'] as String?),
      errorType: errorType,
      message: message,
      stackTrace: json['stackTrace'] as String?,
      timestamp: timestamp,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      platform: json['platform'] as String? ?? 'unknown',
      repairable: json['repairable'] as bool? ?? false,
    );
  }
}

/// Persists the most recent startup-gate failure so it survives the process.
///
/// A failing launch has no other egress: the log buffer is in memory only, a
/// GUI-launched Windows release build has no console, and the in-app log
/// viewer sits behind the gate that just failed. Writing one small record next
/// to the database lets the next *successful* launch surface it in
/// Settings › Logs, where the user can upload it (#1732).
///
/// The record is an allowlist of already-redacted fields; raw store contents
/// never reach it.
abstract final class StartupDiagnosticsStore {
  static const String fileName = 'startup_failure.json';

  @visibleForTesting
  static Directory? debugDirectoryOverride;

  static StartupFailureRecord? _pending;

  /// Record observed during this launch, if any. Set both when a failure is
  /// recorded and when one written by an earlier launch is consumed.
  static StartupFailureRecord? get pending => _pending;

  static Future<File?> _file() async {
    try {
      final directory = debugDirectoryOverride ?? await getApplicationSupportDirectory();
      return File(p.join(directory.path, fileName));
    } catch (error, stackTrace) {
      appLogger.d('Startup diagnostics location unavailable', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// Best-effort write. A diagnostics failure must never worsen the failure it
  /// is describing, so every error here is logged and swallowed.
  static Future<void> record(StartupFailureRecord failure) async {
    _pending = failure;
    try {
      final file = await _file();
      if (file == null) return;
      if (!await file.parent.exists()) await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(failure.toJson()), flush: true);
    } catch (error, stackTrace) {
      appLogger.d('Could not persist the startup failure record', error: error, stackTrace: stackTrace);
    }
  }

  /// Reads and deletes a record written by an earlier launch.
  ///
  /// Deleting on read stops one stale failure from following the user forever;
  /// the value stays in [pending] for the rest of the session so the logs
  /// screen can still show it after the user navigates away and back.
  static Future<StartupFailureRecord?> consumePrevious() async {
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return null;
      final raw = await file.readAsString();
      await file.delete();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final record = StartupFailureRecord.fromJson(decoded.cast<String, Object?>());
      if (record != null) _pending = record;
      return record;
    } catch (error, stackTrace) {
      appLogger.d('Could not read a previous startup failure record', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// Drops a persisted record without surfacing it in [pending].
  static Future<void> clear() async {
    _pending = null;
    try {
      final file = await _file();
      if (file != null && await file.exists()) await file.delete();
    } catch (error, stackTrace) {
      appLogger.d('Could not clear the startup failure record', error: error, stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _pending = null;
    debugDirectoryOverride = null;
  }

  /// Seeds [pending] without touching disk, for widget tests. The widget-test
  /// binding runs in a fake-async zone where a `dart:io` future never
  /// completes, so [record] cannot be awaited from one.
  @visibleForTesting
  static void setPendingForTesting(StartupFailureRecord? failure) => _pending = failure;
}
