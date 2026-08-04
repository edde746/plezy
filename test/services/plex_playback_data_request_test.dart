import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

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

  Future<({PlaybackInitializationResult result, Uri decisionUri})> initializeTranscodeAudio({
    int? selectedAudioStreamId,
    AudioTrack? preferredAudioTrack,
  }) async {
    late Uri decisionUri;
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/42') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'type': 'episode',
                  'title': 'Episode',
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
                            {
                              'streamType': 2,
                              'id': 301,
                              'index': 0,
                              'codec': 'aac',
                              'languageCode': 'eng',
                              'title': 'Original',
                              'selected': true,
                            },
                            {
                              'streamType': 2,
                              'id': 305,
                              'index': 1,
                              'codec': 'flac',
                              'languageCode': 'jpn',
                              'title': 'Main',
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
      }
      if (request.url.path == '/video/:/transcode/universal/decision') {
        decisionUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {'generalDecisionCode': 1001, 'transcodeDecisionCode': 1001},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('unexpected request', 500);
    });
    try {
      final result = await client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.episode, serverId: 'server-id'),
          selectedMediaIndex: 0,
          selectedAudioStreamId: selectedAudioStreamId,
          preferredAudioTrack: preferredAudioTrack,
          qualityPreset: TranscodeQualityPreset.p720_3mbps,
          sessionIdentifier: 'session-id',
          transcodeSessionId: 'transcode-id',
        ),
      );
      return (result: result, decisionUri: decisionUri);
    } finally {
      client.close();
    }
  }

  MediaSourceInfo mediaInfoWithSubtitles(List<MediaSubtitleTrack> subtitleTracks) {
    return MediaSourceInfo(
      videoUrl: 'https://plex.example.com/video.mkv',
      audioTracks: const [],
      subtitleTracks: subtitleTracks,
      chapters: const [],
    );
  }

  List<PlaybackSubtitleSidecar> buildTranscodeSubtitles(PlexClient client, List<MediaSubtitleTrack> subtitleTracks) {
    return client.buildTranscodeSidecarSubtitlesForTesting(
      mediaInfoWithSubtitles(subtitleTracks),
      'https://plex.example.com/video.mkv?X-Plex-Token=token',
    );
  }

  test('selectStreams sends audio stream selection with allParts', () async {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
    addTearDown(client.close);

    final saved = await client.selectStreams(99, audioStreamID: 301, allParts: true);

    expect(saved, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/library/parts/99');
    expect(requests.single.url.queryParameters['audioStreamID'], '301');
    expect(requests.single.url.queryParameters['allParts'], '1');
  });

  test('semantic carried audio is sent to the Plex transcode decision', () async {
    final initialized = await initializeTranscodeAudio(
      preferredAudioTrack: const AudioTrack(id: 'source:999', language: 'jpn', title: 'Main', codec: 'flac'),
    );

    expect(initialized.decisionUri.queryParameters['audioStreamID'], '305');
    expect(initialized.result.activeAudioStreamId, 305);
  });

  test('explicit Plex audio stream wins over a conflicting semantic carry', () async {
    final initialized = await initializeTranscodeAudio(
      selectedAudioStreamId: 301,
      preferredAudioTrack: const AudioTrack(id: 'source:999', language: 'jpn', title: 'Main', codec: 'flac'),
    );

    expect(initialized.decisionUri.queryParameters['audioStreamID'], '301');
    expect(initialized.result.activeAudioStreamId, 301);
  });

  test('unresolvable semantic audio carry lets the Plex transcoder choose the stream', () async {
    final initialized = await initializeTranscodeAudio(
      preferredAudioTrack: const AudioTrack(id: 'source:999', language: 'swe'),
    );

    expect(initialized.decisionUri.queryParameters.containsKey('audioStreamID'), isFalse);
    expect(initialized.result.activeAudioStreamId, isNull);
  });

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
    expect(requests.single.queryParameters['checkFiles'], '1');
    expect(requests.single.queryParameters.containsKey('checkFileAvailability'), isFalse);
    expect(data.mediaInfo?.subtitleTracks, hasLength(1));
    expect(data.mediaInfo?.subtitleTracks.single.id, 401);
    expect(data.mediaInfo?.subtitleTracks.single.selected, isTrue);
  });

  test('transcode initialization wires a subtitle-free HLS request to the complete sidecar catalog', () async {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      if (request.url.path == '/library/metadata/42') {
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
                              'languageCode': 'eng',
                              'selected': true,
                            },
                            {
                              'streamType': 3,
                              'id': 402,
                              'index': 2,
                              'codec': 'srt',
                              'languageCode': 'swe',
                              'key': '/library/streams/402',
                              'external': true,
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
      }
      if (request.url.path == '/video/:/transcode/universal/decision') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {'generalDecisionCode': 1001, 'transcodeDecisionCode': 1001},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('unexpected request', 500);
    });
    addTearDown(client.close);

    final result = await client.getPlaybackInitialization(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id'),
        selectedMediaIndex: 0,
        qualityPreset: TranscodeQualityPreset.p720_3mbps,
        sessionIdentifier: 'session-id',
        transcodeSessionId: 'transcode-id',
      ),
    );

    final decisionRequest = requests.singleWhere(
      (request) => request.url.path == '/video/:/transcode/universal/decision',
    );
    expect(decisionRequest.url.queryParameters['subtitles'], 'none');
    expect(decisionRequest.url.queryParameters.containsKey('subtitleStreamID'), isFalse);
    expect(decisionRequest.url.queryParameters.containsKey('advancedSubtitles'), isFalse);
    expect(result.isTranscoding, isTrue);
    expect(result.videoUrl, contains('/video/:/transcode/universal/start.m3u8?'));
    expect(result.subtitleSidecars.map((sidecar) => sidecar.sourceStreamId), [401, 402]);
    expect(result.subtitleSidecars.every((sidecar) => sidecar.preload), isTrue);
    expect(result.subtitleSidecars.first.track.isContainer, isTrue);
    expect(result.subtitleSidecars.last.track.uri, contains('/library/streams/402.srt'));
  });

  test('playback uses metadata availability flags without probing part URLs', () async {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      if (request.url.path != '/library/metadata/42') {
        return http.Response('unexpected request', 500);
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
                      {'id': 10, 'key': '/library/parts/10/file.mkv', 'exists': 0, 'accessible': 1},
                      {'id': 20, 'key': '/library/parts/20/file.mkv', 'exists': 1, 'accessible': 1},
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
    expect(requests.single.url.queryParameters['checkFiles'], '1');
    expect(requests.single.url.queryParameters.containsKey('checkFileAvailability'), isFalse);
    expect(data.videoUrl, 'https://plex.example.com/library/parts/20/file.mkv?X-Plex-Token=token');
    expect(data.selectedMediaIndex, 0);
    expect(data.selectedPartIndex, 1);
  });

  test('latest server metadata overwrites cached playback media fields', () async {
    final cache = PlexApiCache.instance;
    await cache.put(ServerId('server-id'), '/library/metadata/42', {
      'MediaContainer': {
        'Metadata': [
          {
            'ratingKey': '42',
            'type': 'movie',
            'title': 'Playback title',
            'Media': [
              {
                'id': 7,
                'Part': [
                  {
                    'id': 99,
                    'key': '/library/parts/99/file.mkv',
                    'exists': true,
                    'accessible': true,
                    'Stream': [
                      {'streamType': 1, 'id': 300, 'codec': 'h264'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    });

    await cache.put(ServerId('server-id'), '/library/metadata/42', {
      'MediaContainer': {
        'Metadata': [
          {
            'ratingKey': '42',
            'type': 'movie',
            'title': 'Detail title',
            'Media': [
              {
                'id': 7,
                'Part': [
                  {'id': 99, 'key': '/library/parts/99/weak.mkv'},
                ],
              },
            ],
          },
        ],
      },
    });

    final cached = await cache.get(ServerId('server-id'), '/library/metadata/42');
    final metadata = (cached!['MediaContainer'] as Map<String, dynamic>)['Metadata'] as List<dynamic>;
    final item = metadata.single as Map<String, dynamic>;
    final media = item['Media'] as List<dynamic>;
    final part = ((media.single as Map<String, dynamic>)['Part'] as List<dynamic>).single as Map<String, dynamic>;

    expect(item['title'], 'Detail title');
    expect(part['key'], '/library/parts/99/weak.mkv');
    expect(part.containsKey('exists'), isFalse);
    expect(part.containsKey('accessible'), isFalse);
    expect(part.containsKey('Stream'), isFalse);
  });

  test('network failure falls back to profile-scoped lean cached playback metadata', () async {
    await PlexApiCache.instance.put(
      buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile').cacheServerId,
      '/library/metadata/42',
      {
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': '42',
              'type': 'movie',
              'title': 'Movie',
              'Media': [
                {
                  'id': 7,
                  'Part': [
                    {'id': 10, 'key': '/library/parts/10/stale.mkv'},
                  ],
                },
                {
                  'id': 8,
                  'Part': [
                    {'id': 20, 'key': '/library/parts/20/current.mkv'},
                  ],
                },
              ],
            },
          ],
        },
      },
    );
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      throw Exception('offline');
    });
    addTearDown(client.close);

    final data = await client.getVideoPlaybackData('42');

    expect(requests, hasLength(1));
    expect(data.videoUrl, 'https://plex.example.com/library/parts/10/stale.mkv?X-Plex-Token=token');
    expect(data.availableVersions, hasLength(2));
  });

  test('playback initialization exposes effective selected media index', () async {
    final client = makeClient((request) async {
      if (request.url.path != '/library/metadata/42') {
        return http.Response('unexpected request', 500);
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
                    'Part': [
                      {'id': 10, 'key': '/library/parts/10/stale.mkv', 'exists': false, 'accessible': false},
                    ],
                  },
                  {
                    'id': 8,
                    'Part': [
                      {'id': 20, 'key': '/library/parts/20/current.mkv', 'exists': true, 'accessible': true},
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
        metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id'),
        selectedMediaIndex: 0,
      ),
    );

    expect(result.videoUrl, 'https://plex.example.com/library/parts/20/current.mkv?X-Plex-Token=token');
    expect(result.selectedMediaIndex, 1);
  });

  test('transcode subtitle catalog includes embedded and keyed Plex streams', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(id: 401, codec: 'ass', languageCode: 'eng', title: 'Embedded', selected: true, forced: false),
      MediaSubtitleTrack(
        id: 402,
        codec: 'srt',
        languageCode: 'swe',
        title: 'External',
        selected: false,
        forced: false,
        key: '/library/streams/402',
        external: true,
      ),
    ]);

    expect(subtitles, hasLength(2));
    expect(subtitles.map((sidecar) => sidecar.sourceStreamId), [401, 402]);
    expect(subtitles.every((sidecar) => sidecar.preload), isTrue);
    expect(subtitles.first.track.isContainer, isTrue);
    expect(subtitles.first.track.uri, 'https://plex.example.com/video.mkv?X-Plex-Token=token');
    expect(subtitles.last.track.isContainer, isFalse);
    expect(
      subtitles.last.track.uri,
      'https://plex.example.com/library/streams/402.srt?encoding=utf-8&X-Plex-Token=token',
    );
  });

  test('tokenless transcode keeps embedded and keyed subtitle sources', () {
    final client = testPlexClient(
      serverId: ServerId('server-id'),
      token: null,
      handler: (_) async => http.Response('not used', 500),
    );
    addTearDown(client.close);

    final subtitles = client.buildTranscodeSidecarSubtitlesForTesting(
      mediaInfoWithSubtitles([
        MediaSubtitleTrack(id: 401, codec: 'ass', languageCode: 'eng', selected: true, forced: false),
        MediaSubtitleTrack(
          id: 402,
          codec: 'srt',
          languageCode: 'swe',
          selected: false,
          forced: false,
          key: '/library/streams/402',
          external: true,
        ),
      ]),
      'https://plex.example.com/video.mkv',
    );

    expect(subtitles, hasLength(2));
    expect(subtitles.first.track.isContainer, isTrue);
    expect(subtitles.first.track.uri, 'https://plex.example.com/video.mkv');
    expect(subtitles.last.track.isContainer, isFalse);
    expect(subtitles.last.track.uri, 'https://plex.example.com/library/streams/402.srt?encoding=utf-8');
  });

  test('video transcode stays subtitle-free while preserving the HLS profile', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(params['protocol'], 'hls');
    expect(params['subtitles'], 'none');
    expect(params.containsKey('subtitleStreamID'), isFalse);
    expect(params.containsKey('advancedSubtitles'), isFalse);
    expect(params.containsKey('X-Plex-Chunked'), isFalse);
    expect(params['X-Plex-Incomplete-Segments'], '1');
    expect(params['X-Plex-Client-Profile-Name'], 'Generic');

    final profile = params['X-Plex-Client-Profile-Extra'];
    expect(profile, contains('add-settings(DirectPlayStreamSelection=true)'));
    expect(
      profile,
      contains(
        'add-limitation(scope=videoCodec&scopeName=*&type=upperBound'
        '&name=video.bitrate&value=3000&replace=true)',
      ),
    );
    expect(
      profile,
      contains(
        'add-transcode-target(type=videoProfile&context=streaming'
        '&protocol=hls&container=mpegts',
      ),
    );
    expect(
      profile,
      contains(
        'add-transcode-target(type=subtitleProfile&context=streaming'
        '&protocol=hls&container=webvtt&subtitleCodec=webvtt)',
      ),
    );
    expect(profile, isNot(contains('protocol=http&container=mkv')));
  });

  test('transcode start path uses the HLS manifest endpoint without token', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    final startPath = client.buildTranscodeStartPathFromParamsForTesting(params);

    expect(startPath, startsWith('/video/:/transcode/universal/start.m3u8?'));
    expect(startPath, contains('protocol=hls'));
    expect(startPath, isNot(contains('offset=')));
    expect(startPath, isNot(contains('X-Plex-Token')));
  });

  test('transcode params preserve resolved media and part indices', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 1,
      partIndex: 2,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(params['mediaIndex'], '1');
    expect(params['partIndex'], '2');
  });

  test('image-based embedded subtitles use the shared container sidecar', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(id: 401, codec: 'pgs', languageCode: 'eng', selected: true, forced: false),
      MediaSubtitleTrack(id: 402, codec: 'dvd_subtitle', languageCode: 'eng', selected: false, forced: false),
    ]);

    expect(subtitles, hasLength(2));
    expect(subtitles.every((sidecar) => sidecar.track.isContainer), isTrue);
    expect(subtitles.map((sidecar) => sidecar.track.uri).toSet(), {
      'https://plex.example.com/video.mkv?X-Plex-Token=token',
    });
  });

  group('playback metadata failure contract', () {
    Map<String, dynamic> playableBody() => {
      'MediaContainer': {
        'Metadata': [
          {
            'ratingKey': '42',
            'type': 'movie',
            'Media': [
              {
                'id': 7,
                'Part': [
                  {'id': 10, 'key': '/library/parts/10/file.mkv'},
                ],
              },
            ],
          },
        ],
      },
    };

    Map<String, dynamic> noPartBody() => {
      'MediaContainer': {
        'Metadata': [
          {
            'ratingKey': '42',
            'type': 'movie',
            'Media': [
              {'id': 7, 'Part': []},
            ],
          },
        ],
      },
    };

    PlaybackInitializationOptions options() => PlaybackInitializationOptions(
      metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id'),
      selectedMediaIndex: 0,
    );

    test('raw helper preserves 401 while initialization classifies authentication', () async {
      final client = makeClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'body-canary'}), 401, headers: {'content-type': 'application/json'}),
      );
      addTearDown(client.close);

      await expectLater(
        client.getVideoPlaybackData('42'),
        throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 401)),
      );
      await expectLater(
        client.getPlaybackInitialization(options()),
        throwsA(
          isA<PlaybackException>()
              .having((error) => error.reason, 'reason', PlaybackFailureReason.authenticationRequired)
              .having((error) => error.message, 'message', isNot(contains('body-canary'))),
        ),
      );
    });

    test('raw timeout survives and initialization classifies server unavailable', () async {
      final client = makeClient(
        (_) async => throw MediaServerHttpException(
          type: MediaServerHttpErrorType.receiveTimeout,
          message: 'timeout-canary',
          requestUri: Uri.parse('https://private.invalid/library/metadata/42?secret=uri-canary'),
        ),
      );
      addTearDown(client.close);

      await expectLater(
        client.getVideoPlaybackData('42'),
        throwsA(
          isA<MediaServerHttpException>().having(
            (error) => error.type,
            'type',
            MediaServerHttpErrorType.receiveTimeout,
          ),
        ),
      );
      try {
        await client.getPlaybackInitialization(options());
        fail('Timeout must throw');
      } on PlaybackException catch (error) {
        expect(error.reason, PlaybackFailureReason.serverUnavailable);
        expect(error.message, isNot(contains('timeout-canary')));
        expect(error.toString(), isNot(anyOf(contains('private.invalid'), contains('uri-canary'))));
      }
    });

    test('successful malformed envelope, Media, and Part collections are invalid data', () async {
      final malformedBodies = <Map<String, dynamic>>[
        {'notMediaContainer': true},
        {
          'MediaContainer': {
            'Metadata': [
              {'Media': 'payload-canary'},
            ],
          },
        },
        {
          'MediaContainer': {
            'Metadata': [
              {
                'Media': [
                  {'Part': 'payload-canary'},
                ],
              },
            ],
          },
        },
      ];

      for (final body in malformedBodies) {
        final client = makeClient(
          (_) async => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'}),
        );
        addTearDown(client.close);
        await expectLater(client.getVideoPlaybackData('42'), throwsA(isA<FormatException>()));
        await expectLater(
          client.getPlaybackInitialization(options()),
          throwsA(
            isA<PlaybackException>()
                .having((error) => error.reason, 'reason', PlaybackFailureReason.invalidPlaybackData)
                .having((error) => error.toString(), 'safe text', isNot(contains('payload-canary'))),
          ),
        );
      }
    });

    test('playback validation preserves singleton and mixed valid Media/Part shapes', () async {
      final bodies = <Map<String, dynamic>>[
        {
          'MediaContainer': {
            'Metadata': [
              {
                'Media': {
                  'id': 7,
                  'Part': {'id': 10, 'key': '/library/parts/10/singleton.mkv'},
                },
              },
            ],
          },
        },
        {
          'MediaContainer': {
            'Metadata': [
              {
                'Media': [
                  'ignored',
                  {
                    'id': 7,
                    'Part': [
                      'ignored',
                      {'id': 10, 'key': '/library/parts/10/mixed.mkv'},
                    ],
                  },
                ],
              },
            ],
          },
        },
      ];

      for (final body in bodies) {
        final client = makeClient(
          (_) async => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'}),
        );
        addTearDown(client.close);

        final data = await client.getVideoPlaybackData('42');

        expect(data.hasValidVideoUrl, isTrue);
        expect(data.videoUrl, contains('/library/parts/10/'));
      }
    });

    test('invalid JSON and non-map top-level data classify as invalid playback data', () async {
      final responses = [
        http.Response('{', 200, headers: {'content-type': 'application/json'}),
        http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'}),
      ];

      for (final response in responses) {
        final client = makeClient((_) async => response);
        addTearDown(client.close);
        await expectLater(
          client.getPlaybackInitialization(options()),
          throwsA(
            isA<PlaybackException>().having(
              (error) => error.reason,
              'reason',
              PlaybackFailureReason.invalidPlaybackData,
            ),
          ),
        );
      }
    });

    test('valid metadata without a part remains noPlayableSource', () async {
      final client = makeClient(
        (_) async => http.Response(jsonEncode(noPartBody()), 200, headers: {'content-type': 'application/json'}),
      );
      addTearDown(client.close);

      final raw = await client.getVideoPlaybackData('42');
      expect(raw.hasValidVideoUrl, isFalse);
      await expectLater(
        client.getPlaybackInitialization(options()),
        throwsA(
          isA<PlaybackException>().having((error) => error.reason, 'reason', PlaybackFailureReason.noPlayableSource),
        ),
      );
    });

    test('auth, server, malformed, and no-source failures expose distinct reasons and messages', () async {
      Future<PlaybackException> capture(PlexClient client) async {
        try {
          await client.getPlaybackInitialization(options());
          fail('Initialization must throw');
        } on PlaybackException catch (error) {
          return error;
        }
      }

      final auth = makeClient((_) async => http.Response('{}', 401, headers: {'content-type': 'application/json'}));
      final server = makeClient((_) async => http.Response('{}', 500, headers: {'content-type': 'application/json'}));
      final malformed = makeClient(
        (_) async => http.Response(
          jsonEncode({'MediaContainer': 'invalid'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final noSource = makeClient(
        (_) async => http.Response(jsonEncode(noPartBody()), 200, headers: {'content-type': 'application/json'}),
      );
      addTearDown(auth.close);
      addTearDown(server.close);
      addTearDown(malformed.close);
      addTearDown(noSource.close);

      final failures = [await capture(auth), await capture(server), await capture(malformed), await capture(noSource)];
      expect(failures.map((failure) => failure.reason).toSet(), {
        PlaybackFailureReason.authenticationRequired,
        PlaybackFailureReason.serverUnavailable,
        PlaybackFailureReason.invalidPlaybackData,
        PlaybackFailureReason.noPlayableSource,
      });
      expect(failures.map((failure) => failure.message).toSet(), hasLength(4));
    });

    test('500, connection failure, and cancellation never become no-source', () async {
      final cases = <(PlaybackFailureReason, Future<http.Response> Function(http.Request))>[
        (
          PlaybackFailureReason.serverUnavailable,
          (_) async => http.Response('{}', 500, headers: {'content-type': 'application/json'}),
        ),
        (
          PlaybackFailureReason.serverUnavailable,
          (_) async =>
              throw MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'unavailable'),
        ),
        (PlaybackFailureReason.cancelled, (request) async => throw http.RequestAbortedException(request.url)),
      ];

      for (final (reason, handler) in cases) {
        final client = makeClient(handler);
        addTearDown(client.close);
        await expectLater(
          client.getPlaybackInitialization(options()),
          throwsA(isA<PlaybackException>().having((error) => error.reason, 'reason', reason)),
        );
      }
    });

    test('unclassified failures use the safe unknown reason and message', () async {
      final client = makeClient((_) async => throw StateError('unknown-cause-canary'));
      addTearDown(client.close);

      await expectLater(
        client.getPlaybackInitialization(options()),
        throwsA(
          isA<PlaybackException>()
              .having((error) => error.reason, 'reason', PlaybackFailureReason.unknown)
              .having((error) => error.message, 'safe message', isNot(contains('unknown-cause-canary'))),
        ),
      );
    });

    test('status failure still serves a valid cached playable row', () async {
      await PlexApiCache.instance.put(
        buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile').cacheServerId,
        '/library/metadata/42',
        playableBody(),
      );
      final client = makeClient((_) async => http.Response('{}', 500, headers: {'content-type': 'application/json'}));
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42');

      expect(data.hasValidVideoUrl, isTrue);
      expect(data.videoUrl, contains('/library/parts/10/file.mkv'));
    });

    test('external URL and download resolution propagate typed request failures', () async {
      final client = makeClient((_) async => http.Response('{}', 401, headers: {'content-type': 'application/json'}));
      addTearDown(client.close);
      final item = testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id');

      await expectLater(client.resolveExternalPlaybackUrl(item), throwsA(isA<MediaServerHttpException>()));
      await expectLater(client.resolveDownload(item), throwsA(isA<MediaServerHttpException>()));
    });
  });
}
