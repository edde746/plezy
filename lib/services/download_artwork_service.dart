import 'dart:io';
import '../media/ids.dart';

import '../media/download_resolution.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';
import 'download_artwork_helpers.dart';
import 'download_storage_service.dart';

class _ArtworkDownloadOperation {
  final Future<void> future;

  const _ArtworkDownloadOperation(this.future);
}

/// Centralized helper for downloaded artwork keys, paths, and file writes.
///
/// Downloaded artwork is addressed by a normalized storage key rather than the
/// raw metadata path. This matters for Jellyfin because metadata URLs include
/// `api_key`, while local filenames must not contain long-lived tokens.
class DownloadArtworkService {
  static final Map<String, _ArtworkDownloadOperation> _downloadsByPath = <String, _ArtworkDownloadOperation>{};

  final DownloadStorageService storageService;
  final MediaServerHttpClient http;

  const DownloadArtworkService({required this.storageService, required this.http});

  static String normalizeKey(String pathOrUrl) => artworkStorageKey(pathOrUrl);

  static String? localPathSync(DownloadStorageService storageService, ServerId serverId, String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    return storageService.getArtworkPathSync(serverId, normalizeKey(pathOrUrl));
  }

  Future<String> localPath(ServerId serverId, String pathOrUrl) {
    return storageService.getArtworkPathFromThumb(serverId, normalizeKey(pathOrUrl));
  }

  Future<bool> existsUsable(ServerId serverId, String pathOrUrl) async {
    final file = File(await localPath(serverId, pathOrUrl));
    return isUsableArtworkFile(file);
  }

  Future<bool> hasMissingArtwork(ServerId serverId, Iterable<DownloadArtworkSpec> specs) async {
    for (final spec in specs) {
      if (!await existsUsable(serverId, spec.localKey)) return true;
    }
    return false;
  }

  Future<void> ensureArtworkForMetadata(MediaItem metadata, MediaServerClient client) async {
    final serverId = metadata.serverId;
    if (serverId == null) return;
    await ensureArtworkSpecs(ServerId(serverId), client.resolveDownloadArtwork(metadata));
  }

  Future<void> ensureArtworkSpecs(ServerId serverId, Iterable<DownloadArtworkSpec> specs) async {
    for (final spec in specs) {
      await downloadSingleArtwork(serverId, spec);
    }
  }

  /// Download one artwork blob if it is missing or unusable.
  ///
  /// The HTTP helper writes atomically. This method validates the final file so
  /// HTML/JSON error bodies do not poison future existence checks.
  Future<void> downloadSingleArtwork(ServerId serverId, DownloadArtworkSpec spec) async {
    if (spec.url.isEmpty) {
      appLogger.w('Empty artwork URL for: ${spec.localKey}');
      return;
    }

    final filePath = await localPath(serverId, spec.localKey);
    final inFlight = _downloadsByPath[filePath];
    if (inFlight != null) {
      await inFlight.future;
      return;
    }

    final operation = _ArtworkDownloadOperation(_downloadSingleArtworkToPath(serverId, spec, filePath));
    _downloadsByPath[filePath] = operation;
    try {
      await operation.future;
    } finally {
      if (identical(_downloadsByPath[filePath], operation)) {
        _downloadsByPath.remove(filePath);
      }
    }
  }

  Future<void> _downloadSingleArtworkToPath(ServerId serverId, DownloadArtworkSpec spec, String filePath) async {
    try {
      if (await existsUsable(serverId, spec.localKey)) {
        appLogger.d('Artwork already exists: ${spec.localKey}');
        return;
      }

      final file = File(filePath);
      await file.parent.create(recursive: true);

      if (await file.exists()) {
        await file.delete();
      }

      await http.downloadFile(spec.url, filePath);

      if (!await isUsableArtworkFile(file)) {
        if (await file.exists()) await file.delete();
        appLogger.w('Downloaded artwork was not a usable image: ${spec.localKey}');
        return;
      }

      appLogger.i('Downloaded artwork: ${spec.localKey} -> $filePath');
    } catch (e, stack) {
      appLogger.w('Failed to download artwork: ${spec.localKey}', error: e, stackTrace: stack);
    }
  }

  static Future<bool> isUsableArtworkFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length <= 0) return false;

      final raf = await file.open();
      try {
        final bytes = await raf.read(length < 512 ? length : 512);
        final prefix = String.fromCharCodes(bytes.take(128)).trimLeft().toLowerCase();
        if (prefix.startsWith('<!doctype html') || prefix.startsWith('<html') || prefix.startsWith('{')) {
          return false;
        }
        return true;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }
}
