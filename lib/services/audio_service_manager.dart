import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import 'media_kit_audio_handler.dart';

/// Global singleton manager for audio service
/// Ensures AudioService.init() is only called once and the handler is reused
class AudioServiceManager {
  static AudioServiceManager? _instance;
  MediaKitAudioHandler? _handler;
  bool _isInitialized = false;
  bool _isInitializing = false;

  AudioServiceManager._();

  static AudioServiceManager get instance {
    _instance ??= AudioServiceManager._();
    return _instance!;
  }

  /// Initialize the audio service with the given player and configuration
  /// This should only be called once - subsequent calls will reuse the existing handler
  Future<void> initialize({
    required Player player,
    required String plexServerUrl,
    required String authToken,
    Future<void> Function()? onSkipToNext,
    Future<void> Function()? onSkipToPrevious,
  }) async {
    // If already initialized, update the player reference and callbacks
    if (_isInitialized && _handler != null) {
      appLogger.d('Audio service already initialized, updating player reference and callbacks');

      // Update the player reference (critical for episode switching)
      await _handler!.updatePlayer(player);

      // Update navigation callbacks
      _handler!.onSkipToNext = onSkipToNext;
      _handler!.onSkipToPrevious = onSkipToPrevious;

      return;
    }

    // Prevent concurrent initialization
    if (_isInitializing) {
      appLogger.d('Audio service initialization already in progress, waiting...');
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    try {
      _isInitializing = true;
      appLogger.d('Initializing audio service for the first time');

      final handler = await AudioService.init(
        builder: () => MediaKitAudioHandler(
          player: player,
          plexServerUrl: plexServerUrl,
          authToken: authToken,
          onSkipToNext: onSkipToNext,
          onSkipToPrevious: onSkipToPrevious,
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.edde746.plezy.audio',
          androidNotificationChannelName: 'Plezy Playback',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
        ),
      );

      _handler = handler;
      _isInitialized = true;
      appLogger.d('Audio service initialized successfully');
    } catch (e) {
      appLogger.e('Failed to initialize audio service', error: e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Update the current media item being played
  void updateMediaItem(PlexMetadata metadata) {
    if (_handler == null) {
      appLogger.w('Cannot update media item: audio handler not initialized');
      return;
    }
    _handler!.updateCurrentMediaItem(metadata);
  }

  /// Update navigation callbacks for next/previous episode
  void updateNavigation({
    Future<void> Function()? onNext,
    Future<void> Function()? onPrevious,
  }) {
    if (_handler == null) {
      appLogger.w('Cannot update navigation: audio handler not initialized');
      return;
    }
    _handler!.updateNavigationCallbacks(
      onNext: onNext,
      onPrevious: onPrevious,
    );
  }

  /// Pause playback but keep the media session active
  Future<void> pause() async {
    if (_handler == null) {
      appLogger.w('Cannot pause: audio handler not initialized');
      return;
    }
    await _handler!.pause();
  }

  /// Clear the notification but keep the audio service singleton alive
  /// This is used when exiting the video player but not closing the app
  Future<void> clearNotification() async {
    if (_handler == null) {
      appLogger.w('Cannot clear notification: audio handler not initialized');
      return;
    }

    appLogger.d('Clearing notification while keeping audio service alive');

    // Broadcast idle state to remove notification
    _handler!.playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
      controls: [],
      systemActions: const {},
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));

    // Clear media item
    _handler!.mediaItem.add(null);

    // IMPORTANT: DON'T reset _isInitialized or _handler
    // Keep the singleton alive for next playback

    appLogger.d('Notification cleared, audio service remains initialized');
  }

  /// Stop playback completely and remove the notification
  /// This should only be called when the app is closing or user explicitly stops
  Future<void> shutdown() async {
    if (_handler == null) {
      appLogger.w('Cannot shutdown: audio handler not initialized');
      return;
    }

    appLogger.d('Shutting down audio service and removing notification');

    // Broadcast idle state to remove notification
    _handler!.playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
      controls: [],
      systemActions: const {},
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));

    // Clear media item
    _handler!.mediaItem.add(null);

    // Dispose the handler
    await _handler!.dispose();

    _handler = null;
    _isInitialized = false;
    appLogger.d('Audio service shutdown complete');
  }

  /// Check if the audio service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current handler (for advanced use cases)
  MediaKitAudioHandler? get handler => _handler;
}
