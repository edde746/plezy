import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/episode_collection.dart';

MediaItem _ep(int season, int episode) => MediaItem(
  id: 's${season}e$episode',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'S${season}E$episode',
  parentIndex: season,
  index: episode,
);

void main() {
  group('episodeAiringOrder', () {
    test('sorts by season then episode, missing indices first', () {
      final items = [
        _ep(2, 1),
        _ep(1, 3),
        _ep(1, 1),
        MediaItem(id: 'x', backend: MediaBackend.plex, kind: MediaKind.episode),
      ]..sort(episodeAiringOrder);
      expect(items.map((e) => e.id), ['x', 's1e1', 's1e3', 's2e1']);
    });
  });

  group('selectEpisodesForDownload', () {
    final pool = [for (var e = 1; e <= 20; e++) _ep(1, e)];

    test('returns the pool unchanged when random is off', () {
      expect(selectEpisodesForDownload(pool, maxCount: 5, random: false), same(pool));
    });

    test('returns the pool unchanged when there is no count cap', () {
      expect(selectEpisodesForDownload(pool, maxCount: null, random: true), same(pool));
    });

    test('returns the pool unchanged when the cap covers the whole pool', () {
      expect(selectEpisodesForDownload(pool, maxCount: 20, random: true), same(pool));
      expect(selectEpisodesForDownload(pool, maxCount: 999, random: true), same(pool));
    });

    test('random pick returns exactly maxCount items, all from the pool', () {
      final picked = selectEpisodesForDownload(pool, maxCount: 5, random: true, rng: Random(7));
      expect(picked, hasLength(5));
      final poolIds = pool.map((e) => e.id).toSet();
      expect(picked.every((e) => poolIds.contains(e.id)), isTrue);
      expect(picked.map((e) => e.id).toSet(), hasLength(5)); // no duplicates
    });

    test('random pick is restored to airing order', () {
      final picked = selectEpisodesForDownload(pool, maxCount: 6, random: true, rng: Random(123));
      final episodeNumbers = picked.map((e) => e.index!).toList();
      final sorted = [...episodeNumbers]..sort();
      expect(episodeNumbers, sorted);
    });

    test('same seed yields the same selection (deterministic seam)', () {
      final a = selectEpisodesForDownload(pool, maxCount: 5, random: true, rng: Random(42));
      final b = selectEpisodesForDownload(pool, maxCount: 5, random: true, rng: Random(42));
      expect(a.map((e) => e.id), b.map((e) => e.id));
    });

    test('selection genuinely varies across seeds (not just the first N)', () {
      final outcomes = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final picked = selectEpisodesForDownload(pool, maxCount: 5, random: true, rng: Random(seed));
        outcomes.add(picked.map((e) => e.id).join(','));
      }
      // Fixed seeds make this deterministic; many distinct subsets prove the
      // selection is actually randomised rather than always the leading slice.
      expect(outcomes.length, greaterThan(1));
      final firstFive = pool.take(5).map((e) => e.id).join(',');
      expect(outcomes, isNot(everyElement(firstFive)));
    });
  });
}
