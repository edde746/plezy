import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/subtitles/subtitle_search_result.dart';
import 'package:plezy/services/open_subtitles_client.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  test('OpenSubtitles bounds search and keeps the API key off the download host', () async {
    final requests = <http.Request>[];
    final client = OpenSubtitlesClient(
      apiKey: 'test-api-key',
      transport: SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.host == 'api.opensubtitles.com' && request.url.path.endsWith('/subtitles')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': '78',
                    'attributes': {
                      'files': [
                        {'file_id': 1234, 'file_name': 'Example.en.srt'},
                      ],
                      'release': 'Example release',
                      'language': 'en',
                      'ratings': 9.1,
                      'match': true,
                    },
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.host == 'api.opensubtitles.com' && request.url.path.endsWith('/download')) {
            expect(jsonDecode(request.body), {'file_id': 1234, 'sub_format': 'srt'});
            return http.Response(
              jsonEncode({'link': 'https://dl.opensubtitles.com/subtitle/123', 'file_name': 'Example.en.srt'}),
              200,
            );
          }
          return http.Response('1\n00:00:01,000 --> 00:00:02,000\nHello\n', 200);
        }),
      ),
    );

    final results = await client.search(query: 'Film' * 40, languageCode: 'eng', imdbId: 'tt1234567', year: 2024);
    expect(results, hasLength(1));
    expect(results.single.key, '1234');
    expect(results.single.codec, 'srt');
    expect(results.single.languageCode, 'en');
    expect(results.single.perfectMatch, isTrue);
    final searchRequest = requests.first;
    expect(searchRequest.url.queryParameters['query']!.length, 120);
    expect(searchRequest.url.queryParameters['languages'], 'en');
    expect(searchRequest.url.queryParameters['imdb_id'], '1234567');
    expect(searchRequest.url.queryParameters['year'], '2024');
    expect(searchRequest.headers['api-key'], 'test-api-key');

    final downloaded = await client.download(results.single);
    expect(downloaded.fileName, 'Example.en.srt');
    expect(utf8.decode(downloaded.bytes), contains('Hello'));
    final cdnRequest = requests.last;
    expect(cdnRequest.url.host, 'dl.opensubtitles.com');
    expect(cdnRequest.headers.containsKey('api-key'), isFalse);
    expect(cdnRequest.headers.containsKey('authorization'), isFalse);
    client.close();
  });

  test('OpenSubtitles rejects a download URL outside its service domain', () async {
    final client = OpenSubtitlesClient(
      apiKey: 'test-api-key',
      transport: SourceTransport(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/download')) {
            return http.Response(jsonEncode({'link': 'https://evil.example/subtitle'}), 200);
          }
          return http.Response('', 500);
        }),
      ),
    );

    await expectLater(
      client.download(SubtitleSearchResult(id: 1, key: '1234', codec: 'srt')),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
    );
    client.close();
  });
}
