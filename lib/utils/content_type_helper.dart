/// Utility class for content type checking and filtering
class ContentTypeHelper {
  /// Checks if the given type is music content (artist, album, or track)
  ///
  /// [type] The content type string to check
  /// Returns true if the type is artist, album, or track (case-insensitive)
  static bool isMusicContent(String type) {
    final lowerType = type.toLowerCase();
    return lowerType == 'artist' ||
        lowerType == 'album' ||
        lowerType == 'track';
  }

  /// Checks if the given library is a music library
  ///
  /// [lib] The library object to check (must have a 'type' property)
  /// Returns true if the library type is 'artist' (case-insensitive)
  static bool isMusicLibrary(dynamic lib) {
    if (lib == null) return false;
    try {
      final type = (lib as dynamic).type as String?;
      return type?.toLowerCase() == 'artist';
    } catch (e) {
      return false;
    }
  }

  /// Checks if the given type is video content (movie, show, episode, or season)
  ///
  /// [type] The content type string to check
  /// Returns true if the type is movie, show, episode, or season (case-insensitive)
  static bool isVideoContent(String type) {
    final lowerType = type.toLowerCase();
    return lowerType == 'movie' ||
        lowerType == 'show' ||
        lowerType == 'episode' ||
        lowerType == 'season';
  }

  /// Filters out music content from a list of items
  ///
  /// [items] The list of items to filter
  /// [getType] A function that extracts the type string from each item
  /// Returns a new list with music content removed
  ///
  /// Example:
  /// ```dart
  /// final filtered = ContentTypeHelper.filterOutMusic(
  ///   items,
  ///   (item) => item.type,
  /// );
  /// ```
  static List<T> filterOutMusic<T>(List<T> items, String Function(T) getType) {
    return items.where((item) => !isMusicContent(getType(item))).toList();
  }
}
