import 'media_item.dart';
import 'media_kind.dart';
import '../sources/source_models.dart';
import '../utils/external_ids.dart';

/// Strong cross-source IDs for server-backed movies, shows and exact episodes.
/// Title/year matches deliberately do not produce a canonical identity.
Set<String> canonicalVideoIdentitiesForMediaItem(MediaItem media) {
  final ids = _externalIdsForMediaItem(media);
  final String mediaType;
  String? episodeKey;
  switch (media.kind) {
    case MediaKind.movie:
      mediaType = 'movie';
      break;
    case MediaKind.show:
      mediaType = 'show';
      break;
    case MediaKind.episode:
      final season = media.parentIndex;
      final episode = media.index;
      if (season == null || episode == null || season < 0 || episode < 0) return const {};
      mediaType = 'episode';
      episodeKey = 's${season}e$episode';
      break;
    case MediaKind.clip ||
          MediaKind.artist ||
          MediaKind.album ||
          MediaKind.track ||
          MediaKind.season ||
          MediaKind.collection ||
          MediaKind.playlist ||
          MediaKind.photo ||
          MediaKind.folder ||
          MediaKind.unknown:
      return const {};
  }
  return _canonicalExternalIdKeys(ids, mediaType, episodeKey);
}

/// Strong cross-source IDs for indexed source videos. Episodes are comparable
/// only when both exact season and episode were recorded.
Set<String> canonicalVideoIdentitiesForSourceEntry(SourceEntry entry) {
  if (entry.kind != SourceItemKind.video) return const {};
  final ids = _externalIdsForSourceEntry(entry);
  final indexedType = entry.identifiers['plezyMediaType'];
  late final String mediaType;
  String? episodeKey;
  if (indexedType == 'movie') {
    mediaType = 'movie';
  } else if (indexedType == 'show' ||
      (entry.identifiers['plezySeason'] != null && entry.identifiers['plezyEpisode'] != null)) {
    final season = int.tryParse(entry.identifiers['plezySeason'] ?? '');
    final episode = int.tryParse(entry.identifiers['plezyEpisode'] ?? '');
    if (season != null && episode != null && season >= 0 && episode >= 0) {
      mediaType = 'episode';
      episodeKey = 's${season}e$episode';
    } else if (indexedType == 'show') {
      mediaType = 'show';
    } else {
      return const {};
    }
  } else {
    return const {};
  }
  return _canonicalExternalIdKeys(ids, mediaType, episodeKey);
}

/// Canonical identity keys for an external lookup. [mediaType] is `movie` or
/// `show`; a show lookup with both season and episode becomes an exact episode
/// identity. Supplying only one episode coordinate yields no identity.
Set<String> canonicalVideoIdentitiesForExternalIds({
  required Map<String, String> identifiers,
  required String mediaType,
  int? season,
  int? episode,
}) {
  final normalized = <String, String>{};
  for (final key in const ['imdb', 'tmdb', 'tvdb']) {
    final raw = identifiers[key]?.trim().toLowerCase();
    if (raw == null || raw.isEmpty || raw.length > 100) continue;
    final value = raw.startsWith('$key:') ? raw.substring(key.length + 1) : raw;
    if (value.isNotEmpty) normalized[key] = value;
  }
  final ids = ExternalIds(
    imdb: normalized['imdb'],
    tmdb: int.tryParse(normalized['tmdb'] ?? ''),
    tvdb: int.tryParse(normalized['tvdb'] ?? ''),
  );
  if (mediaType == 'movie') return _canonicalExternalIdKeys(ids, 'movie', null);
  if (mediaType != 'show') return const {};
  if ((season == null) != (episode == null)) return const {};
  if (season != null && episode != null) {
    if (season < 0 || episode < 0) return const {};
    return _canonicalExternalIdKeys(ids, 'episode', 's${season}e$episode');
  }
  return _canonicalExternalIdKeys(ids, 'show', null);
}

Set<String> _canonicalExternalIdKeys(ExternalIds ids, String mediaType, String? episodeKey) {
  final suffix = episodeKey == null ? '' : '/$episodeKey';
  return {
    if (ids.imdb case final value?) '$mediaType/imdb:$value$suffix',
    if (ids.tmdb case final value?) '$mediaType/tmdb:$value$suffix',
    if (ids.tvdb case final value?) '$mediaType/tvdb:$value$suffix',
  };
}

ExternalIds _externalIdsForMediaItem(MediaItem item) {
  final raw = item.raw;
  if (item is PlexMediaItem) {
    final guidList = raw?['Guid'];
    return ExternalIds.fromGuids(guidList is List ? guidList : const []).fillFrom(
      ExternalIds.fromLegacyPlexGuid(item.guid),
    );
  }
  final providerIds = _objectMap(raw?['ProviderIds']);
  return providerIds == null ? const ExternalIds() : ExternalIds.fromJellyfinProviderIds(providerIds);
}

ExternalIds _externalIdsForSourceEntry(SourceEntry entry) {
  String? value(String key) {
    final raw = entry.identifiers[key]?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    final unprefixed = raw.startsWith('$key:') ? raw.substring(key.length + 1) : raw;
    return unprefixed.isEmpty ? null : unprefixed;
  }

  return ExternalIds(
    imdb: value('imdb'),
    tmdb: int.tryParse(value('tmdb') ?? ''),
    tvdb: int.tryParse(value('tvdb') ?? ''),
  );
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is! Map) return null;
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}
