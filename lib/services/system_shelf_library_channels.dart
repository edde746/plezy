import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../utils/external_ids.dart';

/// Builds deduplicated Recently Added / New Releases lists from Discover hubs
/// across Plex + Jellyfin (and Emby) servers.
///
/// [recentlyAdded] keeps library-arrival order ([MediaItem.addedAt]).
/// [newReleases] ranks movies/shows by premiere date only — add date is
/// ignored — and drops titles older than [newReleaseMaxAgeDays] so an old
/// catalog import cannot fill the row.
class SystemShelfLibraryChannels {
  SystemShelfLibraryChannels._();

  static const int maxItems = 20;

  /// Premiere window for New Releases. Add date is intentionally ignored;
  /// this only drops theatrical / originally-available dates that are too old
  /// to count as "new" (e.g. Rise of Skywalker in a small hub pool).
  static const int newReleaseMaxAgeDays = 730;

  /// Hub keys that mean "just landed in the library".
  static bool isRecentlyAddedHub(MediaHub hub) {
    for (final key in _semanticKeys(hub)) {
      final compact = _compact(key);
      if (compact.contains('recentlyplayed') ||
          compact.contains('latestalbum') ||
          compact.contains('mostplayed') ||
          compact.contains('continue') ||
          compact.contains('nextup') ||
          compact.contains('ondeck') ||
          compact.contains('inprogress')) {
        continue;
      }
      if (compact.contains('recentlyadded') ||
          compact.endsWith('recent') ||
          (compact.contains('latest') && !compact.contains('album'))) {
        return true;
      }
    }
    return false;
  }

  /// Hub keys that mean theatrical / premiere recency (when a server exposes one).
  static bool isNewReleasesHub(MediaHub hub) {
    for (final key in _semanticKeys(hub)) {
      final compact = _compact(key);
      if (compact.contains('recentlyreleased') ||
          compact.contains('newrelease') ||
          compact.contains('newreleases') ||
          compact.contains('premiere')) {
        return true;
      }
    }
    return false;
  }

  /// Anything the server put in a recently-added / latest hub, newest library
  /// arrival first. Episodes stay — a just-added episode is a recent add.
  ///
  /// Ranking uses [MediaItem.addedAt] only (never [MediaItem.updatedAt], which
  /// follows metadata refreshes). Items missing [addedAt] still appear, last.
  static List<MediaItem> recentlyAdded(List<MediaHub> hubs, {int limit = maxItems}) {
    final items = <MediaItem>[];
    for (final hub in hubs) {
      if (!isRecentlyAddedHub(hub)) continue;
      for (final item in hub.items) {
        if (_isShelfKind(item.kind)) items.add(item);
      }
    }
    return _dedupeAndSort(
      items,
      limit: limit,
      sortKey: (item) => item.addedAt ?? 0,
    );
  }

  /// Newest movies/shows by premiere date. Library add date is ignored.
  ///
  /// Prefers dedicated new-release hubs; otherwise takes movies/shows from
  /// every Discover hub and ranks by premiere so a just-imported older film
  /// cannot outrank a newer title that simply was not in a "recent" hub.
  /// Episodes are excluded — air dates are not movie/show premieres.
  static List<MediaItem> newReleases(
    List<MediaHub> hubs, {
    int limit = maxItems,
    DateTime? now,
  }) {
    final fromReleaseHubs = <MediaItem>[];
    for (final hub in hubs) {
      if (!isNewReleasesHub(hub)) continue;
      for (final item in hub.items) {
        if (_isNewReleaseKind(item.kind)) fromReleaseHubs.add(item);
      }
    }
    final source = fromReleaseHubs.isNotEmpty
        ? fromReleaseHubs
        : [
            for (final hub in hubs)
              for (final item in hub.items)
                if (_isNewReleaseKind(item.kind)) item,
          ];
    final clock = now ?? DateTime.now();
    final fresh = [
      for (final item in source)
        if (_isFreshRelease(item, now: clock)) item,
    ];
    return _dedupeAndSort(
      fresh,
      limit: limit,
      sortKey: _releaseSortKey,
    );
  }

  static List<MediaItem> _dedupeAndSort(
    List<MediaItem> items, {
    required int limit,
    required int Function(MediaItem) sortKey,
  }) {
    final ranked = List<MediaItem>.of(items)
      ..sort((a, b) {
        final byKey = sortKey(b).compareTo(sortKey(a));
        if (byKey != 0) return byKey;
        return (a.globalKey).compareTo(b.globalKey);
      });

    final seen = <String>{};
    final out = <MediaItem>[];
    for (final item in ranked) {
      final key = dedupeKey(item);
      if (!seen.add(key)) continue;
      out.add(item);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Stable cross-server identity: catalog ids beat title+year.
  static String dedupeKey(MediaItem item) {
    final ids = externalIdsOf(item);
    if (ids != null && ids.hasCatalogIds) {
      if (ids.imdb != null) return 'imdb:${ids.imdb}';
      if (ids.tmdb != null) return 'tmdb:${item.kind.name}:${ids.tmdb}';
      if (ids.tvdb != null) return 'tvdb:${item.kind.name}:${ids.tvdb}';
    }
    if (item.kind == MediaKind.episode) {
      final show = (item.grandparentTitle ?? item.parentTitle ?? item.title ?? '').trim().toLowerCase();
      return 'ep:$show|${item.parentIndex ?? 0}|${item.index ?? 0}|${item.year ?? 0}';
    }
    final title = (item.title ?? '').trim().toLowerCase();
    return '${item.kind.name}:$title|${item.year ?? 0}';
  }

  static ExternalIds? externalIdsOf(MediaItem item) {
    final raw = item.raw;
    ExternalIds fromRaw = const ExternalIds();
    if (raw != null) {
      final guids = raw['Guid'];
      if (guids is List) {
        fromRaw = ExternalIds.fromGuids(guids);
      }
      final providerIds = raw['ProviderIds'];
      if (providerIds is Map) {
        fromRaw = fromRaw.fillFrom(
          ExternalIds.fromJellyfinProviderIds(providerIds.cast<String, Object?>()),
        );
      }
    }
    final legacy = ExternalIds.fromLegacyPlexGuid(item.guid);
    final merged = fromRaw.fillFrom(legacy);
    return merged.hasAny ? merged : null;
  }

  /// Premiere / year as YYYYMMDD so year-only and fully-dated values share a
  /// scale. Mixing epoch-seconds with `year * 10000` let a dated 2019 film
  /// outrank a 2024 title that only had a year.
  static int _releaseSortKey(MediaItem item) {
    final raw = item.originallyAvailableAt?.trim();
    if (raw != null && raw.isNotEmpty) {
      final normalized = raw.length >= 10 ? raw.substring(0, 10) : raw;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.year * 10000 + parsed.month * 100 + parsed.day;
      }
      final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 8) {
        return int.tryParse(digits.substring(0, 8)) ?? 0;
      }
      if (digits.length >= 4) {
        final year = int.tryParse(digits.substring(0, 4));
        if (year != null) return year * 10000;
      }
    }
    return item.year != null ? item.year! * 10000 : 0;
  }

  static bool _isFreshRelease(MediaItem item, {required DateTime now}) {
    final key = _releaseSortKey(item);
    if (key <= 0) return false;
    final cutoff = now.subtract(const Duration(days: newReleaseMaxAgeDays));
    final cutoffKey = cutoff.year * 10000 + cutoff.month * 100 + cutoff.day;
    return key >= cutoffKey;
  }

  static bool _isShelfKind(MediaKind kind) =>
      kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.episode;

  static bool _isNewReleaseKind(MediaKind kind) =>
      kind == MediaKind.movie || kind == MediaKind.show;

  static Iterable<String> _semanticKeys(MediaHub hub) sync* {
    yield hub.id;
    final identifier = hub.identifier;
    if (identifier != null && identifier.isNotEmpty) yield identifier;
  }

  static final RegExp _separators = RegExp(r'[^a-z0-9]+');

  static String _compact(String raw) => raw.toLowerCase().replaceAll(_separators, '');
}
