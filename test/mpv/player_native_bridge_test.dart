import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/mpv/video.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

final class _InvokingPlayerNative extends PlayerNative {
  Future<T?> debugInvoke<T>(String method) => invoke<T>(method);
}

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

  test('three overlapping players preserve the newest event owner and serialize native release', () async {
    final calls = <MethodCall>[];
    final eventCalls = <MethodCall>[];
    final firstNativeDisposeStarted = Completer<void>();
    final releaseFirstNativeDispose = Completer<void>();
    final secondNativeDisposeStarted = Completer<void>();
    final releaseSecondNativeDispose = Completer<void>();
    var nativeDisposeCount = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        if (call.method == 'initialize') return true;
        if (call.method == 'dispose') {
          switch (nativeDisposeCount++) {
            case 0:
              firstNativeDisposeStarted.complete();
              await releaseFirstNativeDispose.future;
              break;
            case 1:
              secondNativeDisposeStarted.complete();
              await releaseSecondNativeDispose.future;
              break;
          }
        }
        return null;
      },
      eventHandler: (call) async {
        eventCalls.add(call);
        return null;
      },
      testBody: () async {
        final first = PlayerNative();
        PlayerNative? second;
        PlayerNative? third;
        Future<void>? firstDisposal;
        Future<void>? secondDisposal;
        try {
          await first.setLogLevel('warn');
          second = PlayerNative();
          third = PlayerNative();
          await Future<void>.delayed(Duration.zero);

          expect(eventCalls.where((call) => call.method == 'listen'), hasLength(3));

          firstDisposal = first.dispose();
          secondDisposal = second.dispose();
          final thirdInitialization = third.setLogLevel('warn');

          await firstNativeDisposeStarted.future;
          await Future<void>.delayed(Duration.zero);

          expect(secondNativeDisposeStarted.isCompleted, isFalse);
          expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
          expect(eventCalls.where((call) => call.method == 'cancel'), isEmpty);

          releaseFirstNativeDispose.complete();
          await firstDisposal;
          await secondNativeDisposeStarted.future;

          expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
          expect(eventCalls.where((call) => call.method == 'cancel'), isEmpty);

          releaseSecondNativeDispose.complete();
          await Future.wait([secondDisposal, thirdInitialization]);

          expect(
            calls.where((call) => call.method == 'initialize' || call.method == 'dispose').map((call) => call.method),
            ['initialize', 'dispose', 'dispose', 'initialize'],
          );

          await third.dispose();
          expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(1));
          expect(calls.where((call) => call.method == 'dispose'), hasLength(3));
        } finally {
          if (!releaseFirstNativeDispose.isCompleted) releaseFirstNativeDispose.complete();
          if (!releaseSecondNativeDispose.isCompleted) releaseSecondNativeDispose.complete();
          await firstDisposal;
          await secondDisposal;
          await first.dispose();
          await second?.dispose();
          await third?.dispose();
        }
      },
    );
  });

  test('dispose does not wait forever for a predecessor that never releases the native channel', () async {
    PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(milliseconds: 5);
    addTearDown(() => PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3));
    final stalledNativeDispose = Completer<void>();
    final calls = <MethodCall>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        if (call.method == 'initialize') return Future.value(true);
        if (call.method == 'dispose' && !stalledNativeDispose.isCompleted) return stalledNativeDispose.future;
        return Future.value(null);
      },
      testBody: () async {
        final first = PlayerNative();
        final second = PlayerNative();
        Future<void>? firstDisposal;
        try {
          await first.setLogLevel('warn');
          firstDisposal = first.dispose();
          await Future<void>.delayed(Duration.zero);

          await second.dispose().timeout(const Duration(seconds: 1));

          expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        } finally {
          if (!stalledNativeDispose.isCompleted) stalledNativeDispose.complete();
          await firstDisposal;
          await second.dispose();
        }
      },
    );
  });

  test('invoke returns null when a predecessor release remains stalled', () async {
    PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(milliseconds: 5);
    addTearDown(() => PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3));
    final stalledNativeDispose = Completer<void>();
    final calls = <MethodCall>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        if (call.method == 'initialize') return Future.value(true);
        if (call.method == 'dispose' && !stalledNativeDispose.isCompleted) return stalledNativeDispose.future;
        return Future.value(null);
      },
      testBody: () async {
        final first = PlayerNative();
        final second = PlayerNative();
        final third = _InvokingPlayerNative();
        Future<void>? firstDisposal;
        try {
          await first.setLogLevel('warn');
          firstDisposal = first.dispose();
          await Future<void>.delayed(Duration.zero);
          await second.dispose();

          expect(await third.debugInvoke<Object>('probe'), isNull);
          expect(calls.where((call) => call.method == 'probe'), isEmpty);

          stalledNativeDispose.complete();
          await firstDisposal;
          await third.setLogLevel('warn');
          expect(calls.where((call) => call.method == 'initialize'), hasLength(2));
        } finally {
          if (!stalledNativeDispose.isCompleted) stalledNativeDispose.complete();
          await firstDisposal;
          await second.dispose();
          await third.dispose();
        }
      },
    );
  });

  test('initialization cannot publish readiness after disposal starts', () async {
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
        final initialization = player.setLogLevel('warn');
        final initializationFailure = expectLater(initialization, throwsA(isA<StateError>()));
        await Future<void>.delayed(Duration.zero);

        final disposal = player.dispose();
        initialize.complete(true);
        await initializationFailure;
        await disposal;

        expect(calls.where((call) => call.method == 'observeProperty'), isEmpty);
        expect(calls.where((call) => call.method == 'setLogLevel'), isEmpty);
        expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
      },
    );
  });

  test('dispose synchronously rejects public core traffic while an audio write is blocked', () async {
    final speedStarted = Completer<void>();
    final releaseSpeed = Completer<void>();
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'speed') {
          speedStarted.complete();
          await releaseSpeed.future;
        }
        return null;
      },
      testBody: () async {
        final player = _InvokingPlayerNative();
        Future<void>? disposal;
        try {
          await player.setLogLevel('warn');
          final rate = player.setRate(1.25);
          await speedStarted.future;

          disposal = player.dispose();
          expect(identical(disposal, player.dispose()), isTrue);
          final callCountAtDisposeEntry = calls.length;

          await Future.wait<void>([
            player.command(['probe']),
            player.open(Media('https://example.test/late.mkv')),
            player.setProperty('pause', 'yes'),
            player.setLogLevel('debug'),
            player.setRate(1.5),
            player.play(),
            player.pause(),
            player.stop(),
            player.seek(const Duration(seconds: 3)),
            player.setVolume(25),
            player.setAudioPassthrough(true),
            player.setAudioNormalization(true),
            player.setAudioDownmix(enabled: true, centerBoostDb: 3, normalize: true),
            player.updateFrame(),
            player.abandonAudioFocus(),
          ]);
          expect(await player.getProperty('pause'), isNull);
          expect(await player.requestAudioFocus(), isFalse);
          expect(await player.setVisible(false), isFalse);
          expect(await player.debugInvoke<Object>('probe-direct'), isNull);
          expect(calls, hasLength(callCountAtDisposeEntry));

          releaseSpeed.complete();
          await rate;
          await disposal;
          expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        } finally {
          if (!releaseSpeed.isCompleted) releaseSpeed.complete();
          await disposal;
          await player.dispose();
        }
      },
    );
  });

  test('Linux texture bootstrap gates observations and commands until ready', () async {
    PlayerNative.debugUseLinuxVideoBootstrap = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);
    final ready = Completer<void>();
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        if (call.method == 'initialize') return Future.value(73);
        if (call.method == 'waitForVideoReady') return ready.future;
        return Future.value(null);
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final operation = player.setLogLevel('warn');
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);

          expect(player.textureId, 73);
          expect(player.textureIdListenable.value, 73);
          expect(calls.any((call) => call.method == 'waitForVideoReady'), isTrue);
          expect(calls.any((call) => call.method == 'observeProperty'), isFalse);
          expect(calls.any((call) => call.method == 'setLogLevel'), isFalse);

          ready.complete();
          await operation;
          expect(calls.any((call) => call.method == 'observeProperty'), isTrue);
          expect(calls.where((call) => call.method == 'setLogLevel'), hasLength(1));
        } finally {
          if (!ready.isCompleted) ready.complete();
          await player.dispose();
        }
      },
    );
  });

  testWidgets('Linux texture handoff stays black until playback restarts', (tester) async {
    PlayerNative.debugUseLinuxVideoBootstrap = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);
    final ready = Completer<void>();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return 73;
        if (call.method == 'waitForVideoReady') {
          await ready.future;
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        await tester.pumpWidget(MaterialApp(home: Video(player: player)));
        expect(find.byType(Texture), findsNothing);

        final initialization = player.setLogLevel('warn');
        await tester.pump();
        expect(find.byType(Texture), findsOneWidget);
        final videoBox = find.descendant(of: find.byType(Video), matching: find.byType(ColoredBox));
        expect(tester.widget<ColoredBox>(videoBox).color, Colors.black);

        ready.complete();
        await initialization;
        player.handlePlayerEvent('playback-restart', null);
        await tester.pump();
        await tester.pump();
        expect(tester.widget<ColoredBox>(videoBox).color, Colors.transparent);

        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(player.dispose);
      },
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('Linux texture bootstrap failure clears the provisional ID and retries', () async {
    PlayerNative.debugUseLinuxVideoBootstrap = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);
    var initializeCount = 0;
    var readinessCount = 0;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return 80 + initializeCount++;
        if (call.method == 'waitForVideoReady' && readinessCount++ == 0) {
          throw PlatformException(code: 'INIT_FAILED', message: 'GPU bootstrap failed');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await expectLater(
            player.setLogLevel('warn'),
            throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'INIT_FAILED')),
          );
          expect(player.textureId, isNull);

          await player.setLogLevel('warn');
          expect(initializeCount, 2);
          expect(readinessCount, 2);
          expect(player.textureId, 81);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('Linux disposal clears the published texture ID', () async {
    PlayerNative.debugUseLinuxVideoBootstrap = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return 73;
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        final textureIds = <int?>[];
        player.textureIdListenable.addListener(() => textureIds.add(player.textureIdListenable.value));

        await player.setLogLevel('warn');
        expect(player.textureId, 73);
        await player.dispose();

        expect(textureIds, [73, null]);
      },
    );
  });

  test('non-Linux texture initialization skips the Linux readiness handshake', () async {
    PlayerNative.debugUseLinuxVideoBootstrap = false;
    addTearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        if (call.method == 'initialize') return 91;
        if (call.method == 'waitForVideoReady') {
          throw StateError('non-Linux backends must not use Linux readiness');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setLogLevel('warn');
          expect(player.textureId, 91);
          expect(calls.any((call) => call.method == 'waitForVideoReady'), isFalse);
        } finally {
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

          Future<void> sendEvent(Object? event) async {
            final done = Completer<void>();
            await messenger.handlePlatformMessage(
              'com.plezy/mpv_player/events',
              codec.encodeSuccessEnvelope(event),
              (_) => done.complete(),
            );
            await done.future;
            await Future<void>.delayed(Duration.zero);
          }

          Future<void> sendObservation(String name, Object? value) async {
            await sendEvent([observations[name], value]);
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

          // Malformed envelopes and malformed siblings are ignored without
          // taking down the event subscription or discarding valid siblings.
          await sendEvent(['not-a-property-id', const {}]);
          await sendEvent({'type': 'event', 'name': 7, 'data': const {}});
          await sendEvent({'type': 'event', 'name': 'unknown', 'data': 'not-a-map'});
          await sendObservation('track-list', const [
            {'type': 7, 'id': 'bad'},
            {
              'type': 'audio',
              'id': 8,
              'title': 12,
              'lang': false,
              'codec': {'unexpected': true},
              'demux-channel-count': 'many',
              'selected': true,
            },
          ]);
          await sendObservation('demuxer-cache-state', const {
            'cache-end': 'not-a-number',
            'seekable-ranges': [
              {'start': 'bad', 'end': 3},
              {'start': 2, 'end': 6},
            ],
          });
          await sendObservation('audio-device-list', const [
            {'name': 9, 'description': 'bad'},
            {'name': 'headphones', 'description': 4},
          ]);

          expect(player.state.tracks.audio.single.id, '8');
          expect(player.state.tracks.audio.single.title, isNull);
          expect(player.state.tracks.audio.single.channels, isNull);
          expect(player.state.buffer, const Duration(milliseconds: 12500));
          expect(player.state.bufferRanges.single.start, const Duration(seconds: 2));
          expect(player.state.bufferRanges.single.end, const Duration(seconds: 6));
          expect(player.state.audioDevices.single.name, 'headphones');
          expect(player.state.audioDevices.single.description, isEmpty);

          await sendObservation('track-list', [double.nan]);
          expect(player.state.tracks.audio.single.id, '8');

          player.handlePropertyChange('aid', 'no');
          expect(player.state.track.audio, isNull);
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

  test('typed rate restores native speed after a generic speed property write', () async {
    final speedValues = <String>[];
    var nativeRate = 1.0;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          if (arguments['name'] == 'speed') {
            final value = arguments['value'] as String;
            speedValues.add(value);
            nativeRate = double.parse(value);
          }
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setProperty('speed', '2');
          await player.setRate(1);

          expect(speedValues, ['2', '1.0']);
          expect(nativeRate, 1);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('late downmix failure force-restores the accepted native filter state', () async {
    final nativeProperties = <String, String>{};
    final writes = <(String, String)>[];
    var rejectNextStereo = false;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          final name = arguments['name'] as String;
          final value = arguments['value'] as String;
          writes.add((name, value));
          if (rejectNextStereo && name == 'audio-channels' && value == 'stereo') {
            rejectNextStereo = false;
            throw PlatformException(code: 'SET_PROPERTY_FAILED');
          }
          nativeProperties[name] = value;
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setAudioDownmix(enabled: true, centerBoostDb: 2, normalize: false);
          writes.clear();
          rejectNextStereo = true;

          await expectLater(
            player.setAudioDownmix(enabled: true, centerBoostDb: 9, normalize: true),
            throwsA(isA<PlatformException>()),
          );

          expect(writes, [
            ('audio-swresample-o', 'center_mix_level=1.9953'),
            ('audio-normalize-downmix', 'yes'),
            ('audio-channels', 'auto-safe'),
            ('audio-channels', 'stereo'),
            ('audio-swresample-o', 'center_mix_level=0.8913'),
            ('audio-normalize-downmix', 'no'),
            ('audio-channels', 'auto-safe'),
            ('audio-channels', 'stereo'),
            ('af', ''),
          ]);
          expect(nativeProperties['audio-swresample-o'], 'center_mix_level=0.8913');
          expect(nativeProperties['audio-normalize-downmix'], 'no');
          expect(nativeProperties['audio-channels'], 'stereo');
          expect(nativeProperties['af'], '');
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('failed older audio field is not revived by a queued different-field update', () async {
    final normalizationStarted = Completer<void>();
    final releaseNormalization = Completer<void>();
    final speedValues = <String>[];
    var normalizationAttempts = 0;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          final name = arguments['name'] as String;
          final value = arguments['value'] as String;
          if (name == 'af' && value.isNotEmpty) {
            normalizationAttempts++;
            if (normalizationAttempts == 1) {
              normalizationStarted.complete();
              await releaseNormalization.future;
              throw PlatformException(code: 'SET_PROPERTY_FAILED');
            }
          }
          if (name == 'speed') speedValues.add(value);
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          final normalization = player.setAudioNormalization(true);
          await normalizationStarted.future;
          final rate = player.setRate(1.25);
          releaseNormalization.complete();

          await expectLater(normalization, throwsA(isA<PlatformException>()));
          await rate;

          expect(normalizationAttempts, 1);
          expect(speedValues, ['1.25']);
        } finally {
          if (!releaseNormalization.isCompleted) releaseNormalization.complete();
          await player.dispose();
        }
      },
    );
  });

  test('failed passthrough write does not publish speculative active state', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'audio-spdif') {
          throw PlatformException(code: 'SET_PROPERTY_FAILED');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await expectLater(player.setAudioPassthrough(true), throwsA(isA<PlatformException>()));
          expect(player.audioPassthroughActive, isFalse);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('failed passthrough restores requested normalization', () async {
    final propertyWrites = <(String, String)>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          final write = (arguments['name'] as String, arguments['value'] as String);
          propertyWrites.add(write);
          if (write.$1 == 'audio-spdif') throw PlatformException(code: 'SET_PROPERTY_FAILED');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setAudioNormalization(true);
          await expectLater(player.setAudioPassthrough(true), throwsA(isA<PlatformException>()));

          expect(propertyWrites.where((write) => write.$1 == 'af').map((write) => write.$2), [
            'loudnorm=I=-14:TP=-3:LRA=4',
            '',
            'loudnorm=I=-14:TP=-3:LRA=4',
          ]);
          expect(player.audioPassthroughActive, isFalse);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('exclusive-audio hint failure does not reject accepted passthrough', () async {
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'audio-exclusive') {
          throw PlatformException(code: 'SET_PROPERTY_FAILED');
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setAudioPassthrough(true);
          expect(player.audioPassthroughActive, isTrue);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  test('failed rate write restores accepted passthrough state', () async {
    var rejectSpeed = false;
    final propertyWrites = <(String, String)>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method == 'setProperty') {
          final arguments = call.arguments as Map;
          final name = arguments['name'] as String;
          final value = arguments['value'] as String;
          propertyWrites.add((name, value));
          if (name == 'speed' && rejectSpeed) {
            throw PlatformException(code: 'SET_PROPERTY_FAILED');
          }
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setAudioPassthrough(true);
          expect(player.audioPassthroughActive, isTrue);
          rejectSpeed = true;

          await expectLater(player.setRate(1.25), throwsA(isA<PlatformException>()));

          expect(player.audioPassthroughActive, isTrue);
          expect(propertyWrites.where((write) => write.$1 == 'audio-spdif').map((write) => write.$2), [
            'ac3,eac3,dts,dts-hd,truehd',
            '',
            'ac3,eac3,dts,dts-hd,truehd',
          ]);
        } finally {
          await player.dispose();
        }
      },
    );
  });

  for (final channel in [
    (label: 'video', method: 'com.plezy/mpv_player', events: 'com.plezy/mpv_player/events', audio: false),
    (label: 'audio', method: 'com.plezy/mpv_audio_player', events: 'com.plezy/mpv_audio_player/events', audio: true),
  ]) {
    group('${channel.label} property bridge', () {
      test('propagates SET_PROPERTY_FAILED', () async {
        final calls = <MethodCall>[];
        await withMockPlayerChannels(
          methodChannelName: channel.method,
          eventChannelName: channel.events,
          methodHandler: (call) async {
            calls.add(call);
            if (call.method == 'initialize') return true;
            if (call.method == 'setProperty') {
              final arguments = call.arguments as Map;
              if (arguments['name'] == 'unsupported-property') {
                throw PlatformException(code: 'SET_PROPERTY_FAILED', message: 'Property write rejected');
              }
            }
            return null;
          },
          testBody: () async {
            final player = channel.audio ? PlayerNative.audio() : PlayerNative();
            try {
              await expectLater(
                player.setProperty('unsupported-property', 'invalid'),
                throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'SET_PROPERTY_FAILED')),
              );

              final initializeIndex = calls.indexWhere((call) => call.method == 'initialize');
              final propertyIndex = calls.indexWhere(
                (call) => call.method == 'setProperty' && (call.arguments as Map)['name'] == 'unsupported-property',
              );
              expect(initializeIndex, isNonNegative);
              expect(propertyIndex, greaterThan(initializeIndex));
            } finally {
              await player.dispose();
            }
          },
        );
      });

      test('failed setVolume leaves published volume unchanged', () async {
        await withMockPlayerChannels(
          methodChannelName: channel.method,
          eventChannelName: channel.events,
          methodHandler: (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'setProperty') {
              final arguments = call.arguments as Map;
              if (arguments['name'] == 'volume') {
                throw PlatformException(code: 'SET_PROPERTY_FAILED', message: 'Property write rejected');
              }
            }
            return null;
          },
          testBody: () async {
            final player = channel.audio ? PlayerNative.audio() : PlayerNative();
            try {
              final initialVolume = player.state.volume;
              await expectLater(
                player.setVolume(37),
                throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'SET_PROPERTY_FAILED')),
              );
              expect(player.state.volume, initialVolume);
            } finally {
              await player.dispose();
            }
          },
        );
      });

      test('successful setVolume publishes only after the accepted write', () async {
        final volumeWriteStarted = Completer<void>();
        final acceptVolumeWrite = Completer<void>();
        await withMockPlayerChannels(
          methodChannelName: channel.method,
          eventChannelName: channel.events,
          methodHandler: (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'setProperty') {
              final arguments = call.arguments as Map;
              if (arguments['name'] == 'volume') {
                volumeWriteStarted.complete();
                await acceptVolumeWrite.future;
              }
            }
            return null;
          },
          testBody: () async {
            final player = channel.audio ? PlayerNative.audio() : PlayerNative();
            try {
              final initialVolume = player.state.volume;
              final write = player.setVolume(42);
              await volumeWriteStarted.future;
              expect(player.state.volume, initialVolume);

              acceptVolumeWrite.complete();
              await write;
              expect(player.state.volume, 42);
            } finally {
              if (!acceptVolumeWrite.isCompleted) acceptVolumeWrite.complete();
              await player.dispose();
            }
          },
        );
      });
    });
  }
}
