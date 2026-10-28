import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/visualization/visualizer_pack_store.dart';
import 'package:plezy/services/visualization/visualizer_session.dart';

// Regression source only in this delivery. Run on an authorized private JIT
// runner with the rest of the Flutter checks before promoting the feature.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.plezy/mpv_audio_player');
  const preset = VisualizerPresetFile(id: 'fixture', title: 'Fixture', path: '/library/fixture.milk',
    root: '/library', libraryPath: 'imports/fixture.milk');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('disposing during creation releases the lease without loading into a dead widget', () async {
    final creating = Completer<void>();
    final created = Completer<Map<String, int>>();
    final disposed = Completer<int>();
    var loads = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'visualizerCapabilities') return {'available': true};
      if (call.method == 'visualizerCreate') { creating.complete(); return created.future; }
      if (call.method == 'visualizerDispose') disposed.complete((call.arguments as Map)['sessionId'] as int);
      if (call.method == 'visualizerLoad') loads++;
      return null;
    });
    final session = VisualizerSession();
    final loading = session.load(preset);
    await creating.future;
    session.dispose();
    created.complete({'sessionId': 42, 'textureId': 8});
    await loading;
    expect(await disposed.future, 42);
    expect(loads, 0);
  });

  test('an unavailable PCM dependency cannot create a renderer or claim a frame', () async {
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      return {'available': false, 'reason': 'PCM tap missing'};
    });
    final session = VisualizerSession();
    await session.load(preset);
    expect(methods, ['visualizerCapabilities']);
    expect(session.state, 'unavailable');
    expect(session.reason, 'PCM tap missing');
    expect(session.hasFrame, isFalse);
    session.dispose();
  });

  test('stale disposal does not retry against a newer session', () async {
    final leases = <int>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'visualizerCapabilities') return {'available': true};
      if (call.method == 'visualizerCreate') return {'sessionId': 7, 'textureId': 9};
      if (call.method == 'visualizerDispose') {
        leases.add((call.arguments as Map)['sessionId'] as int);
        throw PlatformException(code: 'VISUALIZER_STALE');
      }
      return null;
    });
    final session = VisualizerSession();
    await session.load(preset);
    await session.stop();
    expect(leases, [7]);
    expect(session.textureId, isNull);
    expect(session.active, isFalse);
    session.dispose();
  });

  test('saved double presets are rejected before a native session is created', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async { calls++; return null; });
    final session = VisualizerSession();
    await session.load(const VisualizerPresetFile(id: 'double', title: 'Double', path: '/library/double.milk2',
      root: '/library', libraryPath: 'imports/double.milk2'));
    expect(calls, 0);
    expect(session.state, 'failed');
    expect(session.hasFrame, isFalse);
    session.dispose();
  });
}
