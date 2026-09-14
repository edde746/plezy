import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/utils/search_relevance.dart';

import '../test_helpers/media_items.dart';

void main() {
  group('normalizeSearchText', () {
    test('normalizes canonical, compatibility, separator, and typography variants', () {
      expect(normalizeSearchText('Amélie'), normalizeSearchText('Ame\u0301lie'));
      expect(normalizeSearchText('Ａｍｅｌｉｅ'), normalizeSearchText('Amelie'));
      expect(normalizeSearchText('Spider\u00a0Man'), normalizeSearchText('Spider Man'));

      final expected = normalizeSearchText('Spider Man');
      for (final value in ['Spider-Man', 'Spider‑Man', 'Spider–Man', 'Spider—Man']) {
        expect(normalizeSearchText(value), expected, reason: value);
      }
    });

    test('preserves accents and script-significant marks', () {
      expect(normalizeSearchText('Cafe'), isNot(normalizeSearchText('Café')));
      expect(normalizeSearchText('Café'), normalizeSearchText('Cafe\u0301'));
      expect(normalizeSearchText('क'), isNot(normalizeSearchText('कि')));
      expect(normalizeSearchText('कि'), contains('ि'));
    });
  });

  group('media search ranking', () {
    test('does not give an English-only leading article bonus', () {
      final items = [
        testMediaItem(id: 'the', title: 'The Boys'),
        testMediaItem(id: 'les', title: 'Les Boys'),
        testMediaItem(id: 'los', title: 'Los Boys'),
      ];

      expect(_ids(rankMediaSearchResults(items, 'Boys')), ['the', 'les', 'los']);
      expect(_ids(rankMediaSearchResults(items.reversed.toList(), 'Boys')), ['los', 'les', 'the']);
    });

    test('keeps exact titles above longer prefixes', () {
      final items = [
        testMediaItem(id: 'longer', title: 'The Boys in the Boat'),
        testMediaItem(id: 'exact', title: 'The Boys'),
      ];

      expect(_ids(rankMediaSearchResults(items, 'The Boys')), ['exact', 'longer']);
    });

    test('preserves nullable-field weighting', () {
      final items = [
        testMediaItem(id: 'parent', parentTitle: 'Target'),
        testMediaItem(id: 'original', originalTitle: 'Target'),
      ];

      expect(_ids(rankMediaSearchResults(items, 'Target')), ['original', 'parent']);
    });
  });

  group('rankMediaSearchResults', () {
    test('ranks equivalent query forms identically and preserves normalized ties', () {
      final items = [
        testMediaItem(id: 'first', title: 'Spider-Man'),
        testMediaItem(id: 'second', title: 'Spider‑Man'),
        testMediaItem(id: 'third', title: 'Spider Man Returns'),
        testMediaItem(id: 'accented', title: 'Amélie'),
        testMediaItem(id: 'decomposed', title: 'Ame\u0301lie'),
      ];

      final asciiOrder = _ids(rankMediaSearchResults(items, 'Spider Man'));
      final compatibilityOrder = _ids(rankMediaSearchResults(items, 'Ｓｐｉｄｅｒ　Ｍａｎ'));
      final typographicOrder = _ids(rankMediaSearchResults(items, 'Spider—Man'));

      expect(compatibilityOrder, asciiOrder);
      expect(typographicOrder, asciiOrder);
      expect(asciiOrder.take(2), ['first', 'second']);
      expect(_ids(rankMediaSearchResults(items, 'Spider Man', limit: 1)), ['first']);
      expect(_ids(rankMediaSearchResults(items, 'Amélie')).take(2), ['accented', 'decomposed']);
    });

    test('bounded selection matches the unbounded full ordering for a large input', () {
      final items = <MediaItem>[
        for (var i = 0; i < 1000; i++)
          testMediaItem(
            id: 'item-$i',
            title: switch (i) {
              999 => 'Target',
              _ when i % 137 == 0 => 'Target result $i',
              _ when i % 41 == 0 => 'A Target result $i',
              _ => 'Candidate $i',
            },
          ),
      ];
      final expected = _fullyRankedIds(items, 'Target').take(100).toList();

      expect(_ids(rankMediaSearchResults(items, 'Target', limit: 100)), expected);
      expect(expected.first, 'item-999');
    });

    test('retains the earliest items when an equal-score run crosses the cap', () {
      final items = [for (var i = 0; i < 150; i++) testMediaItem(id: 'tie-$i', title: 'Same title')];

      expect(_ids(rankMediaSearchResults(items, 'Same title', limit: 100)), [for (var i = 0; i < 100; i++) 'tie-$i']);
    });

    test('preserves limit boundaries, full ordering, and empty-query input order', () {
      final items = [
        testMediaItem(id: 'prefix', title: 'Target Extended'),
        testMediaItem(id: 'exact', title: 'Target'),
        testMediaItem(id: 'contains', title: 'A Target Story'),
      ];
      final expected = _fullyRankedIds(items, 'Target');

      expect(rankMediaSearchResults(items, 'Target', limit: 0), isEmpty);
      expect(_ids(rankMediaSearchResults(items, 'Target', limit: 1)), ['exact']);
      expect(_ids(rankMediaSearchResults(items, 'Target', limit: items.length)), expected);
      expect(_ids(rankMediaSearchResults(items, 'Target', limit: items.length + 5)), expected);
      expect(_ids(rankMediaSearchResults(items, 'Target')), expected);
      expect(_ids(rankMediaSearchResults(items, '— ‑ !!!', limit: 2)), ['prefix', 'exact']);
    });

    test('keeps the negative-limit failure contract', () {
      final items = [testMediaItem(title: 'Target')];

      expect(() => rankMediaSearchResults(items, 'Target', limit: -1), throwsRangeError);
      expect(() => rankMediaSearchResults(items, '!!!', limit: -1), throwsRangeError);
    });
  });
}

List<String> _ids(Iterable<MediaItem> items) => [for (final item in items) item.id];

List<String> _fullyRankedIds(List<MediaItem> items, String query) => _ids(rankMediaSearchResults(items, query));
