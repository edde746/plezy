import 'package:flutter/foundation.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/title_match_candidates.dart';
import '../data_aggregation_service.dart';

/// Matches external catalog items back to the user's libraries.
///
/// One reverse-lookup fan-out per tap (see
/// `DataAggregationService.findByExternalIdsAcrossServers`), memoized for
/// the session: a complete positive wave is kept (library membership rarely
/// shrinks mid-session); negatives expire so newly-added media is picked up,
/// and so does any wave a server sat out — a slow or unreachable server is
/// not evidence of absence, and the next tap after [negativeTtl] asks it
/// again. Profile-scoped via the provider subtree, so a profile switch drops
/// the cache by construction.
class CatalogLibraryMatcher {
  static const Duration negativeTtl = Duration(minutes: 10);

  final MultiServerProvider _multiServer;
  final DateTime Function() _now;
  final Map<String, ({DateTime at, LibraryLookupResult result})> _cache = {};

  CatalogLibraryMatcher(this._multiServer) : _now = DateTime.now;

  @visibleForTesting
  CatalogLibraryMatcher.withClock(this._multiServer, this._now);

  Future<LibraryLookupResult> match(CatalogItem item) async {
    if (!item.ids.hasAny) return _nothing;
    final titles = lookupTitles(item);
    // Do not use `identityKey`: its canonical series ids make every MAL/AniList
    // season collide. All five Mushoku Tensei entries (`mal39535 s1`,
    // `mal45576 s1`, `mal51179 s2`, `mal55888 s2`, `mal59193 s3`) collapse to
    // `imdb:tt13293588`, so the first season-gated result would poison the rest.
    // Namespace by source too: MAL and AniList can share a MAL id while
    // contributing different localized title candidates. The id forms and
    // the title candidates join the key because a detail load can enrich an
    // item with external ids its row form lacked (#1715: Plex rows carry only
    // a rating key) or with alternate titles (Trakt aliases, #2098); the
    // richer lookup must not be short-circuited by the poorer form's cached
    // negative.
    final key = '${item.source.name}/${item.entryIdentityKey}/${item.ids.allKeys.join(',')}/${titles.join('\u0000')}';
    final cached = _cache[key];
    if (cached != null && (_isAuthoritativeHit(cached.result) || _now().difference(cached.at) < negativeTtl)) {
      return cached.result;
    }

    // A sequel entry's year is its own season's, not the parent show's, so a
    // ±1 window around it excludes the very show we are looking for. Fribb
    // does not map a season for every entry, so fall back to the title: a
    // strippable season suffix says "sequel" just as reliably.
    final isSequel = (item.season?.isSequel ?? false) || stripSeasonSuffix(item.title) != null;
    final result = await _multiServer.aggregationService.findByExternalIdsAcrossServers(
      item.ids.toExternalIds(),
      kind: item.kind,
      titles: titles,
      year: isSequel ? null : item.year,
      plexGuid: _plexGuidFor(item),
      season: item.season,
    );
    _cache[key] = (at: _now(), result: result);
    return result;
  }

  /// The title candidates a lookup for [item] spends its request budget on:
  /// every title the source knows, own title first, native title last (it is
  /// the one a Plex library reaches through `originalTitle` even when filed
  /// under another display title, so it earns the slot least). A detail load
  /// that adds titles changes this list, which is what tells the detail
  /// screen to ask again.
  static List<String> lookupTitles(CatalogItem item) =>
      titleMatchCandidates([item.title, ...item.altTitles, item.originalTitle]);

  static bool _isAuthoritativeHit(LibraryLookupResult result) =>
      result.items.isNotEmpty && result.failedServerIds.isEmpty && result.cancelledServerIds.isEmpty;

  static const LibraryLookupResult _nothing = (
    items: <MediaItem>[],
    succeededServerIds: <String>{},
    cancelledServerIds: <String>{},
    failedServerIds: <String>{},
  );

  /// The exact `plex://` guid for a Plex Discover item, which its own rating
  /// key already is. Free — no request, no cloud lookup; other sources get
  /// null and fall back to the title candidates.
  String? _plexGuidFor(CatalogItem item) {
    final plexId = item.ids.plex;
    if (item.source != CatalogSourceId.plex || plexId == null || plexId.isEmpty) return null;
    return 'plex://${item.kind == MediaKind.movie ? 'movie' : 'show'}/$plexId';
  }
}
