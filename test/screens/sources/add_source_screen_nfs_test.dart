import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/screens/sources/add_source_screen.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../sources/fixtures/memory_sources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SourceDatabase database;
  late MemorySources sources;
  late TrackersProvider trackers;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plezy-nfs-setup-test-');
    database = SourceDatabase(NativeDatabase.memory());
    sources = MemorySources(SourceRepository(database), directory);
    trackers = TrackersProvider();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    sources.dispose();
    trackers.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  testWidgets('NFS setup exposes mount and RPC TLS controls without account fields', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const nfs = FileSource(
      id: 'nas',
      profileId: 'alice',
      kind: FileSourceKind.nfs,
      name: 'NAS',
      endpoint: 'nfs://nas.example/export',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
        ],
        child: MaterialApp(
          theme: monoTheme(MonoPalette.dark),
          home: const AddSourceScreen(existing: nfs),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.sourceSetup.nfsMountPort), findsOneWidget);
    expect(find.text(t.sourceSetup.nfsUserId), findsOneWidget);
    expect(find.text(t.sourceSetup.nfsGroupId), findsOneWidget);
    expect(find.text(t.sourceSetup.nfsEncryption), findsOneWidget);
    expect(find.text(t.fileSources.username), findsNothing);
    expect(find.text(t.fileSources.password), findsNothing);

    await tester.ensureVisible(find.text(t.sourceSetup.nfsEncryption));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.sourceSetup.nfsEncryption));
    await tester.pumpAndSettle();
    expect(find.text(t.sourceSetup.nfsTrustCertificate), findsOneWidget);
    expect(find.text(t.sourceSetup.clientCertificate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
