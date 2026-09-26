import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/trackers/fribb_mapping_store.dart';

void main() {
  group('parseFribbIndex', () {
    test('parses the current anime-list-mini schema and fans out every id', () {
      // imdb_id is an array; themoviedb_id is {"movie": [...]} (multiple ids).
      final index = parseFribbIndex('''
[
  {
    "type": "MOVIE",
    "anidb_id": 7,
    "mal_id": 100,
    "anilist_id": 101,
    "simkl_id": 102,
    "imdb_id": ["tt0286390", "tt1"],
    "themoviedb_id": {"movie": [10, 11]},
    "tvdb_id": 81797,
    "season": {"tvdb": 1, "tmdb": 2}
  },
  {
    "type": "TV",
    "anidb_id": 8,
    "mal_id": 200,
    "imdb_id": "tt2",
    "themoviedb_id": {"tv": 456},
    "tvdb_id": 555
  }
]
''');

      final movie = index.byTvdb[81797]!.single;
      expect(movie.malId, 100);
      expect(movie.anilistId, 101);
      expect(movie.simklId, 102);
      expect(movie.isMovie, isTrue);
      expect(movie.imdbIds, ['tt0286390', 'tt1']);
      expect(movie.tmdbMovieIds, [10, 11]);
      expect(movie.tmdbTvId, isNull);
      // season object still resolves via the readValue helpers.
      expect(movie.tvdbSeason, 1);
      expect(movie.tmdbSeason, 2);

      // Movie row is indexed under every tmdb movie id and every imdb id.
      expect(index.byTmdbMovie[10]!.single, same(movie));
      expect(index.byTmdbMovie[11]!.single, same(movie));
      expect(index.byImdb['tt0286390']!.single, same(movie));
      expect(index.byImdb['tt1']!.single, same(movie));

      // {"tv": id} is a single series id; legacy flat imdb string is wrapped
      // into a list.
      final tv = index.byTvdb[555]!.single;
      expect(tv.tmdbTvId, 456);
      expect(tv.tmdbMovieIds, isNull);
      expect(tv.imdbIds, ['tt2']);
      expect(index.byTmdbTv[456]!.single, same(tv));
      expect(index.byTmdbMovie[456], isNull);
      expect(index.byImdb['tt2']!.single, same(tv));

      // AniDB is the dataset's primary key, so it indexes to a single row —
      // the only handle a HAMA-matched Plex library can offer (#1788).
      expect(index.byAnidb[7], same(movie));
      expect(index.byAnidb[8], same(tv));
    });

    test('an unexpected field shape yields null fields, not a whole-parse crash', () {
      final index = parseFribbIndex('''
[
  {"type": ["TV"], "imdb_id": 123, "themoviedb_id": "garbage", "tvdb_id": 999, "mal_id": 1},
  {"type": "TV", "imdb_id": ["tt9"], "themoviedb_id": {"tv": 42}, "tvdb_id": 1000, "mal_id": 2}
]
''');

      // First row: every odd field coerces to null but the row still parses and
      // is indexed by its (valid) tvdb id.
      final weird = index.byTvdb[999]!.single;
      expect(weird.type, isNull);
      expect(weird.imdbIds, isNull);
      expect(weird.tmdbTvId, isNull);
      expect(weird.tmdbMovieIds, isNull);
      expect(weird.malId, 1);

      // Second, well-formed row is unaffected.
      expect(index.byTvdb[1000]!.single.malId, 2);
      expect(index.byTmdbTv[42]!.single.malId, 2);
      expect(index.byImdb['tt9']!.single.malId, 2);
    });

    test('returns an empty index for a non-list payload', () {
      final index = parseFribbIndex('{"not": "a list"}');
      expect(index.isEmpty, isTrue);
    });

    test('a legacy key-less tmdb id is filed by the row type', () {
      final index = parseFribbIndex('''
[
  {"type": "MOVIE", "themoviedb_id": [7, 8], "mal_id": 1},
  {"type": "TV", "themoviedb_id": 9, "mal_id": 2}
]
''');

      expect(index.byTmdbMovie[7]!.single.malId, 1);
      expect(index.byTmdbMovie[8]!.single.malId, 1);
      expect(index.byTmdbTv[9]!.single.malId, 2);
      expect(index.byTmdbTv[7], isNull);
      expect(index.byTmdbMovie[9], isNull);
    });
  });

  group('FribbIndex.lookup', () {
    // Real rows: TMDB numbers films and series independently, so 982 is both
    // The Manchurian Candidate (movie) and Transformers: Armada (tv).
    final index = parseFribbIndex('''
[
  {"type": "TV", "anidb_id": 525, "mal_id": 1675, "imdb_id": ["tt0329938"],
   "themoviedb_id": {"tv": 982}, "tvdb_id": 78628, "season": {"tvdb": 1, "tmdb": 1}},
  {"type": "MOVIE", "anidb_id": 5975, "mal_id": 199, "imdb_id": ["tt0245429"],
   "themoviedb_id": {"movie": [129]}},
  {"type": "MOVIE", "anidb_id": 43, "mal_id": 405, "themoviedb_id": {"tv": 19849},
   "tvdb_id": 78960, "season": {"tvdb": 0, "tmdb": 0}}
]
''');

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
