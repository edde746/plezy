import 'package:json_annotation/json_annotation.dart';

part 'plex_playlist.g.dart';

@JsonSerializable()
class PlexPlaylist {
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
  });

  /// Helper to get display image (composite or thumb)
  String? get displayImage => composite ?? thumb;

  /// Helper to get display title (consistent with PlexMetadata)
  String get displayTitle => title;

  /// Helper to determine if playlist is editable
  bool get isEditable => !smart;

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

  factory PlexPlaylist.fromJson(Map<String, dynamic> json) =>
      _$PlexPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlexPlaylistToJson(this);
}
