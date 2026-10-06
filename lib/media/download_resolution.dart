/// Backend-neutral download resolution types.
///
/// Returned by [MediaServerClient] download-resolution methods so the
/// [DownloadManagerService] doesn't need to know whether it's talking to
/// Plex or Jellyfin.
library;

/// Spec for a single external subtitle track that should be downloaded
/// alongside the video file.
///
/// `id` is a backend-stable integer used in the on-disk filename
/// (Plex stream id, Jellyfin stream index).
class DownloadSubtitleSpec {
  final int id;
  final String url;
  final String? codec;
  final String? language;
  final String? languageCode;
  final bool forced;
  final String? displayTitle;

  const DownloadSubtitleSpec({
    required this.id,
    required this.url,
    this.codec,
    this.language,
    this.languageCode,
    this.forced = false,
    this.displayTitle,
  });
}

/// Spec for a single artwork file. `localKey` is the deterministic key the
/// storage service hashes to compute the on-disk filename — Plex passes the
/// backend-relative path so cache deduplication works across items that
/// reference the same blob; Jellyfin passes the absolute URL since artwork
/// URLs are already unique per item after stripping auth query parameters.
class DownloadArtworkSpec {
  final String localKey;
  final String url;

  const DownloadArtworkSpec({required this.localKey, required this.url});
}

/// A file after the first of an item stacked across several files (Plex
/// `Part 2`, `Part 3`), with the subtitle sidecars that belong to that file.
class DownloadPartResolution {
  final String url;
  final List<DownloadSubtitleSpec> externalSubtitles;

  const DownloadPartResolution({required this.url, this.externalSubtitles = const []});
}

/// Bundle of everything the download pipeline needs to fetch the primary
/// video file and its companion subtitle sidecars for a chosen media
/// version.
class DownloadResolution {
  /// The first (for most items the only) file.
  final String? videoUrl;
  final String? mediaSourceId;
  final List<DownloadSubtitleSpec> externalSubtitles;

  /// Whether [externalSubtitles] is authoritative. A false value keeps the
  /// supplementary-download queue pending so it can retry enrichment later.
  final bool externalSubtitlesResolved;

  /// The files after [videoUrl], in playback order, when the version is
  /// stacked across several files. Empty for a single-file version.
  final List<DownloadPartResolution> additionalParts;

  const DownloadResolution({
    required this.videoUrl,
    this.mediaSourceId,
    this.externalSubtitles = const [],
    this.externalSubtitlesResolved = true,
    this.additionalParts = const [],
  });
}
