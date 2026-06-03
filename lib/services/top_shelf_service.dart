import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart' show EpisodePosterMode;

/// Service for syncing On Deck / Continue Watching content to the tvOS Top Shelf.
class TopShelfService {
  static const MethodChannel _channel = MethodChannel('com.plezy/top_shelf');

  static final TopShelfService _instance = TopShelfService._internal();
  factory TopShelfService() => _instance;

  TopShelfService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Callback for when a Top Shelf item is tapped (warm start deep link).
  ValueChanged<String>? onTopShelfTap;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onTopShelfTap') {
      final contentId = call.arguments['contentId'] as String?;
      if (contentId != null) {
        onTopShelfTap?.call(contentId);
      }
    }
  }

  /// Get a pending deep link from cold start (consumed on first call).
  Future<String?> getInitialDeepLink() async {
    if (!PlatformDetector.isAppleTV()) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialDeepLink');
    } catch (e) {
      appLogger.w('Failed to get Top Shelf initial deep link', error: e);
      return null;
    }
  }

  /// Sync On Deck items to the tvOS Top Shelf (capped at 20 items).
  Future<bool> syncFromOnDeck(
    List<MediaItem> onDeckItems,
    MediaServerClient Function(ServerId serverId) getClientForServerId, {
    bool hideSpoilers = false,
  }) async {
    if (!PlatformDetector.isAppleTV()) return false;

    try {
      final items = onDeckItems.take(20).map((item) {
        return _convertToTopShelfItem(item, getClientForServerId, hideSpoilers: hideSpoilers);
      }).toList();

      return await _channel.invokeMethod<bool>('sync', {'items': items}) ?? false;
    } catch (e) {
      appLogger.e('Failed to sync Top Shelf', error: e);
      return false;
    }
  }

  /// Clear all Top Shelf entries.
  Future<bool> clear() async {
    if (!PlatformDetector.isAppleTV()) return false;
    try {
      return await _channel.invokeMethod<bool>('clear') ?? false;
    } catch (e) {
      appLogger.e('Failed to clear Top Shelf', error: e);
      return false;
    }
  }

  /// Remove a single item from the Top Shelf.
  Future<bool> removeItem(ServerId serverId, String ratingKey) async {
    if (!PlatformDetector.isAppleTV()) return false;
    try {
      final contentId = _buildContentId(serverId, ratingKey);
      return await _channel.invokeMethod<bool>('remove', {'contentId': contentId}) ?? false;
    } catch (e) {
      appLogger.e('Failed to remove Top Shelf item', error: e);
      return false;
    }
  }

  /// Build a content ID. Format: plezy_{serverId}_{ratingKey}
  static String _buildContentId(ServerId? serverId, String ratingKey) {
    return 'plezy_${serverId ?? 'unknown'}_$ratingKey';
  }

  /// Parse a content ID back to (serverId, ratingKey), or null if invalid.
  static (ServerId serverId, String ratingKey)? parseContentId(String contentId) {
    if (!contentId.startsWith('plezy_')) return null;
    final parts = contentId.substring(6).split('_');
    if (parts.length < 2) return null;
    return (ServerId(parts.first), parts.sublist(1).join('_'));
  }

  Map<String, dynamic> _convertToTopShelfItem(
    MediaItem item,
    MediaServerClient Function(ServerId serverId) getClientForServerId, {
    bool hideSpoilers = false,
  }) {
    final contentId = _buildContentId(serverIdOrNull(item.serverId), item.id);

    String? imageUrl;
    try {
      if (item.serverId != null) {
        final client = getClientForServerId(ServerId(item.serverId!));
        String? thumbPath;
        if (hideSpoilers && item.shouldHideSpoiler) {
          thumbPath = item.spoilerSafeArt;
        }
        thumbPath ??= item.posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true);
        if (thumbPath != null) {
          imageUrl = client.thumbnailUrl(thumbPath);
        }
      }
    } catch (e) {
      appLogger.w('Failed to get image URL for Top Shelf: ${item.title}', error: e);
    }

    final String title;
    if (item.kind == MediaKind.episode && item.grandparentTitle != null) {
      title = item.grandparentTitle!;
    } else {
      title = item.title ?? '';
    }

    return {
      'contentId': contentId,
      'title': title,
      'imageUrl': imageUrl,
      'durationMs': item.durationMs ?? 0,
      'lastPlaybackPositionMs': item.viewOffsetMs ?? 0,
    };
  }
}
