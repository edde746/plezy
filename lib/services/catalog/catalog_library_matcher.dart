import 'package:flutter/foundation.dart';

import '../../media/media_item.dart';
import '../../media/media_item_merge.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/title_match_candidates.dart';
import '../data_aggregation_service.dart';

/// Matches external catalog items back to the user's libraries.
///
/// One reverse-lookup fan-out per tap (see
/// `DataAggregationService.findByExternalIdsAcrossServers`), memoized for
/// the session per server: a server's answer is replaced only by that
/// server. A wave every expected server answered is kept when positive
/// (library membership rarely shrinks mid-session); negatives expire so
/// newly-added media is picked up, and so does any wave a server sat out —
/// a server that failed, was cancelled, or was never asked at all because
/// it is offline is not evidence of absence, and the next tap after
/// [negativeTtl] asks it again while its last-known copies stay on screen.
/// Profile-scoped via the provider subtree. Membership changes invalidate
/// coverage immediately and discard copies belonging to departed servers.
class CatalogLibraryMatcher {
  static const Duration negativeTtl = Duration(minutes: 10);

  final MultiServerProvider _multiServer;
  final DateTime Function() _now;
  final Map<String, _Entry> _cache = {};
  Set<String> _serverIds = {};
  int _scopeGeneration = 0;

  CatalogLibraryMatcher(this._multiServer) : _now = DateTime.now {
    _listenToServerScope();
  }

  @visibleForTesting
  CatalogLibraryMatcher.withClock(this._multiServer, this._now) {
    _listenToServerScope();
  }

  void _listenToServerScope() {
    _syncServerScope();
    _multiServer.addListener(_syncServerScope);
  }

  void _syncServerScope() {
    final serverIds = _multiServer.expectedServerIds.toSet();
    if (setEquals(serverIds, _serverIds)) return;
    _serverIds = serverIds;
    _scopeGeneration++;
    for (final entry in _cache.values) {
      entry.byServer.removeWhere((serverId, _) => !serverIds.contains(serverId));
    }
  }

  void dispose() => _multiServer.removeListener(_syncServerScope);

  Future<LibraryLookupResult> match(CatalogItem item) async {
    _syncServerScope();
    final scopeGeneration = _scopeGeneration;
    final titles = lookupTitles(item);
    // Do not use `identityKey`: its canonical series ids make every MAL/AniList
    // season collide. All five Mushoku Tensei entries (`mal39535 s1`,
    // `mal45576 s1`, `mal51179 s2`, `mal55888 s2`, `mal59193 s3`) collapse to
    // `imdb:tt13293588`, so the first season-gated result would poison the rest.
    // Namespace by source too: MAL and AniList can share a MAL id while
    // carrying different titles. The id forms and the title candidates join
    // the key because a detail load can enrich an item with external ids its
    // row form lacked (#1715: Plex rows carry only a rating key) or with the
    // native title; the richer lookup must not be short-circuited by the
    // poorer form's cached negative.
    final key = '${item.source.name}/${item.entryIdentityKey}/${item.ids.allKeys.join(',')}/${titles.join('\u0000')}';
    final cached = _cache[key];
    if (cached != null &&
        cached.scopeGeneration == scopeGeneration &&
        (_isAuthoritativeHit(cached.result) || _now().difference(cached.at) < negativeTtl)) {
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
      serverIds: _serverIds,
      titles: titles,
      year: isSequel ? null : item.year,
      plexGuid: _plexGuidFor(item),
      season: item.season,
    );
    // A membership update while HTTP was in flight invalidates that wave too.
    _syncServerScope();
    if (scopeGeneration != _scopeGeneration) return match(item);
    final entry = _fold(cached?.byServer, result);
    _cache[key] = entry;
    return entry.result;
  }

  /// Fold a wave into the last-known per-server answers.
  ///
  /// Stated positively: only a server in the succeeded set may replace its
  /// own entry, because it is the only one that just answered. Servers in
  /// the failed, cancelled or unqueried sets keep their previous copies — a
  /// timeout, a client abort, and an expected server that could not execute
  /// the query are none of them evidence of removal (#2098) —
  /// and their sets pass through so the UI still names them unchecked and
  /// the wave is retried after [negativeTtl]. Everything else is dropped:
  /// a server in none of the four sets is no longer on the account.
  ///
  /// Membership is the answering server's to define, but each copy it
  /// returns again is folded onto its predecessor by [mergeLibraryCopy]:
  /// the library stamp is best-effort, and a retry that lost it must not
  /// overwrite a labeled copy with an unlabeled one for the rest of the
  /// session.
  _Entry _fold(Map<String?, List<MediaItem>>? previous, LibraryLookupResult result) {
    bool sawNoAnswerFrom(String? serverId) =>
        result.failedServerIds.contains(serverId) ||
        result.cancelledServerIds.contains(serverId) ||
        result.unqueriedServerIds.contains(serverId);
    final byServer = <String?, List<MediaItem>>{};
    // Copies of the servers that just answered, about to be replaced by
    // whatever they returned this time.
    final replaced = <String, MediaItem>{};
    for (final MapEntry(:key, :value) in previous?.entries ?? const <MapEntry<String?, List<MediaItem>>>[]) {
      if (sawNoAnswerFrom(key)) {
        byServer[key] = value;
      } else {
        for (final item in value) {
          replaced[item.globalKey] = item;
        }
      }
    }
    for (final item in result.items) {
      final prior = replaced[item.globalKey];
      (byServer[item.serverId] ??= []).add(prior == null ? item : mergeLibraryCopy(prior, item));
    }
    // Carried and enriched copies are absent from `result.items`, so a wave
    // with a predecessor is rebuilt around them; a first wave already is the
    // whole answer.
    return (
      at: _now(),
      scopeGeneration: _scopeGeneration,
      byServer: byServer,
      result: previous == null
          ? result
          : (
              items: [for (final items in byServer.values) ...items]..sort(compareLibraryCopies),
              succeededServerIds: result.succeededServerIds,
              cancelledServerIds: result.cancelledServerIds,
              failedServerIds: result.failedServerIds,
              unqueriedServerIds: result.unqueriedServerIds,
            ),
    );
  }

  /// The title candidates a lookup for [item] spends its request budget on.
  ///
  /// Native title first: both backends index `originalTitle` alongside the
  /// display title (Plex `/hubs/search`, Jellyfin `SearchTerm`; verified on
  /// PMS 1.43 and Jellyfin 10.11), and every copy of a foreign title carries
  /// the same `originalTitle` whatever language it is filed under — English,
  /// romaji, localized or native. One query with it reaches all of them
  /// (#2098). The item's own title follows for the catalog/agent spelling
  /// drift the native form can suffer, and each brings its season-stripped
  /// form for sequel entries. Alternate titles are not candidates: the
  /// copies they used to reach are exactly the ones the native title reaches.
  ///
  /// A detail load that changes this list is what tells the detail screen
  /// to ask again.
  static List<String> lookupTitles(CatalogItem item) => titleMatchCandidates([item.originalTitle, item.title]);

  /// Whether [result] may be memoized for the rest of the session: a hit
  /// every expected server took part in. One that sat out — failed,
  /// cancelled or never asked — leaves the answer incomplete, so it expires
  /// with [negativeTtl] instead of being cached until the profile switches.
  static bool _isAuthoritativeHit(LibraryLookupResult result) =>
      result.items.isNotEmpty &&
      result.failedServerIds.isEmpty &&
      result.cancelledServerIds.isEmpty &&
      result.unqueriedServerIds.isEmpty;

  /// The exact `plex://` guid for a Plex Discover item, which its own rating
  /// key already is. Free — no request, no cloud lookup; other sources get
  /// null and fall back to the title candidates.
  String? _plexGuidFor(CatalogItem item) {
    final plexId = item.ids.plex;
    if (item.source != CatalogSourceId.plex || plexId == null || plexId.isEmpty) return null;
    return 'plex://${item.kind == MediaKind.movie ? 'movie' : 'show'}/$plexId';
  }
}

/// Last-known copies keyed by [MediaItem.serverId] alongside the wave they
/// assemble into; [at] stamps the newest wave for [CatalogLibraryMatcher.negativeTtl].
typedef _Entry = ({
  DateTime at,
  int scopeGeneration,
  Map<String?, List<MediaItem>> byServer,
  LibraryLookupResult result,
});
