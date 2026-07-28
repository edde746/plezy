import 'dart:io';

import '../database/app_database.dart';
import '../models/download_models.dart';
import '../utils/app_logger.dart';
import '../utils/downloaded_version_match.dart';
import 'download_storage_service.dart';

/// A downloaded copy resolved to a playable location, plus the version that is
/// actually on disk — which can differ from the requested one when
/// [resolveDownloadedVideoSource] was allowed to fall back.
typedef DownloadedVideoSource = ({String path, int mediaIndex, String? mediaSourceId});

/// Single source of truth for "where is the playable copy of this downloaded
/// row, and is it the version that was asked for".
///
/// Returns null when the row cannot back playback: the download is not
/// complete, it holds a different version than requested (unless
/// [allowAnyDownloadedVersion]), it has no stored video path, or the stored
/// file is gone from disk.
///
/// Version matching is strict by default so online flows keep streaming an
/// explicitly requested non-downloaded version (issue #1440). With
/// [allowAnyDownloadedVersion] the downloaded version is returned on mismatch
/// instead — for offline flows where the alternative is failing outright.
///
/// Callers own their own preconditions (profile ownership, how the row was
/// looked up); this only judges the row itself.
Future<DownloadedVideoSource?> resolveDownloadedVideoSource(
  DownloadedMediaItem row, {
  int? requestedMediaIndex,
  String? requestedMediaSourceId,
  bool allowAnyDownloadedVersion = false,
}) async {
  if (row.status != DownloadStatus.completed.index) {
    appLogger.d('Download not complete for ${row.globalKey}. Status: ${row.status}');
    return null;
  }

  if (!downloadedVersionMatches(
    row,
    requestedMediaIndex: requestedMediaIndex,
    requestedMediaSourceId: requestedMediaSourceId,
  )) {
    if (!allowAnyDownloadedVersion) {
      appLogger.d(
        '[VersionTrace] Downloaded copy of ${row.globalKey} is version ${row.mediaIndex} '
        '(source ${row.mediaSourceId}), but requested version $requestedMediaIndex '
        '(source ${requestedMediaSourceId?.trim()}) — skipping offline',
      );
      return null;
    }
    appLogger.d(
      '[VersionTrace] Requested version $requestedMediaIndex (source ${requestedMediaSourceId?.trim()}) '
      'is not downloaded — falling back to downloaded version ${row.mediaIndex} '
      '(source ${row.mediaSourceId})',
    );
  }

  final storedPath = row.videoFilePath;
  if (storedPath == null) {
    appLogger.d('Video file path is null for ${row.globalKey}');
    return null;
  }

  final storageService = DownloadStorageService.instance;
  // SAF URIs (content://) are already playable and come back untouched; file
  // paths may be stored relative, so resolve them and confirm they still exist.
  final readablePath = await storageService.getReadablePath(storedPath);
  if (!storageService.isSafUri(storedPath) && !await File(readablePath).exists()) {
    appLogger.w('Offline video file not found: $readablePath (stored as: $storedPath)');
    return null;
  }

  appLogger.d('Found offline video: $readablePath');
  return (path: readablePath, mediaIndex: row.mediaIndex, mediaSourceId: row.mediaSourceId);
}
