import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/android_self_update.dart';
import 'package:plezy/utils/snackbar_helper.dart';
import 'package:plezy/utils/update_dialog.dart';

final _updateInfo = <String, dynamic>{
  'hasUpdate': true,
  'currentVersion': '1.0.0',
  'latestVersion': '1.1.0',
  'releaseUrl': 'https://github.com/edde746/plezy/releases/tag/1.1.0',
  'assets': [
    {
      'name': 'plezy-android-armeabi-v7a.tar.gz',
      'browser_download_url':
          'https://github.com/edde746/plezy/releases/download/1.1.0/plezy-android-armeabi-v7a.tar.gz',
    },
  ],
};

void main() {
  final calls = <String>[];
  var canInstall = false;
  var abis = <String, Object?>{
    'running': 'armeabi-v7a',
    'supported': ['armeabi-v7a'],
  };

  setUp(() {
    calls.clear();
    canInstall = false;
    abis = {
      'running': 'armeabi-v7a',
      'supported': ['armeabi-v7a'],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      AndroidSelfUpdate.channel,
      (call) async {
        calls.add(call.method);
        return switch (call.method) {
          'getAbis' => abis,
          'canRequestInstall' => canInstall,
          'openInstallPermissionSettings' => true,
          _ => null,
        };
      },
    );
  });

  tearDown(() {
    AndroidSelfUpdate.debugSetSupported(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      AndroidSelfUpdate.channel,
      null,
    );
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return hostContext;
  }

  Future<void> open(WidgetTester tester) async {
    final context = await pumpHost(tester);
    unawaited(showUpdateAvailableDialog(context, _updateInfo, title: 'Update', dismissLabel: 'Later'));
    await tester.pumpAndSettle();
  }

  testWidgets('builds that cannot update themselves keep the release link', (tester) async {
    AndroidSelfUpdate.debugSetSupported(false);
    await open(tester);

    expect(find.text(t.update.viewRelease), findsOneWidget);
    expect(find.text(t.update.install), findsNothing);
  });

  testWidgets('a self-updating build offers to install the update', (tester) async {
    AndroidSelfUpdate.debugSetSupported(true);
    await open(tester);

    expect(find.text(t.update.install), findsOneWidget);
    expect(find.text(t.update.viewRelease), findsNothing);
  });

  testWidgets('asks for the install permission before downloading anything', (tester) async {
    AndroidSelfUpdate.debugSetSupported(true);
    await open(tester);

    await tester.tap(find.text(t.update.install));
    await tester.pumpAndSettle();

    expect(find.text(t.update.installPermissionTitle), findsOneWidget);
    expect(calls, ['getAbis', 'canRequestInstall']);

    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls, ['getAbis', 'canRequestInstall'], reason: 'nothing downloaded or installed');
  });

  testWidgets('opens the permission settings and resumes once the user is back', (tester) async {
    AndroidSelfUpdate.debugSetSupported(true);
    await open(tester);

    await tester.tap(find.text(t.update.install));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.update.openSettings));
    await tester.pumpAndSettle();
    expect(calls.last, 'openInstallPermissionSettings');

    // The user leaves the settings page without allowing it: nothing further happens.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(calls, ['getAbis', 'canRequestInstall', 'openInstallPermissionSettings', 'canRequestInstall']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a release without an APK for the device says so', (tester) async {
    AndroidSelfUpdate.debugSetSupported(true);
    abis = {
      'running': 'x86',
      'supported': ['x86'],
    };
    await open(tester);

    await tester.tap(find.text(t.update.install));
    await tester.pumpAndSettle();

    expect(find.text(t.update.noCompatibleApk), findsOneWidget);
    expect(calls, ['getAbis']);
  });
}
