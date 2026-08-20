import '../database/app_database.dart';

/// Single source of truth for "does this downloaded row satisfy a version
/// request".
///
/// Source-id comparison wins when both sides have one — Jellyfin merged
/// versions can reorder between item fetches, so the stable id is the only
/// trustworthy discriminator there. Otherwise fall back to the media index.
/// A null [requestedMediaIndex] means "any version" (the caller has no
/// version opinion, e.g. external-player launches keyed by item only).
bool downloadedVersionMatches(DownloadedMediaItem row, {int? requestedMediaIndex, String? requestedMediaSourceId}) {
  final downloadedSourceId = row.mediaSourceId;
  final requestedSourceId = requestedMediaSourceId?.trim();
  final comparedBySourceId =
      requestedSourceId != null &&
      requestedSourceId.isNotEmpty &&
      downloadedSourceId != null &&
      downloadedSourceId.isNotEmpty;
  if (comparedBySourceId) {
    return downloadedSourceId == requestedSourceId;
  }
  if (requestedMediaIndex == null) {
    return true;
  }
  return row.mediaIndex == requestedMediaIndex;
}
