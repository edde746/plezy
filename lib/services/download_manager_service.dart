import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as path;
import 'package:plezy/utils/media_server_http_client.dart';
import '../database/app_database.dart';
import '../database/download_operations.dart';
import '../media/download_resolution.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import 'api_cache.dart';
import 'download_artwork_helpers.dart';
import 'settings_service.dart';
import 'saf_storage_service.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import '../models/download_models.dart';
import '../services/offline_mode_source.dart';
import '../services/download_storage_service.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/codec_utils.dart';
import '../utils/global_key_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef MediaClientResolver = MediaServerClient? Function(String serverId, {String? clientScopeId});

class _DownloadContext {
  final MediaItem metadata;
  final DownloadQueueItem queueItem;
  final String filePath; // Absolute path (normal) or SAF dir URI (SAF mode)
  final String extension;
  final MediaServerClient client;
  final int? showYear;
  final bool isSafMode;
  final List<DownloadSubtitleSpec>? subtitles;

  _DownloadContext({
    required this.metadata,
    required this.queueItem,
    required this.filePath,
    required this.extension,
    required this.client,
    this.showYear,
    this.isSafMode = false,
    this.subtitles,
  });
}

class DownloadManagerService {
  final AppDatabase _database;
  final DownloadStorageService _storageService;
  final MediaServerHttpClient _http;

  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  final _deletionProgressController = StreamController<DeletionProgress>.broadcast();
  Stream<DeletionProgress> get deletionProgressStream => _deletionProgressController.stream;

  final Map<String, _DownloadContext> _pendingDownloadContext = {};

  // Items recovered with video complete but supplementary downloads missing
  final Set<String> _pendingSupplementaryDownloads = {};

  // Resolve the correct MediaServerClient for a given serverId/scope (set via setClientResolver).
  // Falls back to _fallbackClient only when no serverId or resolver is available.
  MediaClientResolver? _clientResolver;
  MediaServerClient? _fallbackClient;

  OfflineModeSource? _offlineSource;

  bool _fileDownloaderInitialized = false;
  static const _downloadGroup = 'video_downloads';
  static const _maxAppRetries = 3;
  static const _nativeRetries = 5;
  static const _autoRetryDelay = Duration(seconds: 30);
  static const _progressDebounceDelay = Duration(seconds: 2);
  static const _videoExtensions = {'.mp4', '.ogv', '.mkv', '.m4v', '.avi'};

  // Keys currently being paused — prevents holding queue from promoting them
  final Set<String> _pausingKeys = {};

  // Keys whose completion callback is in-flight — prevents orphan scan from re-queuing them
  final Set<String> _completingKeys = {};

  // Prevents concurrent _processQueue calls
  bool _isProcessingQueue = false;
  bool _disposed = false;

  // Debounce timers for DB progress writes (keyed by globalKey).
  // UI progress streams are still real-time; only the DB write is debounced.
  final Map<String, Timer> _progressDebounceTimers = {};

  // App-level auto-retry timers for downloads that exhausted native retries.
  // Keyed by globalKey; each timer fires a fresh re-enqueue after a delay.
  final Map<String, Timer> _autoRetryTimers = {};

  // Circuit breaker: consecutive instant failures in _processQueue.
  // Stops the queue when all items fail with the same error (e.g. DNS).
  int _consecutiveQueueFailures = 0;
  static const _maxConsecutiveFailures = 3;

  static Future<bool> shouldBlockDownloadOnCellular() async {
    final List<ConnectivityResult> connectivity;
    try {
      connectivity = await Connectivity().checkConnectivity();
    } catch (e) {
      // connectivity_plus can throw PlatformException on Windows — don't block
      return false;
    }
    return shouldBlockDownloadOnCellularWith(connectivity);
  }

  /// Same check as [shouldBlockDownloadOnCellular] but uses a pre-read
  /// connectivity result so callers that already queried connectivity don't
  /// pay for a second platform round-trip.
  static Future<bool> shouldBlockDownloadOnCellularWith(List<ConnectivityResult> connectivity) async {
    final settings = await SettingsService.getInstance();
    if (!settings.read(SettingsService.downloadOnWifiOnly)) return false;
    if (connectivity.isEmpty) return false;
    return connectivity.contains(ConnectivityResult.mobile) &&
        !connectivity.contains(ConnectivityResult.wifi) &&
        !connectivity.contains(ConnectivityResult.ethernet);
  }

  /// Future that completes when interrupted download recovery finishes.
  /// Await this before reading download state from the DB to avoid races.
  late final Future<void> recoveryFuture;

  DownloadManagerService({
    required AppDatabase database,
    required DownloadStorageService storageService,
    MediaServerHttpClient? http,
  }) : _database = database,
       _storageService = storageService,
       _http = http ?? httpClient;

  void setClientResolver(MediaClientResolver resolver) {
    _clientResolver = resolver;
  }

  /// Inject the offline-mode source. When `isOffline`, queue/resume paths skip
  /// network work and defer until connectivity returns.
  void setOfflineSource(OfflineModeSource? source) {
    _offlineSource = source;
  }

  bool get _isOffline => _offlineSource?.isOffline ?? false;

  /// Look up the correct client for [serverId].
  /// Returns null if the server is offline — callers should skip/defer the work.
  MediaServerClient? _getClient(String? serverId, {String? clientScopeId}) {
    if (serverId != null && _clientResolver != null) {
      return _clientResolver!(serverId, clientScopeId: clientScopeId);
    }
    return _fallbackClient;
  }

  Future<MediaServerClient?> _getClientForDownloadKey(String globalKey) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return _getClient(null);
    final record = await _database.getDownloadedMedia(globalKey);
    return _getClient(parsed.serverId, clientScopeId: record?.clientScopeId);
  }

  String? activeClientScopeIdForServer(String serverId) {
    final client = _getClient(serverId);
    final scopeId = client?.cacheServerId;
    if (scopeId == null || scopeId == serverId || scopeId.isEmpty) return null;
    return scopeId;
  }

  /// Bulk-load every backend's pinned metadata into one map keyed by
  /// `buildGlobalKey(serverId, itemId)`. Plex and Jellyfin entries never
  /// collide because `serverId` is globally unique across backends.
  Future<Map<String, MediaItem>> getAllPinnedMetadata({bool preferActiveScope = false}) async {
    final results = await Future.wait(MediaBackend.values.map((b) => ApiCache.forBackend(b).getAllPinnedMetadata()));
    final merged = {for (final r in results) ...r};

    for (final item in await _database.getAllDownloadedMetadata()) {
      final client = _getClient(item.serverId, clientScopeId: item.clientScopeId);
      final backend = client?.backend ?? await _backendForServer(item.serverId);
      if (backend == null) continue;
      for (final scopeId in _metadataScopeCandidates(
        item.serverId,
        downloadedClientScopeId: item.clientScopeId,
        preferActiveScope: preferActiveScope,
      )) {
        final scoped = await ApiCache.forBackend(backend).getMetadata(scopeId, item.ratingKey);
        if (scoped != null) {
          merged[item.globalKey] = scoped;
          break;
        }
      }
    }

    return merged;
  }

  /// Public mirror of [_lookupMetadata] for callers that hydrate offline
  /// state outside the manager (e.g. [DownloadProvider]).
  Future<MediaItem?> lookupMetadata(String serverId, String itemId, {bool preferActiveScope = false}) async {
    final download = await _database.getDownloadedMedia(buildGlobalKey(serverId, itemId));
    for (final scopeId in _metadataScopeCandidates(
      serverId,
      downloadedClientScopeId: download?.clientScopeId,
      preferActiveScope: preferActiveScope,
    )) {
      final hit = await _lookupMetadata(serverId, itemId, clientScopeId: scopeId == serverId ? null : scopeId);
      if (hit != null) return hit;
    }
    return null;
  }

  List<String> _metadataScopeCandidates(
    String serverId, {
    String? downloadedClientScopeId,
    required bool preferActiveScope,
  }) {
    final candidates = <String>[
      if (preferActiveScope) ?activeClientScopeIdForServer(serverId),
      ?downloadedClientScopeId,
      ?_getClient(serverId, clientScopeId: downloadedClientScopeId)?.cacheServerId,
      serverId,
    ];
    return <String>{
      for (final id in candidates)
        if (id.isNotEmpty) id,
    }.toList(growable: false);
  }

  /// Force-resolve metadata for [itemId] by hitting the live server when the
  /// per-backend cache lookup misses. Pins the resulting cache row so the
  /// next cold start finds it. Returns null when no online client is
  /// available or the fetch itself fails.
  ///
  /// Used as a fallback by [DownloadProvider.refreshMetadataFromCache] to
  /// recover from cache rows that were never written or got lost (cleared
  /// data, schema reset, etc.) — without it, downloaded items render with
  /// no title and sync rules show their rating key instead of the show
  /// name.
  Future<MediaItem?> fetchAndPinMetadata(String serverId, String itemId, {bool preferActiveScope = false}) async {
    final download = await _database.getDownloadedMedia(buildGlobalKey(serverId, itemId));
    final clientScopeId = preferActiveScope
        ? activeClientScopeIdForServer(serverId) ?? download?.clientScopeId
        : download?.clientScopeId;
    final client = _getClient(serverId, clientScopeId: clientScopeId);
    if (client == null) return null;
    try {
      final metadata = await client.fetchItem(itemId);
      if (metadata == null) return null;
      await ApiCache.forBackend(client.backend).pinForOffline(client.cacheServerId, itemId);
      return metadata;
    } catch (e) {
      appLogger.d('fetchAndPinMetadata failed for $serverId:$itemId', error: e);
      return null;
    }
  }

  /// Resolve which backend the cache row for [serverId] uses. Reads the
  /// `Connections` table directly so the lookup works even when the server
  /// is currently offline (the connection persists across launches).
  ///
  /// Jellyfin's connection row is keyed by `${serverMachineId}/$userId`
  /// while clients/cache rows use the bare machineId — match by prefix so
  /// the lookup resolves either form. Uses [substr]-based prefix matching
  /// (mirrors [JellyfinApiCache._serverContext]) so any `_` / `%` chars in
  /// [serverId] are treated literally; `LIKE '$serverId/%'` would interpret
  /// them as wildcards.
  Future<MediaBackend?> _backendForServer(String serverId) async {
    // Prefer a live client — `MediaServerClient.backend` is in memory.
    final live = _getClient(serverId);
    if (live != null) return live.backend;
    final prefix = '$serverId/';
    final row =
        await (_database.select(_database.connections)
              ..where((t) => t.id.equals(serverId) | t.id.substr(1, prefix.length).equals(prefix))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return switch (row.kind) {
      'jellyfin' => MediaBackend.jellyfin,
      'plex' => MediaBackend.plex,
      _ => null,
    };
  }

  /// Backend-aware metadata lookup. Dispatches to the right `getMetadata`
  /// helper so callers don't have to thread backend identity through every
  /// layer.
  ///
  /// When [_backendForServer] can't resolve the backend (no live client and
  /// no `connections` row — happens when a server has been removed but old
  /// download rows still reference it), fan out to every registered backend
  /// cache instead of silently defaulting to Plex. Otherwise Jellyfin items
  /// would render with blank metadata after a connection is severed.
  Future<MediaItem?> _lookupMetadata(String serverId, String itemId, {String? clientScopeId}) async {
    final backend = await _backendForServer(serverId);
    final live = _getClient(serverId, clientScopeId: clientScopeId);
    if (backend != null) {
      return ApiCache.forBackend(backend).getMetadata(clientScopeId ?? live?.cacheServerId ?? serverId, itemId);
    }
    appLogger.w('Cache lookup for $serverId:$itemId — backend unresolved; trying all registered backends');
    for (final candidate in MediaBackend.values) {
      if (clientScopeId != null && clientScopeId.isNotEmpty) {
        final scopedHit = await ApiCache.forBackend(candidate).getMetadata(clientScopeId, itemId);
        if (scopedHit != null) return scopedHit;
      }
      final hit = await ApiCache.forBackend(candidate).getMetadata(serverId, itemId);
      if (hit != null) return hit;
    }
    return null;
  }

  /// Backend-aware "ensure cached & pin". Jellyfin loads playback extras so
  /// both item metadata and native media segments are available offline; other
  /// backends only need the item metadata row. Then pin cached rows so they
  /// survive general cache eviction.
  Future<void> _pinMetadataForOffline(MediaServerClient client, MediaItem metadata) async {
    final serverId = metadata.serverId;
    if (serverId == null) {
      appLogger.w('Cannot pin metadata without serverId');
      return;
    }
    if (client.backend == MediaBackend.jellyfin) {
      try {
        await client.fetchPlaybackExtras(metadata.id);
      } catch (e) {
        appLogger.w('fetchPlaybackExtras failed during offline-pin for ${metadata.globalKey}', error: e);
      }
    } else {
      try {
        await client.fetchItem(metadata.id);
      } catch (e) {
        appLogger.w('fetchItem failed during offline-pin for ${metadata.globalKey}', error: e);
      }
    }
    await ApiCache.forBackend(client.backend).pinForOffline(client.cacheServerId, metadata.id);
  }

  Future<void> _deleteForItemByServer(String serverId, String itemId, {String? clientScopeId}) async {
    final backend = await _backendForServer(serverId);
    final live = _getClient(serverId, clientScopeId: clientScopeId);
    if (backend != null) {
      await ApiCache.forBackend(backend).deleteForItem(clientScopeId ?? live?.cacheServerId ?? serverId, itemId);
      return;
    }
    // Backend unresolved — purge from every registered backend so a stale
    // row from either side doesn't outlive the deletion. Idempotent;
    // missing rows are no-ops.
    appLogger.w('Cache delete for $serverId:$itemId — backend unresolved; clearing all registered backends');
    for (final candidate in MediaBackend.values) {
      if (clientScopeId != null && clientScopeId.isNotEmpty) {
        await ApiCache.forBackend(candidate).deleteForItem(clientScopeId, itemId);
      }
      await ApiCache.forBackend(candidate).deleteForItem(serverId, itemId);
    }
  }

  /// Initialize background_downloader with callbacks, notifications, and concurrency config.
  Future<void> _initializeFileDownloader() async {
    if (_fileDownloaderInitialized) return;

    FileDownloader()
        .registerCallbacks(
          group: _downloadGroup,
          taskStatusCallback: _onTaskStatusChanged,
          taskProgressCallback: _onTaskProgress,
        )
        .configureNotificationForGroup(
          _downloadGroup,
          running: const TaskNotification('{displayName}', 'Downloading...'),
          complete: const TaskNotification('{displayName}', 'Download complete'),
          error: const TaskNotification('{displayName}', 'Download failed'),
          paused: const TaskNotification('{displayName}', 'Download paused'),
          progressBar: true,
        );

    // Plex servers can reject concurrent media downloads.
    await FileDownloader().configure(globalConfig: (Config.holdingQueue, (1, 1, 1)));

    await FileDownloader().trackTasks();
    // Deliver status updates from iOS background-to-foreground transitions
    await FileDownloader().resumeFromBackground();

    _fileDownloaderInitialized = true;
  }

  /// Recover downloads that were interrupted when the app was killed.
  /// Uses background_downloader's rescheduleKilledTasks for native recovery,
  /// then scans drift for orphaned items.
  Future<void> recoverInterruptedDownloads() async {
    try {
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Initializing FileDownloader', category: 'downloads')));
      await _initializeFileDownloader();

      // Let background_downloader re-enqueue tasks killed by the OS
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Rescheduling killed tasks', category: 'downloads')));
      final (rescheduled, _) = await FileDownloader().rescheduleKilledTasks();
      if (rescheduled.isNotEmpty) {
        appLogger.i('Rescheduled ${rescheduled.length} killed download task(s)');
      }

      // One-time migration: normalize stored file paths that may contain a
      // doubled base-dir prefix from an earlier bug in the recovery callback.
      // Re-run on v2 to also fix paths without a leading / that the v1 migration missed.
      final prefs = (await SettingsService.getInstance()).prefs;
      if ((prefs.getInt('download_paths_normalized_version') ?? 0) < 2) {
        final allItems = await _database.select(_database.downloadedMedia).get();
        var fixed = 0;
        for (final item in allItems) {
          if (item.videoFilePath != null) {
            final vfp = item.videoFilePath!;
            var normalized = await _storageService.toRelativePath(vfp);
            // If toRelativePath didn't help, try extracting from downloads/ onward
            // for paths that lack a leading / but contain nested base-dir fragments
            if (normalized == vfp) {
              final idx = vfp.indexOf('downloads/');
              if (idx > 0) normalized = vfp.substring(idx);
            }
            appLogger.d('Path migration: videoFilePath="$vfp", normalized="$normalized"');
            if (normalized != vfp) {
              await _database.updateVideoFilePath(item.globalKey, normalized);
              fixed++;
            }
          }
          if (item.thumbPath != null) {
            final tp = item.thumbPath!;
            var normalized = await _storageService.toRelativePath(tp);
            if (normalized == tp) {
              final idx = tp.indexOf('downloads/');
              if (idx > 0) normalized = tp.substring(idx);
            }
            if (normalized != tp) {
              await _database.updateArtworkPaths(globalKey: item.globalKey, thumbPath: normalized);
            }
          }
        }
        if (fixed > 0) appLogger.i('Normalized $fixed corrupted download path(s)');
        await prefs.setInt('download_paths_normalized_version', 2);
      }

      // Scan drift for orphaned items stuck in 'downloading'
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Scanning for orphaned downloads', category: 'downloads')));
      final allDownloads = await _database.select(_database.downloadedMedia).get();
      for (final item in allDownloads) {
        if (item.status == DownloadStatus.downloading.index) {
          // Skip items whose completion callback is already in-flight (race with trackTasks)
          if (_completingKeys.contains(item.globalKey)) {
            appLogger.d('Skipping orphan check for ${item.globalKey}: completion in progress');
            continue;
          }

          // Video already downloaded but post-processing didn't complete
          if (item.videoFilePath != null) {
            appLogger.i('Download ${item.globalKey} has video but incomplete post-processing, completing');
            await _database.updateDownloadStatus(item.globalKey, DownloadStatus.completed.index);
            await _database.removeFromQueue(item.globalKey);
            _emitProgress(item.globalKey, DownloadStatus.completed, 100);
            _pendingSupplementaryDownloads.add(item.globalKey);
            continue;
          }

          // Check if background_downloader still has this task
          Task? bgTask;
          if (item.bgTaskId != null) {
            bgTask = await FileDownloader().taskForId(item.bgTaskId!);
          }

          if (bgTask == null) {
            // No active bg task — orphan, re-queue it
            appLogger.i('Re-queuing orphaned download: ${item.globalKey}');
            await _database.updateDownloadStatus(item.globalKey, DownloadStatus.queued.index);
            await _database.updateBgTaskId(item.globalKey, null);
            await _database.addToQueue(mediaGlobalKey: item.globalKey);
          }
          // If bgTask exists, background_downloader is still handling it
        }
      }
    } catch (e) {
      appLogger.e('Failed to recover interrupted downloads', error: e);
    }
  }

  /// Resume queued downloads that have no active processing.
  /// Call after a [MediaServerClient] becomes available (e.g. after server connect on launch).
  void resumeQueuedDownloads(MediaServerClient client) {
    _fallbackClient = client;

    if (_isOffline) {
      appLogger.d('Skipping resumeQueuedDownloads — offline');
      return;
    }

    // Attempt deferred supplementary downloads for recovered items
    _processPendingSupplementaryDownloads(client);

    unawaited(
      _database
          .getNextQueueItem()
          .then((item) {
            if (item != null) {
              appLogger.i('Resuming queued downloads after app restart');
              _processQueue(client);
            }
          })
          .catchError((e, st) {
            appLogger.e('Failed to resume queued downloads', error: e, stackTrace: st);
          }),
    );
  }

  /// Attempt supplementary downloads (artwork, subtitles) for items that were
  /// recovered with a completed video but missed post-processing.
  Future<void> _processPendingSupplementaryDownloads(MediaServerClient client) async {
    if (_pendingSupplementaryDownloads.isEmpty) return;

    final keys = Set<String>.from(_pendingSupplementaryDownloads);
    _pendingSupplementaryDownloads.clear();

    for (final globalKey in keys) {
      try {
        // Resolve the correct client for this item's server/scope.
        final parsed = parseGlobalKey(globalKey);
        final record = await _database.getDownloadedMedia(globalKey);
        final itemClient = await _getClientForDownloadKey(globalKey);
        if (itemClient == null) {
          appLogger.d('Deferring supplementary download $globalKey: server offline');
          _pendingSupplementaryDownloads.add(globalKey);
          continue;
        }

        final metadata = await _resolveMetadata(globalKey);
        if (metadata == null) {
          appLogger.w('No metadata for deferred supplementary download: $globalKey');
          continue;
        }

        // Look up show year for episodes
        int? showYear;
        if (metadata.isEpisode && metadata.grandparentId != null) {
          if (parsed != null) {
            showYear = await _fetchShowYear(
              parsed.serverId,
              metadata.grandparentId,
              clientScopeId: record?.clientScopeId,
            );
          }
        }

        await _downloadArtwork(globalKey, metadata, itemClient);
        await _downloadChapterThumbnails(metadata.serverId!, metadata.id, itemClient);

        // Attempt subtitles
        try {
          final resolution = await itemClient.resolveDownload(metadata);
          if (resolution.externalSubtitles.isNotEmpty) {
            await _downloadSubtitles(globalKey, metadata, resolution.externalSubtitles, itemClient, showYear: showYear);
          }
        } catch (e) {
          appLogger.w('Could not resolve subtitles for deferred download: $globalKey', error: e);
        }

        appLogger.i('Deferred supplementary downloads completed for $globalKey');
      } catch (e) {
        appLogger.w('Deferred supplementary downloads failed for $globalKey', error: e);
      }
    }
  }

  /// Cancel any per-download timers (progress debounce + auto-retry) for [key].
  /// Idempotent; safe to call from any terminal/pause path.
  void _cancelDownloadTimers(String key) {
    _progressDebounceTimers.remove(key)?.cancel();
    _autoRetryTimers.remove(key)?.cancel();
  }

  /// Delete a file if it exists and log the deletion
  /// Returns true if file was deleted, false otherwise
  Future<bool> _deleteFileIfExists(File file, String description) async {
    try {
      if (await file.exists()) {
        await file.delete();
        appLogger.i('Deleted $description: ${file.path}');
        return true;
      }
    } catch (e) {
      appLogger.w('Failed to delete $description: ${file.path}', error: e);
    }
    return false;
  }

  /// Delete a SAF file or directory. Missing targets are a silent no-op.
  Future<void> _tryDeleteSaf(String uri, {required bool isDir, required String description}) async {
    final ok = await SafStorageService.instance.delete(uri, isDir: isDir);
    if (ok) appLogger.i('Deleted $description: $uri');
  }

  /// Recursively delete a SAF directory — lists children in parallel, deletes
  /// leaves, recurses into subdirectories, then removes the dir itself.
  /// Manual recursion because DocumentsProvider-level recursion isn't guaranteed
  /// across providers.
  Future<void> _deleteSafDirRecursive(String dirUri, {required String description}) async {
    final saf = SafStorageService.instance;
    final children = await saf.list(dirUri);
    if (children != null && children.isNotEmpty) {
      await Future.wait(
        children.map((child) {
          return child.isDir
              ? _deleteSafDirRecursive(child.uri, description: description)
              : saf.delete(child.uri, isDir: false);
        }),
      );
    }
    await _tryDeleteSaf(dirUri, isDir: true, description: description);
  }

  /// Walk a chain of SAF directory URIs (deepest-first) and delete each that is empty.
  /// Stops at the first non-empty directory. Skips missing/null entries.
  Future<void> _deleteEmptySafDirsInOrder(List<String?> dirUris) async {
    final saf = SafStorageService.instance;
    for (final uri in dirUris) {
      if (uri == null) break;
      if (!await saf.exists(uri, isDir: true)) continue;
      final children = await saf.list(uri);
      if (children == null || children.isNotEmpty) break;
      if (!await saf.delete(uri, isDir: true)) break;
      appLogger.i('Cleaned up empty SAF directory: $uri');
    }
  }

  /// Find a SAF file in [dirUri] whose name (minus extension) matches [baseName].
  Future<SafDocumentFile?> _findSafFileByBaseName(String dirUri, String baseName) async {
    final children = await SafStorageService.instance.list(dirUri);
    if (children == null) return null;
    for (final child in children) {
      if (!child.isDir && path.basenameWithoutExtension(child.name) == baseName) return child;
    }
    return null;
  }

  /// Delete the canonical target file and any pre-existing numbered duplicates
  /// in [safDirUri] before re-enqueueing a SAF download. SAF DocumentsProviders
  /// auto-number on createDocument when a name conflict exists, which would
  /// otherwise produce "name (1).ext" / "name.ext (1)" corrupt duplicates on
  /// every app-level retry.
  Future<void> _cleanupSafTargetFile(String safDirUri, String safFileName) async {
    final children = await SafStorageService.instance.list(safDirUri);
    if (children == null) return;

    // Match BOTH numbering schemes a DocumentsProvider may use:
    //   "S02E11 - The Hunt (1).mkv"  - inserted before extension (most providers)
    //   "S02E11 - The Hunt.mkv (1)"  - appended after full name (Downloads tree)
    final base = path.basenameWithoutExtension(safFileName);
    final ext = path.extension(safFileName);
    final dup = RegExp(
      '^${RegExp.escape(base)} \\(\\d+\\)${RegExp.escape(ext)}\$|'
      '^${RegExp.escape(safFileName)} \\(\\d+\\)\$',
    );

    await Future.wait([
      for (final child in children)
        if (!child.isDir && (child.name == safFileName || dup.hasMatch(child.name)))
          _tryDeleteSaf(
            child.uri,
            isDir: false,
            description: child.name == safFileName
                ? 'stale SAF video before re-download'
                : 'stale SAF numbered duplicate',
          ),
    ]);
  }

  Future<void> queueDownload({
    required MediaItem metadata,
    required MediaServerClient client,
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
    int mediaIndex = 0,
  }) async {
    final globalKey = metadata.globalKey;

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing != null &&
        (existing.status == DownloadStatus.downloading.index || existing.status == DownloadStatus.completed.index)) {
      appLogger.i('Download already exists for $globalKey with status ${existing.status}');
      return;
    }

    await _database.insertDownload(
      serverId: metadata.serverId!,
      clientScopeId: client.cacheServerId == metadata.serverId ? null : client.cacheServerId,
      ratingKey: metadata.id,
      globalKey: globalKey,
      type: metadata.kind.id,
      parentRatingKey: metadata.parentId,
      grandparentRatingKey: metadata.grandparentId,
      status: DownloadStatus.queued.index,
      mediaIndex: mediaIndex,
    );

    // Populate the offline cache via the read path and pin so the row
    // survives general eviction. Idempotent — fetchItem is a no-op when the
    // cache is warm and falls back to the existing entry on network error.
    await _pinMetadataForOffline(client, metadata);

    await _database.addToQueue(
      mediaGlobalKey: globalKey,
      priority: priority,
      downloadSubtitles: downloadSubtitles,
      downloadArtwork: downloadArtwork,
    );

    _emitProgress(globalKey, DownloadStatus.queued, 0);

    unawaited(_processQueue(client));
  }

  /// Process the download queue — prepares and enqueues items with background_downloader.
  /// Non-blocking: returns after all queued items are enqueued (downloads run natively).
  Future<void> _processQueue(MediaServerClient client) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    _fallbackClient = client;

    try {
      await _initializeFileDownloader();

      while (true) {
        if (_consecutiveQueueFailures >= _maxConsecutiveFailures) {
          appLogger.w('Circuit breaker: $_consecutiveQueueFailures consecutive failures, pausing queue');
          break;
        }

        final nextItem = await _database.getNextQueueItem();
        if (nextItem == null) break;

        // Resolve the correct client for the item's server/scope — skip if unavailable.
        final itemClient = await _getClientForDownloadKey(nextItem.mediaGlobalKey);
        if (itemClient == null) {
          appLogger.d('Skipping queued download ${nextItem.mediaGlobalKey}: server offline');
          break;
        }
        final enqueued = await _prepareAndEnqueueDownload(nextItem.mediaGlobalKey, itemClient, nextItem);
        if (enqueued) {
          _consecutiveQueueFailures = 0;
        } else {
          _consecutiveQueueFailures++;
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Cancel any lingering background task and reset progress before re-enqueuing.
  Future<void> _cleanupStaleDownload(String globalKey) async {
    final existingTaskId = await _database.getBgTaskId(globalKey);
    if (existingTaskId != null) {
      await FileDownloader().cancelTaskWithId(existingTaskId);
      await _database.updateBgTaskId(globalKey, null);
      appLogger.d('Cancelled stale bg task $existingTaskId for $globalKey');
    }
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
  }

  /// Resolve metadata, video URL, and file path, then enqueue a background download task.
  /// Returns true if successfully enqueued, false if it failed immediately.
  Future<bool> _prepareAndEnqueueDownload(
    String globalKey,
    MediaServerClient client,
    DownloadQueueItem queueItem,
  ) async {
    try {
      // Guard: don't re-enqueue an item that's already completed or was deleted
      final existing = await _database.getDownloadedMedia(globalKey);
      if (existing == null || existing.status == DownloadStatus.completed.index) {
        appLogger.d('Skipping enqueue for $globalKey: already completed or deleted');
        await _database.removeFromQueue(globalKey);
        return true;
      }

      appLogger.i('Preparing download for $globalKey');
      if (existing.bgTaskId != null) await _cleanupStaleDownload(globalKey);
      await _transitionStatus(globalKey, DownloadStatus.downloading);

      final parsed = parseGlobalKey(globalKey);
      if (parsed == null) throw Exception('Invalid globalKey: $globalKey');
      final serverId = parsed.serverId;
      final ratingKey = parsed.ratingKey;

      MediaItem? metadata = await _lookupMetadata(serverId, ratingKey, clientScopeId: existing.clientScopeId);
      if (metadata == null) {
        // Cache miss — try re-fetching from server (cache may have been cleared between queue and prepare)
        appLogger.w('Cache miss for $globalKey, attempting network re-fetch');
        try {
          final fetched = await client.fetchItem(ratingKey);
          if (fetched != null) metadata = fetched.copyWith(serverId: serverId);
        } catch (e) {
          appLogger.w('Network re-fetch failed for $globalKey', error: e);
        }
        if (metadata == null) {
          throw Exception('Metadata not found in cache and could not be fetched for $globalKey');
        }
      }

      final selectedMediaIndex = existing.mediaIndex;
      var resolution = await client.resolveDownload(metadata, mediaIndex: selectedMediaIndex);
      if (resolution.videoUrl == null) {
        // Cache miss for the per-version fields — refresh from network.
        appLogger.w('No video URL from cache for $globalKey, retrying via network');
        final fetched = await client.fetchItem(ratingKey);
        if (fetched != null) metadata = fetched.copyWith(serverId: serverId);
        resolution = await client.resolveDownload(metadata, mediaIndex: selectedMediaIndex);
        if (resolution.videoUrl == null) throw Exception('Could not get video URL for $globalKey');
      }

      final ext = downloadExtensionFromUrl(resolution.videoUrl!) ?? 'mp4';

      // Look up show year for episodes
      final showYear = metadata.isEpisode
          ? await _fetchShowYear(serverId, metadata.grandparentId, clientScopeId: existing.clientScopeId)
          : null;

      // Build display name for notifications
      final displayName = metadata.isEpisode
          ? '${metadata.grandparentTitle ?? metadata.displayTitle} - ${metadata.displayTitle}'
          : metadata.displayTitle;

      // Get WiFi-only setting for native enforcement
      final settings = await SettingsService.getInstance();
      final requiresWiFi = settings.read(SettingsService.downloadOnWifiOnly);

      if (_storageService.isUsingSaf) {
        // SAF mode: use UriDownloadTask (writes directly to content:// URI, no pause/resume)
        final List<String> pathComponents;
        final String safFileName;
        if (metadata.isMovie) {
          pathComponents = _storageService.getMovieSafPathComponents(metadata);
          safFileName = _storageService.getMovieSafFileName(metadata, ext);
        } else if (metadata.isEpisode) {
          pathComponents = _storageService.getEpisodeSafPathComponents(metadata, showYear: showYear);
          safFileName = _storageService.getEpisodeSafFileName(metadata, ext);
        } else {
          pathComponents = [serverId, metadata.id];
          safFileName = 'video.$ext';
        }

        final safDirUri = await SafStorageService.instance.createNestedDirectories(
          _storageService.safBaseUri!,
          pathComponents,
        );
        if (safDirUri == null) throw Exception('Failed to create SAF directory');

        await _cleanupSafTargetFile(safDirUri, safFileName);

        final task = UriDownloadTask(
          url: resolution.videoUrl!,
          filename: safFileName,
          directoryUri: Uri.parse(safDirUri),
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: _nativeRetries,
          allowPause: true,
          metaData: globalKey,
          displayName: displayName,
        );

        _pendingDownloadContext[globalKey] = _DownloadContext(
          metadata: metadata,
          queueItem: queueItem,
          filePath: safDirUri,
          extension: ext,
          client: client,
          showYear: showYear,
          isSafMode: true,
          subtitles: resolution.externalSubtitles,
        );

        await _database.updateBgTaskId(globalKey, task.taskId);
        final success = await FileDownloader().enqueue(task);
        if (!success) throw Exception('Failed to enqueue SAF download task');
        appLogger.i('Enqueued SAF download task ${task.taskId} for $globalKey');
      } else {
        // Normal mode: use DownloadTask with pause/resume support
        String downloadFilePath;
        if (metadata.isMovie) {
          downloadFilePath = await _storageService.getMovieVideoPath(metadata, ext);
        } else if (metadata.isEpisode) {
          downloadFilePath = await _storageService.getEpisodeVideoPath(metadata, ext, showYear: showYear);
        } else {
          downloadFilePath = await _storageService.getVideoFilePath(serverId, metadata.id, ext);
        }

        // Clean up partial files from previous attempts to prevent
        // background_downloader from creating numbered copies (File (1).mp4)
        await Future.wait([
          _deleteFileIfExists(File(downloadFilePath), 'stale video before re-download'),
          _deleteFileIfExists(File('$downloadFilePath.part'), 'stale .part before re-download'),
        ]);

        await File(downloadFilePath).parent.create(recursive: true);

        final task = DownloadTask(
          url: resolution.videoUrl!,
          filename: path.basename(downloadFilePath),
          directory: path.dirname(downloadFilePath),
          baseDirectory: BaseDirectory.root,
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: _nativeRetries,
          allowPause: true,
          metaData: globalKey,
          displayName: displayName,
        );

        _pendingDownloadContext[globalKey] = _DownloadContext(
          metadata: metadata,
          queueItem: queueItem,
          filePath: downloadFilePath,
          extension: ext,
          client: client,
          showYear: showYear,
          subtitles: resolution.externalSubtitles,
        );

        await _database.updateBgTaskId(globalKey, task.taskId);
        final success = await FileDownloader().enqueue(task);
        if (!success) throw Exception('Failed to enqueue download task');
        appLogger.i('Enqueued download task ${task.taskId} for $globalKey');
      }
      return true;
    } catch (e) {
      appLogger.e('Failed to prepare download for $globalKey', error: e);
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: e.toString());
      await _database.removeFromQueue(globalKey);
      _pendingDownloadContext.remove(globalKey);
      return false;
    }
  }

  /// Callback: background_downloader progress update
  void _onTaskProgress(TaskProgressUpdate update) {
    if (_disposed) return;
    final globalKey = update.task.metaData;
    if (globalKey.isEmpty || update.progress < 0) return;

    // If this item is being paused, the holding queue promoted it — cancel it
    if (_pausingKeys.contains(globalKey)) {
      FileDownloader().cancelTaskWithId(update.task.taskId);
      return;
    }

    final progress = (update.progress * 100).round().clamp(0, 100);
    final speedBytesPerSec = update.hasNetworkSpeed ? update.networkSpeed * 1024 * 1024 : 0.0;
    final totalBytes = update.hasExpectedFileSize ? update.expectedFileSize : 0;
    final downloadedBytes = totalBytes > 0 ? (update.progress * totalBytes).round() : 0;

    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: DownloadStatus.downloading,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        speed: speedBytesPerSec,
        currentFile: 'video',
      ),
    );

    // Debounce DB writes — only the latest progress value is persisted after
    // a 2-second settle period. The stream above provides real-time UI updates;
    // the DB write is only for crash-recovery state.
    _progressDebounceTimers[globalKey]?.cancel();
    _progressDebounceTimers[globalKey] = Timer(_progressDebounceDelay, () {
      _progressDebounceTimers.remove(globalKey);
      _database.updateDownloadProgress(globalKey, progress, downloadedBytes, totalBytes).catchError((e) {
        appLogger.w('Failed to update download progress in DB', error: e);
      });
    });
  }

  /// Callback: background_downloader status change
  void _onTaskStatusChanged(TaskStatusUpdate update) {
    if (_disposed) return;
    final globalKey = update.task.metaData;
    if (globalKey.isEmpty) return;

    appLogger.d('Background task status: ${update.status} for $globalKey');

    try {
      switch (update.status) {
        case TaskStatus.complete:
          _onDownloadComplete(globalKey, update.task);
        case TaskStatus.failed:
          _onDownloadFailed(globalKey, update.exception?.description ?? 'Download failed');
        case TaskStatus.notFound:
          _onDownloadPermanentlyFailed(globalKey, 'File not found (404)');
        case TaskStatus.canceled:
          if (_pausingKeys.contains(globalKey)) break;
          _onDownloadCanceled(globalKey);
        case TaskStatus.paused:
          appLogger.d('Download paused by system for $globalKey');
        case TaskStatus.waitingToRetry:
          appLogger.d('Download waiting to retry for $globalKey');
        case TaskStatus.enqueued:
        case TaskStatus.running:
          // If this item is being paused, the holding queue promoted it — cancel it
          if (_pausingKeys.contains(globalKey)) {
            FileDownloader().cancelTaskWithId(update.task.taskId);
          }
          break;
      }
    } catch (e) {
      appLogger.e('Error handling download status change for $globalKey', error: e);
    }
  }

  /// Handle a system-initiated cancel — re-queue unless already completed.
  Future<void> _onDownloadCanceled(String globalKey) async {
    _cancelDownloadTimers(globalKey);
    final ctx = _pendingDownloadContext.remove(globalKey);
    if (ctx == null) return;
    if (_completingKeys.contains(globalKey)) return;

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) return;

    appLogger.w('Download cancelled by system for $globalKey, re-queuing');
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final client = await _getClientForDownloadKey(globalKey);
    if (client != null) unawaited(_processQueue(client));
  }

  /// Handle a failed download — auto-retry if retries remain, otherwise permanently fail.
  /// Native retries (Range-based resume) are already exhausted at this point.
  Future<void> _onDownloadFailed(String globalKey, String errorMessage) async {
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Ignoring failure event for $globalKey: completion in progress');
      return;
    }
    _cancelDownloadTimers(globalKey);
    _pendingDownloadContext.remove(globalKey);

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) {
      appLogger.d('Ignoring stale failure for completed download $globalKey');
      return;
    }
    final retryCount = existing?.retryCount ?? 0;

    // DNS/connection errors fail instantly and exhaust native retries in milliseconds,
    // creating a retry storm. Treat them as permanent failures.
    final isNetworkError =
        errorMessage.contains('Unable to resolve host') ||
        errorMessage.contains('No address associated with hostname') ||
        errorMessage.contains('Network is unreachable') ||
        errorMessage.contains('Connection refused');
    final isServerError = errorMessage.contains('500 Internal Server Error');

    final client = await _getClientForDownloadKey(globalKey);
    final hadProgress = (existing?.downloadedBytes ?? 0) > 0;

    if (!isNetworkError && !isServerError && retryCount < _maxAppRetries && client != null) {
      // App-level auto-retry: schedule a fresh download after a delay.
      // Each new task gets 5 native retries with Range-based resume.
      appLogger.w(
        'Download failed for $globalKey (attempt ${retryCount + 1}/$_maxAppRetries), '
        'scheduling auto-retry in ${_autoRetryDelay.inSeconds}s: $errorMessage',
      );
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: errorMessage);
      await _database.removeFromQueue(globalKey);
      _autoRetryTimers[globalKey] = Timer(_autoRetryDelay, () {
        _autoRetryTimers.remove(globalKey);
        _performAutoRetry(globalKey);
      });

      // Only advance the queue if the download actually started transferring.
      // Instant failures (DNS, connection) would just cause the next item to fail too.
      if (hadProgress) unawaited(_processQueue(client));
    } else {
      if (isNetworkError) {
        appLogger.w('Network error for $globalKey, failing permanently (no auto-retry): $errorMessage');
      }
      final userMessage = isServerError ? t.downloads.serverErrorBitrate : errorMessage;
      await _onDownloadPermanentlyFailed(globalKey, userMessage);
    }
  }

  /// Handle a non-retryable failure (e.g. 404) — fail immediately without auto-retry.
  Future<void> _onDownloadPermanentlyFailed(String globalKey, String errorMessage) async {
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Ignoring permanent failure event for $globalKey: completion in progress');
      return;
    }
    _cancelDownloadTimers(globalKey);
    _pendingDownloadContext.remove(globalKey);

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) {
      appLogger.d('Ignoring stale permanent failure for completed download $globalKey');
      return;
    }

    appLogger.e('Download permanently failed for $globalKey: $errorMessage');
    await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: errorMessage);
    await _database.removeFromQueue(globalKey);

    // Try to enqueue more items from the queue
    final client = await _getClientForDownloadKey(globalKey);
    if (client != null) unawaited(_processQueue(client));
  }

  /// Execute an app-level auto-retry: transition back to queued and re-enqueue.
  Future<void> _performAutoRetry(String globalKey) async {
    if (_disposed) return;
    final client = await _getClientForDownloadKey(globalKey);
    if (client == null) {
      appLogger.w('Cannot auto-retry $globalKey: no client available');
      return;
    }

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing == null || existing.status != DownloadStatus.failed.index) {
      // Download was cancelled/deleted/retried by user during the delay
      return;
    }

    appLogger.i('Auto-retrying download for $globalKey');
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    unawaited(_processQueue(client));
  }

  /// Handle a completed video download — store path, download supplementary content, mark done.
  Future<void> _onDownloadComplete(String globalKey, Task task) async {
    _consecutiveQueueFailures = 0;
    // Prevent duplicate concurrent completions (e.g. trackTasks replaying events)
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Already processing completion for $globalKey, skipping');
      return;
    }
    _completingKeys.add(globalKey);
    try {
      // Flush any pending debounced progress write + cancel any scheduled retry
      _cancelDownloadTimers(globalKey);

      // Fresh DB check — bail if already completed (guards against race with orphan scan)
      final existingCheck = await _database.getDownloadedMedia(globalKey);
      if (existingCheck?.status == DownloadStatus.completed.index) {
        appLogger.d('Download already completed for $globalKey, skipping');
        return;
      }

      final ctx = _pendingDownloadContext.remove(globalKey);

      // ── Phase 1 (critical): resolve and store the video file path ──
      final String storedPath;
      if (ctx != null) {
        // Happy path: context available from this session
        if (ctx.isSafMode) {
          // UriDownloadTask wrote directly to SAF — find the file URI
          final child = await SafStorageService.instance.getChild(ctx.filePath, [task.filename]);
          if (child != null) {
            storedPath = child.uri;
          } else {
            storedPath = await _resolveSafStoredPath(ctx.metadata, ctx.extension, ctx.showYear) ?? '';
            if (storedPath.isEmpty) throw Exception('Cannot determine SAF file URI');
          }
        } else {
          storedPath = await _storageService.toRelativePath(ctx.filePath);
        }
      } else {
        // Recovery path: context missing (app was restarted)
        final existing = await _database.getDownloadedMedia(globalKey);
        if (existing?.videoFilePath != null && existing?.status == DownloadStatus.completed.index) {
          appLogger.d('Download already completed for $globalKey');
          return;
        }
        if (existing?.videoFilePath != null) {
          // Video path set but status not completed — just finish up
          storedPath = existing!.videoFilePath!;
        } else if (task is UriDownloadTask) {
          // SAF mode recovery: re-derive path from metadata
          final parsed = parseGlobalKey(globalKey);
          if (parsed == null) throw Exception('Invalid globalKey for recovery: $globalKey');
          final metadata = await _lookupMetadata(
            parsed.serverId,
            parsed.ratingKey,
            clientScopeId: existing?.clientScopeId,
          );
          if (metadata == null) throw Exception('No metadata for SAF recovery of $globalKey');
          final ext = downloadExtensionFromUrl(task.url) ?? 'mp4';
          storedPath =
              await _resolveSafStoredPathForRecovery(metadata, ext, clientScopeId: existing?.clientScopeId) ?? '';
          if (storedPath.isEmpty) throw Exception('Cannot resolve SAF path on recovery');
        } else {
          // Normal mode recovery: reconstruct from task
          storedPath = await _storageService.toRelativePath('${task.directory}/${task.filename}');
        }
      }

      await _database.updateVideoFilePath(globalKey, storedPath);
      appLogger.d('Video download completed for $globalKey');

      // ── Phase 2 (best-effort): supplementary downloads ──
      try {
        final metadata = ctx?.metadata ?? await _resolveMetadata(globalKey);
        final client = ctx?.client ?? await _getClientForDownloadKey(globalKey);
        final showYear = ctx?.showYear;

        final queueItem =
            ctx?.queueItem ??
            await (_database.select(
              _database.downloadQueue,
            )..where((t) => t.mediaGlobalKey.equals(globalKey))).getSingleOrNull();
        final downloadArtwork = queueItem?.downloadArtwork ?? true;
        final downloadSubtitles = queueItem?.downloadSubtitles ?? true;

        if (metadata != null && client != null) {
          if (downloadArtwork) {
            await _downloadArtwork(globalKey, metadata, client);
            await _downloadChapterThumbnails(metadata.serverId!, metadata.id, client);
          }
          if (downloadSubtitles) {
            var subtitles = ctx?.subtitles;
            if (subtitles == null) {
              try {
                final resolution = await client.resolveDownload(metadata);
                subtitles = resolution.externalSubtitles;
              } catch (e) {
                appLogger.w('Could not re-resolve subtitles', error: e);
              }
            }
            if (subtitles != null && subtitles.isNotEmpty) {
              await _downloadSubtitles(globalKey, metadata, subtitles, client, showYear: showYear);
            }
          }
        }
      } catch (e) {
        appLogger.w('Supplementary downloads failed for $globalKey (video is saved)', error: e);
      }

      // Mark as completed — video is saved regardless of supplementary outcome
      await _transitionStatus(globalKey, DownloadStatus.completed);
      await _database.removeFromQueue(globalKey);
      appLogger.i('Download completed for $globalKey');
    } catch (e) {
      appLogger.e('Post-download processing failed for $globalKey', error: e);
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: 'Post-processing failed: $e');
      await _database.removeFromQueue(globalKey);
    } finally {
      _completingKeys.remove(globalKey);
      // Always advance the queue, even after errors
      final nextClient = await _getClientForDownloadKey(globalKey);
      if (nextClient != null) unawaited(_processQueue(nextClient));
    }
  }

  Future<MediaItem?> _resolveMetadata(String globalKey) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;
    final record = await _database.getDownloadedMedia(globalKey);
    return _lookupMetadata(parsed.serverId, parsed.ratingKey, clientScopeId: record?.clientScopeId);
  }

  /// Look up the year of the parent show for an episode (used for folder naming).
  Future<int?> _fetchShowYear(String serverId, String? grandparentRatingKey, {String? clientScopeId}) async {
    if (grandparentRatingKey == null) return null;
    return (await _lookupMetadata(serverId, grandparentRatingKey, clientScopeId: clientScopeId))?.year;
  }

  Future<String?> _resolveSafStoredPath(MediaItem metadata, String ext, int? showYear) async {
    final safBaseUri = _storageService.safBaseUri;
    if (safBaseUri == null) return null;

    final List<String> pathComponents;
    final String safFileName;
    if (metadata.isMovie) {
      pathComponents = _storageService.getMovieSafPathComponents(metadata);
      safFileName = _storageService.getMovieSafFileName(metadata, ext);
    } else if (metadata.isEpisode) {
      pathComponents = _storageService.getEpisodeSafPathComponents(metadata, showYear: showYear);
      safFileName = _storageService.getEpisodeSafFileName(metadata, ext);
    } else {
      pathComponents = [metadata.serverId!, metadata.id];
      safFileName = 'video.$ext';
    }

    final dirUri = await SafStorageService.instance.createNestedDirectories(safBaseUri, pathComponents);
    if (dirUri == null) return null;

    final child = await SafStorageService.instance.getChild(dirUri, [safFileName]);
    return child?.uri;
  }

  @visibleForTesting
  Future<int?> debugResolveSafRecoveryShowYear(MediaItem metadata, {String? clientScopeId}) {
    return _resolveSafRecoveryShowYear(metadata, clientScopeId: clientScopeId);
  }

  Future<String?> _resolveSafStoredPathForRecovery(MediaItem metadata, String ext, {String? clientScopeId}) async {
    final showYear = await _resolveSafRecoveryShowYear(metadata, clientScopeId: clientScopeId);
    return await _resolveSafStoredPath(metadata, ext, showYear) ??
        (showYear == null ? null : await _resolveSafStoredPath(metadata, ext, null));
  }

  Future<int?> _resolveSafRecoveryShowYear(MediaItem metadata, {String? clientScopeId}) async {
    final serverId = metadata.serverId;
    if (!metadata.isEpisode || serverId == null) return null;
    return _fetchShowYear(serverId, metadata.grandparentId, clientScopeId: clientScopeId);
  }

  Future<void> _downloadArtwork(String globalKey, MediaItem metadata, MediaServerClient client) async {
    if (metadata.serverId == null) return;

    try {
      _emitProgress(globalKey, DownloadStatus.downloading, 0, currentFile: 'artwork');

      final serverId = metadata.serverId!;
      final specs = client.resolveDownloadArtwork(metadata);
      for (final spec in specs) {
        await _downloadSingleArtwork(serverId, spec);
      }

      final storedThumbPath = metadata.thumbPath == null ? null : artworkStorageKey(metadata.thumbPath!);
      await _database.updateArtworkPaths(globalKey: globalKey, thumbPath: storedThumbPath);

      _emitProgressWithArtwork(globalKey, thumbPath: storedThumbPath);
      appLogger.d('Artwork downloaded for $globalKey');
    } catch (e) {
      appLogger.w('Failed to download artwork for $globalKey', error: e);
      // Don't fail the entire download if artwork fails
    }
  }

  /// Download a single artwork blob if not already on disk. The [spec] carries
  /// both the storage key (used to hash the local filename) and the absolute
  /// URL to fetch.
  Future<void> _downloadSingleArtwork(String serverId, DownloadArtworkSpec spec) async {
    try {
      // Check if already downloaded (deduplication)
      if (await _storageService.artworkExists(serverId, spec.localKey)) {
        appLogger.d('Artwork already exists: ${spec.localKey}');
        return;
      }

      if (spec.url.isEmpty) {
        appLogger.w('Empty artwork URL for: ${spec.localKey}');
        return;
      }

      final filePath = await _storageService.getArtworkPathFromThumb(serverId, spec.localKey);
      final file = File(filePath);

      // Ensure parent directory exists
      await file.parent.create(recursive: true);

      // Download the artwork
      await _http.downloadFile(spec.url, filePath);
      appLogger.i('Downloaded artwork: ${spec.localKey} -> $filePath');
    } catch (e, stack) {
      appLogger.w('Failed to download artwork: ${spec.localKey}', error: e, stackTrace: stack);
      // Don't throw - artwork download failures shouldn't kill the entire download
    }
  }

  /// Download all artwork for a metadata item (public method for parent metadata)
  /// Downloads thumb/poster, clearLogo, and background art
  Future<void> downloadArtworkForMetadata(MediaItem metadata, MediaServerClient client) async {
    if (metadata.serverId == null) return;
    final serverId = metadata.serverId!;
    for (final spec in client.resolveDownloadArtwork(metadata)) {
      await _downloadSingleArtwork(serverId, spec);
    }
  }

  /// Download chapter thumbnail images for a media item. Works for any
  /// backend whose [MediaServerClient.fetchPlaybackExtras] returns chapters
  /// with a `thumb` path — Plex's `/library/parts/X/indexes/sd/Y` and
  /// Jellyfin's `/Items/X/Images/Chapter/N?tag=Y` both pass through.
  Future<void> _downloadChapterThumbnails(String serverId, String ratingKey, MediaServerClient client) async {
    try {
      final extras = await client.fetchPlaybackExtras(ratingKey);

      for (final chapter in extras.chapters) {
        final thumb = chapter.thumb;
        if (thumb == null || thumb.isEmpty) continue;
        final url = client.thumbnailUrl(thumb);
        if (url.isEmpty) continue;
        await _downloadSingleArtwork(serverId, DownloadArtworkSpec(localKey: thumb, url: url));
      }

      if (extras.chapters.isNotEmpty) {
        appLogger.d('Downloaded ${extras.chapters.length} chapter thumbnails');
      }
    } catch (e) {
      appLogger.w('Failed to download chapter thumbnails', error: e);
      // Don't fail the entire download if chapter thumbnails fail
    }
  }

  /// [showYear]: For episodes, pass the show's premiere year (not the episode's year)
  Future<void> _downloadSubtitles(
    String globalKey,
    MediaItem metadata,
    List<DownloadSubtitleSpec> subtitles,
    MediaServerClient client, {
    int? showYear,
  }) async {
    try {
      _emitProgress(globalKey, DownloadStatus.downloading, 0, currentFile: 'subtitles');

      for (final subtitle in subtitles) {
        // Determine file extension from codec
        final extension = CodecUtils.getSubtitleExtension(subtitle.codec);

        // Get user-friendly subtitle path based on media type
        final String subtitlePath;
        if (_storageService.isUsingSaf) {
          subtitlePath = await _storageService.getSubtitlePath(metadata.serverId!, metadata.id, subtitle.id, extension);
        } else if (metadata.isEpisode) {
          subtitlePath = await _storageService.getEpisodeSubtitlePath(
            metadata,
            subtitle.id,
            extension,
            showYear: showYear,
          );
        } else if (metadata.isMovie) {
          subtitlePath = await _storageService.getMovieSubtitlePath(metadata, subtitle.id, extension);
        } else {
          // Fallback to old structure
          subtitlePath = await _storageService.getSubtitlePath(metadata.serverId!, metadata.id, subtitle.id, extension);
        }

        // Download subtitle file
        final file = File(subtitlePath);
        await file.parent.create(recursive: true);
        await _http.downloadFile(subtitle.url, subtitlePath);

        appLogger.d('Downloaded subtitle ${subtitle.id} for $globalKey');
      }
    } catch (e) {
      appLogger.w('Failed to download subtitles for $globalKey', error: e);
      // Don't fail the entire download if subtitles fail
    }
  }

  void _emitProgress(
    String globalKey,
    DownloadStatus status,
    int progress, {
    String? errorMessage,
    String? currentFile,
  }) {
    if (_disposed) return;
    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: status,
        progress: progress,
        errorMessage: errorMessage,
        currentFile: currentFile,
      ),
    );
  }

  /// Update download status in database and emit progress notification.
  ///
  /// This helper combines two common operations:
  /// 1. Update status in the database
  /// 2. Emit progress to listeners
  ///
  /// Default progress is 0 for most statuses, 100 for completed.
  Future<void> _transitionStatus(String globalKey, DownloadStatus status, {int? progress, String? errorMessage}) async {
    await _database.updateDownloadStatus(globalKey, status.index);
    if (status == DownloadStatus.failed && errorMessage != null) {
      await _database.updateDownloadError(globalKey, errorMessage);
    }
    _emitProgress(
      globalKey,
      status,
      progress ?? (status == DownloadStatus.completed ? 100 : 0),
      errorMessage: errorMessage,
    );
  }

  /// Emit progress update with artwork paths so DownloadProvider can sync
  void _emitProgressWithArtwork(String globalKey, {String? thumbPath}) {
    if (_disposed) return;
    // Emit a progress update containing artwork path
    // The status is preserved as downloading since artwork is just one step
    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: DownloadStatus.downloading,
        progress: 0,
        currentFile: 'artwork',
        thumbPath: thumbPath,
      ),
    );
  }

  /// Pause a download (works for both downloading and queued items)
  Future<void> pauseDownload(String globalKey) async {
    // Mark as pausing synchronously so callbacks from holding-queue promotions
    // can detect and cancel promoted tasks before any await yields.
    _pausingKeys.add(globalKey);

    try {
      _cancelDownloadTimers(globalKey);
      final bgTaskId = await _database.getBgTaskId(globalKey);
      if (bgTaskId != null) {
        final task = await FileDownloader().taskForId(bgTaskId);
        if (task != null && task is DownloadTask) {
          // Normal mode: native pause support
          await FileDownloader().pause(task);
        } else {
          // SAF mode (UriDownloadTask) or task not found: cancel (re-download on resume)
          await FileDownloader().cancelTaskWithId(bgTaskId);
        }
      }
      _pendingDownloadContext.remove(globalKey);
      await _transitionStatus(globalKey, DownloadStatus.paused);
      await _database.removeFromQueue(globalKey);
    } finally {
      _pausingKeys.remove(globalKey);
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, MediaServerClient client) async {
    final bgTaskId = await _database.getBgTaskId(globalKey);

    // Try native resume first (only works for normal-mode DownloadTask that was paused)
    if (bgTaskId != null) {
      final task = await FileDownloader().taskForId(bgTaskId);
      if (task != null && task is DownloadTask) {
        final resumed = await FileDownloader().resume(task);
        if (resumed) {
          appLogger.i('Resumed download via background_downloader for $globalKey');
          await _database.updateDownloadStatus(globalKey, DownloadStatus.downloading.index);
          _emitProgress(globalKey, DownloadStatus.downloading, 0);
          return;
        }
      }
    }

    // Native resume failed or not supported (SAF mode) — re-enqueue from scratch
    await _database.updateBgTaskId(globalKey, null);
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final resolvedClient = await _getClientForDownloadKey(globalKey) ?? client;
    unawaited(_processQueue(resolvedClient));
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, MediaServerClient client) async {
    _autoRetryTimers.remove(globalKey)?.cancel();
    await _database.clearDownloadError(globalKey);
    await _database.updateBgTaskId(globalKey, null);
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final resolvedClient = await _getClientForDownloadKey(globalKey) ?? client;
    unawaited(_processQueue(resolvedClient));
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    _cancelDownloadTimers(globalKey);
    final bgTaskId = await _database.getBgTaskId(globalKey);
    if (bgTaskId != null) {
      await FileDownloader().cancelTaskWithId(bgTaskId);
    }
    _pendingDownloadContext.remove(globalKey);
    await _transitionStatus(globalKey, DownloadStatus.cancelled);
    await _database.removeFromQueue(globalKey);
  }

  Future<void> deleteDownload(String globalKey) async {
    _cancelDownloadTimers(globalKey);
    final bgTaskId = await _database.getBgTaskId(globalKey);
    if (bgTaskId != null) {
      await FileDownloader().cancelTaskWithId(bgTaskId);
    }
    _pendingDownloadContext.remove(globalKey);

    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) {
      await _database.deleteDownload(globalKey);
      return;
    }

    final serverId = parsed.serverId;
    final ratingKey = parsed.ratingKey;
    final downloadRecord = await _database.getDownloadedMedia(globalKey);
    final clientScopeId = downloadRecord?.clientScopeId;
    final metadata = await _lookupMetadata(serverId, ratingKey, clientScopeId: clientScopeId);

    if (metadata == null) {
      // Fallback deletion without progress
      await _deleteMediaFilesWithMetadata(serverId, ratingKey, clientScopeId: clientScopeId);
      await _deleteForItemByServer(serverId, ratingKey, clientScopeId: clientScopeId);
      await _database.deleteDownload(globalKey);
      return;
    }

    final totalItems = await _getTotalItemsToDelete(metadata, serverId, clientScopeId: clientScopeId);

    _emitDeletionProgress(
      DeletionProgress(globalKey: globalKey, itemTitle: metadata.displayTitle, currentItem: 0, totalItems: totalItems),
    );

    await _deleteMediaFilesWithMetadata(serverId, ratingKey, clientScopeId: clientScopeId);

    await _deleteForItemByServer(serverId, ratingKey, clientScopeId: clientScopeId);

    await _database.deleteDownload(globalKey);

    _emitDeletionProgress(
      DeletionProgress(
        globalKey: globalKey,
        itemTitle: metadata.displayTitle,
        currentItem: totalItems,
        totalItems: totalItems,
      ),
    );
  }

  void _emitDeletionProgress(DeletionProgress progress) {
    if (_disposed) return;
    _deletionProgressController.add(progress);
  }

  /// Calculate total items to delete (for progress tracking)
  Future<int> _getTotalItemsToDelete(MediaItem metadata, String serverId, {String? clientScopeId}) async {
    switch (metadata.kind) {
      case MediaKind.episode:
      case MediaKind.movie:
        return 1;
      case MediaKind.season:
        final episodes = await _database.getEpisodesBySeason(metadata.id, serverId: serverId);
        return episodes.length;
      case MediaKind.show:
        final episodes = await _database.getEpisodesByShow(metadata.id, serverId: serverId);
        return episodes.length;
      default:
        return 1;
    }
  }

  Future<void> _deleteMediaFilesWithMetadata(String serverId, String ratingKey, {String? clientScopeId}) async {
    try {
      final gk = buildGlobalKey(serverId, ratingKey);
      final downloadRecord = await _database.getDownloadedMedia(gk);
      final scopeId = clientScopeId ?? downloadRecord?.clientScopeId;
      final metadata = await _lookupMetadata(serverId, ratingKey, clientScopeId: scopeId);

      if (metadata == null) {
        // Fallback: Try database record
        if (downloadRecord?.videoFilePath != null) {
          await _deleteByFilePath(downloadRecord!);
          return;
        }
        appLogger.w('Cannot delete - no metadata for $gk');
        return;
      }

      final isSaf = _storageService.isUsingSaf;
      switch (metadata.kind) {
        case MediaKind.episode:
          isSaf
              ? await _deleteEpisodeFilesSaf(metadata, serverId, clientScopeId: scopeId)
              : await _deleteEpisodeFiles(metadata, serverId, clientScopeId: scopeId);
          break;
        case MediaKind.season:
          isSaf
              ? await _deleteSeasonFilesSaf(metadata, serverId, clientScopeId: scopeId)
              : await _deleteSeasonFiles(metadata, serverId, clientScopeId: scopeId);
          break;
        case MediaKind.show:
          isSaf
              ? await _deleteShowFilesSaf(metadata, serverId, clientScopeId: scopeId)
              : await _deleteShowFiles(metadata, serverId, clientScopeId: scopeId);
          break;
        case MediaKind.movie:
          isSaf
              ? await _deleteMovieFilesSaf(metadata, serverId, clientScopeId: scopeId)
              : await _deleteMovieFiles(metadata, serverId, clientScopeId: scopeId);
          break;
        default:
          appLogger.w('Unknown type for deletion: ${metadata.kind.id}');
      }
    } catch (e, stack) {
      appLogger.e('Error deleting files', error: e, stackTrace: stack);
    }
  }

  /// Get chapter thumb paths from cached metadata. Backend-aware: routes
  /// through the resolved [MediaServerClient] so Jellyfin items return
  /// their `/Items/.../Images/Chapter/...?tag=...` paths and Plex items
  /// return their `/library/parts/.../indexes/sd/...` paths. Both shapes
  /// hash through [DownloadStorageService] the same way.
  ///
  /// `fetchPlaybackExtras` consults each backend's cache first, so this
  /// stays cheap during deletion (no network round-trip when the metadata
  /// is already cached, which it always is for downloaded items).
  Future<List<String>> _getChapterThumbPaths(String serverId, String ratingKey, {String? clientScopeId}) async {
    try {
      final client = _getClient(serverId, clientScopeId: clientScopeId);
      if (client == null) return [];
      final extras = await client.fetchPlaybackExtras(ratingKey);
      return extras.chapters
          .map((ch) => ch.thumb)
          .where((thumb) => thumb != null && thumb.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      appLogger.w('Error getting chapter thumb paths for $ratingKey', error: e);
      return [];
    }
  }

  /// Delete chapter thumbnails for a media item (with reference counting).
  ///
  /// Pre-loads all chapter paths for other items on the same server in one pass,
  /// then checks membership in a Set — O(items * chapters) instead of
  /// O(thumbs * items * chapters) with repeated DB queries.
  Future<void> _deleteChapterThumbnails(String serverId, String ratingKey, {String? clientScopeId}) async {
    try {
      final record = await _database.getDownloadedMedia(buildGlobalKey(serverId, ratingKey));
      final scopeId = clientScopeId ?? record?.clientScopeId;
      final thumbPaths = await _getChapterThumbPaths(serverId, ratingKey, clientScopeId: scopeId);

      if (thumbPaths.isEmpty) {
        appLogger.d('No chapter thumbnails to delete for $ratingKey');
        return;
      }

      final otherItems = await _database.getDownloadsByServerId(serverId);
      final inUseThumbPaths = <String>{};
      for (final item in otherItems) {
        if (item.ratingKey == ratingKey) continue;
        final itemChapterPaths = await _getChapterThumbPaths(
          serverId,
          item.ratingKey,
          clientScopeId: item.clientScopeId,
        );
        inUseThumbPaths.addAll(itemChapterPaths);
      }

      int deletedCount = 0;
      int preservedCount = 0;

      for (final thumbPath in thumbPaths) {
        try {
          if (inUseThumbPaths.contains(thumbPath)) {
            appLogger.d('Preserving chapter thumbnail (in use): $thumbPath');
            preservedCount++;
            continue;
          }

          final artworkPath = await _storageService.getArtworkPathFromThumb(serverId, thumbPath);
          if (await _deleteFileIfExists(File(artworkPath), 'chapter thumbnail')) {
            deletedCount++;
          }
        } catch (e) {
          appLogger.w('Failed to delete chapter thumbnail: $thumbPath', error: e);
        }
      }

      if (deletedCount > 0 || preservedCount > 0) {
        appLogger.i('Deleted $deletedCount of ${thumbPaths.length} chapter thumbnails ($preservedCount preserved)');
      }
    } catch (e, stack) {
      appLogger.w('Error deleting chapter thumbnails for $ratingKey', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteEpisodeFiles(MediaItem episode, String serverId, {String? clientScopeId}) async {
    try {
      final parentMetadata = episode.grandparentId != null
          ? await _lookupMetadata(serverId, episode.grandparentId!, clientScopeId: clientScopeId)
          : null;
      final showYear = parentMetadata?.year;

      final videoPathTemplate = await _storageService.getEpisodeVideoPath(episode, 'tmp', showYear: showYear);
      final videoPathWithoutExt = videoPathTemplate.substring(0, videoPathTemplate.lastIndexOf('.'));
      final actualVideoFile = await _findFileWithAnyExtension(videoPathWithoutExt);
      if (actualVideoFile != null) {
        await _deleteFileIfExists(actualVideoFile, 'episode video');
        // Also clean up any .part file from interrupted downloads
        await _deleteFileIfExists(File('${actualVideoFile.path}.part'), 'partial download');
      }

      final thumbPath = await _storageService.getEpisodeThumbnailPath(episode, showYear: showYear);
      await _deleteFileIfExists(File(thumbPath), 'episode thumbnail');

      final subsDir = await _storageService.getEpisodeSubtitlesDirectory(episode, showYear: showYear);
      if (await subsDir.exists()) {
        await subsDir.delete(recursive: true);
        appLogger.i('Deleted episode subtitles: ${subsDir.path}');
      }

      await _deleteChapterThumbnails(serverId, episode.id, clientScopeId: clientScopeId);

      await _cleanupEmptyDirectories(episode, showYear);

      // Safety net: verify the actual DB-recorded file is gone
      await _ensureDbFileDeleted(serverId, episode.id);
    } catch (e, stack) {
      appLogger.e('Error deleting episode files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteSeasonFiles(MediaItem season, String serverId, {String? clientScopeId}) async {
    try {
      final parentMetadata = season.parentId != null
          ? await _lookupMetadata(serverId, season.parentId!, clientScopeId: clientScopeId)
          : null;
      final showYear = parentMetadata?.year;

      final episodesInSeason = await _database.getEpisodesBySeason(season.id, serverId: serverId);

      appLogger.d('Deleting ${episodesInSeason.length} episodes in season ${season.id}');
      await _deleteEpisodesInCollection(
        episodes: episodesInSeason,
        serverId: serverId,
        clientScopeId: clientScopeId,
        parentKey: season.id,
        parentTitle: season.displayTitle,
      );

      final seasonDir = await _storageService.getSeasonDirectory(season, showYear: showYear);
      if (await seasonDir.exists()) {
        await seasonDir.delete(recursive: true);
        appLogger.i('Deleted season directory: ${seasonDir.path}');
      }

      await _cleanupShowDirectory(season, showYear);
    } catch (e, stack) {
      appLogger.e('Error deleting season files', error: e, stackTrace: stack);
    }
  }

  /// Delete episodes in a collection (season or show). In SAF mode, cleans up
  /// app-private subtitle/thumbnail assets per episode — the SAF video files
  /// and parent directories are wiped in one recursive call by the caller.
  Future<void> _deleteEpisodesInCollection({
    required List<DownloadedMediaItem> episodes,
    required String serverId,
    String? clientScopeId,
    required String parentKey,
    required String parentTitle,
  }) async {
    final isSaf = _storageService.isUsingSaf;
    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final episodeGlobalKey = buildGlobalKey(serverId, episode.ratingKey);

      _emitDeletionProgress(
        DeletionProgress(
          globalKey: buildGlobalKey(serverId, parentKey),
          itemTitle: parentTitle,
          currentItem: i + 1,
          totalItems: episodes.length,
          currentOperation: 'Deleting episode ${i + 1} of ${episodes.length}',
        ),
      );

      if (isSaf) {
        final episodeScopeId = episode.clientScopeId ?? clientScopeId;
        final episodeMetadata = await _lookupMetadata(serverId, episode.ratingKey, clientScopeId: episodeScopeId);
        if (episodeMetadata != null) {
          await _deleteEpisodeFilesSaf(
            episodeMetadata,
            serverId,
            clientScopeId: episodeScopeId,
            skipSafVideoAndParents: true,
          );
        } else {
          await _deleteChapterThumbnails(serverId, episode.ratingKey, clientScopeId: episodeScopeId);
          await _deleteByFilePath(episode);
        }
      } else {
        await _deleteChapterThumbnails(
          serverId,
          episode.ratingKey,
          clientScopeId: episode.clientScopeId ?? clientScopeId,
        );
        await _deleteByFilePath(episode);
      }

      await _deleteForItemByServer(serverId, episode.ratingKey, clientScopeId: episode.clientScopeId ?? clientScopeId);
      await _database.deleteDownload(episodeGlobalKey);
    }
  }

  Future<void> _deleteShowFiles(MediaItem show, String serverId, {String? clientScopeId}) async {
    try {
      final episodesInShow = await _database.getEpisodesByShow(show.id, serverId: serverId);

      appLogger.d('Deleting ${episodesInShow.length} episodes in show ${show.id}');
      await _deleteEpisodesInCollection(
        episodes: episodesInShow,
        serverId: serverId,
        clientScopeId: clientScopeId,
        parentKey: show.id,
        parentTitle: show.displayTitle,
      );

      final showDir = await _storageService.getShowDirectory(show);
      if (await showDir.exists()) {
        await showDir.delete(recursive: true);
        appLogger.i('Deleted show directory: ${showDir.path}');
      }
    } catch (e, stack) {
      appLogger.e('Error deleting show files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteMovieFiles(MediaItem movie, String serverId, {String? clientScopeId}) async {
    try {
      final movieDir = await _storageService.getMovieDirectory(movie);
      if (await movieDir.exists()) {
        await movieDir.delete(recursive: true);
        appLogger.i('Deleted movie directory: ${movieDir.path}');
      }

      await _deleteChapterThumbnails(serverId, movie.id, clientScopeId: clientScopeId);

      // Safety net: verify the actual DB-recorded file is gone
      await _ensureDbFileDeleted(serverId, movie.id);
    } catch (e, stack) {
      appLogger.e('Error deleting movie files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteMovieFilesSaf(MediaItem movie, String serverId, {String? clientScopeId}) async {
    try {
      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final movieDir = await SafStorageService.instance.getChild(
          safBaseUri,
          _storageService.getMovieSafPathComponents(movie),
        );
        if (movieDir != null) {
          await _deleteSafDirRecursive(movieDir.uri, description: 'movie directory');
        }
      }
      await _deleteChapterThumbnails(serverId, movie.id, clientScopeId: clientScopeId);
      await _ensureDbFileDeleted(serverId, movie.id);
    } catch (e, stack) {
      appLogger.e('Error deleting SAF movie files', error: e, stackTrace: stack);
    }
  }

  /// When called inside a bulk season/show delete, the caller wipes the parent
  /// dir — so we skip the SAF video delete and parent walk-up here.
  Future<void> _deleteEpisodeFilesSaf(
    MediaItem episode,
    String serverId, {
    String? clientScopeId,
    bool skipSafVideoAndParents = false,
  }) async {
    try {
      final parentMetadata = episode.grandparentId != null
          ? await _lookupMetadata(serverId, episode.grandparentId!, clientScopeId: clientScopeId)
          : null;
      final showYear = parentMetadata?.year;

      final safBaseUri = _storageService.safBaseUri;
      String? seasonDirUri;
      String? showDirUri;

      if (safBaseUri != null && !skipSafVideoAndParents) {
        final saf = SafStorageService.instance;
        final resolved = await Future.wait([
          saf.getChild(safBaseUri, _storageService.getEpisodeSafPathComponents(episode, showYear: showYear)),
          saf.getChild(safBaseUri, _storageService.getShowSafPathComponents(episode, showYear: showYear)),
        ]);
        seasonDirUri = resolved[0]?.uri;
        showDirUri = resolved[1]?.uri;

        if (seasonDirUri != null) {
          final baseName = _storageService.getEpisodeSafBaseName(episode);
          final file = await _findSafFileByBaseName(seasonDirUri, baseName);
          if (file != null) {
            await _tryDeleteSaf(file.uri, isDir: false, description: 'SAF episode video');
          }
        }
      }

      // Subtitles and the episode thumbnail are written into app-private storage
      // even in SAF mode (getDownloadsDirectory() falls through to default when
      // _customPathType == 'saf'). Deletion follows suit until writing is migrated.
      final thumbPath = await _storageService.getEpisodeThumbnailPath(episode, showYear: showYear);
      await _deleteFileIfExists(File(thumbPath), 'episode thumbnail');

      final subsDir = await _storageService.getEpisodeSubtitlesDirectory(episode, showYear: showYear);
      if (await subsDir.exists()) {
        await subsDir.delete(recursive: true);
        appLogger.i('Deleted episode subtitles: ${subsDir.path}');
      }

      await _deleteChapterThumbnails(serverId, episode.id, clientScopeId: clientScopeId);

      if (!skipSafVideoAndParents) {
        await _deleteEmptySafDirsInOrder([seasonDirUri, showDirUri]);
        await _ensureDbFileDeleted(serverId, episode.id);
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF episode files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteSeasonFilesSaf(MediaItem season, String serverId, {String? clientScopeId}) async {
    try {
      final parentMetadata = season.parentId != null
          ? await _lookupMetadata(serverId, season.parentId!, clientScopeId: clientScopeId)
          : null;
      final showYear = parentMetadata?.year;

      final episodesInSeason = await _database.getEpisodesBySeason(season.id, serverId: serverId);
      appLogger.d('Deleting ${episodesInSeason.length} episodes in season ${season.id} (SAF)');
      await _deleteEpisodesInCollection(
        episodes: episodesInSeason,
        serverId: serverId,
        clientScopeId: clientScopeId,
        parentKey: season.id,
        parentTitle: season.displayTitle,
      );

      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final saf = SafStorageService.instance;
        final seasonDir = await saf.getChild(
          safBaseUri,
          _storageService.getSeasonSafPathComponents(season, showYear: showYear),
        );
        if (seasonDir != null) {
          await _deleteSafDirRecursive(seasonDir.uri, description: 'season directory');
        }
        final showDir = await saf.getChild(
          safBaseUri,
          _storageService.getShowSafPathComponents(season, showYear: showYear),
        );
        if (showDir != null) {
          await _deleteEmptySafDirsInOrder([showDir.uri]);
        }
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF season files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteShowFilesSaf(MediaItem show, String serverId, {String? clientScopeId}) async {
    try {
      final episodesInShow = await _database.getEpisodesByShow(show.id, serverId: serverId);
      appLogger.d('Deleting ${episodesInShow.length} episodes in show ${show.id} (SAF)');
      await _deleteEpisodesInCollection(
        episodes: episodesInShow,
        serverId: serverId,
        clientScopeId: clientScopeId,
        parentKey: show.id,
        parentTitle: show.displayTitle,
      );

      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final showDir = await SafStorageService.instance.getChild(
          safBaseUri,
          _storageService.getShowSafPathComponents(show),
        );
        if (showDir != null) {
          await _deleteSafDirRecursive(showDir.uri, description: 'show directory');
        }
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF show files', error: e, stackTrace: stack);
    }
  }

  /// Safety net: after metadata-based deletion, verify the actual DB-recorded
  /// video file is gone. If not, delete it and clean up parent directories.
  Future<void> _ensureDbFileDeleted(String serverId, String ratingKey) async {
    try {
      final globalKey = buildGlobalKey(serverId, ratingKey);
      final record = await _database.getDownloadedMedia(globalKey);
      if (record?.videoFilePath == null) return;

      final storedPath = record!.videoFilePath!;
      if (_storageService.isSafUri(storedPath)) {
        // SAF mode: parent cleanup is handled by the type-specific SAF helpers —
        // here we only verify the video URI itself is gone.
        if (await SafStorageService.instance.exists(storedPath, isDir: false)) {
          appLogger.w('Safety net: SAF video still exists after metadata deletion, deleting: $storedPath');
          await SafStorageService.instance.delete(storedPath, isDir: false);
        }
        return;
      }

      final videoPath = await _storageService.ensureAbsolutePath(storedPath);
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) return;

      appLogger.w('Safety net: video still exists after metadata deletion, deleting: $videoPath');
      await videoFile.delete();

      await _deleteFileIfExists(File('$videoPath.part'), 'partial download');
      final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
      final subsDir = Directory(subsPath);
      if (await subsDir.exists()) await subsDir.delete(recursive: true);

      // Walk up empty parent directories toward downloads root
      await _cleanupEmptyParentDirectories(videoFile.parent);
    } catch (e, stack) {
      appLogger.w('Safety net deletion failed', error: e, stackTrace: stack);
    }
  }

  /// Walk up from a directory toward the downloads root, removing empty dirs.
  Future<void> _cleanupEmptyParentDirectories(Directory dir) async {
    try {
      final downloadsDir = await _storageService.getDownloadsDirectory();
      var current = dir;
      while (current.path != downloadsDir.path && current.path.startsWith(downloadsDir.path)) {
        if (!await current.exists()) {
          current = current.parent;
          continue;
        }
        final contents = await current.list().toList();
        if (contents.isEmpty) {
          await current.delete();
          appLogger.i('Cleaned up empty directory: ${current.path}');
          current = current.parent;
        } else {
          break;
        }
      }
    } catch (e) {
      appLogger.w('Error cleaning up parent directories', error: e);
    }
  }

  /// Clean up empty directories after deleting episode (file mode only — the
  /// SAF deleters call [_deleteEmptySafDirsInOrder] directly).
  Future<void> _cleanupEmptyDirectories(MediaItem episode, int? showYear) async {
    if (_storageService.isUsingSaf) return;
    final seasonDir = await _storageService.getSeasonDirectory(episode, showYear: showYear);

    if (await seasonDir.exists()) {
      final contents = await seasonDir.list().toList();
      final hasVideos = contents.any(
        (e) => _videoExtensions.any((ext) => e.path.endsWith(ext)) || e.path.contains('_subs'),
      );

      if (!hasVideos) {
        if (!await _isSeasonArtworkInUse(episode, showYear)) {
          await seasonDir.delete(recursive: true);
          appLogger.i('Deleted empty season directory: ${seasonDir.path}');
          await _cleanupShowDirectory(episode, showYear);
        }
      }
    }
  }

  /// Clean up show directory if empty (file mode only).
  Future<void> _cleanupShowDirectory(MediaItem metadata, int? showYear) async {
    if (_storageService.isUsingSaf) return;
    final showDir = await _storageService.getShowDirectory(metadata, showYear: showYear);

    if (await showDir.exists()) {
      final contents = await showDir.list().toList();
      final hasSeasons = contents.any((e) => e is Directory && e.path.contains('Season '));

      if (!hasSeasons) {
        if (!await _isShowArtworkInUse(metadata, showYear)) {
          await showDir.delete(recursive: true);
          appLogger.i('Deleted empty show directory: ${showDir.path}');
        }
      }
    }
  }

  Future<bool> _isSeasonArtworkInUse(MediaItem episode, int? _) async {
    final seasonKey = episode.parentId;
    if (seasonKey == null) return false;

    final otherEpisodes = await _database.getEpisodesBySeason(seasonKey);

    return otherEpisodes.any((e) => e.globalKey != episode.globalKey);
  }

  Future<bool> _isShowArtworkInUse(MediaItem metadata, int? _) async {
    final showKey = metadata.grandparentId ?? metadata.parentId ?? metadata.id;

    // Use targeted query instead of full table scan
    final showEpisodes = await _database.getEpisodesByShow(showKey);

    return showEpisodes.any((item) => item.globalKey != metadata.globalKey);
  }

  Future<File?> _findFileWithAnyExtension(String pathWithoutExt) async {
    final dir = Directory(path.dirname(pathWithoutExt));
    final baseName = path.basename(pathWithoutExt);

    if (!await dir.exists()) return null;

    try {
      final files = await dir
          .list()
          .where((e) => e is File && path.basenameWithoutExtension(e.path) == baseName)
          .toList();

      return files.isNotEmpty ? files.first as File : null;
    } catch (e) {
      appLogger.w('Error finding file: $pathWithoutExt', error: e);
      return null;
    }
  }

  /// Fallback deletion using file paths from database
  Future<void> _deleteByFilePath(DownloadedMediaItem record) async {
    try {
      if (record.videoFilePath != null && _storageService.isSafUri(record.videoFilePath!)) {
        // Metadata is gone by the time this fallback runs, so parent-dir cleanup
        // is not attempted here — SAF URIs don't expose a parent reliably.
        await _tryDeleteSaf(record.videoFilePath!, isDir: false, description: 'SAF video file');
      } else if (record.videoFilePath != null) {
        final videoPath = await _storageService.ensureAbsolutePath(record.videoFilePath!);
        final videoFile = File(videoPath);
        final videoDeleted = await _deleteFileIfExists(videoFile, 'video file');

        if (videoDeleted) {
          await _deleteFileIfExists(File('$videoPath.part'), 'partial download');

          final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
          final subsDir = Directory(subsPath);
          if (await subsDir.exists()) {
            await subsDir.delete(recursive: true);
            appLogger.i('Deleted subtitles: $subsPath');
          }

          await _cleanupEmptyParentDirectories(videoFile.parent);
        }
      }

      // thumbPath is a server-side API path (Plex /library/metadata/.../thumb,
      // Jellyfin /Items/.../Images/Primary), not a local file path —
      // resolve it via getArtworkPathFromThumb
      if (record.thumbPath != null) {
        final parsed = parseGlobalKey(record.globalKey);
        if (parsed != null) {
          final thumbPath = await _storageService.getArtworkPathFromThumb(parsed.serverId, record.thumbPath!);
          await _deleteFileIfExists(File(thumbPath), 'thumbnail');
        }
      }
    } catch (e, stack) {
      appLogger.e('Error in fallback deletion', error: e, stackTrace: stack);
    }
  }

  Future<List<DownloadedMediaItem>> getAllDownloads() {
    return _database.select(_database.downloadedMedia).get();
  }

  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) {
    return _database.getDownloadedMedia(globalKey);
  }

  /// Save metadata for a media item (show, season, movie, or episode)
  /// Used to persist parent metadata (shows/seasons) for offline display.
  ///
  /// Both backends now have read-path cache-through, so the work is just to
  /// hit `client.fetchItem` (idempotent) and pin the resulting row.
  Future<void> saveMetadata(MediaItem metadata, MediaServerClient client) async {
    if (metadata.serverId == null) {
      appLogger.w('Cannot save metadata without serverId');
      return;
    }
    await _pinMetadataForOffline(client, metadata);
  }

  void dispose() {
    _disposed = true;
    for (final timer in _progressDebounceTimers.values) {
      timer.cancel();
    }
    _progressDebounceTimers.clear();
    for (final timer in _autoRetryTimers.values) {
      timer.cancel();
    }
    _autoRetryTimers.clear();
    _pendingDownloadContext.clear();
    _pendingSupplementaryDownloads.clear();
    _completingKeys.clear();
    _pausingKeys.clear();
    _progressController.close();
    _deletionProgressController.close();
  }
}

String? downloadExtensionFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  final lastDot = lastSegment.lastIndexOf('.');
  if (lastDot != -1 && lastDot < lastSegment.length - 1) {
    return _safeDownloadExtension(lastSegment.substring(lastDot + 1));
  }
  for (final entry in uri.queryParameters.entries) {
    if (entry.key.toLowerCase() == 'container') {
      return _safeDownloadExtension(entry.value);
    }
  }
  return null;
}

String? _safeDownloadExtension(String raw) {
  final ext = raw.split(RegExp(r'[,|]')).first.trim().replaceFirst(RegExp(r'^\.+'), '').toLowerCase();
  if (ext.isEmpty || !RegExp(r'^[a-z0-9][a-z0-9._-]{0,39}$').hasMatch(ext)) return null;
  return ext;
}
