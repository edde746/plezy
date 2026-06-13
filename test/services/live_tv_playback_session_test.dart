import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/models/plex/plex_config.dart';
import 'package:vibe_stream/services/jellyfin_client.dart';
import 'package:vibe_stream/services/plex_api_cache.dart';
import 'package:vibe_stream/services/plex_client.dart';

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
                    {'beginsAt': '1700000000'},
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

    PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) => PlexClient.forTesting(
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
        if (request.url.path.endsWith('/tune')) return jsonResponse(tuneResponse());
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

    test('streamUrlAt builds live-edge and offset URLs against one transcode session', () async {
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) return jsonResponse(tuneResponse());
        if (request.url.path == '/video/:/transcode/universal/decision') return http.Response('ok', 200);
        return jsonResponse(const {});
      });
      addTearDown(client.close);

      final session = (await client.liveTv.startPlayback('ch-1', dvrKey: 'dvr-1'))!;

      final liveEdge = await session.streamUrlAt();
      final shifted = await session.streamUrlAt(offsetSeconds: 90);

      expect(liveEdge, isNotNull);
      final liveEdgeUri = Uri.parse(liveEdge!);
      expect(liveEdgeUri.path, '/video/:/transcode/universal/start');
      expect(liveEdgeUri.queryParameters['path'], '/livetv/sessions/session-abc');
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
        if (request.url.path.endsWith('/tune')) return jsonResponse(tuneResponse());
        if (request.url.path == '/:/timeline') {
          timelineQuery = request.url.queryParameters;
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
      // Position past the program duration — Plex 400s when time > duration
      // (Tunarr-style short synthetic programs), so duration must grow.
      final updated = await session.reportTimeline(state: 'playing', positionMs: 2000000, durationMs: 1800000);

      expect(timelineQuery!['ratingKey'], 'prog-1');
      expect(timelineQuery!['key'], '/livetv/sessions/session-abc');
      expect(timelineQuery!['state'], 'playing');
      expect(timelineQuery!['time'], '2000000');
      expect(timelineQuery!['duration'], '2000000');
      expect(updated, isNotNull);
      expect(updated!.seekableDurationSeconds, 300);
    });

    test('recover re-tunes and the fresh session builds degraded URLs', () async {
      var tunes = 0;
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          tunes++;
          return jsonResponse(tuneResponse());
        }
        if (request.url.path == '/video/:/transcode/universal/decision') return http.Response('ok', 200);
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

    test('startPlayback negotiates one direct URL; no time-shift; recover reuses it', () async {
      final client = JellyfinClient.forTesting(
        connection: conn(),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('PlaybackInfo')) {
            return jsonResponse({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {'Id': 'source-1', 'Container': 'ts', 'LiveStreamId': 'live-1'},
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

      final url = await session.streamUrlAt();
      expect(url, isNotNull);
      expect(Uri.parse(url!).path, contains('/Videos/channel-1'));
      expect(Uri.parse(url).queryParameters['PlaySessionId'], 'play-1');

      // Time-shift unsupported — an offset request must not silently play live.
      expect(await session.streamUrlAt(offsetSeconds: 60), isNull);

      // Session-less URL: recovery is just re-opening it.
      expect(await session.recover(directStream: false, directStreamAudio: false), same(session));
    });
  });
}
