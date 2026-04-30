import 'media_stream.dart';

/// One physical file part of a [MediaVersion]. A movie typically has a single
/// part; some Plex multi-part files (CD1/CD2) and DVD/BluRay rips can have
/// several. Jellyfin items always map to a single part per media source.
class MediaPart {
  /// Backend-opaque part identifier.
  final String id;

  /// Backend-specific path used to construct a direct stream URL — e.g. Plex's
  /// `/library/parts/123/file.mkv` or Jellyfin's `/Videos/{id}/stream`. The
  /// per-backend client is responsible for prefixing the base URL and
  /// appending auth.
  final String? streamPath;

  final int? sizeBytes;
  final String? container;
  final int? durationMs;
  final bool? accessible;
  final bool? exists;
  final List<MediaStream> streams;

  const MediaPart({
    required this.id,
    this.streamPath,
    this.sizeBytes,
    this.container,
    this.durationMs,
    this.accessible,
    this.exists,
    this.streams = const [],
  });

  /// Defaults to true when fields are absent. Plex sets these only when the
  /// metadata request includes `checkFiles=1`.
  bool get isPlayable => accessible != false && exists != false;
}
