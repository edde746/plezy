// Pure JSON/DTO→neutral-type mappers for Plex. Mirrors [JellyfinMappers].
//
// The DTO layer ([PlexMetadataDto] etc.) is a typed shim over the raw
// `/library/metadata` JSON shape that exists so the Plex-specific quirks
// (heterogeneous tags, obfuscation, the OnDeck nesting) can be handled
// once. The [PlexMappers] class is a thin public wrapper that converts
// either parsed DTOs or raw JSON into the neutral
// [MediaItem] / [MediaLibrary] / [MediaHub] / [MediaPlaylist] types.
//
// Pure: no HTTP, no client state, no token-aware image-URL resolution.
// The client wraps the static methods with per-instance image-URL
// resolution and server-tagging.

import 'package:json_annotation/json_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_part.dart';
import '../media/media_playlist.dart';
import '../media/media_role.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import '../utils/json_utils.dart';
import '../utils/obfuscation_utils.dart';
import 'file_info_parser.dart';

part 'plex_mappers.g.dart';

/// Shared suffix of both unmatched-agent URL schemes: legacy
/// `com.plexapp.agents.none://` and new-style `tv.plex.agents.none://`.
const _unmatchedAgentMarker = 'agents.none://';

Map<String, dynamic> _obfuscatePlaylistJson(Map<String, dynamic> json) {
  final copy = Map<String, dynamic>.from(json);
  for (final key in const ['title', 'summary']) {
    if (copy[key] is String) copy[key] = obfuscateText(copy[key] as String);
  }
  return copy;
}

int _flexibleIntOrZero(Object? v) => flexibleInt(v) ?? 0;

Map? _firstPartMap(Object? raw) {
  final parts = flexibleList(raw);
  if (parts == null || parts.isEmpty) return null;
  final part = parts.first;
  return part is Map ? part : null;
}

String _partKeyFromJson(Object? raw) => _firstPartMap(raw)?['key']?.toString() ?? '';

bool? _partAccessibleFromJson(Object? raw) => flexibleBoolNullable(_firstPartMap(raw)?['accessible']);

bool? _partExistsFromJson(Object? raw) => flexibleBoolNullable(_firstPartMap(raw)?['exists']);

Object? _readPartKey(Map json, String _) => _partKeyFromJson(json['Part']);

Object? _readPartAccessible(Map json, String _) => _partAccessibleFromJson(json['Part']);

Object? _readPartExists(Map json, String _) => _partExistsFromJson(json['Part']);

String _hubTitleFromJson(Object? raw) {
  final title = raw as String? ?? 'Unknown';
  return kBlurArtwork ? obfuscateText(title) : title;
}

Object? _readHubItems(Map json, String _) {
  final entries = <Map<String, dynamic>>[];

  void append(Object? raw, {required bool isDirectory}) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      if (isDirectory && !entry.containsKey('type')) {
        entry['type'] = (entry.containsKey('leafCount') || entry.containsKey('childCount')) ? 'show' : 'folder';
      }
      entries.add(entry);
    }
  }

  append(json['Metadata'], isDirectory: false);
  append(json['Directory'], isDirectory: true);
  return entries;
}

List<PlexMetadataDto> _hubItemsFromJson(Object? raw) {
  final items = <PlexMetadataDto>[];
  if (raw is! List) return items;
  for (final item in raw) {
    try {
      items.add(PlexMetadataDto.fromJsonWithImages(item as Map<String, dynamic>));
    } catch (_) {
      // Skip hub entries that fail to parse; Plex hubs can mix item shapes.
    }
  }
  return items;
}

Object? _readMetadataRatingKey(Map json, String _) => (json['ratingKey'] ?? json['key'])?.toString() ?? '';

List<String>? _tagListFromJson(Object? raw) => stringListFromRaw(raw, mapKey: 'tag');

@JsonSerializable(createToJson: false)
class PlexRoleDto {
  @JsonKey(fromJson: flexibleInt)
  final int? id;
  final String? filter;
  final String tag;
  final String? tagKey;
  final String? role;
  final String? thumb;
  @JsonKey(fromJson: flexibleInt)
  final int? count;

  const PlexRoleDto({this.id, this.filter, required this.tag, this.tagKey, this.role, this.thumb, this.count});

  factory PlexRoleDto.fromJson(Map<String, dynamic> json) => _$PlexRoleDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class PlexMediaVersionDto {
  @JsonKey(fromJson: _flexibleIntOrZero)
  final int id;
  @JsonKey(readValue: readStringField)
  final String? videoResolution;
  @JsonKey(readValue: readStringField)
  final String? videoCodec;
  @JsonKey(fromJson: flexibleInt)
  final int? bitrate;
  @JsonKey(fromJson: flexibleInt)
  final int? width;
  @JsonKey(fromJson: flexibleInt)
  final int? height;
  @JsonKey(readValue: readStringField)
  final String? container;
  @JsonKey(readValue: _readPartKey)
  final String partKey;
  @JsonKey(readValue: _readPartAccessible)
  final bool? accessible;
  @JsonKey(readValue: _readPartExists)
  final bool? exists;

  const PlexMediaVersionDto({
    required this.id,
    this.videoResolution,
    this.videoCodec,
    this.bitrate,
    this.width,
    this.height,
    this.container,
    required this.partKey,
    this.accessible,
    this.exists,
  });

  factory PlexMediaVersionDto.fromJson(Map<String, dynamic> json) => _$PlexMediaVersionDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class PlexLibraryDto {
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String type;
  final String? agent;
  final String? scanner;
  final String? language;
  final String? uuid;
  @JsonKey(fromJson: flexibleInt)
  final int? updatedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? createdAt;
  @JsonKey(fromJson: flexibleInt)
  final int? hidden;
  @JsonKey(includeFromJson: false)
  final String? serverId;
  @JsonKey(includeFromJson: false)
  final String? serverName;
  @JsonKey(includeFromJson: false)
  final bool isShared;

  const PlexLibraryDto({
    required this.key,
    required this.title,
    required this.type,
    this.agent,
    this.scanner,
    this.language,
    this.uuid,
    this.updatedAt,
    this.createdAt,
    this.hidden,
    this.serverId,
    this.serverName,
    this.isShared = false,
  });

  factory PlexLibraryDto.fromJson(Map<String, dynamic> json) => _$PlexLibraryDtoFromJson(json);

  PlexLibraryDto copyWith({String? serverId, String? serverName, bool? isShared}) {
    return PlexLibraryDto(
      key: key,
      title: title,
      type: type,
      agent: agent,
      scanner: scanner,
      language: language,
      uuid: uuid,
      updatedAt: updatedAt,
      createdAt: createdAt,
      hidden: hidden,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      isShared: isShared ?? this.isShared,
    );
  }

  String get globalKey => serverId != null ? buildGlobalKey(serverId!, key) : key;
}

@JsonSerializable(createToJson: false)
class PlexPlaylistDto {
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String ratingKey;
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String type;
  @JsonKey(defaultValue: '')
  final String title;
  final String? summary;
  @JsonKey(defaultValue: false)
  final bool smart;
  @JsonKey(defaultValue: '')
  final String playlistType;
  @JsonKey(fromJson: flexibleInt)
  final int? duration;
  @JsonKey(fromJson: flexibleInt)
  final int? leafCount;
  final String? composite;
  @JsonKey(fromJson: flexibleInt)
  final int? addedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? updatedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? lastViewedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? viewCount;
  final String? content;
  final String? guid;
  final String? thumb;
  @JsonKey(includeFromJson: false)
  final String? serverId;
  @JsonKey(includeFromJson: false)
  final String? serverName;

  const PlexPlaylistDto({
    required this.ratingKey,
    required this.key,
    required this.type,
    required this.title,
    this.summary,
    required this.smart,
    required this.playlistType,
    this.duration,
    this.leafCount,
    this.composite,
    this.addedAt,
    this.updatedAt,
    this.lastViewedAt,
    this.viewCount,
    this.content,
    this.guid,
    this.thumb,
    this.serverId,
    this.serverName,
  });

  factory PlexPlaylistDto.fromJson(Map<String, dynamic> json) =>
      _$PlexPlaylistDtoFromJson(kBlurArtwork ? _obfuscatePlaylistJson(json) : json);

  PlexPlaylistDto copyWith({String? serverId, String? serverName}) {
    return PlexPlaylistDto(
      ratingKey: ratingKey,
      key: key,
      type: type,
      title: title,
      summary: summary,
      smart: smart,
      playlistType: playlistType,
      duration: duration,
      leafCount: leafCount,
      composite: composite,
      addedAt: addedAt,
      updatedAt: updatedAt,
      lastViewedAt: lastViewedAt,
      viewCount: viewCount,
      content: content,
      guid: guid,
      thumb: thumb,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}

@JsonSerializable(createToJson: false)
class PlexHubDto {
  @JsonKey(name: 'key', readValue: readStringField, defaultValue: '')
  final String hubKey;
  @JsonKey(fromJson: _hubTitleFromJson)
  final String title;
  @JsonKey(defaultValue: 'hub')
  final String type;
  final String? hubIdentifier;
  @JsonKey(fromJson: _flexibleIntOrZero)
  final int size;
  @JsonKey(fromJson: flexibleBool)
  final bool more;
  @JsonKey(readValue: _readHubItems, fromJson: _hubItemsFromJson)
  final List<PlexMetadataDto> items;
  @JsonKey(includeFromJson: false)
  final String? serverId;
  @JsonKey(includeFromJson: false)
  final String? serverName;

  const PlexHubDto({
    required this.hubKey,
    required this.title,
    required this.type,
    this.hubIdentifier,
    required this.size,
    required this.more,
    required this.items,
    this.serverId,
    this.serverName,
  });

  factory PlexHubDto.fromJson(Map<String, dynamic> json, {String? serverId, String? serverName}) {
    final parsed = _$PlexHubDtoFromJson(json);
    final items = serverId == null && serverName == null
        ? parsed.items
        : parsed.items.map((item) => item.copyWith(serverId: serverId, serverName: serverName)).toList();

    return PlexHubDto(
      hubKey: parsed.hubKey,
      title: parsed.title,
      type: parsed.type,
      hubIdentifier: parsed.hubIdentifier,
      size: flexibleInt(json['size']) ?? items.length,
      more: parsed.more,
      items: items,
      serverId: serverId,
      serverName: serverName,
    );
  }
}

@JsonSerializable(includeIfNull: false)
class PlexMetadataDto {
  @JsonKey(readValue: _readMetadataRatingKey, defaultValue: '')
  final String ratingKey;
  final String? key;
  final String? guid;
  final String? studio;
  final String? type;
  final String? title;
  final String? titleSort;
  final String? contentRating;
  final String? summary;
  final double? rating;
  final double? audienceRating;
  final double? userRating;
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? originallyAvailableAt;
  final String? thumb;
  final String? art;
  @JsonKey(fromJson: flexibleInt)
  final int? duration;
  @JsonKey(fromJson: flexibleInt)
  final int? addedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? updatedAt;
  @JsonKey(fromJson: flexibleInt)
  final int? lastViewedAt;
  final String? grandparentTitle;
  final String? grandparentThumb;
  final String? grandparentArt;
  @JsonKey(readValue: readStringField)
  final String? grandparentRatingKey;
  final String? parentTitle;
  final String? parentThumb;
  @JsonKey(readValue: readStringField)
  final String? parentRatingKey;
  @JsonKey(fromJson: flexibleInt)
  final int? parentIndex;
  @JsonKey(fromJson: flexibleInt)
  final int? index;
  final String? grandparentTheme;
  @JsonKey(fromJson: flexibleInt)
  final int? viewOffset;
  @JsonKey(fromJson: flexibleInt)
  final int? viewCount;
  @JsonKey(fromJson: flexibleInt)
  final int? leafCount;
  @JsonKey(fromJson: flexibleInt)
  final int? viewedLeafCount;
  @JsonKey(fromJson: flexibleInt)
  final int? childCount;
  @JsonKey(name: 'Role', includeToJson: false)
  final List<PlexRoleDto>? role;
  @JsonKey(name: 'Media', includeToJson: false)
  final List<PlexMediaVersionDto>? mediaVersions;
  @JsonKey(name: 'Genre', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? genre;
  @JsonKey(name: 'Director', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? director;
  @JsonKey(name: 'Writer', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? writer;
  @JsonKey(name: 'Producer', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? producer;
  @JsonKey(name: 'Country', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? country;
  @JsonKey(name: 'Collection', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? collection;
  @JsonKey(name: 'Label', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? label;
  @JsonKey(name: 'Style', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? style;
  @JsonKey(name: 'Mood', fromJson: _tagListFromJson, includeToJson: false)
  final List<String>? mood;
  final String? audioLanguage;
  final String? subtitleLanguage;
  @JsonKey(fromJson: flexibleInt)
  final int? subtitleMode;
  @JsonKey(fromJson: flexibleInt)
  final int? playlistItemID;
  @JsonKey(fromJson: flexibleInt)
  final int? playQueueItemID;
  @JsonKey(fromJson: flexibleInt)
  final int? librarySectionID;
  final String? librarySectionTitle;
  final String? ratingImage;
  final String? audienceRatingImage;
  final String? tagline;
  final String? originalTitle;
  final String? editionTitle;
  final String? subtype;
  @JsonKey(fromJson: flexibleInt)
  final int? extraType;
  final String? primaryExtraKey;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;
  final String? clearLogo;
  final String? backgroundSquare;

  const PlexMetadataDto({
    required this.ratingKey,
    this.key,
    this.guid,
    this.studio,
    this.type,
    this.title,
    this.titleSort,
    this.contentRating,
    this.summary,
    this.rating,
    this.audienceRating,
    this.userRating,
    this.year,
    this.originallyAvailableAt,
    this.thumb,
    this.art,
    this.duration,
    this.addedAt,
    this.updatedAt,
    this.lastViewedAt,
    this.grandparentTitle,
    this.grandparentThumb,
    this.grandparentArt,
    this.grandparentRatingKey,
    this.parentTitle,
    this.parentThumb,
    this.parentRatingKey,
    this.parentIndex,
    this.index,
    this.grandparentTheme,
    this.viewOffset,
    this.viewCount,
    this.leafCount,
    this.viewedLeafCount,
    this.childCount,
    this.role,
    this.mediaVersions,
    this.genre,
    this.director,
    this.writer,
    this.producer,
    this.country,
    this.collection,
    this.label,
    this.style,
    this.mood,
    this.audioLanguage,
    this.subtitleLanguage,
    this.subtitleMode,
    this.playlistItemID,
    this.playQueueItemID,
    this.librarySectionID,
    this.librarySectionTitle,
    this.ratingImage,
    this.audienceRatingImage,
    this.tagline,
    this.originalTitle,
    this.editionTitle,
    this.subtype,
    this.extraType,
    this.primaryExtraKey,
    this.serverId,
    this.serverName,
    this.clearLogo,
    this.backgroundSquare,
  });

  factory PlexMetadataDto.fromJson(Map<String, dynamic> rawJson) {
    final json = kBlurArtwork ? _obfuscateJson(rawJson) : rawJson;
    try {
      return _$PlexMetadataDtoFromJson(json);
    } on TypeError catch (e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) {
          scope.setContexts('json', json);
        },
      );
      rethrow;
    }
  }

  factory PlexMetadataDto.fromJsonWithImages(Map<String, dynamic> json) {
    String? clearLogoUrl;
    String? backgroundSquareUrl;
    final images = json['Image'] as List?;
    if (images != null) {
      for (final image in images) {
        if (image is Map) {
          final type = image['type'];
          final url = image['url'] as String?;
          if (url == null) continue;
          if (type == 'clearLogo') clearLogoUrl = url;
          if (type == 'backgroundSquare') backgroundSquareUrl = url;
        }
      }
    }
    if (clearLogoUrl == null && backgroundSquareUrl == null) {
      return PlexMetadataDto.fromJson(json);
    }
    final enriched = Map<String, dynamic>.from(json);
    if (clearLogoUrl != null) enriched['clearLogo'] = clearLogoUrl;
    if (backgroundSquareUrl != null) enriched['backgroundSquare'] = backgroundSquareUrl;
    return PlexMetadataDto.fromJson(enriched);
  }

  static Map<String, dynamic> _obfuscateJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    for (final key in const ['title', 'summary', 'tagline', 'grandparentTitle', 'parentTitle', 'studio']) {
      if (copy[key] is String) copy[key] = obfuscateText(copy[key] as String);
    }
    return copy;
  }

  String get globalKey => serverId != null ? buildGlobalKey(serverId!, ratingKey) : ratingKey;

  bool get isLibrarySection => key != null && key!.startsWith('/library/sections/');

  bool get isUnmatched => guid == null || guid!.isEmpty || guid!.contains(_unmatchedAgentMarker);

  /// Top-level scalar fields surface as a plain Plex JSON map. Used by the
  /// download-manager cache layer to overlay scalar updates on top of an
  /// existing Plex response without losing Chapter/Marker/Media arrays.
  Map<String, dynamic> toJson() => _$PlexMetadataDtoToJson(this);

  PlexMetadataDto copyWith({
    String? ratingKey,
    String? key,
    String? guid,
    String? studio,
    String? type,
    String? title,
    String? titleSort,
    String? contentRating,
    String? summary,
    double? rating,
    double? audienceRating,
    double? userRating,
    int? year,
    String? originallyAvailableAt,
    String? thumb,
    String? art,
    int? duration,
    int? addedAt,
    int? updatedAt,
    int? lastViewedAt,
    String? grandparentTitle,
    String? grandparentThumb,
    String? grandparentArt,
    String? grandparentRatingKey,
    String? parentTitle,
    String? parentThumb,
    String? parentRatingKey,
    int? parentIndex,
    int? index,
    String? grandparentTheme,
    int? viewOffset,
    int? viewCount,
    int? leafCount,
    int? viewedLeafCount,
    int? childCount,
    List<PlexRoleDto>? role,
    List<PlexMediaVersionDto>? mediaVersions,
    List<String>? genre,
    List<String>? director,
    List<String>? writer,
    List<String>? producer,
    List<String>? country,
    List<String>? collection,
    List<String>? label,
    List<String>? style,
    List<String>? mood,
    String? audioLanguage,
    String? subtitleLanguage,
    int? subtitleMode,
    int? playlistItemID,
    int? playQueueItemID,
    int? librarySectionID,
    String? librarySectionTitle,
    String? ratingImage,
    String? audienceRatingImage,
    String? tagline,
    String? originalTitle,
    String? editionTitle,
    String? subtype,
    int? extraType,
    String? primaryExtraKey,
    String? serverId,
    String? serverName,
    String? clearLogo,
    String? backgroundSquare,
  }) {
    return PlexMetadataDto(
      ratingKey: ratingKey ?? this.ratingKey,
      key: key ?? this.key,
      guid: guid ?? this.guid,
      studio: studio ?? this.studio,
      type: type ?? this.type,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      contentRating: contentRating ?? this.contentRating,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      audienceRating: audienceRating ?? this.audienceRating,
      userRating: userRating ?? this.userRating,
      year: year ?? this.year,
      originallyAvailableAt: originallyAvailableAt ?? this.originallyAvailableAt,
      thumb: thumb ?? this.thumb,
      art: art ?? this.art,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      grandparentTitle: grandparentTitle ?? this.grandparentTitle,
      grandparentThumb: grandparentThumb ?? this.grandparentThumb,
      grandparentArt: grandparentArt ?? this.grandparentArt,
      grandparentRatingKey: grandparentRatingKey ?? this.grandparentRatingKey,
      parentTitle: parentTitle ?? this.parentTitle,
      parentThumb: parentThumb ?? this.parentThumb,
      parentRatingKey: parentRatingKey ?? this.parentRatingKey,
      parentIndex: parentIndex ?? this.parentIndex,
      index: index ?? this.index,
      grandparentTheme: grandparentTheme ?? this.grandparentTheme,
      viewOffset: viewOffset ?? this.viewOffset,
      viewCount: viewCount ?? this.viewCount,
      leafCount: leafCount ?? this.leafCount,
      viewedLeafCount: viewedLeafCount ?? this.viewedLeafCount,
      childCount: childCount ?? this.childCount,
      role: role ?? this.role,
      mediaVersions: mediaVersions ?? this.mediaVersions,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      writer: writer ?? this.writer,
      producer: producer ?? this.producer,
      country: country ?? this.country,
      collection: collection ?? this.collection,
      label: label ?? this.label,
      style: style ?? this.style,
      mood: mood ?? this.mood,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      subtitleMode: subtitleMode ?? this.subtitleMode,
      playlistItemID: playlistItemID ?? this.playlistItemID,
      playQueueItemID: playQueueItemID ?? this.playQueueItemID,
      librarySectionID: librarySectionID ?? this.librarySectionID,
      librarySectionTitle: librarySectionTitle ?? this.librarySectionTitle,
      ratingImage: ratingImage ?? this.ratingImage,
      audienceRatingImage: audienceRatingImage ?? this.audienceRatingImage,
      tagline: tagline ?? this.tagline,
      originalTitle: originalTitle ?? this.originalTitle,
      editionTitle: editionTitle ?? this.editionTitle,
      subtype: subtype ?? this.subtype,
      extraType: extraType ?? this.extraType,
      primaryExtraKey: primaryExtraKey ?? this.primaryExtraKey,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      clearLogo: clearLogo ?? this.clearLogo,
      backgroundSquare: backgroundSquare ?? this.backgroundSquare,
    );
  }
}

/// Pure JSON/DTO→neutral-type mappers for Plex. Mirrors [JellyfinMappers].
///
/// Methods come in two flavours:
///   * `<type>FromJson` — accept raw Plex JSON and parse + map in one step.
///     Used by tests and by callers that haven't already parsed a DTO.
///   * `<type>` (DTO-typed) — accept an already-parsed DTO. Used by the
///     [PlexClient] which keeps a DTO step internally for caching, copying,
///     and OnDeck composition.
///
/// Pure: no HTTP, no client state, no token-aware image-URL resolution.
/// Token-aware image URLs are layered on at the [PlexClient] boundary via
/// `thumbnailUrl`/`externalImageUrl` — this layer leaves the relative
/// `thumb`/`art`/`clearLogo` paths intact so they can be resolved per
/// instance.
class PlexMappers {
  PlexMappers._();

  /// Map a Plex `Metadata` JSON entry directly into a [PlexMediaItem].
  static PlexMediaItem mediaItemFromJson(Map<String, dynamic> json, {String? serverId, String? serverName}) {
    final dto = PlexMetadataDto.fromJsonWithImages(json).copyWith(serverId: serverId, serverName: serverName);
    return mediaItem(dto);
  }

  /// Parse a Plex `/library/metadata/{id}` JSON object into a neutral
  /// [MediaItem]. Used by the offline cache layer to convert persisted Plex
  /// JSON back into MediaItem without depending on the Plex client surface.
  static MediaItem mediaItemFromCacheJson(Map<String, dynamic> json, {required String serverId}) {
    final dto = PlexMetadataDto.fromJsonWithImages(json).copyWith(serverId: serverId);
    return mediaItem(dto);
  }

  /// Map a parsed [PlexMetadataDto] into a [PlexMediaItem].
  static PlexMediaItem mediaItem(PlexMetadataDto dto) {
    return PlexMediaItem(
      id: dto.ratingKey,
      kind: MediaKind.fromString(dto.type),
      guid: dto.guid,
      title: dto.title,
      titleSort: dto.titleSort,
      summary: dto.summary,
      tagline: dto.tagline,
      originalTitle: dto.originalTitle,
      editionTitle: dto.editionTitle,
      studio: dto.studio,
      year: dto.year,
      originallyAvailableAt: dto.originallyAvailableAt,
      contentRating: dto.contentRating,
      parentId: dto.parentRatingKey,
      parentTitle: dto.parentTitle,
      parentThumbPath: dto.parentThumb,
      parentIndex: dto.parentIndex,
      index: dto.index,
      grandparentId: dto.grandparentRatingKey,
      grandparentTitle: dto.grandparentTitle,
      grandparentThumbPath: dto.grandparentThumb,
      grandparentArtPath: dto.grandparentArt,
      thumbPath: dto.thumb,
      artPath: dto.art,
      clearLogoPath: dto.clearLogo,
      backgroundSquarePath: dto.backgroundSquare,
      durationMs: dto.duration,
      viewOffsetMs: dto.viewOffset,
      viewCount: dto.viewCount,
      lastViewedAt: dto.lastViewedAt,
      leafCount: dto.leafCount,
      viewedLeafCount: dto.viewedLeafCount,
      childCount: dto.childCount,
      addedAt: dto.addedAt,
      updatedAt: dto.updatedAt,
      rating: dto.rating,
      audienceRating: dto.audienceRating,
      userRating: dto.userRating,
      ratingImage: dto.ratingImage,
      audienceRatingImage: dto.audienceRatingImage,
      genres: dto.genre,
      directors: dto.director,
      writers: dto.writer,
      producers: dto.producer,
      countries: dto.country,
      collections: dto.collection,
      labels: dto.label,
      styles: dto.style,
      moods: dto.mood,
      roles: dto.role?.map(role).toList(),
      mediaVersions: dto.mediaVersions?.map(mediaVersion).toList(),
      libraryId: dto.librarySectionID?.toString(),
      libraryTitle: dto.librarySectionTitle,
      audioLanguage: dto.audioLanguage,
      subtitleLanguage: dto.subtitleLanguage,
      subtitleMode: dto.subtitleMode,
      trailerKey: dto.primaryExtraKey,
      playlistItemId: dto.playlistItemID,
      playQueueItemId: dto.playQueueItemID,
      subtype: dto.subtype,
      extraType: dto.extraType,
      serverId: dto.serverId,
      serverName: dto.serverName,
      raw: dto.key != null ? {'key': dto.key} : null,
    );
  }

  /// Map a parsed [PlexRoleDto] into a [MediaRole].
  static MediaRole role(PlexRoleDto dto) {
    return MediaRole(id: dto.id?.toString(), tag: dto.tag, role: dto.role, thumbPath: dto.thumb);
  }

  /// Map a parsed [PlexMediaVersionDto] into a [MediaVersion].
  static MediaVersion mediaVersion(PlexMediaVersionDto dto) {
    final part = MediaPart(
      id: dto.id.toString(),
      streamPath: dto.partKey,
      container: dto.container,
      accessible: dto.accessible,
      exists: dto.exists,
    );
    return MediaVersion(
      id: dto.id.toString(),
      width: dto.width,
      height: dto.height,
      videoResolution: dto.videoResolution,
      videoCodec: dto.videoCodec,
      bitrate: dto.bitrate,
      container: dto.container,
      parts: [part],
    );
  }

  /// Map a Plex Media JSON entry directly into a [MediaVersion].
  static MediaVersion mediaVersionFromJson(Map<String, dynamic> json) {
    return mediaVersion(PlexMediaVersionDto.fromJson(json));
  }

  /// Map a parsed [PlexLibraryDto] into a [MediaLibrary].
  static MediaLibrary mediaLibrary(PlexLibraryDto dto) {
    return MediaLibrary(
      id: dto.key,
      backend: MediaBackend.plex,
      title: dto.title,
      kind: MediaKind.fromString(dto.type),
      language: dto.language,
      updatedAt: dto.updatedAt,
      createdAt: dto.createdAt,
      hidden: dto.hidden == 1,
      isShared: dto.isShared,
      serverId: dto.serverId,
      serverName: dto.serverName,
    );
  }

  /// Map a Plex `/library/sections` Directory entry into a [MediaLibrary].
  static MediaLibrary mediaLibraryFromJson(
    Map<String, dynamic> json, {
    String? serverId,
    String? serverName,
    bool isShared = false,
  }) {
    final dto = PlexLibraryDto.fromJson(json).copyWith(serverId: serverId, serverName: serverName, isShared: isShared);
    return mediaLibrary(dto);
  }

  /// Map a parsed [PlexHubDto] into a [MediaHub].
  static MediaHub mediaHub(PlexHubDto dto) {
    return MediaHub(
      id: dto.hubKey,
      identifier: dto.hubIdentifier,
      title: dto.title,
      type: dto.type,
      items: dto.items.map(mediaItem).toList(),
      size: dto.size,
      more: dto.more,
      serverId: dto.serverId,
      serverName: dto.serverName,
    );
  }

  /// Map a Plex `/hubs` Hub JSON entry directly into a [MediaHub].
  static MediaHub mediaHubFromJson(Map<String, dynamic> json, {String? serverId, String? serverName}) {
    return mediaHub(PlexHubDto.fromJson(json, serverId: serverId, serverName: serverName));
  }

  /// Map a parsed [PlexPlaylistDto] into a [MediaPlaylist].
  static MediaPlaylist mediaPlaylist(PlexPlaylistDto dto) {
    return MediaPlaylist(
      id: dto.ratingKey,
      backend: MediaBackend.plex,
      title: dto.title,
      summary: dto.summary,
      guid: dto.guid,
      smart: dto.smart,
      playlistType: dto.playlistType,
      durationMs: dto.duration,
      leafCount: dto.leafCount,
      viewCount: dto.viewCount,
      addedAt: dto.addedAt,
      updatedAt: dto.updatedAt,
      lastViewedAt: dto.lastViewedAt,
      compositeImagePath: dto.composite,
      thumbPath: dto.thumb,
      serverId: dto.serverId,
      serverName: dto.serverName,
    );
  }

  /// Map a Plex `/playlists` Metadata entry directly into a [MediaPlaylist].
  static MediaPlaylist mediaPlaylistFromJson(Map<String, dynamic> json, {String? serverId, String? serverName}) {
    final dto = PlexPlaylistDto.fromJson(json).copyWith(serverId: serverId, serverName: serverName);
    return mediaPlaylist(dto);
  }
}

/// Build a [MediaSourceInfo] from a Plex `/library/metadata/{id}` JSON
/// envelope as stored by [PlexApiCache]. Parses audio/subtitle tracks from
/// `Media[0].Part[0].Stream[]` so that offline playback can still apply
/// language-based track selection.
///
/// Returns `null` when the JSON shape is missing the `Media`/`Part` arrays.
/// Plex-only — the on-disk format mirrors what the Plex API returns and
/// uses Plex `streamType` int codes (1=video, 2=audio, 3=subtitle).
MediaSourceInfo? plexMediaSourceInfoFromCacheJson(Map<String, dynamic> metadata, {int mediaIndex = 0}) {
  final media = flexibleList(metadata['Media']);
  if (media == null || media.isEmpty) return null;
  final selectedMedia = mediaIndex >= 0 && mediaIndex < media.length ? media[mediaIndex] : media.first;
  final parts = flexibleList(selectedMedia['Part']);
  if (parts == null || parts.isEmpty) return null;
  final streams = walkStreams(
    flexibleList(parts.first['Stream']),
    const PlexFileInfoStreamReader(),
    onMalformed: (error, _, _) => appLogger.d('Skipping malformed stream in cached metadata', error: error),
  );

  return MediaSourceInfo(
    videoUrl: '',
    audioTracks: streams.audioTracks,
    subtitleTracks: streams.subtitleTracks,
    chapters: const [],
    frameRate: streams.frameRate,
  );
}

PlaybackExtras plexPlaybackExtrasFromCacheJson(
  Map<String, dynamic>? metadataJson, {
  String? introPattern,
  String? creditsPattern,
  bool forceChapterFallback = false,
}) {
  return PlaybackExtras.withChapterFallback(
    chapters: plexChaptersFromCacheJson(metadataJson),
    markers: plexMarkersFromCacheJson(metadataJson),
    introPatternStr: introPattern,
    creditsPatternStr: creditsPattern,
    forceChapterFallback: forceChapterFallback,
  );
}

List<MediaChapter> plexChaptersFromCacheJson(Map<String, dynamic>? metadataJson) {
  final chapterList = metadataJson?['Chapter'];
  if (chapterList is! List) return const [];

  final out = <MediaChapter>[];
  for (final chapter in chapterList.whereType<Map<String, dynamic>>()) {
    final id = flexibleInt(chapter['id']);
    if (id == null) continue;
    out.add(
      MediaChapter(
        id: id,
        index: flexibleInt(chapter['index']),
        startTimeOffset: flexibleInt(chapter['startTimeOffset']),
        endTimeOffset: flexibleInt(chapter['endTimeOffset']),
        title: chapter['tag']?.toString() ?? chapter['title']?.toString(),
        thumb: chapter['thumb'] as String?,
      ),
    );
  }
  return out;
}

List<MediaMarker> plexMarkersFromCacheJson(Map<String, dynamic>? metadataJson) {
  final markerList = metadataJson?['Marker'];
  if (markerList is! List) return const [];

  final out = <MediaMarker>[];
  for (final marker in markerList.whereType<Map<String, dynamic>>()) {
    final id = flexibleInt(marker['id']);
    final type = marker['type']?.toString();
    final start = flexibleInt(marker['startTimeOffset']);
    final end = flexibleInt(marker['endTimeOffset']);
    if (id == null || type == null || start == null || end == null) continue;
    out.add(MediaMarker(id: id, type: type, startTimeOffset: start, endTimeOffset: end));
  }
  return out;
}
