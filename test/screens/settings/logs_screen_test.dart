import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/logs_screen.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/media_server_http_client.dart';

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
}
