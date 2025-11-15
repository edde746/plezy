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

  /// Helper to get formatted duration
  String? get formattedDuration {
    if (duration == null) return null;
    final hours = duration! ~/ 3600000;
    final minutes = (duration! % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Helper to determine if playlist is editable
  bool get isEditable => !smart;

  factory PlexPlaylist.fromJson(Map<String, dynamic> json) =>
      _$PlexPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlexPlaylistToJson(this);
}
