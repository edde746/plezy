import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/plex_url_helper.dart';
import 'plex_client.dart';

/// Service for syncing Plex "On Deck" content to Android TV's Watch Next row.
/// This allows users to resume content directly from the Android TV launcher.
class WatchNextService {
  static const MethodChannel _channel = MethodChannel('app.plezy/watch_next');

  // Singleton instance
  static final WatchNextService _instance = WatchNextService._internal();
  factory WatchNextService() => _instance;

  WatchNextService._internal() {
    // Listen for callbacks from native Android (deep link taps)
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Callback for when a Watch Next item is tapped.
  /// The contentId format is: plezy_{serverId}_{ratingKey}
  ValueChanged<String>? onWatchNextTap;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWatchNextTap':
        final contentId = call.arguments['contentId'] as String?;
        if (contentId != null) {
          appLogger.d('Watch Next tap received: $contentId');
          onWatchNextTap?.call(contentId);
        }
        break;
    }
  }

  /// Check if Watch Next is supported (Android TV only).
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e) {
      appLogger.w('Failed to check Watch Next support', error: e);
      return false;
    }
  }

  /// Sync On Deck items to Watch Next row.
  /// Call this after fetching On Deck data on Android TV.
  ///
  /// [onDeckItems] - List of PlexMetadata items from On Deck
  /// [getClientForServerId] - Function to get PlexClient for a given server ID
  Future<bool> syncFromOnDeck(
    List<PlexMetadata> onDeckItems,
    PlexClient Function(String serverId) getClientForServerId,
  ) async {
    if (!Platform.isAndroid) return false;

    try {
      // Check if supported first
      final supported = await isSupported();
      if (!supported) {
        appLogger.d('Watch Next not supported on this device');
        return false;
      }

      // Convert PlexMetadata items to Watch Next format
      final items = onDeckItems.map((item) {
        return _convertToWatchNextItem(item, getClientForServerId);
      }).toList();

      appLogger.d('Syncing ${items.length} items to Watch Next');

      final success = await _channel.invokeMethod<bool>('sync', {'items': items}) ?? false;

      if (success) {
        appLogger.d('Watch Next sync completed successfully');
      } else {
        appLogger.w('Watch Next sync returned false');
      }

      return success;
    } catch (e) {
      appLogger.e('Failed to sync Watch Next', error: e);
      return false;
    }
  }

  /// Clear all Watch Next entries.
  Future<bool> clear() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('clear') ?? false;
    } catch (e) {
      appLogger.e('Failed to clear Watch Next', error: e);
      return false;
    }
  }

  /// Remove a single item from Watch Next.
  Future<bool> removeItem(String serverId, String ratingKey) async {
    if (!Platform.isAndroid) return false;

    try {
      final contentId = _buildContentId(serverId, ratingKey);
      return await _channel.invokeMethod<bool>('remove', {'contentId': contentId}) ?? false;
    } catch (e) {
      appLogger.e('Failed to remove Watch Next item', error: e);
      return false;
    }
  }

  /// Build a content ID for Watch Next.
  /// Format: plezy_{serverId}_{ratingKey}
  static String _buildContentId(String? serverId, String ratingKey) {
    final safeServerId = serverId ?? 'unknown';
    return 'plezy_${safeServerId}_$ratingKey';
  }

  /// Parse a content ID back to server ID and rating key.
  /// Returns (serverId, ratingKey) or null if invalid.
  static (String serverId, String ratingKey)? parseContentId(String contentId) {
    if (!contentId.startsWith('plezy_')) return null;

    final parts = contentId.substring(6).split('_');
    if (parts.length < 2) return null;

    // The rating key might contain underscores, so rejoin everything after server ID
    final serverId = parts[0];
    final ratingKey = parts.sublist(1).join('_');

    return (serverId, ratingKey);
  }

  /// Convert PlexMetadata to Watch Next item format.
  Map<String, dynamic> _convertToWatchNextItem(
    PlexMetadata item,
    PlexClient Function(String serverId) getClientForServerId,
  ) {
    final contentId = _buildContentId(item.serverId, item.ratingKey);

    // Get poster URL with auth token
    String? posterUri;
    try {
      if (item.serverId != null) {
        final client = getClientForServerId(item.serverId!);
        // Use grandparent thumb for episodes (show poster), or thumb for movies
        final thumbPath = item.grandparentThumb ?? item.thumb;
        if (thumbPath != null) {
          posterUri = client.getThumbnailUrl(thumbPath);
        }
      }
    } catch (e) {
      appLogger.w('Failed to get poster URL for Watch Next: ${item.title}', error: e);
    }

    // For episodes, create a display title that includes the show name
    String title;
    if (item.mediaType == PlexMediaType.episode && item.grandparentTitle != null) {
      if (item.parentIndex != null && item.index != null) {
        title = '${item.grandparentTitle} - S${item.parentIndex}:E${item.index}';
      } else {
        title = '${item.grandparentTitle} - ${item.title}';
      }
    } else {
      title = item.title;
    }

    // Calculate last engagement time (when the item was last watched)
    // Use lastViewedAt if available, otherwise use current time
    final lastEngagementTime = item.lastViewedAt != null
        ? item.lastViewedAt! *
              1000 // Convert seconds to milliseconds
        : DateTime.now().millisecondsSinceEpoch;

    return {
      'contentId': contentId,
      'title': title,
      'description': item.summary,
      'posterUri': posterUri,
      'type': item.type.toLowerCase(),
      'duration': item.duration ?? 0,
      'lastPlaybackPosition': item.viewOffset ?? 0,
      'lastEngagementTime': lastEngagementTime,
      'seriesTitle': item.grandparentTitle,
      'seasonNumber': item.parentIndex,
      'episodeNumber': item.index,
    };
  }
}

/// Extension on PlexMetadata for Watch Next convenience methods.
extension WatchNextMetadataExtension on PlexMetadata {
  /// Get the Watch Next content ID for this item.
  String get watchNextContentId => WatchNextService._buildContentId(serverId, ratingKey);
}
