import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/atmos_diagnostics_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plezy/atmos_probe');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const AtmosDiagnosticsScreen()));
    await tester.pump();
    await tester.ensureVisible(find.text(t.settings.atmosTestStop));
  }

  testWidgets('unmounting during stop does not set state or stop twice', (tester) async {
    final stopCompleter = Completer<void>();
    var stopCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stop') {
        stopCalls++;
        await stopCompleter.future;
      }
      return call.method == 'getStatus' ? <Object?, Object?>{} : null;
    });

    await pumpScreen(tester);
    await tester.tap(find.text(t.settings.atmosTestStop));
    await tester.pump();
    expect(stopCalls, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(stopCalls, 1);

    stopCompleter.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(stopCalls, 1);
  });

  testWidgets('native stop failure is shown without escaping', (tester) async {
    var stopCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stop') {
        stopCalls++;
        throw PlatformException(code: 'stop_failed', message: 'Native stop failed');
      }
      return call.method == 'getStatus' ? <Object?, Object?>{} : null;
    });

    await pumpScreen(tester);
    await tester.tap(find.text(t.settings.atmosTestStop));
    await tester.pump();

    expect(stopCalls, 1);
    expect(find.text('Native stop failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
