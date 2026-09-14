import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/utils/external_ids.dart';

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
    test('entryKey identifies the entry, not the series it shares with its seasons', () {
      // Every MAL/AniList season of one show carries the same series ids, so
      // canonicalKey collides across seasons and cannot key a season-gated
      // result. All five Mushoku Tensei entries collapse to imdb:tt13293588.
      const s1 = CatalogItemIds(mal: 39535, imdb: 'tt13293588', tmdb: 94664, tvdb: 371310);
      const s2 = CatalogItemIds(mal: 51179, imdb: 'tt13293588', tmdb: 94664, tvdb: 371310);

      expect(s1.canonicalKey, s2.canonicalKey);
      expect(s1.entryKey, 'mal:39535');
      expect(s2.entryKey, 'mal:51179');
      expect(const CatalogItemIds(anilist: 6, imdb: 'tt1').entryKey, 'anilist:6');
      // Falls back to the series id when the entry has no provider-native id.
      expect(const CatalogItemIds(imdb: 'tt1').entryKey, 'imdb:tt1');
    });
  });

  group('CatalogItem', () {
    const item = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'You and I Are Polar Opposites Season 2',
      altTitles: ['Seihantai na Kimi to Boku 2nd Season', '\u6b63\u53cd\u5bfe\u306a\u541b\u3068\u50d5 \u7b2c2\u671f'],
      season: ExternalSeasonRef(tvdb: 2, tmdb: 1),
      year: 2026,
      ids: CatalogItemIds(anilist: 210031, mal: 63832, tvdb: 457078),
    );

    test('survives the MediaItem.raw round trip the detail screen relies on', () {
      // The Explore detail screen rebuilds the item out of MediaItem.raw, so a
      // field that does not survive this seam silently disables the match fix
      // in production while every source-level test still passes.
      final raw = item.toMediaItem().raw?[CatalogItem.rawKey] as Map<String, Object?>?;
      final decoded = CatalogItem.fromJson(raw!);

      expect(decoded.altTitles, item.altTitles);
      expect(decoded.season, const ExternalSeasonRef(tvdb: 2, tmdb: 1));
      expect(decoded.title, item.title);
      expect(decoded.ids.entryKey, 'mal:63832');
    });

    test('carries every attributed rating onto the synthesized MediaItem', () {
      // Explore's dashboard hubs render through this conversion, so a rating
      // dropped here means the TV spotlight silently falls back to one score.
      const rated = CatalogItem(
        source: CatalogSourceId.simkl,
        kind: MediaKind.movie,
        title: 'Rated',
        ids: CatalogItemIds(tmdb: 603),
        rating: 8.1,
        ratings: [
          MediaRatingSource(source: 'simkl', value: 8.1, votes: 11),
          MediaRatingSource(source: 'imdb', value: 7.9, votes: 12),
        ],
      );

      final rendered = rated.toMediaItem();

      expect(rendered.rating, 8.1);
      expect(rendered.ratings?.map((rating) => rating.source), ['simkl', 'imdb']);
      expect(rendered.ratings?.last.votes, 12);
    });

    test('survives an encode/decode cycle that erases the static map types', () {
      // Persisted/transport JSON comes back as Map<String, dynamic> and
      // List<dynamic>; the nested season object must not depend on its
      // compile-time type to be read back.
      final decoded = CatalogItem.fromJson(jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>);

      expect(decoded.altTitles, item.altTitles);
      expect(decoded.season?.tvdb, 2);
      expect(decoded.season?.tmdb, 1);
      expect(decoded.season?.isSequel, isTrue);
      expect(decoded.season?.agreedSeason, isNull);
    });

    test('omits both new fields when absent rather than emitting empties', () {
      const bare = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.movie,
        title: 'Solo Movie',
        ids: CatalogItemIds(imdb: 'tt1'),
      );

      expect(bare.toJson().containsKey('altTitles'), isFalse);
      expect(bare.toJson().containsKey('season'), isFalse);
      final decoded = CatalogItem.fromJson(bare.toJson());
      expect(decoded.altTitles, isEmpty);
      expect(decoded.season, isNull);
    });

    test('enrichedWith unions audience counters instead of replacing them', () {
      // A Simkl trending row supplies windowed viewers and planning; its
      // detail body supplies only a drop rate. Replacing the object wholesale
      // silently dropped the row's counters.
      const row = CatalogItem(
        source: CatalogSourceId.simkl,
        kind: MediaKind.show,
        title: 'House of the Dragon',
        ids: CatalogItemIds(simkl: 1197910),
        audience: CatalogAudience(viewers: 7603, viewersPeriod: CatalogAudiencePeriod.week, planning: 8422),
      );
      const detail = CatalogItem(
        source: CatalogSourceId.simkl,
        kind: MediaKind.show,
        title: 'House of the Dragon',
        ids: CatalogItemIds(simkl: 1197910),
        audience: CatalogAudience(dropRate: 0.031),
      );

      final merged = row.enrichedWith(detail).audience!;
      expect(merged.viewers, 7603);
      expect(merged.viewersPeriod, CatalogAudiencePeriod.week);
      expect(merged.planning, 8422);
      expect(merged.dropRate, 0.031);
    });

    test('enrichedWith lets detail replace a row value and merges ids per key', () {
      const row = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.movie,
        title: 'The Matrix',
        ids: CatalogItemIds(imdb: 'tt0133093'),
        ranks: [CatalogRank(rank: 3, scope: CatalogRankScope.trending, allTime: false)],
      );
      const detail = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.movie,
        title: 'The Matrix',
        overview: 'A full synopsis the row never carried.',
        ids: CatalogItemIds(tmdb: 603),
      );

      final merged = row.enrichedWith(detail);
      expect(merged.overview, 'A full synopsis the row never carried.');
      expect(merged.ids.imdb, 'tt0133093', reason: 'row-only id must survive');
      expect(merged.ids.tmdb, 603, reason: 'detail id must be adopted');
      expect(merged.ranks?.single.rank, 3, reason: 'a rank is row context a detail body cannot know');
    });
  });
}
