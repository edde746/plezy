import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
String _newRecordId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-'
    '${Random().nextInt(0xFFFFFF).toRadixString(16)}';

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
    this.reported = false,
    String? id,
  }) : id = id ?? _newRecordId(),
       message = LogRedactionManager.redact(message),
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

  /// Distinguishes this record from any other, including one written moments
  /// later by a retry that also failed.
  ///
  /// A slow flush can still be sending record A when a retry writes record B;
  /// without an identity, marking A reported would overwrite B on disk and
  /// lose the newer failure entirely.
  final String id;

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

  /// Whether this record has already reached the crash reporter.
  ///
  /// The earliest gate phases run before crash reporting is initialised, so a
  /// failure there is captured by a no-op hub and silently discarded. Records
  /// are therefore always persisted first and sent once the reporter is up —
  /// on the in-app retry, or on the next launch (#1732).
  final bool reported;

  StartupFailureRecord copyWith({bool? reported}) => StartupFailureRecord(
    id: id,
    phase: phase,
    errorType: errorType,
    message: message,
    stackTrace: stackTrace,
    timestamp: timestamp,
    appVersion: appVersion,
    platform: platform,
    repairable: repairable,
    reported: reported ?? this.reported,
  );

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
    'id': id,
    'phase': phase?.id,
    'errorType': errorType,
    'message': message,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'platform': platform,
    'repairable': repairable,
    'reported': reported,
  };

  static StartupFailureRecord? fromJson(Map<String, Object?> json) {
    final message = json['message'];
    final errorType = json['errorType'];
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (message is! String || errorType is! String || timestamp == null) return null;
    return StartupFailureRecord(
      // Records written before ids existed fall back to their timestamp, which
      // is stable for a given file even if it is not globally unique.
      id: json['id'] as String? ?? 'legacy-${timestamp.microsecondsSinceEpoch}',
      phase: StartupPhase.fromId(json['phase'] as String?),
      errorType: errorType,
      message: message,
      stackTrace: json['stackTrace'] as String?,
      timestamp: timestamp,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      platform: json['platform'] as String? ?? 'unknown',
      repairable: json['repairable'] as bool? ?? false,
      reported: json['reported'] as bool? ?? false,
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

  /// A crash-report flush that must finish before the record may be consumed.
  static Future<void>? _flushInFlight;

  /// The persist started by [record]. Callers launch it unawaited from the
  /// failure path, so every later reader has to settle it first or it can land
  /// after a peek (losing the report) or after a consume (stranding a stale
  /// unreported file).
  static Future<void>? _writeInFlight;

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
  static Future<void> record(StartupFailureRecord failure) {
    // Published synchronously: the failure screen and the logs banner read it
    // straight away, and the disk write below may never land at all.
    _pending = failure;
    return _enqueueWrite(() => _write(failure));
  }

  /// Serializes every mutation of the record file.
  ///
  /// Writes are launched unawaited from the failure path, and a retry that
  /// also fails writes while the first one may still be running. Two
  /// concurrent writers to one file can land out of order, and a
  /// read-modify-write like [markReported] can interleave with a write and
  /// resurrect the record it just superseded. Chaining makes disk order match
  /// call order and makes the compare-and-set atomic against writes (#1732).
  static Future<void> _enqueueWrite(Future<void> Function() operation) {
    final previous = _writeInFlight;
    final task = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // Best effort: an earlier failed write must not block this one.
        }
      }
      await operation();
    }();
    _writeInFlight = task;
    return task.whenComplete(() {
      if (identical(_writeInFlight, task)) _writeInFlight = null;
    });
  }

  static Future<void> _write(StartupFailureRecord failure) async {
    try {
      final file = await _file();
      if (file == null) return;
      if (!await file.parent.exists()) await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(failure.toJson()), flush: true);
    } catch (error, stackTrace) {
      appLogger.d('Could not persist the startup failure record', error: error, stackTrace: stackTrace);
    }
  }

  /// Waits for an in-flight [record] so readers never race the write.
  static Future<void> _settleWrite() async {
    final write = _writeInFlight;
    if (write == null) return;
    try {
      await write;
    } catch (error, stackTrace) {
      appLogger.d('Startup failure record write failed', error: error, stackTrace: stackTrace);
    }
  }

  /// Registers a crash-report flush so [consumePrevious] cannot delete the
  /// record out from under it.
  ///
  /// The flush is deliberately off the startup critical path, and the success
  /// path consumes the record as soon as the gate completes. Without this gate
  /// a fast launch could delete the file before the flush had read it, losing
  /// the report entirely — the exact failure this whole path exists to
  /// prevent (#1732).
  static void holdForFlush(Future<void> flush) {
    _flushInFlight = flush;
  }

  /// Reads a persisted record without consuming it.
  ///
  /// Used by the crash-report flush, which has to run before the record is
  /// consumed for display and must not remove it if the send fails.
  static Future<StartupFailureRecord?> peekPersisted() async {
    await _settleWrite();
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return StartupFailureRecord.fromJson(decoded.cast<String, Object?>());
    } catch (error, stackTrace) {
      appLogger.d('Could not peek at the startup failure record', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// Rewrites the persisted record as already reported, so a later launch does
  /// not send it a second time. It stays on disk for Settings > Logs.
  static Future<void> markReported(StartupFailureRecord failure) {
    // Queued with the writes: reading and rewriting outside the queue lets a
    // concurrent `record` land between the two and be overwritten, losing the
    // newer failure.
    return _enqueueWrite(() async {
      try {
        final file = await _file();
        if (file == null || !await file.exists()) return;
        // Compare and set: a retry may have failed too and replaced this
        // record while the send was in flight.
        final current = await _decodeFile(file);
        await debugAfterReportedRead?.call();
        if (current == null || current.id != failure.id) {
          appLogger.d('Startup failure record was superseded before it could be marked reported');
          return;
        }
        final updated = failure.copyWith(reported: true);
        if (_pending?.id == failure.id) _pending = updated;
        await file.writeAsString(jsonEncode(updated.toJson()), flush: true);
      } catch (error, stackTrace) {
        appLogger.d('Could not mark the startup failure record as reported', error: error, stackTrace: stackTrace);
      }
    });
  }

  /// Test seam: pauses [markReported] between its read and its write so the
  /// compare-and-set can be exercised against a concurrent record.
  @visibleForTesting
  static Future<void> Function()? debugAfterReportedRead;

  static Future<StartupFailureRecord?> _decodeFile(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;
    return StartupFailureRecord.fromJson(decoded.cast<String, Object?>());
  }

  /// Loads a record written by an earlier launch, deleting it only once it has
  /// been reported.
  ///
  /// An unreported record is the crash reporter's only retry: the reporter can
  /// be uninitialised, offline, or backed by a no-op hub that accepts events
  /// and drops them. Deleting it here would silently end the retry, which is
  /// the failure this whole path exists to prevent (#1732). A record that can
  /// never be sent — no crash reporting compiled in, or the user opted out —
  /// is marked reported by the flush, so nothing lingers indefinitely.
  ///
  /// Either way the value lands in [pending] so the logs screen can show it
  /// for the rest of the session.
  static Future<StartupFailureRecord?> consumePrevious() async {
    await _settleWrite();
    final flush = _flushInFlight;
    if (flush != null) {
      _flushInFlight = null;
      // A failed flush must not block the display path.
      try {
        await flush;
      } catch (error, stackTrace) {
        appLogger.d('Startup failure flush failed before consumption', error: error, stackTrace: stackTrace);
      }
    }
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return null;
      final record = await _decodeFile(file);
      if (record == null) {
        // Unreadable: nothing can be retried or shown, so drop it.
        await file.delete();
        return null;
      }
      if (record.reported) await file.delete();
      _pending = record;
      return record;
    } catch (error, stackTrace) {
      appLogger.d('Could not read a previous startup failure record', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// Drops a persisted record without surfacing it in [pending].
  static Future<void> clear() async {
    await _settleWrite();
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
    _flushInFlight = null;
    _writeInFlight = null;
    debugAfterReportedRead = null;
    debugDirectoryOverride = null;
  }

  /// Seeds [pending] without touching disk, for widget tests. The widget-test
  /// binding runs in a fake-async zone where a `dart:io` future never
  /// completes, so [record] cannot be awaited from one.
  @visibleForTesting
  static void setPendingForTesting(StartupFailureRecord? failure) => _pending = failure;
}
