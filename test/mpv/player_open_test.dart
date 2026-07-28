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

    test('ExoPlayer clears stale timeline state before dispatching a new open', () async {
      late PlayerAndroid player;
      Duration? positionAtNativeOpen;
      Duration? durationAtNativeOpen;

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            case 'open':
              positionAtNativeOpen = player.state.position;
              durationAtNativeOpen = player.state.duration;
              return Future.value(null);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          player = PlayerAndroid();
          try {
            player.handlePropertyChange('time-pos', 188.0);
            player.handlePropertyChange('duration', 439.968);

            await player.open(Media('https://example.test/next.mkv'));

            expect(positionAtNativeOpen, Duration.zero);
            expect(durationAtNativeOpen, Duration.zero);

            player.handlePropertyChange('duration', 401.0);
            expect(player.state.duration, const Duration(seconds: 401));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer restores the previous timeline when native open is rejected', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          if (call.method == 'initialize') return Future.value(true);
          if (call.method == 'open') {
            throw PlatformException(code: 'OPEN_FAILED', message: 'rejected');
          }
          return Future.value(null);
        },
        testBody: () async {
          final player = _TestPlayerAndroid();
          try {
            _seedTracks(player);
            player.seedExternalSubtitleMetadata(const [
              SubtitleTrack(
                id: 'old-external',
                title: 'Old sidecar',
                language: 'eng',
                codec: 'srt',
                isDefault: false,
                isForced: true,
                isExternal: true,
                uri: 'https://example.test/old.srt',
              ),
            ]);
            player.handlePropertyChange('time-pos', 188.0);
            player.handlePropertyChange('duration', 439.968);

            await expectLater(
              player.open(
                Media('https://example.test/rejected.mkv', start: const Duration(seconds: 12)),
                timelineDuration: const Duration(seconds: 401),
                externalSubtitles: const [
                  SubtitleTrack(
                    id: 'rejected-external',
                    title: 'Rejected sidecar',
                    language: 'spa',
                    codec: 'ass',
                    isDefault: false,
                    isForced: false,
                    isExternal: true,
                    uri: 'https://example.test/rejected.ass',
                  ),
                ],
              ),
              throwsA(isA<PlatformException>()),
            );

            expect(player.state.position, const Duration(seconds: 188));
            expect(player.state.duration, const Duration(milliseconds: 439968));
            expect(player.state.tracks.audio.single.title, 'English');
            expect(player.state.tracks.subtitle.single.title, 'English');

            player.handlePropertyChange('track-list', const [
              {
                'type': 'sub',
                'id': 'restored-external',
                'external': true,
                'external-filename': 'https://example.test/old.srt',
                'selected': true,
              },
            ]);
            expect(player.state.tracks.subtitle.single.title, 'Old sidecar');
            expect(player.state.tracks.subtitle.single.isForced, isTrue);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer applies audio settings queued before initialization', () async {
      final calls = <MethodCall>[];
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'requestAudioFocus') return true;
          return null;
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            await player.setAudioNormalization(true);
            await player.setAudioDownmix(enabled: true, centerBoostDb: 4, normalize: false);

            expect(calls.where((call) => call.method == 'setAudioNormalization'), isEmpty);
            expect(calls.where((call) => call.method == 'setAudioDownmix'), isEmpty);

            expect(await player.requestAudioFocus(), isTrue);

            final normalization = calls.singleWhere((call) => call.method == 'setAudioNormalization');
            expect((normalization.arguments as Map)['enabled'], isTrue);
            final downmix = calls.singleWhere((call) => call.method == 'setAudioDownmix');
            expect(downmix.arguments, {'enabled': true, 'centerBoostDb': 4, 'normalize': false});
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer retries initialization after a recoverable native failure', () async {
      var initializeAttempts = 0;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') return ++initializeAttempts > 1;
          if (call.method == 'requestAudioFocus') return true;
          return null;
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            await expectLater(player.requestAudioFocus(), throwsA(isA<Exception>()));
            expect(await player.requestAudioFocus(), isTrue);
            expect(initializeAttempts, 2);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('ExoPlayer initialization cannot commit after disposal starts', () async {
      final initialize = Completer<bool>();
      final calls = <MethodCall>[];
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          if (call.method == 'initialize') return initialize.future;
          return Future.value(null);
        },
        testBody: () async {
          final player = PlayerAndroid();
          final initialization = player.requestAudioFocus();
          final initializationFailure = expectLater(initialization, throwsA(isA<StateError>()));
          await Future<void>.delayed(Duration.zero);

          final disposal = player.dispose();
          initialize.complete(true);
          await initializationFailure;
          await disposal;

          expect(calls.where((call) => call.method == 'observeProperty'), isEmpty);
          expect(calls.where((call) => call.method == 'requestAudioFocus'), isEmpty);
          expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        },
      );
    });

    test('ExoPlayer forwards complete container metadata and rejects empty sidecar URIs', () async {
      final calls = <MethodCall>[];

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/exo_player',
        eventChannelName: 'com.plezy/exo_player/events',
        methodHandler: (call) {
          calls.add(call);
          return call.method == 'initialize' ? Future.value(true) : Future.value(null);
        },
        testBody: () async {
          final player = PlayerAndroid();
          try {
            const containerUri = 'https://example.test/movie.mkv';
            await player.open(
              Media('https://example.test/transcode.m3u8'),
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
                SubtitleTrack(
                  id: 'container:1',
                  title: 'English Dialogue',
                  language: 'eng',
                  codec: 'ass',
                  isDefault: true,
                  isExternal: true,
                  isContainer: true,
                  uri: containerUri,
                ),
                SubtitleTrack(
                  id: 'container:2',
                  title: 'English Signs',
                  language: 'eng',
                  codec: 'ass',
                  isForced: true,
                  isExternal: true,
                  isContainer: true,
                  uri: containerUri,
                ),
                SubtitleTrack(id: 'invalid', uri: '', isExternal: true, isContainer: true),
              ],
            );

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final args = Map<Object?, Object?>.from(openCall.arguments as Map);
            final external = (args['externalSubtitles'] as List)
                .map((entry) => Map<Object?, Object?>.from(entry as Map))
                .toList();

            expect(external, hasLength(3));
            expect(external.first['uri'], 'https://example.test/sub.srt');
            expect(external.first['title'], 'English Forced');
            expect(external.first['isDefault'], isTrue);
            expect(external.first['isForced'], isTrue);
            expect(external.skip(1).map((entry) => entry['uri']).toSet(), {containerUri});
            expect(external.skip(1).map((entry) => entry['title']), ['English Dialogue', 'English Signs']);
            expect(external.skip(1).every((entry) => entry['isContainer'] == true), isTrue);
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

    test('ExoPlayer opens HLS transcodes at native timeline positions', () async {
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
              Media('https://example.test/start.m3u8', start: timelineStart),
              timelineDuration: timelineDuration,
            );

            expect(player.state.position, timelineStart);
            expect(player.state.duration, timelineDuration);

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final openArgs = Map<Object?, Object?>.from(openCall.arguments as Map);
            expect(openArgs['startPositionMs'], timelineStart.inMilliseconds);
            expect(openArgs['hasStartPosition'], isTrue);

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

    test('ExoPlayer HLS open keeps the requested position after stale native zero position', () async {
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
              Media('https://example.test/start.m3u8', start: timelineStart),
              timelineDuration: timelineDuration,
            );

            expect(player.state.position, timelineStart);
            expect(player.state.duration, timelineDuration);

            final openCall = calls.singleWhere((call) => call.method == 'open');
            final openArgs = Map<Object?, Object?>.from(openCall.arguments as Map);
            expect(openArgs['startPositionMs'], timelineStart.inMilliseconds);
            expect(openArgs['hasStartPosition'], isTrue);
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

    test('MPV restores per-stream metadata while loading a shared container once', () async {
      final calls = <MethodCall>[];
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          calls.add(call);
          return call.method == 'initialize' ? Future.value(true) : Future.value(null);
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            const subtitleUri = 'https://example.test/movie.mkv?X-Plex-Token=secret';
            await player.open(
              Media('https://example.test/transcode.m3u8'),
              externalSubtitles: const [
                SubtitleTrack(
                  id: 'container:1',
                  uri: subtitleUri,
                  title: 'English Dialogue',
                  language: 'eng',
                  codec: 'ass',
                  isDefault: true,
                  isExternal: true,
                  isContainer: true,
                ),
                SubtitleTrack(
                  id: 'container:2',
                  uri: subtitleUri,
                  title: 'English Signs',
                  language: 'eng',
                  codec: 'ass',
                  isForced: true,
                  isExternal: true,
                  isContainer: true,
                ),
              ],
            );
            expect(_loadfileArgs(calls), [
              'loadfile',
              'https://example.test/transcode.m3u8',
              'replace',
              '-1',
              'sub-files=${_fixedLengthPathList([subtitleUri])}',
            ]);

            player.handlePropertyChange('track-list', const [
              {'type': 'audio', 'id': 'sidecar-audio', 'external': true, 'external-filename': subtitleUri},
              {
                'type': 'sub',
                'id': '1',
                'title': 'movie.mkv?X-Plex-Token=secret',
                'default': false,
                'forced': false,
                'external': true,
                'external-filename': subtitleUri,
              },
              {
                'type': 'sub',
                'id': '2',
                'title': 'movie.mkv?X-Plex-Token=secret',
                'default': false,
                'forced': false,
                'external': true,
                'external-filename': subtitleUri,
              },
            ]);

            expect(player.state.tracks.audio, isEmpty);
            final subtitles = player.state.tracks.subtitle;
            expect(subtitles, hasLength(2));
            expect(subtitles.map((track) => track.title), ['English Dialogue', 'English Signs']);
            expect(subtitles.map((track) => track.language), ['eng', 'eng']);
            expect(subtitles.map((track) => track.codec), ['ass', 'ass']);
            expect(subtitles.map((track) => track.isDefault), [true, false]);
            expect(subtitles.map((track) => track.isForced), [false, true]);
            expect(subtitles.every((track) => track.uri == subtitleUri && track.isContainer), isTrue);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV keeps native metadata fallbacks for non-container subtitles', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) => call.method == 'initialize' ? Future.value(true) : Future.value(null),
        testBody: () async {
          final player = PlayerNative();
          try {
            const sidecarUri = 'https://example.test/subtitle.srt';
            await player.open(
              Media('https://example.test/movie.mkv'),
              externalSubtitles: const [SubtitleTrack(id: 'external', uri: sidecarUri, isExternal: true)],
            );

            player.handlePropertyChange('track-list', const [
              {
                'type': 'sub',
                'id': 'external',
                'title': 'English Dialogue - SRT',
                'lang': 'eng',
                'codec': 'subrip',
                'external': true,
                'external-filename': sidecarUri,
              },
              {'type': 'sub', 'id': 'embedded', 'title': 'French Dialogue - ASS', 'lang': 'fre', 'codec': 'ass'},
            ]);

            expect(player.state.tracks.subtitle.map((track) => track.title), ['English Dialogue', 'French Dialogue']);
            expect(player.state.tracks.subtitle.map((track) => track.language), ['eng', 'fre']);
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

    test('MPV exposes load-scoped start and terminal failure events', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            final fileStarted = expectLater(player.streams.fileStarted, emits(isNull));
            player.handlePlayerEvent('start-file', null);
            await fileStarted;

            final fileLoadFailed = expectLater(player.streams.fileLoadFailed, emits(isNull));
            player.handlePlayerEvent('end-file', {'reason': 'error'});
            await fileLoadFailed;
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV exposes primary media readiness before external subtitles finish', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          var emissionCount = 0;
          final subscription = player.streams.primaryMediaReady.listen((_) => emissionCount++);
          try {
            player.handlePlayerEvent('start-file', null);
            player.handlePropertyChange('track-list', const [
              {'type': 'sub', 'id': '2', 'external': true},
            ]);
            await Future<void>.delayed(Duration.zero);
            expect(emissionCount, 0);

            player.handlePropertyChange('track-list', const [
              {'type': 'video', 'id': '4', 'external': false, 'image': true, 'albumart': true},
              {'type': 'sub', 'id': '2', 'external': true},
            ]);
            await Future<void>.delayed(Duration.zero);
            expect(emissionCount, 0);

            player.handlePropertyChange('track-list', const [
              {'type': 'video', 'id': '1', 'external': false},
              {'type': 'sub', 'id': '2', 'external': true},
            ]);
            await Future<void>.delayed(Duration.zero);
            expect(emissionCount, 1);

            player.handlePropertyChange('track-list', const [
              {'type': 'video', 'id': '1', 'external': false},
              {'type': 'audio', 'id': '3', 'external': false},
            ]);
            await Future<void>.delayed(Duration.zero);
            expect(emissionCount, 1);
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('MPV opens HLS transcodes at native timeline positions', () async {
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
              Media('https://example.test/start.m3u8', start: const Duration(seconds: 10)),
              timelineDuration: const Duration(seconds: 100),
            );

            expect(player.state.position, const Duration(seconds: 10));
            expect(player.state.duration, const Duration(seconds: 100));

            player.handlePropertyChange('duration', 90.0);
            expect(player.state.duration, const Duration(seconds: 100));

            await player.seek(const Duration(seconds: 25));

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '25.0', 'absolute']);
            expect(player.state.position, const Duration(seconds: 25));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV HLS refresh seek preserves the requested position', () async {
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
              Media('https://example.test/start.m3u8', start: timelineStart),
              timelineDuration: const Duration(seconds: 1502),
            );

            expect(player.state.position, timelineStart);

            await player.seek(timelineStart);

            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '143.894', 'absolute']);
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

class _TestPlayerAndroid extends PlayerAndroid {
  void seedExternalSubtitleMetadata(List<SubtitleTrack> subtitles) {
    setExternalSubtitleMetadata(subtitles);
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
