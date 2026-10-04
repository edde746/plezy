import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/display_mode_service.dart';
import 'package:plezy/services/fullscreen_state_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/app_logger.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test_display_mode_service');
  late DisplayModeService service;
  late List<String> calls;

  void setHandler(Future<dynamic> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  Future<void> seedNativeState({required bool mode, required bool hdr}) async {
    setHandler((call) async {
      calls.add(call.method);
      return switch (call.method) {
        'isModeChanged' => mode,
        'isHDRChanged' => hdr,
        _ => throw StateError('Unexpected method ${call.method}'),
      };
    });
    await service.syncWithNative();
    calls.clear();
  }

  setUp(() async {
    calls = <String>[];
    MemoryLogOutput.clearLogs();
    setLoggerLevel(true);
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    service = DisplayModeService.forTesting(settings, FullscreenStateManager(), channel: channel);
  });

  tearDown(() {
    setHandler(null);
    MemoryLogOutput.clearLogs();
  });

  test('false display-mode payload retains state for a later retry', () async {
    await seedNativeState(mode: true, hdr: false);
    var accepted = false;
    setHandler((call) async {
      calls.add(call.method);
      expect(call.method, 'restoreDisplayMode');
      return accepted;
    });

    await service.restoreAll();
    expect(service.anyChangeApplied, isTrue);

    accepted = true;
    await service.restoreAll();
    expect(calls, ['restoreDisplayMode', 'restoreDisplayMode']);
    expect(service.anyChangeApplied, isFalse);
  });

  test('false HDR payload warns without logging restoration success', () async {
    await seedNativeState(mode: false, hdr: true);
    var accepted = false;
    setHandler((call) async {
      calls.add(call.method);
      expect(call.method, 'restoreSystemHDR');
      return accepted;
    });

    await service.restoreAll();
    expect(service.hdrStateChanged, isTrue);
    var messages = MemoryLogOutput.getLogs().map((entry) => entry.message).join('\n');
    expect(messages, contains('retaining retry state'));
    expect(messages, isNot(contains('Restored system HDR state')));

    accepted = true;
    await service.restoreAll();
    messages = MemoryLogOutput.getLogs().map((entry) => entry.message).join('\n');
    expect(calls, ['restoreSystemHDR', 'restoreSystemHDR']);
    expect(service.hdrStateChanged, isFalse);
    expect(service.anyChangeApplied, isFalse);
    expect(messages, contains('Restored system HDR state'));
  });

  test('HDR failure does not suppress successful mode restoration', () async {
    await seedNativeState(mode: true, hdr: true);
    var hdrAccepted = false;
    setHandler((call) async {
      calls.add(call.method);
      return switch (call.method) {
        'restoreSystemHDR' => hdrAccepted,
        'restoreDisplayMode' => true,
        _ => throw StateError('Unexpected method ${call.method}'),
      };
    });

    await service.restoreAll();
    expect(calls, ['restoreSystemHDR', 'restoreDisplayMode']);
    expect(service.hdrStateChanged, isTrue);
    expect(service.anyChangeApplied, isTrue);

    calls.clear();
    hdrAccepted = true;
    await service.restoreAll();
    expect(calls, ['restoreSystemHDR']);
    expect(service.anyChangeApplied, isFalse);
  });

  test('mode failure does not suppress successful HDR restoration', () async {
    await seedNativeState(mode: true, hdr: true);
    var modeAccepted = false;
    setHandler((call) async {
      calls.add(call.method);
      return switch (call.method) {
        'restoreSystemHDR' => true,
        'restoreDisplayMode' => modeAccepted,
        _ => throw StateError('Unexpected method ${call.method}'),
      };
    });

    await service.restoreAll();
    expect(calls, ['restoreSystemHDR', 'restoreDisplayMode']);
    expect(service.hdrStateChanged, isFalse);
    expect(service.anyChangeApplied, isTrue);

    calls.clear();
    modeAccepted = true;
    await service.restoreAll();
    expect(calls, ['restoreDisplayMode']);
    expect(service.anyChangeApplied, isFalse);
  });

  test('a channel exception retains only the throwing restoration', () async {
    await seedNativeState(mode: true, hdr: true);
    setHandler((call) async {
      calls.add(call.method);
      if (call.method == 'restoreSystemHDR') {
        throw PlatformException(code: 'RESTORE_FAILED');
      }
      if (call.method == 'restoreDisplayMode') return true;
      throw StateError('Unexpected method ${call.method}');
    });

    await service.restoreAll();
    expect(calls, ['restoreSystemHDR', 'restoreDisplayMode']);
    expect(service.hdrStateChanged, isTrue);
    expect(service.anyChangeApplied, isTrue);
  });

  group('findBestRefreshRate', () {
    List<Map> modes(List<int> rates) => [
      for (final rate in rates) {'width': 3840, 'height': 2160, 'refreshRate': rate},
    ];
    int best(double fps, List<int> rates) => DisplayModeService.findBestRefreshRate(fps, modes(rates), 3840, 2160);

    test('reads Windows 23/29/59 Hz modes as their 1000/1001 rates', () {
      expect(best(23.976, [23, 24, 60]), 23);
      expect(best(29.97, [29, 30, 59, 60]), 29);
      expect(best(59.94, [59, 60]), 59);
      // Film-rate content on a panel with only NTSC-family modes.
      expect(best(23.976, [59, 119]), 119);
    });

    test('whole-number content keeps its whole-number modes', () {
      expect(best(24, [23, 24, 60]), 24);
      expect(best(30, [29, 30, 60]), 30);
      expect(best(25, [50, 59, 60]), 50);
      expect(best(60, [59, 60, 120]), 60);
    });
  });

  test('non-Windows override performs no native work', () async {
    service = DisplayModeService.forTesting(
      SettingsService.instance,
      FullscreenStateManager(),
      channel: channel,
      isWindows: false,
    );
    setHandler((call) async {
      calls.add(call.method);
      return true;
    });

    await service.syncWithNative();
    await service.restoreAll();
    expect(calls, isEmpty);
  });
}
