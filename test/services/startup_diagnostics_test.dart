import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main.dart';
import 'package:plezy/services/sensitive_prefs.dart';
import 'package:plezy/services/startup_diagnostics.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

StartupFailureRecord _record({
  StartupPhase? phase = StartupPhase.database,
  Object error = const FormatException('boom'),
  StackTrace? stackTrace,
}) => StartupFailureRecord.fromError(
  phase: phase,
  error: error,
  stackTrace: stackTrace,
  appVersion: '2.11.0+124',
  platform: 'windows 11',
);

void main() {
  late Directory tempDir;

  setUp(() async {
    LogRedactionManager.clearTrackedValues();
    StartupDiagnosticsStore.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('plezy-startup-diagnostics');
    StartupDiagnosticsStore.debugDirectoryOverride = tempDir;
  });

  tearDown(() async {
    StartupDiagnosticsStore.resetForTesting();
    LogRedactionManager.clearTrackedValues();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('StartupPhaseException', () {
    test('unwraps to the real cause and reports the phase', () {
      const inner = FormatException('inner');
      const wrapped = StartupPhaseException(StartupPhase.storage, inner);

      expect(StartupPhaseException.unwrap(wrapped), same(inner));
      expect(StartupPhaseException.phaseOf(wrapped), StartupPhase.storage);
      expect(StartupPhaseException.unwrap(inner), same(inner));
    });

    test('a record built from a wrapper describes the cause, not the wrapper', () {
      final record = StartupFailureRecord.fromError(
        error: const StartupPhaseException(StartupPhase.database, FormatException('inner')),
        stackTrace: StackTrace.empty,
        appVersion: 'v',
        platform: 'p',
      );

      expect(record.phase, StartupPhase.database);
      expect(record.errorType, 'FormatException');
    });
  });

  group('describeErrorSafely', () {
    test('drops the source excerpt a FormatException carries', () {
      final key = base64Encode(List<int>.generate(32, (i) => i));
      final source = '{"$credentialVaultKeyPref":"$key","truncated';
      late final FormatException raw;
      try {
        jsonDecode(source);
        fail('expected a FormatException');
      } on FormatException catch (error) {
        raw = error;
      }
      expect(raw.toString(), contains(key), reason: 'precondition: the raw error does leak the key');

      final described = StartupFailureRecord.describeErrorSafely(raw);

      expect(described, isNot(contains(key)));
      expect(described, contains('offset'));
    });

    test('a record never persists the leaked excerpt', () async {
      final key = base64Encode(List<int>.generate(32, (i) => i));
      late final FormatException raw;
      try {
        jsonDecode('{"$credentialVaultKeyPref":"$key","truncated');
        fail('expected a FormatException');
      } on FormatException catch (error) {
        raw = error;
      }

      final record = _record(error: raw);
      await StartupDiagnosticsStore.record(record);

      final onDisk = await File('${tempDir.path}/${StartupDiagnosticsStore.fileName}').readAsString();
      expect(record.describe(), isNot(contains(key)));
      expect(onDisk, isNot(contains(key)));
    });

    test('leaves other error types alone', () {
      expect(StartupFailureRecord.describeErrorSafely(StateError('plain')), contains('plain'));
    });
  });

  group('record contents', () {
    test('redacts registered secrets out of the message', () {
      LogRedactionManager.registerToken('super-secret-token');

      final record = _record(error: StateError('failed with super-secret-token'));

      expect(record.message, isNot(contains('super-secret-token')));
    });

    test('describe() carries the phase, type and build for a bug report', () {
      final text = _record(error: StateError('nope')).describe();

      expect(text, contains('Phase: database'));
      expect(text, contains('Error: StateError'));
      expect(text, contains('2.11.0+124'));
      expect(text, contains('windows 11'));
    });

    test('headline stays one line', () {
      expect(_record().headline, startsWith('[database] FormatException'));
    });
  });

  group('persistence', () {
    test('round-trips a record through disk', () async {
      final original = _record(error: StateError('disk failure'), stackTrace: StackTrace.fromString('#0 frame'));
      await StartupDiagnosticsStore.record(original);
      StartupDiagnosticsStore.resetForTesting();
      StartupDiagnosticsStore.debugDirectoryOverride = tempDir;

      final restored = await StartupDiagnosticsStore.consumePrevious();

      expect(restored, isNotNull);
      expect(restored!.phase, StartupPhase.database);
      expect(restored.errorType, 'StateError');
      expect(restored.message, contains('disk failure'));
      expect(restored.stackTrace, contains('#0 frame'));
    });

    test('consuming deletes the file but keeps the record available in-session', () async {
      await StartupDiagnosticsStore.record(_record());
      StartupDiagnosticsStore.resetForTesting();
      StartupDiagnosticsStore.debugDirectoryOverride = tempDir;

      await StartupDiagnosticsStore.consumePrevious();

      // Deleted so one stale failure cannot follow the user forever, but held
      // in memory so Settings > Logs can still show and upload it.
      expect(await File('${tempDir.path}/${StartupDiagnosticsStore.fileName}').exists(), isFalse);
      expect(StartupDiagnosticsStore.pending, isNotNull);
    });

    test('consuming nothing yields null', () async {
      expect(await StartupDiagnosticsStore.consumePrevious(), isNull);
      expect(StartupDiagnosticsStore.pending, isNull);
    });

    test('a malformed record is ignored rather than thrown', () async {
      await File('${tempDir.path}/${StartupDiagnosticsStore.fileName}').writeAsString('not json');

      expect(await StartupDiagnosticsStore.consumePrevious(), isNull);
    });

    test('clear removes both the file and the pending record', () async {
      await StartupDiagnosticsStore.record(_record());

      await StartupDiagnosticsStore.clear();

      expect(await File('${tempDir.path}/${StartupDiagnosticsStore.fileName}').exists(), isFalse);
      expect(StartupDiagnosticsStore.pending, isNull);
    });

    test('an unwritable location degrades instead of failing the failure path', () async {
      StartupDiagnosticsStore.debugDirectoryOverride = Directory('${tempDir.path}/missing/deeper');

      await expectLater(StartupDiagnosticsStore.record(_record()), completes);
      // Still exposed in-session even when it could not be written.
      expect(StartupDiagnosticsStore.pending, isNotNull);
    });
  });

  group('phase ids', () {
    test('round-trip through their stable wire form', () {
      for (final phase in StartupPhase.values) {
        expect(StartupPhase.fromId(phase.id), phase, reason: phase.name);
      }
      expect(StartupPhase.fromId('nonexistent'), isNull);
      expect(StartupPhase.fromId(null), isNull);
    });
  });

  group('deferred crash reporting', () {
    // The preferences phase runs before crash reporting is initialised, so an
    // inline capture goes to a no-op hub and is silently discarded — the
    // likeliest failure phase producing no telemetry at all (#1732).

    test('flushes a persisted record once and marks it reported', () async {
      await StartupDiagnosticsStore.record(_record(phase: StartupPhase.preferences));

      final sent = <StartupFailureRecord>[];
      await flushPendingStartupFailure(send: (record) async => sent.add(record));

      expect(sent.single.phase, StartupPhase.preferences);
      expect((await StartupDiagnosticsStore.peekPersisted())!.reported, isTrue);

      // A later launch must not resend it.
      await flushPendingStartupFailure(send: (record) async => sent.add(record));
      expect(sent, hasLength(1));
    });

    test('leaves the record unreported when the send fails', () async {
      await StartupDiagnosticsStore.record(_record());

      await flushPendingStartupFailure(send: (_) async => throw StateError('offline'));

      // Still pending, so the next launch retries rather than losing it.
      expect((await StartupDiagnosticsStore.peekPersisted())!.reported, isFalse);
    });

    test('does nothing when no launch has failed', () async {
      final sent = <StartupFailureRecord>[];

      await flushPendingStartupFailure(send: (record) async => sent.add(record));

      expect(sent, isEmpty);
    });

    test('peeking leaves the record on disk for the display path', () async {
      await StartupDiagnosticsStore.record(_record());

      await StartupDiagnosticsStore.peekPersisted();

      expect(await StartupDiagnosticsStore.consumePrevious(), isNotNull);
    });
  });
}
