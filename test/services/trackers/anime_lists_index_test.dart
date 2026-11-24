import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/anime_lists_mapping.dart';
import 'package:plezy/services/trackers/anime_lists_index.dart';

AnimeListEpisodeMapping _tvdbRange({required int start, required int end, int offset = 0}) => AnimeListEpisodeMapping(
  anidbSeason: 1,
  provider: AnimeListProvider.tvdb,
  externalSeason: 1,
  start: start,
  end: end,
  offset: offset,
);

void main() {
  group('AnimeListsIndex.lookupEpisode', () {
    test('default offset maps external episodes back to AniDB local episodes', () {
      final index = AnimeListsIndex.fromEntries(const [
        AnimeListEntry(anidbId: 1, tvdbId: 123, defaultTvdbSeason: AnimeListSeasonRef.number(1), episodeOffset: 12),
      ]);

      final match = index.lookupEpisode(tvdbId: 123, season: 1, episodeNumber: 14);

      expect(match?.anidbId, 1);
      expect(match?.anidbEpisode, 2);
      expect(match?.kind, AnimeListMatchKind.defaultMapping);
    });

    test('same TVDB season split across two AniDB entries resolves by range', () {
      final index = AnimeListsIndex.fromEntries([
        AnimeListEntry(
          anidbId: 1,
          tvdbId: 123,
          defaultTvdbSeason: const AnimeListSeasonRef.number(1),
          mappings: [_tvdbRange(start: 1, end: 12)],
        ),
        AnimeListEntry(
          anidbId: 2,
          tvdbId: 123,
          defaultTvdbSeason: const AnimeListSeasonRef.number(1),
          mappings: [_tvdbRange(start: 1, end: 12, offset: 12)],
        ),
      ]);

      final first = index.lookupEpisode(tvdbId: 123, season: 1, episodeNumber: 12);
      final second = index.lookupEpisode(tvdbId: 123, season: 1, episodeNumber: 14);

      expect(first?.anidbId, 1);
      expect(first?.anidbEpisode, 12);
      expect(second?.anidbId, 2);
      expect(second?.anidbEpisode, 2);
    });

    test('ambiguous same-priority matches do not guess', () {
      final index = AnimeListsIndex.fromEntries(const [
        AnimeListEntry(anidbId: 1, tvdbId: 123, defaultTvdbSeason: AnimeListSeasonRef.number(1)),
        AnimeListEntry(anidbId: 2, tvdbId: 123, defaultTvdbSeason: AnimeListSeasonRef.number(1)),
      ]);

      final match = index.lookupEpisode(tvdbId: 123, season: 1, episodeNumber: 1);

      expect(match, isNull);
    });
  });
}
