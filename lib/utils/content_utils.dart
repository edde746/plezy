import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/plex_metadata.dart';

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

  /// Checks if the given library is a music library
  static bool isMusicLibrary(dynamic lib) {
    if (lib == null) return false;
    try {
      final type = (lib as dynamic).type as String?;
      return type?.toLowerCase() == ContentTypes.artist;
    } catch (e) {
      return false;
    }
  }

  /// Filters out music content from a list of items
  static List<T> filterOutMusic<T>(List<T> items, String Function(T) getType) {
    return items.where((item) => !isMusicContent(getType(item))).toList();
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

/// Extension on PlexMetadata for type checking convenience methods
extension PlexMetadataType on PlexMetadata {
  String get _lowerType => type.toLowerCase();

  bool get isShow => _lowerType == ContentTypes.show;
  bool get isMovie => _lowerType == ContentTypes.movie;
  bool get isSeason => _lowerType == ContentTypes.season;
  bool get isEpisode => _lowerType == ContentTypes.episode;
  bool get isArtist => _lowerType == ContentTypes.artist;
  bool get isAlbum => _lowerType == ContentTypes.album;
  bool get isTrack => _lowerType == ContentTypes.track;
  bool get isCollection => _lowerType == ContentTypes.collection;
  bool get isPlaylist => _lowerType == ContentTypes.playlist;
  bool get isClip => _lowerType == ContentTypes.clip;
  bool get isMusicContent => ContentTypes.musicTypes.contains(_lowerType);
  bool get isVideoContent => ContentTypes.videoTypes.contains(_lowerType);

  /// Whether this episode should have spoiler protection applied.
  /// True when the item is an unwatched episode watched less than 50%.
  bool get shouldHideSpoiler {
    if (!isEpisode) return false;
    if (isWatched) return false;
    if (viewOffset != null && viewOffset! > 0 && duration != null && duration! > 0) {
      return viewOffset! / duration! < 0.5;
    }
    return true;
  }
}
