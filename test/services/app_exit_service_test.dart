import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/app_exit_service.dart';
import 'package:plezy/utils/platform_detector.dart';

// The standard test binding rejects required exits before they reach the binary
// messenger. Restore only that platform leg; lifecycle observer dispatch stays
// on the real WidgetsBinding implementation.
class _AppExitTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<ui.AppExitResponse> exitApplication(ui.AppExitType exitType, [int exitCode = 0]) async {
    final result = await SystemChannels.platform.invokeMethod<Map<String, Object?>>(
      'System.exitApplication',
      <String, Object?>{'type': exitType.name, 'exitCode': exitCode},
    );
    return result == null || result['response'] == 'cancel' ? ui.AppExitResponse.cancel : ui.AppExitResponse.exit;
  }
}

void main() {
  final binding = _AppExitTestBinding();

  setUp(() {
    PlatformDetector.debugSetIsDesktopOSOverride(true);
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
  });

  testWidgets('native termination waits for the exit listener to finish teardown', (tester) async {
    final teardown = Completer<void>();
    final events = <String>[];
    final listener = AppLifecycleListener(
      onExitRequested: () async {
        events.add('teardown started');
        await teardown.future;
        events.add('stopped reported');
        return ui.AppExitResponse.exit;
      },
    );
    addTearDown(listener.dispose);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'System.exitApplication') return null;
      // Model Windows: a cancelable request immediately returns cancel, not
      // the result of the app's asynchronously dispatched exit observers.
      if ((call.arguments as Map)['type'] == 'cancelable') return {'response': 'cancel'};
      events.add('native termination');
      return {'response': 'exit'};
    });

    final close = AppExitService.requestGracefulExit();
    await tester.pump();
    expect(events, ['teardown started']);
    await tester.pump(const Duration(seconds: 6));
    expect(events, ['teardown started']);

    teardown.complete();
    await tester.pump();
    expect(await close, isTrue);
    expect(events, ['teardown started', 'stopped reported', 'native termination']);
  });

  testWidgets('a canceled close never terminates and a later accepted close can proceed', (tester) async {
    var cancel = true;
    var terminations = 0;
    final listener = AppLifecycleListener(
      onExitRequested: () async => cancel ? ui.AppExitResponse.cancel : ui.AppExitResponse.exit,
    );
    addTearDown(listener.dispose);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'System.exitApplication') return null;
      terminations++;
      return {'response': 'exit'};
    });

    final canceledClose = AppExitService.requestGracefulExit();
    await tester.pump();
    expect(await canceledClose, isFalse);
    expect(terminations, 0);

    cancel = false;
    final acceptedClose = AppExitService.requestGracefulExit();
    await tester.pump();
    expect(await acceptedClose, isTrue);
    expect(terminations, 1);
  });

  testWidgets('concurrent closes share teardown and wait for native termination', (tester) async {
    final teardown = Completer<void>();
    final nativeExit = Completer<Map<String, String>>();
    var teardownCalls = 0;
    var terminations = 0;
    var completedCloses = 0;
    final listener = AppLifecycleListener(
      onExitRequested: () async {
        teardownCalls++;
        await teardown.future;
        return ui.AppExitResponse.exit;
      },
    );
    addTearDown(listener.dispose);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'System.exitApplication') return null;
      terminations++;
      return nativeExit.future;
    });
    Future<bool> close() => AppExitService.requestGracefulExit().then((accepted) {
      completedCloses++;
      return accepted;
    });

    final first = close();
    final second = close();
    await tester.pump();
    expect(teardownCalls, 1);
    expect(terminations, 0);
    expect(completedCloses, 0);

    teardown.complete();
    await tester.pump();
    final third = close();
    await tester.pump();
    expect(teardownCalls, 1);
    expect(terminations, 1);
    expect(completedCloses, 0);

    nativeExit.complete({'response': 'exit'});
    await tester.pump();
    expect(await Future.wait([first, second, third]), [true, true, true]);
    expect(terminations, 1);
  });

  testWidgets('native failure follows teardown and does not latch later close requests', (tester) async {
    final teardown = Completer<void>();
    final events = <String>[];
    var failNativeExit = true;
    final listener = AppLifecycleListener(
      onExitRequested: () async {
        await teardown.future;
        events.add('teardown finished');
        return ui.AppExitResponse.exit;
      },
    );
    addTearDown(listener.dispose);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'System.exitApplication') return null;
      events.add('native termination');
      if (failNativeExit) throw PlatformException(code: 'exit_failed');
      return {'response': 'exit'};
    });

    final failedClose = expectLater(AppExitService.requestGracefulExit(), throwsA(isA<PlatformException>()));
    await tester.pump();
    expect(events, isEmpty);
    teardown.complete();
    await tester.pump();
    await failedClose;
    expect(events, ['teardown finished', 'native termination']);

    failNativeExit = false;
    final retry = AppExitService.requestGracefulExit();
    await tester.pump();
    expect(await retry, isTrue);
    expect(events, ['teardown finished', 'native termination', 'teardown finished', 'native termination']);
  });

  testWidgets('native exit timeout starts after teardown and permits a later close', (tester) async {
    final teardown = Completer<void>();
    final stalledNativeExit = Completer<Map<String, String>>();
    var stallNativeExit = true;
    var terminations = 0;
    var closeFailed = false;
    final listener = AppLifecycleListener(
      onExitRequested: () async {
        await teardown.future;
        return ui.AppExitResponse.exit;
      },
    );
    addTearDown(listener.dispose);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'System.exitApplication') return null;
      terminations++;
      return stallNativeExit ? stalledNativeExit.future : {'response': 'exit'};
    });

    final failedClose = expectLater(AppExitService.requestGracefulExit(), throwsA(isA<TimeoutException>())).then((_) {
      closeFailed = true;
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(terminations, 0);
    expect(closeFailed, isFalse);

    teardown.complete();
    await tester.pump();
    expect(terminations, 1);
    await tester.pump(const Duration(milliseconds: 2999));
    expect(closeFailed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await failedClose;
    expect(closeFailed, isTrue);

    stallNativeExit = false;
    final retry = AppExitService.requestGracefulExit();
    await tester.pump();
    expect(await retry, isTrue);
    expect(terminations, 2);
    stalledNativeExit.complete({'response': 'exit'});
    await tester.pump();
  });
}
