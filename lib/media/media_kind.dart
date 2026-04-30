/// Backend-neutral classification of a media item.
///
/// Mirrors the categories in [PlexMediaType] but is the canonical type used by
/// neutral domain models. Each backend's adapter is responsible for mapping
/// its own type strings (Plex `type` field, Jellyfin `BaseItemKind`) into one
/// of these values.
enum MediaKind {
  movie,
  show,
  season,
  episode,
  artist,
  album,
  track,
  collection,
  playlist,
  clip,
  photo,
  unknown;

  bool get isVideo => this == movie || this == episode || this == clip;

  bool get isShowRelated => this == show || this == season || this == episode;

  bool get isMusic => this == artist || this == album || this == track;

  bool get isPlayable => isVideo || this == track;

  /// Lowercase string id used when persisting or comparing legacy code paths
  /// that still hold raw type strings.
  String get id => switch (this) {
    MediaKind.movie => 'movie',
    MediaKind.show => 'show',
    MediaKind.season => 'season',
    MediaKind.episode => 'episode',
    MediaKind.artist => 'artist',
    MediaKind.album => 'album',
    MediaKind.track => 'track',
    MediaKind.collection => 'collection',
    MediaKind.playlist => 'playlist',
    MediaKind.clip => 'clip',
    MediaKind.photo => 'photo',
    MediaKind.unknown => 'unknown',
  };

  static MediaKind fromString(String? raw) {
    if (raw == null) return MediaKind.unknown;
    return switch (raw.toLowerCase()) {
      'movie' => MediaKind.movie,
      'show' || 'series' => MediaKind.show,
      'season' => MediaKind.season,
      'episode' => MediaKind.episode,
      'artist' || 'musicartist' => MediaKind.artist,
      'album' || 'musicalbum' => MediaKind.album,
      'track' || 'audio' => MediaKind.track,
      'collection' || 'boxset' => MediaKind.collection,
      'playlist' => MediaKind.playlist,
      'clip' || 'trailer' => MediaKind.clip,
      'photo' => MediaKind.photo,
      _ => MediaKind.unknown,
    };
  }
}
