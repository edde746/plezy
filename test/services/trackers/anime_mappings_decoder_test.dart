import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/anime_lists_mapping.dart';
import 'package:plezy/services/trackers/anime_mappings_decoder.dart';

/// `anime-mappings.bin.gz` written by edde746/anime-mappings' own `build.py`
/// (`write_tables` + `gzip_bytes`, and `check` read it back equal) from:
///
/// anime-list-mini.json:
/// ```json
/// [
///   {"type": "MOVIE", "anidb_id": 7, "mal_id": 100, "anilist_id": 101, "simkl_id": 102, "anime-planet_id": "x",
///    "imdb_id": ["tt0286390", "tt1"], "themoviedb_id": {"movie": [10, 11]}, "tvdb_id": 81797,
///    "season": {"tvdb": 1, "tmdb": 2}},
///   {"type": "TV", "anidb_id": 3, "mal_id": 200, "imdb_id": ["tt2"], "themoviedb_id": {"tv": 456}, "tvdb_id": 555},
///   {"mal_id": 300}
/// ]
/// ```
///
/// anime-list.xml:
/// ```xml
/// <anime-list>
///   <anime anidbid="1" tvdbid="123" defaulttvdbseason="1" episodeoffset="2" tmdbtv="456" tmdbseason="a"
///          tmdboffset="-1" tmdbid="10,11" imdbid="tt1,tt2">
///     <name>First</name>
///     <mapping-list>
///       <mapping anidbseason="1" tvdbseason="1" start="1" end="12" offset="12"/>
///       <mapping anidbseason="0" tvdbseason="0" tmdbseason="0">;1-3;2-0;3-4+5;</mapping>
///     </mapping-list>
///     <supplemental-info><studio>Studio</studio></supplemental-info>
///   </anime>
///   <anime anidbid="2" tvdbid="movie" defaulttvdbseason="a" tmdbtv="789">
///     <name>Second</name>
///   </anime>
/// </anime-list>
/// ```
///
/// plus what a later release of the same format version may add and this
/// reader must skip: a `fribb` column `from_a_later_release` of unknown type
/// 42, and a table `from_a_later_release`.
const _fixture =
    'H4sIAAAAAAAC/21SzY7TMBD2xInTny27VcuKfQVQV90WEKgHtAeQOKxAWrTXyE0m1GoSR7HTwjNw2ufgSRDizKNwQ9hOf8UqUuT5ZjzzfZ'
    '/n+ub6IwRBWon5nA58/bVEv+cFNx/u3r/1Pt2BR1q8EMk8EolHT1uE5TyzZ/YD7NdaCq1qlySEnJhShbyKF1ukY5BMKG1j/ycQ0jdAjrGs'
    'C53IdbGtaymRL11j/5epGriqAteqQL2W1XI3IRMrjBe80lvkTC8wlyuBjuOlXoFP7kMyOIbdMQjo8JyQUOQOZI9pW+vx5NXL6esx1frKM7'
    '8JCfXKpYF9+9v+3SJdo0jJ4tLCQM3IHZBbIDBssRRKJhjJNFWoN5XkgUS+SQzTSuYRjzKusYoqzExHfGozXac8sp4p71HovDdKPUqZbWto'
    '0T9Aus050vhF+20InDwC/QRTXmfaZhuSYDw6/w9t7gUAnEBvw7GhCF5AmKVpfbwPv590bLDtRcjpPtw3AeKqth28poNIAt/6zYQLWIdaj5'
    '3FfsFzpD32TlRKh7dmHYqEzTGVFVIzZHjgQZTzshTFZ+W1DsyArjvvNELnSDIcs4ZAabMx1guKRQLeBWFbshfEtzpon5zNrkbT2WQ0nk1H'
    'z5+9mD05ZKHqsszQrKTmGeyZmOefZzJeAkBYYZnxGH0jIMSm1jwNU7pOhIRmShjeupAmIreFLJaZrJS7U1ZoHnFN4eHtAAhWPKuNQd6b'
    'f4R9uFG1AwAA';

void main() {
  final index = decodeAnimeMappings(base64Decode(_fixture));

  group('decodeAnimeMappings Fribb rows', () {
    test('keep every id with TMDB films and series in their own namespaces', () {
      final movie = index.fribb.byAnidb[7]!;
      expect(movie.type, 'MOVIE');
      expect(movie.isMovie, isTrue);
      expect(movie.malId, 100);
      expect(movie.anilistId, 101);
      expect(movie.simklId, 102);
      expect(movie.imdbIds, ['tt0286390', 'tt1']);
      expect(movie.tmdbMovieIds, [10, 11]);
      expect(movie.tmdbTvId, isNull);
      expect(movie.tvdbId, 81797);
      expect(movie.tvdbSeason, 1);
      expect(movie.tmdbSeason, 2);

      // anidb_id is delta-coded; 7 → 3 is a negative step.
      final tv = index.fribb.byAnidb[3]!;
      expect(tv.type, 'TV');
      expect(tv.malId, 200);
      expect(tv.tmdbTvId, 456);
      expect(tv.tmdbMovieIds, isNull);
      expect(tv.imdbIds, ['tt2']);
      expect(tv.tvdbId, 555);
      expect(tv.tvdbSeason, isNull);
      expect(index.fribb.byTmdbTv[456]!.single, same(tv));
      expect(index.fribb.byTmdbMovie[456], isNull);
    });

    test('leave a key the row lacks absent', () {
      final bare = index.fribb.byMal[300]!;
      expect(bare.anidbId, isNull);
      expect(bare.type, isNull);
      expect(bare.tvdbId, isNull);
      expect(bare.imdbIds, isNull);
      expect(bare.tmdbMovieIds, isNull);
    });
  });

  group('decodeAnimeMappings Anime-Lists entries', () {
    test('carry their attributes, with season words and negative offsets', () {
      final first = index.animeLists.byTvdb[123]!.single;
      expect(first.anidbId, 1);
      expect(first.name, 'First');
      expect(first.defaultTvdbSeason?.number, 1);
      expect(first.episodeOffset, 2);
      expect(first.tmdbTvId, 456);
      expect(first.tmdbSeason?.isAbsolute, isTrue);
      expect(first.tmdbOffset, -1);
      expect(first.tmdbMovieIds, [10, 11]);
      expect(first.imdbIds, ['tt1', 'tt2']);

      final second = index.animeLists.byTmdbTv[789]!.single;
      expect(second.anidbId, 2);
      expect(second.tvdbId, isNull);
      expect(second.rawTvdbId, 'movie');
      expect(second.defaultTvdbSeason?.isAbsolute, isTrue);
      expect(second.mappings, isEmpty);
      expect(index.animeLists.byTvdb.keys, [123]);
    });

    test('resolve episodes through their own mapping rows', () {
      final first = index.animeLists.byTvdb[123]!.single;

      final range = first
          .resolveEpisode(provider: AnimeListProvider.tvdb, externalSeason: 1, externalEpisode: 14)
          .single;
      expect(range.anidbEpisode, 2);
      expect(range.kind, AnimeListMatchKind.range);

      // One <mapping> naming a TVDB and a TMDB season serves both providers.
      for (final provider in AnimeListProvider.values) {
        final explicit = first.resolveEpisode(provider: provider, externalSeason: 0, externalEpisode: 5).single;
        expect(explicit.anidbSeason, 0, reason: provider.name);
        expect(explicit.anidbEpisode, 3, reason: provider.name);
        expect(explicit.kind, AnimeListMatchKind.explicit, reason: provider.name);
      }

      // `2-0` maps AniDB episode 2 to no external episode.
      final specials = first.mappings.firstWhere((mapping) => mapping.externalSeason == 0);
      expect(specials.explicit.map((mapping) => mapping.anidbEpisode), [1, 3]);
    });
  });

  test('rejects a body that is not a version 1 packed list', () {
    expect(() => decodeAnimeMappings(utf8.encode('[{"mal_id": 1}]')), throwsFormatException);
    expect(() => decodeAnimeMappings(Uint8List.fromList([0x41, 0x4D, 0x41, 0x50, 2, 0])), throwsFormatException);
  });
}
