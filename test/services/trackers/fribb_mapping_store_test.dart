import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/services/trackers/fribb_mapping_store.dart';

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
      expect(movie.tmdbIds, [10, 11]);
      // season object still resolves via the readValue helpers.
      expect(movie.tvdbSeason, 1);
      expect(movie.tmdbSeason, 2);

      // Movie row is indexed under every tmdb id and every imdb id.
      expect(index.byTmdb[10]!.single, same(movie));
      expect(index.byTmdb[11]!.single, same(movie));
      expect(index.byImdb['tt0286390']!.single, same(movie));
      expect(index.byImdb['tt1']!.single, same(movie));

      // {"tv": id} flattens to a single-element list; legacy flat imdb string
      // is wrapped into a list.
      final tv = index.byTvdb[555]!.single;
      expect(tv.tmdbIds, [456]);
      expect(tv.imdbIds, ['tt2']);
      expect(index.byTmdb[456]!.single, same(tv));
      expect(index.byImdb['tt2']!.single, same(tv));
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
      expect(weird.tmdbIds, isNull);
      expect(weird.malId, 1);

      // Second, well-formed row is unaffected.
      expect(index.byTvdb[1000]!.single.malId, 2);
      expect(index.byTmdb[42]!.single.malId, 2);
      expect(index.byImdb['tt9']!.single.malId, 2);
    });

    test('returns an empty index for a non-list payload', () {
      final index = parseFribbIndex('{"not": "a list"}');
      expect(index.isEmpty, isTrue);
    });
  });
}
