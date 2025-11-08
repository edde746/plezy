import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'media_kit_audio_handler.dart';
import '../utils/app_logger.dart';

/// Singleton manager for OS media controls integration
/// Manages a single AudioHandler instance for the entire app lifecycle
class MediaServiceManager {
  static MediaServiceManager? _instance;
  static MediaKitAudioHandler? _audioHandler;
  static bool _isInitialized = false;

  MediaServiceManager._();

  static MediaServiceManager get instance {
    _instance ??= MediaServiceManager._();
    return _instance!;
  }

  /// Initialize the audio service once at app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      appLogger.w('MediaServiceManager already initialized');
      return;
    }

    try {
      appLogger.i('Initializing MediaServiceManager');

      _audioHandler = await AudioService.init(
        builder: () => MediaKitAudioHandler(
          player: null, // Will be set when first video plays
          onNext: null,
          onPrevious: null,
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.plezy.app.channel.audio',
          androidNotificationChannelName: 'Plezy Playback',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'drawable/ic_stat_notification',
          // Configure audio session for proper media playback
          preloadArtwork: true,
        ),
      );

      _isInitialized = true;
      appLogger.i('MediaServiceManager initialized successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        '❌ Failed to initialize MediaServiceManager',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal, app can continue without OS media controls
    }
  }

  /// Update the audio handler with a new player and callbacks
  Future<void> updatePlayer({
    required Player? player,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) async {
    if (!_isInitialized || _audioHandler == null) {
      appLogger.w('MediaServiceManager not initialized, cannot update player');
      return;
    }

    try {
      await _audioHandler!.updatePlayer(
        player: player,
        onNext: onNext,
        onPrevious: onPrevious,
      );
    } catch (e) {
      appLogger.e('Failed to update player', error: e);
    }
  }

  /// Stop playback and clear OS controls
  Future<void> stop() async {
    if (_audioHandler == null) return;

    try {
      await _audioHandler!.stop();
    } catch (e) {
      appLogger.e('Failed to stop audio service', error: e);
    }
  }

  /// Update the media item shown in OS controls
  void updateMediaItem(dynamic metadata, String? thumbnailUrl) {
    if (_audioHandler == null) return;

    try {
      _audioHandler!.setMediaItemFromMetadata(metadata, thumbnailUrl);
    } catch (e) {
      appLogger.e('Failed to update media item', error: e);
    }
  }

  /// Update navigation actions availability
  void updateNavigationActions({bool? hasNext, bool? hasPrevious}) {
    _audioHandler?.updateNavigationActions(
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  /// Force an immediate state update to trigger notification
  /// Call this after playback starts to ensure Android shows the notification
  void forceStateUpdate() {
    _audioHandler?.forceStateUpdate();
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the audio handler (for advanced usage)
  MediaKitAudioHandler? get audioHandler => _audioHandler;
}
