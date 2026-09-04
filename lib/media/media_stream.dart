/// Type of an embedded or sidecar stream within a media file.
enum MediaStreamKind { video, audio, subtitle, image, data, lyric, unknown }

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

  /// The server's current pick for this user (Plex `selected`, Jellyfin's
  /// default-stream index). Distinct from [isDefault]: Plex marks the
  /// container's default track separately, and the player's selection ladder
  /// ranks the two differently.
  final bool selected;

  /// The container's own default flag (Plex `default`, Jellyfin `IsDefault`).
  final bool isDefault;

  // Audio
  final int? channels;

  // Video
  final double? frameRate;
  final bool hdr;
  final bool dolbyVision;
  final int? dolbyVisionProfile;

  // Subtitle
  final bool forced;

  /// Backend-resolved location for true sidecar subtitle download. Null for
  /// embedded streams, even when Jellyfin can expose them through temporary
  /// external delivery URLs during playback negotiation.
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
    this.isDefault = false,
    this.channels,
    this.frameRate,
    this.hdr = false,
    this.dolbyVision = false,
    this.dolbyVisionProfile,
    this.forced = false,
    this.sidecarPath,
  });

  bool get isExternal => sidecarPath != null && sidecarPath!.isNotEmpty;
}
