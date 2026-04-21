import 'package:json_annotation/json_annotation.dart';

import 'mixins/multi_server_fields.dart';
import '../utils/global_key_utils.dart';
import '../utils/json_utils.dart';

part 'plex_library.g.dart';

@JsonSerializable()
class PlexLibrary with MultiServerFields {
  @JsonKey(readValue: readStringField)
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

  // Multi-server support fields (from MultiServerFields mixin)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;

  /// Whether this is a shared library (individually shared items, not a real section)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isShared;

  /// Global unique identifier across all servers (serverId:key)
  String get globalKey => serverId != null ? buildGlobalKey(serverId!, key) : key;

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
    this.isShared = false,
  });

  factory PlexLibrary.fromJson(Map<String, dynamic> json) => _$PlexLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$PlexLibraryToJson(this);

  /// Create a copy of this library with optional field overrides
  PlexLibrary copyWith({
    String? key,
    String? title,
    String? type,
    String? agent,
    String? scanner,
    String? language,
    String? uuid,
    int? updatedAt,
    int? createdAt,
    int? hidden,
    String? serverId,
    String? serverName,
    bool? isShared,
  }) {
    return PlexLibrary(
      key: key ?? this.key,
      title: title ?? this.title,
      type: type ?? this.type,
      agent: agent ?? this.agent,
      scanner: scanner ?? this.scanner,
      language: language ?? this.language,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      hidden: hidden ?? this.hidden,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      isShared: isShared ?? this.isShared,
    );
  }
}
