/// Type of an embedded or sidecar stream within a media file.
enum MediaStreamKind { video, audio, subtitle, unknown }

/// A single audio, video, or subtitle stream inside a media part.
class MediaStream {
  /// Backend-opaque stream identifier.
  final String id;
  final MediaStreamKind kind;
  final int? index;
  final String? codec;
  final String? language;
  final String? languageCode;
  final String? title;
  final String? displayTitle;
  final bool selected;

  // Audio
  final int? channels;

  // Video
  final double? frameRate;

  // Subtitle
  final bool forced;

  /// Backend-resolved location for sidecar subtitle download. For Plex this
  /// is the Plex-specific `/library/streams/{id}` path; for Jellyfin this is
  /// the `DeliveryUrl` returned by `/Items/{id}/PlaybackInfo`. Null for
  /// embedded streams.
  final String? sidecarPath;

  const MediaStream({
    required this.id,
    required this.kind,
    this.index,
    this.codec,
    this.language,
    this.languageCode,
    this.title,
    this.displayTitle,
    this.selected = false,
    this.channels,
    this.frameRate,
    this.forced = false,
    this.sidecarPath,
  });

  bool get isExternal => sidecarPath != null && sidecarPath!.isNotEmpty;
}
