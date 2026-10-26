import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/webos_media_proxy.dart';

void main() {
  group('WebOSMediaProxy', () {
    late HttpServer origin;
    late HttpClient client;
    late WebOSMediaProxy proxy;
    final requests = <HttpRequest>[];

    setUp(() async {
      requests.clear();
      origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = HttpClient();
      proxy = await WebOSMediaProxy.bind();
      origin.listen((request) async {
        requests.add(request);
        if (request.uri.path == '/playlist.m3u8') {
          request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
          request.response.write(
            '#EXTM3U\n'
            '#EXT-X-KEY:METHOD=AES-128,URI="/key.bin?X-Plex-Token=query-secret"\n'
            '#EXTINF:2,\n'
            'segment.ts?X-Plex-Token=query-secret\n',
          );
        } else if (request.uri.path == '/key.bin') {
          request.response.add([0x01, 0x02, 0x03]);
        } else if (request.uri.path == '/segment.ts') {
          request.response.statusCode = request.headers.value(HttpHeaders.rangeHeader) == 'bytes=0-3'
              ? HttpStatus.partialContent
              : HttpStatus.ok;
          if (request.headers.value(HttpHeaders.rangeHeader) == 'bytes=0-3') {
            request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes 0-3/4');
          }
          request.response.add([0x10, 0x20, 0x30, 0x40]);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
    });

    tearDown(() async {
      client.close(force: true);
      await proxy.close();
      await origin.close(force: true);
    });

    test('moves query credentials into headers and forwards byte ranges', () async {
      final source = Uri.parse('http://127.0.0.1:${origin.port}/segment.ts?X-Plex-Token=query-secret');
      final local = proxy.register(source, headers: const {'X-Plex-Client-Identifier': 'test-client'});

      expect(local.toString(), isNot(contains('query-secret')));
      final request = await client.getUrl(local);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-3');
      final response = await request.close();

      expect(response.statusCode, HttpStatus.partialContent);
      expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes 0-3/4');
      expect(await response.fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk)), [0x10, 0x20, 0x30, 0x40]);
      expect(requests, hasLength(1));
      expect(requests.single.uri.query, isEmpty);
      expect(requests.single.headers.value('X-Plex-Token'), 'query-secret');
      expect(requests.single.headers.value('X-Plex-Client-Identifier'), 'test-client');
      expect(requests.single.headers.value(HttpHeaders.rangeHeader), 'bytes=0-3');
    });

    test('rewrites HLS keys and segments to opaque local resources', () async {
      final source = Uri.parse('http://127.0.0.1:${origin.port}/playlist.m3u8?X-Plex-Token=query-secret');
      final local = proxy.register(source);
      final playlistResponse = await client.getUrl(local).then((request) => request.close());
      final playlist = await utf8.decodeStream(playlistResponse);

      expect(playlist, contains('#EXTM3U'));
      expect(playlist, isNot(contains('query-secret')));
      final localResources = RegExp(
        r'URI="(http://127\.0\.0\.1:\d+/r/[^"]+)"',
      ).allMatches(playlist).map((match) => Uri.parse(match.group(1)!)).toList();
      final segment = playlist
          .split('\n')
          .firstWhere((line) => line.startsWith('http://127.0.0.1:') && !line.startsWith('#'));
      localResources.add(Uri.parse(segment));
      expect(localResources, hasLength(2));

      for (final resource in localResources) {
        final response = await client.getUrl(resource).then((request) => request.close());
        await response.drain<void>();
      }
      expect(requests.map((request) => request.uri.path), containsAll(['/key.bin', '/segment.ts']));
      expect(
        requests
            .where((request) => request.uri.path != '/playlist.m3u8')
            .every((request) => request.headers.value('X-Plex-Token') == 'query-secret' && request.uri.query.isEmpty),
        isTrue,
      );
    });

    test('rejects methods and playlist children outside the media origin', () async {
      final foreign = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => foreign.close(force: true));
      var foreignRequestCount = 0;
      foreign.listen((request) async {
        foreignRequestCount++;
        await request.response.close();
      });

      final badSource = Uri.parse('http://127.0.0.1:${origin.port}/playlist.m3u8');
      final local = proxy.register(badSource);
      final post = await client.postUrl(local).then((request) => request.close());
      expect(post.statusCode, HttpStatus.methodNotAllowed);

      final body = '#EXTM3U\n#EXTINF:2,\nhttp://127.0.0.1:${foreign.port}/private.ts\n';
      final alternate = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => alternate.close(force: true));
      alternate.listen((request) async {
        request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
        request.response.write(body);
        await request.response.close();
      });
      final alternateLocal = proxy.register(Uri.parse('http://127.0.0.1:${alternate.port}/playlist.m3u8'));
      final forbidden = await client.getUrl(alternateLocal).then((request) => request.close());
      expect(forbidden.statusCode, HttpStatus.badGateway);
      expect(foreignRequestCount, 0);
    });
  });
}
