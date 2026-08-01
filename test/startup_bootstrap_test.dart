import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show ApplyInterceptor, QueryExecutor, QueryExecutorUser, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/database/tvos_database_recovery_store.dart';
import 'package:plezy/main.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:plezy/services/startup_diagnostics.dart';
import 'package:plezy/widgets/startup_failure_view.dart';

import 'test_helpers/download_fixtures.dart';
import 'test_helpers/prefs.dart';

final class _OpenTrackingInterceptor extends QueryInterceptor {
  _OpenTrackingInterceptor({this.failure, this.updateFailure});

  final Object? failure;
  final Object? updateFailure;
  var ensureOpenCalls = 0;
  var ensureOpenCompleted = false;
  var closed = false;

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) async {
    ensureOpenCalls++;
    final failure = this.failure;
    if (failure != null) throw failure;

    final result = await executor.ensureOpen(user);
    ensureOpenCompleted = true;
    return result;
  }

  @override
  Future<int> runUpdate(QueryExecutor executor, String statement, List<Object?> args) {
    final updateFailure = this.updateFailure;
    if (updateFailure != null) throw updateFailure;
    return executor.runUpdate(statement, args);
  }

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    closed = true;
  }
}

void main() {
  testWidgets('renders a Flutter frame before starting the initialization gate', (tester) async {
    final completion = Completer<int>();
    var bootstrapWasMounted = false;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () {
          bootstrapWasMounted = find.byKey(startupBootstrapProgressKey).evaluate().isNotEmpty;
          return completion.future;
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );

    expect(bootstrapWasMounted, isTrue);
    expect(find.byKey(startupBootstrapProgressKey), findsOneWidget);

    completion.complete(1);
    await tester.pump();
  });

  testWidgets('replaces bootstrap UI with the initialized app on success', (tester) async {
    final completion = Completer<int>();

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () => completion.future,
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );

    completion.complete(7);
    await tester.pump();

    expect(find.text('ready 7'), findsOneWidget);
    expect(find.byKey(startupBootstrapProgressKey), findsNothing);
  });

  testWidgets('names the failing phase instead of showing a bare error', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw const StartupPhaseException(StartupPhase.database, FormatException('boom')),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();

    expect(find.byKey(startupBootstrapFailureKey), findsOneWidget);
    expect(find.byKey(startupBootstrapRetryKey), findsOneWidget);
    expect(find.byKey(startupFailureCopyKey), findsOneWidget);
    // The phase and concrete type are what turn "Error" into a report.
    expect(find.textContaining('database'), findsOneWidget);
    expect(find.textContaining('FormatException'), findsOneWidget);
  });

  testWidgets('expands the full detail block on request', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw StateError('database unavailable'),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();

    expect(find.byKey(startupFailureDetailsKey), findsNothing);
    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(find.byKey(startupFailureDetailsKey), findsOneWidget);
    expect(find.textContaining('database unavailable'), findsWidgets);
  });

  testWidgets('offers a repair only for a repairable failure', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw StateError('unrelated'),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();
    expect(find.byKey(startupFailureRepairKey), findsNothing);

    await tester.pumpWidget(
      StartupBootstrap<int>(
        key: const Key('repairable'),
        initialize: () async => throw CorruptPreferenceStoreException(const FormatException('bad'), StackTrace.current),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();
    expect(find.byKey(startupFailureRepairKey), findsOneWidget);
  });

  testWidgets('re-runs initialization after a successful repair', (tester) async {
    var attempts = 0;
    var repairCalls = 0;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async {
          attempts++;
          if (attempts == 1) {
            throw CorruptPreferenceStoreException(const FormatException('bad'), StackTrace.current);
          }
          return 7;
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
        repair: (_, _, _) async {
          repairCalls++;
          return StartupRepairResult.retry;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(startupFailureRepairKey));
    await tester.pump();
    await tester.pump();

    expect(repairCalls, 1);
    expect(attempts, 2);
    expect(find.text('ready 7'), findsOneWidget);
  });

  testWidgets('a repair that reports no change does not retry', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async {
          attempts++;
          throw CorruptPreferenceStoreException(const FormatException('bad'), StackTrace.current);
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
        repair: (_, _, _) async => StartupRepairResult.none,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(startupFailureRepairKey));
    await tester.pump();
    await tester.pump();

    expect(attempts, 1);
    expect(find.byKey(startupBootstrapFailureKey), findsOneWidget);
  });

  testWidgets('a repair that needs a restart parks the app instead of retrying', (tester) async {
    // The repair seeds the salvaged credentials straight to disk and leaves
    // this process's store closed, because the plugin still holds the bad
    // document. Re-running the gate would reopen onto that stale map and the
    // first write would flush it over the seed, destroying the vault key and
    // orphaning every ciphertext token in the database (#1732).
    var attempts = 0;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async {
          attempts++;
          throw CorruptPreferenceStoreException(const FormatException('bad'), StackTrace.current);
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
        repair: (_, _, _) async => StartupRepairResult.restart,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(startupFailureRepairKey));
    await tester.pump();
    await tester.pump();

    expect(attempts, 1);
    // Withdrawn, not disabled: both are the actions that would touch the store.
    expect(find.byKey(startupBootstrapRetryKey), findsNothing);
    expect(find.byKey(startupFailureRepairKey), findsNothing);
    // And the user is actually told what to do about it.
    expect(find.byKey(startupFailureRestartKey), findsOneWidget);
  });

  testWidgets('the restart state survives and still allows uploading the diagnostic', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw CorruptPreferenceStoreException(const FormatException('bad'), StackTrace.current),
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
        repair: (_, _, _) async => StartupRepairResult.restart,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(startupFailureRepairKey));
    await tester.pump();
    await tester.pump();

    // Copy and Upload stay live — the whole point of the failure screen is
    // that a stuck user can still get the diagnostic out.
    expect(find.byKey(startupFailureCopyKey), findsOneWidget);
    expect(find.byKey(startupFailureUploadKey), findsOneWidget);
  });

  testWidgets('persists the failure so it can be reported once the reporter is up', (tester) async {
    // Not reported inline: the earliest gate phases run before crash
    // reporting exists, so an inline capture would reach a no-op hub and be
    // discarded. The record is held for `flushPendingStartupFailure` (#1732).
    StartupDiagnosticsStore.resetForTesting();
    addTearDown(StartupDiagnosticsStore.resetForTesting);

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw const StartupPhaseException(StartupPhase.storage, 'nope'),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();

    expect(StartupDiagnosticsStore.pending?.phase, StartupPhase.storage);
    expect(StartupDiagnosticsStore.pending?.reported, isFalse);
  });

  testWidgets('retry clears the failed generation and can commit a later success', (tester) async {
    final retryCompletion = Completer<int>();
    var attempts = 0;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () {
          attempts++;
          if (attempts == 1) return Future<int>.error(StateError('first attempt'));
          return retryCompletion.future;
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(startupBootstrapRetryKey));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byKey(startupBootstrapProgressKey), findsOneWidget);

    retryCompletion.complete(42);
    await tester.pump();

    expect(find.text('ready 42'), findsOneWidget);
    expect(find.byKey(startupBootstrapFailureKey), findsNothing);
  });

  testWidgets('discards a completion from a disposed bootstrap generation', (tester) async {
    final completion = Completer<int>();
    final discarded = <int>[];

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () => completion.future,
        buildApp: (_, value) => Text('ready $value'),
        discard: discarded.add,
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete(9);
    await tester.pump();

    expect(discarded, [9]);
    expect(find.text('ready 9'), findsNothing);
  });

  test('storage-full lazy database open discards native work before retrying', () async {
    resetSharedPreferencesForTest();
    final tempDir = await Directory.systemTemp.createTemp('plezy_startup_storage_full_');
    final file = File('${tempDir.path}/plezy_downloads.db');
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final failedOpen = _OpenTrackingInterceptor(
      failure: const FileSystemException('write failed: No space left on device'),
    );
    final successfulOpen = _OpenTrackingInterceptor();
    AppDatabase? seeded;
    AppDatabase? resultDatabase;

    try {
      seeded = AppDatabase.forTesting(NativeDatabase(file));
      await seeded.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'active',
        globalKey: 'srv:active',
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await seeded.updateBgTaskId('srv:active', 'native-task');
      await seeded.addToQueue(mediaGlobalKey: 'srv:active');
      await seeded.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'complete',
        globalKey: 'srv:complete',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await seeded.close();
      seeded = null;

      var openAttempts = 0;
      var recoveries = 0;
      final bootstrap = await openAppDatabaseWithDownloadRecovery(
        openDatabase: () {
          return AppDatabase.open(
            isTvos: false,
            databaseFile: file,
            preferences: prefs,
            executorFactory: (databaseFile) {
              openAttempts++;
              final interceptor = openAttempts == 1 ? failedOpen : successfulOpen;
              return NativeDatabase(databaseFile).interceptWith(interceptor);
            },
          );
        },
        recoverNativeDownloads: () async {
          expect(failedOpen.closed, isTrue);
          recoveries++;
        },
        storageFullMessage: 'Storage full',
      );
      resultDatabase = bootstrap.database;

      final active = await resultDatabase.getDownloadedMedia('srv:active');
      final complete = await resultDatabase.getDownloadedMedia('srv:complete');
      expect(bootstrap.recoveryOutcome, TvosDatabaseRecoveryOutcome.notApplicable);
      expect(openAttempts, 2);
      expect(recoveries, 1);
      expect(failedOpen.ensureOpenCalls, 1);
      expect(successfulOpen.ensureOpenCalls, greaterThanOrEqualTo(1));
      expect(successfulOpen.ensureOpenCompleted, isTrue);
      expect(active?.status, DownloadStatus.failed.index);
      expect(active?.bgTaskId, isNull);
      expect(active?.errorMessage, 'Storage full');
      expect(complete?.status, DownloadStatus.completed.index);
      expect(await resultDatabase.select(resultDatabase.downloadQueue).get(), isEmpty);
      expect(await resultDatabase.customSelect('SELECT 1').get(), isNotEmpty);
    } finally {
      await resultDatabase?.close();
      await seeded?.close();
      await tempDir.delete(recursive: true);
    }
  });

  test('post-recovery download failure closes the reopened database before rethrowing', () async {
    resetSharedPreferencesForTest();
    final tempDir = await Directory.systemTemp.createTemp('plezy_startup_recovery_update_failure_');
    final file = File('${tempDir.path}/plezy_downloads.db');
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final failedOpen = _OpenTrackingInterceptor(
      failure: const FileSystemException('write failed: No space left on device'),
    );
    final updateError = StateError('injected post-recovery update failure');
    final reopened = _OpenTrackingInterceptor(updateFailure: updateError);
    AppDatabase? seeded;

    try {
      seeded = AppDatabase.forTesting(NativeDatabase(file));
      await seeded.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'active',
        globalKey: 'srv:active',
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await seeded.close();
      seeded = null;

      var openAttempts = 0;
      final open = openAppDatabaseWithDownloadRecovery(
        openDatabase: () {
          return AppDatabase.open(
            isTvos: false,
            databaseFile: file,
            preferences: prefs,
            executorFactory: (databaseFile) {
              openAttempts++;
              final interceptor = openAttempts == 1 ? failedOpen : reopened;
              return NativeDatabase(databaseFile).interceptWith(interceptor);
            },
          );
        },
        recoverNativeDownloads: () async {},
        storageFullMessage: 'Storage full',
      );

      await expectLater(open, throwsA(same(updateError)));
      expect(openAttempts, 2);
      expect(reopened.closed, isTrue);
    } finally {
      await seeded?.close();
      await tempDir.delete(recursive: true);
    }
  });

  test('non-storage lazy database-open errors bypass download recovery', () async {
    resetSharedPreferencesForTest();
    final tempDir = await Directory.systemTemp.createTemp('plezy_startup_open_error_');
    final file = File('${tempDir.path}/plezy_downloads.db');
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final error = StateError('injected database setup failure');
    final failedOpen = _OpenTrackingInterceptor(failure: error);
    var openAttempts = 0;
    var recoveries = 0;

    try {
      final open = openAppDatabaseWithDownloadRecovery(
        openDatabase: () {
          return AppDatabase.open(
            isTvos: false,
            databaseFile: file,
            preferences: prefs,
            executorFactory: (databaseFile) {
              openAttempts++;
              return NativeDatabase(databaseFile).interceptWith(failedOpen);
            },
          );
        },
        recoverNativeDownloads: () async {
          recoveries++;
        },
        storageFullMessage: 'Storage full',
      );

      await expectLater(open, throwsA(same(error)));
      expect(failedOpen.ensureOpenCalls, 1);
      expect(failedOpen.closed, isTrue);
      expect(openAttempts, 1);
      expect(recoveries, 0);
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
