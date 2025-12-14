import '../utils/content_type_helper.dart';
import 'plex_metadata.dart';

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
}
