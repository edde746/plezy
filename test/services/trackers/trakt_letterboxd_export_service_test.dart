import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_client.dart';
import 'package:plezy/services/trackers/trakt/trakt_letterboxd_export_service.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'test-token',
    refreshToken: 'test-refresh-token',
    expiresAt: now + 3600,
    createdAt: now,
  );
}

http.Response _page(List<Map<String, dynamic>> rows, int page, int pageCount) => http.Response(
  jsonEncode(rows),
  200,
  headers: {'x-pagination-page': '$page', 'x-pagination-page-count': '$pageCount', 'x-pagination-item-count': '500'},
);

Map<String, dynamic> _event({
  required Object? id,
  required String? watchedAt,
  required String title,
  required int traktId,
  required int? tmdbId,
  String? imdbId,
  int year = 2024,
}) => {
  'id': id,
  'watched_at': watchedAt,
  'movie': {
    'title': title,
    'year': year,
    'ids': {'trakt': traktId, 'tmdb': tmdbId, 'imdb': imdbId},
  },
};

void main() {
  test('paginates once, deduplicates history IDs, preserves rewatches, and quotes CSV cells', () async {
    final requests = <http.Request>[];
    final client = TraktClient(
      _session(),
      onSessionInvalidated: () => fail('the valid test session must remain connected'),
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.method, 'GET');
        expect(request.url.path, '/users/me/history/movies');
        expect(request.headers['authorization'], 'Bearer test-token');
        final page = int.parse(request.url.queryParameters['page']!);
        expect(request.url.queryParameters['limit'], '250');
        expect(request.url.queryParameters['end_at'], isNotEmpty);
        final rows = switch (page) {
          1 => [
            _event(
              id: 100,
              watchedAt: '2024-01-01T12:00:00Z',
              title: 'Second Film',
              traktId: 200,
              tmdbId: 2000,
              imdbId: 'tt0000200',
              year: 2023,
            ),
            _event(
              id: 101,
              watchedAt: '2024-01-02T12:00:00Z',
              title: 'A, "Great"\nMovie',
              traktId: 100,
              tmdbId: 1000,
              imdbId: 'tt0000100',
            ),
          ],
          2 => [
            _event(
              id: 101,
              watchedAt: '2024-01-02T12:00:00Z',
              title: 'A, "Great"\nMovie',
              traktId: 100,
              tmdbId: 1000,
              imdbId: 'tt0000100',
            ),
            _event(
              id: 102,
              watchedAt: '2024-01-03T12:00:00Z',
              title: 'A, "Great"\nMovie',
              traktId: 100,
              tmdbId: 1000,
              imdbId: 'tt0000100',
            ),
            _event(id: null, watchedAt: '2024-01-04T12:00:00Z', title: 'No history ID', traktId: 300, tmdbId: 3000),
            _event(id: 103, watchedAt: null, title: 'No watch date', traktId: 400, tmdbId: 4000),
          ],
          _ => throw StateError('unexpected page $page'),
        };
        return _page(rows, page, 2);
      }),
    );

    final export = await TraktLetterboxdExportService.create(client);
    client.dispose();

    expect(requests, hasLength(2));
    expect(requests.map((request) => request.url.queryParameters['page']), ['1', '2']);
    expect(
      requests.map((request) => request.url.queryParameters['end_at']).toSet(),
      hasLength(1),
      reason: 'all pages use the same end time so new plays cannot shift the export',
    );
    expect(export.movieCount, 2);
    expect(export.playCount, 3);
    expect(export.skippedCount, 2);
    expect(export.parts, hasLength(1));

    final csv = utf8.decode(export.parts.single.bytes);
    expect(csv, startsWith('tmdbID,imdbID,Title,Year,WatchedDate,Rewatch\n'));
    expect(csv, contains('2000,tt0000200,Second Film,2023,2024-01-01,false\n'));
    expect(csv, contains('1000,tt0000100,"A, \\"Great\\"\nMovie",2024,2024-01-02,false\n'));
    expect(csv, contains('1000,tt0000100,"A, \\"Great\\"\nMovie",2024,2024-01-03,true\n'));
  });

  test('splits large exports into parts below Letterboxd’s safe size limit', () async {
    const pageCount = 2;
    final client = TraktClient(
      _session(),
      onSessionInvalidated: () => fail('the valid test session must remain connected'),
      httpClient: MockClient((request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        final rows = List.generate(250, (index) {
          final traktId = (page - 1) * 250 + index + 1;
          return _event(
            id: traktId,
            watchedAt: '2024-01-01T12:00:00Z',
            title: 'Film $traktId ${'x' * 2000}',
            traktId: traktId,
            tmdbId: traktId,
          );
        });
        return _page(rows, page, pageCount);
      }),
    );

    final export = await TraktLetterboxdExportService.create(client);
    client.dispose();

    expect(export.playCount, 500);
    expect(export.movieCount, 500);
    expect(export.parts.length, greaterThan(1));
    expect(export.parts.fold<int>(0, (count, part) => count + part.entryCount), 500);
    for (final part in export.parts) {
      expect(part.bytes.length, lessThanOrEqualTo(TraktLetterboxdExportService.maxPartSizeBytes));
      expect(utf8.decode(part.bytes), startsWith('tmdbID,imdbID,Title,Year,WatchedDate,Rewatch\n'));
    }
  });

  test('rejects a partial history page when Trakt omits pagination metadata', () async {
    final client = TraktClient(
      _session(),
      onSessionInvalidated: () => fail('the valid test session must remain connected'),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode([_event(id: 1, watchedAt: '2024-01-01T12:00:00Z', title: 'Film', traktId: 1, tmdbId: 1)]),
          200,
        ),
      ),
    );

    await expectLater(
      TraktLetterboxdExportService.create(client),
      throwsA(isA<TraktLetterboxdExportException>().having((error) => error.isSizeLimit, 'isSizeLimit', isFalse)),
    );
    client.dispose();
  });

  test('stops before requesting an unsafe number of history pages', () async {
    final client = TraktClient(
      _session(),
      onSessionInvalidated: () => fail('the valid test session must remain connected'),
      httpClient: MockClient(
        (_) async => http.Response('[]', 200, headers: {'x-pagination-page': '1', 'x-pagination-page-count': '501'}),
      ),
    );

    await expectLater(
      TraktLetterboxdExportService.create(client),
      throwsA(isA<TraktLetterboxdExportException>().having((error) => error.isSizeLimit, 'isSizeLimit', isTrue)),
    );
    client.dispose();
  });
}
