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
        : _recentItems(section, sourceHubs);
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
  final combined = output.isEmpty || sections.every((s) => s.keepSourceRows) ? [...output, ...sourceHubs] : output;
  if (rowOrder.isEmpty) return combined;
  final positions = {for (var i = 0; i < rowOrder.length; i++) rowOrder[i]: i};
  String tokenFor(MediaHub hub) {
    final custom = sections.where((section) => section.id == hub.id).firstOrNull;
    if (custom != null) return 'custom:${custom.id}';
    if (hub.libraryId != null) return 'plex:${hub.serverId ?? ''}:${hub.libraryId}:${hub.identifier ?? hub.id}';
    return '';
  }

  final sorted = combined.indexed.toList();
  sorted.sort(
    (a, b) => (positions[tokenFor(a.$2)] ?? rowOrder.length).compareTo(positions[tokenFor(b.$2)] ?? rowOrder.length),
  );
  return sorted.map((entry) => entry.$2).toList();
}

List<MediaItem> _collectionItems(HomeSectionConfig section, List<MediaItem> all, Map<String, MediaKind> libraryKinds) =>
    all.where((item) {
      if (item.kind != MediaKind.collection) return false;
      final libraryKind = libraryKinds[item.libraryGlobalKey];
      if (libraryKind != section.kind.collectionKind) return false;
      if (section.collectionKeys.isNotEmpty && !section.collectionKeys.contains(item.globalKey)) return false;
      return section.libraryKeys.isEmpty || section.libraryKeys.contains(item.libraryGlobalKey);
    }).toList();

List<MediaItem> _recentItems(HomeSectionConfig section, List<MediaHub> hubs) => [
  for (final hub in hubs)
    if (_matches(section.kind, hub))
      for (final item in hub.items)
        if (section.libraryKeys.isEmpty ||
            section.libraryKeys.contains(item.libraryGlobalKey ?? _hubLibraryGlobalKey(hub)))
          item,
];

String? _hubLibraryGlobalKey(MediaHub hub) {
  final serverId = hub.serverId;
  final libraryId = hub.libraryId;
  if (serverId == null || libraryId == null) return null;
  return buildGlobalKey(ServerId(serverId), libraryId);
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
