import 'plex_metadata.dart';

/// Extension on PlexMetadata for type checking convenience methods
extension PlexMetadataType on PlexMetadata {
  bool get isShow => type.toLowerCase() == 'show';
  bool get isMovie => type.toLowerCase() == 'movie';
  bool get isSeason => type.toLowerCase() == 'season';
  bool get isEpisode => type.toLowerCase() == 'episode';
  bool get isArtist => type.toLowerCase() == 'artist';
  bool get isAlbum => type.toLowerCase() == 'album';
  bool get isTrack => type.toLowerCase() == 'track';
  bool get isCollection => type.toLowerCase() == 'collection';
  bool get isPlaylist => type.toLowerCase() == 'playlist';
  bool get isClip => type.toLowerCase() == 'clip';
  bool get isMusicContent => isArtist || isAlbum || isTrack;
  bool get isVideoContent => isShow || isMovie || isSeason || isEpisode;
}
