import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item.dart';
import '../models/plex_metadata.dart';
import 'plex_client.dart';
import '../utils/app_logger.dart';

typedef ClientLocator = PlexClient? Function(String serverId);

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  List<DownloadItem> _downloadItems = [];
  final Map<String, CancelToken> _cancelTokens = {};
  bool _isInitialized = false;
  String? _customDownloadPath;
  ClientLocator? clientLocator;

  List<DownloadItem> get downloadItems => List.unmodifiable(_downloadItems);

  Future<String> get downloadPath async {
    if (_customDownloadPath != null) return _customDownloadPath!;
    return await _getDefaultDownloadPath();
  }

  Future<void> setDownloadPath(String path) async {
    _customDownloadPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_path', path);
    notifyListeners();
  }

  Future<String> _getDefaultDownloadPath() async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return '$home/Movies/Plezy';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Downloads/Plezy';
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return '$userProfile\\Downloads\\Plezy';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/downloads';
  }

  // Queue management
  static const int _maxConcurrentDownloads = 1;
  bool _isProcessingQueue = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadItems();
    _isInitialized = true;

    // Ensure directory exists for default path
    try {
      final path = await downloadPath;
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      appLogger.e('Failed to create download directory', error: e);
    }

    // Mark interrupted downloads as pending (auto-resume)
    bool changed = false;
    for (int i = 0; i < _downloadItems.length; i++) {
      final item = _downloadItems[i];
      if (item.status == DownloadStatus.downloading ||
          (item.status == DownloadStatus.failed &&
              item.error == "Interrupted on startup")) {
        _downloadItems[i] = item.copyWith(
          status: DownloadStatus.pending,
          error: null, // Clear error
          progress: item.progress,
          // We keep progress? If we don't support resume, we might want to reset to 0 in _startDownload
          // But visually pending is fine.
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _persistDownloads();
    }
    notifyListeners();

    // Trigger queue to resume
    _processQueue();
  }

  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('downloads');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _downloadItems = jsonList.map((j) => DownloadItem.fromJson(j)).toList();
      }
      _customDownloadPath = prefs.getString('download_path');
    } catch (e) {
      appLogger.e('Failed to load downloads', error: e);
    }
  }

  Future<void> _persistDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(
        _downloadItems.map((i) => i.toJson()).toList(),
      );
      await prefs.setString('downloads', jsonString);
    } catch (e) {
      appLogger.e('Failed to save downloads', error: e);
    }
  }

  Future<void> download(PlexClient client, PlexMetadata metadata) async {
    // Check if already exists
    if (_downloadItems.any(
      (item) => item.metadata.ratingKey == metadata.ratingKey,
    )) {
      return;
    }

    final id =
        metadata.ratingKey ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Create item with pending status and no URL initially (JIT fetching)
    // Title defaults to metadata title, fallback to Unknown
    final newItem = DownloadItem(
      id: id,
      metadata: metadata,
      downloadUrl: null, // Will be fetched when processing
      title: metadata.title ?? 'Unknown',
      status: DownloadStatus.pending,
    );

    _downloadItems.add(newItem);
    _persistDownloads();
    notifyListeners();

    // Trigger queue processing
    _processQueue();
  }

  Future<void> retry(String id, PlexClient client) async {
    final index = _downloadItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    // Reset item state
    _downloadItems[index] = _downloadItems[index].copyWith(
      status: DownloadStatus.pending,
      error: null, // Clear error
      progress:
          0.0, // Reset progress (could keep it if resuming supported, but simple retry restarts)
      downloadSpeed: 0,
    );
    _persistDownloads();
    notifyListeners();

    // Trigger queue processing
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      // Count active downloads
      final activeCount = _downloadItems
          .where((i) => i.status == DownloadStatus.downloading)
          .length;

      if (activeCount >= _maxConcurrentDownloads) {
        return;
      }

      // Find next pending items
      final pendingItems = _downloadItems
          .where((i) => i.status == DownloadStatus.pending)
          .take(_maxConcurrentDownloads - activeCount)
          .toList();

      for (final item in pendingItems) {
        PlexClient? client;
        if (clientLocator != null && item.metadata.serverId != null) {
          client = clientLocator!(item.metadata.serverId!);
        }

        if (client == null) {
          appLogger.w(
            'Cannot start download for ${item.title}: Client not found (Server ID: ${item.metadata.serverId})',
          );
          // Skip loop, leaving it pending.
          // TODO: Maybe mark as paused or failed if persistent?
          continue;
        }

        // Don't await here to allow concurrent starts
        _startDownload(item, client);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _startDownload(DownloadItem item, PlexClient client) async {
    try {
      // Mark as downloading immediately to reserve slot
      final index = _downloadItems.indexWhere((i) => i.id == item.id);
      if (index == -1) return;

      // JIT URL Fetching if needed
      String? url = item.downloadUrl;
      if (url == null) {
        url = await client.getVideoUrl(item.metadata.ratingKey);
        if (url == null) {
          _updateItemStatus(
            item.id,
            DownloadStatus.failed,
            error: 'Could not fetch URL',
          );
          // Continue to next item
          _processQueue();
          return;
        }

        // Update item with URL
        _downloadItems[index] = _downloadItems[index].copyWith(
          downloadUrl: url,
          status: DownloadStatus.downloading,
        );
        // Refresh local var
        item = _downloadItems[index];
      } else {
        _updateItemStatus(item.id, DownloadStatus.downloading);
      }

      notifyListeners();

      final dirPath = await downloadPath;
      final downloadsDir = Directory(dirPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName =
          '${item.id}_${_sanitizeFilename(item.metadata.title ?? "video")}.mp4';
      final savePath = '$dirPath/$fileName';

      // Update local path
      final updatedIndex = _downloadItems.indexWhere((i) => i.id == item.id);
      if (updatedIndex != -1) {
        _downloadItems[updatedIndex] = _downloadItems[updatedIndex].copyWith(
          localPath: savePath,
        );
        _persistDownloads();
      }

      final cancelToken = CancelToken();
      _cancelTokens[item.id] = cancelToken;

      // Retry configuration
      int maxRetries = 5;
      bool success = false;
      String? lastError;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          if (attempt > 1) {
            appLogger.d('Retrying download ${item.title} (attempt $attempt)');
            // Add delay before retry
            await Future.delayed(const Duration(seconds: 2));
          }

          if (cancelToken.isCancelled) {
            throw DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.cancel,
            );
          }

          int lastReceived = 0;
          DateTime lastSpeedUpdate = DateTime.now();

          // Delete partial file if exists from previous attempt
          final file = File(savePath);
          if (await file.exists()) {
            await file.delete();
          }

          await _dio.download(
            url,
            savePath,
            cancelToken: cancelToken,
            deleteOnError: true,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final now = DateTime.now();
                final durationInSeconds =
                    now.difference(lastSpeedUpdate).inMilliseconds / 1000.0;

                // Update speed every 1 second
                int speed = 0;
                if (durationInSeconds >= 1.0) {
                  final bytesDelta = received - lastReceived;
                  speed = (bytesDelta / durationInSeconds).round();

                  lastReceived = received;
                  lastSpeedUpdate = now;

                  final progress = received / total;
                  _updateItemProgressAndSpeed(item.id, progress, speed);
                } else {
                  final progress = received / total;
                  _updateItemProgress(item.id, progress);
                }
              }
            },
          );

          success = true;
          break; // Success!
        } catch (e) {
          lastError = e.toString();

          if (e is DioException && CancelToken.isCancel(e)) {
            rethrow; // Don't retry invalid cancellations
          }

          // Special handling for Connection Closed
          if (e.toString().contains("Connection closed")) {
            appLogger.w(
              'Connection closed for ${item.title}, waiting before retry...',
            );
            await Future.delayed(const Duration(seconds: 3));
          }

          // Continue loop to retry
        }
      }

      if (success) {
        _updateItemStatus(item.id, DownloadStatus.completed);
      } else {
        throw Exception(
          lastError ?? 'Download failed after $maxRetries attempts',
        );
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        _updateItemStatus(item.id, DownloadStatus.canceled);
      } else {
        appLogger.e('Download failed for ${item.title}', error: e);
        _updateItemStatus(item.id, DownloadStatus.failed, error: e.toString());
      }
    } finally {
      _cancelTokens.remove(item.id);
      _processQueue();
    }
  }

  void _updateItemStatus(String id, DownloadStatus status, {String? error}) {
    final index = _downloadItems.indexWhere((i) => i.id == id);
    if (index != -1) {
      _downloadItems[index] = _downloadItems[index].copyWith(
        status: status,
        error: error,
        // Reset progress if completed
        progress: status == DownloadStatus.completed
            ? 1.0
            : _downloadItems[index].progress,
        downloadSpeed:
            0, // Reset speed on status change (e.g. completed/failed)
      );
      _persistDownloads();
      notifyListeners();
    }
  }

  void _updateItemProgress(String id, double progress) {
    final index = _downloadItems.indexWhere((i) => i.id == id);
    if (index != -1) {
      // Only notify if progress changed significantly to avoid flooding
      if ((progress - _downloadItems[index].progress).abs() > 0.01 ||
          progress == 1.0) {
        _downloadItems[index] = _downloadItems[index].copyWith(
          progress: progress,
        );
        notifyListeners();
      }
    }
  }

  void _updateItemProgressAndSpeed(String id, double progress, int speed) {
    final index = _downloadItems.indexWhere((i) => i.id == id);
    if (index != -1) {
      _downloadItems[index] = _downloadItems[index].copyWith(
        progress: progress,
        downloadSpeed: speed,
      );
      notifyListeners(); // Always notify on speed update (processed every 1s)
    }
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\.-]'), '');
  }

  Future<void> delete(String id) async {
    final index = _downloadItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _downloadItems[index];

    // Cancel if running
    if (_cancelTokens.containsKey(id)) {
      _cancelTokens[id]?.cancel();
      _cancelTokens.remove(id);
    }

    // Delete file
    if (item.localPath != null) {
      try {
        final file = File(item.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        appLogger.e('Failed to delete file', error: e);
      }
    }

    _downloadItems.removeAt(index);
    notifyListeners();
    _persistDownloads();

    // Trigger queue to fill the slot (with no client - will just process nulls and skip,
    // waiting for next actual download call to resume queue)
    _processQueue();
  }

  bool isDownloaded(String id) {
    return _downloadItems.any(
      (i) => i.id == id && i.status == DownloadStatus.completed,
    );
  }

  bool isDownloading(String id) {
    return _downloadItems.any(
      (i) =>
          i.id == id &&
          (i.status == DownloadStatus.downloading ||
              i.status == DownloadStatus.pending),
    );
  }

  DownloadItem? getItem(String id) {
    try {
      return _downloadItems.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }
}
