/// Backend-neutral download resolution types.
///
/// Returned by [MediaServerClient] download-resolution methods so the
/// [DownloadManagerService] doesn't need to know whether it's talking to
/// Plex or Jellyfin.
library;

import '../models/transcode_quality_preset.dart';
import 'media_item.dart';

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

  /// File extension for [videoUrl] when its path does not carry one, as with
  /// a server-converted file. Null lets the URL decide.
  final String? videoExtension;

  const DownloadResolution({
    required this.videoUrl,
    this.mediaSourceId,
    this.externalSubtitles = const [],
    this.externalSubtitlesResolved = true,
    this.additionalParts = const [],
    this.videoExtension,
  });
}

/// Where a server-side conversion of a download stands.
sealed class ConvertedDownloadState {
  const ConvertedDownloadState();
}

/// The converted file is ready to fetch from [url]. Stacked versions come
/// back joined into this one file.
class ConvertedDownloadReady extends ConvertedDownloadState {
  final String url;

  /// Container the server converted to (`mkv`, `mp4`), when it said.
  final String? container;

  const ConvertedDownloadReady({required this.url, this.container});
}

/// The server is still deciding or converting. Ask again after [retryAfter].
class ConvertedDownloadPending extends ConvertedDownloadState {
  /// Conversion progress 0–100, or null while the item waits its turn.
  final int? percent;
  final Duration retryAfter;

  const ConvertedDownloadPending({this.percent, required this.retryAfter});
}

/// The server could not convert the item.
class ConvertedDownloadFailed extends ConvertedDownloadState {
  final String reason;

  const ConvertedDownloadFailed(this.reason);
}

/// A backend that can convert a download to a lower quality on the server
/// before the device fetches it, so a small screen does not have to store
/// the full-size original.
///
/// Requesting the same item at the same quality again must be idempotent:
/// the download pipeline re-asks after every wait, app restart, and resume
/// rather than persisting the server's job id.
abstract interface class ConvertedDownloadClient {
  Future<ConvertedDownloadState> requestConvertedDownload(
    MediaItem item, {
    required int mediaIndex,
    required TranscodeQualityPreset preset,
  });
}
