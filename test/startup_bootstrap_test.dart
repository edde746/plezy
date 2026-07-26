import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/database/tvos_database_recovery_store.dart';
import 'package:plezy/main.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/download_models.dart';

import 'test_helpers/download_fixtures.dart';

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

  testWidgets('shows a localized recoverable failure instead of removing Flutter UI', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw StateError('database unavailable'),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();

    expect(find.byKey(startupBootstrapFailureKey), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
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

  test('storage-full database open discards native work before retrying', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertDownload(
      serverId: ServerId('srv'),
      ratingKey: 'active',
      globalKey: 'srv:active',
      type: 'movie',
      status: DownloadStatus.downloading.index,
    );
    await database.updateBgTaskId('srv:active', 'native-task');
    await database.addToQueue(mediaGlobalKey: 'srv:active');
    await database.insertDownload(
      serverId: ServerId('srv'),
      ratingKey: 'complete',
      globalKey: 'srv:complete',
      type: 'movie',
      status: DownloadStatus.completed.index,
    );

    var openAttempts = 0;
    var recoveries = 0;
    final bootstrap = AppDatabaseBootstrap(
      database: database,
      recoveryOutcome: TvosDatabaseRecoveryOutcome.notApplicable,
    );

    final result = await openAppDatabaseWithDownloadRecovery(
      openDatabase: () async {
        openAttempts++;
        if (openAttempts == 1) {
          throw const FileSystemException('write failed: No space left on device');
        }
        return bootstrap;
      },
      recoverNativeDownloads: () async {
        recoveries++;
      },
      storageFullMessage: 'Storage full',
    );

    final active = await database.getDownloadedMedia('srv:active');
    final complete = await database.getDownloadedMedia('srv:complete');
    expect(result, same(bootstrap));
    expect(openAttempts, 2);
    expect(recoveries, 1);
    expect(active?.status, DownloadStatus.failed.index);
    expect(active?.bgTaskId, isNull);
    expect(active?.errorMessage, 'Storage full');
    expect(complete?.status, DownloadStatus.completed.index);
    expect(await database.select(database.downloadQueue).get(), isEmpty);
  });
}
