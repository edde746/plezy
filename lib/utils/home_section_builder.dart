import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/home_section_config.dart';
import '../media/ids.dart';
import '../utils/global_key_utils.dart';

/// Builds user-defined Home rows from normalized hubs and real collection items.
List<MediaHub> buildConfiguredHomeSections({
  required List<MediaHub> sourceHubs,
  required List<MediaItem> collections,
  required List<HomeSectionConfig> sections,
  Map<String, MediaKind> collectionLibraryKinds = const {},
  List<String> rowOrder = const [],
}) {
  final output = <MediaHub>[];
  for (final section in sections.where((s) => s.enabled && s.showOnHome)) {
    final items = section.isCollectionRow
        ? _collectionItems(section, collections, collectionLibraryKinds)
        : _recentItems(section, sourceHubs.where((hub) => _matches(section.kind, hub)).toList());
    if (items.isEmpty) continue;
    output.add(
      MediaHub(
        id: section.id,
        identifier: 'configured.${section.kind.id}',
        title: section.title,
        type: section.isCollectionRow ? 'collection' : 'mixed',
        items: _dedupe(items),
        size: items.length,
      ),
    );
  }
  final combined = [...output, ...sourceHubs];
  if (rowOrder.isEmpty) return combined;

  // home_row_order (the Organizer, what Settings actually shows and lets the
  // user edit) is the single source of truth for which rows appear on Home
  // and in what order, once it's non-empty -- not a secondary sort layered
  // over a separately decided content list, and not a sort-with-fallback
  // that silently re-adds anything the user removed. A merged row and the
  // specific raw hub it draws from can both have their own token here; if
  // the user doesn't want the raw one showing too, they remove its row
  // directly in the Organizer, and that removal has to actually stick. A hub
  // with no library id can never get a token at all (nothing to remove it
  // by), so it always shows, same as before this feature existed.
  //
  // A saved Plex token's identifier can't be compared for exact equality
  // against a fetched hub's identifier: the Organizer's token comes from
  // Plex's hub-*management* endpoint (fetchManagedHubs), while the hub shown
  // on Home comes from its hub-*content* endpoints -- Plex itself returns a
  // different identifier string for the same conceptual hub across those two
  // APIs (e.g. "movie.recentlyreleased" vs. "movie.recentlyreleased.7",
  // confirmed live). The content identifier always extends the managed one
  // as a dot-separated suffix, so matching is done per (server, library) by
  // identifier-prefix rather than by exact string.
  final custom = <String, MediaHub>{};
  final byLibrary = <String, List<MediaHub>>{};
  final untrackable = <MediaHub>[];
  for (final hub in combined) {
    final customSection = sections.where((section) => section.id == hub.id).firstOrNull;
    if (customSection != null) {
      custom['custom:${customSection.id}'] = hub;
      continue;
    }
    final libraryId = _hubLibraryId(hub);
    if (libraryId == null) {
      untrackable.add(hub);
      continue;
    }
    (byLibrary['${hub.serverId ?? ''}:$libraryId'] ??= []).add(hub);
  }

  MediaHub? resolvePlexToken(String token) {
    final parts = token.split(':');
    if (parts.length < 4 || parts[0] != 'plex') return null;
    final wantedIdentifier = parts.sublist(3).join(':');
    final candidates = byLibrary['${parts[1]}:${parts[2]}'] ?? const [];
    for (final hub in candidates) {
      final actual = hub.identifier ?? hub.id;
      if (actual == wantedIdentifier || actual.startsWith('$wantedIdentifier.')) return hub;
    }
    return null;
  }

  final usedHubs = <MediaHub>{};
  final ordered = <MediaHub>[];
  for (final token in rowOrder) {
    final hub = token.startsWith('custom:') ? custom[token] : resolvePlexToken(token);
    if (hub != null && usedHubs.add(hub)) ordered.add(hub);
  }
  return [...ordered, ...untrackable];
}

List<MediaItem> _collectionItems(HomeSectionConfig section, List<MediaItem> all, Map<String, MediaKind> libraryKinds) =>
    all.where((item) {
      if (item.kind != MediaKind.collection) return false;
      final libraryKind = libraryKinds[item.libraryGlobalKey];
      if (libraryKind != section.kind.collectionKind) return false;
      if (section.collectionKeys.isNotEmpty && !section.collectionKeys.contains(item.globalKey)) return false;
      return section.libraryKeys.isEmpty || section.libraryKeys.contains(item.libraryGlobalKey);
    }).toList();

/// [matchedHubs] are already filtered to this section's kind (see the
/// caller) so this only applies the section's own library selection.
List<MediaItem> _recentItems(HomeSectionConfig section, List<MediaHub> matchedHubs) {
  final items = [
    for (final hub in matchedHubs)
      for (final item in hub.items)
        if (section.libraryKeys.isEmpty ||
            section.libraryKeys.contains(item.libraryGlobalKey ?? _hubLibraryGlobalKey(hub)))
          item,
  ];
  // Items above are grouped one source hub at a time (every movie-library item,
  // then every show-library item, ...), so a merged row needs its own sort or
  // it renders as library-sized blocks rather than one interleaved timeline.
  items.sort(_recencyComparator(section.kind));
  return items;
}

int Function(MediaItem, MediaItem) _recencyComparator(HomeSectionKind kind) =>
    kind == HomeSectionKind.recentlyReleased
        ? (a, b) => (b.originallyAvailableAt ?? '').compareTo(a.originallyAvailableAt ?? '')
        : (a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0);

String? _hubLibraryGlobalKey(MediaHub hub) {
  final serverId = hub.serverId;
  final libraryId = _hubLibraryId(hub);
  if (serverId == null || libraryId == null) return null;
  return buildGlobalKey(ServerId(serverId), libraryId);
}

/// The Plex client never sets [MediaHub.libraryId] itself (the section id it
/// computes per hub only gets pushed down onto that hub's own items), so a
/// hub has to borrow one of its item's library ids instead -- the same
/// fallback media_hub_ordering.dart's own library sort already relies on.
String? _hubLibraryId(MediaHub hub) {
  final direct = hub.libraryId;
  if (direct != null) return direct;
  for (final item in hub.items) {
    final itemLibraryId = item.libraryId;
    if (itemLibraryId != null) return itemLibraryId;
  }
  return null;
}

bool _matches(HomeSectionKind kind, MediaHub hub) {
  final values = [hub.id, hub.identifier, hub.title].whereType<String>().map(_compact);
  return switch (kind) {
    HomeSectionKind.recentlyAdded => values.any(
      (v) => v.contains('recentlyadded') || v == 'latest' || v.contains('latestin'),
    ),
    HomeSectionKind.recentlyReleased => values.any(
      (v) => v.contains('recentlyreleased') || v.contains('newlyreleased') || v.contains('recentlyavailable'),
    ),
    _ => false,
  };
}

String _compact(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

List<MediaItem> _dedupe(List<MediaItem> items) {
  final seen = <String>{};
  return items.where((item) => seen.add(item.globalKey)).toList(growable: false);
}
