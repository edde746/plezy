import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/smart_deletion_handler.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('completion before the first dialog frame removes the exact pending route', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    final manager = DownloadManagerService(
      database: database,
      storageService: DownloadStorageService.instance,
      clientResolver: (_, {clientScopeId}) => null,
    )..recoveryFuture = Future<void>.value();
    final provider = _GatedDeletionProvider(manager, database);
    await provider.ensureInitialized();
    addTearDown(() async {
      provider.dispose();
      manager.dispose();
      await database.close();
    });

    late BuildContext actionContext;
    await tester.pumpWidget(
      ChangeNotifierProvider<DownloadProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              actionContext = context;
              return const Scaffold(body: Text('underlying page'));
            },
          ),
        ),
      ),
    );

    final deletion = SmartDeletionHandler.deleteWithProgress(
      context: actionContext,
      provider: provider,
      globalKey: 'srv:item',
      delayMs: 0,
    );
    await tester.pump();
    provider.completeDeletion();
    await deletion;
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('underlying page'), findsOneWidget);
  });
}

class _GatedDeletionProvider extends DownloadProvider {
  _GatedDeletionProvider(DownloadManagerService manager, AppDatabase database)
    : super.forTesting(downloadManager: manager, database: database);

  final Completer<void> _deletion = Completer<void>();

  @override
  Future<void> deleteDownload(String globalKey) => _deletion.future;

  void completeDeletion() => _deletion.complete();
}
