import 'dart:convert';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/catalog/catalog_item.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../sources/source_models.dart';

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
    this.publicCatalogWorkId,
    this.publicCatalogAuthor = '',
    this.lendingLibraryId,
    this.lendingBookId,
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
    this.portableIds = const {},
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
  /// Open Library work identity. Presence always means catalog-only: it is
  /// never an owned item or a verified local-library offer.
  final String? publicCatalogWorkId;
  final String publicCatalogAuthor;
  /// Local-only lender identity. It is never a portable/public catalog ID.
  final String? lendingLibraryId;
  final String? lendingBookId;
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

  /// Whitelisted public identifiers used only for optional cross-device
  /// Saved picks. Server, source, library, and account identifiers never
  /// belong in this map.
  final Map<String, String> portableIds;

  String? get portableReference {
    if (publicCatalogWorkId != null || lendingLibraryId != null || lendingBookId != null) return null;
    final resolvable = switch (type) {
      DiscoveryChoiceType.video => mediaKind == MediaKind.movie || mediaKind == MediaKind.show,
      DiscoveryChoiceType.music =>
        mediaKind == null ||
            mediaKind == MediaKind.artist ||
            mediaKind == MediaKind.album ||
            mediaKind == MediaKind.track,
      DiscoveryChoiceType.ebook ||
      DiscoveryChoiceType.audiobook ||
      DiscoveryChoiceType.comic ||
      DiscoveryChoiceType.sourceVideo => mediaKind == null,
      DiscoveryChoiceType.liveProgram => false,
    };
    if (!resolvable) return null;
    final id = _canonicalPortableId(portableIds);
    if (id == null) return null;
    return jsonEncode(['discovery-pick-v1', type.name, mediaKind?.id, id.$1, id.$2]);
  }

  String? get portableKey {
    final reference = portableReference;
    return reference == null ? null : sourceDigest(reference);
  }

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
    publicCatalogWorkId,
    lendingLibraryId,
    lendingBookId,
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
    publicCatalogWorkId: publicCatalogWorkId,
    publicCatalogAuthor: publicCatalogAuthor,
    lendingLibraryId: lendingLibraryId,
    lendingBookId: lendingBookId,
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
    portableIds: portableIds,
  );

  DiscoveryChoice withPortableIds(Map<String, String> value) => DiscoveryChoice(
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
    publicCatalogWorkId: publicCatalogWorkId,
    publicCatalogAuthor: publicCatalogAuthor,
    lendingLibraryId: lendingLibraryId,
    lendingBookId: lendingBookId,
    year: year,
    liveProgramId: liveProgramId,
    channelId: channelId,
    dvrKey: dvrKey,
    liveBeginsAtSeconds: liveBeginsAtSeconds,
    liveEndsAtSeconds: liveEndsAtSeconds,
    offlineReady: offlineReady,
    mediaItem: mediaItem,
    sourceEntry: sourceEntry,
    liveProgram: liveProgram,
    liveChannel: liveChannel,
    catalogItem: catalogItem,
    artworkPath: artworkPath,
    portableIds: sanitizeDiscoveryPortableIds(value),
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
    'publicCatalogWorkId': publicCatalogWorkId,
    'publicCatalogAuthor': _bounded(publicCatalogAuthor, 160),
    'lendingLibraryId': lendingLibraryId,
    'lendingBookId': lendingBookId,
    'year': year,
    'liveProgramId': liveProgramId,
    'channelId': channelId,
    'dvrKey': dvrKey,
    'liveBeginsAtSeconds': liveBeginsAtSeconds,
    'liveEndsAtSeconds': liveEndsAtSeconds,
    'offlineReady': offlineReady,
    if (portableIds.isNotEmpty) 'portableIds': portableIds,
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
      publicCatalogWorkId: _validPublicWorkId(json['publicCatalogWorkId']),
      publicCatalogAuthor: _bounded(json['publicCatalogAuthor'] is String ? json['publicCatalogAuthor'] as String : '', 160),
      lendingLibraryId: _validLocalLendingId(json['lendingLibraryId'], 128),
      lendingBookId: _validLocalLendingId(json['lendingBookId'], 256),
      year: json['year'] is num ? (json['year'] as num).toInt() : null,
      liveProgramId: _nonEmpty(json['liveProgramId']),
      channelId: _nonEmpty(json['channelId']),
      dvrKey: _nonEmpty(json['dvrKey']),
      liveBeginsAtSeconds: json['liveBeginsAtSeconds'] is num ? (json['liveBeginsAtSeconds'] as num).toInt() : null,
      liveEndsAtSeconds: json['liveEndsAtSeconds'] is num ? (json['liveEndsAtSeconds'] as num).toInt() : null,
      offlineReady: json['offlineReady'] == true,
      portableIds: sanitizeDiscoveryPortableIds(
        sourceMap(json['portableIds']).map((key, value) => MapEntry(key, '$value')),
      ),
    );
    if (choice.id.isEmpty ||
        choice.title.isEmpty ||
        (json['publicCatalogWorkId'] != null && choice.publicCatalogWorkId == null) ||
        ((json['lendingLibraryId'] != null || json['lendingBookId'] != null) &&
            (choice.lendingLibraryId == null || choice.lendingBookId == null))) {
      throw const FormatException('Invalid discovery choice snapshot');
    }
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

  static String? _validPublicWorkId(Object? value) {
    if (value is! String || !RegExp(r'^OL[0-9]{1,14}W$').hasMatch(value)) return null;
    return value;
  }

  static String? _validLocalLendingId(Object? value, int maxLength) {
    if (value is! String || value.trim().isEmpty || value.length > maxLength || value.contains(RegExp(r'[\r\n\u0000]'))) {
      return null;
    }
    return value;
  }
}

/// Identifiers eligible for replication. These are public title identities;
/// provider URLs and PlezyNG's local ids are intentionally excluded.
Map<String, String> sanitizeDiscoveryPortableIds(Map<String, String> raw) {
  final result = <String, String>{};
  for (final entry in raw.entries.take(16)) {
    final key = entry.key.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    var value = entry.value.trim();
    if (value.length > 128) continue;
    switch (key) {
      case 'imdb':
      case 'imdbid':
        final normalized = value.toLowerCase();
        if (RegExp(r'^tt[0-9]{6,12}$').hasMatch(normalized)) result.putIfAbsent('imdb', () => normalized);
      case 'tmdb':
      case 'tmdbid':
      case 'themoviedb':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('tmdb', () => value);
      case 'tvdb':
      case 'tvdbid':
      case 'thetvdb':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('tvdb', () => value);
      case 'mal':
      case 'malid':
      case 'myanimelist':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('mal', () => value);
      case 'anilist':
      case 'anilistid':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('anilist', () => value);
      case 'simkl':
      case 'simklid':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('simkl', () => value);
      case 'trakt':
      case 'traktid':
        if (RegExp(r'^[0-9]{1,12}$').hasMatch(value)) result.putIfAbsent('trakt', () => value);
      case 'isbn':
      case 'isbn10':
      case 'isbn13':
      case 'isbn10id':
      case 'isbn13id':
        value = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
        if (RegExp(r'^[0-9]{13}$').hasMatch(value)) {
          result.putIfAbsent('isbn13', () => value);
        } else if (RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(value)) {
          result.putIfAbsent('isbn10', () => value);
        }
      case 'asin':
      case 'asinid':
        final normalized = value.toUpperCase();
        if (RegExp(r'^[A-Z0-9]{10}$').hasMatch(normalized)) result.putIfAbsent('asin', () => normalized);
      case 'doi':
      case 'doiid':
        value = value.replaceFirst(RegExp(r'^https?://(?:dx\.)?doi\.org/', caseSensitive: false), '');
        if (RegExp(r'^10\.[0-9]{4,9}/[^\s]{1,100}$', caseSensitive: false).hasMatch(value)) {
          result.putIfAbsent('doi', () => value.toLowerCase());
        }
    }
  }
  return Map.unmodifiable(result);
}

(String, String)? _canonicalPortableId(Map<String, String> ids) {
  for (final key in const [
    'imdb',
    'isbn13',
    'isbn10',
    'tmdb',
    'tvdb',
    'asin',
    'mal',
    'anilist',
    'simkl',
    'trakt',
    'doi',
  ]) {
    final value = ids[key];
    if (value != null && value.isNotEmpty) return (key, value);
  }
  return null;
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
