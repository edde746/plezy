import '../media/media_kind.dart';

/// Plex `streamType` integer codes used in the `Stream` array on a Part.
///
/// Lifted into a shared module so [plex_mappers.dart] doesn't need to
/// reach back into [plex_client.dart] (which would close a circular import
/// — the mapper file is consumed by the client). The values match what
/// the Plex Media Server API returns; do not renumber.
class PlexStreamType {
  static const int video = 1;
  static const int audio = 2;
  static const int subtitle = 3;
  static const int lyrics = 4;
}

/// Plex metadata `type` integer codes — the value that goes in the
/// `?type=` query param on `/library/sections/{id}/all` and friends.
///
/// Centralised here so call sites can reference a named constant instead
/// of an inline magic number, and bridge to [MediaKind] in one place.
class PlexMetadataType {
  static const int movie = 1;
  static const int show = 2;
  static const int season = 3;
  static const int episode = 4;
  static const int artist = 8;
  static const int album = 9;
  static const int track = 10;

  /// `type=1,2,3,4` — the standard "everything except music" filter used
  /// by the All / shared-library views, where music libraries surface as
  /// their own top-level kind.
  static const String videoCsv = '1,2,3,4';

  /// Plex `type` code for [kind]; `null` for kinds Plex has no code for.
  static int? forKind(MediaKind? kind) => switch (kind) {
    MediaKind.movie => movie,
    MediaKind.show => show,
    MediaKind.season => season,
    MediaKind.episode => episode,
    MediaKind.artist => artist,
    MediaKind.album => album,
    MediaKind.track => track,
    _ => null,
  };

  /// Inverse of [forKind]; `null` for unknown codes.
  static MediaKind? kindFor(int? type) => switch (type) {
    movie => MediaKind.movie,
    show => MediaKind.show,
    season => MediaKind.season,
    episode => MediaKind.episode,
    artist => MediaKind.artist,
    album => MediaKind.album,
    track => MediaKind.track,
    _ => null,
  };
}
