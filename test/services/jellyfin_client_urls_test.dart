import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
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

    test('buildDirectStreamUrl omits MediaSourceId by default', () {
      final url = client.buildDirectStreamUrl('item-99');
      expect(Uri.parse(url).queryParameters.containsKey('MediaSourceId'), isFalse);
    });

    test('buildDirectStreamUrl path-encodes reserved item id characters', () {
      final url = client.buildDirectStreamUrl('folder/item #1?x');
      expect(Uri.parse(url).path, '/Videos/folder%2Fitem%20%231%3Fx/stream');
    });

    test('buildHlsStreamUrl wires required + optional params', () {
      final url = client.buildHlsStreamUrl(
        'item-42',
        mediaSourceId: 'src-1',
        videoBitrate: 5000000,
        audioStreamIndex: 1,
        subtitleStreamIndex: 2,
        playSessionId: 'sess-01',
      );
      final uri = Uri.parse(url);

      expect(uri.path, '/Videos/item-42/master.m3u8');
      expect(uri.queryParameters['MediaSourceId'], 'src-1');
      expect(uri.queryParameters['VideoBitrate'], '5000000');
      expect(uri.queryParameters['AudioStreamIndex'], '1');
      expect(uri.queryParameters['SubtitleStreamIndex'], '2');
      expect(uri.queryParameters['PlaySessionId'], 'sess-01');
      expect(uri.queryParameters['DeviceId'], 'dev-xyz');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('buildHlsStreamUrl omits null optional params', () {
      final url = client.buildHlsStreamUrl('item-42', mediaSourceId: 'src-1');
      final uri = Uri.parse(url);

      expect(uri.queryParameters['MediaSourceId'], 'src-1');
      expect(uri.queryParameters.containsKey('VideoBitrate'), isFalse);
      expect(uri.queryParameters.containsKey('AudioStreamIndex'), isFalse);
      expect(uri.queryParameters.containsKey('SubtitleStreamIndex'), isFalse);
      expect(uri.queryParameters.containsKey('PlaySessionId'), isFalse);
    });

    test('buildHlsStreamUrl path-encodes reserved item id characters', () {
      final url = client.buildHlsStreamUrl('folder/item #1?x', mediaSourceId: 'src-1');
      expect(Uri.parse(url).path, '/Videos/folder%2Fitem%20%231%3Fx/master.m3u8');
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

    test('resolveDownload pins direct stream URL to selected media source', () async {
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
                  {'Id': 'src-2', 'MediaStreams': []},
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
                    'MediaStreams': [],
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
      await scoped.removeFromContinueWatching(item);
      await scoped.rate(item, 7);
      await scoped.rate(item, -1);

      final paths = captured.map((u) => u.path).toList();
      expect(paths, contains('/Shows/folder%2Fshow%20%231%3Fx/Seasons'));
      expect(paths, contains('/Shows/folder%2Fshow%20%231%3Fx/Episodes'));
      expect(paths, contains('/UserPlayedItems/folder%2Fitem%20%231%3Fx'));
      expect(paths.where((p) => p == '/UserPlayedItems/folder%2Fitem%20%231%3Fx'), hasLength(2));
      expect(paths, contains('/UserItems/folder%2Fitem%20%231%3Fx/HideFromResume'));
      expect(paths.where((p) => p == '/UserItems/folder%2Fitem%20%231%3Fx/Rating'), hasLength(2));
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

    test('live TV stream resolution negotiates PlaybackInfo and preserves PlaySessionId', () async {
      final requests = <Uri>[];
      final scoped = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path == '/Items/channel-1/PlaybackInfo') {
            return http.Response(
              jsonEncode({
                'PlaySessionId': 'live-session-1',
                'MediaSources': [
                  {'Id': 'source-1', 'TranscodingUrl': '/Videos/channel-1/master.m3u8?PlaySessionId=live-session-1'},
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
      expect(resolution, isNotNull);
      expect(resolution!.playSessionId, 'live-session-1');
      final uri = Uri.parse(resolution.url);
      expect(uri.path, '/Videos/channel-1/master.m3u8');
      expect(uri.queryParameters['PlaySessionId'], 'live-session-1');
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
      final nextUp = requests.singleWhere((uri) => uri.path == '/Shows/NextUp');
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '3');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
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

      final nextUp = capturedNextUpRequest();
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '12');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
      expect(nextUp.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
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

    test('library Next Up excludes resumable episodes without date cutoff', () async {
      final client = buildClient();
      addTearDown(client.close);

      await client.fetchLibraryHubs('lib-99', limit: 12);

      final nextUp = captured.singleWhere((uri) => uri.path == '/Shows/NextUp');
      expect(nextUp.queryParameters['ParentId'], 'lib-99');
      expect(nextUp.queryParameters['userId'], 'user-1');
      expect(nextUp.queryParameters['Limit'], '12');
      expect(nextUp.queryParameters['EnableResumable'], 'false');
      expect(nextUp.queryParameters['EnableTotalRecordCount'], 'false');
      expect(nextUp.queryParameters.containsKey('NextUpDateCutoff'), isFalse);
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
      expect(captured!.queryParameters['MediaTypes'], 'Video');
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
      expect(captured!.queryParameters.containsKey('ParentId'), isFalse);
      expect(captured!.queryParameters['EnableResumable'], 'false');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'false');
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
      client.close();
    });

    test('library-scoped "library.{id}.nextup" forwards ParentId to NextUp', () async {
      final client = buildClient();
      await client.fetchMoreHubItems('library.lib-99.nextup');

      expect(captured, isNotNull);
      expect(captured!.path, '/Shows/NextUp');
      expect(captured!.queryParameters['ParentId'], 'lib-99');
      expect(captured!.queryParameters['userId'], 'user-1');
      expect(captured!.queryParameters['EnableResumable'], 'false');
      expect(captured!.queryParameters['EnableTotalRecordCount'], 'false');
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

  group('JellyfinClient.fetchPlaylists filtering', () {
    JellyfinClient buildClient() {
      final mock = MockClient((req) async {
        if (req.url.path == '/Items') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'video-1', 'Name': 'Video Playlist', 'Type': 'Playlist', 'MediaType': 'Video'},
                {'Id': 'audio-1', 'Name': 'Audio Playlist', 'Type': 'Playlist', 'MediaType': 'Audio'},
                {'Id': 'photo-1', 'Name': 'Photo Playlist', 'Type': 'Playlist', 'MediaType': 'Photo'},
              ],
            }),
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
