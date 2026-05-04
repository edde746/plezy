import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:http/http.dart' as http;

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/future_extensions.dart';
import '../utils/platform_detector.dart';
import '../utils/media_server_http_client.dart';
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

  /// Cache of thumbnail paths to Litterbox URLs with expiry (1 hour). Keyed
  /// by `<backendId>:<thumbPath>` so the same path on different backends
  /// doesn't collide.
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
  MediaItem? _currentMetadata;
  MediaServerClient? _currentClient;
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

  static bool get isAvailable {
    if (!PlatformDetector.isDesktopOS()) {
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
    _isEnabled = settings.read(SettingsService.enableDiscordRPC);

    if (_isEnabled) {
      await _connect();
    }
  }

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

  /// Start showing presence for media playback. Works for any backend —
  /// thumbnail upload uses the neutral [MediaServerClient.thumbnailUrl] /
  /// [MediaServerClient.streamHeaders] surface.
  Future<void> startPlayback(MediaItem metadata, MediaServerClient client) async {
    _currentMetadata = metadata;
    _currentClient = client;
    _playbackStartTime = DateTime.now();
    _mediaDuration = metadata.durationMs != null ? Duration(milliseconds: metadata.durationMs!) : null;
    _currentPosition = Duration.zero;
    _cachedThumbnailUrl = null;
    _playbackSpeed = 1.0;

    if (_isEnabled && _isConnected) {
      // Upload thumbnail in background, don't block playback
      unawaited(_uploadThumbnailAndUpdatePresence());
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

  Future<void> clearPresence() async {
    try {
      unawaited(_rpc?.clearPresence());
    } catch (e) {
      appLogger.d('Failed to clear Discord presence', error: e);
    }
  }

  /// Dispose the service (call on app shutdown)
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _disconnect();
  }

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
        unawaited(_rpc?.dispose());
      } catch (e) {
        appLogger.d('DiscordRPC: dispose ignored', error: e);
      }
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
      unawaited(_rpc?.dispose());
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

  Future<String?> _uploadThumbnail(MediaItem metadata, MediaServerClient client) async {
    try {
      // Get the thumbnail path (prefer show poster for episodes)
      final thumbPath = metadata.grandparentThumbPath ?? metadata.thumbPath;
      if (thumbPath == null || thumbPath.isEmpty) return null;

      // Check cache first (with expiry check). Key by backend so the same
      // path on Plex and Jellyfin doesn't collide.
      final cacheKey = '${client.backend.id}:$thumbPath';
      final cached = _litterboxCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        appLogger.d('Using cached Litterbox URL for: $cacheKey');
        return cached.url;
      }

      // Build the image URL. Both backends embed auth in the URL — Plex via
      // `?X-Plex-Token=...`, Jellyfin via `?api_key=...` — so no extra
      // headers are needed for the fetch below. We still pass [streamHeaders]
      // for Plex installs that prefer header-based auth.
      final imageUrl = client.thumbnailUrl(thumbPath);
      if (imageUrl.isEmpty) return null;

      final imageBytes = await httpClient.getBytes(
        imageUrl,
        headers: client.streamHeaders,
        timeout: const Duration(seconds: 10),
      );
      if (imageBytes.isEmpty) return null;

      final uploadRequest = http.MultipartRequest('POST', Uri.parse(_litterboxUrl))
        ..fields['reqtype'] = 'fileupload'
        ..fields['time'] = '1h'
        ..files.add(http.MultipartFile.fromBytes('fileToUpload', imageBytes, filename: 'thumbnail.jpg'));

      final uploadStreamed = await httpClient.inner
          .send(uploadRequest)
          .namedTimeout(const Duration(seconds: 15), operation: 'Litterbox upload');
      final uploadedUrl = (await uploadStreamed.stream.bytesToString()).trim();

      if (uploadedUrl.startsWith('http')) {
        // Cache the URL with 1 hour expiry (matching Litterbox)
        _litterboxCache[cacheKey] = _CachedUrl(uploadedUrl, DateTime.now().add(const Duration(hours: 1)));
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
              ? DiscordAsset(url: _cachedThumbnailUrl!, text: metadata.grandparentTitle ?? metadata.title ?? '')
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
  String _buildDetails(MediaItem metadata) {
    switch (metadata.kind) {
      case MediaKind.movie:
        final year = metadata.year != null ? ' (${metadata.year})' : '';
        return (metadata.title ?? '') + year;

      case MediaKind.episode:
        // Show: "Show Name" or just episode title if no show name
        return metadata.grandparentTitle ?? metadata.title ?? '';

      default:
        return metadata.title ?? '';
    }
  }

  /// Build the "state" line (second line of presence)
  String? _buildState(MediaItem metadata) {
    switch (metadata.kind) {
      case MediaKind.episode:
        // Format: "S1 E5 - Episode Title"
        final season = metadata.parentIndex;
        final episode = metadata.index;
        if (season != null && episode != null) {
          return 'S$season E$episode - ${metadata.title ?? ''}';
        }
        return metadata.title;

      case MediaKind.movie:
        return metadata.studio;

      default:
        return null;
    }
  }
}
