import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

/// Guards the channel contract: every property [PlayerBase.handlePropertyChange]
/// depends on for core state must be registered by each backend at init.
/// The Android ExoPlayer plugin replays exactly these registrations into a
/// fallback MPV core, so a missing registration here silently breaks the
/// event stream after a backend switch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  const coreNames = {
    'time-pos',
    'duration',
    'seekable',
    'pause',
    'paused-for-cache',
    'eof-reached',
    'volume',
    'speed',
    'aid',
    'sid',
    'track-list',
  };

  Future<List<MethodCall>> capturedObservations({
    required String channelName,
    required Future<void> Function() initialize,
    required Future<void> Function() dispose,
  }) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final methodChannel = MethodChannel(channelName);
    final observations = <MethodCall>[];

    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'observeProperty') observations.add(call);
      if (call.method == 'initialize') return true;
      return null;
    });
    try {
      await initialize();
    } finally {
      await dispose();
      messenger.setMockMethodCallHandler(methodChannel, null);
    }
    return observations;
  }

  Set<String> names(List<MethodCall> calls) => calls.map((c) => (c.arguments as Map)['name'] as String).toSet();

  test('the shared core table covers every state-critical property', () {
    final tableNames = PlayerBase.corePropertyObservations.map((e) => e.$1).toSet()..add('track-list');
    expect(tableNames, coreNames);
  });

  test('ExoPlayer registers the core properties (plus its cache extra)', () async {
    final player = PlayerAndroid();
    final observations = await capturedObservations(
      channelName: 'com.plezy/exo_player',
      initialize: () => player.requestAudioFocus(), // forces _ensureInitialized
      dispose: () => player.dispose(),
    );

    final registered = names(observations);
    expect(registered, containsAll(coreNames));
    expect(registered, contains('demuxer-cache-time'));
    for (final call in observations) {
      final args = call.arguments as Map;
      expect(args['format'], isNotNull);
      expect(args['id'], isA<int>());
    }
  });

  test('mpv registers the core properties (plus its track/device extras)', () async {
    final player = PlayerNative();
    final observations = await capturedObservations(
      channelName: 'com.plezy/mpv_player',
      initialize: () => player.setLogLevel('warn'), // forces _ensureInitialized
      dispose: () => player.dispose(),
    );

    final registered = names(observations);
    expect(registered, containsAll(coreNames));
    expect(registered, containsAll({'secondary-sid', 'demuxer-cache-state', 'audio-device-list', 'audio-device'}));
  });
}
