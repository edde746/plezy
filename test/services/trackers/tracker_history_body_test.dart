import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/services/trackers/tracker_history_body.dart';
import 'package:plezy/utils/external_ids.dart';

TrackerContext _episode(int tvdb, int season, int number) => TrackerContext.episode(
  external: ExternalIds(tvdb: tvdb),
  anime: null,
  ratingKey: 'episode-$tvdb-$season-$number',
  libraryGlobalKey: null,
  season: season,
  episodeNumber: number,
);

TrackerContext _movie(int tmdb) => TrackerContext.movie(
  external: ExternalIds(tmdb: tmdb),
  anime: null,
  ratingKey: 'movie-$tmdb',
  libraryGlobalKey: null,
);

Map<String, Object?> _ids(TrackerContext ctx) => {'tvdb': ?ctx.external.tvdb, 'tmdb': ?ctx.external.tmdb};

void main() {
  test('folds a container into one entry per show and season, sending a repeated item once', () {
    final watchedAt = DateTime.utc(2026, 10, 1, 20);
    final body = trackerHistoryBody(
      [
        (ctx: _episode(1, 1, 1), watchedAt: watchedAt),
        (ctx: _episode(1, 1, 2), watchedAt: null),
        (ctx: _episode(2, 1, 1), watchedAt: null),
        (ctx: _episode(1, 2, 1), watchedAt: null),
        // Two media-server rows for one episode: one play, not two.
        (ctx: _episode(1, 1, 2), watchedAt: watchedAt),
        (ctx: _movie(9), watchedAt: null),
        (ctx: _movie(9), watchedAt: null),
      ],
      idsFor: _ids,
      includeWatchedAt: true,
    );

    expect(body, {
      'movies': [
        {
          'ids': {'tmdb': 9},
        },
      ],
      'shows': [
        {
          'ids': {'tvdb': 1},
          'seasons': [
            {
              'number': 1,
              'episodes': [
                {'number': 1, 'watched_at': '2026-10-01T20:00:00.000Z'},
                {'number': 2},
              ],
            },
            {
              'number': 2,
              'episodes': [
                {'number': 1},
              ],
            },
          ],
        },
        {
          'ids': {'tvdb': 2},
          'seasons': [
            {
              'number': 1,
              'episodes': [
                {'number': 1},
              ],
            },
          ],
        },
      ],
    });
  });

  test('leaves out what the service cannot address and sends nothing when nothing remains', () {
    final unaddressable = [(ctx: _movie(9), watchedAt: DateTime.utc(2026)), (ctx: _episode(1, 1, 1), watchedAt: null)];

    expect(trackerHistoryBody(unaddressable, idsFor: (_) => const {}, includeWatchedAt: true), isNull);
    expect(trackerHistoryBody(unaddressable, idsFor: _ids, includeWatchedAt: false)?['movies'], [
      {
        'ids': {'tmdb': 9},
      },
    ], reason: 'a removal carries no timestamp');
  });
}
