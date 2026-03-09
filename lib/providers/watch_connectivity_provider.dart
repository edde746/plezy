import 'package:flutter/foundation.dart';
import '../services/watch_connectivity_service.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';

/// Provider for Apple Watch connectivity
/// Manages the connection to the paired Apple Watch and handles
/// playback state synchronization
class WatchConnectivityProvider with ChangeNotifier {
  final WatchConnectivityService _service = WatchConnectivityService();
  
  PlexClient? _client;
  PlaybackStateProvider? _playbackState;
  PlexMetadata? _currentMetadata;
  bool _isPlaying = false;
  
  // Function to get OnDeck items when no queue is active
  Future<List<PlexMetadata>> Function()? onDeckProvider;
  
  WatchConnectivityProvider() {
    // Set up command handlers
    _service.onPlay = _handlePlay;
    _service.onPause = _handlePause;
    _service.onNext = _handleNext;
    _service.onPrevious = _handlePrevious;
    _service.onTransferToWatch = _handleTransferToWatch;
    _service.onRequestQueue = _getQueueForWatch;
    _service.onVolumeUp = _handleVolumeUp;
    _service.onVolumeDown = _handleVolumeDown;
    
    appLogger.d('[WatchProvider] Initialized');
  }
  
  // Callbacks to be set by the video player
  VoidCallback? onPlayRequested;
  VoidCallback? onPauseRequested;
  VoidCallback? onNextRequested;
  VoidCallback? onPreviousRequested;
  VoidCallback? onVolumeUpRequested;
  VoidCallback? onVolumeDownRequested;
  
  /// Set the Plex client for building URLs
  void setClient(PlexClient? client) {
    _client = client;
    _service.setClient(client);
    appLogger.d('[WatchProvider] Client set: ${client != null}');
  }
  
  /// Set the playback state provider for queue access
  void setPlaybackState(PlaybackStateProvider? playbackState) {
    _playbackState = playbackState;
    appLogger.d('[WatchProvider] PlaybackState set: ${playbackState != null}');
  }
  
  /// Update the current playing metadata
  void updateCurrentMetadata(PlexMetadata? metadata) {
    _currentMetadata = metadata;
    appLogger.d('[WatchProvider] Current metadata updated: ${metadata?.title}');
  }
  
  /// Update watch with current playback state
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required PlexMetadata metadata,
    Uint8List? albumArt,
    bool canGoNext = true,
    bool canGoPrevious = true,
    double? position,
    double? duration,
  }) async {
    _isPlaying = isPlaying;
    _currentMetadata = metadata;

    await _service.updatePlaybackState(
      isPlaying: isPlaying,
      title: metadata.title,
      artist: metadata.grandparentTitle ?? metadata.parentTitle,
      albumArt: albumArt,
      canGoNext: canGoNext,
      canGoPrevious: canGoPrevious,
      position: position,
      duration: duration,
    );
  }
  
  /// Clear playback state on the watch
  Future<void> clearPlaybackState() async {
    _currentMetadata = null;
    _isPlaying = false;
    await _service.clearPlaybackState();
  }
  
  /// Check if watch is connected
  Future<bool> isWatchConnected() => _service.isWatchConnected();
  
  /// Check if watch is paired
  Future<bool> isWatchPaired() => _service.isWatchPaired();
  
  // Private handlers
  void _handlePlay() {
    appLogger.d('[WatchProvider] Play requested');
    onPlayRequested?.call();
  }
  
  void _handlePause() {
    appLogger.d('[WatchProvider] Pause requested');
    onPauseRequested?.call();
  }
  
  void _handleNext() {
    appLogger.d('[WatchProvider] Next requested');
    onNextRequested?.call();
  }
  
  void _handlePrevious() {
    appLogger.d('[WatchProvider] Previous requested');
    onPreviousRequested?.call();
  }
  
  void _handleVolumeUp() {
    appLogger.d('[WatchProvider] Volume up requested');
    onVolumeUpRequested?.call();
  }

  void _handleVolumeDown() {
    appLogger.d('[WatchProvider] Volume down requested');
    onVolumeDownRequested?.call();
  }

  void _handleTransferToWatch() {
    print('[WATCH-PROVIDER] Transfer to watch requested!');
    appLogger.d('[WatchProvider] Transfer to watch requested');
    // The transfer is handled by onRequestQueue callback
  }
  
  /// Get the current queue to send to watch
  /// Returns (playQueueReference, previewItems)
  /// Priority:
  /// 1. Active play queue from PlaybackStateProvider (returns queue reference for direct Plex access)
  /// 2. Current metadata (single item)
  /// 3. OnDeck items
  Future<(WatchPlayQueueReference?, List<WatchQueueItem>)> _getQueueForWatch() async {
    print('[WATCH-PROVIDER] Getting queue for watch');
    print('[WATCH-PROVIDER] Client: ${_client != null}, PlaybackState: ${_playbackState != null}');
    
    // Use the client from PlaybackStateProvider if available (it knows the correct server)
    // Fall back to _client which is set from MainScreen
    final activeClient = _playbackState?.client ?? _client;
    
    if (activeClient == null) {
      print('[WATCH-PROVIDER] No client available');
      appLogger.w('[WatchProvider] No client available');
      return (null, <WatchQueueItem>[]);
    }
    
    final items = <WatchQueueItem>[];
    WatchPlayQueueReference? playQueueRef;
    
    // First, check if there's an active play queue
    if (_playbackState != null && _playbackState!.isQueueActive) {
      final playQueueId = _playbackState!.playQueueId;
      print('[WATCH-PROVIDER] Active play queue found, ID: $playQueueId');
      appLogger.d('[WatchProvider] Using active play queue: $playQueueId');
      
      if (playQueueId != null) {
        final queueClient = _playbackState!.client ?? activeClient;
        final token = queueClient.authToken;
        
        if (token != null) {
          // Create play queue reference for watch to use
          playQueueRef = WatchPlayQueueReference(
            playQueueId: playQueueId,
            plexServerUrl: queueClient.config.baseUrl,
            plexToken: token,
            currentIndex: 0, // Watch will start from the beginning
          );
          
          print('[WATCH-PROVIDER] Created play queue reference: $playQueueId at ${queueClient.config.baseUrl}');
          
          // Also get preview items for immediate display
          try {
            final playQueue = await queueClient.getPlayQueue(playQueueId);
            if (playQueue != null && playQueue.items != null && playQueue.items!.isNotEmpty) {
              print('[WATCH-PROVIDER] Got ${playQueue.items!.length} items from play queue for preview');
              
              // Convert to watch queue items (limit to 5 for payload size)
              for (var i = 0; i < playQueue.items!.length && i < 5; i++) {
                final item = await _createQueueItemFromMetadata(playQueue.items![i], client: queueClient);
                if (item != null) {
                  items.add(item);
                }
              }
            }
          } catch (e) {
            print('[WATCH-PROVIDER] Error getting play queue preview: $e');
            // Continue anyway - we have the queue reference
          }
          
          print('[WATCH-PROVIDER] Returning play queue ref with ${items.length} preview items');
          return (playQueueRef, items);
        }
      }
    }
    
    // If we have a current playing item, use that (no play queue reference)
    if (_currentMetadata != null) {
      print('[WATCH-PROVIDER] Using current metadata: ${_currentMetadata!.title}');
      appLogger.d('[WatchProvider] Using current metadata: ${_currentMetadata!.title}');
      final item = await _createQueueItemFromMetadata(_currentMetadata!, client: activeClient);
      if (item != null) {
        items.add(item);
      }
    }
    
    // If no current item, try to get OnDeck items
    if (items.isEmpty && onDeckProvider != null) {
      print('[WATCH-PROVIDER] Fetching OnDeck items');
      appLogger.d('[WatchProvider] Fetching OnDeck items');
      try {
        final onDeckItems = await onDeckProvider!();
        print('[WATCH-PROVIDER] Got ${onDeckItems.length} OnDeck items');
        appLogger.d('[WatchProvider] Got ${onDeckItems.length} OnDeck items');
        
        // Take first few OnDeck items (limit to 5)
        for (var i = 0; i < onDeckItems.length && i < 5; i++) {
          final item = await _createQueueItemFromMetadata(onDeckItems[i], client: activeClient);
          if (item != null) {
            items.add(item);
          }
        }
      } catch (e) {
        print('[WATCH-PROVIDER] Failed to get OnDeck: $e');
        appLogger.w('[WatchProvider] Failed to get OnDeck items', error: e);
      }
    }
    
    // If still no items, try to get the client's OnDeck directly
    if (items.isEmpty) {
      print('[WATCH-PROVIDER] Fetching OnDeck directly from client');
      appLogger.d('[WatchProvider] Fetching OnDeck directly from client');
      try {
        final onDeckItems = await activeClient.getOnDeck();
        print('[WATCH-PROVIDER] Got ${onDeckItems.length} OnDeck items from client');
        appLogger.d('[WatchProvider] Got ${onDeckItems.length} OnDeck items from client');
        
        for (var i = 0; i < onDeckItems.length && i < 5; i++) {
          final item = await _createQueueItemFromMetadata(onDeckItems[i], client: activeClient);
          if (item != null) {
            items.add(item);
          }
        }
      } catch (e) {
        print('[WATCH-PROVIDER] Failed to get OnDeck from client: $e');
        appLogger.w('[WatchProvider] Failed to get OnDeck from client', error: e);
      }
    }
    
    print('[WATCH-PROVIDER] Returning ${items.length} queue items (no play queue ref)');
    appLogger.d('[WatchProvider] Returning ${items.length} queue items');
    return (null, items);
  }
  
  /// Create a WatchQueueItem from PlexMetadata
  /// Returns null for non-audio items (movies, episodes, etc.) since the watch can only play audio
  Future<WatchQueueItem?> _createQueueItemFromMetadata(
    PlexMetadata metadata, {
    PlexClient? client,
  }) async {
    // Watch can only play audio — skip video content entirely
    if (metadata.mediaType.isVideo) {
      appLogger.d('[WatchProvider] Skipping video item: ${metadata.title} (${metadata.type})');
      return null;
    }

    final useClient = client ?? _client;
    if (useClient == null) return null;

    // Get the direct stream URL
    final streamUrl = await useClient.getDirectStreamUrl(metadata.ratingKey);
    if (streamUrl == null) {
      appLogger.w('[WatchProvider] No stream URL for ${metadata.title}');
      return null;
    }
    
    final token = useClient.authToken;
    if (token == null) {
      appLogger.w('[WatchProvider] No auth token');
      return null;
    }
    
    // Build album art URL
    String? albumArtUrl;
    if (metadata.thumb != null) {
      albumArtUrl = useClient.getThumbnailUrl(metadata.thumb!);
    }
    
    return WatchQueueItem(
      id: metadata.ratingKey,
      title: metadata.title,
      artist: metadata.grandparentTitle ?? metadata.parentTitle,
      albumArtUrl: albumArtUrl,
      streamUrl: streamUrl,
      plexToken: token,
      duration: (metadata.duration ?? 0) / 1000.0,
    );
  }
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
