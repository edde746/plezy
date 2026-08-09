import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:saf_util/saf_util.dart';

import '../media/media_file_info.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/app_logger.dart';

/// Describes the single-stream artifact produced by a Plex download
/// transcode. Plex's live response is not added to the library, so querying
/// `/library/metadata` after completion can only describe the source file.
Future<MediaFileInfo?> getTranscodedDownloadFileInfo({
  required String filePath,
  required TranscodeQualityPreset qualityPreset,
  int? durationMs,
}) async {
  if (qualityPreset.isOriginal) return null;

  final fileSize = await _localFileSize(filePath);
  final container = _containerFromPath(filePath) ?? 'mkv';
  final resolutionHeight = qualityPreset.resolutionHeight;
  final bitrateKbps = fileSize != null && durationMs != null && durationMs > 0
      ? (fileSize * 8 / durationMs).round()
      : null;

  return MediaFileInfo(
    versions: [
      MediaFileVersion(
        container: container,
        bitrateKbps: bitrateKbps,
        durationMs: durationMs,
        videoResolutionLabel: resolutionHeight == null ? null : '${resolutionHeight}p',
        videoCodec: 'h264',
        audioCodec: 'aac',
        protocol: 'File',
        supportsDirectPlay: true,
        parts: [
          MediaFilePart(
            filePath: filePath,
            fileSize: fileSize,
            container: container,
            durationMs: durationMs,
            exists: true,
            accessible: true,
            streams: [
              MediaStreamDetails(kind: MediaStreamKind.video, ordinal: 1, codec: 'h264'),
              MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 1, codec: 'aac'),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _containerFromPath(String filePath) {
  final parsedPath = filePath.startsWith('content://') ? Uri.parse(filePath).path : filePath;
  final extension = path.extension(parsedPath).replaceFirst('.', '').toLowerCase();
  return extension.isEmpty ? null : extension;
}

Future<int?> _localFileSize(String filePath) async {
  try {
    if (filePath.startsWith('content://')) {
      final document = await SafUtil().stat(filePath, false);
      return document == null || document.length < 0 ? null : document.length;
    }
    final file = File(filePath);
    return await file.exists() ? file.length() : null;
  } catch (error, stackTrace) {
    appLogger.w('Could not read downloaded file size for File Info', error: error, stackTrace: stackTrace);
    return null;
  }
}
