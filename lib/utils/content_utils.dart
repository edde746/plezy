import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Content type constants used throughout the app
class ContentTypes {
  ContentTypes._();

  static const String movie = 'movie';
  static const String show = 'show';
  static const String season = 'season';
  static const String episode = 'episode';
  static const String artist = 'artist';
  static const String album = 'album';
  static const String track = 'track';
  static const String collection = 'collection';
  static const String playlist = 'playlist';
  static const String clip = 'clip';

  static const Set<String> musicTypes = {artist, album, track};
  static const Set<String> videoTypes = {movie, show, season, episode};
  static const Set<String> playableTypes = {movie, episode, clip, track};
}

/// Utility class for content type checking and filtering
class ContentTypeHelper {
  ContentTypeHelper._();

  /// Checks if the given type is music content (artist, album, or track)
  static bool isMusicContent(String type) => ContentTypes.musicTypes.contains(type.toLowerCase());

  /// Checks if the given type is video content (movie, show, episode, or season)
  static bool isVideoContent(String type) => ContentTypes.videoTypes.contains(type.toLowerCase());

  /// Checks if the given [MediaLibrary] is a music library.
  static bool isMusicLibrary(dynamic lib) {
    if (lib == null) return false;
    try {
      // ignore: avoid_dynamic_calls — duck-typed across library shapes
      final type = (lib as dynamic).kind?.id as String?;
      return type?.toLowerCase() == ContentTypes.artist;
    } catch (e) {
      return false;
    }
  }

  /// Returns the appropriate icon for a given library type
  static IconData getLibraryIcon(String type) {
    switch (type.toLowerCase()) {
      case ContentTypes.movie:
        return Symbols.movie_rounded;
      case ContentTypes.show:
        return Symbols.tv_rounded;
      case ContentTypes.artist:
        return Symbols.music_note_rounded;
      case 'photo':
        return Symbols.photo_rounded;
      case 'mixed':
        return Symbols.share_rounded;
      default:
        return Symbols.folder_rounded;
    }
  }
}

/// Utility function to format content ratings by removing country prefixes
String formatContentRating(String? contentRating) {
  if (contentRating == null || contentRating.isEmpty) {
    return '';
  }

  // Remove common country prefixes like "gb/", "us/", "de/", etc.
  // The pattern matches: lowercase letters followed by a forward slash
  final regex = RegExp(r'^[a-z]{2,3}/(.+)$', caseSensitive: false);
  final match = regex.firstMatch(contentRating);

  if (match != null && match.groupCount >= 1) {
    return match.group(1) ?? contentRating;
  }

  return contentRating;
}
