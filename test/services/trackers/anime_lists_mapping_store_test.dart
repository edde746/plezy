import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/models/trackers/anime_lists_mapping.dart';
import 'package:vibe_stream/services/trackers/anime_lists_mapping_store.dart';

void main() {
  group('AnimeListsMappingStore parser', () {
    test('parses defaults, offsets, ranges, explicit mappings, and absolute seasons', () {
      final index = parseAnimeListsIndex('''
<anime-list>
  <anime anidbid="1" tvdbid="123" defaulttvdbseason="1" episodeoffset="2" tmdbtv="456" tmdbseason="a" tmdbid="10,11" imdbid="tt1,tt2">
    <name>First</name>
    <mapping-list>
      <mapping anidbseason="1" tvdbseason="1" start="1" end="12" offset="12" />
      <mapping anidbseason="0" tvdbseason="0">;1-3;2-0;3-4+5;</mapping>
    </mapping-list>
  </anime>
</anime-list>
''');

      final entry = index.byTvdb[123]!.single;

      expect(entry.anidbId, 1);
      expect(entry.name, 'First');
      expect(entry.defaultTvdbSeason?.number, 1);
      expect(entry.episodeOffset, 2);
      expect(entry.tmdbSeason?.isAbsolute, isTrue);
      expect(entry.tmdbMovieIds, [10, 11]);
      expect(entry.imdbIds, ['tt1', 'tt2']);

      final range = entry
          .resolveEpisode(provider: AnimeListProvider.tvdb, externalSeason: 1, externalEpisode: 14)
          .single;
      expect(range.anidbEpisode, 2);
      expect(range.kind, AnimeListMatchKind.range);

      final explicit = entry
          .resolveEpisode(provider: AnimeListProvider.tvdb, externalSeason: 0, externalEpisode: 5)
          .single;
      expect(explicit.anidbSeason, 0);
      expect(explicit.anidbEpisode, 3);
      expect(explicit.kind, AnimeListMatchKind.explicit);
    });

    test('default offset maps external episodes back to AniDB local episodes', () {
      final index = parseAnimeListsIndex('''
<anime-list>
  <anime anidbid="1" tvdbid="123" defaulttvdbseason="1" episodeoffset="12">
    <name>Second Cour</name>
  </anime>
</anime-list>
''');

      final match = lookupAnimeListEpisodeInIndex(index, tvdbId: 123, season: 1, episodeNumber: 14);

      expect(match?.anidbId, 1);
      expect(match?.anidbEpisode, 2);
      expect(match?.kind, AnimeListMatchKind.defaultMapping);
    });

    test('same TVDB season split across two AniDB entries resolves by range', () {
      final index = parseAnimeListsIndex('''
<anime-list>
  <anime anidbid="1" tvdbid="123" defaulttvdbseason="1">
    <name>Cour 1</name>
    <mapping-list>
      <mapping anidbseason="1" tvdbseason="1" start="1" end="12" />
    </mapping-list>
  </anime>
  <anime anidbid="2" tvdbid="123" defaulttvdbseason="1">
    <name>Cour 2</name>
    <mapping-list>
      <mapping anidbseason="1" tvdbseason="1" start="1" end="12" offset="12" />
    </mapping-list>
  </anime>
</anime-list>
''');

      final first = lookupAnimeListEpisodeInIndex(index, tvdbId: 123, season: 1, episodeNumber: 12);
      final second = lookupAnimeListEpisodeInIndex(index, tvdbId: 123, season: 1, episodeNumber: 14);

      expect(first?.anidbId, 1);
      expect(first?.anidbEpisode, 12);
      expect(second?.anidbId, 2);
      expect(second?.anidbEpisode, 2);
    });

    test('ambiguous same-priority matches do not guess', () {
      final index = parseAnimeListsIndex('''
<anime-list>
  <anime anidbid="1" tvdbid="123" defaulttvdbseason="1"><name>A</name></anime>
  <anime anidbid="2" tvdbid="123" defaulttvdbseason="1"><name>B</name></anime>
</anime-list>
''');

      final match = lookupAnimeListEpisodeInIndex(index, tvdbId: 123, season: 1, episodeNumber: 1);

      expect(match, isNull);
    });
  });
}
