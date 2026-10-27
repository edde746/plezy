import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

/// Guards the channel contract: every property [PlayerBase.handlePropertyChange]
/// depends on for core state must be registered by the mpv backend at init.
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
    final structuredFormat = Platform.isAndroid ? 'string' : 'node';
    for (final call in observations.where((call) {
      final name = (call.arguments as Map)['name'];
      return name == 'track-list' || name == 'demuxer-cache-state' || name == 'audio-device-list';
    })) {
      expect((call.arguments as Map)['format'], structuredFormat);
    }
  });

  test('audio-only mpv registers only the properties the music path consumes', () async {
    final player = PlayerNative.audio();
    final observations = await capturedObservations(
      channelName: 'com.plezy/mpv_audio_player',
      initialize: () => player.setLogLevel('warn'), // forces _ensureInitialized
      dispose: () => player.dispose(),
    );

    expect(names(observations), {'time-pos', 'duration', 'pause', 'eof-reached', 'playlist-pos'});
    final playlistPos = observations.singleWhere((call) => (call.arguments as Map)['name'] == 'playlist-pos');
    expect((playlistPos.arguments as Map)['format'], Platform.isAndroid ? 'string' : 'node');
  });
}
