import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../models/plex_library.dart';

/// Extension methods for tagging items with server information
/// Used for multi-server support to track which server each item belongs to

extension PlexMetadataServerTagging on Iterable<PlexMetadata> {
  /// Tags all items in the collection with the given server ID and name
  /// Returns a new list with all items updated
  List<PlexMetadata> tagWithServer(String? serverId, String? serverName) {
    return map(
      (item) => item.copyWith(serverId: serverId, serverName: serverName),
    ).toList();
  }

  /// Tags all items in the collection with server info from a library
  /// Returns a new list with all items updated
  List<PlexMetadata> tagWithLibrary(PlexLibrary library) {
    return tagWithServer(library.serverId, library.serverName);
  }
}

extension PlexPlaylistServerTagging on Iterable<PlexPlaylist> {
  /// Tags all playlists in the collection with the given server ID and name
  /// Returns a new list with all playlists updated
  List<PlexPlaylist> tagWithServer(String? serverId, String? serverName) {
    return map(
      (playlist) =>
          playlist.copyWith(serverId: serverId, serverName: serverName),
    ).toList();
  }

  /// Tags all playlists in the collection with server info from a library
  /// Returns a new list with all playlists updated
  List<PlexPlaylist> tagWithLibrary(PlexLibrary library) {
    return tagWithServer(library.serverId, library.serverName);
  }
}
