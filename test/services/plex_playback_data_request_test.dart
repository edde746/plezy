import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/media/media_source_info.dart';
import 'package:vibe_stream/mpv/mpv.dart';
import 'package:vibe_stream/models/plex/plex_config.dart';
import 'package:vibe_stream/models/transcode_quality_preset.dart';
import 'package:vibe_stream/services/plex_api_cache.dart';
import 'package:vibe_stream/services/plex_client.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) {
    return PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Vibe',
        version: '1',
      ),
      serverId: 'server-id',
      httpClient: MockClient(handler),
    );
  }

  MediaSourceInfo mediaInfoWithSubtitles(List<MediaSubtitleTrack> subtitleTracks) {
    return MediaSourceInfo(
      videoUrl: 'https://plex.example.com/video.mkv',
      audioTracks: const [],
      subtitleTracks: subtitleTracks,
      chapters: const [],
    );
  }

  List<SubtitleTrack> buildTranscodeSubtitles(PlexClient client, List<MediaSubtitleTrack> subtitleTracks) {
    return client.buildTranscodeSidecarSubtitlesForTesting(mediaInfoWithSubtitles(subtitleTracks));
  }

  test('playback metadata request includes streams for transcode sidecar subtitles', () async {
    final requests = <Uri>[];
    final client = makeClient((request) async {
      requests.add(request.url);
      if (request.url.path != '/library/metadata/42') {
        return http.Response('not found', 404);
      }

      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': '42',
                'type': 'movie',
                'title': 'Movie',
                'Media': [
                  {
                    'id': 7,
                    'container': 'mkv',
                    'Part': [
                      {
                        'id': 99,
                        'key': '/library/parts/99/file.mkv',
                        'Stream': [
                          {'streamType': 1, 'id': 300, 'codec': 'h264'},
                          {'streamType': 2, 'id': 301, 'index': 0, 'languageCode': 'jpn', 'selected': true},
                          {
                            'streamType': 3,
                            'id': 401,
                            'index': 1,
                            'codec': 'ass',
                            'language': 'English',
                            'languageCode': 'eng',
                            'title': 'Signs/Songs',
                            'selected': true,
                          },
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

    final data = await client.getVideoPlaybackData('42');

    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['includeStreams'], '1');
    expect(data.mediaInfo?.subtitleTracks, hasLength(1));
    expect(data.mediaInfo?.subtitleTracks.single.id, 401);
    expect(data.mediaInfo?.subtitleTracks.single.selected, isTrue);
  });

  test('transcode subtitle sidecars only use real Plex stream keys', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(id: 401, codec: 'srt', languageCode: 'eng', selected: false, forced: false),
      MediaSubtitleTrack(
        id: 402,
        codec: 'srt',
        languageCode: 'eng',
        selected: false,
        forced: false,
        key: '/library/streams/402',
        external: true,
      ),
    ]);

    expect(subtitles, hasLength(1));
    expect(subtitles.single.uri, 'https://plex.example.com/library/streams/402.srt?encoding=utf-8&X-Plex-Token=token');
  });

  test('selected internal text subtitles are not attached as external sidecars', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(
        id: 401,
        codec: 'ass',
        language: 'English',
        languageCode: 'eng',
        title: 'Signs/Songs',
        selected: true,
        forced: false,
      ),
    ]);

    expect(subtitles, isEmpty);
  });

  test('selected internal text subtitles are embedded in HTTP MKV transcode', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: MediaSubtitleTrack(
        id: 401,
        codec: 'ass',
        languageCode: 'eng',
        selected: true,
        forced: false,
      ),
    );

    expect(params['protocol'], 'http');
    expect(params['subtitles'], 'embedded');
    expect(params['subtitleStreamID'], '401');
    expect(params['advancedSubtitles'], 'text');
    expect(params['X-Plex-Chunked'], '1');
    expect(params.containsKey('X-Plex-Incomplete-Segments'), isFalse);
    expect(params['X-Plex-Client-Profile-Extra'], contains('add-settings(DirectPlayStreamSelection=true)'));
    expect(
      params['X-Plex-Client-Profile-Extra'],
      contains(
        'add-transcode-target(type=videoProfile&context=streaming'
        '&protocol=http&container=mkv&videoCodec=h264%2Chevc%2C*'
        '&audioCodec=opus%2Cvorbis%2Cflac%2C*&subtitleCodec=ass%2Cpgs%2Cvobsub%2C*)',
      ),
    );
    expect(params['X-Plex-Client-Profile-Extra'], isNot(contains('protocol=hls')));
    expect(params['X-Plex-Client-Profile-Extra'], isNot(contains('type=subtitleProfile')));
  });

  test('transcode start path uses HTTP start endpoint without token', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      offsetMs: 90500,
    );

    final startPath = client.buildTranscodeStartPathFromParamsForTesting(params);

    expect(params['offset'], '90');
    expect(startPath, startsWith('/video/:/transcode/universal/start?'));
    expect(startPath, isNot(contains('start.m3u8')));
    expect(startPath, contains('protocol=http'));
    expect(startPath, contains('offset=90'));
    expect(startPath, isNot(contains('X-Plex-Token')));
  });

  test('unsupported embedded subtitles keep main transcode subtitles disabled', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: MediaSubtitleTrack(
        id: 401,
        codec: 'pgs',
        languageCode: 'eng',
        selected: true,
        forced: false,
      ),
    );

    expect(params['subtitles'], 'none');
    expect(params['protocol'], 'http');
    expect(params.containsKey('subtitleStreamID'), isFalse);
    expect(params.containsKey('advancedSubtitles'), isFalse);
    expect(params['X-Plex-Client-Profile-Extra'], isNot(contains('type=subtitleProfile')));
  });

  test('bitmap embedded subtitles are skipped during transcode instead of burned', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(id: 401, codec: 'pgs', languageCode: 'eng', selected: true, forced: false),
      MediaSubtitleTrack(id: 402, codec: 'dvd_subtitle', languageCode: 'eng', selected: true, forced: false),
    ]);

    expect(subtitles, isEmpty);
  });
}
