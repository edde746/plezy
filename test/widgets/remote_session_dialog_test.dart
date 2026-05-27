import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/companion_remote/remote_session_dialog.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    SettingsService.resetForTesting();
  });

  testWidgets('opening dialog does not start a stopped server', (tester) async {
    final provider = _FakeCompanionRemoteProvider();
    addTearDown(provider.dispose);

    await _pumpDialogLauncher(tester, provider);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(RemoteSessionDialog), findsOneWidget);
    expect(provider.startCount, 0);
    expect(provider.isHostServerRunning, isFalse);
    expect(find.text(t.companionRemote.session.serverStopped), findsWidgets);
  });

  testWidgets('D-pad select activates Stop server', (tester) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.enableCompanionRemoteServer, true);
    final provider = _FakeCompanionRemoteProvider(isHostServerRunning: true);
    addTearDown(provider.dispose);

    await _pumpDialogLauncher(tester, provider);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(t.companionRemote.session.stopServer), findsOneWidget);

    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(provider.stopCount, 1);
    expect(provider.isHostServerRunning, isFalse);
    expect(settings.read(SettingsService.enableCompanionRemoteServer), isFalse);
    expect(find.text(t.companionRemote.session.startServer), findsOneWidget);
  });

  testWidgets('D-pad can move to Minimize and close dialog', (tester) async {
    final provider = _FakeCompanionRemoteProvider();
    addTearDown(provider.dispose);

    await _pumpDialogLauncher(tester, provider);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _pressDpadKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.byType(RemoteSessionDialog), findsNothing);
  });
}

class _FakeCompanionRemoteProvider extends CompanionRemoteProvider {
  _FakeCompanionRemoteProvider({bool isHostServerRunning = false}) : _isHostServerRunning = isHostServerRunning;

  bool _isHostServerRunning;
  int startCount = 0;
  int stopCount = 0;

  @override
  bool get isHostServerRunning => _isHostServerRunning;

  @override
  Future<void> startHostServer() async {
    startCount++;
    _isHostServerRunning = true;
    notifyListeners();
  }

  @override
  Future<void> stopHostServer() async {
    stopCount++;
    _isHostServerRunning = false;
    notifyListeners();
  }
}

Future<void> _pumpDialogLauncher(WidgetTester tester, CompanionRemoteProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<CompanionRemoteProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(onPressed: () => RemoteSessionDialog.show(context), child: const Text('Open')),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _pressDpadKey(WidgetTester tester, LogicalKeyboardKey logicalKey, PhysicalKeyboardKey physicalKey) async {
  _dispatchKey(
    KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration.zero,
      deviceType: ui.KeyEventDeviceType.directionalPad,
    ),
  );
  await tester.pump();
}

KeyEventResult _dispatchKey(KeyEvent event) {
  FocusNode? node = FocusManager.instance.primaryFocus;
  while (node != null) {
    final result = node.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    if (result == KeyEventResult.handled) return result;
    node = node.parent;
  }
  return KeyEventResult.ignored;
}
