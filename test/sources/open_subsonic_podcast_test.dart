import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/open_subsonic_source.dart';
import 'package:plezy/sources/adapters/podcast_rss_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';
import 'package:plezy/sources/podcast_opml.dart';

http.Response _json(Object value, {int status = 200}) =>
    http.Response(jsonEncode(value), status, headers: const {'content-type': 'application/json'});

Map<String, Object?> _subsonic(Object data) => {
  'subsonic-response': {'status': 'ok', ...?data as Map<String, Object?>?},
};

void main() {
  group('OpenSubsonic source', () {
    test('browses and resolves audio through the read-only server adapter', () async {
      final requests = <http.Request>[];
      final transport = SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/ping.view')) return _json(_subsonic({'version': '1.16.1'}));
          if (request.url.path.endsWith('/search3.view')) {
            return _json(
              _subsonic({
                'searchResult3': {
                  'song': [
                    {
                      'id': 'song-7',
                      'title': 'Night Drive',
                      'artist': 'The Group',
                      'album': 'After Hours',
                      'contentType': 'audio/flac',
                      'duration': 61.5,
                      'coverArt': 'cover-7',
                    },
                  ],
                },
              }),
            );
          }
          return http.Response('', 404);
        }),
      );
      final source = OpenSubsonicSourceAdapter(
        const FileSource(
          id: 'music',
          profileId: 'profile',
          kind: FileSourceKind.openSubsonic,
          name: 'Music',
          endpoint: 'https://music.example/music/rest/',
        ),
        transport,
        () async => {'apiKey': 'private-api-key'},
      );

      try {
        final root = await source.browse();
        expect(root.entries.map((entry) => entry.id), ['artists', 'albums', 'recent']);

        final search = await source.browse(query: 'Night Drive');
        final song = search.entries.single;
        expect(song.kind, SourceItemKind.music);
        expect(song.title, 'Night Drive');
        expect(song.author, 'The Group');
        expect(song.series, 'After Hours');
        expect(song.coverId, 'cover-7');
        expect(song.files.single.name, 'Night Drive.flac');
        expect(song.files.single.durationMs, 61500);

        final lease = await source.resolve(song.files.single);
        expect(lease.uri.path, '/music/rest/stream.view');
        expect(lease.uri.queryParameters['id'], 'song-7');
        expect(lease.uri.queryParameters['apiKey'], 'private-api-key');
        expect(source.capabilities.audioProgress, isFalse);
        expect(source.capabilities.writableState, isFalse);
        expect(requests, hasLength(2));
        expect(requests.every((request) => request.method == 'POST'), isTrue);
        expect(requests.every((request) => request.url.host == 'music.example'), isTrue);
        expect(requests.last.bodyFields['apiKey'], 'private-api-key');
      } finally {
        source.close();
      }
    });

    test('falls back to legacy token auth only when an API key extension is unsupported', () async {
      final requests = <http.Request>[];
      final source = OpenSubsonicSourceAdapter(
        const FileSource(
          id: 'music',
          profileId: 'p',
          kind: FileSourceKind.openSubsonic,
          name: 'Music',
          endpoint: 'https://music.example/',
        ),
        SourceTransport(
          client: MockClient((request) async {
            requests.add(request);
            if (request.bodyFields.containsKey('apiKey')) {
              return _json({
                'subsonic-response': {
                  'status': 'failed',
                  'error': {'code': 41, 'message': 'API key authentication is not supported'},
                },
              });
            }
            return _json(_subsonic({'version': '1.16.1'}));
          }),
        ),
        () async => {'apiKey': 'private-api-key', 'username': 'reader', 'password': 'private-password'},
      );

      try {
        expect((await source.browse()).entries, hasLength(3));
        expect(requests, hasLength(2));
        expect(requests.first.bodyFields['apiKey'], 'private-api-key');
        expect(requests.last.bodyFields['u'], 'reader');
        expect(requests.last.bodyFields['t'], isNotEmpty);
        expect(requests.last.bodyFields['s'], isNotEmpty);
        expect(requests.last.bodyFields.containsKey('password'), isFalse);
      } finally {
        source.close();
      }
    });

    test('refuses endpoints that include credentials or query parameters before a request', () async {
      var requests = 0;
      final source = OpenSubsonicSourceAdapter(
        const FileSource(
          id: 'music',
          profileId: 'p',
          kind: FileSourceKind.openSubsonic,
          name: 'Music',
          endpoint: 'https://music.example/rest?token=secret',
        ),
        SourceTransport(
          client: MockClient((_) async {
            requests++;
            return _json(_subsonic({}));
          }),
        ),
        () async => {'apiKey': 'private-api-key'},
      );
      try {
        await expectLater(source.browse(), throwsA(isA<SourceException>()));
        expect(requests, 0);
      } finally {
        source.close();
      }
    });
  });

  group('Podcast RSS source', () {
    const feed = '''
<rss version="2.0"><channel>
  <title>Desk Cast</title>
  <image><url>https://cdn.example/cover.jpg</url></image>
  <item>
    <title>Episode One</title><guid>episode-1</guid>
    <description><![CDATA[<p>A safe <b>description</b>.</p>]]></description>
    <pubDate>2026-01-02T03:04:05Z</pubDate><duration>1:02:03</duration>
    <enclosure url="https://cdn.example/audio/episode.mp3?token=stream-secret" type="audio/mpeg" length="1234" />
  </item>
  <item>
    <title>Unsafe Episode</title><guid>episode-2</guid>
    <enclosure url="https://user:secret@cdn.example/audio/private.mp3" type="audio/mpeg" />
  </item>
</channel></rss>
''';

    test('parses bounded feeds and never sends feed credentials to enclosure or artwork hosts', () async {
      final requests = <http.Request>[];
      final source = PodcastRssSourceAdapter(
        const FileSource(
          id: 'podcast',
          profileId: 'p',
          kind: FileSourceKind.podcastRss,
          name: 'Desk Cast',
          endpoint: 'https://feeds.example/feed.xml',
        ),
        SourceTransport(
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.host == 'feeds.example') return http.Response(feed, 200);
            if (request.url.path == '/cover.jpg') return http.Response.bytes([1, 2, 3], 200);
            return http.Response('', 404);
          }),
        ),
        () async => {'feedUrl': 'https://feeds.example/feed.xml', 'username': 'reader', 'password': 'private-password'},
      );

      try {
        final root = await source.browse();
        expect(root.entries.single.title, 'Desk Cast');
        final episodes = await source.browse(parent: 'podcast:episodes');
        expect(episodes.entries, hasLength(1));
        final episode = episodes.entries.single;
        expect(episode.title, 'Episode One');
        expect(episode.description, 'A safe description.');
        expect(episode.files.single.size, 1234);
        expect(episode.files.single.durationMs, 3723000);
        expect(source.capabilities.audioProgress, isFalse);
        expect(source.capabilities.writableState, isFalse);

        final lease = await source.resolve(episode.files.single);
        expect(lease.uri.host, 'cdn.example');
        expect(lease.uri.queryParameters['token'], 'stream-secret');
        expect(lease.headers.containsKey('Authorization'), isFalse);
        expect(await source.coverBytes(episode), [1, 2, 3]);
        final feedRequests = requests.where((request) => request.url.host == 'feeds.example').toList();
        expect(feedRequests, isNotEmpty);
        expect(feedRequests.every((request) => request.method == 'GET'), isTrue);
        expect(feedRequests.every((request) => request.headers['authorization']?.startsWith('Basic ') == true), isTrue);
        final externalRequests = requests.where((request) => request.url.host == 'cdn.example').toList();
        expect(externalRequests.every((request) => !request.headers.containsKey('authorization')), isTrue);
        expect(requests.every((request) => request.method == 'GET'), isTrue);
      } finally {
        source.close();
      }
    });

    test('rejects insecure feeds unless the source transport explicitly allows HTTP', () async {
      var requests = 0;
      final source = PodcastRssSourceAdapter(
        const FileSource(id: 'podcast', profileId: 'p', kind: FileSourceKind.podcastRss, name: 'Feed'),
        SourceTransport(
          client: MockClient((_) async {
            requests++;
            return http.Response(feed, 200);
          }),
        ),
        () async => {'feedUrl': 'http://feeds.example/feed.xml'},
      );
      try {
        await expectLater(source.browse(), throwsA(isA<SourceException>()));
        expect(requests, 0);
      } finally {
        source.close();
      }
    });
  });

  test('OPML import is HTTPS-only, deduplicated and bounded; export escapes titles', () {
    const input = '''
<opml version="2.0"><body>
  <outline text="Books &amp; Stories" title="Books &amp; Stories" xmlUrl="https://feeds.example/books.xml" />
  <outline text="Duplicate" xmlUrl="https://feeds.example/books.xml" />
  <outline text="Local HTTP" xmlUrl="http://localhost/feed.xml" />
</body></opml>
''';
    final parsed = PodcastOpml.parse(input);
    expect(parsed, hasLength(1));
    expect(parsed.single.title, 'Books & Stories');

    final exported = PodcastOpml.write(parsed);
    expect(exported, contains('Books &amp; Stories'));
    expect(PodcastOpml.parse(exported).single.url, parsed.single.url);
    expect(
      () => PodcastOpml.parse('<opml><body><outline xmlUrl="http://feeds.example/feed.xml" /></body></opml>'),
      throwsA(isA<SourceException>()),
    );
  });
}
