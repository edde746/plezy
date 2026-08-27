import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/subtitle_preference.dart';
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
            'MediaContainer': {
              'generalDecisionCode': 1001,
              'transcodeDecisionCode': 1001,
              // Real decisions echo the honoured target container back; the
              // client refuses a transcode whose container it never asked for.
              'Metadata': [
                {
                  'Media': [
                    {'container': 'mp4', 'protocol': 'hls', 'selected': true},
                  ],
                },
              ],
            },
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
    return client.buildTranscodeSidecarSubtitlesForTesting(mediaInfoWithSubtitles(subtitleTracks));
  }

  test('selectStreams sends audio stream selection with allParts', () async {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
    addTearDown(client.close);

    final saved = await client.selectStreams(99, audioStreamID: 301);

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

  group('fresh-cache-first playback metadata', () {
    // Same scope [PlexClient.getVideoPlaybackData] resolves via
    // `ServerId(cacheServerId)` — the fixture's default profile scope.
    final cacheScope = buildPlexProfileScopeId(
      serverId: ServerId('server-id'),
      profileId: 'test-profile',
    ).cacheServerId;
    const endpoint = '/library/metadata/42';

    // The shape the detail screen caches: includeStreams + checkFiles keys
    // (`Stream`/`exists`/`accessible`) present on the part.
    Map<String, dynamic> richPlaybackPayload() => {
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
                    'exists': true,
                    'accessible': true,
                    'Stream': [
                      {'streamType': 1, 'id': 300, 'codec': 'h264'},
                      {'streamType': 3, 'id': 401, 'index': 1, 'codec': 'ass', 'languageCode': 'eng', 'selected': true},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    };

    PlexClient makeCountingClient(List<Uri> requests) => makeClient((request) async {
      requests.add(request.url);
      if (request.url.path != endpoint) return http.Response('not found', 404);
      return http.Response(jsonEncode(richPlaybackPayload()), 200, headers: {'content-type': 'application/json'});
    });

    test('fresh stream-rich cached row is served with zero network requests', () async {
      await PlexApiCache.instance.put(cacheScope, endpoint, richPlaybackPayload());
      final requests = <Uri>[];
      final client = makeCountingClient(requests);
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42');

      expect(requests, isEmpty);
      expect(data.hasValidVideoUrl, isTrue);
      expect(data.videoUrl, contains('/library/parts/99/file.mkv'));
      expect(data.mediaInfo?.subtitleTracks.single.id, 401);
    });

    test('forceRefresh bypasses a fresh stream-rich cached row', () async {
      // The subtitle-download poller relies on this: it must observe the new
      // external stream appearing server-side while the shared row is fresh.
      await PlexApiCache.instance.put(cacheScope, endpoint, richPlaybackPayload());
      final requests = <Uri>[];
      final client = makeCountingClient(requests);
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42', forceRefresh: true);

      expect(requests, hasLength(1));
      expect(requests.single.queryParameters['includeStreams'], '1');
      expect(data.mediaInfo?.subtitleTracks.single.id, 401);
    });

    test('fresh but stream-less cached row still fetches from the network', () async {
      // getPlaybackExtras' lean fetch overwrites the shared row without
      // includeStreams/checkFiles; that shape must never satisfy playback.
      await PlexApiCache.instance.put(cacheScope, endpoint, {
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
                    {'id': 99, 'key': '/library/parts/99/file.mkv'},
                  ],
                },
              ],
            },
          ],
        },
      });
      final requests = <Uri>[];
      final client = makeCountingClient(requests);
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42');

      expect(requests, hasLength(1));
      expect(requests.single.queryParameters['includeStreams'], '1');
      expect(data.mediaInfo?.subtitleTracks.single.id, 401);
    });

    test('cached row older than the freshness window fetches from the network', () async {
      await PlexApiCache.instance.put(cacheScope, endpoint, richPlaybackPayload());
      await (db.update(db.apiCache)..where((t) => t.cacheKey.equals('$cacheScope:$endpoint'))).write(
        ApiCacheCompanion(
          cachedAt: Value(DateTime.now().subtract(playbackMetadataCacheFreshness + const Duration(seconds: 1))),
        ),
      );
      final requests = <Uri>[];
      final client = makeCountingClient(requests);
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42');

      expect(requests, hasLength(1));
      expect(data.hasValidVideoUrl, isTrue);
    });

    test('cache miss fetches from the network', () async {
      final requests = <Uri>[];
      final client = makeCountingClient(requests);
      addTearDown(client.close);

      final data = await client.getVideoPlaybackData('42');

      expect(requests, hasLength(1));
      expect(data.hasValidVideoUrl, isTrue);
    });
  });

  test('transcode initialization burns the selected embedded stream and sidecars only the external file', () async {
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
            'MediaContainer': {
              'generalDecisionCode': 1001,
              'transcodeDecisionCode': 1001,
              'Metadata': [
                {
                  'Media': [
                    {'container': 'mp4', 'protocol': 'hls', 'selected': true},
                  ],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' && request.url.path == '/library/parts/99') {
        return http.Response('', 200);
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
    expect(decisionRequest.url.queryParameters['subtitles'], 'burn');
    expect(
      decisionRequest.url.queryParameters.containsKey('offset'),
      isFalse,
      reason: 'the player seeks in-band; an offset start forces transcoder restarts PMS can wedge on (#1859)',
    );
    expect(
      decisionRequest.url.queryParameters.containsKey('subtitleStreamID'),
      isFalse,
      reason: 'the universal transcoder ignores it; the part selection below is what picks the stream',
    );
    expect(decisionRequest.url.queryParameters.containsKey('advancedSubtitles'), isFalse);
    expect(decisionRequest.url.queryParameters['X-Plex-Incomplete-Segments'], '1');

    // What actually aims the burn: the embedded ASS track is selected on the
    // part first, so the server burns 401 rather than whatever it had stored.
    final selection = requests.singleWhere(
      (request) => request.method == 'PUT' && request.url.path == '/library/parts/99',
    );
    expect(selection.url.queryParameters['subtitleStreamID'], '401');
    expect(selection.url.queryParameters.containsKey('audioStreamID'), isFalse);
    expect(result.isTranscoding, isTrue);
    expect(result.videoUrl, contains('/video/:/transcode/universal/start.m3u8?'));
    expect(Uri.parse(result.videoUrl!).queryParameters.containsKey('offset'), isFalse);
    expect(result.subtitleSidecars.map((sidecar) => sidecar.sourceStreamId), [402]);
    expect(result.subtitleSidecars.single.preload, isTrue);
    expect(result.subtitleSidecars.single.track.uri, contains('/library/streams/402.srt'));
  });

  test('direct play preloads every external subtitle file, not just the selected one', () async {
    // Two sidecar files next to the video: only one is selected, but both must
    // load with the media so the other stays selectable as a secondary
    // subtitle without a reopen (#1860). The embedded row is the container's
    // job on direct play and gets no sidecar.
    final client = makeClient((request) async {
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
                      'container': 'mp4',
                      'Part': [
                        {
                          'id': 99,
                          'key': '/library/parts/99/file.mp4',
                          'Stream': [
                            {'streamType': 1, 'id': 300, 'codec': 'h264'},
                            {'streamType': 2, 'id': 301, 'index': 0, 'languageCode': 'eng', 'selected': true},
                            {
                              'streamType': 3,
                              'id': 401,
                              'index': 1,
                              'codec': 'srt',
                              'languageCode': 'deu',
                              'key': '/library/streams/401',
                              'external': true,
                              'selected': true,
                            },
                            {
                              'streamType': 3,
                              'id': 402,
                              'index': 2,
                              'codec': 'srt',
                              'languageCode': 'fra',
                              'key': '/library/streams/402',
                              'external': true,
                            },
                            {'streamType': 3, 'id': 403, 'index': 3, 'codec': 'ass', 'languageCode': 'eng'},
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
      return http.Response('unexpected request', 500);
    });
    addTearDown(client.close);

    final result = await client.getPlaybackInitialization(
      PlaybackInitializationOptions(
        metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id'),
        selectedMediaIndex: 0,
      ),
    );

    expect(result.playMethod, 'DirectPlay');
    expect(result.subtitleSidecars.map((sidecar) => sidecar.sourceStreamId), [401, 402]);
    expect(result.subtitleSidecars.map((sidecar) => sidecar.preload), everyElement(isTrue));
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

  test('transcode subtitle catalog carries only real external subtitle files', () {
    // Embedded streams are burned into the picture by the transcoder. Handing them
    // back as sidecars on the source container would make the client range-read the
    // whole remux over HTTP while the transcode is already streaming (#1815, #1738).
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final subtitles = buildTranscodeSubtitles(client, [
      MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', languageCode: 'eng', selected: true, forced: false),
      MediaSubtitleTrack(id: 402, index: 4, codec: 'pgs', languageCode: 'eng', selected: false, forced: false),
      MediaSubtitleTrack(
        id: 403,
        index: 5,
        codec: 'srt',
        languageCode: 'swe',
        title: 'External',
        selected: false,
        forced: false,
        key: '/library/streams/403',
        external: true,
      ),
    ]);

    expect(subtitles.map((sidecar) => sidecar.sourceStreamId), [403]);
    expect(subtitles.single.preload, isTrue);
    expect(subtitles.single.track.isContainer, isFalse);
    expect(
      subtitles.single.track.uri,
      'https://plex.example.com/library/streams/403.srt?encoding=utf-8&X-Plex-Token=token',
    );
  });

  test('tokenless transcode still sidecars the external subtitle file', () {
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
    );

    expect(subtitles.map((sidecar) => sidecar.sourceStreamId), [402]);
    expect(subtitles.single.track.uri, 'https://plex.example.com/library/streams/402.srt?encoding=utf-8');
  });

  test('transcode burns the selected embedded stream whatever its format', () {
    // Burn covers text as well as image: it is the one mechanism that keeps ASS/SSA
    // styling intact through an HLS transcode.
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    Map<String, String> paramsForSelected(MediaSubtitleTrack track) => client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: track,
    );

    final textParams = paramsForSelected(
      MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', languageCode: 'eng', selected: true, forced: false),
    );
    expect(textParams['subtitles'], 'burn');
    expect(textParams.containsKey('subtitleStreamID'), isFalse);
    expect(textParams.containsKey('advancedSubtitles'), isFalse);

    final imageParams = paramsForSelected(
      MediaSubtitleTrack(id: 402, index: 4, codec: 'pgs', languageCode: 'eng', selected: true, forced: false),
    );
    expect(imageParams['subtitles'], 'burn');
    expect(imageParams.containsKey('subtitleStreamID'), isFalse);
  });

  test('a burn aims at the caller track by selecting it on the part first', () async {
    // The universal transcoder burns whatever the part has selected, so this
    // PUT is the only thing that makes `subtitles=burn` hit the chosen stream.
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
    addTearDown(client.close);

    await client.selectSubtitleStreamForBurn(
      partId: 99,
      track: MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', selected: true, forced: false),
    );

    final put = requests.singleWhere((request) => request.method == 'PUT');
    expect(put.url.path, '/library/parts/99');
    expect(put.url.queryParameters['subtitleStreamID'], '401');
  });

  test('a sidecarred external file leaves the server selection untouched', () async {
    // External files are fetched directly and never burned; rewriting the
    // part's selection here would change what other Plex clients see.
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
    addTearDown(client.close);

    await client.selectSubtitleStreamForBurn(
      partId: 99,
      track: MediaSubtitleTrack(
        id: 403,
        index: 5,
        codec: 'srt',
        selected: true,
        forced: false,
        key: '/library/streams/403',
        external: true,
      ),
    );
    await client.selectSubtitleStreamForBurn(partId: 99, track: null);

    expect(requests, isEmpty);
  });

  test('an unaimable burn refuses rather than letting the server pick', () async {
    // Proceeding would burn whatever the part already had selected, welding a
    // language the viewer never chose into the picture.
    final client = makeClient((_) async => http.Response('', 200));
    addTearDown(client.close);

    await expectLater(
      client.selectSubtitleStreamForBurn(
        partId: null,
        track: MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', selected: true, forced: false),
      ),
      throwsStateError,
    );
  });

  test('a selection the server did not commit refuses the burn too', () async {
    // 204 rather than 200: no HTTP error to raise, but nothing was stored
    // either, so the burn target is still whatever the part had before.
    final client = makeClient((_) async => http.Response('', 204));
    addTearDown(client.close);

    await expectLater(
      client.selectSubtitleStreamForBurn(
        partId: 99,
        track: MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', selected: true, forced: false),
      ),
      throwsStateError,
    );
  });

  test('a burn that cannot be aimed never reaches the decision endpoint', () async {
    // The whole transcode is abandoned: the caller falls back to direct play,
    // where the native player reads the embedded track itself.
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'MediaContainer': {'generalDecisionCode': 1001, 'transcodeDecisionCode': 1001},
        }),
        request.method == 'PUT' ? 403 : 200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final result = await client.buildTranscodeStartPath(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      partId: 99,
      selectedSubtitleTrack: MediaSubtitleTrack(id: 401, index: 3, codec: 'ass', selected: true, forced: false),
    );

    expect(result.outcome, TranscodeDecisionOutcome.failed);
    expect(result.startPath, isNull);
    expect(
      requests.where((request) => request.url.path.contains('/transcode/universal')),
      isEmpty,
      reason: 'no burn may be requested once the target could not be selected',
    );
  });

  test('transcode leaves a real external subtitle file to the sidecar instead of burning it', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: MediaSubtitleTrack(
        id: 403,
        index: 5,
        codec: 'srt',
        languageCode: 'swe',
        selected: true,
        forced: false,
        key: '/library/streams/403',
        external: true,
      ),
    );

    expect(params['subtitles'], 'none');
    expect(params.containsKey('subtitleStreamID'), isFalse);
  });

  test('no burn keeps the per-preset directPlay/directStream pinning', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final originalParams = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.original,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );
    expect(originalParams['directPlay'], '1');
    expect(originalParams['directStream'], '1');

    final cappedParams = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );
    expect(cappedParams['directPlay'], '0');
    expect(cappedParams['directStream'], '0');
  });

  test('a burn withdraws directPlay, because painting the subtitle in is a re-encode', () {
    // Not a preference: a real PMS answers HTTP 400 to `directPlay=1` combined
    // with `subtitles=burn`, for text and image subtitles alike. With
    // directPlay withdrawn it answers `decision=transcode` on the video stream
    // and `decision=burn` on the subtitle.
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    Map<String, String> paramsFor(String codec, TranscodeQualityPreset preset) => client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: preset,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: MediaSubtitleTrack(id: 401, index: 3, codec: codec, selected: true, forced: false),
    );

    for (final codec in ['ass', 'srt', 'pgs']) {
      final params = paramsFor(codec, TranscodeQualityPreset.p720_3mbps);
      expect(params['subtitles'], 'burn', reason: '$codec should burn');
      expect(params['directPlay'], '0', reason: '$codec burn must not also advertise direct play');
    }

    // Even an original-quality session must drop directPlay once it burns.
    final originalBurn = paramsFor('ass', TranscodeQualityPreset.original);
    expect(originalBurn['subtitles'], 'burn');
    expect(originalBurn['directPlay'], '0');
    expect(originalBurn['directStream'], '1');
  });

  test('video transcode requests no subtitles when none is selected, preserving the HLS profile', () {
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
        '&protocol=hls&container=mp4&videoCodec=h264%2Chevc'
        '&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)',
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
    // HEVC-in-TS is the mis-mux of issue #1859; the VOD profile must never
    // reintroduce it.
    expect(profile, isNot(contains('container=mpegts')));
    expect(profile, isNot(contains('mpeg2video')));
  });

  test('non-original presets send the resolution and quality caps their labels promise', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final capped = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p1080_8mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );
    expect(capped['videoResolution'], '1920x1080');
    expect(capped['videoQuality'], '60');

    final original = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.original,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );
    expect(original.containsKey('videoResolution'), isFalse);
    expect(original.containsKey('videoQuality'), isFalse);
  });

  Future<({PlaybackInitializationResult result, List<String> paths})> initializeCappedPlayback({
    required TranscodeQualityPreset preset,
    required int bitrateKbps,
    required int height,
  }) async {
    final paths = <String>[];
    final client = makeClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/library/metadata/42') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'Media': [
                    {
                      'id': 7,
                      'container': 'mkv',
                      'bitrate': bitrateKbps,
                      'height': height,
                      'Part': [
                        {'id': 99, 'key': '/library/parts/99/file.mkv'},
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
            'MediaContainer': {
              'transcodeDecisionCode': 1001,
              'Metadata': [
                {
                  'Media': [
                    {'container': 'mp4', 'protocol': 'hls', 'selected': true},
                  ],
                },
              ],
            },
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
          metadata: testMediaItem(id: '42', backend: MediaBackend.plex, serverId: 'server-id'),
          selectedMediaIndex: 0,
          qualityPreset: preset,
          sessionIdentifier: 'session-id',
          transcodeSessionId: 'transcode-id',
        ),
      );
      return (result: result, paths: paths);
    } finally {
      client.close();
    }
  }

  test('a preset the source already fits under plays the file itself (#2152)', () async {
    final run = await initializeCappedPlayback(
      preset: TranscodeQualityPreset.p1080_10mbps,
      bitrateKbps: 6206,
      height: 1080,
    );

    expect(run.paths, isNot(contains('/video/:/transcode/universal/decision')));
    expect(run.result.isTranscoding, isFalse);
    expect(run.result.playMethod, 'DirectPlay');
    expect(run.result.videoUrl, contains('/library/parts/99/file.mkv'));
    // Not a fallback: nothing failed, so the player must not report one.
    expect(run.result.fallbackReason, isNull);
  });

  test('a source the preset would actually reduce still transcodes', () async {
    final overBitrate = await initializeCappedPlayback(
      preset: TranscodeQualityPreset.p1080_10mbps,
      bitrateKbps: 13137,
      height: 1080,
    );
    expect(overBitrate.paths, contains('/video/:/transcode/universal/decision'));
    expect(overBitrate.result.playMethod, 'Transcode');

    final overResolution = await initializeCappedPlayback(
      preset: TranscodeQualityPreset.p1080_10mbps,
      bitrateKbps: 6534,
      height: 2160,
    );
    expect(overResolution.paths, contains('/video/:/transcode/universal/decision'));
    expect(overResolution.result.playMethod, 'Transcode');
  });

  test('the TS fallback profile offers only H.264, never HEVC-in-TS', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      useTsFallbackTarget: true,
    );

    final profile = params['X-Plex-Client-Profile-Extra'];
    expect(
      profile,
      contains(
        'add-transcode-target(type=videoProfile&context=streaming'
        '&protocol=hls&container=mpegts&videoCodec=h264'
        '&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)',
      ),
    );
    expect(profile, isNot(contains('hevc')));
    expect(profile, isNot(contains('container=mp4')));
  });

  Future<({({String? startPath, TranscodeDecisionOutcome outcome}) result, List<Uri> decisions})> runGuardedDecision(
    String Function(int decisionNumber) containerFor,
  ) async {
    final decisions = <Uri>[];
    final client = makeClient((request) async {
      decisions.add(request.url);
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'transcodeDecisionCode': 1001,
            'Metadata': [
              {
                'Media': [
                  {'container': containerFor(decisions.length), 'protocol': 'hls', 'selected': true},
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

    final result = await client.buildTranscodeStartPath(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );
    return (result: result, decisions: decisions);
  }

  test('a decision that honours the fMP4 container is used without a retry', () async {
    final run = await runGuardedDecision((_) => 'mp4');

    expect(run.result.outcome, TranscodeDecisionOutcome.transcodeOk);
    expect(run.decisions, hasLength(1));
    final profile = Uri.parse(run.result.startPath!).queryParameters['X-Plex-Client-Profile-Extra']!;
    expect(profile, contains('container=mp4&videoCodec=h264%2Chevc'));
  });

  test('a decision that ignores the fMP4 container is retried once with the TS/h264 profile', () async {
    final run = await runGuardedDecision((decisionNumber) => decisionNumber == 1 ? 'mkv' : 'mpegts');

    expect(run.result.outcome, TranscodeDecisionOutcome.transcodeOk);
    expect(run.decisions, hasLength(2));
    final retryProfile = run.decisions[1].queryParameters['X-Plex-Client-Profile-Extra']!;
    expect(retryProfile, contains('container=mpegts&videoCodec=h264&audioCodec'));
    // The start path must carry the profile the server actually honoured,
    // not the fMP4 one it ignored.
    final startProfile = Uri.parse(run.result.startPath!).queryParameters['X-Plex-Client-Profile-Extra']!;
    expect(startProfile, contains('container=mpegts&videoCodec=h264&audioCodec'));
  });

  test('a server honouring neither container falls back to direct play instead of a mis-mux', () async {
    final run = await runGuardedDecision((_) => 'mkv');

    expect(run.result.outcome, TranscodeDecisionOutcome.failed);
    expect(run.result.startPath, isNull);
    expect(run.decisions, hasLength(2));
  });

  test('a direct-play-only decision passes through without a container retry', () async {
    final decisions = <Uri>[];
    final client = makeClient((request) async {
      decisions.add(request.url);
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'transcodeDecisionCode': 1000,
            'Metadata': [
              {
                'Media': [
                  {'container': 'mkv', 'selected': true},
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

    final result = await client.buildTranscodeStartPath(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
    );

    expect(result.outcome, TranscodeDecisionOutcome.directPlayOnly);
    expect(decisions, hasLength(1));
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
    // Without a requested offset the start path must stay offset-free so the
    // session transcodes from the beginning exactly as before.
    expect(startPath, isNot(contains('offset=')));
    expect(startPath, isNot(contains('X-Plex-Token')));
  });

  test('an embedded subtitle this server cannot burn falls back as a failure', () async {
    // The row has no `key`, so it is embedded and a transcode would have to burn it; `dvb_teletext`
    // is not a codec the burn path accepts. Treating that as "no burn requested" sent
    // `subtitles=none` with the row still selected, so the caption vanished while state reported it
    // active *and* the capped preset was silently retained.
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/42') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'Media': [
                    {
                      'id': 1,
                      'Part': [
                        {
                          'id': 11,
                          'key': '/library/parts/11/file.mkv',
                          'Stream': <dynamic>[
                            {'id': 31, 'streamType': 3, 'index': 2, 'codec': 'dvb_teletext', 'language': 'English'},
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
        // The server answers direct-play-only, which is what refusing the burn looks like.
        return http.Response(
          jsonEncode({
            'MediaContainer': {'generalDecisionCode': 1000, 'transcodeDecisionCode': 1000},
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
        preferredSubtitleTrack: const SubtitlePreference.track(
          SubtitleTrack(id: 'source:31', codec: 'dvb_teletext', language: 'English'),
        ),
      ),
    );

    expect(result.playMethod, 'DirectPlay', reason: 'direct play is the route that can deliver it');
    expect(result.fallbackReason, isNotNull, reason: 'a dropped burn is a refusal to warn about, not a silent success');
  });

  test('a valid transcode is refused when it cannot carry the selected subtitle', () async {
    // The server happily transcodes the video, but the decision went out as `subtitles=none` because
    // `dvb_teletext` cannot be burned. Accepting that stream left the row selected with nothing
    // drawing it and no sidecar behind it, so the caption was simply gone.
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/42') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'Media': [
                    {
                      'id': 1,
                      'Part': [
                        {
                          'id': 11,
                          'key': '/library/parts/11/file.mkv',
                          'Stream': <dynamic>[
                            {'id': 31, 'streamType': 3, 'index': 2, 'codec': 'dvb_teletext', 'language': 'English'},
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
        // 1001 = the server will transcode. Without the refusal this is accepted outright.
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
        preferredSubtitleTrack: const SubtitlePreference.track(
          SubtitleTrack(id: 'source:31', codec: 'dvb_teletext', language: 'English'),
        ),
      ),
    );

    expect(result.isTranscoding, isFalse, reason: 'the stream could not carry the caption that was asked for');
    expect(result.playMethod, 'DirectPlay', reason: 'direct play lets the native player read it');
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

  test('image-based embedded subtitles are burned rather than sidecarred', () {
    final client = makeClient((_) async => http.Response('not used', 500));
    addTearDown(client.close);

    final tracks = [
      MediaSubtitleTrack(id: 401, index: 3, codec: 'pgs', languageCode: 'eng', selected: true, forced: false),
      MediaSubtitleTrack(id: 402, index: 4, codec: 'dvd_subtitle', languageCode: 'eng', selected: false, forced: false),
    ];

    expect(buildTranscodeSubtitles(client, tracks), isEmpty);

    final params = client.buildTranscodeParamsForTesting(
      ratingKey: '42',
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_3mbps,
      sessionIdentifier: 'session-id',
      transcodeSessionId: 'transcode-id',
      selectedSubtitleTrack: client.resolveTranscodeSubtitleTrackForTesting(mediaInfoWithSubtitles(tracks), null),
    );

    expect(params['subtitles'], 'burn');
    expect(params.containsKey('subtitleStreamID'), isFalse);
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

    test('fetchItem primes the row a transiently failing playback fetch falls back to (#1867)', () async {
      var failNetwork = false;
      final client = makeClient((request) async {
        if (failNetwork) {
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.connectionTimeout,
            message: 'connect timed out',
          );
        }
        return http.Response(jsonEncode(playableBody()), 200, headers: {'content-type': 'application/json'});
      });
      addTearDown(client.close);

      // Cold row: a connectivity blip at the transition surfaces as a
      // transient failure — this is the dead-end from the issue.
      failNetwork = true;
      await expectLater(
        client.getVideoPlaybackData('42'),
        throwsA(isA<MediaServerHttpException>().having((error) => error.isTransient, 'isTransient', isTrue)),
      );

      // Adjacency discovery primes the row through fetchItem: same cache key,
      // same full playback query shape.
      failNetwork = false;
      expect(await client.fetchItem('42'), isNotNull);

      // The same blip now falls back to the primed row and playback proceeds.
      failNetwork = true;
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
