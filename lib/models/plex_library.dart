import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'mixins/multi_server_fields.dart';
import '../utils/global_key_utils.dart';

part 'plex_library.g.dart';

@JsonSerializable()
class PlexLibrary with MultiServerFields {
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

  /// Global unique identifier across all servers (serverId:key)
  String get globalKey => serverId != null ? buildGlobalKey(serverId!, key) : key;

  /// Whether this library contains audiobooks (music library with audiobook agent)
  bool get isAudiobookLibrary {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('audiobooks')) return true;
    if (type.toLowerCase() != 'artist') return false;
    final agentLower = agent?.toLowerCase() ?? '';
    if (agentLower.contains('audiobookshelf')) return true;
    if (agentLower.contains('audnexus')) return true;
    if (agentLower.contains('audiobook')) return true;
    return false;
  }

  /// Icon for this library type
  IconData get libraryIcon {
    if (isAudiobookLibrary) return Icons.headphones;
    switch (type.toLowerCase()) {
      case 'movie': return Icons.movie;
      case 'show': return Icons.tv;
      case 'artist': return Icons.music_note;
      case 'photo': return Icons.photo;
      default: return Icons.folder;
    }
  }

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
    );
  }
}
