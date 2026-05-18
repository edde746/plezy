import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/playback_initialization_types.dart';

JellyfinConnection _conn({String accessToken = 'tok-abc', String baseUrl = 'https://jf.example.com'}) =>
    JellyfinConnection(
      id: 'srv-1/user-1',
      baseUrl: baseUrl,
      serverName: 'Home',
      serverMachineId: 'srv-1',
      userId: 'user-1',
      userName: 'edde',
      accessToken: accessToken,
      deviceId: 'dev-xyz',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

/// URL-builder smoke tests. We can't unit-test a network round-trip without
/// spinning up a Jellyfin server, but the URL shape is a clear unit-of-work:
/// query parameters must include the right keys and the auth token. These
/// tests pin the contract so the next iteration of the player (Task 8 wiring)
/// has something to point at.
void main() {
  group('JellyfinClient URL builders', () {
    late JellyfinClient client;

    setUp(() async {
      client = await JellyfinClient.create(_conn());
    });

    tearDown(() {
      client.close();
    });

    test('buildDirectStreamUrl includes static flag, api_key, and device id', () {
      final url = client.buildDirectStreamUrl('item-99');
      final uri = Uri.parse(url);

      expect(uri.scheme, 'https');
      expect(uri.host, 'jf.example.com');
      expect(uri.path, '/Videos/item-99/stream');
      expect(uri.queryParameters['Static'], 'true');
      expect(uri.queryParameters['api_key'], 'tok-abc');
      expect(uri.queryParameters['DeviceId'], 'dev-xyz');
      expect(uri.queryParameters.containsKey('Container'), isFalse);
    });

    test('buildDirectStreamUrl appends Container when provided', () {
      final url = client.buildDirectStreamUrl('item-99', container: 'mp4');
      expect(Uri.parse(url).queryParameters['Container'], 'mp4');
    });

    test('buildDirectStreamUrl appends MediaSourceId when provided', () {
      // Items with multiple `MediaSources` need this param to disambiguate;
      // without it Jellyfin defaults to the primary source even if the URL's
      // {itemId} matches a non-primary.
      final url = client.buildDirectStreamUrl('item-99', mediaSourceId: 'src-2');
      expect(Uri.parse(url).queryParameters['MediaSourceId'], 'src-2');
    });

    test('buildDirectStreamUrl appends AudioStreamIndex when provided', () {
      final url = client.buildDirectStreamUrl('item-99', audioStreamIndex: 4);
      expect(Uri.parse(url).queryParameters['AudioStreamIndex'], '4');
    });

    test('buildDirectStreamUrl omits MediaSourceId by default', () {
      final url = client.buildDirectStreamUrl('item-99');
      expect(Uri.parse(url).queryParameters.containsKey('MediaSourceId'), isFalse);
    });

    test('buildDirectStreamUrl path-encodes reserved item id characters', () {
      final url = client.buildDirectStreamUrl('folder/item #1?x');
      expect(Uri.parse(url).path, '/Videos/folder%2Fitem%20%231%3Fx/stream');
    });

    test('fetchSortOptions exposes the broad Jellyfin sort set', () async {
      final sorts = await client.fetchSortOptions('lib-1');
      expect(sorts.map((sort) => sort.key).toList(), [
        'title',
        'rating',
        'criticRating',
        'addedAt',
        'lastViewedAt',
        'viewCount',
        'productionYear',
        'runtime',
        'officialRating',
        'originallyAvailableAt',
        'startDate',
        'airTime',
        'studio',
        'random',
      ]);
    });

    test('reportPlaybackProgress sends media source and stream indexes', () async {
      Uri? capturedUri;
      String? capturedBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;
          return http.Response('', 204);
        }),
      );
      addTearDown(scoped.close);

      await scoped.reportPlaybackProgress(
        itemId: 'item-1',
        position: const Duration(seconds: 12),
        duration: const Duration(seconds: 100),
        isPaused: true,
        playSessionId: 'play-1',
        playMethod: 'Transcode',
        mediaSourceId: 'source-1',
        audioStreamIndex: 2,
        subtitleStreamIndex: -1,
      );

      expect(capturedUri!.path, '/Sessions/Playing/Progress');
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['ItemId'], 'item-1');
      expect(body['MediaSourceId'], 'source-1');
      expect(body['AudioStreamIndex'], 2);
      expect(body['SubtitleStreamIndex'], -1);
      expect(body['PlaySessionId'], 'play-1');
      expect(body['PlayMethod'], 'Transcode');
      expect(body['IsPaused'], isTrue);
    });

    test('resolveDownload pins direct stream URL and subtitles to selected media source', () async {
      final requests = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {'Id': 'src-1', 'Container': 'mp4', 'MediaStreams': []},
                  {'Id': 'src-2', 'Container': 'mkv', 'MediaStreams': []},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'MediaSources': [
                  {'Id': 'src-1', 'MediaStreams': []},
                  {
                    'Id': 'src-2',
                    'MediaStreams': [
                      {
                        'Index': 3,
                        'Type': 'Subtitle',
                        'Codec': 'srt',
                        'Language': 'eng',
                        'DisplayLanguage': 'English',
                        'DisplayTitle': 'English - SRT',
                        'DeliveryMethod': 'External',
                        'DeliveryUrl': '/Videos/item-1/src-2/Subtitles/3/Stream.srt',
                      },
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final resolution = await scoped.resolveDownload(
        MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
        mediaIndex: 1,
      );

      final uri = Uri.parse(resolution.videoUrl!);
      expect(uri.queryParameters['MediaSourceId'], 'src-2');
      expect(uri.queryParameters['Container'], 'mkv');
      expect(requests.map((u) => u.path), contains('/Items/item-1/PlaybackInfo'));
      expect(resolution.externalSubtitles, hasLength(1));
      final subtitle = resolution.externalSubtitles.single;
      expect(subtitle.id, 3);
      expect(subtitle.language, 'English');
      expect(subtitle.languageCode, 'eng');
      final subtitleUri = Uri.parse(subtitle.url);
      expect(subtitleUri.path, '/Videos/item-1/src-2/Subtitles/3/Stream.srt');
      expect(subtitleUri.queryParameters['api_key'], 'tok-abc');
    });

    test('getPlaybackInitialization preserves PlaySessionId from TranscodingUrl', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {'Id': 'src-1', 'Container': 'mp4', 'MediaStreams': []},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'TranscodingUrl': '/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=play-session-1',
                    'MediaStreams': [
                      {'Index': 0, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng', 'DisplayTitle': 'English - AAC'},
                      {
                        'Index': 2,
                        'Type': 'Subtitle',
                        'Codec': 'srt',
                        'Language': 'eng',
                        'DisplayTitle': 'English - SRT',
                        'DeliveryMethod': 'External',
                        'DeliveryUrl': '/Videos/item-1/src-1/Subtitles/2/Stream.srt',
                      },
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.p720_2mbps,
        ),
      );

      expect(result.isTranscoding, isTrue);
      expect(result.playMethod, 'Transcode');
      expect(result.playSessionId, 'play-session-1');
      final uri = Uri.parse(result.videoUrl!);
      expect(uri.queryParameters['PlaySessionId'], 'play-session-1');
      expect(uri.queryParameters['api_key'], 'tok-abc');
      expect(result.mediaInfo!.subtitleTracks, hasLength(1));
      expect(result.externalSubtitles, hasLength(1));
      expect(result.externalSubtitles.single.title, 'English');
      expect(result.externalSubtitles.single.language, 'eng');
      final subtitleUri = Uri.parse(result.externalSubtitles.single.uri!);
      expect(subtitleUri.path, '/Videos/item-1/src-1/Subtitles/2/Stream.srt');
      expect(subtitleUri.queryParameters['api_key'], 'tok-abc');
    });

    test('getPlaybackInitialization uses negotiated DirectStreamUrl when transcode URL is absent', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {'Id': 'src-1', 'Container': 'mp4', 'MediaStreams': []},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'PlaySessionId': 'play-session-direct',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'DirectStreamUrl': '/Videos/item-1/stream?MediaSourceId=src-1&PlaySessionId=play-session-direct',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.p720_2mbps,
        ),
      );

      expect(result.isTranscoding, isFalse);
      expect(result.playMethod, 'DirectStream');
      expect(result.fallbackReason, isNull);
      expect(result.playSessionId, 'play-session-direct');
      final uri = Uri.parse(result.videoUrl!);
      expect(uri.path, '/Videos/item-1/stream');
      expect(uri.queryParameters['PlaySessionId'], 'play-session-direct');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('getPlaybackInitialization negotiates original playback and uses returned source media streams', () async {
      final requests = <Uri>[];
      String? playbackInfoBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'Container': 'mp4',
                    'MediaStreams': [
                      {'Index': 1, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng'},
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            playbackInfoBody = request.body;
            return http.Response(
              jsonEncode({
                'PlaySessionId': 'play-session-direct',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'Container': 'mp4',
                    'DefaultAudioStreamIndex': 1,
                    'DirectStreamUrl': '/Videos/item-1/stream?MediaSourceId=src-1&PlaySessionId=play-session-direct',
                    'MediaStreams': [
                      {'Index': 1, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng', 'DisplayTitle': 'English - AAC'},
                      {
                        'Index': 3,
                        'Type': 'Subtitle',
                        'Codec': 'srt',
                        'Language': 'eng',
                        'DisplayTitle': 'English - SRT',
                        'DeliveryMethod': 'External',
                        'DeliveryUrl': '/Videos/item-1/src-1/Subtitles/3/Stream.srt',
                      },
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
        ),
      );

      final playbackInfoRequest = requests.firstWhere((uri) => uri.path == '/Items/item-1/PlaybackInfo');
      expect(playbackInfoRequest.queryParameters.containsKey('MaxStreamingBitrate'), isFalse);
      expect(playbackInfoRequest.queryParameters['MediaSourceId'], 'src-1');
      final body = jsonDecode(playbackInfoBody!) as Map<String, dynamic>;
      expect(body.containsKey('MaxStreamingBitrate'), isFalse);
      final profile = body['DeviceProfile'] as Map<String, dynamic>;
      expect(profile.containsKey('MaxStreamingBitrate'), isFalse);

      expect(result.isTranscoding, isFalse);
      expect(result.playMethod, 'DirectStream');
      expect(result.playSessionId, 'play-session-direct');
      expect(result.activeAudioStreamId, isNull);
      expect(result.mediaInfo!.audioTracks.single.selected, isTrue);
      final uri = Uri.parse(result.videoUrl!);
      expect(uri.path, '/Videos/item-1/stream');
      expect(uri.queryParameters['PlaySessionId'], 'play-session-direct');
      expect(uri.queryParameters['api_key'], 'tok-abc');
      expect(result.mediaInfo!.subtitleTracks, hasLength(1));
      expect(result.externalSubtitles, hasLength(1));
      expect(result.externalSubtitles.single.title, 'English');
      final subtitleUri = Uri.parse(result.externalSubtitles.single.uri!);
      expect(subtitleUri.path, '/Videos/item-1/src-1/Subtitles/3/Stream.srt');
      expect(subtitleUri.queryParameters['api_key'], 'tok-abc');
    });

    test('selected external audio is sent to PlaybackInfo and fallback direct URL', () async {
      Uri? playbackInfoUri;
      String? playbackInfoBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'Container': 'mkv',
                    'MediaStreams': [
                      {'Index': 0, 'Type': 'Video'},
                      {'Index': 1, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng', 'IsDefault': true},
                      {'Index': 4, 'Type': 'Audio', 'Codec': 'flac', 'Language': 'jpn', 'DeliveryMethod': 'External'},
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            playbackInfoUri = request.url;
            playbackInfoBody = request.body;
            return http.Response('server unavailable', 500);
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
          selectedAudioStreamId: 4,
        ),
      );

      expect(playbackInfoUri!.queryParameters['AudioStreamIndex'], '4');
      final body = jsonDecode(playbackInfoBody!) as Map<String, dynamic>;
      expect(body['AudioStreamIndex'], 4);

      expect(result.playMethod, 'DirectPlay');
      expect(result.activeAudioStreamId, 4);
      final selected = result.mediaInfo!.audioTracks.singleWhere((track) => track.id == 4);
      expect(selected.isExternal, isTrue);
      expect(selected.selected, isTrue);
      final uri = Uri.parse(result.videoUrl!);
      expect(uri.queryParameters['AudioStreamIndex'], '4');
      expect(uri.queryParameters['MediaSourceId'], 'src-1');
      expect(uri.queryParameters['Container'], 'mkv');
    });

    test('stale selected audio stream is not sent for a source without that stream', () async {
      Uri? playbackInfoUri;
      String? playbackInfoBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'Container': 'mkv',
                    'MediaStreams': [
                      {'Index': 1, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng'},
                      {'Index': 4, 'Type': 'Audio', 'Codec': 'flac', 'Language': 'jpn'},
                    ],
                  },
                  {
                    'Id': 'src-2',
                    'Container': 'mp4',
                    'DefaultAudioStreamIndex': 8,
                    'MediaStreams': [
                      {'Index': 8, 'Type': 'Audio', 'Codec': 'aac', 'Language': 'eng'},
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            playbackInfoUri = request.url;
            playbackInfoBody = request.body;
            return http.Response('server unavailable', 500);
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 1,
          selectedAudioStreamId: 4,
        ),
      );

      expect(playbackInfoUri!.queryParameters.containsKey('AudioStreamIndex'), isFalse);
      final body = jsonDecode(playbackInfoBody!) as Map<String, dynamic>;
      expect(body.containsKey('AudioStreamIndex'), isFalse);

      expect(result.activeAudioStreamId, isNull);
      expect(result.mediaInfo!.audioTracks.single.selected, isTrue);
      final uri = Uri.parse(result.videoUrl!);
      expect(uri.queryParameters.containsKey('AudioStreamIndex'), isFalse);
      expect(uri.queryParameters['MediaSourceId'], 'src-2');
    });

    test('getPlaybackInfo path-encodes reserved item id characters', () async {
      Uri? capturedUri;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'MediaSources': []}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(scoped.close);

      await scoped.getPlaybackInfo('folder/item #1?x');

      expect(capturedUri.toString(), contains('/Items/folder%2Fitem%20%231%3Fx/PlaybackInfo'));
    });

    test('getPlaybackInfo advertises external subtitle support', () async {
      Uri? capturedUri;
      String? capturedBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;
          return http.Response(jsonEncode({'MediaSources': []}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(scoped.close);

      await scoped.getPlaybackInfo(
        'item-1',
        maxStreamingBitrate: 5000000,
        mediaSourceId: 'src-1',
        audioStreamIndex: 1,
        subtitleStreamIndex: 2,
      );

      expect(capturedUri!.queryParameters['MaxStreamingBitrate'], '5000000');
      expect(capturedUri!.queryParameters.containsKey('IsPlayback'), isFalse);
      expect(capturedUri!.queryParameters.containsKey('AutoOpenLiveStream'), isFalse);
      expect(capturedUri!.queryParameters['MediaSourceId'], 'src-1');
      expect(capturedUri!.queryParameters['AudioStreamIndex'], '1');
      expect(capturedUri!.queryParameters['SubtitleStreamIndex'], '2');

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      final profile = body['DeviceProfile'] as Map<String, dynamic>;
      expect(profile['MaxStreamingBitrate'], 5000000);
      expect(profile.containsKey('MaxStaticBitrate'), isFalse);
      expect(profile.containsKey('MusicStreamingTranscodingBitrate'), isFalse);
      expect(profile['DirectPlayProfiles'], isNotEmpty);
      final directPlayProfile = (profile['DirectPlayProfiles'] as List<dynamic>).first as Map<String, dynamic>;
      expect(directPlayProfile['VideoCodec'], contains('mpeg2video'));
      expect(directPlayProfile['AudioCodec'], contains('mp2'));
      expect(profile['TranscodingProfiles'], isNotEmpty);
      expect(profile['CodecProfiles'], isEmpty);
      final subtitleProfiles = profile['SubtitleProfiles'] as List<dynamic>;
      expect(
        subtitleProfiles.map((profile) => (profile as Map<String, dynamic>)['Format']),
        containsAll(['srt', 'ass', 'ssa', 'vtt', 'pgssub', 'dvdsub', 'dvbsub']),
      );
      expect(subtitleProfiles.every((profile) => (profile as Map<String, dynamic>)['Method'] == 'External'), isTrue);
    });

    test('path-encodes reserved ids for browse and watch-state endpoints', () async {
      final captured = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          captured.add(request.url);
          return http.Response(jsonEncode({'Items': <Object>[]}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(scoped.close);

      final item = MediaItem(
        id: 'folder/item #1?x',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-1',
      );

      try {
        await scoped.fetchChildren('folder/show #1?x');
      } catch (_) {
        // This URL-only test does not initialize JellyfinApiCache; fetchChildren
        // may fail after the request when it tries to cache the mock response.
      }
      await scoped.fetchClientSideEpisodeQueue('folder/show #1?x');
      await scoped.markWatched(item);
      await scoped.markUnwatched(item);
      await scoped.rate(item, 7);
      await scoped.rate(item, -1);

      final paths = captured.map((u) => u.path).toList();
      expect(paths, contains('/Shows/folder%2Fshow%20%231%3Fx/Seasons'));
      expect(paths, contains('/Shows/folder%2Fshow%20%231%3Fx/Episodes'));
      expect(paths, contains('/UserPlayedItems/folder%2Fitem%20%231%3Fx'));
      expect(paths.where((p) => p == '/UserPlayedItems/folder%2Fitem%20%231%3Fx'), hasLength(2));
      expect(paths.where((p) => p == '/UserItems/folder%2Fitem%20%231%3Fx/Rating'), hasLength(2));
    });

    test('removeFromContinueWatching is unsupported for Jellyfin and does not call the server', () async {
      var requested = false;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requested = true;
          return http.Response('', 500);
        }),
      );
      addTearDown(scoped.close);

      final item = MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1');

      await expectLater(scoped.removeFromContinueWatching(item), throwsA(isA<UnsupportedError>()));
      expect(requested, isFalse);
    });

    test('getPlaybackInitialization URL-encodes appended api_key', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(accessToken: 'tok+with spaces/?&'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {'Id': 'src-1', 'Container': 'mp4', 'MediaStreams': []},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items/item-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'MediaSources': [
                  {'Id': 'src-1', 'TranscodingUrl': '/Videos/item-1/master.m3u8?MediaSourceId=src-1'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.p720_2mbps,
        ),
      );

      expect(result.videoUrl, contains('api_key=tok%2Bwith+spaces%2F%3F%26'));
      expect(Uri.parse(result.videoUrl!).queryParameters['api_key'], 'tok+with spaces/?&');
    });

    test('getPlaybackInitialization builds fallback URL for external subtitle without DeliveryUrl', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'Container': 'mp4',
                    'MediaStreams': [
                      {'Index': 3, 'Type': 'Subtitle', 'Codec': 'srt', 'Language': 'eng', 'IsExternal': true},
                    ],
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
        ),
      );

      expect(result.externalSubtitles, hasLength(1));
      expect(result.playMethod, 'DirectPlay');
      final uri = Uri.parse(result.externalSubtitles.single.uri!);
      expect(uri.path, '/Videos/item-1/src-1/Subtitles/3/Stream.srt');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('live TV stream resolution opens a direct stream instead of HLS transcode', () async {
      final requests = <Uri>[];
      String? capturedBody;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          capturedBody = request.body;
          if (request.url.path == '/Items/channel-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'PlaySessionId': 'live-session-1',
                'MediaSources': [
                  {
                    'Id': 'source-1',
                    'Container': 'ts',
                    'LiveStreamId': 'open-stream-1',
                    'TranscodingUrl': '/Videos/channel-1/live.m3u8?PlaySessionId=live-session-1',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final resolution = await scoped.liveTv.resolveStreamUrl('channel-1');

      expect(requests.single.path, '/Items/channel-1/PlaybackInfo');
      expect(requests.single.queryParameters['AutoOpenLiveStream'], 'true');
      expect(requests.single.queryParameters['EnableTranscoding'], 'false');
      expect(requests.single.queryParameters['EnableDirectPlay'], 'true');
      expect(requests.single.queryParameters['EnableDirectStream'], 'true');
      expect(requests.single.queryParameters['AllowVideoStreamCopy'], 'true');
      expect(requests.single.queryParameters['AllowAudioStreamCopy'], 'true');
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['AutoOpenLiveStream'], isTrue);
      expect(body['EnableTranscoding'], isFalse);
      expect(resolution, isNotNull);
      expect(resolution!.playSessionId, 'live-session-1');
      final uri = Uri.parse(resolution.url);
      expect(uri.path, '/Videos/channel-1/stream');
      expect(uri.queryParameters['Static'], 'true');
      expect(uri.queryParameters['Container'], 'ts');
      expect(uri.queryParameters['MediaSourceId'], 'source-1');
      expect(uri.queryParameters['LiveStreamId'], 'open-stream-1');
      expect(uri.queryParameters['PlaySessionId'], 'live-session-1');
      expect(uri.queryParameters['DeviceId'], 'dev-xyz');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('buildTrickplayTileUrl wires width, sheet index, api_key, and DeviceId', () {
      final url = client.buildTrickplayTileUrl('item-99', 320, 4);
      final uri = Uri.parse(url);

      expect(uri.scheme, 'https');
      expect(uri.host, 'jf.example.com');
      expect(uri.path, '/Videos/item-99/Trickplay/320/4.jpg');
      expect(uri.queryParameters['api_key'], 'tok-abc');
      expect(uri.queryParameters['DeviceId'], 'dev-xyz');
      expect(uri.queryParameters.containsKey('MediaSourceId'), isFalse);
    });

    test('buildTrickplayTileUrl appends MediaSourceId when provided', () {
      // Multi-source items need the param; without it Jellyfin returns the
      // primary source's tiles even if the user picked a non-default version.
      final url = client.buildTrickplayTileUrl('item-99', 320, 0, mediaSourceId: 'src-2');
      expect(Uri.parse(url).queryParameters['MediaSourceId'], 'src-2');
    });

    test('buildTrickplayTileUrl URL-encodes special chars in itemId', () {
      final url = client.buildTrickplayTileUrl('item with spaces & chars', 160, 1);
      // Path segments are encoded once; the `+` form for spaces is also
      // valid per RFC 3986 — Uri.parse normalizes back to the original.
      expect(url, contains('/Videos/item%20with%20spaces%20%26%20chars/Trickplay/160/1.jpg'));
    });

    test('thumbnailUrl resolves a relative path against baseUrl with api_key', () {
      final url = client.thumbnailUrl('/Items/item-99/Images/Primary?tag=abc');
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'jf.example.com');
      expect(uri.path, '/Items/item-99/Images/Primary');
      expect(uri.queryParameters['tag'], 'abc');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('thumbnailUrl preserves reverse-proxy subpaths for relative artwork paths', () {
      final proxied = JellyfinClient.forTesting(
        connection: _conn(baseUrl: 'https://jf.example.com/jellyfin'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(proxied.close);

      final url = proxied.thumbnailUrl('/Items/item-99/Images/Primary?tag=abc');
      final uri = Uri.parse(url);

      expect(uri.path, '/jellyfin/Items/item-99/Images/Primary');
      expect(uri.queryParameters['tag'], 'abc');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('negotiated bare relative DirectStreamUrl preserves reverse-proxy subpaths', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(baseUrl: 'https://jf.example.com/jellyfin'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/jellyfin/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'Movie',
                'MediaSources': [
                  {'Id': 'src-1', 'Container': 'mp4', 'MediaStreams': []},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/jellyfin/Items/item-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'PlaySessionId': 'play-session-direct',
                'MediaSources': [
                  {
                    'Id': 'src-1',
                    'DirectStreamUrl': 'Videos/item-1/stream?MediaSourceId=src-1&PlaySessionId=play-session-direct',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: MediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1'),
          selectedMediaIndex: 0,
          qualityPreset: TranscodeQualityPreset.p720_2mbps,
        ),
      );

      final uri = Uri.parse(result.videoUrl!);
      expect(uri.path, '/jellyfin/Videos/item-1/stream');
      expect(uri.queryParameters['PlaySessionId'], 'play-session-direct');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('thumbnailUrl honours width/height hints', () {
      final url = client.thumbnailUrl('/Items/x/Images/Primary', width: 200, height: 300);
      final uri = Uri.parse(url);
      expect(uri.queryParameters['maxWidth'], '200');
      expect(uri.queryParameters['maxHeight'], '300');
    });

    test('thumbnailUrl does not prefix already absolute artwork URLs', () {
      final url = client.thumbnailUrl('https://jf.example.com/Items/x/Images/Primary?tag=abc', width: 200);
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'jf.example.com');
      expect(uri.path, '/Items/x/Images/Primary');
      expect(url, isNot(contains('https://jf.example.comhttps://jf.example.com')));
      expect(uri.queryParameters['tag'], 'abc');
      expect(uri.queryParameters['maxWidth'], '200');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('thumbnailUrl preserves existing auth and size parameters', () {
      final url = client.thumbnailUrl(
        'https://other.example/Items/x/Images/Primary?api_key=existing&maxWidth=100',
        width: 200,
        height: 300,
      );
      final uri = Uri.parse(url);
      expect(uri.host, 'other.example');
      expect(uri.queryParameters['api_key'], 'existing');
      expect(uri.queryParameters['maxWidth'], '100');
      expect(uri.queryParameters['maxHeight'], '300');
    });

    test('thumbnailUrl returns empty string for null/empty path', () {
      expect(client.thumbnailUrl(null), '');
      expect(client.thumbnailUrl(''), '');
    });

    test('every request carries the SDK-style MediaBrowser Authorization header', () {
      // Findroid + the official Jellyfin SDK send this exact header shape.
      // Some setups (Jellyfin 10.9+ behind reverse proxies) reject requests
      // that only carry the legacy X-Emby-Token header, returning a 404 from
      // the proxy/routing layer instead of a 401. We send both.
      final headers = client.defaultHeadersForTesting;

      final auth = headers['Authorization'];
      expect(auth, isNotNull);
      expect(auth, startsWith('MediaBrowser '));
      expect(auth, contains('Client="Plezy"'));
      expect(auth, contains('Device="Plezy"'));
      expect(auth, contains('DeviceId="dev-xyz"'));
      expect(auth, contains(RegExp(r'Version="[^"]+"')));
      expect(auth, contains('Token="tok-abc"'));

      // Belt-and-suspenders: legacy Emby token header is still present for
      // older servers that prefer it.
      expect(headers['X-Emby-Token'], 'tok-abc');
      expect(headers['Accept'], 'application/json');
    });

    test('fetchLibraryContent sends a bounded paged Items request', () async {
      Uri? captured;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured = req.url;
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Movie'},
              ],
              'TotalRecordCount': 123,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(scoped.close);

      final page = await scoped.fetchLibraryContent(
        'lib-1',
        const LibraryQuery(kind: MediaKind.movie, offset: 50, limit: 25),
      );

      expect(page.items.single.id, 'movie-1');
      expect(page.totalCount, 123);
      expect(captured, isNotNull);
      expect(captured!.path, '/Items');
      expect(captured!.queryParameters['ParentId'], 'lib-1');
      expect(captured!.queryParameters['StartIndex'], '50');
      expect(captured!.queryParameters['Limit'], '25');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'true');
      expect(captured!.queryParameters['IncludeItemTypes'], 'Movie');
      expect(captured!.queryParameters['Fields'], isNot(contains('MediaSources')));
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
    });

    test('fetchLibraryContent uses sentinel total fallback when server omits total', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          final start = int.parse(req.url.queryParameters['StartIndex'] ?? '0');
          final limit = int.parse(req.url.queryParameters['Limit'] ?? '25');
          return http.Response(
            jsonEncode({
              'Items': [
                for (var i = start; i < start + limit; i++) {'Id': 'movie-$i', 'Type': 'Movie', 'Name': 'Movie $i'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(scoped.close);

      final page = await scoped.fetchLibraryContent(
        'lib-1',
        const LibraryQuery(kind: MediaKind.movie, offset: 50, limit: 25),
      );

      expect(page.items.length, 25);
      expect(page.totalCount, 76);
    });

    test('fetchLibraryPagedContent uses library kind only when query kind is absent', () async {
      final captured = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured.add(req.url);
          return http.Response(
            jsonEncode({'Items': const [], 'TotalRecordCount': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(scoped.close);

      await scoped.fetchLibraryPagedContent(
        'lib-1',
        query: const LibraryQuery(offset: 0, limit: 20),
        libraryKind: MediaKind.show,
      );
      await scoped.fetchLibraryPagedContent(
        'lib-1',
        query: const LibraryQuery(kind: MediaKind.episode, offset: 0, limit: 20),
        libraryKind: MediaKind.show,
      );

      expect(captured.first.queryParameters['IncludeItemTypes'], 'Series');
      expect(captured[1].queryParameters['IncludeItemTypes'], 'Episode');
    });

    test('fetchClientSideEpisodeQueue pages past the first 200 episodes', () async {
      final starts = <String?>[];
      final pagedClient = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          starts.add(req.url.queryParameters['StartIndex']);
          final start = int.parse(req.url.queryParameters['StartIndex'] ?? '0');
          const total = 250;
          final end = (start + 200).clamp(0, total);
          final items = [
            for (var i = start; i < end; i++)
              {
                'Id': 'ep-$i',
                'Type': 'Episode',
                'Name': 'Episode $i',
                'SeriesId': 'show-1',
                'UserData': {'PlayCount': 0},
              },
          ];
          return http.Response(
            jsonEncode({'Items': items, 'TotalRecordCount': total}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(pagedClient.close);

      final result = await pagedClient.fetchClientSideEpisodeQueue('show-1');

      expect(result, hasLength(250));
      expect(starts, ['0', '200']);
    });

    test('fetchPersonMedia queries items by person id', () async {
      Uri? captured;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured = req.url;
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Movie'},
              ],
              'TotalRecordCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(scoped.close);

      final result = await scoped.fetchPersonMedia('person-1');

      expect(result.single.id, 'movie-1');
      expect(captured, isNotNull);
      expect(captured!.path, '/Items');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['PersonIds'], 'person-1');
      expect(captured!.queryParameters['IncludeItemTypes'], 'Movie,Series');
      expect(captured!.queryParameters['Recursive'], 'true');
      expect(captured!.queryParameters['SortBy'], 'PremiereDate,ProductionYear,SortName');
      expect(captured!.queryParameters['SortOrder'], 'Descending,Descending,Ascending');
      expect(captured!.queryParameters['CollapseBoxSetItems'], 'false');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
    });

    test('fetchItemWithOnDeck keeps resumable NextUp semantics for show detail lookup', () async {
      Uri? capturedNextUp;
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          if (req.url.path == '/Users/user-1/Items/show-1') {
            return http.Response(
              jsonEncode({'Id': 'show-1', 'Type': 'Series', 'Name': 'Show 1'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/Shows/NextUp') {
            capturedNextUp = req.url;
            return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      await scoped.fetchItemWithOnDeck('show-1');

      expect(capturedNextUp, isNotNull);
      expect(capturedNextUp!.queryParameters['seriesId'], 'show-1');
      expect(capturedNextUp!.queryParameters['Limit'], '1');
      expect(capturedNextUp!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(capturedNextUp!.queryParameters['ImageTypeLimit'], '1');
      expect(capturedNextUp!.queryParameters.containsKey('EnableResumable'), isFalse);
      expect(capturedNextUp!.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
    });

    test('fetchPlaybackExtras loads native Jellyfin media segments', () async {
      final requests = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requests.add(req.url);
          if (req.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({'Id': 'item-1', 'Type': 'Episode', 'Name': 'Episode', 'Chapters': []}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/MediaSegments/item-1') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Type': 'Intro', 'StartTicks': 50000000, 'EndTicks': 450000000},
                  {'Type': 'Outro', 'StartTicks': 900000000, 'EndTicks': 1000000000},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      final extras = await scoped.fetchPlaybackExtras('item-1');

      expect(requests.map((uri) => uri.path), contains('/MediaSegments/item-1'));
      expect(extras.markers.map((m) => m.type), ['intro', 'credits']);
      expect(extras.markers.first.startTimeOffset, 5000);
      expect(extras.markers.first.endTimeOffset, 45000);
    });

    test('fetchPlaybackExtras falls back to OP/ED chapters when media segments are unavailable', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          if (req.url.path == '/Users/user-1/Items/item-1') {
            return http.Response(
              jsonEncode({
                'Id': 'item-1',
                'Type': 'Episode',
                'Name': 'Episode',
                'RunTimeTicks': 1200000000,
                'Chapters': [
                  {'Name': 'OP', 'StartPositionTicks': 100000000},
                  {'Name': 'Episode', 'StartPositionTicks': 450000000},
                  {'Name': 'ED', 'StartPositionTicks': 900000000},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/MediaSegments/item-1') {
            return http.Response('not found', 404);
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      final extras = await scoped.fetchPlaybackExtras('item-1');

      expect(extras.markers.map((m) => m.type), ['intro', 'credits']);
      expect(extras.markers.first.endTimeOffset, 45000);
      expect(extras.markers.last.endTimeOffset, 120000);
    });

    test('fetchContinueWatching merges resume with non-resumable Next Up', () async {
      final requests = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requests.add(req.url);
          if (req.url.path == '/UserItems/Resume') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'resume-show-1', 'Type': 'Episode', 'Name': 'Resume Show 1', 'SeriesId': 'show-1'},
                  {'Id': 'resume-movie-1', 'Type': 'Movie', 'Name': 'Resume Movie 1'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/Shows/NextUp') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'next-show-1', 'Type': 'Episode', 'Name': 'Next Show 1', 'SeriesId': 'show-1'},
                  {'Id': 'next-show-2', 'Type': 'Episode', 'Name': 'Next Show 2', 'SeriesId': 'show-2'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      final items = await scoped.fetchContinueWatching(count: 3);

      expect(items.map((item) => item.id), ['resume-show-1', 'resume-movie-1', 'next-show-2']);
      final resume = requests.singleWhere((uri) => uri.path == '/UserItems/Resume');
      expect(resume.queryParameters['userId'], 'user-1');
      expect(resume.queryParameters['Limit'], '3');
      expect(resume.queryParameters['MediaTypes'], 'Video');
      expect(resume.queryParameters['Recursive'], 'true');
      expect(resume.queryParameters['EnableTotalRecordCount'], 'false');
      expect(resume.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(resume.queryParameters['ImageTypeLimit'], '1');
      final nextUp = requests.singleWhere((uri) => uri.path == '/Shows/NextUp');
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '3');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
      expect(nextUp.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(nextUp.queryParameters['ImageTypeLimit'], '1');
      expect(nextUp.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
    });

    test('fetchContinueWatching keeps resume items when Next Up fails', () async {
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          if (req.url.path == '/UserItems/Resume') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'resume-movie-1', 'Type': 'Movie', 'Name': 'Resume Movie 1'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/Shows/NextUp') {
            return http.Response('server error', 500);
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      final items = await scoped.fetchContinueWatching();

      expect(items.map((item) => item.id), ['resume-movie-1']);
    });

    test('fetchContinueWatching omits Limit when count is null', () async {
      final requests = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requests.add(req.url);
          if (req.url.path == '/UserItems/Resume') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'resume-movie-1', 'Type': 'Movie', 'Name': 'Resume Movie 1'},
                  {'Id': 'resume-movie-2', 'Type': 'Movie', 'Name': 'Resume Movie 2'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path == '/Shows/NextUp') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'next-show-1', 'Type': 'Episode', 'Name': 'Next Show 1', 'SeriesId': 'show-1'},
                  {'Id': 'next-show-2', 'Type': 'Episode', 'Name': 'Next Show 2', 'SeriesId': 'show-2'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(scoped.close);

      final items = await scoped.fetchContinueWatching(count: null);

      expect(items.map((item) => item.id), ['resume-movie-1', 'resume-movie-2', 'next-show-1', 'next-show-2']);
      final resume = requests.singleWhere((uri) => uri.path == '/UserItems/Resume');
      expect(resume.queryParameters.containsKey('Limit'), isFalse);
      final nextUp = requests.singleWhere((uri) => uri.path == '/Shows/NextUp');
      expect(nextUp.queryParameters.containsKey('Limit'), isFalse);
    });
  });

  group('JellyfinClient.fetchGlobalHubs URL builders', () {
    late List<Uri> captured;

    JellyfinClient buildClient() {
      captured = [];
      final mock = MockClient((req) async {
        captured.add(req.url);
        return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
      });
      return JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
    }

    Uri capturedNextUpRequest() => captured.singleWhere((uri) => uri.path == '/Shows/NextUp');

    test('global Next Up excludes resumable episodes without date cutoff', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchGlobalHubs(limit: 12);

      final resume = captured.singleWhere((uri) => uri.path == '/UserItems/Resume');
      expect(resume.queryParameters['EnableTotalRecordCount'], 'false');

      final nextUp = capturedNextUpRequest();
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '12');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
      expect(nextUp.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(nextUp.queryParameters['ImageTypeLimit'], '1');
      expect(nextUp.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
    });

    test('can skip global playback hubs', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchGlobalHubs(limit: 12, includePlaybackHubs: false);

      expect(captured.map((uri) => uri.path), ['/Users/user-1/Items/Latest']);
      expect(captured.single.queryParameters['IncludeItemTypes'], 'Movie,Series,Episode');
      expect(captured.single.queryParameters['Limit'], '12');
    });
  });

  group('JellyfinClient.fetchLibraryHubs URL builders', () {
    late List<Uri> captured;

    JellyfinClient buildClient() {
      captured = [];
      final mock = MockClient((req) async {
        captured.add(req.url);
        return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
      });
      return JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
    }

    test('show library Next Up excludes resumable episodes without date cutoff', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchLibraryHubs('lib-99', libraryName: 'Shows', limit: 12, libraryKind: MediaKind.show);

      final nextUp = captured.singleWhere((uri) => uri.path == '/Shows/NextUp');
      expect(nextUp.queryParameters['ParentId'], 'lib-99');
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '12');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
      expect(nextUp.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(nextUp.queryParameters['ImageTypeLimit'], '1');
      expect(nextUp.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
    });

    test('movie library skips Next Up and disables resume total count', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchLibraryHubs('lib-99', libraryName: 'Movies', limit: 12, libraryKind: MediaKind.movie);

      expect(captured.where((uri) => uri.path == '/Shows/NextUp'), isEmpty);
      final resume = captured.singleWhere((uri) => uri.path == '/UserItems/Resume');
      expect(resume.queryParameters['ParentId'], 'lib-99');
      expect(resume.queryParameters['Limit'], '12');
      expect(resume.queryParameters['EnableTotalRecordCount'], 'false');
    });

    test('can skip library playback hubs', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchLibraryHubs('lib-99', libraryName: 'Movies', limit: 12, includePlaybackHubs: false);

      expect(captured.map((uri) => uri.path), ['/Users/user-1/Items/Latest']);
      expect(captured.single.queryParameters['ParentId'], 'lib-99');
      expect(captured.single.queryParameters['Limit'], '12');
    });
  });

  group('JellyfinClient.fetchMoreHubItems URL builders', () {
    Uri? captured;

    JellyfinClient buildClient() {
      captured = null;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });
      return JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
    }

    test('global "home.recent" hits /Users/{userId}/Items/Latest with provided limit', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('home.recent', limit: 80);

      expect(captured, isNotNull);
      expect(captured!.path, '/Users/user-1/Items/Latest');
      expect(captured!.queryParameters['Limit'], '80');
      expect(captured!.queryParameters['IncludeItemTypes'], 'Movie,Series,Episode');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      expect(captured!.queryParameters.containsKey('ParentId'), isFalse);
      client.close();
    });

    test('global "home.continue" hits /UserItems/Resume with userId', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('home.continue');

      expect(captured, isNotNull);
      expect(captured!.path, '/UserItems/Resume');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['Limit'], '50');
      expect(captured!.queryParameters['StartIndex'], '0');
      expect(captured!.queryParameters['MediaTypes'], 'Video');
      expect(captured!.queryParameters['Recursive'], 'true');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'true');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      expect(captured!.queryParameters.containsKey('ParentId'), isFalse);
      client.close();
    });

    test('global "home.nextup" hits /Shows/NextUp with userId', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('home.nextup', limit: 25);

      expect(captured, isNotNull);
      expect(captured!.path, '/Shows/NextUp');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['Limit'], '25');
      expect(captured!.queryParameters['StartIndex'], '0');
      expect(captured!.queryParameters.containsKey('ParentId'), isFalse);
      expect(captured!.queryParameters['EnableResumable'], 'false');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'true');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      expect(captured!.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
      client.close();
    });

    test('library-scoped "library.{id}.recent" forwards ParentId to Latest', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('library.lib-99.recent', limit: 30);

      expect(captured, isNotNull);
      expect(captured!.path, '/Users/user-1/Items/Latest');
      expect(captured!.queryParameters['ParentId'], 'lib-99');
      expect(captured!.queryParameters['Limit'], '30');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      // ParentId-scoped Latest should NOT also pin IncludeItemTypes (the
      // library already constrains the kinds returned).
      expect(captured!.queryParameters.containsKey('IncludeItemTypes'), isFalse);
      client.close();
    });

    test('library-scoped "library.{id}.continue" forwards ParentId to Resume', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('library.lib-99.continue');

      expect(captured, isNotNull);
      expect(captured!.path, '/UserItems/Resume');
      expect(captured!.queryParameters['ParentId'], 'lib-99');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['StartIndex'], '0');
      expect(captured!.queryParameters['Recursive'], 'true');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'true');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      client.close();
    });

    test('library-scoped "library.{id}.nextup" forwards ParentId to NextUp', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('library.lib-99.nextup');

      expect(captured, isNotNull);
      expect(captured!.path, '/Shows/NextUp');
      expect(captured!.queryParameters['ParentId'], 'lib-99');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['StartIndex'], '0');
      expect(captured!.queryParameters['EnableResumable'], 'false');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'true');
      expect(captured!.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(captured!.queryParameters['ImageTypeLimit'], '1');
      expect(captured!.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
      client.close();
    });

    test('unknown identifier returns empty without hitting the network', () async {
      final client = buildClient();
      final items = await client.fetchMoreHubItems('totally.unknown');

      expect(items, isEmpty);
      expect(captured, isNull);
      client.close();
    });

    test('paged Resume hub sends requested offset and parses total count', () async {
      Uri? requestUri;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requestUri = req.url;
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 30,
              'Items': [
                {'Id': 'resume-20', 'Name': 'Resume', 'Type': 'Movie'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);

      final page = await client.fetchMoreHubItemsPage('home.continue', start: 20, size: 10);

      expect(page.items.single.id, 'resume-20');
      expect(page.totalCount, 30);
      expect(page.offset, 20);
      expect(requestUri, isNotNull);
      expect(requestUri!.path, '/UserItems/Resume');
      expect(requestUri!.queryParameters['StartIndex'], '20');
      expect(requestUri!.queryParameters['Limit'], '10');
      expect(requestUri!.queryParameters['EnableTotalRecordCount'], 'true');
    });

    test('Latest hub is treated as a single page when offset is requested', () async {
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requestCount++;
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);

      final page = await client.fetchMoreHubItemsPage('home.recent', start: 20, size: 10);

      expect(page.items, isEmpty);
      expect(page.totalCount, 20);
      expect(page.offset, 20);
      expect(requestCount, 0);
    });

    test('paged hub first-page errors throw while list helper keeps empty fallback', () async {
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requestCount++;
          return http.Response('server error', 500);
        }),
      );
      addTearDown(client.close);

      await expectLater(client.fetchMoreHubItemsPage('home.continue', start: 0, size: 10), throwsA(isA<Exception>()));

      final items = await client.fetchMoreHubItems('home.continue');
      expect(items, isEmpty);
      expect(requestCount, 2);
    });

    test('paged hub later-page errors throw instead of truncating', () async {
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          requestCount++;
          return http.Response('server error', 500);
        }),
      );
      addTearDown(client.close);

      await expectLater(client.fetchMoreHubItemsPage('home.continue', start: 20, size: 10), throwsA(isA<Exception>()));

      expect(requestCount, 1);
    });
  });

  group('JellyfinClient.fetchCollections', () {
    test('uses boxsets view instead of selected media library parent', () async {
      final requests = <Uri>[];
      final mock = MockClient((req) async {
        requests.add(req.url);
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies'},
                {'Id': 'lib-boxsets', 'Name': 'Collections', 'CollectionType': 'boxsets'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/Items') {
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 1,
              'Items': [
                {'Id': 'collection-1', 'Name': 'Collection 1', 'Type': 'BoxSet'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final collections = await client.fetchCollections('lib-movies');

      expect(collections.map((c) => c.id).toList(), ['collection-1']);
      expect(collections.single.kind, MediaKind.collection);
      expect(requests.map((u) => u.path).toList(), ['/Users/user-1/Views', '/Items']);
      final itemsRequest = requests.singleWhere((u) => u.path == '/Items');
      expect(itemsRequest.queryParameters['ParentId'], 'lib-boxsets');
      expect(itemsRequest.queryParameters['ParentId'], isNot('lib-movies'));
      expect(itemsRequest.queryParameters['IncludeItemTypes'], 'BoxSet');
      expect(itemsRequest.queryParameters['Recursive'], 'true');
      expect(itemsRequest.queryParameters['StartIndex'], '0');
      expect(itemsRequest.queryParameters['Limit'], '36');
      expect(itemsRequest.queryParameters['SortBy'], 'SortName');
      expect(itemsRequest.queryParameters['SortOrder'], 'Ascending');
      expect(
        itemsRequest.queryParameters['Fields'],
        'RecursiveItemCount,ChildCount,UserData,PremiereDate,OriginalTitle,SortName,Overview',
      );
      expect(itemsRequest.queryParameters.containsKey('EnableTotalRecordCount'), isFalse);
      expect(itemsRequest.queryParameters['EnableImageTypes'], 'Primary,Backdrop,Thumb,Logo');
      expect(itemsRequest.queryParameters['ImageTypeLimit'], '1');
    });

    test('fetchCollectionsPage uses requested collection page bounds', () async {
      Uri? itemsRequest;
      final mock = MockClient((req) async {
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'lib-boxsets', 'Name': 'Collections', 'CollectionType': 'boxsets'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/Items') {
          itemsRequest = req.url;
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 30,
              'Items': [
                {'Id': 'collection-20', 'Name': 'Collection 20', 'Type': 'BoxSet'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchCollectionsPage('lib-movies', start: 20, size: 10);

      expect(page.totalCount, 30);
      expect(page.offset, 20);
      expect(page.items.single.id, 'collection-20');
      expect(itemsRequest, isNotNull);
      expect(itemsRequest!.queryParameters['ParentId'], 'lib-boxsets');
      expect(itemsRequest!.queryParameters['StartIndex'], '20');
      expect(itemsRequest!.queryParameters['Limit'], '10');
      expect(itemsRequest!.queryParameters.containsKey('EnableTotalRecordCount'), isFalse);
    });

    test('fetchCollectionsPage uses sentinel total when total count is missing', () async {
      final mock = MockClient((req) async {
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'lib-boxsets', 'Name': 'Collections', 'CollectionType': 'boxsets'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/Items') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'collection-1', 'Name': 'Collection 1', 'Type': 'BoxSet'},
                {'Id': 'collection-2', 'Name': 'Collection 2', 'Type': 'BoxSet'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchCollectionsPage('lib-movies', size: 2);

      expect(page.items.map((c) => c.id).toList(), ['collection-1', 'collection-2']);
      expect(page.totalCount, 3);
    });

    test('walks boxsets view in pages', () async {
      final itemRequests = <Uri>[];
      final mock = MockClient((req) async {
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'lib-boxsets', 'Name': 'Collections', 'CollectionType': 'boxsets'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/Items') {
          itemRequests.add(req.url);
          final start = req.url.queryParameters['StartIndex'];
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 2,
              'Items': [
                {'Id': start == '0' ? 'collection-1' : 'collection-2', 'Name': 'Collection', 'Type': 'BoxSet'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final collections = await client.fetchCollections('lib-movies');

      expect(collections.map((c) => c.id).toList(), ['collection-1', 'collection-2']);
      expect(itemRequests.map((u) => u.queryParameters['StartIndex']).toList(), ['0', '1']);
      expect(itemRequests.every((u) => u.queryParameters['Limit'] == '36'), isTrue);
    });

    test('returns empty when boxsets view is missing', () async {
      var itemsRequested = false;
      final mock = MockClient((req) async {
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/Items') {
          itemsRequested = true;
          return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final collections = await client.fetchCollections('lib-movies');

      expect(collections, isEmpty);
      expect(itemsRequested, isFalse);
    });

    test('fetchCollectionPage uses Jellyfin item paging', () async {
      Uri? itemsRequest;
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          itemsRequest = req.url;
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 25,
              'Items': [
                {'Id': 'movie-1', 'Name': 'Movie 1', 'Type': 'Movie'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchCollectionPage('collection-1', start: 20, size: 5);

      expect(page.totalCount, 25);
      expect(page.offset, 20);
      expect(page.items.single.id, 'movie-1');
      expect(itemsRequest, isNotNull);
      expect(itemsRequest!.queryParameters['ParentId'], 'collection-1');
      expect(itemsRequest!.queryParameters['StartIndex'], '20');
      expect(itemsRequest!.queryParameters['Limit'], '5');
      expect(itemsRequest!.queryParameters.containsKey('Recursive'), isFalse);
    });
  });

  group('JellyfinClient.fetchLibraries view filtering', () {
    test('drops boxsets and playlists views — they surface as per-library tabs instead', () async {
      // Jellyfin's `/Users/{userId}/Views` returns the user's collection
      // (BoxSet) and playlist roots as top-level "library" views. Surfacing
      // them in the library list duplicates content that's already exposed as
      // tabs on each real library, matching the Plex shape.
      final mock = MockClient((req) async {
        if (req.url.path == '/Users/user-1/Views') {
          return http.Response(
            '''
            {
              "Items": [
                {"Id": "lib-movies", "Name": "Movies", "CollectionType": "movies", "Type": "CollectionFolder"},
                {"Id": "lib-shows", "Name": "TV Shows", "CollectionType": "tvshows", "Type": "CollectionFolder"},
                {"Id": "lib-music", "Name": "Music", "CollectionType": "music", "Type": "CollectionFolder"},
                {"Id": "lib-coll", "Name": "Collections", "CollectionType": "boxsets", "Type": "CollectionFolder"},
                {"Id": "lib-pl", "Name": "Playlists", "CollectionType": "playlists", "Type": "ManualPlaylistsFolder"}
              ]
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);

      final libraries = await client.fetchLibraries();

      expect(libraries.map((l) => l.id), ['lib-movies', 'lib-shows', 'lib-music']);
      client.close();
    });
  });

  group('JellyfinClient paged media lists', () {
    test('fetchPersonMediaPage uses requested page bounds', () async {
      Uri? requestUri;
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          requestUri = req.url;
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'movie-1', 'Name': 'Movie', 'Type': 'Movie'},
              ],
              'TotalRecordCount': 40,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPersonMediaPage('person-1', start: 20, size: 10);

      expect(page.items.single.id, 'movie-1');
      expect(page.totalCount, 40);
      expect(page.offset, 20);
      expect(requestUri, isNotNull);
      expect(requestUri!.queryParameters['PersonIds'], 'person-1');
      expect(requestUri!.queryParameters['StartIndex'], '20');
      expect(requestUri!.queryParameters['Limit'], '10');
    });

    test('fetchPlayableDescendantsPage uses requested page bounds', () async {
      Uri? requestUri;
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          requestUri = req.url;
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'episode-1', 'Name': 'Episode', 'Type': 'Episode'},
              ],
              'TotalRecordCount': 40,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPlayableDescendantsPage('show-1', start: 20, size: 10);

      expect(page.items.single.id, 'episode-1');
      expect(page.totalCount, 40);
      expect(page.offset, 20);
      expect(requestUri, isNotNull);
      expect(requestUri!.queryParameters['ParentId'], 'show-1');
      expect(requestUri!.queryParameters['Recursive'], 'true');
      expect(requestUri!.queryParameters['IncludeItemTypes'], 'Movie,Episode');
      expect(requestUri!.queryParameters['StartIndex'], '20');
      expect(requestUri!.queryParameters['Limit'], '10');
    });

    test('fetchChildren walks generic children pages', () async {
      final itemRequests = <Uri>[];
      final mock = MockClient((req) async {
        if (req.url.path == '/Shows/season-1/Seasons') {
          return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
        }
        if (req.url.path == '/Items') {
          itemRequests.add(req.url);
          final start = int.parse(req.url.queryParameters['StartIndex'] ?? '0');
          final count = start == 0 ? 500 : 1;
          return http.Response(
            jsonEncode({
              'Items': List.generate(
                count,
                (i) => {'Id': 'episode-${start + i}', 'Name': 'Episode', 'Type': 'Episode'},
              ),
              'TotalRecordCount': 501,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final items = await client.fetchChildren('season-1');

      expect(items.length, 501);
      expect(itemRequests.map((u) => u.queryParameters['StartIndex']), ['0', '500']);
      expect(itemRequests.every((u) => u.queryParameters['Limit'] == '500'), isTrue);
    });
  });

  group('JellyfinClient.fetchPlaylists filtering', () {
    JellyfinClient buildClient() {
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          final requestedMediaType = req.url.queryParameters['MediaTypes']?.toLowerCase();
          final items =
              [
                {'Id': 'video-1', 'Name': 'Video Playlist', 'Type': 'Playlist', 'MediaType': 'Video'},
                {'Id': 'audio-1', 'Name': 'Audio Playlist', 'Type': 'Playlist', 'MediaType': 'Audio'},
                {'Id': 'photo-1', 'Name': 'Photo Playlist', 'Type': 'Playlist', 'MediaType': 'Photo'},
              ].where((item) {
                if (requestedMediaType == null) return true;
                return (item['MediaType'] as String).toLowerCase() == requestedMediaType;
              }).toList();
          return http.Response(
            jsonEncode({'Items': items, 'TotalRecordCount': items.length}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      return JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
    }

    test('returns only requested playlist media type', () async {
      final client = buildClient();

      final playlists = await client.fetchPlaylists(playlistType: 'video');

      expect(playlists.map((p) => p.id), ['video-1']);
      client.close();
    });

    test('fetchPlaylistsPage uses filtered playlist offsets', () async {
      final requests = <Uri>[];
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          requests.add(req.url);
          final start = int.parse(req.url.queryParameters['StartIndex'] ?? '0');
          return http.Response(
            jsonEncode({
              'Items': List.generate(
                10,
                (i) => {'Id': 'video-${start + i}', 'Name': 'Video Playlist', 'Type': 'Playlist', 'MediaType': 'Video'},
              ),
              'TotalRecordCount': 50,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPlaylistsPage(playlistType: 'video', start: 20, size: 10);

      expect(page.items.map((item) => item.id), List.generate(10, (i) => 'video-${20 + i}'));
      expect(page.totalCount, 31);
      expect(page.offset, 20);
      expect(requests.map((uri) => uri.queryParameters['StartIndex']), ['0', '10', '20']);
      expect(requests.every((uri) => uri.queryParameters['IncludeItemTypes'] == 'Playlist'), isTrue);
      expect(requests.every((uri) => uri.queryParameters.containsKey('MediaTypes')), isFalse);
      expect(requests.every((uri) => uri.queryParameters['Limit'] == '10'), isTrue);
    });

    test('fetchPlaylistsPage filters playlist type client-side', () async {
      final requests = <Uri>[];
      final allItems = [
        {'Id': 'audio-1', 'Name': 'Audio Playlist', 'Type': 'Playlist', 'MediaType': 'Audio'},
        {'Id': 'video-1', 'Name': 'Video Playlist', 'Type': 'Playlist', 'MediaType': 'Video'},
        {'Id': 'audio-2', 'Name': 'Audio Playlist', 'Type': 'Playlist', 'MediaType': 'Audio'},
        {'Id': 'video-2', 'Name': 'Video Playlist', 'Type': 'Playlist', 'MediaType': 'Video'},
      ];
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          requests.add(req.url);
          final start = int.parse(req.url.queryParameters['StartIndex'] ?? '0');
          final limit = int.parse(req.url.queryParameters['Limit'] ?? '2');
          return http.Response(
            jsonEncode({'Items': allItems.skip(start).take(limit).toList(), 'TotalRecordCount': allItems.length}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPlaylistsPage(playlistType: 'video', start: 0, size: 2);

      expect(page.items.map((item) => item.id), ['video-1', 'video-2']);
      expect(page.totalCount, 2);
      expect(requests.map((uri) => uri.queryParameters['StartIndex']), ['0', '2']);
    });

    test('fetchPlaylistPage uses requested item page bounds', () async {
      Uri? requestUri;
      final mock = MockClient((req) async {
        if (req.url.path == '/Playlists/pl-1/Items') {
          requestUri = req.url;
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'movie-1', 'Name': 'Movie', 'Type': 'Movie'},
              ],
              'TotalRecordCount': 40,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPlaylistPage('pl-1', start: 20, size: 10);

      expect(page.items.single.id, 'movie-1');
      expect(page.totalCount, 40);
      expect(page.offset, 20);
      expect(requestUri, isNotNull);
      expect(requestUri!.queryParameters['StartIndex'], '20');
      expect(requestUri!.queryParameters['Limit'], '10');
    });

    test('fetchPlaylistPage uses minimal fallback total when total count is missing', () async {
      final mock = MockClient((req) async {
        if (req.url.path == '/Playlists/pl-1/Items') {
          return http.Response(
            jsonEncode({
              'Items': List.generate(10, (i) => {'Id': 'movie-$i', 'Name': 'Movie', 'Type': 'Movie'}),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(connection: _conn(), httpClient: mock);
      addTearDown(client.close);

      final page = await client.fetchPlaylistPage('pl-1', start: 20, size: 10);

      expect(page.items.length, 10);
      expect(page.totalCount, 31);
      expect(page.offset, 20);
    });

    test('absolutizes playlist thumbnail artwork with reverse-proxy subpath', () async {
      final mock = MockClient((req) async {
        if (req.url.path == '/jellyfin/Items') {
          return http.Response(
            jsonEncode({
              'Items': [
                {
                  'Id': 'video-1',
                  'Name': 'Video Playlist',
                  'Type': 'Playlist',
                  'MediaType': 'Video',
                  'ImageTags': {'Primary': 'tag 1'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final client = JellyfinClient.forTesting(
        connection: _conn(baseUrl: 'https://jf.example.com/jellyfin'),
        httpClient: mock,
      );
      addTearDown(client.close);

      final playlists = await client.fetchPlaylists(playlistType: 'video');
      final uri = Uri.parse(playlists.single.thumbPath!);

      expect(uri.path, '/jellyfin/Items/video-1/Images/Primary');
      expect(uri.queryParameters['tag'], 'tag 1');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('smart=true returns empty because Jellyfin playlists are normal playlists', () async {
      final client = buildClient();

      final playlists = await client.fetchPlaylists(playlistType: 'video', smart: true);

      expect(playlists, isEmpty);
      client.close();
    });
  });
}
