import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';

import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import 'plex_client.dart';
import 'settings_service.dart' show EpisodePosterMode;

/// Service for syncing Plex "On Deck" content to Android TV's Watch Next row.
class WatchNextService {
  static const MethodChannel _channel = MethodChannel('app.plezy/watch_next');

  static final WatchNextService _instance = WatchNextService._internal();
  factory WatchNextService() => _instance;

  WatchNextService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Callback for when a Watch Next item is tapped (warm start deep link).
  ValueChanged<String>? onWatchNextTap;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onWatchNextTap') {
      final contentId = call.arguments['contentId'] as String?;
      if (contentId != null) {
        onWatchNextTap?.call(contentId);
      }
    }
  }

  /// Get a pending deep link from cold start (consumed on first call).
  Future<String?> getInitialDeepLink() async {
    if (!AppPlatform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialDeepLink');
    } catch (e) {
      appLogger.w('Failed to get initial deep link', error: e);
      return null;
    }
  }

  /// Check if Watch Next is supported (Android TV only).
  Future<bool> isSupported() async {
    if (!AppPlatform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sync On Deck items to Watch Next row.
  Future<bool> syncFromOnDeck(
    List<PlexMetadata> onDeckItems,
    PlexClient Function(String serverId) getClientForServerId,
  ) async {
    if (!AppPlatform.isAndroid) return false;

    try {
      final supported = await isSupported();
      if (!supported) return false;

      final items = onDeckItems.map((item) {
        return _convertToWatchNextItem(item, getClientForServerId);
      }).toList();

      return await _channel.invokeMethod<bool>('sync', {'items': items}) ?? false;
    } catch (e) {
      appLogger.e('Failed to sync Watch Next', error: e);
      return false;
    }
  }

  /// Clear all Watch Next entries.
  Future<bool> clear() async {
    if (!AppPlatform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('clear') ?? false;
    } catch (e) {
      appLogger.e('Failed to clear Watch Next', error: e);
      return false;
    }
  }

  /// Remove a single item from Watch Next.
  Future<bool> removeItem(String serverId, String ratingKey) async {
    if (!AppPlatform.isAndroid) return false;
    try {
      final contentId = _buildContentId(serverId, ratingKey);
      return await _channel.invokeMethod<bool>('remove', {'contentId': contentId}) ?? false;
    } catch (e) {
      appLogger.e('Failed to remove Watch Next item', error: e);
      return false;
    }
  }

  /// Build a content ID. Format: plezy_{serverId}_{ratingKey}
  static String _buildContentId(String? serverId, String ratingKey) {
    return 'plezy_${serverId ?? 'unknown'}_$ratingKey';
  }

  /// Parse a content ID back to (serverId, ratingKey), or null if invalid.
  static (String serverId, String ratingKey)? parseContentId(String contentId) {
    if (!contentId.startsWith('plezy_')) return null;
    final parts = contentId.substring(6).split('_');
    if (parts.length < 2) return null;
    return (parts[0], parts.sublist(1).join('_'));
  }

  Map<String, dynamic> _convertToWatchNextItem(
    PlexMetadata item,
    PlexClient Function(String serverId) getClientForServerId,
  ) {
    final contentId = _buildContentId(item.serverId, item.ratingKey);

    String? posterUri;
    try {
      if (item.serverId != null) {
        final client = getClientForServerId(item.serverId!);
        final thumbPath = item.posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true);
        if (thumbPath != null) {
          posterUri = client.getThumbnailUrl(thumbPath);
        }
      }
    } catch (e) {
      appLogger.w('Failed to get poster URL for Watch Next: ${item.title}', error: e);
    }

    final String title;
    final String? episodeTitle;
    if (item.mediaType == PlexMediaType.episode && item.grandparentTitle != null) {
      title = item.grandparentTitle!;
      episodeTitle = item.title;
    } else {
      title = item.title;
      episodeTitle = null;
    }

    final lastEngagementTime = item.lastViewedAt != null
        ? item.lastViewedAt! * 1000
        : DateTime.now().millisecondsSinceEpoch;

    return {
      'contentId': contentId,
      'title': title,
      'episodeTitle': episodeTitle,
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
