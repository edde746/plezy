import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../utils/external_ids.dart';

/// Builds deduplicated Recently Added / New Releases lists from Discover hubs
/// across Plex + Jellyfin (and Emby) servers.
///
/// Ordering is by library [MediaItem.addedAt] for Recently Added and by
/// premiere / originally-available date for New Releases. Cross-server
/// duplicates collapse on external catalog ids when present, else on a
/// normalized title+year key.
class SystemShelfLibraryChannels {
  SystemShelfLibraryChannels._();

  static const int maxItems = 20;

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

  /// Movies, shows, and episodes from recently-added hubs, newest [addedAt] first.
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
      sortKey: (item) => item.addedAt ?? item.updatedAt ?? 0,
    );
  }

  /// Prefers dedicated new-release hubs; otherwise re-ranks recently-added
  /// titles by premiere date so a combined Plex+Jellyfin row still appears.
  static List<MediaItem> newReleases(List<MediaHub> hubs, {int limit = maxItems}) {
    final fromReleaseHubs = <MediaItem>[];
    for (final hub in hubs) {
      if (!isNewReleasesHub(hub)) continue;
      for (final item in hub.items) {
        if (_isShelfKind(item.kind)) fromReleaseHubs.add(item);
      }
    }
    final source = fromReleaseHubs.isNotEmpty
        ? fromReleaseHubs
        : [
            for (final hub in hubs)
              if (isRecentlyAddedHub(hub))
                for (final item in hub.items)
                  if (_isShelfKind(item.kind) && _releaseSortKey(item) > 0) item,
          ];
    return _dedupeAndSort(
      source,
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

  static int _releaseSortKey(MediaItem item) {
    final raw = item.originallyAvailableAt?.trim();
    if (raw != null && raw.isNotEmpty) {
      final normalized = raw.length >= 10 ? raw.substring(0, 10) : raw;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed.millisecondsSinceEpoch ~/ 1000;
      // YYYY-MM-DD sorts lexicographically; fold to a comparable int.
      final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits.padRight(8, '0').substring(0, 8)) ?? 0;
    }
    return item.year != null ? item.year! * 10000 : 0;
  }

  static bool _isShelfKind(MediaKind kind) =>
      kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.episode;

  static Iterable<String> _semanticKeys(MediaHub hub) sync* {
    yield hub.id;
    final identifier = hub.identifier;
    if (identifier != null && identifier.isNotEmpty) yield identifier;
  }

  static final RegExp _separators = RegExp(r'[^a-z0-9]+');

  static String _compact(String raw) => raw.toLowerCase().replaceAll(_separators, '');
}
