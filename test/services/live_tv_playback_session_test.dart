import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import '../test_helpers/backend_client_fixtures.dart';

/// Pins the [LiveTvPlaybackSession] lifecycle on both backends — the
/// per-backend protocol that used to be hand-rolled (3×) inside the player's
/// live methods: tune → lazy stream URL, time-shift offsets reusing the
/// transcode session, the Tunarr duration-grow guard on heartbeats, and
/// recover-with-degradation.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  http.Response jsonResponse(Map<String, dynamic> body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  group('Plex live playback session', () {
    Map<String, dynamic> tuneResponse() => {
      'MediaContainer': {
        'MediaSubscription': [
          {
            'MediaGrabOperation': [
              {
                'Metadata': {
                  'ratingKey': 'prog-1',
                  'key': '/livetv/sessions/session-abc',
                  'type': 'clip',
                  'duration': 1800000,
                  'Media': [
                    {
                      'beginsAt': '1700000000',
                      'Part': [
                        {
                          'id': '42',
                          'Stream': [
                            {'id': '90', 'streamType': 1, 'codec': 'h264'},
                            {'id': '91', 'streamType': 2, 'codec': 'ac3', 'languageCode': 'mul'},
                            {
                              'id': '92',
                              'streamType': 3,
                              'codec': 'dvb_subtitle',
                              'language': 'Finnish',
                              'languageCode': 'fin',
                            },
                            {
                              'id': '93',
                              'streamType': 3,
                              'codec': 'eia_608',
                              'language': 'English',
                              'languageCode': 'eng',
                            },
                            {
                              'id': '94',
                              'streamType': 3,
                              'codec': 'srt',
                              'key': '/library/streams/94',
                              'languageCode': 'eng',
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
              },
            ],
          },
        ],
        'TranscodeSession': [
          {'timeStamp': '1700000100', 'minOffsetAvailable': '0', 'maxOffsetAvailable': '120'},
        ],
      },
    };

    PlexClient makeClient(
      Future<http.Response> Function(http.Request request) handler, {
      List<String>? prioritizedEndpoints,
    }) => testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'tok',
        clientIdentifier: 'client',
        product: 'Plezy',
        version: '1',
        machineIdentifier: 'machine-1',
      ),
      serverId: ServerId('machine-1'),
      httpClient: MockClient(handler),
      prioritizedEndpoints: prioritizedEndpoints,
    );

    test('startPlayback without a dvrKey returns null (tune requires a DVR)', () async {
      final client = makeClient((request) async => fail('no request expected'));
      addTearDown(client.close);

      expect(await client.liveTv.startPlayback('ch-1'), isNull);
    });

    test('startPlayback tunes and exposes program + capture buffer; URL is built lazily', () async {
      final requests = <String>[];
      final client = makeClient((request) async {
        requests.add(request.url.path);
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1');

      expect(session, isNotNull);
      expect(session!.program.id, 'prog-1');
      expect(session.program.durationMs, 1800000);
      expect(session.program.beginsAt, 1700000000);
      expect(session.captureBuffer, isNotNull);
      expect(session.canTimeShift, isTrue);
      // Tune only — no transcode decision until the caller asks for a URL
      // (a watch-from-start dialog sits between the two).
      expect(requests, ['/livetv/dvrs/dvr-1/channels/ch-1/tune']);
    });

    test('tune exposes only embedded bitmap subtitle streams as burn targets', () async {
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;

      // The DVB bitmap stream is listed (issue #1983); the in-band CEA
      // caption and the external sidecar are deliberately not — captions ride
      // the copied video bitstream (issue #1590) and a sidecar cannot be
      // burned.
      expect(session.subtitleTracks, hasLength(1));
      final track = session.subtitleTracks.single;
      expect(track.id, 92);
      expect(track.codec, 'dvb_subtitle');
      expect(track.languageCode, 'fin');
    });

    test('streamUrlAt with a subtitle track selects it on the tuned part and asks for a burn', () async {
      final requests = <http.Request>[];
      final client = makeClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.method == 'PUT' && request.url.path == '/library/parts/42') {
          return jsonResponse(const {});
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;
      final track = session.subtitleTracks.single;

      final burning = await session.streamUrlAt(subtitleTrack: track);
      final burningUri = Uri.parse(burning!);
      expect(burningUri.queryParameters['subtitles'], 'burn');
      // The burned stream comes from the part's server-side selection, not a
      // `subtitleStreamID` param the transcoder would ignore.
      expect(burningUri.queryParameters.containsKey('subtitleStreamID'), isFalse);

      Iterable<http.Request> selections() =>
          requests.where((request) => request.method == 'PUT' && request.url.path == '/library/parts/42');
      expect(selections(), hasLength(1));
      expect(selections().single.url.queryParameters['subtitleStreamID'], '92');

      final decision = requests.singleWhere((request) => request.url.path == '/video/:/transcode/universal/decision');
      expect(decision.url.queryParameters['subtitles'], 'burn');

      // A time-shift rebuild of the same track keeps the burn without a
      // redundant selection round-trip.
      final shifted = await session.streamUrlAt(offsetSeconds: 30, subtitleTrack: track);
      expect(Uri.parse(shifted!).queryParameters['subtitles'], 'burn');
      expect(selections(), hasLength(1));

      // Dropping the track goes back to `none` (issue #1590's contract).
      final off = await session.streamUrlAt();
      expect(Uri.parse(off!).queryParameters['subtitles'], 'none');
    });

    test('streamUrlAt returns null when the server refuses the burn selection', () async {
      final decisions = <http.Request>[];
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.method == 'PUT' && request.url.path == '/library/parts/42') {
          return http.Response('{}', 500, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          decisions.add(request);
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;

      // Burning against an unconfirmed selection would weld whatever the
      // server had stored into the picture — no URL is the safe answer.
      expect(await session.streamUrlAt(subtitleTrack: session.subtitleTracks.single), isNull);
      expect(decisions, isEmpty);

      // The session stays usable without subtitles.
      final plain = await session.streamUrlAt();
      expect(Uri.parse(plain!).queryParameters['subtitles'], 'none');
    });

    test('streamUrlAt builds live-edge and offset HLS URLs against one transcode session', () async {
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;

      final liveEdge = await session.streamUrlAt();
      final shifted = await session.streamUrlAt(offsetSeconds: 90);

      expect(liveEdge, isNotNull);
      final liveEdgeUri = Uri.parse(liveEdge!);
      expect(liveEdgeUri.path, '/video/:/transcode/universal/start.m3u8');
      expect(liveEdgeUri.queryParameters['path'], '/livetv/sessions/session-abc');
      expect(liveEdgeUri.queryParameters['protocol'], 'hls');
      expect(liveEdgeUri.queryParameters['X-Plex-Incomplete-Segments'], '1');
      expect(liveEdgeUri.queryParameters.containsKey('X-Plex-Chunked'), isFalse);
      // Live TV deliberately keeps the TS target with the broadcast codecs:
      // live sessions copy hevc/mpeg2video channels, unlike the VOD target
      // which moved to fMP4 (issue #1859).
      expect(liveEdgeUri.queryParameters['X-Plex-Client-Profile-Extra'], contains('protocol=hls&container=mpegts'));
      expect(
        liveEdgeUri.queryParameters['X-Plex-Client-Profile-Extra'],
        contains('videoCodec=h264%2Chevc%2Cmpeg2video'),
      );
      expect(liveEdgeUri.queryParameters['subtitles'], 'none');
      expect(liveEdgeUri.queryParameters.containsKey('subtitleStreamID'), isFalse);
      expect(liveEdgeUri.queryParameters.containsKey('advancedSubtitles'), isFalse);
      expect(liveEdgeUri.queryParameters['X-Plex-Token'], 'tok');
      expect(liveEdgeUri.queryParameters.containsKey('offset'), isFalse);

      final shiftedUri = Uri.parse(shifted!);
      expect(shiftedUri.queryParameters['offset'], '90');
      // Same transcode session across rebuilds so the server reuses its
      // capture buffer.
      expect(shiftedUri.queryParameters['session'], liveEdgeUri.queryParameters['session']);
    });

    test('reportTimeline targets the tuned program and grows duration to the position', () async {
      Map<String, String>? timelineQuery;
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/:/timeline') {
          timelineQuery = request.url.queryParameters;
          // Once the stream plays, the top-level session is the playback
          // transcode and the capture buffer sits under its wrapper.
          return jsonResponse({
            'MediaContainer': {
              'TranscodeSession': [
                {'timeStamp': '1700000230.5', 'minOffsetAvailable': '0.033', 'maxOffsetAvailable': '12'},
              ],
              'CaptureBuffer': [
                {
                  'TranscodeSession': [
                    {'timeStamp': '1700000100', 'minOffsetAvailable': '0', 'maxOffsetAvailable': '300'},
                  ],
                },
              ],
            },
          });
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;
      // Position past the program duration — Plex 400s when time > duration
      // (Tunarr-style short synthetic programs), so duration must grow.
      final updated = await session.reportTimeline(state: 'playing', positionMs: 2000000, durationMs: 1800000);

      expect(timelineQuery!['ratingKey'], 'prog-1');
      expect(timelineQuery!['key'], '/livetv/sessions/session-abc');
      expect(timelineQuery!['state'], 'playing');
      expect(timelineQuery!['time'], '2000000');
      expect(timelineQuery!['duration'], '2000000');
      expect(updated!.captureBuffer!.seekableDurationSeconds, 300);
      expect(updated.captureBuffer!.startedAt, 1700000100);
      // The playback transcode's origin is the exact clock anchor (#2100);
      // it must not be mistaken for the capture window.
      expect(updated.playbackStream!.startedAt, 1700000230.5);
    });

    test('reportTimeline reads a lone top-level session as the capture buffer', () async {
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/:/timeline') {
          return jsonResponse({
            'MediaContainer': {
              'TranscodeSession': [
                {'timeStamp': '1700000100', 'minOffsetAvailable': '0', 'maxOffsetAvailable': '300'},
              ],
            },
          });
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;
      final updated = await session.reportTimeline(state: 'playing', positionMs: 1000, durationMs: 1800000);

      expect(updated!.captureBuffer!.seekableDurationSeconds, 300);
      expect(updated.playbackStream, isNull);
    });

    test('reportTimeline does not fail over because it keeps the active live session alive', () async {
      final requests = <Uri>[];
      final client = makeClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/:/timeline') {
          throw http.ClientException('temporary timeline DNS failure', request.url);
        }
        return jsonResponse(const {});
      }, prioritizedEndpoints: const ['https://plex.example.com', 'https://fallback.example.com']);
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;

      await expectLater(
        session.reportTimeline(state: 'playing', positionMs: 10000, durationMs: 1800000),
        throwsA(isA<MediaServerHttpException>()),
      );
      expect(requests.where((uri) => uri.path == '/:/timeline'), hasLength(1));
      expect(client.config.baseUrl, 'https://plex.example.com');
    });

    test('recover re-tunes and the fresh session builds degraded URLs', () async {
      var tunes = 0;
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          tunes++;
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;
      final recovered = await session.recover(directStream: false, directStreamAudio: false);

      expect(tunes, 2);
      final url = await recovered!.streamUrlAt();
      final uri = Uri.parse(url!);
      expect(uri.queryParameters['directStream'], '0');
      expect(uri.queryParameters['directStreamAudio'], '0');
    });

    test('Original quality asks for a remux with no ceiling', () async {
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;
      final uri = Uri.parse((await session.streamUrlAt())!);

      // A tuned session is only reachable through the transcoder's HLS
      // output, so "no re-encode" on live is a remux, never direct play.
      expect(uri.queryParameters['directPlay'], '0');
      expect(uri.queryParameters['directStream'], '1');
      expect(uri.queryParameters.containsKey('videoResolution'), isFalse);
      expect(uri.queryParameters.containsKey('videoQuality'), isFalse);
      expect(uri.queryParameters['X-Plex-Client-Profile-Extra'], isNot(contains('add-limitation')));
    });

    test('a capped preset forces an h264 encode at that ceiling and survives recovery', () async {
      final decisions = <Uri>[];
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/video/:/transcode/universal/decision') {
          decisions.add(request.url);
          return http.Response('ok', 200);
        }
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback(
        'ch-1',
        dvrKey: 'dvr-1',
        quality: TranscodeQualityPreset.p720_2mbps,
      ))!;
      final uri = Uri.parse((await session.streamUrlAt())!);

      // Without a client ceiling a remote session lands on the server's own
      // top transcode tier (#2072): the cap must reach both the decision and
      // the start request, as bitrate limitation plus resolution/quality caps.
      expect(uri.queryParameters['directStream'], '0');
      expect(uri.queryParameters['videoResolution'], '1280x720');
      expect(uri.queryParameters['videoQuality'], '60');
      final profile = uri.queryParameters['X-Plex-Client-Profile-Extra']!;
      expect(profile, contains('name=video.bitrate&value=2000'));
      // Every target codec is now an encode output; HEVC into TS is the #1859
      // corruption, so the h264-only TS target replaces the broadcast one.
      expect(profile, contains('container=mpegts&videoCodec=h264&'));
      expect(profile, isNot(contains('hevc')));
      expect(decisions.single.queryParameters['videoResolution'], '1280x720');
      expect(decisions.single.queryParameters['X-Plex-Client-Profile-Extra'], contains('value=2000'));

      // A re-tune keeps the cap; dropping it would reopen the uncapped shape.
      final recovered = await session.recover(directStream: true, directStreamAudio: true);
      final recoveredUri = Uri.parse((await recovered!.streamUrlAt())!);
      expect(recoveredUri.queryParameters['directStream'], '0');
      expect(recoveredUri.queryParameters['X-Plex-Client-Profile-Extra'], contains('value=2000'));
    });
  });

  group('Jellyfin live playback session', () {
    JellyfinConnection conn() => JellyfinConnection(
      id: 'srv-1/user-1',
      baseUrl: 'https://jf.example.com',
      serverName: 'Home',
      serverMachineId: 'srv-1',
      userId: 'user-1',
      userName: 'edde',
      accessToken: 'tok-abc',
      deviceId: 'dev-xyz',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    test('startPlayback negotiates one HLS URL; no time-shift; recover reuses it', () async {
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            return jsonResponse({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {
                  'Id': 'source-1',
                  'Container': 'ts',
                  'LiveStreamId': 'live-1',
                  'TranscodingUrl': '/Videos/channel-1/live.m3u8?PlaySessionId=play-1',
                },
              ],
            });
          }
          return jsonResponse(const {});
        }),
      );
      addTearDown(client.close);

      final session = await client.liveTv.startPlayback('channel-1');

      expect(session, isNotNull);
      expect(session!.program.id, isNull);
      expect(session.captureBuffer, isNull);
      expect(session.canTimeShift, isFalse);
      expect(session.backgroundPolicy, LiveTvBackgroundPolicy.stopAndExit);

      final url = await session.streamUrlAt();
      expect(url, isNotNull);
      expect(Uri.parse(url!).path, '/Videos/channel-1/live.m3u8');
      expect(Uri.parse(url).queryParameters['PlaySessionId'], 'play-1');

      // Time-shift unsupported — an offset request must not silently play live.
      expect(await session.streamUrlAt(offsetSeconds: 60), isNull);

      // Server-side subtitle selection is intentionally unsupported: the one
      // negotiated URL has no rebuild to deliver a selection through.
      expect(session.subtitleTracks, isEmpty);
      final foreignTrack = MediaSubtitleTrack(id: 1, selected: false, forced: false);
      expect(await session.streamUrlAt(subtitleTrack: foreignTrack), isNull);

      // Recovery re-opens the negotiated HLS URL.
      expect(await session.recover(directStream: false, directStreamAudio: false), same(session));
    });

    test('startPlayback propagates status and cancellation failures', () async {
      final handlers = <(String, Future<http.Response> Function(http.Request))>[
        ('401', (_) async => http.Response('{}', 401, headers: {'content-type': 'application/json'})),
        ('500', (_) async => http.Response('{}', 500, headers: {'content-type': 'application/json'})),
        ('cancelled', (request) async => throw http.RequestAbortedException(request.url)),
      ];

      for (final (name, handler) in handlers) {
        final client = JellyfinClient.forTesting(connection: conn(), httpClient: MockClient(handler));
        addTearDown(client.close);
        await expectLater(
          client.liveTv.startPlayback('channel-1'),
          throwsA(isA<MediaServerHttpException>()),
          reason: name,
        );
      }
    });

    test('malformed successful playback data throws distinctly', () async {
      final missingSources = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((_) async => jsonResponse({'PlaySessionId': 'play-1'})),
      );
      addTearDown(missingSources.close);
      await expectLater(
        missingSources.liveTv.startPlayback('channel-1'),
        throwsA(
          isA<MediaServerHttpException>()
              .having((error) => error.statusCode, 'statusCode', 200)
              .having((error) => error.responseData, 'responseData', isNull),
        ),
      );

      final malformedSource = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient(
          (_) async => jsonResponse({
            'MediaSources': ['invalid'],
          }),
        ),
      );
      addTearDown(malformedSource.close);
      await expectLater(
        malformedSource.liveTv.startPlayback('channel-1'),
        throwsA(
          isA<PlaybackException>().having((error) => error.reason, 'reason', PlaybackFailureReason.invalidPlaybackData),
        ),
      );
    });

    test('only a valid empty source list returns no live stream', () async {
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((_) async => jsonResponse({'MediaSources': []})),
      );
      addTearDown(client.close);

      expect(await client.liveTv.startPlayback('channel-1'), isNull);
    });

    test('Original quality direct-plays when the server grants it', () async {
      final negotiations = <http.Request>[];
      final reports = <http.Request>[];
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            negotiations.add(request);
            return jsonResponse({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {'Id': 'source-1', 'Container': 'ts', 'LiveStreamId': 'live-1', 'SupportsDirectPlay': true},
              ],
            });
          }
          if (request.url.path.contains('Sessions/Playing')) reports.add(request);
          return jsonResponse(const {});
        }),
      );
      addTearDown(client.close);

      final session = await client.liveTv.startPlayback('channel-1');

      final body = jsonDecode(negotiations.single.body) as Map<String, dynamic>;
      expect(body['EnableDirectPlay'], isTrue);
      expect(body['EnableDirectStream'], isTrue);
      // Original sends no ceiling: the server assumes 40 Mbps for an unknown
      // live bitrate, so any real cap would silently deny direct play.
      expect(body.containsKey('MaxStreamingBitrate'), isFalse);

      // The server-proxied direct URL jellyfin-web uses (not the raw tuner
      // Path, which needs reachability probing).
      final url = Uri.parse((await session!.streamUrlAt())!);
      expect(url.path, '/Videos/channel-1/stream.ts');
      expect(url.queryParameters['Static'], 'true');
      expect(url.queryParameters['MediaSourceId'], 'source-1');
      expect(url.queryParameters['LiveStreamId'], 'live-1');
      expect(url.queryParameters['api_key'], 'tok-abc');

      // Heartbeats must report DirectPlay so the server accounts the session
      // correctly and can reclaim the live stream on stop.
      await session.reportTimeline(state: 'playing', positionMs: 1000, durationMs: 0);
      final report = jsonDecode(reports.single.body) as Map<String, dynamic>;
      expect(report['PlayMethod'], 'DirectPlay');
      expect(report['LiveStreamId'], 'live-1');
    });

    test('a capped preset forces a transcode at that ceiling', () async {
      final negotiations = <http.Request>[];
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            negotiations.add(request);
            return jsonResponse({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {
                  'Id': 'source-1',
                  'Container': 'ts',
                  'LiveStreamId': 'live-1',
                  'TranscodingUrl': '/Videos/channel-1/live.m3u8?PlaySessionId=play-1',
                },
              ],
            });
          }
          return jsonResponse(const {});
        }),
      );
      addTearDown(client.close);

      final session = await client.liveTv.startPlayback('channel-1', quality: TranscodeQualityPreset.p720_2mbps);

      final body = jsonDecode(negotiations.single.body) as Map<String, dynamic>;
      expect(body['EnableDirectPlay'], isFalse);
      expect(body['EnableDirectStream'], isFalse);
      expect(body['MaxStreamingBitrate'], 2_000_000);
      expect(Uri.parse((await session!.streamUrlAt())!).path, endsWith('.m3u8'));
    });

    test('a negotiation that yields no HLS URL closes the live stream it opened', () async {
      final closes = <http.Request>[];
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            // What a ts-only tuner answers a client with no ts profile: a
            // plain /stream URL instead of an HLS playlist (#2198).
            return jsonResponse({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {'Id': 'source-1', 'LiveStreamId': 'live-1', 'TranscodingUrl': '/Videos/channel-1/stream'},
              ],
            });
          }
          if (request.url.path.contains('LiveStreams/Close')) {
            closes.add(request);
            return http.Response('', 204);
          }
          return jsonResponse(const {});
        }),
      );
      addTearDown(client.close);

      expect(await client.liveTv.startPlayback('channel-1'), isNull);

      // The close is fire-and-forget; drain it. Without it the tuner slot
      // leaks — no playback session exists to ever stop-report the stream.
      await pumpEventQueue();
      expect(closes.single.method, 'POST');
      expect(closes.single.url.queryParameters['liveStreamId'], 'live-1');
    });

    test('recover degrades a direct-play session to a forced transcode and releases its stream', () async {
      final negotiations = <http.Request>[];
      final closes = <http.Request>[];
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            negotiations.add(request);
            if (negotiations.length == 1) {
              return jsonResponse({
                'PlaySessionId': 'play-1',
                'MediaSources': [
                  {'Id': 'source-1', 'Container': 'ts', 'LiveStreamId': 'live-1', 'SupportsDirectPlay': true},
                ],
              });
            }
            return jsonResponse({
              'PlaySessionId': 'play-2',
              'MediaSources': [
                {
                  'Id': 'source-1',
                  'Container': 'ts',
                  'LiveStreamId': 'live-2',
                  'TranscodingUrl': '/Videos/channel-1/live.m3u8?PlaySessionId=play-2',
                },
              ],
            });
          }
          if (request.url.path.contains('LiveStreams/Close')) {
            closes.add(request);
            return http.Response('', 204);
          }
          return jsonResponse(const {});
        }),
      );
      addTearDown(client.close);

      final session = await client.liveTv.startPlayback('channel-1');
      final recovered = await session!.recover(directStream: false, directStreamAudio: true);

      expect(recovered, isNotNull);
      expect(recovered, isNot(same(session)));
      expect(Uri.parse((await recovered!.streamUrlAt())!).path, endsWith('.m3u8'));

      // The re-negotiation must not ask for direct play again…
      final retryBody = jsonDecode(negotiations[1].body) as Map<String, dynamic>;
      expect(retryBody['EnableDirectPlay'], isFalse);
      expect(retryBody['EnableDirectStream'], isFalse);

      // …and the replaced direct session's live stream is released: the
      // player adopts the replacement without ever stop-reporting the old one.
      await pumpEventQueue();
      expect(closes.single.url.queryParameters['liveStreamId'], 'live-1');

      // A transcode session keeps the documented re-open-the-URL behavior.
      expect(await recovered.recover(directStream: false, directStreamAudio: false), same(recovered));
    });
  });
}
