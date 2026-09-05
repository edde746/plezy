import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/logs_screen.dart';
import 'package:plezy/services/log_upload_service.dart';
import 'package:plezy/services/startup_diagnostics.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_bar_back_button.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() {
    MemoryLogOutput.clearLogs();
  });

  tearDown(() {
    MemoryLogOutput.clearLogs();
  });
  test('log upload payload preserves the header and newest complete lines', () {
    const header = 'Plezy test device\n---\n';
    const logs = 'oldest line that should be removed\nmiddle line that should be removed\nnewest 🚀 line';

    final payload = constrainLogUploadPayload(header: header, logs: logs, maxBytes: 52);

    expect(utf8.encode(payload).length, lessThanOrEqualTo(52));
    expect(payload, startsWith(header));
    expect(payload, endsWith('newest 🚀 line'));
    expect(payload, isNot(contains('oldest line')));
  });

  test('log upload payload remains unchanged below the server limit', () {
    const header = 'device\n---\n';
    const logs = 'one\ntwo';

    expect(constrainLogUploadPayload(header: header, logs: logs, maxBytes: 128), '$header$logs');
  });

  testWidgets('long upload capability displays and copies at narrow width', (tester) async {
    const capability = 'abcdefghijklmnopqrstuvwxy';
    String? uploadedBody;
    http.Request? uploadedRequest;
    String? clipboardText;

    PackageInfo.setMockInitialValues(
      appName: 'Plezy',
      packageName: 'com.plezy.test',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
    final deviceInfo = DeviceInfoPlugin.setMockInitialValues(
      linuxDeviceInfo: LinuxDeviceInfo(
        name: 'Test Linux',
        id: 'test-linux',
        prettyName: 'Test Linux',
        machineId: 'test-machine',
      ),
    );
    const deviceInfoChannel = MethodChannel('dev.fluttercommunity.plus/device_info');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(deviceInfoChannel, (call) async {
      expect(call.method, 'getDeviceInfo');
      return <String, dynamic>{
        'computerName': 'test-mac',
        'hostName': 'test-mac.local',
        'arch': 'arm64',
        'model': 'Mac15,3',
        'modelName': 'Mac',
        'kernelVersion': 'test',
        'osRelease': '15.0',
        'majorVersion': 15,
        'minorVersion': 0,
        'patchVersion': 0,
        'activeCPUs': 8,
        'memorySize': 16 * 1024 * 1024 * 1024,
        'cpuFrequency': 0,
        'systemGUID': 'test-guid',
      };
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(deviceInfoChannel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final client = MediaServerHttpClient(
      client: MockClient((request) async {
        uploadedRequest = request;
        uploadedBody = request.body;
        return http.Response(
          jsonEncode(<String, String>{'id': capability}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);
    appLogger.i('widget upload seed');

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: MaterialApp(
            home: LogsScreen(httpClient: client, deviceInfoPlugin: deviceInfo),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(t.logs.uploadLogs));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(capability, findRichText: true), findsOneWidget);
    expect(utf8.encode(uploadedBody!).length, lessThanOrEqualTo(maxLogUploadBytes));
    expect(uploadedRequest!.method, 'POST');
    expect(uploadedRequest!.url, Uri.parse('https://ice.plezy.app/logs'));
    final contentType = uploadedRequest!.headers.entries
        .singleWhere((entry) => entry.key.toLowerCase() == 'content-type')
        .value;
    expect(contentType, startsWith('text/plain'));
    expect(uploadedBody, contains('widget upload seed'));

    final dialog = find.byType(AlertDialog);
    final copyButton = find.descendant(of: dialog, matching: find.byType(IconButton));
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pump();
    expect(clipboardText, capability);

    clipboardText = null;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(clipboardText, capability);
    expect(tester.takeException(), isNull);
  });

  group('previous startup failure', () {
    late StartupFailureRecord record;

    Future<void> pumpLogs(WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Plezy',
        packageName: 'com.plezy.test',
        version: '2.11.0',
        buildNumber: '124',
        buildSignature: '',
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: InputModeTracker(child: MaterialApp(home: const LogsScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      StartupDiagnosticsStore.resetForTesting();
      record = StartupFailureRecord.fromError(
        phase: StartupPhase.database,
        error: StateError('sqlite could not open'),
        stackTrace: StackTrace.empty,
        appVersion: '2.11.0+124',
        platform: 'windows 11',
      );
    });

    tearDown(StartupDiagnosticsStore.resetForTesting);

    testWidgets('renders nothing when no launch has failed', (tester) async {
      await pumpLogs(tester);

      expect(find.byKey(previousStartupFailureKey), findsNothing);
    });

    testWidgets('shows the recorded failure so the user can see and act on it', (tester) async {
      // The failing process left no in-memory log at all; this banner is the
      // only surface that failure ever reaches (#1732).
      StartupDiagnosticsStore.setPendingForTesting(record);

      await pumpLogs(tester);

      expect(find.byKey(previousStartupFailureKey), findsOneWidget);
      expect(find.textContaining('sqlite could not open'), findsOneWidget);
      expect(find.textContaining('Phase: database'), findsOneWidget);
    });

    testWidgets('enables upload and copy with a record but an empty log buffer', (tester) async {
      MemoryLogOutput.clearLogs();
      StartupDiagnosticsStore.setPendingForTesting(record);

      await pumpLogs(tester);

      // Gating these on the log buffer alone would show the record and then
      // refuse to let the user do anything with it.
      final bar = tester.widget<FocusableActionBar>(find.byType(FocusableActionBar));
      for (final tooltip in [t.logs.uploadLogs, t.logs.copyLogs, t.logs.clearLogs]) {
        final action = bar.actions.singleWhere((candidate) => candidate.tooltip == tooltip);
        expect(action.onPressed, isNotNull, reason: tooltip);
      }
    });
  });

  group('log body rendering', () {
    late DeviceInfoPlugin deviceInfo;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'Plezy',
        packageName: 'com.plezy.test',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );
      deviceInfo = DeviceInfoPlugin.setMockInitialValues(
        linuxDeviceInfo: LinuxDeviceInfo(
          name: 'Test Linux',
          id: 'test-linux',
          prettyName: 'Test Linux',
          machineId: 'test-machine',
        ),
      );
      const deviceInfoChannel = MethodChannel('dev.fluttercommunity.plus/device_info');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(deviceInfoChannel, (call) async {
        return <String, dynamic>{
          'computerName': 'test-mac',
          'hostName': 'test-mac.local',
          'arch': 'arm64',
          'model': 'Mac15,3',
          'modelName': 'Mac',
          'kernelVersion': 'test',
          'osRelease': '15.0',
          'majorVersion': 15,
          'minorVersion': 0,
          'patchVersion': 0,
          'activeCPUs': 8,
          'memorySize': 16 * 1024 * 1024 * 1024,
          'cpuFrequency': 0,
          'systemGUID': 'test-guid',
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(deviceInfoChannel, null));
    });

    // Stores entries without echoing thousands of lines to the test console.
    void seedLogs(Iterable<String> messages) {
      final printer = MemoryAwareLogPrinter(SimplePrinter());
      for (final message in messages) {
        printer.log(LogEvent(Level.debug, message));
      }
    }

    Future<void> pumpLogs(WidgetTester tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: InputModeTracker(
            child: MaterialApp(home: LogsScreen(deviceInfoPlugin: deviceInfo)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lays out only the visible slice of a large buffer', (tester) async {
      // Rendering the whole buffer as one paragraph froze the frame for tens
      // of seconds and OOM-killed low-memory devices; offscreen entries must
      // never be materialized.
      seedLogs(['oldest-entry-marker', for (var i = 1; i < 1999; i++) 'entry-$i payload', 'newest-entry-marker']);

      await pumpLogs(tester);

      // Newest entry renders at the top; the oldest is offscreen and unbuilt.
      expect(find.textContaining('newest-entry-marker', findRichText: true), findsOneWidget);
      expect(find.textContaining('oldest-entry-marker', findRichText: true), findsNothing);

      // The tail is still reachable by scrolling.
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      for (var i = 0; i < 10 && position.pixels < position.maxScrollExtent; i++) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }
      expect(find.textContaining('oldest-entry-marker', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps the copied payload below the binder limit and keeps the newest lines', (tester) async {
      String? clipboardText;
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

      final filler = 'x' * 1024;
      seedLogs(['oldest-copy-marker', for (var i = 1; i < 599; i++) 'copy-entry-$i $filler', 'newest-copy-marker']);

      await pumpLogs(tester);
      await tester.tap(find.byTooltip(t.logs.copyLogs));
      await tester.pump();

      expect(clipboardText, isNotNull);
      expect(utf8.encode(clipboardText!).length, lessThanOrEqualTo(256 * 1024));
      expect(clipboardText, contains('newest-copy-marker'));
      expect(clipboardText, isNot(contains('oldest-copy-marker')));
      expect(tester.takeException(), isNull);
    });
  });

  group('app-bar D-pad traversal', () {
    // Android TV: `defaultTargetPlatform` is already Android under
    // `flutter test`, which is what selects the Android text-editing shortcuts.
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);
      PackageInfo.setMockInitialValues(
        appName: 'Plezy',
        packageName: 'com.plezy.test',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );
    });

    tearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      TvDetectionService.setForceTVSync(false);
    });

    testWidgets('ArrowRight from the app-bar back button reaches the action bar on TV', (tester) async {
      // The back button only exists on a pushed route, which is how the
      // screen is always reached from Settings.
      await tester.pumpWidget(
        TranslationProvider(
          child: InputModeTracker(
            child: MaterialApp(
              initialRoute: '/logs',
              routes: {'/': (_) => const Scaffold(), '/logs': (_) => const LogsScreen()},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final backButton = find.byType(AppBarBackButton);
      expect(backButton, findsOneWidget);
      final backNode = Focus.of(tester.element(find.descendant(of: backButton, matching: find.byType(Tooltip))));
      backNode.requestFocus();
      await tester.pumpAndSettle();
      expect(backNode.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      final focused = FocusManager.instance.primaryFocus;
      expect(
        focused?.context?.findAncestorWidgetOfExactType<FocusableActionBar>(),
        isNotNull,
        reason: 'focus stayed on ${focused?.debugLabel}; Right should move it into the action bar',
      );
    });

    testWidgets('Shift+ArrowRight from the app-bar back button is still consumed by the selection region', (
      tester,
    ) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: InputModeTracker(
            child: MaterialApp(
              initialRoute: '/logs',
              routes: {'/': (_) => const Scaffold(), '/logs': (_) => const LogsScreen()},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final backButton = find.byType(AppBarBackButton);
      final backNode = Focus.of(tester.element(find.descendant(of: backButton, matching: find.byType(Tooltip))));
      backNode.requestFocus();
      await tester.pumpAndSettle();
      expect(backNode.hasPrimaryFocus, isTrue);

      // Nothing else on this screen handles Right, so "handled" can only come
      // from the SelectionArea's extend-selection action: the override must
      // defer to it rather than swallow every arrow.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final handled = await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(handled, isTrue, reason: 'Shift+Right is a selection gesture and must reach the SelectionArea');
      expect(backNode.hasPrimaryFocus, isTrue);
    });
  });
}
