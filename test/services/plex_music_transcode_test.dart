import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/audio_quality_preset.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: ServerId('server-id'), handler: handler);

  test('music transcode params cap bitrate and carry the musicProfile target', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildMusicTranscodeParamsForTesting(
      ratingKey: '9669',
      mediaIndex: 0,
      preset: AudioQualityPreset.medium,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(params['hasMDE'], '1');
    expect(params['path'], '/library/metadata/9669');
    expect(params['mediaIndex'], '0');
    expect(params['partIndex'], '0');
    expect(params['protocol'], 'http');
    expect(params['directPlay'], '0');
    expect(params['directStream'], '0');
    expect(params['musicBitrate'], '192');
    expect(params['session'], 'transcode-id');
    expect(params['X-Plex-Session-Identifier'], 'session-id');
    expect(
      params['X-Plex-Client-Profile-Extra'],
      'add-transcode-target(type=musicProfile&context=streaming'
      '&protocol=http&container=mp3&audioCodec=mp3)',
    );
  });

  test('music transcode params carry no video/subtitle params', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildMusicTranscodeParamsForTesting(
      ratingKey: '9669',
      mediaIndex: 0,
      preset: AudioQualityPreset.high,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(params['musicBitrate'], '320');
    for (final videoOnly in ['subtitles', 'subtitleStreamID', 'advancedSubtitles', 'copyts', 'maxVideoBitrate']) {
      expect(params.containsKey(videoOnly), isFalse, reason: '$videoOnly is video-only');
    }
    expect(params['X-Plex-Client-Profile-Extra'], isNot(contains('videoProfile')));
  });

  test('original preset omits musicBitrate', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildMusicTranscodeParamsForTesting(
      ratingKey: '9669',
      mediaIndex: 0,
      preset: AudioQualityPreset.original,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(params.containsKey('musicBitrate'), isFalse);
  });

  test('music start path uses the mp3 start endpoint without token', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildMusicTranscodeParamsForTesting(
      ratingKey: '9669',
      mediaIndex: 1,
      partIndex: 2,
      preset: AudioQualityPreset.medium,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    final startPath = client.buildTranscodeStartPathFromParamsForTesting(
      params,
      endpoint: '/music/:/transcode/universal/start.mp3',
    );

    expect(startPath, startsWith('/music/:/transcode/universal/start.mp3?'));
    expect(startPath, contains('musicBitrate=192'));
    expect(startPath, contains('mediaIndex=1'));
    expect(startPath, contains('partIndex=2'));
    // Profile-extra parens/ampersands must be percent-encoded on the wire.
    expect(
      startPath,
      contains(
        'X-Plex-Client-Profile-Extra=add-transcode-target%28type%3DmusicProfile%26context%3Dstreaming'
        '%26protocol%3Dhttp%26container%3Dmp3%26audioCodec%3Dmp3%29',
      ),
    );
    expect(startPath, isNot(contains('X-Plex-Token')));
  });

  test('a direct-play track names its playback session in the stream URL', () async {
    final client = makeClient((request) async {
      if (request.url.path != '/library/metadata/9669') return http.Response('unexpected request', 500);
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': '9669',
                'type': 'track',
                'title': 'Track',
                'Media': [
                  {
                    'id': 7,
                    'container': 'flac',
                    'Part': [
                      {
                        'id': 99,
                        'key': '/library/parts/99/1700000000/file.flac',
                        'Stream': [
                          {'streamType': 2, 'id': 301, 'codec': 'flac', 'selected': true},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final result = await client.getPlaybackInitialization(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: '9669', backend: MediaBackend.plex, kind: MediaKind.track, serverId: 'server-id'),
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.original,
        audioQualityPreset: AudioQualityPreset.original,
        sessionIdentifier: 'session-id',
        transcodeSessionId: 'transcode-id',
      ),
    );

    // Gapless playback reuses the playing track's headers for the next
    // track's request, so each track's session must ride its own URL.
    final url = Uri.parse(result.videoUrl!);
    expect(url.path, '/library/parts/99/1700000000/file.flac');
    expect(url.queryParameters['X-Plex-Session-Identifier'], 'session-id');
    expect(url.queryParameters['X-Plex-Token'], 'token');
  });
}
