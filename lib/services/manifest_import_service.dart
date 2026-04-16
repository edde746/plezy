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
// method calls this service and delegates DB writes to DownloadManagerService.
//
// CHERRY-PICK NOTES
// -----------------
// This is a standalone new file. It touches nothing in the existing codebase.
// No conflict risk on upstream merges.

import 'dart:convert';
import '../services/download_storage_service.dart';
import '../services/saf_storage_service.dart';
import '../utils/app_logger.dart';

/// Subdirectory within the SAF root where PlexSyncer files live.
/// Must match PLEXSYNCER_DIR in plex_hardlink_sync.py.
const kPlexSyncerFolder = 'PlexSyncer';

/// A single resolved item ready to be registered in the database.
class ResolvedManifestItem {
  final String  ratingKey;
  final String  type;
  final String  title;
  final String? summary;
  final String? thumb;
  final String? art;
  final int?    duration;
  final int?    year;

  // Episodes only
  final String? grandparentTitle;
  final String? grandparentRatingKey;
  final String? grandparentThumb;
  final String? grandparentArt;
  final int?    grandparentYear;
  final String? parentTitle;
  final String? parentRatingKey;
  final String? parentThumb;
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
    this.art,
    this.duration,
    this.year,
    this.grandparentTitle,
    this.grandparentRatingKey,
    this.grandparentThumb,
    this.grandparentArt,
    this.grandparentYear,
    this.parentTitle,
    this.parentRatingKey,
    this.parentThumb,
    this.seasonNumber,
    this.episodeNumber,
  });
}

/// Result returned by [ManifestImportService.readManifest].
class ManifestReadResult {
  final String  serverId;
  final String  serverName;
  final List<ResolvedManifestItem> resolved;
  final int     missing;         // files listed in manifest but not found on device
  final String? error;           // null on success

  /// SAF URI of the PlexSyncer subfolder (e.g. content://.../PlexSyncer).
  /// Used by the prune step to identify which DB items belong to PlexSyncer.
  final String  psRootUri;

  /// All serverId:ratingKey pairs present in this manifest.
  /// Items previously imported but no longer here were removed by PlexSyncer.
  final Set<String> manifestGlobalKeys;

  const ManifestReadResult({
    this.serverId          = '',
    this.serverName        = '',
    this.resolved          = const [],
    this.missing           = 0,
    this.error,
    this.psRootUri         = '',
    this.manifestGlobalKeys = const {},
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

    // Navigate into the PlexSyncer subfolder first.
    final psRoot = await saf.getChild(safBaseUri, kPlexSyncerFolder);
    if (psRoot == null) {
      return const ManifestReadResult(
        error: 'PlexSyncer folder not found in the configured SAF root.\n'
               'Make sure rclone / Round Sync has finished transferring files.',
      );
    }

    // ── Locate and read manifest.json ────────────────────────────────────────
    final String manifestJson;
    try {
      manifestJson = await _readManifestBytes(saf, psRoot.uri);
    } catch (e) {
      appLogger.e('ManifestImport: cannot read manifest', error: e);
      return const ManifestReadResult(
        error: 'Could not read PlexSyncer/_plezy_meta/manifest.json.\n'
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
    final resolved           = <ResolvedManifestItem>[];
    final manifestGlobalKeys = <String>{};
    int missing              = 0;

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

      manifestGlobalKeys.add('$serverId:$ratingKey');

      // Resolve the file to a SAF content:// URI.
      final fileUri = await _resolveToUri(saf, psRoot.uri, relativePath);
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
        art:                  raw['art']                 as String?,
        duration:             raw['duration']            as int?,
        year:                 raw['year']                as int?,
        grandparentTitle:     raw['grandparentTitle']    as String?,
        grandparentRatingKey: raw['grandparentRatingKey'] as String?,
        grandparentThumb:     raw['grandparentThumb']    as String?,
        grandparentArt:       raw['grandparentArt']      as String?,
        grandparentYear:      raw['grandparentYear']     as int?,
        parentTitle:          raw['parentTitle']         as String?,
        parentRatingKey:      raw['parentRatingKey']     as String?,
        parentThumb:          raw['parentThumb']         as String?,
        seasonNumber:         raw['seasonNumber']        as int?,
        episodeNumber:        raw['episodeNumber']       as int?,
      ));
    }

    appLogger.i(
      'ManifestImport: resolved ${resolved.length} items, $missing missing',
    );
    return ManifestReadResult(
      serverId:           serverId,
      serverName:         serverName,
      resolved:           resolved,
      missing:            missing,
      psRootUri:          psRoot.uri,
      manifestGlobalKeys: manifestGlobalKeys,
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
