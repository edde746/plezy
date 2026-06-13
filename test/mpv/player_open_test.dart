import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('player open', () {
    test('ExoPlayer clears stale Dart track state before opening new media', () async {
      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        testBody: () async {
          final player = PlayerAndroid();
          try {
            _seedTracks(player);
            expect(player.state.tracks.audio, isNotEmpty);
            expect(player.state.track.audio, isNotNull);

            await player.open(Media('https://example.test/next.mkv'));

            expect(player.state.tracks.audio, isEmpty);
            expect(player.state.tracks.subtitle, isEmpty);
            expect(player.state.track.audio, isNull);
            expect(player.state.track.subtitle, isNull);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer forwards external subtitle metadata at open', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            await player.open(
              Media('https://example.test/movie.mkv'),
              externalSubtitles: const [
                SubtitleTrack(
                  id: 'external-sub',
                  title: 'English Forced',
                  language: 'eng',
                  codec: 'srt',
                  isDefault: true,
                  isForced: true,
                  isExternal: true,
                  uri: 'https://example.test/sub.srt',
                ),
              ],
            );

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final args = Map<Object?, Object?>.from(openCall.arguments as Map);
            final external = args['externalSubtitles'] as List;
            final subtitle = Map<Object?, Object?>.from(external.single as Map);

            expect(subtitle['uri'], 'https://example.test/sub.srt');
            expect(subtitle['title'], 'English Forced');
            expect(subtitle['language'], 'eng');
            expect(subtitle['codec'], 'srt');
            expect(subtitle['isDefault'], isTrue);
            expect(subtitle['isForced'], isTrue);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer applies DV conversion mode changed during in-flight initialization', () async {
      final initialize = Completer<bool>();
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return initialize.future;
            case 'requestAudioFocus':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            final focusFuture = player.requestAudioFocus();
            await Future<void>.delayed(Duration.zero);

            final modeFuture = player.setProperty('dv-conversion-mode', 'hevc_strip');
            await Future<void>.delayed(Duration.zero);

            final initCall = calls.singleWhere((call) => call.method == 'initialize');
            final initArgs = Map<Object?, Object?>.from(initCall.arguments as Map);
            expect(initArgs['dvConversionMode'], 'auto');
            expect(calls.where((call) => call.method == 'setDvConversionMode'), isEmpty);

            initialize.complete(true);
            await modeFuture;
            await focusFuture;

            final dvCall = calls.singleWhere((call) => call.method == 'setDvConversionMode');
            final dvArgs = Map<Object?, Object?>.from(dvCall.arguments as Map);
            expect(dvArgs['mode'], 'hevc_strip');
          } finally {
            if (!initialize.isCompleted) initialize.complete(true);
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer maps copyts transcode streams as absolute timeline positions', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            const timelineStart = Duration(seconds: 2058); // 34:18
            const timelineDuration = Duration(seconds: 2903); // 48:23
            await player.open(
              Media('https://example.test/transcode.mkv'),
              timelineOffset: timelineStart,
              timelineDuration: timelineDuration,
            );

            expect(player.state.position, timelineStart);
            expect(player.state.duration, timelineDuration);

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final openArgs = Map<Object?, Object?>.from(openCall.arguments as Map);
            expect(openArgs['startPositionMs'], 0);

            await Future<void>.delayed(const Duration(milliseconds: 260));
            player.handlePropertyChange('time-pos', 2058.0);
            expect(player.state.position, timelineStart);

            await player.seek(const Duration(minutes: 40));

            final seekCall = calls.lastWhere((call) => call.method == 'seek');
            final seekArgs = Map<Object?, Object?>.from(seekCall.arguments as Map);
            expect(seekArgs['positionMs'], const Duration(minutes: 40).inMilliseconds);
            expect(player.state.position, const Duration(minutes: 40));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV clears stale Dart track state before opening new media', () async {
      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            _seedTracks(player);
            expect(player.state.tracks.audio, isNotEmpty);
            expect(player.state.track.audio, isNotNull);

            await player.open(Media('https://example.test/next.mkv'));

            expect(player.state.tracks.audio, isEmpty);
            expect(player.state.tracks.subtitle, isEmpty);
            expect(player.state.track.audio, isNull);
            expect(player.state.track.subtitle, isNull);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV disables subtitles before loading media', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            await player.open(Media('https://example.test/next.mkv'));

            final sidIndex = _setPropertyCallIndex(calls, 'sid');
            final secondarySidIndex = _setPropertyCallIndex(calls, 'secondary-sid');
            final loadIndex = _loadfileCallIndex(calls);

            expect(sidIndex, greaterThanOrEqualTo(0));
            expect(secondarySidIndex, greaterThanOrEqualTo(0));
            expect(loadIndex, greaterThanOrEqualTo(0));
            expect(sidIndex, lessThan(loadIndex));
            expect(secondarySidIndex, lessThan(loadIndex));
            expect(_setPropertyValue(calls[sidIndex]), 'no');
            expect(_setPropertyValue(calls[secondarySidIndex]), 'no');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV open(play: true) unpauses after loadfile even when previously paused', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            // Simulate the in-place reload: the old file is paused before the
            // replacement opens. mpv's pause property survives loadfile.
            await player.pause();
            await player.open(Media('https://example.test/next.mkv'));

            final loadIndex = _loadfileCallIndex(calls);
            final unpauseIndex = _setPropertyValueIndex(calls, 'pause', 'no');
            expect(loadIndex, greaterThanOrEqualTo(0));
            expect(unpauseIndex, greaterThan(loadIndex), reason: 'open(play: true) must clear pause after loadfile');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV open(play: false) opens paused and never unpauses', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            await player.open(Media('https://example.test/next.mkv'), play: false);

            final loadIndex = _loadfileCallIndex(calls);
            final pauseIndex = _setPropertyCallIndex(calls, 'pause');
            final unpauseIndex = _setPropertyValueIndex(calls, 'pause', 'no');
            expect(pauseIndex, greaterThanOrEqualTo(0));
            expect(pauseIndex, lessThan(loadIndex));
            expect(_setPropertyValue(calls[pauseIndex]), 'yes');
            expect(unpauseIndex, -1, reason: 'a paused open must stay paused');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV maps server-offset streams to absolute timeline positions', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            await player.open(
              Media('https://example.test/transcode.mkv'),
              timelineOffset: const Duration(seconds: 10),
              timelineDuration: const Duration(seconds: 100),
            );

            expect(player.state.position, const Duration(seconds: 10));
            expect(player.state.duration, const Duration(seconds: 100));

            player.handlePropertyChange('duration', 90.0);
            expect(player.state.duration, const Duration(seconds: 100));

            await player.seek(const Duration(seconds: 25));

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '15.0', 'absolute']);
            expect(player.state.position, const Duration(seconds: 25));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV refresh seek preserves timeline offset position', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            const timelineStart = Duration(milliseconds: 143894);
            await player.open(
              Media('https://example.test/transcode.mkv'),
              timelineOffset: timelineStart,
              timelineDuration: const Duration(seconds: 1502),
            );

            expect(player.state.position, timelineStart);

            await player.seek(timelineStart);

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '0.0', 'absolute']);
            expect(player.state.position, timelineStart);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV forwards preserve display mode flag on dispose', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          return Future.value(null);
        },
        testBody: () async {
          final player = PlayerNative();

          await player.dispose(preserveDisplayMode: true);

          final disposeCall = calls.singleWhere((call) => call.method == 'dispose');
          final args = Map<Object?, Object?>.from(disposeCall.arguments as Map);
          expect(args['preserveDisplayMode'], isTrue);
        },
      );
    });

    test('dispose continues when native event stream cancellation is already detached', () async {
      final calls = <MethodCall>[];

      await _withMockChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          return Future.value(null);
        },
        eventHandler: (call) {
          if (call.method == 'cancel') {
            throw PlatformException(code: 'error', message: 'No active stream to cancel');
          }
          return Future.value(null);
        },
        testBody: () async {
          final player = PlayerNative();
          final playingDone = expectLater(player.streams.playing, emitsDone);

          await expectLater(player.dispose(), completes);
          await playingDone;

          expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        },
      );
    });
  });
}

Future<void> _withMockChannels({
  required String methodChannelName,
  required String eventChannelName,
  Future<Object?> Function(MethodCall call)? methodHandler,
  Future<Object?> Function(MethodCall call)? eventHandler,
  required Future<void> Function() testBody,
}) async {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final methodChannel = MethodChannel(methodChannelName);
  final eventChannel = MethodChannel(eventChannelName);

  messenger.setMockMethodCallHandler(
    methodChannel,
    methodHandler ??
        (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'observeProperty':
            case 'setVisible':
            case 'setProperty':
            case 'command':
            case 'open':
            case 'dispose':
              return null;
            default:
              return null;
          }
        },
  );
  messenger.setMockMethodCallHandler(eventChannel, eventHandler ?? (call) async => null);

  try {
    await testBody();
  } finally {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
  }
}

void _seedTracks(dynamic player) {
  player.handlePropertyChange('track-list', const [
    {'type': 'audio', 'id': '2_0', 'title': 'English', 'lang': 'eng', 'selected': true},
    {'type': 'sub', 'id': '3_0', 'title': 'English', 'lang': 'eng', 'selected': true},
  ]);
}

int _setPropertyCallIndex(List<MethodCall> calls, String name) {
  return calls.indexWhere((call) => call.method == 'setProperty' && _setPropertyName(call) == name);
}

int _setPropertyValueIndex(List<MethodCall> calls, String name, String value) {
  return calls.indexWhere(
    (call) => call.method == 'setProperty' && _setPropertyName(call) == name && _setPropertyValue(call) == value,
  );
}

String? _setPropertyName(MethodCall call) => Map<Object?, Object?>.from(call.arguments as Map)['name'] as String?;

String? _setPropertyValue(MethodCall call) => Map<Object?, Object?>.from(call.arguments as Map)['value'] as String?;

int _loadfileCallIndex(List<MethodCall> calls) {
  return calls.indexWhere((call) {
    if (call.method != 'command') return false;
    final args = Map<Object?, Object?>.from(call.arguments as Map)['args'] as List;
    return args.isNotEmpty && args.first == 'loadfile';
  });
}
