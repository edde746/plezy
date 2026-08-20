import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/app_exit_service.dart';
import 'package:plezy/services/startup_diagnostics.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/startup_failure_view.dart';

StartupFailureRecord _record() => StartupFailureRecord(
  phase: StartupPhase.preferences,
  errorType: 'CorruptPreferenceStoreException',
  message: 'the preference store could not be parsed',
  stackTrace: null,
  timestamp: DateTime.utc(2026),
  appVersion: '2.11.1',
  platform: 'windows',
  repairable: true,
);

Future<void> _pumpView(
  WidgetTester tester, {
  required bool restartRequired,
  Future<bool> Function()? onExitRequested,
  bool repairable = true,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: StartupFailureView(
            failure: _record(),
            restartRequired: restartRequired,
            onRetry: () {},
            onRepair: repairable ? () async {} : null,
            requestExit: ({AppExitApplication? exitApplicationForTesting}) async =>
                onExitRequested == null ? false : await onExitRequested(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Whether [key] resolves to the filled (primary) Material button.
bool _isPrimary(WidgetTester tester, Key key) => tester.widget(find.byKey(key)) is FilledButton;

/// Whether [key]'s enclosing focusable currently holds focus.
bool _hasFocus(WidgetTester tester, Key key) =>
    tester.widget<Focus>(find.ancestor(of: find.byKey(key), matching: find.byType(Focus)).first).focusNode?.hasFocus ??
    false;

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  tearDown(() => PlatformDetector.debugSetIsDesktopOSOverride(null));
  testWidgets('the ordinary failure offers retry and repair', (tester) async {
    await _pumpView(tester, restartRequired: false);

    expect(find.byKey(startupBootstrapRetryKey), findsOneWidget);
    expect(find.byKey(startupFailureRepairKey), findsOneWidget);
    expect(find.byKey(startupFailureRestartKey), findsNothing);
  });

  testWidgets('repair leads the screen whenever it is offered', (tester) async {
    await _pumpView(tester, restartRequired: false);

    // Retry re-reads the same damaged document, so it can never clear this
    // failure. Presenting it as the primary, autofocused action is what left
    // the #1732 reporter pressing it and concluding the fix had not shipped.
    expect(_isPrimary(tester, startupFailureRepairKey), isTrue);
    expect(_isPrimary(tester, startupBootstrapRetryKey), isFalse);
    await tester.pump();
    expect(_hasFocus(tester, startupFailureRepairKey), isTrue);
    expect(find.text(t.startup.failedBodyRepairable), findsOneWidget);
  });

  testWidgets('retry leads when no repair can address the failure', (tester) async {
    await _pumpView(tester, restartRequired: false, repairable: false);

    // A locked database or a denied directory can genuinely change between
    // attempts, so Retry keeps both the primary styling and the focus there.
    expect(find.byKey(startupFailureRepairKey), findsNothing);
    expect(_isPrimary(tester, startupBootstrapRetryKey), isTrue);
    await tester.pump();
    expect(_hasFocus(tester, startupBootstrapRetryKey), isTrue);
    expect(find.text(t.startup.failedBody), findsOneWidget);
  });

  testWidgets('a pending restart withdraws every action that would touch the store', (tester) async {
    await _pumpView(tester, restartRequired: true);

    // Withdrawn rather than disabled: a greyed-out Retry still invites another
    // press, and pressing it would flush the plugin's stale map over the
    // freshly seeded credentials (#1732).
    expect(find.byKey(startupBootstrapRetryKey), findsNothing);
    expect(find.byKey(startupFailureRepairKey), findsNothing);
    // The diagnostic actions stay, because a stuck user still needs them out.
    expect(find.byKey(startupFailureCopyKey), findsOneWidget);
    expect(find.byKey(startupFailureUploadKey), findsOneWidget);
    expect(find.text(t.startup.restartRequiredBody), findsOneWidget);
  });

  testWidgets('the desktop quit button asks the platform to exit', (tester) async {
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    var exitRequests = 0;

    await _pumpView(
      tester,
      restartRequired: true,
      onExitRequested: () async {
        exitRequests++;
        return true;
      },
    );

    expect(find.byKey(startupFailureQuitKey), findsOneWidget);
    await tester.tap(find.byKey(startupFailureQuitKey));
    await tester.pump();

    expect(exitRequests, 1);
  });

  testWidgets('a platform that refuses to quit does not break the screen', (tester) async {
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    await _pumpView(tester, restartRequired: true, onExitRequested: () async => throw StateError('no'));

    await tester.tap(find.byKey(startupFailureQuitKey));
    await tester.pump();

    // The instruction is still on screen; the window controls remain the
    // user's fallback.
    expect(find.text(t.startup.restartRequiredBody), findsOneWidget);
  });

  testWidgets('a non-desktop host gets the instruction without a quit button', (tester) async {
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    await _pumpView(tester, restartRequired: true);

    expect(find.byKey(startupFailureQuitKey), findsNothing);
    expect(find.text(t.startup.restartRequiredBody), findsOneWidget);
  });
}
