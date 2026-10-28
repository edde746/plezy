import 'dart:convert';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/catalog/catalog_item.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../sources/source_models.dart';
import '../utils/external_ids.dart';

enum DiscoveryChoiceType { video, music, ebook, audiobook, comic, sourceVideo, liveProgram }

/// An ephemeral, profile-authorized choice. Its persisted representation is a
/// deliberately small snapshot: it never contains a media payload, signed
/// URL, credential, artwork URL, or playback cursor.
class DiscoveryChoice {
  const DiscoveryChoice({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.summary,
    required this.durationMs,
    required this.totalDurationMs,
    required this.isEstimate,
    this.unitLabel = '',
    required this.serverId,
    required this.mediaId,
    required this.mediaKind,
    required this.sourceId,
    required this.entryId,
    this.libraryId,
    this.catalogSourceId,
    this.catalogEntryKey,
    required this.year,
    this.liveProgramId,
    this.channelId,
    this.dvrKey,
    this.liveBeginsAtSeconds,
    this.liveEndsAtSeconds,
    this.offlineReady = false,
    this.mediaItem,
    this.sourceEntry,
    this.liveProgram,
    this.liveChannel,
    this.catalogItem,
    this.artworkPath,
  });

  final String id;
  final DiscoveryChoiceType type;
  final String title;
  final String subtitle;
  final String reason;
  final String summary;

  /// Duration of the next useful unit where available (e.g. a chapter), else
  /// the whole work. Unknown is null, never zero.
  final int? durationMs;
  final int? totalDurationMs;
  final bool isEstimate;
  final String unitLabel;

  final String? serverId;
  final String? mediaId;
  final MediaKind? mediaKind;
  final String? sourceId;
  final String? entryId;
  final String? libraryId;

  /// Stable, non-secret catalog identity. The current provider resolves it
  /// again before opening a saved pick.
  final String? catalogSourceId;
  final String? catalogEntryKey;
  final int? year;
  final String? liveProgramId;
  final String? channelId;
  final String? dvrKey;
  final int? liveBeginsAtSeconds;
  final int? liveEndsAtSeconds;
  final bool offlineReady;

  /// Runtime-only authorized objects. These are intentionally omitted from
  /// [toSnapshot]. A saved pick must be resolved against the current profile
  /// and source before it can launch.
  final MediaItem? mediaItem;
  final SourceEntry? sourceEntry;
  final LiveTvProgram? liveProgram;
  final LiveTvChannel? liveChannel;
  final CatalogItem? catalogItem;
  final String? artworkPath;

  String get typeLabel => switch (type) {
    DiscoveryChoiceType.video => 'Video',
    DiscoveryChoiceType.music => 'Music',
    DiscoveryChoiceType.ebook => 'Book',
    DiscoveryChoiceType.audiobook => 'Audiobook',
    DiscoveryChoiceType.comic => 'Comic',
    DiscoveryChoiceType.sourceVideo => 'Video',
    DiscoveryChoiceType.liveProgram => 'Live TV',
  };

  String get stableReference => jsonEncode([
    'discovery',
    type.name,
    serverId,
    mediaKind?.id,
    mediaId,
    sourceId,
    entryId,
    liveProgramId,
    channelId,
    liveBeginsAtSeconds,
  ]);

  DiscoveryChoice withRuntime({MediaItem? media, SourceEntry? entry, String? art}) => DiscoveryChoice(
    id: id,
    type: type,
    title: title,
    subtitle: subtitle,
    reason: reason,
    summary: summary,
    durationMs: durationMs,
    totalDurationMs: totalDurationMs,
    isEstimate: isEstimate,
    unitLabel: unitLabel,
    serverId: serverId,
    mediaId: mediaId,
    mediaKind: mediaKind,
    sourceId: sourceId,
    entryId: entryId,
    libraryId: libraryId,
    catalogSourceId: catalogSourceId,
    catalogEntryKey: catalogEntryKey,
    year: year,
    liveProgramId: liveProgramId,
    channelId: channelId,
    dvrKey: dvrKey,
    liveBeginsAtSeconds: liveBeginsAtSeconds,
    liveEndsAtSeconds: liveEndsAtSeconds,
    offlineReady: offlineReady,
    mediaItem: media ?? mediaItem,
    sourceEntry: entry ?? sourceEntry,
    liveProgram: liveProgram,
    liveChannel: liveChannel,
    catalogItem: catalogItem,
    artworkPath: art ?? artworkPath,
  );

  Map<String, dynamic> toSnapshot() => {
    'id': id,
    'type': type.name,
    'title': _bounded(title, 160),
    'subtitle': _bounded(subtitle, 180),
    'reason': _bounded(reason, 160),
    'summary': _bounded(summary, 480),
    'durationMs': _validDuration(durationMs),
    'totalDurationMs': _validDuration(totalDurationMs),
    'isEstimate': isEstimate,
    'unitLabel': _bounded(unitLabel, 120),
    'serverId': serverId,
    'mediaId': mediaId,
    'mediaKind': mediaKind?.id,
    'sourceId': sourceId,
    'entryId': entryId,
    'libraryId': libraryId,
    'catalogSourceId': catalogSourceId,
    'catalogEntryKey': catalogEntryKey,
    'year': year,
    'liveProgramId': liveProgramId,
    'channelId': channelId,
    'dvrKey': dvrKey,
    'liveBeginsAtSeconds': liveBeginsAtSeconds,
    'liveEndsAtSeconds': liveEndsAtSeconds,
    'offlineReady': offlineReady,
  };

  factory DiscoveryChoice.fromSnapshot(Map<String, dynamic> json) {
    final type = DiscoveryChoiceType.values.where((value) => value.name == json['type']).firstOrNull;
    if (type == null) throw const FormatException('Unknown discovery choice type');
    final kind = MediaKind.values.where((value) => value.id == json['mediaKind']).firstOrNull;
    final choice = DiscoveryChoice(
      id: _bounded(json['id'] is String ? json['id'] as String : '', 512),
      type: type,
      title: _bounded('${json['title'] ?? ''}', 160),
      subtitle: _bounded('${json['subtitle'] ?? ''}', 180),
      reason: _bounded('${json['reason'] ?? ''}', 160),
      summary: _bounded('${json['summary'] ?? ''}', 480),
      durationMs: _validDuration(json['durationMs'] is num ? (json['durationMs'] as num).toInt() : null),
      totalDurationMs: _validDuration(json['totalDurationMs'] is num ? (json['totalDurationMs'] as num).toInt() : null),
      isEstimate: json['isEstimate'] == true,
      unitLabel: _bounded(json['unitLabel'] is String ? json['unitLabel'] as String : '', 120),
      serverId: _nonEmpty(json['serverId']),
      mediaId: _nonEmpty(json['mediaId']),
      mediaKind: kind,
      sourceId: _nonEmpty(json['sourceId']),
      entryId: _nonEmpty(json['entryId']),
      libraryId: _nonEmpty(json['libraryId']),
      catalogSourceId: _nonEmpty(json['catalogSourceId']),
      catalogEntryKey: _nonEmpty(json['catalogEntryKey']),
      year: json['year'] is num ? (json['year'] as num).toInt() : null,
      liveProgramId: _nonEmpty(json['liveProgramId']),
      channelId: _nonEmpty(json['channelId']),
      dvrKey: _nonEmpty(json['dvrKey']),
      liveBeginsAtSeconds: json['liveBeginsAtSeconds'] is num ? (json['liveBeginsAtSeconds'] as num).toInt() : null,
      liveEndsAtSeconds: json['liveEndsAtSeconds'] is num ? (json['liveEndsAtSeconds'] as num).toInt() : null,
      offlineReady: json['offlineReady'] == true,
    );
    if (choice.id.isEmpty || choice.title.isEmpty) throw const FormatException('Invalid discovery choice snapshot');
    return choice;
  }

  static String _bounded(String value, int limit) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.substring(0, normalized.length > limit ? limit : normalized.length);
  }

  static int? _validDuration(int? value) =>
      value != null && value > 0 && value < const Duration(days: 60).inMilliseconds ? value : null;

  static String? _nonEmpty(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}

String discoveryMediaIdentity(MediaItem item) {
  final serverId = item.serverId;
  if (serverId == null || serverId.trim().isEmpty || item.id.trim().isEmpty) return '';
  return jsonEncode(['media-server-item', item.backend.id, serverId, item.kind.id, item.id]);
}

String discoverySourceIdentity(SourceEntry entry) {
  if (entry.sourceId.trim().isEmpty || entry.id.trim().isEmpty) return '';
  return jsonEncode(['publication-edition', entry.sourceId, entry.id, entry.kind.name]);
}

/// Strong, cross-source identities for video choices. These keys are used to
/// collapse a source copy into the server/catalog card that already represents
/// the same movie or exact episode. Source-local IDs remain the playback and
/// progress identity; these keys only coordinate browse projections.
Set<String> discoveryCanonicalVideoIdentities(DiscoveryChoice choice) {
  if (choice.type != DiscoveryChoiceType.video && choice.type != DiscoveryChoiceType.sourceVideo) {
    return const {};
  }

  late final ExternalIds ids;
  late final String mediaType;
  String? episodeKey;

  final media = choice.mediaItem;
  if (media != null) {
    ids = _externalIdsForMediaItem(media);
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
        if (season == null || episode == null) return const {};
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
  } else {
    final entry = choice.sourceEntry;
    if (entry == null || entry.kind != SourceItemKind.video) return const {};
    ids = _externalIdsForSourceEntry(entry);
    final indexedType = entry.identifiers['plezyMediaType'];
    if (indexedType == 'movie') {
      mediaType = 'movie';
    } else if (indexedType == 'show') {
      final season = int.tryParse(entry.identifiers['plezySeason'] ?? '');
      final episode = int.tryParse(entry.identifiers['plezyEpisode'] ?? '');
      if (season != null && episode != null) {
        mediaType = 'episode';
        episodeKey = 's${season}e$episode';
      } else {
        mediaType = 'show';
      }
    } else {
      return const {};
    }
  }

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

DiscoveryChoiceType? discoveryTypeForMediaKind(MediaKind kind) => switch (kind) {
  MediaKind.movie ||
  MediaKind.show ||
  MediaKind.season ||
  MediaKind.episode ||
  MediaKind.clip => DiscoveryChoiceType.video,
  MediaKind.artist || MediaKind.album || MediaKind.track => DiscoveryChoiceType.music,
  // These are navigation containers rather than individual playable works,
  // but Plezy has real detail routes for them.
  MediaKind.collection || MediaKind.playlist => DiscoveryChoiceType.video,
  MediaKind.photo || MediaKind.folder || MediaKind.unknown => null,
};

DiscoveryChoiceType? discoveryTypeForSourceKind(SourceItemKind kind) => switch (kind) {
  SourceItemKind.ebook => DiscoveryChoiceType.ebook,
  SourceItemKind.audiobook => DiscoveryChoiceType.audiobook,
  SourceItemKind.comic => DiscoveryChoiceType.comic,
  SourceItemKind.music => DiscoveryChoiceType.music,
  SourceItemKind.video => DiscoveryChoiceType.sourceVideo,
  SourceItemKind.folder || SourceItemKind.unknown => null,
};
