import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
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

  group('player open', () {
    test('ExoPlayer clears stale Dart track state before opening new media', () async {
      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

    test('ExoPlayer backend switch clears stale tracks before fallback tracks arrive', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        testBody: () async {
          final player = PlayerAndroid();
          try {
            _seedTracks(player);
            expect(player.state.tracks.audio, isNotEmpty);
            expect(player.needsDecoderRefreshAfterDisplaySwitch, isFalse);

            player.handlePlayerEvent('backend-switched', null);

            expect(player.needsDecoderRefreshAfterDisplaySwitch, isTrue);
            expect(player.state.tracks.audio, isEmpty);
            expect(player.state.tracks.subtitle, isEmpty);

            player.handlePropertyChange('track-list', const [
              {'type': 'audio', 'id': '1', 'title': 'Fallback Audio', 'lang': 'eng'},
              {'type': 'sub', 'id': '2', 'title': 'Fallback Subtitle', 'lang': 'eng'},
            ]);

            expect(player.state.tracks.audio.single.id, '1');
            expect(player.state.tracks.subtitle.single.id, '2');

            player.handlePlayerEvent('backend-switched', null);

            expect(player.state.tracks.audio.single.id, '1');
            expect(player.state.tracks.subtitle.single.id, '2');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer applies DV conversion mode changed during in-flight initialization', () async {
      final initialize = Completer<bool>();
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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
            expect(openArgs['hasStartPosition'], isFalse);

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

    test('ExoPlayer source-offset open keeps timeline offset after stale native zero position', () async {
      final calls = <MethodCall>[];
      late PlayerAndroid player;

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            case 'open':
              player.handlePropertyChange('time-pos', 0.0);
              player.handlePropertyChange('duration', 0.0);
              player.handlePropertyChange('demuxer-cache-time', 0.0);
              return Future.value(null);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          player = PlayerAndroid();
          try {
            const timelineStart = Duration(seconds: 2058);
            const timelineDuration = Duration(seconds: 2903);
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
            expect(openArgs['hasStartPosition'], isFalse);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer marks explicit non-zero media starts for native fallback', () async {
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
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
            await player.open(Media('https://example.test/movie.mkv', start: const Duration(seconds: 12)));

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final openArgs = Map<Object?, Object?>.from(openCall.arguments as Map);
            expect(openArgs['startPositionMs'], 12000);
            expect(openArgs['hasStartPosition'], isTrue);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV clears stale Dart track state before opening new media', () async {
      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

    test('MPV passes external subtitles through loadfile options', () async {
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
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
            expect(player.attachesExternalSubtitlesAtOpen, isTrue);
            const english = 'https://example.test/library/parts/1/subtitle.srt?token=a,b:c';
            const french = 'https://example.test/subtitles/fr forced.ass';

            await player.open(
              Media('https://example.test/movie.mkv'),
              externalSubtitles: const [
                SubtitleTrack(id: 'external-en', uri: english, title: 'English', language: 'eng', codec: 'srt'),
                SubtitleTrack(id: 'external-fr', uri: french, title: 'French Forced', language: 'fra', codec: 'ass'),
              ],
            );

            expect(_loadfileArgs(calls), [
              'loadfile',
              'https://example.test/movie.mkv',
              'replace',
              '-1',
              'sub-files=${_fixedLengthPathList([english, french])}',
            ]);
            expect(_commandCalls(calls, 'sub-add'), isEmpty);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV preserves external subtitle metadata for loadfile sidecars', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            const subtitleUri = 'https://example.test/subtitles/en-forced.srt';
            await player.open(
              Media('https://example.test/movie.mkv'),
              externalSubtitles: const [
                SubtitleTrack(
                  id: 'server-subtitle',
                  uri: subtitleUri,
                  title: 'English Forced',
                  language: 'eng',
                  codec: 'srt',
                  isDefault: true,
                  isForced: true,
                  isExternal: true,
                ),
              ],
            );

            player.handlePropertyChange('track-list', const [
              {'type': 'sub', 'id': '1', 'codec': 'subrip', 'external': true, 'external-filename': subtitleUri},
            ]);

            final subtitle = player.state.tracks.subtitle.single;
            expect(subtitle.title, 'English Forced');
            expect(subtitle.language, 'eng');
            expect(subtitle.codec, 'srt');
            expect(subtitle.isDefault, isTrue);
            expect(subtitle.isForced, isTrue);
            expect(subtitle.uri, subtitleUri);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV open(play: true) unpauses after loadfile even when previously paused', () async {
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

    test('MPV exposes file-loaded events through PlayerStreams', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            final fileLoaded = expectLater(player.streams.fileLoaded, emits(isNull));

            player.handlePlayerEvent('file-loaded', null);

            await fileLoaded;
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV maps server-offset streams to absolute timeline positions', () async {
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

      await withMockPlayerChannels(
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

List _loadfileArgs(List<MethodCall> calls) {
  final loadIndex = _loadfileCallIndex(calls);
  expect(loadIndex, greaterThanOrEqualTo(0));
  return Map<Object?, Object?>.from(calls[loadIndex].arguments as Map)['args'] as List;
}

Iterable<MethodCall> _commandCalls(List<MethodCall> calls, String command) {
  return calls.where((call) {
    if (call.method != 'command') return false;
    final args = Map<Object?, Object?>.from(call.arguments as Map)['args'] as List;
    return args.isNotEmpty && args.first == command;
  });
}

String _fixedLengthPathList(List<String> values) {
  final separator = Platform.isWindows ? ';' : ':';
  final escaped = values.map((value) => _escapePathListEntry(value, separator)).join(separator);
  return '%${utf8.encode(escaped).length}%$escaped';
}

String _escapePathListEntry(String value, String separator) {
  return value.replaceAll(r'\', r'\\').replaceAll(separator, '\\$separator');
}
