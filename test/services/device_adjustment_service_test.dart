import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/device_adjustment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test_device_adjustment');
  late DeviceAdjustmentService service;
  late List<MethodCall> calls;

  void setHandler(Future<dynamic> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    calls = <MethodCall>[];
    service = DeviceAdjustmentService(channel: channel);
  });

  tearDown(() {
    setHandler(null);
    service.dispose();
  });

  test('getters clamp native values', () async {
    setHandler((call) async {
      calls.add(call);
      return switch (call.method) {
        'getBrightness' => 2.0,
        'getMediaVolume' => -1.0,
        _ => null,
      };
    });

    expect(await service.getBrightness(), 1.0);
    expect(await service.getMediaVolume(), 0.0);
  });

  test('setters clamp outgoing values', () async {
    setHandler((call) async {
      calls.add(call);
      return null;
    });

    await service.setBrightness(-1);
    await service.setMediaVolume(2);

    expect(calls.map((call) => call.method), ['setBrightness', 'setMediaVolume']);
    expect(calls[0].arguments, 0.0);
    expect(calls[1].arguments, 1.0);
  });

  test('restoreBrightness no-ops before any brightness write', () async {
    setHandler((call) async {
      calls.add(call);
      return null;
    });

    await service.restoreBrightness();

    expect(calls, isEmpty);
  });

  test('restoreBrightness waits behind an in-flight brightness write', () async {
    final setCompleter = Completer<void>();
    setHandler((call) async {
      calls.add(call);
      if (call.method == 'setBrightness') await setCompleter.future;
      return null;
    });

    final setFuture = service.setBrightness(0.8);
    await Future<void>.delayed(Duration.zero);
    final restoreFuture = service.restoreBrightness();

    expect(calls.map((call) => call.method), ['setBrightness']);
    setCompleter.complete();
    await Future.wait([setFuture, restoreFuture]);

    expect(calls.map((call) => call.method), ['setBrightness', 'restoreBrightness']);
  });

  test('missing plugin is harmless', () async {
    setHandler(null);

    expect(await service.getBrightness(), isNull);
    await service.setBrightness(0.7);
    await service.restoreBrightness();
    expect(await service.getMediaVolume(), isNull);
    await service.setMediaVolume(0.3);
  });

  test('platform exceptions are swallowed by the service', () async {
    setHandler((call) async {
      throw PlatformException(code: 'TEST_FAILURE');
    });

    expect(await service.getBrightness(), isNull);
    await service.setBrightness(0.7);
    await service.restoreBrightness();
    expect(await service.getMediaVolume(), isNull);
    await service.setMediaVolume(0.3);
  });
}
