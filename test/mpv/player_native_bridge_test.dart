import 'dart:async' show Completer;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('MPV coalesces concurrent Dart initialization requests', () async {
    final initialize = Completer<bool>();
    final calls = <MethodCall>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        if (call.method == 'initialize') return initialize.future;
        return Future.value(null);
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final logLevel = player.setLogLevel('warn');
          final command = player.command(['stop']);
          await Future<void>.delayed(Duration.zero);

          expect(calls.where((call) => call.method == 'initialize'), hasLength(1));

          initialize.complete(true);
          await Future.wait([logLevel, command]);

          expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
          expect(calls.where((call) => call.method == 'setLogLevel'), hasLength(1));
          expect(calls.where((call) => call.method == 'command'), hasLength(1));
        } finally {
          if (!initialize.isCompleted) initialize.complete(true);
          await player.dispose();
        }
      },
    );
  });

  test('MPV accepts nested node observations and null unsupported values', () async {
    final observations = <String, int>{};
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'observeProperty') {
          final arguments = call.arguments as Map;
          observations[arguments['name'] as String] = arguments['id'] as int;
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setLogLevel('warn');
          final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          const codec = StandardMethodCodec();

          Future<void> sendObservation(String name, Object? value) async {
            final done = Completer<void>();
            await messenger.handlePlatformMessage(
              'com.plezy/mpv_player/events',
              codec.encodeSuccessEnvelope([observations[name], value]),
              (_) => done.complete(),
            );
            await done.future;
            await Future<void>.delayed(Duration.zero);
          }

          await sendObservation('track-list', const [
            {
              'type': 'audio',
              'id': 7,
              'title': 'Main',
              'selected': true,
              'metadata': {
                'nested': [true, 2, 3.5, null],
              },
            },
          ]);
          await sendObservation('demuxer-cache-state', const {
            'cache-end': 12.5,
            'seekable-ranges': [
              {'start': 1, 'end': 9.25},
            ],
          });
          await sendObservation('audio-device-list', const [
            {'name': 'speakers', 'description': 'Main speakers'},
          ]);

          expect(player.state.tracks.audio.single.id, '7');
          expect(player.state.tracks.audio.single.title, 'Main');
          expect(player.state.buffer, const Duration(milliseconds: 12500));
          expect(player.state.bufferRanges.single.start, const Duration(seconds: 1));
          expect(player.state.bufferRanges.single.end, const Duration(milliseconds: 9250));
          expect(player.state.audioDevices.single.name, 'speakers');

          // Unsupported mpv_node formats cross the native bridge as null and
          // must not erase the last valid structured observation.
          for (final invalid in [null, '{not-json', 42]) {
            await sendObservation('track-list', invalid);
            await sendObservation('demuxer-cache-state', invalid);
            await sendObservation('audio-device-list', invalid);

            expect(player.state.tracks.audio.single.id, '7');
            expect(player.state.buffer, const Duration(milliseconds: 12500));
            expect(player.state.bufferRanges.single.end, const Duration(milliseconds: 9250));
            expect(player.state.audioDevices.single.name, 'speakers');
          }
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('Android command failure reaches seek recovery', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'command') {
          throw PlatformException(code: 'COMMAND_FAILED', message: 'mpv command failed');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.seek(const Duration(seconds: 12));
          expect(player.state.position, Duration.zero);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('Android setLogLevel failure is exposed to Dart', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setLogLevel') {
          throw PlatformException(code: 'UNSUPPORTED');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await expectLater(
            player.setLogLevel('warn'),
            throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'UNSUPPORTED')),
          );
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('audio setLogLevel uses the dedicated native channel', () async {
    MethodCall? logLevelCall;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_audio_player',
      eventChannelName: 'com.plezy/mpv_audio_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setLogLevel') logLevelCall = call;
        return null;
      },
      testBody: () async {
        final player = PlayerNative.audio();
        try {
          await player.setLogLevel('v');
          expect(logLevelCall?.arguments, {'level': 'v'});
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('Android mpv end-file error preserves native diagnostic message', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final player = PlayerNative();
        final error = player.streams.error.first;
        try {
          player.handlePlayerEvent('end-file', {'reason': 4, 'message': 'Invalid data found when processing input'});

          await expectLater(
            error,
            completion(
              isA<PlayerError>().having(
                (value) => value.message,
                'message',
                'Invalid data found when processing input',
              ),
            ),
          );
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('Android mpv legacy end-file error keeps playback error fallback', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final player = PlayerNative();
        final error = player.streams.error.first;
        try {
          player.handlePlayerEvent('end-file', {'reason': 4});

          await expectLater(
            error,
            completion(isA<PlayerError>().having((value) => value.message, 'message', 'Playback error')),
          );
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('overlapping playback-rate changes are serialized in call order', () async {
    final releaseFirstSpeed = Completer<void>();
    final firstSpeedStarted = Completer<void>();
    final speedValues = <String>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          if (arguments['name'] == 'speed') {
            speedValues.add(arguments['value'] as String);
            if (!firstSpeedStarted.isCompleted) firstSpeedStarted.complete();
            if (speedValues.length == 1) await releaseFirstSpeed.future;
          }
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final first = player.setRate(1.25);
          final second = player.setRate(1.5);
          await firstSpeedStarted.future;

          expect(speedValues, ['1.25']);

          releaseFirstSpeed.complete();
          await Future.wait([first, second]);
          expect(speedValues, ['1.25', '1.5']);
        } finally {
          if (!releaseFirstSpeed.isCompleted) releaseFirstSpeed.complete();
          await player.dispose();
        }
      },
    );
  });
}
