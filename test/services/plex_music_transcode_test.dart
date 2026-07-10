import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/audio_quality_preset.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

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
        product: 'Plezy',
        version: '1',
      ),
      serverId: ServerId('server-id'),
      httpClient: MockClient(handler),
    );
  }

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
}
