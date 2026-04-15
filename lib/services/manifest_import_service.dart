// lib/services/manifest_import_service.dart
//
// PlexSyncer manifest import — SAF reader + JSON parser.
//
// This service is responsible ONLY for:
//   - locating _plezy_meta/manifest.json in the SAF tree
//   - reading + parsing it
//   - resolving each relativePath to a SAF content:// URI
//
// It has no direct database access. The DownloadProvider.importFromManifest()
// method calls this service and then delegates DB writes to DownloadManagerService.
//
// CHERRY-PICK NOTES
// -----------------
// This is a standalone new file. It touches nothing in the existing codebase.
// No conflict risk on upstream merges.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/download_storage_service.dart';
import '../services/saf_storage_service.dart';
import '../utils/app_logger.dart';

/// A single resolved item ready to be registered in the database.
class ResolvedManifestItem {
  final String  ratingKey;
  final String  type;
  final String  title;
  final String? summary;
  final String? thumb;
  final int?    duration;
  final int?    year;

  // Episodes only
  final String? grandparentTitle;
  final String? grandparentRatingKey;
  final String? grandparentThumb;
  final int?    grandparentYear;
  final String? parentTitle;
  final String? parentRatingKey;
  final int?    seasonNumber;
  final int?    episodeNumber;

  /// SAF content:// URI for the video file — confirmed present on device.
  final String fileUri;

  const ResolvedManifestItem({
    required this.ratingKey,
    required this.type,
    required this.title,
    required this.fileUri,
    this.summary,
    this.thumb,
    this.duration,
    this.year,
    this.grandparentTitle,
    this.grandparentRatingKey,
    this.grandparentThumb,
    this.grandparentYear,
    this.parentTitle,
    this.parentRatingKey,
    this.seasonNumber,
    this.episodeNumber,
  });
}

/// Result returned by [ManifestImportService.readManifest].
class ManifestReadResult {
  final String  serverId;
  final String  serverName;
  final List<ResolvedManifestItem> resolved;
  final int     missing;   // files listed in manifest but not found on device
  final String? error;     // null on success

  const ManifestReadResult({
    this.serverId   = '',
    this.serverName = '',
    this.resolved   = const [],
    this.missing    = 0,
    this.error,
  });

  bool get hasError => error != null;
}

class ManifestImportService {
  static ManifestImportService? _instance;
  static ManifestImportService get instance =>
      _instance ??= ManifestImportService._();
  ManifestImportService._();

  /// Read, parse, and resolve the manifest, returning ready-to-register items.
  ///
  /// Returns a [ManifestReadResult] with an [error] string if something went
  /// wrong at the SAF or JSON level. Individual files that are not yet on the
  /// device are counted in [missing] but do not cause an error.
  Future<ManifestReadResult> readManifest() async {
    final storageService = DownloadStorageService.instance;

    if (!storageService.isUsingSaf) {
      return const ManifestReadResult(
        error: 'No SAF download folder configured.\n'
               'Set a download folder in Settings → Downloads first.',
      );
    }

    final safBaseUri = storageService.safBaseUri!;
    final saf        = SafStorageService.instance;

    // ── Locate and read manifest.json ────────────────────────────────────────
    final String manifestJson;
    try {
      manifestJson = await _readManifestBytes(saf, safBaseUri);
    } catch (e) {
      appLogger.e('ManifestImport: cannot read manifest', error: e);
      return ManifestReadResult(
        error: 'Could not read _plezy_meta/manifest.json.\n'
               'Make sure the sync folder has been transferred to this device.',
      );
    }

    // ── Parse JSON ───────────────────────────────────────────────────────────
    final Map<String, dynamic> manifest;
    final List<dynamic> rawItems;
    try {
      manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      rawItems = manifest['items'] as List<dynamic>? ?? [];
    } catch (e) {
      appLogger.e('ManifestImport: invalid JSON', error: e);
      return const ManifestReadResult(error: 'manifest.json contains invalid JSON.');
    }

    final serverId   = (manifest['serverId']   as String?) ?? '';
    final serverName = (manifest['serverName'] as String?) ?? '';

    if (serverId.isEmpty) {
      return const ManifestReadResult(error: 'manifest.json is missing serverId.');
    }

    // ── Resolve each item ────────────────────────────────────────────────────
    final resolved = <ResolvedManifestItem>[];
    int missing    = 0;

    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;

      final ratingKey    = (raw['ratingKey']    as String?) ?? '';
      final type         = (raw['type']         as String?) ?? '';
      final relativePath = (raw['relativePath'] as String?) ?? '';
      final title        = (raw['title']        as String?) ?? '';

      if (ratingKey.isEmpty || type.isEmpty || relativePath.isEmpty) {
        appLogger.w('ManifestImport: incomplete item, skipping: $raw');
        continue;
      }

      // Resolve the file to a SAF content:// URI.
      final fileUri = await _resolveToUri(saf, safBaseUri, relativePath);
      if (fileUri == null) {
        appLogger.w('ManifestImport: not found on device: $relativePath');
        missing++;
        continue;
      }

      resolved.add(ResolvedManifestItem(
        ratingKey:            ratingKey,
        type:                 type,
        title:                title,
        fileUri:              fileUri,
        summary:              raw['summary']             as String?,
        thumb:                raw['thumb']               as String?,
        duration:             raw['duration']            as int?,
        year:                 raw['year']                as int?,
        grandparentTitle:     raw['grandparentTitle']    as String?,
        grandparentRatingKey: raw['grandparentRatingKey'] as String?,
        grandparentThumb:     raw['grandparentThumb']    as String?,
        grandparentYear:      raw['grandparentYear']     as int?,
        parentTitle:          raw['parentTitle']         as String?,
        parentRatingKey:      raw['parentRatingKey']     as String?,
        seasonNumber:         raw['seasonNumber']        as int?,
        episodeNumber:        raw['episodeNumber']       as int?,
      ));
    }

    appLogger.i(
      'ManifestImport: resolved ${resolved.length} items, $missing missing',
    );
    return ManifestReadResult(
      serverId:   serverId,
      serverName: serverName,
      resolved:   resolved,
      missing:    missing,
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<String> _readManifestBytes(
    SafStorageService saf,
    String safBaseUri,
  ) async {
    final metaDir = await saf.getChild(safBaseUri, '_plezy_meta');
    if (metaDir == null) throw Exception('_plezy_meta directory not found');

    final manifestFile = await saf.getChild(metaDir.uri, 'manifest.json');
    if (manifestFile == null) throw Exception('manifest.json not found');

    final bytes = await saf.readFileBytes(manifestFile.uri);
    if (bytes == null) throw Exception('Could not read manifest.json');

    return utf8.decode(bytes);
  }

  /// Walk the SAF tree one segment at a time to resolve a relative path like
  /// "TV Shows/ALF (1986)/Season 01/S01E01 - A_L_F.mp4" to a content:// URI.
  Future<String?> _resolveToUri(
    SafStorageService saf,
    String safBaseUri,
    String relativePath,
  ) async {
    final segments = relativePath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    String currentUri = safBaseUri;
    for (final segment in segments) {
      final child = await saf.getChild(currentUri, segment);
      if (child == null) return null;
      currentUri = child.uri;
    }
    return currentUri;
  }
}
