import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/catalog/catalog_item.dart';

void main() {
  group('CatalogItemIds', () {
    test('round-trips provider-native ids through JSON', () {
      const ids = CatalogItemIds(
        plex: 'plex-4',
        trakt: 8,
        slug: 'title',
        mal: 5,
        anilist: 6,
        simkl: 7,
        imdb: 'tt123',
        tmdb: 2,
        tvdb: 3,
      );

      final json = ids.toJson();
      final decoded = CatalogItemIds.fromJson(json);

      expect(json, {
        'plex': 'plex-4',
        'trakt': 8,
        'slug': 'title',
        'mal': 5,
        'anilist': 6,
        'simkl': 7,
        'imdb': 'tt123',
        'tmdb': 2,
        'tvdb': 3,
      });
      expect(decoded.plex, 'plex-4');
      expect(decoded.anilist, 6);
      expect(decoded.simkl, 7);
      expect(decoded.hasAny, isTrue);
    });

    test('orders canonical and membership keys deterministically', () {
      const ids = CatalogItemIds(
        plex: 'plex-4',
        trakt: 8,
        slug: 'title',
        mal: 5,
        anilist: 6,
        simkl: 7,
        imdb: 'tt123',
        tmdb: 2,
        tvdb: 3,
      );

      expect(ids.canonicalKey, 'imdb:tt123');
      expect(ids.allKeys, [
        'imdb:tt123',
        'tmdb:2',
        'tvdb:3',
        'mal:5',
        'anilist:6',
        'simkl:7',
        'plex:plex-4',
        'trakt:8',
        'slug:title',
      ]);
      expect(const CatalogItemIds(mal: 5, anilist: 6, simkl: 7).canonicalKey, 'mal:5');
      expect(const CatalogItemIds(anilist: 6, simkl: 7).canonicalKey, 'anilist:6');
      expect(const CatalogItemIds(simkl: 7, trakt: 8).canonicalKey, 'simkl:7');
      expect(const CatalogItemIds(plex: 'plex-4', trakt: 8).canonicalKey, 'plex:plex-4');
    });
  });
}
