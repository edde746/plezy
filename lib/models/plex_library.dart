import 'package:json_annotation/json_annotation.dart';

part 'plex_library.g.dart';

@JsonSerializable()
class PlexLibrary {
  final String key;
  final String title;
  final String type;
  final String? agent;
  final String? scanner;
  final String? language;
  final String? uuid;
  final int? updatedAt;
  final int? createdAt;
  final int? hidden;

  // Multi-server support fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId; // Server machine identifier (not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName; // Server display name (not from API)

  /// Global unique identifier across all servers (serverId:key)
  String get globalKey => serverId != null ? '$serverId:$key' : key;

  PlexLibrary({
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
  });

  factory PlexLibrary.fromJson(Map<String, dynamic> json) =>
      _$PlexLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$PlexLibraryToJson(this);
}
