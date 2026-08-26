import 'dart:async' show Completer;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// Exposes the protected playhead-arbitration seams so their interleavings can
/// be driven directly, without the method channel serialising handlers.
final class _ArbitrationPlayerNative extends PlayerNative {
  int begin() => beginPlayheadRelocation();

  void commit(int token) => commitPlayheadRelocation(token);

  void adoptNewSource() => takeSourceOwnership();

  void publish(Duration position, int token) => publishPlayheadRelocation(position, token: token);

  Future<void> seekVia(Duration position, Future<void> Function() seekFn) => runSeek(position, seekFn);
}

/// Audio-only player for driving the real gapless seam: `setNext` arms an
/// entry, and a `file-loaded` the player did not ask for means mpv rolled
/// into it.
final class _AdvancingAudioPlayerNative extends PlayerNative {
  _AdvancingAudioPlayerNative() : super.audio();

  Future<void> seekVia(Duration position, Future<void> Function() seekFn) => runSeek(position, seekFn);

  void markInitialized() => initialized = true;

  void installSource(Duration at) => resetPlaybackProgress(at);
}

final class _InvokingPlayerNative extends PlayerNative {
  Future<T?> debugInvoke<T>(String method) => invoke<T>(method);
}

final class _GuardedPlayerNative extends PlayerNative {
  @override
  bool get nativeDisposeIsStaleGuarded => true;
}

final class _GuardedInvokingPlayerNative extends PlayerNative {
  @override
  bool get nativeDisposeIsStaleGuarded => true;

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

  test('initialize carries the decode intent and the instance token (#2010)', () async {
    for (final hardwareDecoding in [true, false]) {
      final calls = <MethodCall>[];
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          return null;
        },
        testBody: () async {
          final player = PlayerNative(hardwareDecoding: hardwareDecoding);
          try {
            await player.setLogLevel('warn');
            final init = calls.singleWhere((call) => call.method == 'initialize');
            expect(init.arguments, {'hardwareDecoding': hardwareDecoding, 'instanceId': player.nativeInstanceId});
          } finally {
            await player.dispose();
          }
        },
      );
    }

    final audioCalls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_audio_player',
      eventChannelName: 'com.plezy/mpv_audio_player/events',
      methodHandler: (call) async {
        audioCalls.add(call);
        if (call.method == 'initialize') return true;
        return null;
      },
      testBody: () async {
        final player = PlayerNative.audio();
        try {
          await player.setLogLevel('warn');
          final init = audioCalls.singleWhere((call) => call.method == 'initialize');
          expect(init.arguments, {'instanceId': player.nativeInstanceId});
        } finally {
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
    PlayerBase.debugNativeOwnershipInvokeTimeout = const Duration(milliseconds: 5);
    addTearDown(() {
      PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3);
      PlayerBase.debugNativeOwnershipInvokeTimeout = const Duration(seconds: 8);
    });
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

  test('a stale-guarded backend force-disposes past a hung predecessor and frees the channel', () async {
    PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(milliseconds: 5);
    PlayerBase.debugNativeOwnershipInvokeTimeout = const Duration(milliseconds: 50);
    addTearDown(() {
      PlayerBase.debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3);
      PlayerBase.debugNativeOwnershipInvokeTimeout = const Duration(seconds: 8);
    });
    // The first player's native dispose never completes — the hung-teardown
    // scenario that used to wedge every later session behind a release chain.
    // Later disposes answer normally, standing in for the plugin's dispose
    // watchdog and stale-token acknowledgement.
    final hungNativeDispose = Completer<void>();
    var sawFirstDispose = false;
    final calls = <MethodCall>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        if (call.method == 'initialize') return Future.value(true);
        if (call.method == 'dispose' && !sawFirstDispose) {
          sawFirstDispose = true;
          return hungNativeDispose.future;
        }
        return Future.value(null);
      },
      testBody: () async {
        final first = _GuardedPlayerNative();
        final second = _GuardedPlayerNative();
        final third = _GuardedInvokingPlayerNative();
        Future<void>? firstDisposal;
        try {
          await first.setLogLevel('warn');
          firstDisposal = first.dispose();
          await Future<void>.delayed(Duration.zero);

          // The successor's dispose times out waiting, then force-sends its
          // own token instead of skipping, and settles its release at once.
          await second.dispose().timeout(const Duration(seconds: 1));
          final disposes = calls.where((call) => call.method == 'dispose').toList();
          expect(disposes, hasLength(2));
          expect((disposes.last.arguments as Map)['instanceId'], second.nativeInstanceId);

          // The channel is usable again while the hung teardown is still
          // pending: the third player's commands are not wedged behind it.
          await third.setLogLevel('warn');
          expect(calls.where((call) => call.method == 'initialize'), hasLength(2));
        } finally {
          if (!hungNativeDispose.isCompleted) hungNativeDispose.complete();
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

  test('a Linux video plane that cannot start fails initialization by name', () async {
    PlayerNative.debugUseLinuxVideoPlane = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoPlane = null);
    final calls = <MethodCall>[];
    final errors = <String>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        if (call.method == 'initialize') {
          throw PlatformException(
            code: 'VIDEO_PLANE_UNSUPPORTED',
            message: 'compositor does not advertise wl_subcompositor',
          );
        }
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        final subscription = player.streams.error.listen((error) => errors.add(error.message));
        try {
          await expectLater(
            player.setLogLevel('warn'),
            throwsA(
              isA<PlatformException>()
                  .having((error) => error.code, 'code', 'VIDEO_PLANE_UNSUPPORTED')
                  .having((error) => error.message, 'message', contains('wl_subcompositor')),
            ),
          );

          // There is no second video path to degrade onto, so the only correct
          // outcome is a refusal that names its cause. Nothing may run past it:
          // a player that observed properties or accepted commands here would be
          // one playing audio at a black window.
          expect(calls.map((call) => call.method), ['initialize']);
          // The refusal reaches the error stream a turn behind the throw.
          await Future<void>.delayed(Duration.zero);
          expect(errors.single, contains('wl_subcompositor'));

          // Nor is the failure cached as a half-open player: the next caller
          // asks the plane again and is refused by name again, rather than
          // sliding through on a memoized "already initialized".
          await expectLater(player.setLogLevel('warn'), throwsA(isA<PlatformException>()));
          expect(calls.map((call) => call.method), ['initialize', 'initialize']);
        } finally {
          await subscription.cancel();
          await player.dispose();
        }
      },
    );
  });

  test('the native hdr-output-changed event reaches the stream, and a typeless envelope does not', () async {
    // The only notice Dart gets that dragging the window changed the answer to
    // isHdrOutputSupported: Wayland raises no lifecycle event for it. Asserted
    // on the real event channel rather than a fake stream because the failure
    // mode is a rename on one side of the wire, which a fake cannot see.
    var changes = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final player = PlayerNative();
        final subscription = player.streams.hdrOutputChanged.listen((_) => changes++);
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

          await sendEvent(const {'type': 'event', 'name': 'hdr-output-changed'});
          expect(changes, 1);

          // The envelope needs both keys. Omitting `type` is not hypothetical -
          // it is exactly what the native side once sent, and the event was
          // dropped in silence, so the settings sheet kept whatever HDR verdict
          // it had from before the window moved.
          await sendEvent(const {'name': 'hdr-output-changed'});
          expect(changes, 1);

          // And the channel is still live afterwards: a malformed sibling must
          // not take the subscription down with it.
          await sendEvent(const {'type': 'event', 'name': 'hdr-output-changed'});
          expect(changes, 2);
        } finally {
          await subscription.cancel();
          await player.dispose();
        }
      },
    );
  });

  test('the HDR output probe asks the plane by name and answers what it said', () async {
    // The name is half the contract: nothing else in the app invokes
    // isHDRSupported on the player channel, so a misspelling here would simply
    // answer null forever and hide the HDR controls on every Linux session.
    PlayerNative.debugUseLinuxVideoPlane = true;
    addTearDown(() => PlayerNative.debugUseLinuxVideoPlane = null);
    final calls = <MethodCall>[];
    Object? reply;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        if (call.method == 'initialize') return true;
        if (call.method == 'isHDRSupported') return reply;
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          reply = true;
          expect(await player.isHdrOutputSupported(), isTrue);

          // Not cached: the output under the window is what the answer folds in,
          // and that changes without Dart asking anything.
          reply = false;
          expect(await player.isHdrOutputSupported(), isFalse);

          // A native that does not implement the method answers null, which is
          // "no HDR" rather than a crash or an optimistic yes.
          reply = null;
          expect(await player.isHdrOutputSupported(), isFalse);

          expect(calls.where((call) => call.method == 'isHDRSupported'), hasLength(3));
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
            'loudnorm=I=-14:TP=-3:LRA=4,format=srate=48000:format=floatp',
            '',
            'loudnorm=I=-14:TP=-3:LRA=4,format=srate=48000:format=floatp',
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

  group('playhead jump announcements', () {
    test('a seek publishes its requested target alongside the optimistic position', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            await player.seek(const Duration(minutes: 5));
            await Future<void>.delayed(Duration.zero);

            expect(announced, [const Duration(minutes: 5)]);
            expect(player.state.position, const Duration(minutes: 5));
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a seek the backend rejects announces the position it rolled back to', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command') {
            throw PlatformException(code: 'COMMAND_FAILED', message: 'player not ready');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            await player.seek(const Duration(minutes: 5));
            await Future<void>.delayed(Duration.zero);

            // The request is announced when the playhead optimistically moves,
            // because a consumer coalescing its own seeks has to react inside
            // that window. Undoing it has to be announced too, or that consumer
            // keeps building on a target the backend rejected.
            expect(announced, [const Duration(minutes: 5), Duration.zero]);
            expect(player.state.position, Duration.zero);
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a rejected seek reports the position a native tick left behind', () async {
      // `_positionMs` updates on every tick while `PlayerState.position` is
      // throttled, so a tick from the still-playing old position can land mid
      // seek. The rollback must not overwrite it — but staying silent would
      // leave the rejected target pinned (#1819).
      late PlayerNative player;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command') {
            player.handlePropertyChange('time-pos', 20.0);
            throw PlatformException(code: 'COMMAND_FAILED', message: 'player not ready');
          }
          return null;
        },
        testBody: () async {
          player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            // Anchor the 250 ms emit throttle, which runs off a Stopwatch
            // started at construction. Either this tick is itself throttled
            // (so under 250 ms have passed) or it emits and resets the window;
            // either way the racing tick a few microseconds later is throttled,
            // so only the rollback can bring `PlayerState.position` back in
            // line. Without this the assertion would silently stop
            // discriminating on a slow machine.
            player.handlePropertyChange('time-pos', 10.0);

            await player.seek(const Duration(minutes: 5));
            await Future<void>.delayed(Duration.zero);

            expect(announced, [const Duration(minutes: 5), const Duration(seconds: 20)]);
            expect(player.currentPosition, const Duration(seconds: 20), reason: 'the newer tick wins the position');
            // `PlayerState.position` is throttled, so it can still be showing
            // the optimistic target. Consumers rebase off it, so the abandoned
            // target must not survive there either.
            expect(player.state.position, const Duration(seconds: 20));
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a superseded seek failing late leaves the newer seek alone', () async {
      // Otherwise the stale failure republishes the newer target, which reads
      // as a foreign jump and retires the pin that target belongs to (#1819).
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      var commands = 0;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command' && commands++ == 0) {
            firstReached.complete();
            await releaseFirst.future;
            throw PlatformException(code: 'COMMAND_FAILED', message: 'superseded');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final stale = player.seek(const Duration(minutes: 5));
            await firstReached.future;
            await player.seek(const Duration(minutes: 9));

            releaseFirst.complete();
            await stale;
            await Future<void>.delayed(Duration.zero);

            expect(announced, [const Duration(minutes: 5), const Duration(minutes: 9)]);
            expect(player.state.position, const Duration(minutes: 9), reason: 'the newer seek still owns the playhead');
          } finally {
            if (!releaseFirst.isCompleted) releaseFirst.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    /// Runs two overlapping seeks — 5m then 9m — where the FIRST one's backend
    /// call is held open until the second has already settled, so replies come
    /// back out of order. [firstSucceeds]/[secondSucceeds] pick each outcome.
    ///
    /// [tickDuringFlight] injects a native `time-pos` while both are in flight.
    /// An anchor tick is sent first so it is guaranteed to fall inside the
    /// 250 ms emit throttle, which is what leaves `PlayerState.position` stale.
    Future<({List<Duration?> announced, Duration position, Duration rawPosition})> runOverlappingSeeks({
      required bool firstSucceeds,
      required bool secondSucceeds,
      Duration? tickDuringFlight,
    }) async {
      late PlayerNative player;
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      var commands = 0;
      late List<Duration?> announced;
      late Duration position;
      late Duration rawPosition;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command') {
            final isFirst = commands++ == 0;
            if (isFirst) {
              firstReached.complete();
              await releaseFirst.future;
            } else if (tickDuringFlight != null) {
              player.handlePropertyChange('time-pos', tickDuringFlight.inMilliseconds / 1000);
            }
            if (isFirst ? firstSucceeds : secondSucceeds) return null;
            throw PlatformException(code: 'COMMAND_FAILED', message: 'player not ready');
          }
          return null;
        },
        testBody: () async {
          player = PlayerNative();
          announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            player.handlePropertyChange('time-pos', 0.0);
            final first = player.seek(const Duration(minutes: 5));
            await firstReached.future;
            await player.seek(const Duration(minutes: 9));

            releaseFirst.complete();
            await first;
            await Future<void>.delayed(Duration.zero);
            position = player.state.position;
            rawPosition = player.currentPosition;
          } finally {
            if (!releaseFirst.isCompleted) releaseFirst.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
      return (announced: announced, position: position, rawPosition: rawPosition);
    }

    test('two overlapping seeks both failing put the playhead back where it started', () async {
      final result = await runOverlappingSeeks(firstSucceeds: false, secondSucceeds: false);

      expect(result.announced, [const Duration(minutes: 5), const Duration(minutes: 9), Duration.zero]);
      expect(result.position, Duration.zero, reason: 'neither seek landed, so nothing moved');
    });

    test('a rejected newer seek falls back to the target its predecessor landed', () async {
      final result = await runOverlappingSeeks(firstSucceeds: true, secondSucceeds: false);

      expect(result.announced, [const Duration(minutes: 5), const Duration(minutes: 9), const Duration(minutes: 5)]);
      expect(result.position, const Duration(minutes: 5), reason: 'only the older seek was accepted');
    });

    test('out-of-order replies still leave the newest accepted seek in charge', () async {
      // The backend applies commands in issue order, so 9m wins even though its
      // reply arrived first. Picking by completion order would rewind to 5m.
      final result = await runOverlappingSeeks(firstSucceeds: true, secondSucceeds: true);

      expect(result.announced, [const Duration(minutes: 5), const Duration(minutes: 9)]);
      expect(result.position, const Duration(minutes: 9));
    });

    test('a throttled tick cannot hide the target the accepted seek reached', () async {
      // The backend accepted 5m and reported it, but `PlayerState.position` is
      // throttled and still shows the rejected 9m. Consumers rebase off state,
      // so deciding by position instead of by which request landed would leave
      // the next skip chaining from a target nothing reached (#1819).
      final result = await runOverlappingSeeks(
        firstSucceeds: true,
        secondSucceeds: false,
        tickDuringFlight: const Duration(minutes: 5),
      );

      expect(result.rawPosition, const Duration(minutes: 5));
      expect(result.position, const Duration(minutes: 5), reason: 'state must not keep the rejected 9m target');
      expect(result.announced.last, const Duration(minutes: 5));
    });

    test('a source opened at a resume position announces where the playhead landed', () async {
      // Dead-stream recovery, a quality switch and a background-suspend resume
      // all rebuild the stream at a position instead of seeking, so the reload
      // is the second way the playhead moves discontinuously (#1819).
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            await player.open(Media('https://example.test/reload.mkv', start: const Duration(minutes: 12)));
            await Future<void>.delayed(Duration.zero);

            expect(announced, [const Duration(minutes: 12)]);
            expect(player.state.position, const Duration(minutes: 12));
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a subtitle seek announces the jump, then the cue mpv chose', () async {
      // Ctrl+Arrow is bound to sub-seek by default, right beside the plain
      // arrow skip. mpv picks the cue itself, so the jump is announced without
      // a destination up front and the real one is read back after, because
      // `PlayerState.position` is what the next skip rebases from (#1819).
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            return '123.5';
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            await player.command(['sub-seek', '1']);
            await Future<void>.delayed(Duration.zero);
            expect(announced, [isNull, const Duration(milliseconds: 123500)]);
            expect(
              player.state.position,
              const Duration(milliseconds: 123500),
              reason: 'a skip pressed straight after must start from the cue, not from before it',
            );

            // An ordinary command leaves the playhead alone and must stay quiet.
            await player.command(['screenshot', 'subtitles']);
            await Future<void>.delayed(Duration.zero);
            expect(announced, hasLength(2));
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a relocation while seeks are in flight survives their settlement', () async {
      // A subtitle seek (or an in-place reload) can land between an overlapping
      // group starting and finishing. It is newer information than any of their
      // outcomes, so the group must not write its own answer over it (#1819).
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            return '400.0';
          }
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'sub-seek') return null;
            if (double.parse(args[1]) == 300.0) {
              firstReached.complete();
              await releaseFirst.future;
              return null; // the older seek is accepted, late
            }
            throw PlatformException(code: 'COMMAND_FAILED', message: 'newer seek rejected');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final first = player.seek(const Duration(minutes: 5));
            await firstReached.future;
            await player.seek(const Duration(minutes: 9));
            await player.command(['sub-seek', '1']);

            releaseFirst.complete();
            await first;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(seconds: 400),
              reason: 'the subtitle cue is newer than either seek outcome',
            );
            expect(announced.last, const Duration(seconds: 400));
          } finally {
            if (!releaseFirst.isCompleted) releaseFirst.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a seek started after a relocation is anchored to it, not to the held group', () async {
      // The old seek is still in flight, so a naive in-flight count would fold
      // the new one into its group and roll back to the pre-relocation anchor.
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            return '400.0';
          }
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'sub-seek') return null;
            if (double.parse(args[1]) == 300.0) {
              firstReached.complete();
              await releaseFirst.future;
              return null;
            }
            throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final held = player.seek(const Duration(minutes: 5));
            await firstReached.future;
            await player.command(['sub-seek', '1']);
            await player.seek(const Duration(minutes: 9));

            releaseFirst.complete();
            await held;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(seconds: 400),
              reason: 'the rejected 9m seek must fall back to the cue it started from',
            );
            expect(announced.last, const Duration(seconds: 400));
          } finally {
            if (!releaseFirst.isCompleted) releaseFirst.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a slow subtitle seek does not overwrite a seek issued while it ran', () async {
      // KeyboardShortcutsService fires sub-seek without awaiting it, so its
      // read-back can complete after a newer skip has already been issued. The
      // newer seek owns the playhead; the stale cue must be dropped.
      final subSeekReached = Completer<void>();
      final releaseSubSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            return '400.0';
          }
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'sub-seek') {
              subSeekReached.complete();
              await releaseSubSeek.future;
            }
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final subSeek = player.command(['sub-seek', '1']);
            await subSeekReached.future;
            await player.seek(const Duration(minutes: 9));

            releaseSubSeek.complete();
            await subSeek;
            await Future<void>.delayed(Duration.zero);

            expect(announced, [isNull, const Duration(minutes: 9)]);
            expect(
              player.state.position,
              const Duration(minutes: 9),
              reason: 'the stale subtitle cue must not win over the newer seek',
            );
          } finally {
            if (!releaseSubSeek.isCompleted) releaseSubSeek.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('two overlapping subtitle seeks leave the newer cue in charge', () async {
      // Each press fires without awaiting, so the older command can answer
      // last. mpv applies them in order, so the newer cue is the truth and the
      // older one must be discarded on arrival rather than merely overtaken.
      final gates = [Completer<void>(), Completer<void>()];
      final reached = [Completer<void>(), Completer<void>()];
      var commandIndex = 0;
      var readBackIndex = 0;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            // The newer command settles first, so it reads its cue first.
            return readBackIndex++ == 0 ? '200.0' : '100.0';
          }
          if (call.method == 'command') {
            final index = commandIndex++;
            reached[index].complete();
            await gates[index].future;
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final first = player.command(['sub-seek', '1']);
            await reached[0].future;
            final second = player.command(['sub-seek', '1']);
            await reached[1].future;

            // Newer answers first and publishes 200; the older press then
            // answers with its own stale 100.
            gates[1].complete();
            await second;
            await Future<void>.delayed(Duration.zero);
            expect(player.state.position, const Duration(seconds: 200));

            gates[0].complete();
            await first;
            await Future<void>.delayed(Duration.zero);

            expect(player.state.position, const Duration(seconds: 200), reason: 'the stale cue must be discarded');
            expect(
              announced,
              isNot(contains(const Duration(seconds: 100))),
              reason: 'and never announced to a consumer',
            );
          } finally {
            for (final gate in gates) {
              if (!gate.isCompleted) gate.complete();
            }
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a rejected relocation leaves the seek group able to undo itself', () async {
      // Claiming must not take ownership away from an in-flight group. The
      // subtitle command is refused, so the playhead never moved and the
      // rejected seek still has to be rolled back rather than left standing.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'seek') {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            }
            // The subtitle command is refused too, so nothing moved.
            throw PlatformException(code: 'COMMAND_FAILED', message: 'refused');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final seek = player.seek(const Duration(minutes: 5));
            await seekReached.future;
            await expectLater(player.command(['sub-seek', '1']), throwsA(isA<PlatformException>()));

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              Duration.zero,
              reason: 'the rejected seek must still be undone, not left owning the playhead',
            );
            expect(announced.last, Duration.zero);
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('an accepted relocation with an unreadable position still takes ownership', () async {
      // mpv moved the playhead; only the read-back failed. An older rejected
      // seek must not roll back across a cue that actually happened, even
      // though nobody can say yet where it landed.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          // Accepted command, unreadable position.
          if (call.method == 'getProperty') return null;
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'seek') {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            }
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final seek = player.seek(const Duration(minutes: 5));
            await seekReached.future;
            await player.command(['sub-seek', '1']);

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(announced, [
              const Duration(minutes: 5),
              isNull,
            ], reason: 'the rejected seek must not announce a rollback across the cue');
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a rejected seek cannot invalidate the cue an accepted subtitle seek is still reading', () async {
      // The seek only ever asked; it never moved the playhead. Ownership has to
      // turn on operations the backend accepted, or the subtitle cue is thrown
      // away and the next skip rebases from the pre-cue anchor.
      final subSeekReached = Completer<void>();
      final releaseSubSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty' && (call.arguments as Map)['name'] == 'time-pos') {
            return '400.0';
          }
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'sub-seek') {
              subSeekReached.complete();
              await releaseSubSeek.future;
              return null; // accepted, just slow
            }
            throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final subSeek = player.command(['sub-seek', '1']);
            await subSeekReached.future;
            await player.seek(const Duration(minutes: 9));

            releaseSubSeek.complete();
            await subSeek;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(seconds: 400),
              reason: 'the accepted cue owns the playhead; the rejected seek never touched it',
            );
            expect(announced.last, const Duration(seconds: 400));
          } finally {
            if (!releaseSubSeek.isCompleted) releaseSubSeek.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a successful seek repairs a stale tick but keeps progress past its target', () async {
      // `_positionMs` moves on every tick while `PlayerState.position` is
      // throttled, so settlement has to reconcile them — without rewinding
      // playback that has legitimately moved on from the accepted target. What
      // separates the two is the media time the command was in flight for, not
      // a fixed window: at speed, real progress can outrun any constant.
      const inFlight = Duration(milliseconds: 300);
      Future<Duration> settleWithTick(Duration tick, {required bool playing, double speed = 1.0}) async {
        late Duration result;
        await withMockPlayerChannels(
          methodChannelName: 'com.plezy/mpv_player',
          eventChannelName: 'com.plezy/mpv_player/events',
          methodHandler: (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'command') await Future<void>.delayed(inFlight);
            return null;
          },
          testBody: () async {
            final player = PlayerNative();
            try {
              if (playing) player.handlePropertyChange('pause', false);
              player.handlePropertyChange('speed', speed);
              // Anchor the emit throttle so the tick below cannot reach state
              // on its own; only settlement can.
              player.handlePropertyChange('time-pos', 0.0);
              final seek = player.seek(const Duration(minutes: 5));
              player.handlePropertyChange('time-pos', tick.inMilliseconds / 1000);
              await seek;
              await Future<void>.delayed(Duration.zero);
              result = player.state.position;
            } finally {
              await player.dispose();
            }
          },
        );
        return result;
      }

      expect(
        await settleWithTick(const Duration(seconds: 20), playing: true),
        const Duration(minutes: 5),
        reason: 'a tick from before the seek is stale and must not survive it',
      );
      expect(
        await settleWithTick(const Duration(minutes: 5, milliseconds: 400), playing: true),
        const Duration(minutes: 5, milliseconds: 400),
        reason: 'playback that ran on past the target during the round trip is fresher than it',
      );
      expect(
        await settleWithTick(const Duration(minutes: 5, seconds: 30), playing: true),
        const Duration(minutes: 5),
        reason: 'a jump far past the target is not progress the round trip could produce',
      );
      expect(
        await settleWithTick(const Duration(minutes: 5, milliseconds: 400), playing: false),
        const Duration(minutes: 5),
        reason: 'a paused player covers no media time, so any drift is stale',
      );
      // The window scales with the rate, so the same drift flips verdict.
      expect(
        await settleWithTick(const Duration(minutes: 5, seconds: 2), playing: true, speed: 8.0),
        const Duration(minutes: 5, seconds: 2),
        reason: 'at 8x the round trip really can cover two seconds of media',
      );
      expect(
        await settleWithTick(const Duration(minutes: 5, seconds: 2), playing: true),
        const Duration(minutes: 5),
        reason: 'at 1x the same drift is far more than the round trip could cover',
      );
      expect(
        await settleWithTick(const Duration(minutes: 5, milliseconds: 200), playing: true, speed: 0.25),
        const Duration(minutes: 5),
        reason: 'slow motion covers less ground, so this is a stale tick, not progress',
      );
    });

    /// A subtitle cue whose read-back lands while a newer seek is still in
    /// flight. [seekSucceeds] decides which of the two owns the playhead.
    Future<({Duration position, List<Duration?> announced})> deferredCueRace({required bool seekSucceeds}) async {
      final readReached = Completer<void>();
      final releaseRead = Completer<void>();
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      late Duration position;
      late List<Duration?> announced;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty') {
            readReached.complete();
            await releaseRead.future;
            return '400.0';
          }
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'seek') {
              seekReached.complete();
              await releaseSeek.future;
              if (!seekSucceeds) throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            }
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final cue = player.command(['sub-seek', '1']);
            await readReached.future;
            final seek = player.seek(const Duration(minutes: 9));
            await seekReached.future;

            // The cue answers while the newer seek is still unresolved.
            releaseRead.complete();
            await cue;
            await Future<void>.delayed(Duration.zero);

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);
            position = player.state.position;
          } finally {
            for (final gate in [releaseRead, releaseSeek]) {
              if (!gate.isCompleted) gate.complete();
            }
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
      return (position: position, announced: announced);
    }

    test('a cue held for a pending seek is published when that seek is rejected', () async {
      final result = await deferredCueRace(seekSucceeds: false);

      expect(result.position, const Duration(seconds: 400), reason: 'the seek moved nothing; the cue did');
      expect(result.announced.last, const Duration(seconds: 400));
    });

    test('a cue held for a pending seek is dropped when that seek lands', () async {
      final result = await deferredCueRace(seekSucceeds: true);

      expect(result.position, const Duration(minutes: 9), reason: 'the seek landed after the cue, so it wins');
      expect(
        result.announced,
        isNot(contains(const Duration(seconds: 400))),
        reason: 'a superseded cue must never reach a consumer as a foreign jump',
      );
    });

    test('an accepted cue with no destination yet still lifts a rejected seek target off state', () async {
      // Driven through the arbitration seams directly: the method channel
      // serialises mock handlers, so this interleaving — commit while a newer
      // seek is unresolved, then that seek rejected before the cue's position
      // is known — cannot be produced through two concurrent channel calls.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            // A distinctive starting position, so the fallback below is pinned
            // to the group's anchor rather than passing on a default zero.
            player.handlePropertyChange('time-pos', 42.0);
            const anchor = Duration(seconds: 42);

            final token = player.begin();
            final seek = player.seekVia(const Duration(minutes: 9), () async {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await seekReached.future;
            expect(
              player.state.position,
              const Duration(minutes: 9),
              reason: 'the seek wrote its target optimistically',
            );

            // The relocation is accepted while that seek is still unresolved,
            // so it is held without a destination.
            player.commit(token);

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              anchor,
              reason: 'the rejected target gives way to where the group started, the nearest known base',
            );
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await player.dispose();
          }
        },
      );
    });

    test('a detached group cannot consume a relocation held for the group that replaced it', () async {
      // Three operations deep: an older group is detached, a newer one takes
      // over, and a cue is held against that newer one. The older group
      // draining must not answer for a cue it never saw — publishing would
      // retire the newer group's pin mid-flight, and falling back would restore
      // an anchor from the timeline it was on.
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      final secondReached = Completer<void>();
      final releaseSecond = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final detached = player.seekVia(const Duration(minutes: 2), () async {
              firstReached.complete();
              await releaseFirst.future;
            });
            await firstReached.future;
            // Detaches the first group without waiting for it.
            player.commit(player.begin());

            // Claimed before the replacement group starts, so that group is
            // newer and this cue has to wait on it.
            final heldToken = player.begin();
            final active = player.seekVia(const Duration(minutes: 9), () async {
              secondReached.complete();
              await releaseSecond.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await secondReached.future;
            player.publish(const Duration(minutes: 7), heldToken);
            expect(announced, isNot(contains(const Duration(minutes: 7))), reason: 'held, not published');

            releaseFirst.complete();
            await detached;
            await Future<void>.delayed(Duration.zero);
            expect(
              announced,
              isNot(contains(const Duration(minutes: 7))),
              reason: 'the detached group must not publish a cue held for its successor',
            );

            releaseSecond.complete();
            await active;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(minutes: 7),
              reason: 'the cue outlives the seek it was waiting on, and that seek was rejected',
            );
          } finally {
            for (final gate in [releaseFirst, releaseSecond]) {
              if (!gate.isCompleted) gate.complete();
            }
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a detached group draining does not sync a tick over the live group\'s target', () async {
      // The tick arrived inside the replacement group's window, so it is that
      // group's business. The older group draining must leave state alone
      // rather than treating "the backend spoke last" as licence to write.
      final firstReached = Completer<void>();
      final releaseFirst = Completer<void>();
      final secondReached = Completer<void>();
      final releaseSecond = Completer<void>();
      Future<void>? active;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            final detached = player.seekVia(const Duration(minutes: 2), () async {
              firstReached.complete();
              await releaseFirst.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await firstReached.future;
            // Detaches the first group, then starts the replacement whose
            // optimistic target is what state legitimately shows.
            player.commit(player.begin());
            active = player.seekVia(const Duration(minutes: 9), () async {
              secondReached.complete();
              await releaseSecond.future;
            });
            await secondReached.future;

            // A stale tick lands mid-flight, as they do while a seek is running.
            player.handlePropertyChange('time-pos', 120.0);

            releaseFirst.complete();
            await detached;
            await Future<void>.delayed(Duration.zero);
            expect(
              player.state.position,
              const Duration(minutes: 9),
              reason: 'the live group owns state; a drained predecessor may not hand it a tick from inside that window',
            );
          } finally {
            for (final gate in [releaseFirst, releaseSecond]) {
              if (!gate.isCompleted) gate.complete();
            }
            await active;
            await player.dispose();
          }
        },
      );
    });

    test('a tick that lands exactly on a rejected target is still the backend talking', () async {
      // Playback genuinely reached the position a doomed seek had asked for.
      // Recognising ownership by value would read that tick as the optimistic
      // write and roll the playhead back to where the seek started.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            // A distinctive base, so a rollback to it would be unmistakable.
            player.handlePropertyChange('time-pos', 42.0);
            final seek = player.seekVia(const Duration(minutes: 9), () async {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await seekReached.future;
            // The coincidence: the backend reports the very value the seek
            // wrote optimistically.
            player.handlePropertyChange('time-pos', 540.0);

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);
            expect(
              player.state.position,
              const Duration(minutes: 9),
              reason: 'a reported position is authoritative whatever it equals; only the writer identifies it',
            );
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await player.dispose();
          }
        },
      );
    });

    test('an incoming tick before file-loaded cannot erase where the outgoing track got to', () async {
      // `time-pos` and `playlist-pos` ride the property flow; `file-loaded`
      // rides the event flow, and the two are collected separately. So the new
      // track can report its first position before the advance is detected.
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_audio_player',
        eventChannelName: 'com.plezy/mpv_audio_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _AdvancingAudioPlayerNative();
          try {
            player.markInitialized();
            await player.setNext(const Media('file:///music/next.flac'));

            // The outgoing track's last report, then the boundary, then the
            // incoming track's first report — all in property-flow order.
            player.handlePropertyChange('time-pos', 42.0);
            player.handlePropertyChange('playlist-pos', 1);
            player.handlePropertyChange('time-pos', 0.5);

            // Only now does the event flow catch up.
            player.handlePlayerEvent('file-loaded', null);
            expect(
              player.outgoingSourcePosition,
              const Duration(seconds: 42),
              reason: 'the outgoing track played to 42s; 0.5s is the track that replaced it',
            );
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('a freeze does not outlive the arm it was taken for', () async {
      // The boundary was seen, then the handover was abandoned by a fresh open.
      // A later advance that loses its own `playlist-pos` edge must fall back
      // to what has been reported since, not to that abandoned snapshot.
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_audio_player',
        eventChannelName: 'com.plezy/mpv_audio_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _AdvancingAudioPlayerNative();
          try {
            player.markInitialized();
            await player.setNext(const Media('file:///music/next.flac'));
            player.handlePropertyChange('time-pos', 42.0);
            player.handlePropertyChange('playlist-pos', 1);

            // The user picks something else instead, tearing the arm down.
            await player.setNext(null);
            player.handlePropertyChange('time-pos', 7.0);

            // A later advance whose boundary edge never arrived.
            await player.setNext(const Media('file:///music/third.flac'));
            player.handlePlayerEvent('file-loaded', null);
            expect(
              player.outgoingSourcePosition,
              const Duration(seconds: 7),
              reason: 'the abandoned arm\'s 42s belongs to a handover that never happened',
            );
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('a gapless advance through file-loaded starts the new track from zero', () async {
      // The real seam: an armed entry plus a `file-loaded` the player did not
      // ask for. A seek against the outgoing track is still in flight, and its
      // target must not survive onto the track now playing.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_audio_player',
        eventChannelName: 'com.plezy/mpv_audio_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _AdvancingAudioPlayerNative();
          try {
            player.markInitialized();
            await player.setNext(const Media('file:///music/next.flac'));

            player.handlePropertyChange('time-pos', 42.0);
            final seek = player.seekVia(const Duration(minutes: 9), () async {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await seekReached.future;
            expect(player.state.position, const Duration(minutes: 9), reason: 'written optimistically');

            // mpv rolled into the armed entry on its own, announcing the
            // boundary on the property flow first.
            player.handlePropertyChange('playlist-pos', 1);
            player.handlePlayerEvent('file-loaded', null);
            expect(
              player.state.position,
              Duration.zero,
              reason: 'the new track starts at its beginning, whatever the outgoing one was doing',
            );
            expect(
              player.outgoingSourcePosition,
              const Duration(seconds: 42),
              reason: 'what the outgoing track reported, not the target a doomed seek wrote over it',
            );

            // A second handoff with no tick in between: the new track reported
            // nothing, so it got nowhere — inheriting its predecessor's
            // position would report it stopped somewhere it never played.
            player.markInitialized();
            await player.setNext(const Media('file:///music/third.flac'));
            player.handlePlayerEvent('file-loaded', null);
            expect(
              player.outgoingSourcePosition,
              Duration.zero,
              reason: 'a source that never reported a position did not reach its predecessor\'s',
            );

            // Opening at a resume offset installs a source that is genuinely
            // there, so a handoff before its first tick reports that, not zero
            // and not the track before it.
            player.installSource(const Duration(minutes: 5));
            player.markInitialized();
            await player.setNext(const Media('file:///music/fourth.flac'));
            player.handlePlayerEvent('file-loaded', null);
            expect(
              player.outgoingSourcePosition,
              const Duration(minutes: 5),
              reason: 'a source installed at a resume offset is at that offset until told otherwise',
            );

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);
            expect(
              player.state.position,
              Duration.zero,
              reason: 'the rejected seek belongs to a timeline that is gone; it may not restore onto this one',
            );
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await player.dispose();
          }
        },
      );
    });

    test('a rejected target just past an accepted one is not mistaken for progress', () async {
      // Both seeks are in flight and land milliseconds apart, so the rejected
      // one's optimistic write sits inside the window real playback could have
      // covered. Only the backend observes playback; reading Dart's own write
      // as an observation would keep the position the backend refused.
      final olderReached = Completer<void>();
      final releaseOlder = Completer<void>();
      final newerReached = Completer<void>();
      final releaseNewer = Completer<void>();
      Future<void>? newer;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            player.handlePropertyChange('pause', false);
            final older = player.seekVia(const Duration(minutes: 5), () async {
              olderReached.complete();
              await releaseOlder.future;
            });
            await olderReached.future;
            newer = player.seekVia(const Duration(minutes: 5, milliseconds: 100), () async {
              newerReached.complete();
              await releaseNewer.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await newerReached.future;

            releaseOlder.complete();
            await older;
            releaseNewer.complete();
            await newer;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(minutes: 5),
              reason: 'the accepted target stands; no backend tick ever reported the rejected one',
            );
          } finally {
            for (final gate in [releaseOlder, releaseNewer]) {
              if (!gate.isCompleted) gate.complete();
            }
            await newer;
            await player.dispose();
          }
        },
      );
    });

    test('a group detached by a newer relocation still lifts its own rejected target', () async {
      // The relocation is newer than the whole group, so it detaches it and the
      // group is barred from rolling back across the cue. That does not license
      // leaving a target the backend refused sitting on state.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            player.handlePropertyChange('time-pos', 42.0);

            final seek = player.seekVia(const Duration(minutes: 9), () async {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await seekReached.future;

            // Claimed and accepted after the seek, so it detaches the group.
            player.commit(player.begin());

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              const Duration(seconds: 42),
              reason: 'a detached group must still clean up the target its own rejected request wrote',
            );
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await player.dispose();
          }
        },
      );
    });

    test('a replaced source publishes its own start instead of the old timeline', () async {
      // Gapless advance rolls into a different track without publishing a
      // position. A seek still in flight against the old track must not put its
      // old-timeline base on the new one when it is rejected.
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => call.method == 'initialize' ? true : null,
        testBody: () async {
          final player = _ArbitrationPlayerNative();
          try {
            player.handlePropertyChange('time-pos', 42.0);

            final seek = player.seekVia(const Duration(minutes: 9), () async {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            });
            await seekReached.future;

            // The backend rolls into the next track on its own. No position has
            // been reported for it yet.
            player.adoptNewSource();

            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(
              player.state.position,
              Duration.zero,
              reason: 'the new track starts at its beginning; neither the old base nor the rejected target applies',
            );

            // Once the new track reports a position, that is authoritative.
            player.handlePropertyChange('time-pos', 3.0);
            expect(player.currentPosition, const Duration(seconds: 3));
          } finally {
            if (!releaseSeek.isCompleted) releaseSeek.complete();
            await player.dispose();
          }
        },
      );
    });

    test('an accepted cue with no readable position still blocks a rejected newer seek rollback', () async {
      // The command moved the playhead; only its position is unknown. A newer
      // seek that is then rejected must not undo itself back across the cue.
      final readReached = Completer<void>();
      final releaseRead = Completer<void>();
      final seekReached = Completer<void>();
      final releaseSeek = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getProperty') return null; // accepted, unreadable
          if (call.method == 'command') {
            final args = List<String>.from((call.arguments as Map)['args'] as List);
            if (args.first == 'seek') {
              seekReached.complete();
              await releaseSeek.future;
              throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
            }
            // Hold the subtitle command itself, so the seek starts while this
            // relocation is still unresolved.
            readReached.complete();
            await releaseRead.future;
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            // A distinctive base, so the repair below is pinned to a real value
            // rather than passing on a default zero.
            player.handlePropertyChange('time-pos', 42.0);

            final cue = player.command(['sub-seek', '1']);
            await readReached.future;
            final seek = player.seek(const Duration(minutes: 9));
            await seekReached.future;

            releaseRead.complete();
            await cue;
            releaseSeek.complete();
            await seek;
            await Future<void>.delayed(Duration.zero);

            expect(
              announced,
              [isNull, const Duration(minutes: 9), isNull],
              reason:
                  'no rollback may be announced across a cue the backend accepted, but the abandonment must be '
                  'said again: the first null predates the seek, whose own echo re-armed the consumer',
            );
            expect(
              player.state.position,
              const Duration(seconds: 42),
              reason: 'the rejected target must still come off state, even with nothing to replace it but the base',
            );
          } finally {
            for (final gate in [releaseRead, releaseSeek]) {
              if (!gate.isCompleted) gate.complete();
            }
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('a subtitle seek announces before the command reaches the backend', () async {
      // mpv relocates the playhead while the platform call is still in flight,
      // so announcing on completion would leave a window where a skip commits
      // from the superseded pin.
      final commandReached = Completer<void>();
      final releaseCommand = Completer<void>();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'command') {
            commandReached.complete();
            await releaseCommand.future;
          }
          return null;
        },
        testBody: () async {
          final player = PlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
          try {
            final pending = player.command(['sub-seek', '1']);
            await commandReached.future;
            await Future<void>.delayed(Duration.zero);

            expect(announced, [isNull], reason: 'the jump must be known while the backend is still working');

            releaseCommand.complete();
            await pending;
            await Future<void>.delayed(Duration.zero);
            // This backend never answers the `time-pos` read, so nothing is
            // published: a guessed position would be worse than none.
            expect(announced, hasLength(1), reason: 'a failed read-back must not fabricate a destination');
          } finally {
            if (!releaseCommand.isCompleted) releaseCommand.complete();
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });
  });
}
