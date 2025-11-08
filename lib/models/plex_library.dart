import 'package:flutter/material.dart';
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
  });

  factory PlexLibrary.fromJson(Map<String, dynamic> json) =>
      _$PlexLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$PlexLibraryToJson(this);

  /// Determines if this library is an audiobook library.
  ///
  /// Audiobooks in Plex are stored as music libraries (type: "artist") but use
  /// specific metadata agents like audnexus, audiobooks, or audiobookshelf.
  ///
  /// Returns true if:
  /// - The library type is "artist" AND
  /// - The agent contains "audnexus", "audiobook", or "audiobookshelf" (case-insensitive)
  ///
  /// Returns false if:
  /// - The library type is not "artist"
  /// - The agent is null
  /// - The agent doesn't contain any audiobook-specific patterns
  bool get isAudiobookLibrary {
    if (type.toLowerCase() != 'artist') return false;

    final agentLower = agent?.toLowerCase() ?? '';
    return agentLower.contains('audnexus') ||
        agentLower.contains('audiobook') ||
        agentLower.contains('audiobookshelf');
  }

  /// Returns the appropriate icon for this library type.
  ///
  /// Uses Icons.headphones for audiobook libraries, and type-specific icons
  /// for other library types.
  IconData get libraryIcon {
    if (isAudiobookLibrary) {
      return Icons.headphones;
    }

    switch (type.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'artist':
        return Icons.music_note;
      case 'photo':
        return Icons.photo;
      default:
        return Icons.folder;
    }
  }
}
