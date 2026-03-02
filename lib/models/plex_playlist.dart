import 'package:json_annotation/json_annotation.dart';

import '../widgets/plex_optimized_image.dart' show kBlurArtwork, obfuscateText;
import 'mixins/multi_server_fields.dart';
import '../utils/global_key_utils.dart';

part 'plex_playlist.g.dart';

@JsonSerializable()
class PlexPlaylist with MultiServerFields {
  final String ratingKey;
  final String key;
  final String type; // "playlist"
  final String title;
  final String? summary;
  final bool smart;
  final String playlistType; // video, audio, photo
  final int? duration;
  final int? leafCount; // Number of items in playlist
  final String? composite; // Composite thumbnail image
  final int? addedAt;
  final int? updatedAt;
  final int? lastViewedAt;
  final int? viewCount;
  final String? content; // For smart playlists - generator URI
  final String? guid;
  final String? thumb;

  // Multi-server support fields (from MultiServerFields mixin)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;

  PlexPlaylist({
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

  /// Helper to get display image (composite or thumb)
  String? get displayImage => composite ?? thumb;

  /// Helper to get display title (consistent with PlexMetadata)
  String get displayTitle => title;

  /// Helper to determine if playlist is editable
  bool get isEditable => !smart;

  /// Get globally unique key across all servers
  String get globalKey => serverId != null ? buildGlobalKey(serverId!, ratingKey) : ratingKey;

  // Properties for MediaCard compatibility with PlexMetadata interface

  /// Playlists are not "watched" in the traditional sense
  bool get isWatched => false;

  /// Playlists don't have resume positions
  int? get viewOffset => null;

  /// Playlists don't have parent/episode indices
  int? get parentIndex => null;
  int? get index => null;

  /// Playlists don't have parent titles or subtitles
  String? get parentTitle => null;
  String? get displaySubtitle => null;

  /// Playlists don't have year, rating, or content metadata
  int? get year => null;
  String? get contentRating => null;
  double? get rating => null;
  String? get studio => null;

  /// Use leafCount as the equivalent of childCount
  int? get childCount => leafCount;

  /// Playlists don't track viewed leaf count
  int? get viewedLeafCount => null;

  factory PlexPlaylist.fromJson(Map<String, dynamic> json) {
    if (kBlurArtwork) {
      final copy = Map<String, dynamic>.from(json);
      for (final key in const ['title', 'summary']) {
        if (copy[key] is String) copy[key] = obfuscateText(copy[key] as String);
      }
      return _$PlexPlaylistFromJson(copy);
    }
    return _$PlexPlaylistFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PlexPlaylistToJson(this);

  /// Create a copy with optional field updates
  PlexPlaylist copyWith({
    String? ratingKey,
    String? key,
    String? type,
    String? title,
    String? summary,
    bool? smart,
    String? playlistType,
    int? duration,
    int? leafCount,
    String? composite,
    int? addedAt,
    int? updatedAt,
    int? lastViewedAt,
    int? viewCount,
    String? content,
    String? guid,
    String? thumb,
    String? serverId,
    String? serverName,
  }) {
    return PlexPlaylist(
      ratingKey: ratingKey ?? this.ratingKey,
      key: key ?? this.key,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      smart: smart ?? this.smart,
      playlistType: playlistType ?? this.playlistType,
      duration: duration ?? this.duration,
      leafCount: leafCount ?? this.leafCount,
      composite: composite ?? this.composite,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      viewCount: viewCount ?? this.viewCount,
      content: content ?? this.content,
      guid: guid ?? this.guid,
      thumb: thumb ?? this.thumb,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}
