import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
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
    test('MPV restores the outgoing file when loadfile is rejected', () async {
      // mpv keeps the outgoing file loaded when `loadfile` fails, so every
      // per-file fact open() tore down before dispatching still describes the
      // file on screen and has to come back — the rendered frame is what a
      // Watch Together rebind reads for readiness, and a paused file emits no
      // further playback-restart to re-establish it.
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          if (call.method == 'initialize') return Future.value(true);
          if (call.method == 'command' && (call.arguments as Map)['args'][0] == 'loadfile') {
            throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
          }
          return Future.value(null);
        },
        testBody: () async {
          final player = _TestPlayerNative();
          final announced = <Duration?>[];
          final subscription = player.streams.playheadJump.listen(announced.add);
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
            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 188.0});
            player.handlePropertyChange('time-pos', 188.0);
            player.handlePropertyChange('duration', 439.968);
            player.handlePropertyChange('seekable', true);
            expect(player.state.hasRenderedFrame, isTrue);

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
            await Future<void>.delayed(Duration.zero);

            expect(player.state.hasRenderedFrame, isTrue);
            expect(player.state.position, const Duration(seconds: 188));
            expect(player.currentPosition, const Duration(seconds: 188));
            expect(player.state.duration, const Duration(milliseconds: 439968));
            expect(player.state.seekable, isTrue);
            expect(player.state.tracks.audio.single.title, 'English');
            expect(player.state.tracks.subtitle.single.title, 'English');
            // The abandoned resume target was announced; so is the way back.
            expect(announced, [const Duration(seconds: 12), const Duration(seconds: 188)]);

            // The track-list gate armed for the load that never started is
            // lifted, and the outgoing file's external metadata still applies.
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

            // A later duration report is not overridden by the rejected
            // open's timeline.
            player.handlePropertyChange('duration', 500.0);
            expect(player.state.duration, const Duration(seconds: 500));
          } finally {
            await subscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('MPV restores the outgoing file when a pre-loadfile command is rejected', () async {
      // The header rebuild runs after the teardown too; a failure there must
      // roll back the same way as a rejected loadfile.
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          if (call.method == 'initialize') return Future.value(true);
          if (call.method == 'command' && (call.arguments as Map)['args'][0] == 'change-list') {
            throw PlatformException(code: 'COMMAND_FAILED', message: 'rejected');
          }
          return Future.value(null);
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            _seedTracks(player);
            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 0.0});
            player.handlePropertyChange('seekable', true);

            await expectLater(player.open(Media('https://example.test/next.mkv')), throwsA(isA<PlatformException>()));

            expect(player.state.hasRenderedFrame, isTrue);
            expect(player.state.seekable, isTrue);
            expect(player.state.tracks.audio.single.title, 'English');
            _seedTracks(player);
            expect(player.state.tracks.subtitle.single.title, 'English');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV keeps the accepted replacement when the post-load unpause is rejected', () async {
      // Once mpv accepts the loadfile the outgoing file is gone; a failure
      // after that point must not resurrect its frame, tracks or playhead.
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          if (call.method == 'initialize') return Future.value(true);
          if (call.method == 'command' && (call.arguments as Map)['args'][0] == 'loadfile') {
            return Future.value({'playlistEntryId': 2});
          }
          if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'pause') {
            throw PlatformException(code: 'SET_PROPERTY_FAILED');
          }
          return Future.value(null);
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            _seedTracks(player);
            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 188.0});
            player.handlePropertyChange('time-pos', 188.0);

            await expectLater(
              player.open(Media('https://example.test/next.mkv', start: const Duration(seconds: 12))),
              throwsA(isA<PlatformException>()),
            );

            expect(player.state.hasRenderedFrame, isFalse);
            expect(player.state.position, const Duration(seconds: 12));
            expect(player.state.tracks.audio, isEmpty);
            // The gate stays armed for the accepted load's start-file.
            _seedTracks(player);
            expect(player.state.tracks.audio, isEmpty);
            player.handlePlayerEvent('start-file', {'sourceId': 2});
            _seedTracks(player);
            expect(player.state.tracks.audio.single.title, 'English');
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

    test('MPV suppresses default subtitle selection per file, never on the outgoing one', () async {
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
            // Stand in for an in-place reload: a file is already playing.
            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePropertyChange('track-list', const [
              {'type': 'sub', 'id': '1', 'title': 'Outgoing', 'lang': 'fre', 'external': false},
            ]);
            expect(player.state.tracks.subtitle, hasLength(1));

            await player.open(Media('https://example.test/next.mkv'));

            // A `sid` property write would deselect the outgoing file's
            // subtitle, and the track-list update that follows re-seeds its
            // tracks over the list this open cleared (#2323).
            expect(_setPropertyCallIndex(calls, 'sid'), -1);
            expect(_setPropertyCallIndex(calls, 'secondary-sid'), -1);
            expect(_loadfileArgs(calls).last, contains('sid=no,secondary-sid=no'));

            // Anything still describing the outgoing file is ignored.
            player.handlePropertyChange('track-list', const [
              {'type': 'sub', 'id': '1', 'title': 'Outgoing', 'lang': 'fre', 'external': false},
            ]);
            expect(player.state.tracks.subtitle, isEmpty);

            player.handlePlayerEvent('start-file', {'sourceId': 2});
            player.handlePropertyChange('track-list', const [
              {'type': 'sub', 'id': '1', 'title': 'Incoming', 'lang': 'eng', 'external': false},
            ]);
            expect(player.state.tracks.subtitle.single.title, 'Incoming');
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV combines server-positioned HLS options with quoted external subtitles', () async {
      final calls = <MethodCall>[];
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          calls.add(call);
          return call.method == 'initialize' ? true : null;
        },
        testBody: () async {
          final player = PlayerNative();
          const uri = 'https://example.test/live.m3u8';
          const subtitle = 'https://example.test/sub.srt?value=a,b';
          try {
            await player.open(
              Media(uri),
              isLive: true,
              startLivePlaylistFromBeginning: true,
              externalSubtitles: const [SubtitleTrack(id: 'external', uri: subtitle)],
            );
            expect(_loadfileArgs(calls), [
              'loadfile',
              uri,
              'replace',
              '-1',
              'sub-files=${_fixedLengthPathList([subtitle])},sid=no,secondary-sid=no,'
                  'demuxer-lavf-o-append=live_start_index=0,cache-pause-initial=yes,cache-pause-wait=6',
            ]);
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
              'sub-files=${_fixedLengthPathList([english, french])},sid=no,secondary-sid=no',
            ]);
            expect(_commandCalls(calls, 'sub-add'), isEmpty);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV keeps backslashes in external subtitle entries verbatim', () async {
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
              Media('https://example.test/movie.mkv'),
              externalSubtitles: const [
                SubtitleTrack(id: 'external-a', uri: r'/subs/a\b.srt'),
                SubtitleTrack(id: 'external-c', uri: r'/subs/c\:d;e.srt'),
              ],
            );

            // mpv's path-list splitter drops only a backslash directly before
            // the separator; every other backslash must reach it undoubled.
            expect(_loadfileArgs(calls), [
              'loadfile',
              'https://example.test/movie.mkv',
              'replace',
              '-1',
              Platform.isWindows
                  ? r'sub-files=%31%/subs/a\b.srt;/subs/c\:d\;e.srt,sid=no,secondary-sid=no'
                  : r'sub-files=%31%/subs/a\b.srt:/subs/c\\:d;e.srt,sid=no,secondary-sid=no',
            ]);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV rebuilds HTTP headers with clr first, appends in map order, all before loadfile', () async {
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
            final headers = <String, String>{
              'X-Plex-Token': 'secret',
              'X-Plex-Device': 'Mac17,9',
              'X-Plex-Platform': 'macOS',
              'User-Agent': 'Plezy',
            };
            await player.open(Media('https://example.test/movie.mkv', headers: headers));

            final headerCommandIndices = <int>[];
            for (var i = 0; i < calls.length; i++) {
              final call = calls[i];
              if (call.method != 'command') continue;
              final args = Map<Object?, Object?>.from(call.arguments as Map)['args'] as List;
              if (args.isNotEmpty && args.first == 'change-list') headerCommandIndices.add(i);
            }
            expect(headerCommandIndices, hasLength(1 + headers.length));

            List commandArgs(int index) => Map<Object?, Object?>.from(calls[index].arguments as Map)['args'] as List;

            // clr is dispatched before any append: the commands are pipelined
            // without intermediate awaits, so channel-FIFO order is the only
            // thing keeping a previous open's headers from leaking through.
            expect(commandArgs(headerCommandIndices.first), ['change-list', 'http-header-fields', 'clr', '']);

            // Appends arrive in header-map order.
            expect(
              headerCommandIndices.skip(1).map(commandArgs).toList(),
              headers.entries
                  .map((entry) => ['change-list', 'http-header-fields', 'append', '${entry.key}: ${entry.value}'])
                  .toList(),
            );

            // Every header command lands before loadfile.
            final loadIndex = _loadfileCallIndex(calls);
            expect(loadIndex, greaterThanOrEqualTo(0));
            expect(headerCommandIndices.last, lessThan(loadIndex));
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
              'sub-files=${_fixedLengthPathList([subtitleUri])},sid=no,secondary-sid=no',
            ]);

            player.handlePlayerEvent('start-file', null);
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

            player.handlePlayerEvent('start-file', null);
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

    test('MPV open resolves with the playlist entry id the loadfile reply names', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          switch (call.method) {
            case 'initialize':
              return Future.value(true);
            case 'command':
              final args = Map<Object?, Object?>.from(call.arguments as Map)['args'] as List;
              return Future.value(args.first == 'loadfile' ? {'playlistEntryId': 17} : null);
            default:
              return Future.value(null);
          }
        },
        testBody: () async {
          final player = PlayerNative();
          try {
            expect(await player.open(Media('https://example.test/live.m3u8'), isLive: true), 17);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV open resolves null when the core does not name the source', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            expect(await player.open(Media('https://example.test/live.m3u8'), isLive: true), isNull);
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('MPV source readiness carries the first rendered non-zero clock position once', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          final started = <PlayerSourceStarted>[];
          final ready = <PlayerSourceReady>[];
          final startedSubscription = player.streams.sourceStarted.listen(started.add);
          final readySubscription = player.streams.sourceReady.listen(ready.add);
          try {
            player.handlePlayerEvent('start-file', {'sourceId': 17});
            player.handlePlayerEvent('playback-restart', {'sourceId': 17, 'positionSeconds': 47.25});
            player.handlePlayerEvent('playback-restart', {'sourceId': 17, 'positionSeconds': 52.0});
            await Future<void>.delayed(Duration.zero);

            expect(started.single.sourceId, 17);
            expect(ready, hasLength(1));
            expect(ready.single.sourceId, 17);
            expect(ready.single.position, const Duration(milliseconds: 47250));
            expect(player.currentPosition, const Duration(milliseconds: 47250));
          } finally {
            await startedSubscription.cancel();
            await readySubscription.cancel();
            await player.dispose();
          }
        },
      );
    });

    test('MPV ignores delayed positions from a replaced source', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            player.handlePlayerEvent('start-file', {'sourceId': 17});
            player.handlePropertyChange('time-pos', 47.0, sourceId: 17);
            expect(player.currentPosition, const Duration(seconds: 47));

            player.handlePlayerEvent('start-file', {'sourceId': 18});
            player.handlePropertyChange('time-pos', 99.0, sourceId: 17);
            expect(player.currentPosition, const Duration(seconds: 47));

            player.handlePropertyChange('time-pos', 5.0, sourceId: 18);
            expect(player.currentPosition, const Duration(seconds: 5));
          } finally {
            await player.dispose();
          }
        },
      );
    });

    test('state records whether the current file has rendered a frame', () async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final player = PlayerNative();
          try {
            expect(player.state.hasRenderedFrame, isFalse);
            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePlayerEvent('file-loaded', {'sourceId': 1});
            expect(player.state.hasRenderedFrame, isFalse);
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 0.0});
            expect(player.state.hasRenderedFrame, isTrue);

            // A seek's restart and end of file leave the fact in place.
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 30.0});
            player.handlePlayerEvent('end-file', {'sourceId': 1, 'reason': 0});
            expect(player.state.hasRenderedFrame, isTrue);

            // A new file starts with nothing rendered; a replaced source's late
            // restart cannot claim the new one's frame.
            player.handlePlayerEvent('start-file', {'sourceId': 2});
            expect(player.state.hasRenderedFrame, isFalse);
            player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 31.0});
            expect(player.state.hasRenderedFrame, isFalse);
            player.handlePlayerEvent('playback-restart', {'sourceId': 2, 'positionSeconds': 0.0});
            expect(player.state.hasRenderedFrame, isTrue);

            // file-loaded is a file boundary too: the loaded file has not
            // rendered anything yet.
            player.handlePlayerEvent('file-loaded', {'sourceId': 2});
            expect(player.state.hasRenderedFrame, isFalse);

            // open() resolves before the backend's start-file: the fact is
            // already the new file's by then, not the outgoing file's.
            player.handlePlayerEvent('playback-restart', {'sourceId': 2, 'positionSeconds': 1.0});
            expect(player.state.hasRenderedFrame, isTrue);
            await player.open(Media('https://example.test/next.mkv'));
            expect(player.state.hasRenderedFrame, isFalse);
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

    test('MPV lays one file of a stacked item onto the item timeline', () async {
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
            // Part 2 of a 50 + 40 minute item, resumed five minutes into it.
            const partStart = Duration(minutes: 50);
            await player.open(
              Media('https://example.test/part2.mkv', start: const Duration(minutes: 55)),
              timelineDuration: const Duration(minutes: 90),
              timelineOffset: partStart,
            );

            // The file starts on its own clock; everything reported is item time.
            expect(_setPropertyValue(calls[_setPropertyCallIndex(calls, 'start')]), '300.0');
            expect(player.state.position, const Duration(minutes: 55));
            expect(player.state.duration, const Duration(minutes: 90));

            player.handlePlayerEvent('start-file', {'sourceId': 1});
            player.handlePropertyChange('duration', 2400.0);
            player.handlePropertyChange('time-pos', 310.0, sourceId: 1);
            expect(player.currentPosition, const Duration(minutes: 55, seconds: 10));
            expect(player.state.duration, const Duration(minutes: 90));

            player.handlePropertyChange('demuxer-cache-state', {
              'cache-end': 400.0,
              'seekable-ranges': [
                {'start': 300.0, 'end': 400.0},
              ],
            });
            expect(player.state.buffer, const Duration(minutes: 56, seconds: 40));
            expect(player.state.bufferRanges, [
              const BufferRange(start: Duration(minutes: 55), end: Duration(minutes: 56, seconds: 40)),
            ]);

            await player.seek(const Duration(minutes: 60));
            final seekCall = calls.lastWhere((call) => call.method == 'command');
            final args = Map<Object?, Object?>.from(seekCall.arguments as Map)['args'] as List;
            expect(args, ['seek', '600.0', 'absolute']);
            expect(player.state.position, const Duration(minutes: 60));

            // The next single-file open is back on its own clock.
            await player.open(Media('https://example.test/other.mkv', start: const Duration(minutes: 2)));
            player.handlePlayerEvent('start-file', {'sourceId': 2});
            player.handlePropertyChange('time-pos', 121.0, sourceId: 2);
            expect(player.currentPosition, const Duration(minutes: 2, seconds: 1));
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

class _TestPlayerNative extends PlayerNative {
  void seedExternalSubtitleMetadata(List<SubtitleTrack> subtitles) {
    setExternalSubtitleMetadata(subtitles);
  }
}

void _seedTracks(PlayerNative player) {
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

String _escapePathListEntry(String value, String separator) => value.replaceAll(separator, '\\$separator');
