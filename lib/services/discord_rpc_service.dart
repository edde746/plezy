import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_helper.dart';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:dio/dio.dart';

import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import 'plex_client.dart';
import 'settings_service.dart';

/// Cached Litterbox URL with expiry timestamp
class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Service that manages Discord Rich Presence integration.
///
/// Desktop only (Windows, macOS, Linux). Shows "Watching" activity
/// when video is playing. Gracefully handles Discord not running.
class DiscordRPCService {
  static const String _applicationId = '1453773470306402439';
  static const String _litterboxUrl = 'https://litterbox.catbox.moe/resources/internals/api.php';

  /// Cache of Plex thumbnail paths to Litterbox URLs with expiry (1 hour)
  static final Map<String, _CachedUrl> _litterboxCache = {};

  static DiscordRPCService? _instance;
  static DiscordRPCService get instance {
    _instance ??= DiscordRPCService._();
    return _instance!;
  }

  DiscordRPC? _rpc;
  bool _isConnected = false;
  bool _isEnabled = false;
  bool _isInitialized = false;
  PlexMetadata? _currentMetadata;
  PlexClient? _currentClient;
  String? _cachedThumbnailUrl;
  DateTime? _playbackStartTime;
  Duration? _mediaDuration;
  Duration? _currentPosition;
  double _playbackSpeed = 1.0;
  Timer? _reconnectTimer;
  DateTime? _lastPresenceUpdate;
  StreamSubscription<void>? _readySubscription;
  StreamSubscription<void>? _disconnectedSubscription;
  StreamSubscription<dynamic>? _errorSubscription;

  DiscordRPCService._();

  /// Check if Discord RPC is available on this platform
  static bool get isAvailable {
    if (kIsWeb || (!AppPlatform.isMacOS && !AppPlatform.isWindows && !AppPlatform.isLinux)) {
      return false;
    }
    return DiscordRPC.isAvailable;
  }

  /// Initialize the service. Call once at app startup (main.dart).
  Future<void> initialize() async {
    if (!isAvailable) {
      appLogger.d('Discord RPC not available on this platform');
      return;
    }

    if (_isInitialized) return;
    _isInitialized = true;

    final settings = await SettingsService.getInstance();
    _isEnabled = settings.getEnableDiscordRPC();

    if (_isEnabled) {
      await _connect();
    }
  }

  /// Enable or disable Discord RPC
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;

    _isEnabled = enabled;

    if (enabled) {
      await _connect();
      // Restore presence if we have active playback
      if (_currentMetadata != null) {
        await _updatePresence();
      }
    } else {
      await _disconnect();
    }
  }

  /// Start showing presence for media playback
  Future<void> startPlayback(PlexMetadata metadata, PlexClient client) async {
    _currentMetadata = metadata;
    _currentClient = client;
    _playbackStartTime = DateTime.now();
    _mediaDuration = metadata.duration != null ? Duration(milliseconds: metadata.duration!) : null;
    _currentPosition = Duration.zero;
    _cachedThumbnailUrl = null;
    _playbackSpeed = 1.0;

    if (_isEnabled && _isConnected) {
      // Upload thumbnail in background, don't block playback
      _uploadThumbnailAndUpdatePresence();
    }
  }

  /// Update current playback position (for progress bar)
  void updatePosition(Duration position) {
    final previousPosition = _currentPosition;
    _currentPosition = position;

    // Update presence if position jumped significantly (seek detected)
    if (_isEnabled && _isConnected && _playbackStartTime != null && previousPosition != null) {
      final drift = (position - previousPosition).abs();
      // If position changed by more than 5 seconds, likely a seek
      if (drift > const Duration(seconds: 5)) {
        // Throttle updates to max once per second
        final now = DateTime.now();
        if (_lastPresenceUpdate == null || now.difference(_lastPresenceUpdate!) > const Duration(seconds: 1)) {
          _lastPresenceUpdate = now;
          _updatePresence();
        }
      }
    }
  }

  /// Update current playback speed (for accurate remaining time calculation)
  void updatePlaybackSpeed(double speed) {
    if (_playbackSpeed == speed) return;
    _playbackSpeed = speed;
    if (_isEnabled && _isConnected && _playbackStartTime != null) {
      _updatePresence();
    }
  }

  /// Resume playback (restore timestamp)
  Future<void> resumePlayback() async {
    if (_currentMetadata == null) return;

    // Reset start time for elapsed time display
    _playbackStartTime = DateTime.now();

    if (_isEnabled && _isConnected) {
      await _updatePresence();
    }
  }

  /// Pause - clear timestamp but keep showing what's playing
  Future<void> pausePlayback() async {
    // Clear start time so Discord stops counting
    _playbackStartTime = null;

    if (_isEnabled && _isConnected) {
      await _updatePresence();
    }
  }

  /// Stop showing presence when playback ends
  Future<void> stopPlayback() async {
    _currentMetadata = null;
    _currentClient = null;
    _playbackStartTime = null;
    _cachedThumbnailUrl = null;
    _playbackSpeed = 1.0;

    if (_isEnabled && _isConnected) {
      await clearPresence();
    }
  }

  /// Clear the presence
  Future<void> clearPresence() async {
    try {
      _rpc?.clearPresence();
    } catch (e) {
      appLogger.d('Failed to clear Discord presence', error: e);
    }
  }

  /// Dispose the service (call on app shutdown)
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _disconnect();
  }

  // Private methods

  Future<void> _connect() async {
    if (_rpc != null) return;

    try {
      _rpc = DiscordRPC();

      _readySubscription = _rpc!.onReady.listen((_) async {
        _isConnected = true;
        appLogger.i('Discord RPC connected');

        // Small delay to let Discord stabilize after connection
        await Future.delayed(const Duration(milliseconds: 200));

        // Update presence if we have active playback
        if (_currentMetadata != null) {
          await _uploadThumbnailAndUpdatePresence();
        }
      });

      _disconnectedSubscription = _rpc!.onDisconnected.listen((_) {
        _isConnected = false;
        appLogger.i('Discord RPC disconnected');
        _scheduleReconnect();
      });

      _errorSubscription = _rpc!.onError.listen((error) {
        appLogger.w('Discord RPC error: $error');
      });

      await _rpc!.initialize(_applicationId);
    } catch (e) {
      appLogger.w('Failed to initialize Discord RPC', error: e);
      // Clean up on failure so reconnect attempts can work
      await _readySubscription?.cancel();
      await _disconnectedSubscription?.cancel();
      await _errorSubscription?.cancel();
      _readySubscription = null;
      _disconnectedSubscription = null;
      _errorSubscription = null;
      try {
        _rpc?.dispose();
      } catch (_) {}
      _rpc = null;
      _scheduleReconnect();
    }
  }

  Future<void> _disconnect() async {
    _reconnectTimer?.cancel();
    _isConnected = false;

    await _readySubscription?.cancel();
    await _disconnectedSubscription?.cancel();
    await _errorSubscription?.cancel();
    _readySubscription = null;
    _disconnectedSubscription = null;
    _errorSubscription = null;

    try {
      _rpc?.dispose();
    } catch (e) {
      appLogger.d('Error disposing Discord RPC', error: e);
    }
    _rpc = null;
  }

  void _scheduleReconnect() {
    if (!_isEnabled) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), () {
      if (_isEnabled && !_isConnected) {
        _connect();
      }
    });
  }

  Future<void> _uploadThumbnailAndUpdatePresence() async {
    // Try to upload thumbnail, but don't block on failure
    if (_cachedThumbnailUrl == null && _currentMetadata != null && _currentClient != null) {
      _cachedThumbnailUrl = await _uploadThumbnail(_currentMetadata!, _currentClient!);
    }
    await _updatePresence();
  }

  Future<String?> _uploadThumbnail(PlexMetadata metadata, PlexClient client) async {
    try {
      // Get the thumbnail path (prefer show poster for episodes)
      final thumbPath = metadata.grandparentThumb ?? metadata.thumb;
      if (thumbPath == null || thumbPath.isEmpty) return null;

      // Check cache first (with expiry check)
      final cached = _litterboxCache[thumbPath];
      if (cached != null && !cached.isExpired) {
        appLogger.d('Using cached Litterbox URL for: $thumbPath');
        return cached.url;
      }

      // Get the full URL with auth token
      final imageUrl = client.getThumbnailUrl(thumbPath);
      if (imageUrl.isEmpty) return null;

      // Fetch image data
      final dio = Dio();
      final imageResponse = await dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 10)),
      );

      final imageBytes = imageResponse.data;
      if (imageBytes == null || imageBytes.isEmpty) return null;

      // Upload to Litterbox
      final formData = FormData.fromMap({
        'reqtype': 'fileupload',
        'time': '1h',
        'fileToUpload': MultipartFile.fromBytes(Uint8List.fromList(imageBytes), filename: 'thumbnail.jpg'),
      });

      final uploadResponse = await dio.post<String>(
        _litterboxUrl,
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );

      final uploadedUrl = uploadResponse.data?.trim();
      if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
        // Cache the URL with 1 hour expiry (matching Litterbox)
        _litterboxCache[thumbPath] = _CachedUrl(uploadedUrl, DateTime.now().add(const Duration(hours: 1)));
        appLogger.d('Uploaded and cached thumbnail: $uploadedUrl');
        return uploadedUrl;
      }
    } catch (e) {
      appLogger.d('Failed to upload thumbnail to Litterbox', error: e);
    }
    return null;
  }

  Future<void> _updatePresence() async {
    if (_rpc == null || !_isConnected || _currentMetadata == null) return;

    try {
      final metadata = _currentMetadata!;
      final details = _buildDetails(metadata);
      final state = _buildState(metadata);

      await _rpc!.setPresence(
        DiscordPresence(
          type: DiscordActivityType.watching,
          details: details,
          state: state,
          timestamps: _buildTimestamps(),
          statusDisplayType: DiscordStatusDisplayType.details,
          largeAsset: _cachedThumbnailUrl != null
              ? DiscordAsset(url: _cachedThumbnailUrl!, text: metadata.grandparentTitle ?? metadata.title)
              : null,
        ),
      );
    } catch (e) {
      appLogger.d('Failed to update Discord presence', error: e);
    }
  }

  /// Build timestamps for Discord progress bar
  DiscordTimestamps? _buildTimestamps() {
    // When paused, don't show timestamps (progress bar would be inaccurate)
    if (_playbackStartTime == null) return null;

    // If we have duration, show progress bar
    if (_mediaDuration != null) {
      final now = DateTime.now();
      final position = _currentPosition ?? Duration.zero;

      // Calculate remaining time accounting for playback speed
      final remainingDuration = _mediaDuration! - position;
      final adjustedRemaining = Duration(microseconds: (remainingDuration.inMicroseconds / _playbackSpeed).round());

      // Calculate total adjusted duration for progress bar
      final adjustedTotal = Duration(microseconds: (_mediaDuration!.inMicroseconds / _playbackSpeed).round());

      final effectiveEnd = now.add(adjustedRemaining);
      final effectiveStart = effectiveEnd.subtract(adjustedTotal);

      return DiscordTimestamps.range(effectiveStart, effectiveEnd);
    }

    // Fallback: just show elapsed time
    return DiscordTimestamps.started(_playbackStartTime!);
  }

  /// Build the main "details" line (first line of presence)
  String _buildDetails(PlexMetadata metadata) {
    switch (metadata.mediaType) {
      case PlexMediaType.movie:
        final year = metadata.year != null ? ' (${metadata.year})' : '';
        return metadata.title + year;

      case PlexMediaType.episode:
        // Show: "Show Name" or just episode title if no show name
        return metadata.grandparentTitle ?? metadata.title;

      default:
        return metadata.title;
    }
  }

  /// Build the "state" line (second line of presence)
  String? _buildState(PlexMetadata metadata) {
    switch (metadata.mediaType) {
      case PlexMediaType.episode:
        // Format: "S1 E5 - Episode Title"
        final season = metadata.parentIndex;
        final episode = metadata.index;
        if (season != null && episode != null) {
          return 'S$season E$episode - ${metadata.title}';
        }
        return metadata.title;

      case PlexMediaType.movie:
        return metadata.studio;

      default:
        return null;
    }
  }
}
