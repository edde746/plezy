import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/main.dart';
import 'package:plezy/services/prefs_recovery.dart';

Future<void> _openDialog(
  WidgetTester tester,
  PrefsRepairOutcome outcome, {
  Future<void> Function(String path)? deleteBackup,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showRepairOutcomeDialog(context, outcome, deleteBackup: deleteBackup ?? PrefsRecovery.deleteBackup),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  late Directory tempDir;
  late File backup;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('plezy-repair-outcome');
    backup = File('${tempDir.path}/shared_preferences.corrupt-x.json');
    await backup.writeAsString('{"credential_vault_key_v1":"secret"}');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('warns that the backup holds credentials and must not be shared', (tester) async {
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: backup.path, vaultKeySalvaged: true, sessionsSalvaged: 0, sessionsLost: 0),
    );

    expect(find.text(t.startup.backupTitle), findsOneWidget);
    expect(find.text(t.startup.backupWarning), findsOneWidget);
    expect(find.text(backup.path), findsOneWidget);
  });

  testWidgets('deleting the backup removes the file and stops showing its path', (tester) async {
    final deleted = <String>[];
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: backup.path, vaultKeySalvaged: true, sessionsSalvaged: 0, sessionsLost: 0),
      // The widget-test binding's fake-async zone never completes a `dart:io`
      // future, so the real delete is covered in prefs_recovery_test.dart and
      // this test owns the UI state that follows it.
      deleteBackup: (path) async => deleted.add(path),
    );

    await tester.tap(find.text(t.startup.deleteBackup));
    await tester.pumpAndSettle();

    expect(deleted, [backup.path]);
    // Regression: the flag lived inside the StatefulBuilder closure, so the
    // rebuild it triggered reset it and the sensitive path stayed on screen.
    expect(find.text(t.startup.backupDeleted), findsOneWidget);
    expect(find.text(backup.path), findsNothing);
    expect(find.text(t.startup.deleteBackup), findsNothing);
  });

  testWidgets('says sign-ins are kept only when the vault key survived', (tester) async {
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: null, vaultKeySalvaged: true, sessionsSalvaged: 2, sessionsLost: 0),
    );

    expect(find.text(t.startup.repairKeptSignIns), findsOneWidget);
    expect(find.text(t.startup.repairLostSignIns), findsNothing);
  });

  testWidgets('states the full credential loss when the vault key is gone', (tester) async {
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: null, vaultKeySalvaged: false, sessionsSalvaged: 0, sessionsLost: 3),
    );

    expect(find.text(t.startup.repairLostSignIns), findsOneWidget);
    // Tracker/Seerr sessions are plaintext preference entries, so they are
    // reported separately from the vault-protected server tokens.
    expect(find.text(t.startup.repairLostSessions), findsOneWidget);
  });

  testWidgets('asks for a restart when the store could not be reopened', (tester) async {
    await _openDialog(
      tester,
      PrefsRepairOutcome(
        backupPath: null,
        vaultKeySalvaged: true,
        sessionsSalvaged: 1,
        sessionsLost: 0,
        requiresRestart: true,
      ),
    );

    expect(find.text(t.startup.repairNeedsRestart), findsOneWidget);
    expect(find.text(t.startup.repairSucceeded), findsNothing);
  });
}
