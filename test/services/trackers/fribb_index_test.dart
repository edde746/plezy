import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/fribb_mapping_row.dart';
import 'package:plezy/services/trackers/fribb_index.dart';

void main() {
  group('FribbIndex.fromRows', () {
    test('files a row under every id it declares', () {
      const movie = FribbMappingRow(
        type: 'MOVIE',
        anidbId: 7,
        malId: 100,
        imdbIds: ['tt0286390', 'tt1', ''],
        tmdbMovieIds: [10, 11],
        tvdbId: 81797,
      );
      const tv = FribbMappingRow(type: 'TV', anidbId: 8, malId: 200, imdbIds: ['tt2'], tmdbTvId: 456, tvdbId: 555);
      final index = FribbIndex.fromRows(const [movie, tv]);

      expect(index.byTvdb[81797]!.single, same(movie));
      // Movie row is indexed under every tmdb movie id and every imdb id.
      expect(index.byTmdbMovie[10]!.single, same(movie));
      expect(index.byTmdbMovie[11]!.single, same(movie));
      expect(index.byImdb['tt0286390']!.single, same(movie));
      expect(index.byImdb['tt1']!.single, same(movie));
      expect(index.byImdb[''], isNull);

      // A series id goes to the TV table only.
      expect(index.byTvdb[555]!.single, same(tv));
      expect(index.byTmdbTv[456]!.single, same(tv));
      expect(index.byTmdbMovie[456], isNull);
      expect(index.byImdb['tt2']!.single, same(tv));

      // AniDB is the dataset's primary key, so it indexes to a single row —
      // the only handle a HAMA-matched Plex library can offer (#1788).
      expect(index.byAnidb[7], same(movie));
      expect(index.byAnidb[8], same(tv));
    });
  });

  group('FribbIndex.lookup', () {
    // Real rows: TMDB numbers films and series independently, so 982 is both
    // The Manchurian Candidate (movie) and Transformers: Armada (tv).
    final index = FribbIndex.fromRows(const [
      FribbMappingRow(
        type: 'TV',
        anidbId: 525,
        malId: 1675,
        imdbIds: ['tt0329938'],
        tmdbTvId: 982,
        tvdbId: 78628,
        tvdbSeason: 1,
        tmdbSeason: 1,
      ),
      FribbMappingRow(type: 'MOVIE', anidbId: 5975, malId: 199, imdbIds: ['tt0245429'], tmdbMovieIds: [129]),
      FribbMappingRow(
        type: 'MOVIE',
        anidbId: 43,
        malId: 405,
        tmdbTvId: 19849,
        tvdbId: 78960,
        tvdbSeason: 0,
        tmdbSeason: 0,
      ),
    ]);

    test('a movie never resolves through a TV series tmdb id', () {
      expect(index.lookup(movie: true, tmdbId: 982), isEmpty);
      expect(index.lookup(movie: false, tmdbId: 982).single.malId, 1675);
    });

    test('a show never resolves through a movie tmdb id', () {
      expect(index.lookup(movie: true, tmdbId: 129).single.malId, 199);
      expect(index.lookup(movie: false, tmdbId: 129), isEmpty);
    });

    test('a movie skips the tvdb series index and falls through to its other ids', () {
      // A library movie's tvdb id is a TVDB *movie* id; Fribb only has series.
      expect(index.lookup(movie: true, tvdbId: 78628), isEmpty);
      expect(index.lookup(movie: true, tvdbId: 78628, imdbId: 'tt0245429').single.malId, 199);
      expect(index.lookup(movie: false, tvdbId: 78628).single.malId, 1675);
    });

    test('a film TMDB lists as a TV special is filed under the series id', () {
      expect(index.lookup(movie: false, tmdbId: 19849).single.malId, 405);
      expect(index.lookup(movie: true, tmdbId: 19849), isEmpty);
    });

    test('an AniDB id resolves regardless of kind', () {
      expect(index.lookup(movie: true, anidbId: 525).single.malId, 1675);
    });
  });
}
