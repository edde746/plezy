import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/background_work_diagnostics_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/background_download_warning_banner.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.plezy/device.background-warning-test');
  late Map<String, Object?> signals;
  late List<MethodCall> calls;

  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    signals = {'verdict': 'ok', 'reasons': <String>[]};
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getBackgroundWorkSignals' => signals,
        'openBackgroundSettings' => true,
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    SettingsService.resetForTesting();
  });

  testWidgets('requests notification permission before probing restrictions', (tester) async {
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    final context = await _pumpShell(tester);
    final events = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBackgroundWorkSignals') {
        events.add('probe');
        return signals;
      }
      return true;
    });

    final proceed = await confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async => events.add('permission'),
    );

    expect(proceed, isTrue);
    expect(events, ['permission', 'probe']);
  });

  testWidgets('download anyway acknowledges the warning and proceeds', (tester) async {
    signals = {
      'verdict': 'blocked',
      'reasons': ['notifications_disabled'],
    };
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    final context = await _pumpShell(tester);

    final result = confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async {},
    );
    await tester.pumpAndSettle();

    expect(find.text(t.downloads.backgroundWarning.dialogTitle), findsOneWidget);
    await tester.tap(find.text(t.downloads.backgroundWarning.dialogDownloadAnyway));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(SettingsService.instance.read(SettingsService.backgroundDownloadWarningAcknowledged), isTrue);
  });

  testWidgets('the focused fix action opens settings and cancels enqueue', (tester) async {
    signals = {
      'verdict': 'blocked',
      'reasons': ['background_restricted'],
    };
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    final context = await _pumpShell(tester);

    final result = confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async {},
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(
      calls.where((call) => call.method == 'openBackgroundSettings').single.arguments,
      BackgroundSettingsTarget.appDetails.id,
    );
  });

  testWidgets('notification denial opens app settings without requiring a channel', (tester) async {
    signals = {
      'verdict': 'blocked',
      'reasons': ['notifications_disabled'],
    };
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    final context = await _pumpShell(tester);

    final result = confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async {},
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.downloads.backgroundWarning.dialogFixFirst));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(
      calls.where((call) => call.method == 'openBackgroundSettings').single.arguments,
      BackgroundSettingsTarget.appNotifications.id,
    );
  });

  testWidgets('opening the OEM remedy clears stale empirical evidence', (tester) async {
    final detector = DownloadStallDetector(observationsToConfirm: 1, minimumBackgroundGap: Duration.zero);
    detector.onPaused(_activity(), DateTime(2026));
    detector.onResumed(_activity(), DateTime(2026, 1, 1, 1), networkAvailable: true);
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel, stallDetector: detector);
    addTearDown(service.dispose);
    await service.refresh();
    final context = await _pumpShell(tester);

    final result = showBackgroundDownloadWarningDialog(context, service: service);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.downloads.backgroundWarning.openSettings));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(detector.isStalled, isFalse);
    expect(service.status.reasons, isEmpty);
  });

  testWidgets('acknowledged warnings still request permission but skip the probe', (tester) async {
    await SettingsService.instance.write(SettingsService.backgroundDownloadWarningAcknowledged, true);
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    final context = await _pumpShell(tester);
    var permissionRequests = 0;

    final proceed = await confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async => permissionRequests++,
    );

    expect(proceed, isTrue);
    expect(permissionRequests, 1);
    expect(calls, isEmpty);
  });

  testWidgets('blocked status renders only while downloads are pending', (tester) async {
    signals = {
      'verdict': 'blocked',
      'reasons': ['background_restricted'],
    };
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    await service.refresh();

    await _pumpShell(tester, child: BackgroundDownloadWarningBanner(hasPendingDownloads: true, service: service));
    expect(find.text(t.downloads.backgroundWarning.bannerBlocked), findsOneWidget);

    await _pumpShell(tester, child: BackgroundDownloadWarningBanner(hasPendingDownloads: false, service: service));
    expect(find.text(t.downloads.backgroundWarning.bannerBlocked), findsNothing);
  });

  testWidgets('Data Saver uses degraded banner and dialog copy', (tester) async {
    signals = {
      'verdict': 'degraded',
      'reasons': ['data_saver'],
    };
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    await service.refresh();

    await _pumpShell(tester, child: BackgroundDownloadWarningBanner(hasPendingDownloads: true, service: service));
    expect(find.text(t.downloads.backgroundWarning.bannerDegraded), findsOneWidget);

    await tester.tap(find.text(t.downloads.backgroundWarning.bannerAction));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(t.downloads.backgroundWarning.sheetTitleDegraded),
      ),
      findsOneWidget,
    );
    expect(find.text(t.downloads.backgroundWarning.sheetTitle), findsNothing);
  });

  testWidgets('an unavailable help link gives user feedback', (tester) async {
    signals = {
      'verdict': 'blocked',
      'reasons': ['background_restricted'],
    };

    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    addTearDown(service.dispose);
    await service.refresh();
    final context = await _pumpShell(tester);

    final result = showBackgroundDownloadWarningDialog(
      context,
      service: service,
      externalUrlLauncher: (_) async => false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('dontkillmyapp.com'));
    await tester.pump();

    expect(find.text(t.downloads.backgroundWarning.linkUnavailable), findsOneWidget);

    await tester.tap(find.text(t.common.close));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('unsupported devices skip both warning surfaces', (tester) async {
    final service = BackgroundWorkDiagnosticsService.forTesting(channel: channel, supported: false);
    addTearDown(service.dispose);
    final context = await _pumpShell(
      tester,
      child: BackgroundDownloadWarningBanner(hasPendingDownloads: true, service: service),
    );
    var permissionRequests = 0;

    final proceed = await confirmBackgroundDownloadRestrictions(
      context,
      service: service,
      notificationPermissionRequester: () async => permissionRequests++,
    );

    expect(proceed, isTrue);
    expect(permissionRequests, 0);
    expect(calls, isEmpty);
    expect(find.byType(BackgroundDownloadWarningBanner), findsOneWidget);
    expect(find.text(t.downloads.backgroundWarning.bannerBlocked), findsNothing);
  });
}

DownloadActivitySnapshot _activity() => (
  activeTasks: 1,
  completedTasks: 0,
  failedTasks: 0,
  downloadedBytes: 1000,
  progressUnits: 0,
  networkAvailable: true,
  networkStateGeneration: 0,
);

Future<BuildContext> _pumpShell(WidgetTester tester, {Widget child = const SizedBox.shrink()}) async {
  late BuildContext context;
  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return Scaffold(body: child);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return context;
}
