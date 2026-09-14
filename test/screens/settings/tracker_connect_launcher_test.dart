import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/tracker_connect_launcher.dart';
import 'package:plezy/widgets/pending_auth_dialog.dart';

/// Knobs for one launched connect flow: the pending `connect` future the
/// launcher awaits, and a count of provider-level cancellations.
class _Harness {
  final Completer<bool> connect = Completer<bool>();
  int cancelCount = 0;
  Future<void>? launch;
}

/// Pumps a screen whose button starts [launchTrackerConnect] with the real
/// [PendingAuthDialog] shell, taps it, and completes the dialog's entrance.
///
/// The dialog shows an indeterminate spinner, so tests must use bounded pumps
/// while it is up — `pumpAndSettle` would never settle.
Future<_Harness> _pumpLauncher(WidgetTester tester) async {
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                harness.launch = launchTrackerConnect<String>(
                  context,
                  isBusyOrConnected: false,
                  serviceName: 'Example',
                  connect: (onCodeReady) {
                    onCodeReady('payload');
                    return harness.connect.future;
                  },
                  onCancel: () {
                    harness.cancelCount++;
                    // Like TrackersProvider.cancelConnect: cancellation unwinds
                    // the pending connect as an unsuccessful completion.
                    if (!harness.connect.isCompleted) harness.connect.complete(false);
                  },
                  buildDialog: (payload, cancel) => PendingAuthDialog(
                    title: 'Connect Example',
                    body: 'Authorize this device.',
                    url: 'https://example.com/activate',
                    openLabel: 'Open Example',
                    onCancel: cancel,
                    children: const [],
                  ),
                  urlFor: (payload) => 'https://example.com/activate',
                );
              },
              child: const Text('connect'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('connect'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(PendingAuthDialog), findsOneWidget);
  return harness;
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  String failureText() => t.services.connectFailed(service: 'Example');

  testWidgets('Cancel button cancels exactly once and shows no failure snackbar', (tester) async {
    final harness = await _pumpLauncher(tester);

    await tester.tap(find.text(t.common.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.cancelCount, 1, reason: 'PopScope and route completion must not each cancel');
    expect(find.byType(PendingAuthDialog), findsNothing);
    expect(find.text(failureText()), findsNothing);
    await harness.launch;
  });

  testWidgets('system back dismissal cancels exactly once and shows no failure snackbar', (tester) async {
    final harness = await _pumpLauncher(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.cancelCount, 1, reason: 'a back-dismissed dialog must abort the poll');
    expect(find.byType(PendingAuthDialog), findsNothing);
    expect(find.text(failureText()), findsNothing);
    await harness.launch;
  });

  testWidgets('successful connect closes the dialog without cancelling and without a snackbar', (tester) async {
    final harness = await _pumpLauncher(tester);

    harness.connect.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.cancelCount, 0, reason: 'the launcher popping its own dialog is not a cancellation');
    expect(find.byType(PendingAuthDialog), findsNothing);
    expect(find.text(failureText()), findsNothing);
    await harness.launch;
  });

  testWidgets('genuine connect failure closes the dialog and shows the failure snackbar', (tester) async {
    final harness = await _pumpLauncher(tester);

    harness.connect.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.cancelCount, 0);
    expect(find.byType(PendingAuthDialog), findsNothing);
    expect(find.text(failureText()), findsOneWidget);
    await harness.launch;

    // Run out the snackbar's display timer and exit animation.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });
}
