import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';

/// Represents a queue item to send to the watch (for preview/immediate display)
class WatchQueueItem {
  final String id;
  final String title;
  final String? artist;
  final String? albumArtUrl;
  final String streamUrl;
  final String plexToken;
  final double duration;

  WatchQueueItem({
    required this.id,
    required this.title,
    this.artist,
    this.albumArtUrl,
    required this.streamUrl,
    required this.plexToken,
    required this.duration,
  });

  /// Convert to a map for sending to watch
  /// WatchConnectivity only supports: String, Number, Data, Date, Array, Dictionary
  /// Null values are NOT supported, so we filter them out
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'streamUrl': streamUrl,
      'plexToken': plexToken,
      'duration': duration,
    };
    // Only add optional fields if they're not null
    if (artist != null) map['artist'] = artist!;
    if (albumArtUrl != null) map['albumArtUrl'] = albumArtUrl!;
    return map;
  }
}

/// Represents a Plex play queue reference to send to the watch
/// The watch can use this to fetch the full queue directly from Plex
class WatchPlayQueueReference {
  final int playQueueId;
  final String plexServerUrl;
  final String plexToken;
  final int? currentIndex;
  
  WatchPlayQueueReference({
    required this.playQueueId,
    required this.plexServerUrl,
    required this.plexToken,
    this.currentIndex,
  });
  
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'playQueueId': playQueueId,
      'plexServerUrl': plexServerUrl,
      'plexToken': plexToken,
    };
    if (currentIndex != null) map['currentIndex'] = currentIndex!;
    return map;
  }
}

/// Service for communicating with Apple Watch companion app.
///
/// Handles:
/// - Sending playback state updates to the watch
/// - Receiving playback commands from the watch
/// - Transferring queue data for local watch playback
class WatchConnectivityService {
  static const _channel = MethodChannel('com.edde746.plezy/watch');

  // Callbacks for watch commands
  Function()? onPlay;
  Function()? onPause;
  Function()? onNext;
  Function()? onPrevious;
  Function()? onTransferToWatch;
  Function()? onVolumeUp;
  Function()? onVolumeDown;

  // Queue provider callback - called when watch requests queue transfer
  // Returns (playQueueReference, previewItems) - preference is to use play queue reference
  Future<(WatchPlayQueueReference?, List<WatchQueueItem>)> Function()? onRequestQueue;

  // Client reference for building URLs
  PlexClient? _client;

  WatchConnectivityService() {
    print('[WATCH] WatchConnectivityService constructor - Platform.isIOS: ${Platform.isIOS}');
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
      print('[WATCH] WatchConnectivityService method channel handler set up');
      appLogger.d('[Watch] WatchConnectivityService initialized');
    }
  }

  void setClient(PlexClient? client) {
    _client = client;
    appLogger.d('[Watch] Client set: ${client != null}');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('[WATCH] Received method call: ${call.method}');
    appLogger.d('[Watch] Received method call: ${call.method}');
    
    switch (call.method) {
      case 'onWatchCommand':
        final args = call.arguments as Map<dynamic, dynamic>;
        final command = args['command'] as String?;
        print('[WATCH] Command from watch: $command');
        appLogger.d('[Watch] Command from watch: $command');
        await _handleCommand(command);
        break;
      case 'getCredentials':
        return _getCredentials();
    }
  }

  Future<void> _handleCommand(String? command) async {
    if (command == null) return;

    appLogger.d('[Watch] Processing command: $command');

    switch (command) {
      case 'play':
        onPlay?.call();
        break;
      case 'pause':
        onPause?.call();
        break;
      case 'next':
        onNext?.call();
        break;
      case 'previous':
        onPrevious?.call();
        break;
      case 'transferToWatch':
        appLogger.d('[Watch] Transfer to watch requested');
        await _handleTransferToWatch();
        break;
      case 'volumeUp':
        appLogger.d('[Watch] Volume up requested');
        onVolumeUp?.call();
        break;
      case 'volumeDown':
        appLogger.d('[Watch] Volume down requested');
        onVolumeDown?.call();
        break;
    }
  }

  Map<String, String>? _getCredentials() {
    if (_client != null && _client!.authToken != null) {
      return {
        'serverUrl': _client!.config.baseUrl,
        'token': _client!.authToken!,
      };
    }
    return null;
  }

  Future<void> _handleTransferToWatch() async {
    print('[WATCH] _handleTransferToWatch called');
    onTransferToWatch?.call();

    // Get queue from provider
    if (onRequestQueue != null) {
      try {
        print('[WATCH] Calling onRequestQueue callback');
        appLogger.d('[Watch] Calling onRequestQueue callback');
        final (playQueueRef, queueItems) = await onRequestQueue!();
        
        // Prefer sending play queue reference (watch can fetch from Plex directly)
        if (playQueueRef != null) {
          print('[WATCH] Got play queue reference: ${playQueueRef.playQueueId}');
          appLogger.d('[Watch] Sending play queue reference: ${playQueueRef.playQueueId}');
          await sendPlayQueueReferenceToWatch(playQueueRef, previewItems: queueItems);
        } else if (queueItems.isNotEmpty) {
          // Fallback to individual items if no play queue
          print('[WATCH] Got ${queueItems.length} queue items (no play queue)');
          appLogger.d('[Watch] Sending ${queueItems.length} items (fallback mode)');
          await sendQueueToWatch(queueItems, currentIndex: 0);
        } else {
          // Send error response
          print('[WATCH] No content available to play');
          await _sendErrorToWatch('No content available to play');
        }
      } catch (e) {
        print('[WATCH] Failed to get queue: $e');
        appLogger.w('[Watch] Failed to get queue for watch transfer', error: e);
        await _sendErrorToWatch('Failed to load content');
      }
    } else {
      print('[WATCH] No onRequestQueue callback set');
      appLogger.w('[Watch] No onRequestQueue callback set');
      await _sendErrorToWatch('App not ready');
    }
  }

  Future<void> _sendErrorToWatch(String message) async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('sendQueueToWatch', {
        'error': message,
      });
    } catch (e) {
      appLogger.w('[Watch] Failed to send error to watch', error: e);
    }
  }

  /// Update the watch with current playback state
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required String title,
    String? artist,
    Uint8List? albumArt,
    bool canGoNext = true,
    bool canGoPrevious = true,
    double? position,
    double? duration,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final state = <String, dynamic>{
        'isPlaying': isPlaying,
        'title': title,
        'artist': artist,
        'canGoNext': canGoNext,
        'canGoPrevious': canGoPrevious,
      };

      if (albumArt != null) {
        state['albumArt'] = albumArt;
      }
      if (position != null) {
        state['position'] = position;
      }
      if (duration != null) {
        state['duration'] = duration;
      }

      await _channel.invokeMethod('updatePlaybackState', state);
    } catch (e) {
      appLogger.w('[Watch] Failed to update watch playback state', error: e);
    }
  }

  /// Send play queue reference to watch (preferred method)
  /// The watch can use this to fetch the queue directly from Plex
  Future<void> sendPlayQueueReferenceToWatch(
    WatchPlayQueueReference queueRef, {
    List<WatchQueueItem>? previewItems,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final payload = <String, dynamic>{
        'playQueueRef': queueRef.toMap(),
      };
      
      // Add preview items (first few items for immediate display)
      if (previewItems != null && previewItems.isNotEmpty) {
        final limitedPreview = previewItems.take(5).toList();
        payload['queue'] = limitedPreview.map((item) => item.toMap()).toList();
        payload['currentIndex'] = queueRef.currentIndex ?? 0;
      }

      print('[WATCH] Sending play queue ref ${queueRef.playQueueId} to watch');
      appLogger.d('[Watch] Sending play queue ref ${queueRef.playQueueId}');
      
      await _channel.invokeMethod('sendQueueToWatch', payload);
      print('[WATCH] Play queue reference sent successfully');
      appLogger.d('[Watch] Play queue reference sent successfully');
    } catch (e) {
      print('[WATCH] Failed to send play queue reference: $e');
      appLogger.w('[Watch] Failed to send play queue reference', error: e);
    }
  }

  /// Send queue to watch for local playback (fallback when no play queue)
  Future<void> sendQueueToWatch(
    List<WatchQueueItem> items, {
    int currentIndex = 0,
  }) async {
    if (!Platform.isIOS) return;

    try {
      // Limit to first 5 items to reduce payload size
      // WatchConnectivity has ~65KB limit for interactive messages
      final limitedItems = items.take(5).toList();
      
      final queueData = <String, dynamic>{
        'queue': limitedItems.map((item) => item.toMap()).toList(),
        'currentIndex': currentIndex,
      };

      // Log approximate payload size
      final jsonStr = queueData.toString();
      print('[WATCH] Sending ${limitedItems.length} items to watch (approx ${jsonStr.length} bytes)');
      appLogger.d('[Watch] Sending ${limitedItems.length} items to watch');
      
      await _channel.invokeMethod('sendQueueToWatch', queueData);
      print('[WATCH] Queue sent successfully');
      appLogger.d('[Watch] Queue sent successfully');
    } catch (e) {
      print('[WATCH] Failed to send queue: $e');
      appLogger.w('[Watch] Failed to send queue to watch', error: e);
    }
  }

  /// Create a WatchQueueItem from PlexMetadata
  Future<WatchQueueItem?> createQueueItem(PlexMetadata metadata, PlexClient client) async {
    // Get the direct stream URL
    final streamUrl = await client.getDirectStreamUrl(metadata.ratingKey);
    if (streamUrl == null) {
      appLogger.w('[Watch] Could not get stream URL for ${metadata.title}');
      return null;
    }

    final token = client.authToken;
    if (token == null) {
      appLogger.w('[Watch] No auth token available');
      return null;
    }

    // Build album art URL
    String? albumArtUrl;
    if (metadata.thumb != null) {
      albumArtUrl = client.getThumbnailUrl(metadata.thumb!);
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

  /// Clear playback state on the watch (when playback stops)
  Future<void> clearPlaybackState() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('clearPlaybackState');
    } catch (e) {
      appLogger.w('[Watch] Failed to clear watch playback state', error: e);
    }
  }

  /// Check if Apple Watch is connected
  Future<bool> isWatchConnected() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isWatchConnected') ?? false;
      appLogger.d('[Watch] isWatchConnected: $result');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Check if Apple Watch is paired
  Future<bool> isWatchPaired() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isWatchPaired') ?? false;
      appLogger.d('[Watch] isWatchPaired: $result');
      return result;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    onPlay = null;
    onPause = null;
    onNext = null;
    onPrevious = null;
    onTransferToWatch = null;
    onRequestQueue = null;
    onVolumeUp = null;
    onVolumeDown = null;
  }
}
