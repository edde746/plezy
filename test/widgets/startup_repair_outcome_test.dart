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
    await _openDialog(tester, PrefsRepairOutcome(backupPath: backup.path, vaultKeySalvaged: true, sessionsLost: 0));

    expect(find.text(t.startup.backupTitle), findsOneWidget);
    expect(find.text(t.startup.backupWarning), findsOneWidget);
    expect(find.text(backup.path), findsOneWidget);
  });

  testWidgets('a backup with nothing in it still offers deletion but claims no secrets', (tester) async {
    // The #1732 store was 10336 zero bytes. Telling the user that copy holds
    // their sign-ins is false, and a warning that cries wolf is the one they
    // will ignore on the launch where the file really is sensitive.
    await _openDialog(
      tester,
      PrefsRepairOutcome(
        backupPath: backup.path,
        backupHoldsCredentials: false,
        vaultKeySalvaged: false,
        sessionsLost: 0,
      ),
    );

    expect(find.text(t.startup.backupTitle), findsOneWidget);
    expect(find.text(backup.path), findsOneWidget);
    expect(find.text(t.startup.backupWarning), findsNothing);
    expect(find.text(t.startup.deleteBackup), findsOneWidget);
  });

  group('consent copy', () {
    test('a store with no recoverable vault key promises nothing it cannot keep', () {
      final message = repairConsentMessage(oneCredential: false, signInsSurvive: false);

      // The #1732 store salvaged nothing. Saying "servers and profiles
      // normally stay signed in" here would be contradicted by the outcome
      // dialog moments later.
      expect(message, contains(t.startup.repairBodyCommon));
      expect(message, contains(t.startup.repairBodySignInsLost));
      expect(message, isNot(contains(t.startup.repairBodySignInsKept)));
    });

    test('a salvageable store keeps the cheaper promise', () {
      final message = repairConsentMessage(oneCredential: false, signInsSurvive: true);

      expect(message, contains(t.startup.repairBodySignInsKept));
      expect(message, isNot(contains(t.startup.repairBodySignInsLost)));
    });

    test('the single-credential repair names its own narrower scope', () {
      final message = repairConsentMessage(oneCredential: true, signInsSurvive: true);

      expect(message, contains(t.startup.repairBodyOneCredential));
      expect(message, isNot(contains(t.startup.repairBodyCommon)));
    });

    test('trackers and Seerr get the same cautious sentence either way', () {
      // Their sessions are plaintext preference entries, salvaged one by one
      // and left untouched by the single-credential repair, so they neither
      // survive nor die with the vault key. Neither branch may borrow that
      // value's verdict for them.
      for (final signInsSurvive in [true, false]) {
        expect(
          repairConsentMessage(oneCredential: false, signInsSurvive: signInsSurvive),
          contains(t.startup.repairBodySessionsUncertain),
        );
      }
      expect(
        repairConsentMessage(oneCredential: true, signInsSurvive: false),
        contains(t.startup.repairBodySessionsUncertain),
      );
    });
  });

  testWidgets('deleting the backup removes the file and stops showing its path', (tester) async {
    final deleted = <String>[];
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: backup.path, vaultKeySalvaged: true, sessionsLost: 0),
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
    await _openDialog(tester, PrefsRepairOutcome(backupPath: null, vaultKeySalvaged: true, sessionsLost: 0));

    expect(find.text(t.startup.repairKeptSignIns), findsOneWidget);
    expect(find.text(t.startup.repairLostSignIns), findsNothing);
  });

  testWidgets('states the full credential loss when the vault key is gone', (tester) async {
    await _openDialog(tester, PrefsRepairOutcome(backupPath: null, vaultKeySalvaged: false, sessionsLost: 3));

    expect(find.text(t.startup.repairLostSignIns), findsOneWidget);
    // Tracker/Seerr sessions are plaintext preference entries, so they are
    // reported separately from the vault-protected server tokens.
    expect(find.text(t.startup.repairLostSessions), findsOneWidget);
  });

  testWidgets('asks for a restart when the store could not be reopened', (tester) async {
    await _openDialog(
      tester,
      PrefsRepairOutcome(backupPath: null, vaultKeySalvaged: true, sessionsLost: 0, requiresRestart: true),
    );

    expect(find.text(t.startup.repairNeedsRestart), findsOneWidget);
    expect(find.text(t.startup.repairSucceeded), findsNothing);
  });
}
